import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/state_view.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/widgets/guest_favourite_sheet.dart';
import '../../favorites/controllers/favorites_controller.dart';
import '../../favorites/views/favorites_view.dart';
import '../../home/controllers/home_controller.dart';
import '../controllers/gallery_controller.dart';
import '../controllers/image_detail_controller.dart';
import '../controllers/image_detail_state.dart';
import '../models/pixabay_image.dart';
import '../services/image_download_exception.dart';
import '../widgets/glass_icon_button.dart';
import '../widgets/image_detail_actions.dart';
import '../widgets/image_detail_creator.dart';
import '../widgets/image_detail_hero.dart';
import '../widgets/image_detail_stats.dart';
import '../widgets/image_detail_tags.dart';

/// Image Details, rendered entirely from the [PixabayImage] the feed already
/// holds — opening it costs no Pixabay request.
class ImageDetailView extends GetView<ImageDetailController> {
  const ImageDetailView({super.key, required this.image});

  final PixabayImage image;

  static const String savedToPhotos = 'Saved to Photos';
  static const String downloadOffline = 'Download needs a connection';
  static const String downloadDenied =
      'Allow Photos access in Settings to save images';
  static const String downloadFailed = "Couldn't save to Photos";

  /// Room under the tags so the floating bar never covers them.
  static const double bottomSpacer = 150;

  static const double backTopInset = 10;
  static const double backLeftInset = 16;

  void _openViewer() {
    Get.toNamed<void>(AppRoutes.imageViewer, arguments: image);
  }

  FavoritesController get _favorites => Get.find<FavoritesController>();

  /// Switch to Explore and search first, then pop: Details may have been
  /// opened from Favourites, the Gallery is already showing its loading
  /// state (no tile heroes) by the time the pop's hero scan runs, and
  /// `search` fills the field without focusing it, so the keyboard stays down.
  void _searchTag(String tag) {
    Get.find<HomeController>().showExplore();
    Get.find<GalleryController>().search(tag);
    Get.back<void>();
  }

  /// Toast plumbing captured before any await: the user may pop Details
  /// while a write or download is still running.
  void Function(String message) _toaster(BuildContext context) {
    final overlay = Overlay.of(context, rootOverlay: true);
    final bottomOffset =
        ImageDetailActions.bottomInset(context) +
        ImageDetailActions.height +
        AppToast.barGap;
    return (String message) =>
        AppToast.show(overlay, message, bottomOffset: bottomOffset);
  }

  /// A guest is offered sign-in first; if they come back signed in, the
  /// tap that started it all is honoured and the image is saved without
  /// asking again. Backing out of the auth screen saves nothing.
  Future<void> _onFavouriteTap(BuildContext context) async {
    final toast = _toaster(context);
    final auth = Get.find<AuthController>();
    if (!auth.state.value.isAuthenticated) {
      if (!await GuestFavouriteSheet.show(context)) return;
      await Get.toNamed<void>(AppRoutes.auth);
      if (!auth.state.value.isAuthenticated) return;
      // `add`, not `toggle`: the intent was to save, and an image this
      // account already holds must stay saved.
      if (!await _favorites.add(image)) {
        toast(FavoritesView.writeErrorMessage);
      }
      return;
    }
    if (!await _favorites.toggle(image)) {
      toast(FavoritesView.writeErrorMessage);
    }
  }

  Future<void> _onDownloadTap(BuildContext context) async {
    final toast = _toaster(context);
    final status = await controller.saveToPhotos(image);
    switch (status) {
      case DownloadSaved():
        toast(savedToPhotos);
      case DownloadFailed(:final error):
        toast(switch (error) {
          ImageDownloadOfflineException() => downloadOffline,
          ImageDownloadAccessDeniedException() => downloadDenied,
          ImageDownloadFailedException() => downloadFailed,
        });
      case DownloadIdle() || DownloadSaving():
        break;
    }
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
          Obx(
            () => ImageDetailActions(
              saved: _favorites.isFavorite(image.id),
              downloading: controller.isSaving,
              onFavouriteTap: () => unawaited(_onFavouriteTap(context)),
              onDownloadTap: () => unawaited(_onDownloadTap(context)),
            ),
          ),
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
        child: StateView(
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
