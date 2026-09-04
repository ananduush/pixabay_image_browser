import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/pill_button.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/widgets/guest_favourite_sheet.dart';
import '../controllers/gallery_controller.dart';
import '../models/pixabay_image.dart';
import '../widgets/gallery_state_view.dart';
import '../widgets/glass_icon_button.dart';
import '../widgets/image_detail_actions.dart';
import '../widgets/image_detail_creator.dart';
import '../widgets/image_detail_hero.dart';
import '../widgets/image_detail_stats.dart';
import '../widgets/image_detail_tags.dart';

/// Image Details, rendered entirely from the [PixabayImage] the feed already
/// holds — opening it costs no Pixabay request.
class ImageDetailView extends StatelessWidget {
  const ImageDetailView({super.key, required this.image});

  final PixabayImage image;

  /// Room under the tags so the floating bar never covers them.
  static const double bottomSpacer = 150;

  static const double backTopInset = 10;
  static const double backLeftInset = 16;

  void _openViewer() {
    Get.toNamed<void>(AppRoutes.imageViewer, arguments: image);
  }

  /// Search first, then pop: the Gallery is already showing its loading
  /// state (no tile heroes) by the time the pop's hero scan runs, and
  /// `search` fills the field without focusing it, so the keyboard stays down.
  void _searchTag(String tag) {
    Get.find<GalleryController>().search(tag);
    Get.back<void>();
  }

  /// Guests get the sign-in sheet. A signed-in tap stays inert until the
  /// Favourites slice adds the toggle.
  void _onFavouriteTap(BuildContext context) {
    if (Get.find<AuthController>().state.value.isAuthenticated) return;
    unawaited(GuestFavouriteSheet.show(context));
  }

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.paddingOf(context).top;
    final barInset = ImageDetailActions.bottomInset(context);
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            // the photo runs under the status bar by design — no SafeArea
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  ImageDetailHero(image: image, onTap: _openViewer),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.gutter,
                      24,
                      AppSpacing.gutter,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(image.title, style: AppTypography.detailTitle),
                        const SizedBox(height: AppSpacing.sm),
                        ImageDetailCreator(image: image),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.gutter,
                      24,
                      AppSpacing.gutter,
                      0,
                    ),
                    child: ImageDetailStats(image: image),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.gutter,
                      18,
                      AppSpacing.gutter,
                      0,
                    ),
                    child: ImageDetailTags(
                      tags: image.tags,
                      onTagTap: _searchTag,
                    ),
                  ),
                  SizedBox(
                    height:
                        bottomSpacer +
                        math.max(
                          0,
                          barInset - ImageDetailActions.designBottomInset,
                        ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: safeTop + backTopInset,
            left: backLeftInset,
            child: GlassIconButton(
              icon: Icons.arrow_back_ios_new,
              label: GlassIconButton.backLabel,
              onTap: Get.back<void>,
            ),
          ),
          // Download stays inert until its slice wires it.
          ImageDetailActions(onFavouriteTap: () => _onFavouriteTap(context)),
        ],
      ),
    );
  }
}

/// Reached only if the route is opened without a [PixabayImage] argument.
class ImageDetailMissingView extends StatelessWidget {
  const ImageDetailMissingView({super.key});

  static const String missingTitle = 'Image unavailable';
  static const String missingBody =
      'This image is no longer available. Go back and pick another.';
  static const String backLabel = 'Back';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: GalleryStateView(
          glyph: const Icon(
            Icons.image_not_supported_outlined,
            size: 34,
            color: AppColors.rule35,
          ),
          title: missingTitle,
          body: missingBody,
          children: <Widget>[
            const SizedBox(height: 24),
            PillButton(label: backLabel, onPressed: Get.back<void>),
          ],
        ),
      ),
    );
  }
}
