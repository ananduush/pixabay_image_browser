import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/glass_tab_bar.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/state_view.dart';
import '../../gallery/models/pixabay_image.dart';
import '../../home/controllers/home_controller.dart';
import '../controllers/favorites_controller.dart';
import '../controllers/favorites_state.dart';
import '../widgets/favorites_header.dart';
import '../widgets/favorites_locked_view.dart';
import '../widgets/favorites_storage_error_view.dart';
import '../widgets/favorites_tile.dart';

/// The Favourites tab. Everything it shows is local, so it renders with no
/// network; a saved image opens Details from the persisted model.
class FavoritesView extends GetView<FavoritesController> {
  const FavoritesView({super.key});

  static const String title = 'Favourites';
  static const String lockedLabel = 'Locked';
  static String countLabel(int count) => '$count saved';

  static const String emptyTitle = 'Nothing saved yet';
  static const String emptyBody =
      'Tap the heart on any image and it will wait for you here, even '
      'without a connection.';
  static const String browseLabel = 'Browse Explore';

  static const String writeErrorMessage = "Couldn't update saved images";

  static const double emptyTopPadding = 96;
  static const double gridGap = 8;

  /// Room under the grid so the floating pill never covers the last row.
  static const double bottomSpacer = 130;

  void _open(PixabayImage image) {
    Get.toNamed<void>(AppRoutes.imageDetail, arguments: image);
  }

  Future<void> _remove(BuildContext context, PixabayImage image) async {
    final overlay = Overlay.of(context, rootOverlay: true);
    final bottomOffset =
        GlassTabBar.bottomInset(context) + GlassTabBar.height + AppToast.barGap;
    if (!await controller.remove(image.id)) {
      AppToast.show(overlay, writeErrorMessage, bottomOffset: bottomOffset);
    }
  }

  String _label(FavoritesState state) => switch (state) {
    FavoritesLoaded(:final count) => countLabel(count),
    FavoritesInactive() => lockedLabel,
    FavoritesLoading() || FavoritesLoadFailed() => '',
  };

  Widget _body(BuildContext context, FavoritesState state) => switch (state) {
    FavoritesInactive() => const SliverToBoxAdapter(
      child: FavoritesLockedView(),
    ),
    FavoritesLoading() => const SliverToBoxAdapter(child: SizedBox.shrink()),
    FavoritesLoadFailed() => SliverToBoxAdapter(
      child: FavoritesStorageErrorView(onRetry: controller.retryLoad),
    ),
    FavoritesLoaded(:final images) when images.isEmpty => SliverToBoxAdapter(
      child: StateView(
        glyph: const Icon(
          Icons.favorite_outline,
          size: 34,
          color: AppColors.rule28,
        ),
        title: emptyTitle,
        body: emptyBody,
        topPadding: emptyTopPadding,
        children: <Widget>[
          const SizedBox(height: AppSpacing.xl),
          PillButton(
            label: browseLabel,
            height: 52,
            onPressed: Get.find<HomeController>().showExplore,
          ),
        ],
      ),
    ),
    FavoritesLoaded(:final images) => _Grid(
      // newest first
      images: images.reversed.toList(growable: false),
      onOpen: _open,
      onRemove: (PixabayImage image) => _remove(context, image),
    ),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          final state = controller.state.value;
          return CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: FavoritesHeader(title: title, label: _label(state)),
              ),
              _body(context, state),
            ],
          );
        }),
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({
    required this.images,
    required this.onOpen,
    required this.onRemove,
  });

  final List<PixabayImage> images;
  final ValueChanged<PixabayImage> onOpen;
  final ValueChanged<PixabayImage> onRemove;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.gutter,
        AppSpacing.gutter,
        FavoritesView.bottomSpacer,
      ),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: FavoritesView.gridGap,
          crossAxisSpacing: FavoritesView.gridGap,
        ),
        delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
          final image = images[index];
          return FavoritesTile(
            key: ValueKey<int>(image.id),
            image: image,
            onTap: () => onOpen(image),
            onRemove: () => onRemove(image),
          );
        }, childCount: images.length),
      ),
    );
  }
}
