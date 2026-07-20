import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../api/services.dart';

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
    final bytes = await x.readAsBytes();
    final parts = _mimeFor(x).split('/');
    final res = await UserService.updateProfile(
      avatar: http.MultipartFile.fromBytes('avatar', bytes,
          filename: x.name.isNotEmpty ? x.name : 'avatar.jpg',
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
