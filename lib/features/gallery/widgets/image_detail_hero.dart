import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/pixabay_image.dart';
import 'image_hero.dart';

/// The Details hero: a full-width, fixed-height, cover-fitted photograph.
/// The tile-sized assets the feed already cached sit underneath the 1280px
/// one, so the hero flight lands on a picture rather than a skeleton.
class ImageDetailHero extends StatelessWidget {
  const ImageDetailHero({super.key, required this.image, this.onTap});

  final PixabayImage image;
  final VoidCallback? onTap;

  /// Design height on a 874pt frame.
  static const double designHeight = 430;

  /// Short screens get proportionally less so the title stays in reach.
  static const double maxHeightFraction = 0.55;

  static const String viewerLabel = 'View full image';

  static double heightFor(BuildContext context) => math.min(
    designHeight,
    MediaQuery.sizeOf(context).height * maxHeightFraction,
  );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: viewerLabel,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: heightFor(context),
          width: double.infinity,
          child: ImageHero(
            image: image,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                const ColoredBox(color: AppColors.skeleton),
                // Square tiles cached the 340px asset, hero tiles the 640px
                // one; whichever was tapped is an instant memory hit.
                _Underlay(url: image.tileUrl),
                _Underlay(url: image.webformatUrl),
                CachedNetworkImage(
                  imageUrl: image.largeImageUrl,
                  fit: BoxFit.cover,
                  fadeInDuration: const Duration(milliseconds: 250),
                  placeholder: (BuildContext context, String url) =>
                      const SizedBox.shrink(),
                  errorWidget: (BuildContext context, String url, Object e) =>
                      const ImageDetailHeroFallback(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Underlay extends StatelessWidget {
  const _Underlay({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return const SizedBox.shrink();
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholder: (BuildContext context, String url) =>
          const SizedBox.shrink(),
      errorWidget: (BuildContext context, String url, Object error) =>
          const SizedBox.shrink(),
    );
  }
}

/// Shown in place of the hero when the large image cannot be loaded. The
/// metadata below it comes from the feed response, so it stays accurate.
class ImageDetailHeroFallback extends StatelessWidget {
  const ImageDetailHeroFallback({super.key, this.hint = failedHint});

  final String hint;

  static const String failedTitle = 'This image failed to load';
  static const String failedHint = 'Details below are still accurate';

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.skeleton,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.sm,
          children: <Widget>[
            const Icon(
              Icons.image_not_supported_outlined,
              size: 26,
              color: AppColors.rule35,
            ),
            Text(failedTitle, style: AppTypography.detailMeta),
            Text(hint, style: AppTypography.detailHint),
          ],
        ),
      ),
    );
  }
}
