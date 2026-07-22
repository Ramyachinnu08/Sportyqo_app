import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../api/services.dart';

/// Crop a picked avatar image into a 1:1 square. Returns the original
/// file when the cropper is unavailable so uploads never break.
Future<XFile?> cropProfileImage(XFile x) async {
  try {
    final cropped = await ImageCropper().cropImage(
      sourcePath: x.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressQuality: 85,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop photo',
          toolbarColor: const Color(0xFF7B2FFF),
          toolbarWidgetColor: Colors.white,
          statusBarColor: const Color(0xFF0A0A1A),
          backgroundColor: const Color(0xFF0A0A1A),
          activeControlsWidgetColor: const Color(0xFF7B2FFF),
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          hideBottomControls: true,
        ),
        IOSUiSettings(
          title: 'Crop photo',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
      ],
    );
    if (cropped == null) return null; // user cancelled
    return XFile(cropped.path);
  } catch (_) {
    return x; // fallback so upload still works
  }
}

/// Opens the crop UI on an already-picked image and returns the cropped
/// XFile (or the original if the user cancelled or crop is unavailable).
/// Videos should skip this — call only for images.
Future<XFile?> cropPostImage(XFile x) async {
  try {
    final cropped = await ImageCropper().cropImage(
      sourcePath: x.path,
      compressQuality: 85,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop photo',
          toolbarColor: const Color(0xFF7B2FFF),
          toolbarWidgetColor: Colors.white,
          statusBarColor: const Color(0xFF0A0A1A),
          backgroundColor: const Color(0xFF0A0A1A),
          activeControlsWidgetColor: const Color(0xFF7B2FFF),
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'Crop photo',
          aspectRatioLockEnabled: false,
          resetAspectRatioEnabled: true,
        ),
      ],
    );
    if (cropped == null) return x; // user backed out — keep original
    return XFile(cropped.path);
  } catch (_) {
    // Cropper failed (e.g. activity not registered) — upload the original
    // so the user is never blocked from posting.
    return x;
  }
}

String _mimeFor(XFile x) {
  if (x.mimeType != null && x.mimeType!.isNotEmpty) return x.mimeType!;
  final n = x.name.toLowerCase();
  if (n.endsWith('.png')) return 'image/png';
  if (n.endsWith('.webp')) return 'image/webp';
  if (n.endsWith('.heic') || n.endsWith('.heif')) return 'image/heic';
  return 'image/jpeg';
}

/// Removes the current user's profile photo.
/// Returns true on success (callers should clear their local avatar state).
Future<bool> removeAvatarPhoto(BuildContext context) async {
  try {
    await UserService.removeAvatar();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profile photo removed'),
          backgroundColor: Color(0xFF7B2FFF)));
    }
    return true;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not remove photo: $e'),
          backgroundColor: Colors.redAccent));
    }
    return false;
  }
}

/// Opens the camera or gallery, uploads the picked image as the
/// current user's avatar, and returns the new avatar URL
/// (null if the user cancelled or the upload failed).
Future<String?> pickAndUploadAvatar(
    BuildContext context, ImageSource source) async {
  try {
    final x = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85);
    if (x == null) return null; // cancelled

    // Crop step — force a 1:1 square for a proper avatar.
    // If the crop UI can't be shown (e.g. UCrop activity missing on
    // Android), fall back to uploading the picked image directly so
    // the user isn't blocked.
    CroppedFile? cropped;
    try {
      cropped = await ImageCropper().cropImage(
        sourcePath: x.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 85,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop photo',
            toolbarColor: const Color(0xFF7B2FFF),
            toolbarWidgetColor: Colors.white,
            statusBarColor: const Color(0xFF0A0A1A),
            backgroundColor: const Color(0xFF0A0A1A),
            activeControlsWidgetColor: const Color(0xFF7B2FFF),
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: true,
          ),
          IOSUiSettings(
            title: 'Crop photo',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );
      if (cropped == null) return null; // user cancelled the crop
    } catch (_) {
      cropped = null; // crop unavailable — use original bytes below
    }
    final bytes = cropped != null
        ? await cropped.readAsBytes()
        : await x.readAsBytes();
    final name = cropped != null
        ? cropped.path.split(RegExp(r'[\\/]')).last
        : (x.name.isNotEmpty ? x.name : 'avatar.jpg');
    final parts = _mimeFor(
        cropped != null ? XFile(cropped.path) : x).split('/');
    final res = await UserService.updateProfile(
      avatar: http.MultipartFile.fromBytes('avatar', bytes,
          filename: name.isNotEmpty ? name : 'avatar.jpg',
          contentType: MediaType(parts[0], parts[1])),
    );
    try {
      await UserService.me(); // refresh cached session user
    } catch (_) {}
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profile photo updated'),
          backgroundColor: Color(0xFF7B2FFF)));
    }
    return res['avatar_url'] as String?;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not update photo: $e'),
          backgroundColor: Colors.redAccent));
    }
    return null;
  }
}
