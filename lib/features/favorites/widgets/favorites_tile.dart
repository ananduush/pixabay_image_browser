import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_surface.dart';
import '../../gallery/models/pixabay_image.dart';
import '../../gallery/widgets/gallery_image_tile.dart';

/// A saved image: the Gallery's square tile plus a glass heart that removes
/// it. The large image is used because Pixabay documents the medium one as
/// expiring after 24 hours, and Details has already cached the large one.
class FavoritesTile extends StatelessWidget {
  const FavoritesTile({
    super.key,
    required this.image,
    required this.onTap,
    required this.onRemove,
  });

  final PixabayImage image;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  static const double removeSize = 34;
  static const double removeInset = 8;

  /// Decode cap: roughly 3× a half-width tile.
  static const int memCacheWidth = 600;

  static String removeLabel(PixabayImage image) =>
      'Remove ${image.title} from favourites';

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        GalleryImageTile(
          image: image,
          onTap: onTap,
          imageUrl: image.largeImageUrl,
          memCacheWidth: memCacheWidth,
        ),
        Positioned(
          top: removeInset,
          right: removeInset,
          child: Semantics(
            button: true,
            label: removeLabel(image),
            excludeSemantics: true,
            child: GestureDetector(
              onTap: onRemove,
              behavior: HitTestBehavior.opaque,
              child: SizedBox.square(
                dimension: removeSize,
                child: GlassSurface(
                  borderRadius: removeSize / 2,
                  child: const Center(
                    child: Icon(Icons.favorite, size: 15, color: AppColors.ink),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
