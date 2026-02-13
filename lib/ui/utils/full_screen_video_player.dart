import 'dart:async';

import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

class FullscreenVideoPlayer extends StatefulWidget {
  final String url;

  const FullscreenVideoPlayer({super.key, required this.url});

  @override
  State<FullscreenVideoPlayer> createState() => _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState extends State<FullscreenVideoPlayer> {
  late VideoPlayerController _controller;
  bool _showControls = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _startHideTimer();
      });
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      setState(() => _showControls = false);
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      if (_showControls) _startHideTimer();
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _toggleControls,
        child: Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
            ),

            if (_showControls)
              Positioned.fill(
                child: Container(
                  color: Colors.black26, // semi-transparent overlay
                ),
              ),

            if (_showControls)
              Center(
                child: IconButton(
                  iconSize: 40,
                  icon: Icon(
                    _controller.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _controller.value.isPlaying
                          ? _controller.pause()
                          : _controller.play();
                      _startHideTimer();
                    });
                  },
                ),
              ),

            if (_showControls)
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: SafeArea(
                  minimum: const EdgeInsets.only(bottom: 30), // tambahan jarak
                  child: buildVideoProgressBar(),
                ),
              ),

            if (_showControls)
              Positioned(
                top: 40,
                left: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 32),
                  onPressed: () => context.pop(),
                ),
              ),

            if (_showControls)
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: Icon(
                    _controller.value.volume > 0
                        ? Icons.volume_up
                        : Icons.volume_off,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      if (_controller.value.volume > 0) {
                        _controller.setVolume(0);
                      } else {
                        _controller.setVolume(1);
                      }
                      _startHideTimer();
                    });
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildVideoProgressBar() {
    final duration = _controller.value.duration;
    final position = _controller.value.position;

    String formatDuration(Duration d) {
      final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
      return '$minutes:$seconds';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          formatDuration(position),
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),

        const SizedBox(width: 8),

        Expanded(
          flex: 5,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: Colors.red,
              inactiveTrackColor: Colors.white24,
              thumbColor: Colors.red,
            ),
            child: Slider(
              value: position.inMilliseconds.toDouble().clamp(
                0.0,
                duration.inMilliseconds.toDouble(),
              ),
              max: duration.inMilliseconds.toDouble(),
              onChanged: (value) {
                _controller.seekTo(Duration(milliseconds: value.toInt()));
              },
            ),
          ),
        ),

        const SizedBox(width: 8),

        Text(
          formatDuration(duration),
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }
}
