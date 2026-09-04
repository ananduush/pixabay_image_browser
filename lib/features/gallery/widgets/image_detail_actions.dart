import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/filled_pill_button.dart';
import '../../../core/widgets/glass_surface.dart';

/// The floating bar under the Details content: the favourite pill (glass
/// while unsaved, ink once saved) and a download circle. A `null` callback
/// leaves a control inert.
class ImageDetailActions extends StatelessWidget {
  const ImageDetailActions({
    super.key,
    this.saved = false,
    this.downloading = false,
    this.onFavouriteTap,
    this.onDownloadTap,
  });

  /// Whether the image is in the signed-in user's favourites.
  final bool saved;

  /// A save to Photos is running: the circle shows a spinner and ignores
  /// taps until it finishes.
  final bool downloading;

  /// Guest sheet or favourite toggle, decided by the caller.
  final VoidCallback? onFavouriteTap;

  /// Saves the photo to the device library.
  final VoidCallback? onDownloadTap;

  static const double height = 56;

  /// Design offset from the physical bottom edge, home indicator included.
  static const double designBottomInset = 40;

  static const double sideInset = 16;

  static const String favouriteLabel = 'Save to favourites';
  static const String savedLabel = 'Saved to favourites';
  static const String downloadLabel = 'Download';
  static const String downloadingLabel = 'Saving to Photos';

  static const double spinnerSize = 16;

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
          if (saved)
            Expanded(
              // the design blurs what sits under the ink pill (tag chips)
              child: ClipRRect(
                borderRadius: BorderRadius.circular(height / 2),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: FilledPillButton(
                    label: savedLabel,
                    icon: Icons.favorite,
                    height: height,
                    onPressed: onFavouriteTap,
                  ),
                ),
              ),
            )
          else
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
            enabled: !downloading,
            label: downloading ? downloadingLabel : downloadLabel,
            child: GestureDetector(
              onTap: downloading ? null : onDownloadTap,
              behavior: HitTestBehavior.opaque,
              child: SizedBox.square(
                dimension: height,
                child: GlassSurface(
                  borderRadius: height / 2,
                  child: Center(
                    child: downloading
                        ? const SizedBox.square(
                            dimension: spinnerSize,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.6,
                              color: AppColors.ink,
                              backgroundColor: AppColors.inkFill16,
                            ),
                          )
                        : const Icon(
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
