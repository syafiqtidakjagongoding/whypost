import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class FediverseVideo extends StatefulWidget {
  final String url;
  const FediverseVideo({super.key, required this.url});

  @override
  State<FediverseVideo> createState() => _FediverseVideoState();
}

class _FediverseVideoState extends State<FediverseVideo> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return Container(
        color: Colors.black12,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        ),

        IconButton(
          iconSize: 50,
          icon: Icon(
            _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
          ),
          onPressed: () {
            setState(() {
              _controller.value.isPlaying
                  ? _controller.pause()
                  : _controller.play();
            });
          },
        ),

        Positioned(
          top: 10,
          right: 10,
          child: IconButton(
            icon: Icon(
              _controller.value.volume > 0 ? Icons.volume_up : Icons.volume_off,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                if (_controller.value.volume > 0) {
                  _controller.setVolume(0);
                } else {
                  _controller.setVolume(1);
                }
              });
            },
          ),
        ),
      ],
    );
  }
}
