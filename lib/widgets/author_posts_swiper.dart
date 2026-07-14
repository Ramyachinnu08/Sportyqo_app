import 'package:flutter/material.dart';

/// One feed slot per author: shows their LATEST post first; swiping
/// left reveals their previous posts (right swipes back to newer).
/// Card height adapts to each post's content.
class AuthorPostsSwiper extends StatefulWidget {
  final List<Map<String, dynamic>> posts; // newest first
  final Widget Function(Map<String, dynamic> post) buildCard;
  final Color accent;

  const AuthorPostsSwiper(
      {super.key,
      required this.posts,
      required this.buildCard,
      this.accent = const Color(0xFF7B2FFF)});

  @override
  State<AuthorPostsSwiper> createState() => _AuthorPostsSwiperState();
}

class _AuthorPostsSwiperState extends State<AuthorPostsSwiper> {
  int _index = 0; // 0 = latest

  void _go(int delta) {
    final next = (_index + delta).clamp(0, widget.posts.length - 1);
    if (next != _index) setState(() => _index = next);
  }

  @override
  Widget build(BuildContext context) {
    final posts = widget.posts;
    if (posts.length == 1) return widget.buildCard(posts.first);
    _index = _index.clamp(0, posts.length - 1);

    return GestureDetector(
      // swipe left => older post, swipe right => back to newer
      onHorizontalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        if (v < -150) _go(1);
        if (v > 150) _go(-1);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                      position: Tween<Offset>(
                              begin: const Offset(0.06, 0),
                              end: Offset.zero)
                          .animate(anim),
                      child: child)),
              child: KeyedSubtree(
                key: ValueKey(_index),
                child: widget.buildCard(posts[_index]),
              ),
            ),
            // "latest / earlier" chip
            Positioned(
              top: 10,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12)),
                child: Text(
                    _index == 0
                        ? 'Latest • 1/${posts.length}'
                        : '${_index + 1}/${posts.length}',
                    style: TextStyle(
                        color: _index == 0
                            ? widget.accent
                            : Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(posts.length, (i) {
              final active = i == _index;
              return GestureDetector(
                onTap: () => setState(() => _index = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active ? widget.accent : Colors.white24,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
