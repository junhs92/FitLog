import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../../core/theme/colors.dart';

class YouTubePlayerWidget extends StatefulWidget {
  final String videoId;
  final VoidCallback onClose;

  const YouTubePlayerWidget({
    required this.videoId,
    required this.onClose,
    super.key,
  });

  @override
  State<YouTubePlayerWidget> createState() => _YouTubePlayerWidgetState();
}

class _YouTubePlayerWidgetState extends State<YouTubePlayerWidget> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showFullscreenButton: true,
        showControls: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        YoutubePlayer(controller: _controller),
        // Close button
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: widget.onClose,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: AppColors.neutralWhite,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
