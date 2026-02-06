import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/theme/colors.dart';

/// Video player widget for exercise demonstration videos
///
/// Features:
/// - Auto-play on mount, loop continuously
/// - Muted by default (exercise demos don't need audio)
/// - Loading indicator while buffering
/// - Tap to pause/play
/// - Fallback to image if video fails
class ExerciseVideoPlayer extends StatefulWidget {
  /// Video URL (MP4 format from ExerciseDB)
  final String? videoUrl;

  /// Fallback image URL if video fails to load
  final String? fallbackImageUrl;

  /// Height of the video container
  final double? height;

  /// Border radius for the container
  final double borderRadius;

  const ExerciseVideoPlayer({
    this.videoUrl,
    this.fallbackImageUrl,
    this.height = 180,
    this.borderRadius = 12,
    super.key,
  });

  @override
  State<ExerciseVideoPlayer> createState() => _ExerciseVideoPlayerState();
}

class _ExerciseVideoPlayerState extends State<ExerciseVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void didUpdateWidget(ExerciseVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposeController();
      _initializeVideo();
    }
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
    _hasError = false;
    _isPaused = false;
  }

  Future<void> _initializeVideo() async {
    final videoUrl = widget.videoUrl;
    if (videoUrl == null || videoUrl.isEmpty) {
      setState(() => _hasError = true);
      return;
    }

    try {
      final proxyUrl = _getProxyUrl(videoUrl);
      final uri = Uri.parse(proxyUrl);

      _controller = VideoPlayerController.networkUrl(uri);

      await _controller!.initialize();
      await _controller!.setLooping(true);
      await _controller!.setVolume(0); // Muted by default
      await _controller!.play();

      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  /// Returns proxy URL for web platform to bypass CORS restrictions
  String _getProxyUrl(String url) {
    if (!kIsWeb) return url;
    if (!url.contains('cdn.exercisedb.dev')) return url;

    const proxyPath = '/functions/v1/image-proxy';
    final proxyBase = '${SupabaseConfig.supabaseUrl}$proxyPath';
    return '$proxyBase?url=${Uri.encodeComponent(url)}';
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;

    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    // Show fallback if error or no video URL
    if (_hasError) {
      return _buildFallback();
    }

    // Show loading while initializing
    if (!_isInitialized || _controller == null) {
      return _buildLoading();
    }

    // Show video player with tap to pause/play
    return GestureDetector(
      onTap: _togglePlayPause,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Video
          Center(
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
          ),
          // Pause overlay
          if (_isPaused)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
          // Buffering indicator
          ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: _controller!,
            builder: (context, value, child) {
              if (value.isBuffering) {
                return const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildFallback() {
    final fallbackUrl = widget.fallbackImageUrl;

    // If we have a fallback image, show it
    if (fallbackUrl != null && fallbackUrl.isNotEmpty) {
      return Image.network(
        _getProxyUrl(fallbackUrl),
        fit: BoxFit.contain,
        height: widget.height,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoading();
        },
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return const Center(
      child: Icon(
        Icons.fitness_center,
        size: 48,
        color: AppColors.neutral400,
      ),
    );
  }
}
