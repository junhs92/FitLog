import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/theme/colors.dart';

/// Displays exercise image from ExerciseDB API with loading/error states
///
/// Uses CachedNetworkImage for efficient caching.
/// Shows placeholder while loading and fallback icon if no imageUrl or error.
class ExerciseGifImage extends StatelessWidget {
  /// Direct image URL from ExerciseDB CDN
  final String? imageUrl;

  /// ExerciseDB exercise ID (legacy, for compatibility)
  final String? exerciseDbId;

  /// Width of the image container
  final double? width;

  /// Height of the image container
  final double? height;

  /// How the image should be inscribed into the box
  final BoxFit fit;

  /// Image resolution (unused now, kept for compatibility)
  final int resolution;

  /// Border radius for the image container
  final double borderRadius;

  /// Background color for the container
  final Color? backgroundColor;

  /// Whether to show a border around the container
  final bool showBorder;

  /// Custom placeholder widget
  final Widget? placeholder;

  /// Custom error widget
  final Widget? errorWidget;

  const ExerciseGifImage({
    this.imageUrl,
    this.exerciseDbId,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.resolution = 180,
    this.borderRadius = 8.0,
    this.backgroundColor,
    this.showBorder = false,
    this.placeholder,
    this.errorWidget,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.neutral100,
        borderRadius: BorderRadius.circular(borderRadius),
        border: showBorder
            ? Border.all(color: AppColors.neutral300, width: 1)
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null && url.isNotEmpty
          ? _buildNetworkImage(url)
          : _buildFallback(),
    );
  }

  /// Returns proxy URL for web platform to bypass CORS restrictions
  String _getProxyUrl(String url) {
    if (!kIsWeb) return url;
    if (!url.contains('cdn.exercisedb.dev')) return url;

    final proxyBase = '${SupabaseConfig.supabaseUrl}/functions/v1/image-proxy';
    return '$proxyBase?url=${Uri.encodeComponent(url)}';
  }

  Widget _buildNetworkImage(String url) {
    return CachedNetworkImage(
      imageUrl: _getProxyUrl(url),
      fit: fit,
      width: width,
      height: height,
      placeholder: (context, url) =>
          placeholder ?? _buildLoadingPlaceholder(),
      errorWidget: (context, url, error) =>
          errorWidget ?? _buildFallback(),
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 100),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      color: backgroundColor ?? AppColors.neutral100,
      child: Center(
        child: SizedBox(
          width: _getIconSize() * 0.6,
          height: _getIconSize() * 0.6,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      color: backgroundColor ?? AppColors.neutral100,
      child: Center(
        child: Icon(
          Icons.fitness_center,
          size: _getIconSize(),
          color: AppColors.neutral400,
        ),
      ),
    );
  }

  double _getIconSize() {
    final size = width ?? height ?? 48;
    return (size * 0.5).clamp(16.0, 48.0);
  }
}

/// Compact version of ExerciseGifImage for use in lists and cards
class ExerciseGifThumbnail extends StatelessWidget {
  final String? imageUrl;
  final double size;

  const ExerciseGifThumbnail({
    this.imageUrl,
    this.size = 48,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ExerciseGifImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      borderRadius: 8,
      showBorder: true,
    );
  }
}

/// Large version of ExerciseGifImage for active session display
class ExerciseGifDisplay extends StatelessWidget {
  final String? imageUrl;
  final double? height;

  const ExerciseGifDisplay({
    this.imageUrl,
    this.height = 180,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ExerciseGifImage(
      imageUrl: imageUrl,
      height: height,
      fit: BoxFit.contain,
      borderRadius: 12,
      backgroundColor: AppColors.neutral100,
    );
  }
}
