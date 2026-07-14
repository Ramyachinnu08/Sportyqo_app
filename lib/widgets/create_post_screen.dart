import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../api/services.dart';

/// Instagram-style "new post" screen: media preview, caption,
/// category, then multipart upload to POST /posts.
class CreatePostScreen extends StatefulWidget {
  final XFile file;
  final bool isVideo;
  final Map<String, String>? categories;
  const CreatePostScreen(
      {super.key,
      required this.file,
      required this.isVideo,
      this.categories});

  @override
  State<CreatePostScreen> createState() =>
      CreatePostScreenState();
}

class CreatePostScreenState extends State<CreatePostScreen> {
  final _captionCtrl = TextEditingController();
  String _category = 'playing';
  bool _posting = false;
  Uint8List? _bytes;

  static const _defaultCategories = <String, String>{
    'playing': 'Playing',
    'certificates': 'Certificates',
    'team': 'Team',
    'trophies': 'Trophies',
  };
  Map<String, String> get _categories =>
      widget.categories ?? _defaultCategories;

  @override
  void initState() {
    super.initState();
    widget.file.readAsBytes().then((b) {
      if (mounted) setState(() => _bytes = b);
    });
  }

  String get _mime {
    final fromFile = widget.file.mimeType;
    if (fromFile != null && fromFile.isNotEmpty) return fromFile;
    final n = widget.file.name.toLowerCase();
    if (widget.isVideo) {
      if (n.endsWith('.mov')) return 'video/quicktime';
      if (n.endsWith('.webm')) return 'video/webm';
      if (n.endsWith('.mkv')) return 'video/x-matroska';
      return 'video/mp4';
    }
    if (n.endsWith('.png')) return 'image/png';
    if (n.endsWith('.webp')) return 'image/webp';
    if (n.endsWith('.heic') || n.endsWith('.heif')) {
      return 'image/heic';
    }
    return 'image/jpeg';
  }

  Future<void> _share() async {
    if (_posting) return;
    final bytes = _bytes ?? await widget.file.readAsBytes();
    setState(() => _posting = true);
    try {
      final parts = _mime.split('/');
      await FeedService.createPost(
        content: _captionCtrl.text.trim(),
        category: _category,
        media: [
          http.MultipartFile.fromBytes('media', bytes,
              filename: widget.file.name.isNotEmpty
                  ? widget.file.name
                  : (widget.isVideo
                      ? 'video.mp4'
                      : 'photo.jpg'),
              contentType: MediaType(parts[0], parts[1])),
        ],
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _posting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not post: $e'),
          backgroundColor: Colors.redAccent));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context, false),
                child: const Icon(Icons.close,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              const Text('New Post',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
              const Spacer(),
              GestureDetector(
                onTap: _posting ? null : _share,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                      color: const Color(0xFF7B2FFF),
                      borderRadius: BorderRadius.circular(20)),
                  child: _posting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2))
                      : const Text('Share',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                ),
              ),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Media preview ──
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      height: 280,
                      color: const Color(0xFF111111),
                      child: widget.isVideo
                          ? AppVideoPlayer.file(
                              widget.file.path,
                              loop: true)
                          : _bytes == null
                              ? const Center(
                                  child:
                                      CircularProgressIndicator(
                                          color: Color(
                                              0xFF7B2FFF)))
                              : Image.memory(_bytes!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 280),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Caption ──
                  const Text('Caption',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _captionCtrl,
                    maxLines: 4,
                    maxLength: 2000,
                    style:
                        const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText:
                          'Write a caption… use #hashtags too',
                      hintStyle: const TextStyle(
                          color: Colors.white30),
                      counterStyle: const TextStyle(
                          color: Colors.white24),
                      filled: true,
                      fillColor: const Color(0xFF111111),
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Category ──
                  const Text('Show under',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.entries.map((e) {
                      final active = _category == e.key;
                      return GestureDetector(
                        onTap: () => setState(
                            () => _category = e.key),
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8),
                          decoration: BoxDecoration(
                            color: active
                                ? const Color(0xFF7B2FFF)
                                : const Color(0xFF111111),
                            borderRadius:
                                BorderRadius.circular(20),
                            border: Border.all(
                                color: active
                                    ? const Color(0xFF7B2FFF)
                                    : Colors.white12),
                          ),
                          child: Text(e.value,
                              style: TextStyle(
                                  color: active
                                      ? Colors.white
                                      : Colors.white54,
                                  fontSize: 13,
                                  fontWeight:
                                      FontWeight.w600)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                      'Your post appears in the Dugout feed of everyone who follows you, and in the tab you pick above on your Playbook.',
                      style: TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                          height: 1.4)),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
