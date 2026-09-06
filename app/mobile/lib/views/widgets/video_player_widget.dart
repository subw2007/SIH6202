import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWidget extends StatefulWidget {
  const VideoPlayerWidget({required this.source, this.height = 188, super.key});

  final String source;
  final double height;

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late final VideoPlayerController _controller;
  Future<void>? _initialization;

  @override
  void initState() {
    super.initState();
    _controller = widget.source.startsWith('http')
        ? VideoPlayerController.networkUrl(Uri.parse(widget.source))
        : VideoPlayerController.file(File(widget.source));
    _initialization = _controller.initialize();
    _controller.addListener(_onPlaybackChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onPlaybackChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onPlaybackChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: FutureBuilder<void>(
        future: _initialization,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const ColoredBox(
              color: Color(0xFFEEF1F8),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return const ColoredBox(
              color: Color(0xFFEEF1F8),
              child: Center(child: Icon(Icons.broken_image_outlined)),
            );
          }
          return Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: Colors.black, child: VideoPlayer(_controller)),
              Center(
                child: IconButton.filled(
                  tooltip: _controller.value.isPlaying ? 'Pause video' : 'Play video',
                  onPressed: () => _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play(),
                  icon: Icon(
                    _controller.value.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
