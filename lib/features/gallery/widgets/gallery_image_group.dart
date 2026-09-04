import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/pixabay_image.dart';
import 'gallery_image_tile.dart';

/// One feed group: a 4:3 hero with its caption, then up to three square
/// tiles in a row. Columns stay equal-width even when the trio is short.
class GalleryImageGroup extends StatelessWidget {
  const GalleryImageGroup({super.key, required this.images, this.onImageTap})
    : assert(images.length >= 1, 'A group needs a hero image');

  final List<PixabayImage> images;

  /// Called with the tapped image; null leaves the tiles inert.
  final ValueChanged<PixabayImage>? onImageTap;

  static const int trioSize = 3;

  PixabayImage get hero => images.first;

  List<PixabayImage> get trio => images.skip(1).take(trioSize).toList();

  @override
  Widget build(BuildContext context) {
    final tiles = trio;
    final onImageTap = this.onImageTap;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AspectRatio(
          aspectRatio: 4 / 3,
          child: GalleryImageTile(
            image: hero,
            hero: true,
            onTap: onImageTap == null ? null : () => onImageTap(hero),
          ),
        ),
        const SizedBox(height: 9),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          spacing: AppSpacing.sm,
          children: <Widget>[
            Expanded(
              child: Text(
                hero.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.captionTitle,
              ),
            ),
            Text(hero.user, style: AppTypography.captionMeta),
          ],
        ),
        if (tiles.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          Row(
            spacing: AppSpacing.gridGap,
            children: <Widget>[
              for (final image in tiles)
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: GalleryImageTile(
                      image: image,
                      onTap: onImageTap == null
                          ? null
                          : () => onImageTap(image),
                    ),
                  ),
                ),
              for (var i = tiles.length; i < trioSize; i++)
                const Expanded(child: SizedBox.shrink()),
            ],
          ),
        ],
      ],
    );
  }
}
