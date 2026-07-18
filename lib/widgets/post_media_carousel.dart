import 'package:flutter/material.dart';

import 'app_video_player.dart';

/// Swipeable media strip for a post: when a user attaches multiple
/// photos/videos, they sit side by side and slide left/right, with
/// dot indicators and a "1/3" counter — instead of only showing the
/// first one.
class PostMediaCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> items; // [{url, type}]
  final double height;
  final Color accent;
  final VoidCallback? onTapImage;

  const PostMediaCarousel(
      {super.key,
      required this.items,
      this.height = 240,
      this.accent = const Color(0xFF7B2FFF),
      this.onTapImage});

  @override
  State<PostMediaCarousel> createState() => _PostMediaCarouselState();
}

class _PostMediaCarouselState extends State<PostMediaCarousel> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    if (items.isEmpty) return const SizedBox.shrink();
    final multiple = items.length > 1;

    return SizedBox(
      height: widget.height,
      child: Stack(children: [
        PageView.builder(
          itemCount: items.length,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (context, i) {
            final m = items[i];
            final url = m['url'] as String;
            if (m['type'] == 'video') {
              return AppVideoPlayer.network(url,
                  aspectRatioOverride: null);
            }
            return GestureDetector(
              onTap: widget.onTapImage,
              child: Image.network(
                url,
                width: double.infinity,
                height: widget.height,
                fit: BoxFit.cover,
                // decode at a bounded size so huge legacy images
                // can't freeze feed scrolling
                cacheWidth: 1080,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    height: widget.height,
                    color: const Color(0xFF1A1A1A),
                    child: Center(
                      child: CircularProgressIndicator(
                          color: widget.accent, strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => Container(
                  height: widget.height,
                  color: const Color(0xFF1A1A1A),
                  child: const Center(
                    child: Icon(Icons.image_outlined,
                        color: Colors.white24, size: 48),
                  ),
                ),
              ),
            );
          },
        ),
        if (multiple) ...[
          // counter chip (top-right)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12)),
              child: Text('${_page + 1}/${items.length}',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 11)),
            ),
          ),
          // dots (bottom-center)
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(items.length, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active ? widget.accent : Colors.white38,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
        ],
      ]),
    );
  }
}
