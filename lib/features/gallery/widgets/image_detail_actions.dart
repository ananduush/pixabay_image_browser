import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_surface.dart';

/// The floating glass bar under the Details content: "Save to favourites"
/// and a download circle. Both are visual-only until their slices land;
/// a `null` callback leaves the control inert.
class ImageDetailActions extends StatelessWidget {
  const ImageDetailActions({
    super.key,
    this.onFavouriteTap,
    this.onDownloadTap,
  });

  /// Wired by the Favourites slice (guest sheet, toggle, toast).
  final VoidCallback? onFavouriteTap;

  /// Download is out of scope for now.
  final VoidCallback? onDownloadTap;

  static const double height = 56;

  /// Design offset from the physical bottom edge, home indicator included.
  static const double designBottomInset = 40;

  static const double sideInset = 16;

  static const String favouriteLabel = 'Save to favourites';
  static const String downloadLabel = 'Download';

  static double bottomInset(BuildContext context) =>
      math.max(designBottomInset, MediaQuery.paddingOf(context).bottom + 6);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: sideInset,
      right: sideInset,
      bottom: bottomInset(context),
      child: Row(
        spacing: AppSpacing.sm,
        children: <Widget>[
          Expanded(
            child: Semantics(
              button: true,
              label: favouriteLabel,
              // the label is the visible text; one node, not two
              excludeSemantics: true,
              child: GestureDetector(
                onTap: onFavouriteTap,
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  height: height,
                  child: GlassSurface(
                    borderRadius: height / 2,
                    // GlassSurface stacks its child top-left; centre it
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: AppSpacing.sm,
                        children: <Widget>[
                          const Icon(
                            Icons.favorite_outline,
                            size: 16,
                            color: AppColors.ink,
                          ),
                          Flexible(
                            child: Text(
                              favouriteLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.actionLabel,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Semantics(
            button: true,
            label: downloadLabel,
            child: GestureDetector(
              onTap: onDownloadTap,
              behavior: HitTestBehavior.opaque,
              child: SizedBox.square(
                dimension: height,
                child: GlassSurface(
                  borderRadius: height / 2,
                  child: const Center(
                    child: Icon(
                      Icons.download_outlined,
                      size: 18,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
