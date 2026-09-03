import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/pixabay_image.dart';

/// One photograph, cover-fitted with a 2pt radius. While loading it shows
/// the skeleton fill; if the bytes never arrive it shows the design's
/// "Image unavailable" fallback instead of an error icon.
class GalleryImageTile extends StatelessWidget {
  const GalleryImageTile({super.key, required this.image, this.hero = false});

  final PixabayImage image;

  /// Heroes load the 640px asset and get the captioned fallback;
  /// square tiles load the 340px variant and a bare glyph.
  final bool hero;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.image)),
      child: ColoredBox(
        color: AppColors.inkFill7,
        child: CachedNetworkImage(
          imageUrl: hero ? image.webformatUrl : image.tileUrl,
          fit: BoxFit.cover,
          fadeInDuration: const Duration(milliseconds: 250),
          placeholder: (BuildContext context, String url) =>
              const SizedBox.expand(),
          errorWidget: (BuildContext context, String url, Object error) =>
              GalleryImageFallback(hero: hero),
        ),
      ),
    );
  }
}

/// Tile shown when an image fails to load.
class GalleryImageFallback extends StatelessWidget {
  const GalleryImageFallback({super.key, required this.hero});

  final bool hero;

  static const String label = 'Image unavailable';

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.skeleton,
        border: Border.all(color: AppColors.rule9),
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.image)),
      ),
      child: Center(
        child: hero
            ? Column(
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpacing.sm,
                children: <Widget>[
                  const Icon(
                    Icons.image_not_supported_outlined,
                    size: 22,
                    color: AppColors.rule35,
                  ),
                  Text(label, style: AppTypography.tileFallback),
                ],
              )
            : const Icon(
                Icons.image_not_supported_outlined,
                size: 18,
                color: AppColors.rule35,
              ),
      ),
    );
  }
}
