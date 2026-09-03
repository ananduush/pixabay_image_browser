import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_surface.dart';

/// Floating glass capsule shown over the header while page 1 is re-fetched.
/// The view positions it; it only draws the spinner and label.
class GalleryRefreshPill extends StatelessWidget {
  const GalleryRefreshPill({super.key});

  static const String refreshingLabel = 'Refreshing';

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: <Widget>[
          const SizedBox.square(
            dimension: 13,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: AppColors.ink,
              backgroundColor: AppColors.inkFill16,
            ),
          ),
          Text(refreshingLabel, style: AppTypography.refreshStatus),
        ],
      ),
    );
  }
}

/// What the pull-to-refresh control draws while the user drags: an arrow and
/// "Pull to refresh" fading in with the pull. Once armed the refresh has
/// started and [GalleryRefreshPill] takes over, so every other mode is empty.
class GalleryPullHint extends StatelessWidget {
  const GalleryPullHint({
    super.key,
    required this.mode,
    required this.pulledExtent,
    required this.triggerDistance,
  });

  final RefreshIndicatorMode mode;
  final double pulledExtent;
  final double triggerDistance;

  static const String pullLabel = 'Pull to refresh';

  /// [RefreshControlIndicatorBuilder] for [CupertinoSliverRefreshControl].
  static Widget builder(
    BuildContext context,
    RefreshIndicatorMode mode,
    double pulledExtent,
    double triggerDistance,
    double indicatorExtent,
  ) {
    return GalleryPullHint(
      mode: mode,
      pulledExtent: pulledExtent,
      triggerDistance: triggerDistance,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget child = switch (mode) {
      RefreshIndicatorMode.drag => Opacity(
        opacity: (pulledExtent / triggerDistance).clamp(0.0, 1.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8,
          children: <Widget>[
            const Icon(Icons.arrow_upward, size: 13, color: AppColors.ink),
            Text(pullLabel, style: AppTypography.refreshHint),
          ],
        ),
      ),
      RefreshIndicatorMode.armed ||
      RefreshIndicatorMode.refresh ||
      RefreshIndicatorMode.done ||
      RefreshIndicatorMode.inactive => const SizedBox.shrink(),
    };
    // Same frame as CupertinoSliverRefreshControl.buildRefreshIndicator.
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned(top: 12, left: 0, right: 0, child: child),
        ],
      ),
    );
  }
}
