import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Real video playback for network URLs or local files, with
/// tap-to-play/pause, progress bar, remaining time, and mute.
class AppVideoPlayer extends StatefulWidget {
  final String? url; // network source
  final String? filePath; // local source (new-post preview)
  final bool autoPlay;
  final bool loop;
  final double? aspectRatioOverride;

  const AppVideoPlayer.network(this.url,
      {super.key,
      this.autoPlay = false,
      this.loop = false,
      this.aspectRatioOverride})
      : filePath = null;

  const AppVideoPlayer.file(this.filePath,
      {super.key,
      this.autoPlay = false,
      this.loop = false,
      this.aspectRatioOverride})
      : url = null;

  @override
  State<AppVideoPlayer> createState() => _AppVideoPlayerState();
}

class _AppVideoPlayerState extends State<AppVideoPlayer> {
  VideoPlayerController? _controller;
  bool _failed = false;
  bool _muted = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final c = widget.filePath != null
          ? VideoPlayerController.file(File(widget.filePath!))
          : VideoPlayerController.networkUrl(Uri.parse(widget.url!));
      _controller = c;
      await c.initialize();
      await c.setLooping(widget.loop);
      if (widget.autoPlay) await c.play();
      if (mounted) setState(() {});
      c.addListener(() {
        if (mounted) setState(() {});
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString();
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Container(
        color: const Color(0xFF111111),
        child: const Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.videocam_off_outlined,
                color: Colors.white38, size: 40),
            SizedBox(height: 8),
            Text('Video unavailable',
                style: TextStyle(color: Colors.white38, fontSize: 12)),
          ]),
        ),
      );
    }
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      return Container(
        color: const Color(0xFF111111),
        child: const Center(
            child: CircularProgressIndicator(color: Color(0xFF7B2FFF))),
      );
    }

    final ratio = widget.aspectRatioOverride ??
        (c.value.aspectRatio == 0 ? 16 / 9 : c.value.aspectRatio);
    final remaining = c.value.duration - c.value.position;

    return GestureDetector(
      onTap: () => c.value.isPlaying ? c.pause() : c.play(),
      child: AspectRatio(
        aspectRatio: ratio,
        child: Stack(alignment: Alignment.center, children: [
          VideoPlayer(c),
          // play overlay when paused
          if (!c.value.isPlaying)
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                  color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.play_arrow,
                  color: Colors.white, size: 34),
            ),
          // mute toggle
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () {
                _muted = !_muted;
                c.setVolume(_muted ? 0 : 1);
                setState(() {});
              },
              child: Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                    color: Colors.black54, shape: BoxShape.circle),
                child: Icon(_muted ? Icons.volume_off : Icons.volume_up,
                    color: Colors.white, size: 16),
              ),
            ),
          ),
          // remaining time
          Positioned(
            bottom: 10,
            right: 8,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6)),
              child: Text(_fmt(remaining),
                  style: const TextStyle(
                      color: Colors.white, fontSize: 10)),
            ),
          ),
          // progress bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: VideoProgressIndicator(
              c,
              allowScrubbing: true,
              padding: EdgeInsets.zero,
              colors: const VideoProgressColors(
                playedColor: Color(0xFF7B2FFF),
                bufferedColor: Colors.white24,
                backgroundColor: Colors.white10,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
