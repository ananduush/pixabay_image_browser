import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../controllers/gallery_controller.dart';
import '../controllers/gallery_state.dart';
import '../models/pixabay_image.dart';
import '../widgets/gallery_chips.dart';
import '../widgets/gallery_error_view.dart';
import '../widgets/gallery_feed_footer.dart';
import '../widgets/gallery_header.dart';
import '../widgets/gallery_image_group.dart';
import '../widgets/gallery_refresh_pill.dart';
import '../widgets/gallery_search_empty_view.dart';
import '../widgets/gallery_search_field.dart';
import '../widgets/gallery_search_results_header.dart';
import '../widgets/gallery_searching_view.dart';
import '../widgets/gallery_skeleton.dart';
import '../widgets/glass_tab_bar.dart';

/// Explore tab: the Pixabay feed in the Aperture layout.
class GalleryView extends GetView<GalleryController> {
  const GalleryView({super.key});

  static const String headerLabel = 'Pixabay';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Obx(
                () => _Body(
                  state: controller.state.value,
                  controller: controller,
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: IgnorePointer(
                child: Obx(
                  () => switch (controller.state.value) {
                    GalleryLoaded(status: FeedRefreshing()) => const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Center(child: GalleryRefreshPill()),
                    ),
                    _ => const SizedBox.shrink(),
                  },
                ),
              ),
            ),
          ),
          GlassTabBar(activeIndex: 0, onActiveTap: controller.scrollToTop),
        ],
      ),
    );
  }
}

// header + search field stay in the first sliver so the text field
// keeps focus across state changes
class _Body extends StatelessWidget {
  const _Body({required this.state, required this.controller});

  final GalleryState state;
  final GalleryController controller;

  @override
  Widget build(BuildContext context) {
    final state = this.state;
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        // depth 0 is the feed itself; the chips row scrolls too
        if (notification.depth != 0) return false;
        final dragging = switch (notification) {
          ScrollStartNotification(:final dragDetails) => dragDetails != null,
          ScrollUpdateNotification(:final dragDetails) => dragDetails != null,
          OverscrollNotification(:final dragDetails) => dragDetails != null,
          ScrollEndNotification() => false,
          _ => null,
        };
        if (dragging != null) controller.onUserDrag(dragging: dragging);
        return false;
      },
      child: CustomScrollView(
        controller: controller.scrollController,
        // scrolling the results drops the keyboard
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        // scrolling the results drops the keyboard
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: <Widget>[
          CupertinoSliverRefreshControl(
            onRefresh: controller.refreshFromPull,
            refreshTriggerPullDistance: 64,
            refreshIndicatorExtent: 0,
            builder: GalleryPullHint.builder,
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                GalleryHeader(
                  trailingLabel: state is GalleryFailure
                      ? null
                      : GalleryView.headerLabel,
                ),
                GallerySearchField(
                  controller: controller.searchController,
                  focusNode: controller.searchFocus,
                  onChanged: controller.onQueryChanged,
                  onSubmitted: controller.search,
                  onClear: controller.clearSearch,
                  onCancel: controller.cancelSearch,
                ),
                if (state case GalleryLoaded(isSearch: false))
                  const GalleryChips(),
              ],
            ),
          ),
          ...switch (state) {
            GalleryLoading(isSearch: false) => const <Widget>[
              SliverToBoxAdapter(child: GallerySkeleton()),
            ],
            GalleryLoading(:final query) => <Widget>[
              SliverToBoxAdapter(child: GallerySearchingView(query: query)),
            ],
            GalleryLoaded(images: <PixabayImage>[], :final query)
                when query.isNotEmpty =>
              <Widget>[
                SliverToBoxAdapter(
                  child: GallerySearchEmptyView(
                    query: query,
                    onSuggestion: controller.search,
                    onBack: controller.cancelSearch,
                  ),
                ),
              ],
            GalleryLoaded(
              :final groups,
              :final query,
              :final totalHits,
              :final status,
              :final nextPage,
            ) =>
              <Widget>[
                if (query.isNotEmpty)
                  SliverToBoxAdapter(
                    child: GallerySearchResultsHeader(
                      totalHits: totalHits,
                      query: query,
                    ),
                  ),
                _GroupsSliver(
                  groups: groups,
                  underHeader: query.isNotEmpty,
                  onImageTap: (PixabayImage image) =>
                      _openImage(controller, image),
                ),
                SliverToBoxAdapter(
                  child: GalleryFeedFooter(
                    status: status,
                    nextPage: nextPage,
                    onRetry: controller.retryLoadMore,
                  ),
                ),
              ],
            GalleryFailure(:final error) => <Widget>[
              SliverToBoxAdapter(
                child: GalleryErrorView(
                  error: error,
                  onRetry: controller.retry,
                ),
              ),
            ],
          },
        ],
      ),
    );
  }
}

/// Drops the keyboard first: a focused field would otherwise take focus
/// back — and raise the keyboard — the moment Details pops.
void _openImage(GalleryController controller, PixabayImage image) {
  controller.searchFocus.unfocus();
  Get.toNamed<void>(AppRoutes.imageDetail, arguments: image);
}

class _GroupsSliver extends StatelessWidget {
  const _GroupsSliver({
    required this.groups,
    required this.underHeader,
    required this.onImageTap,
  });

  final List<List<PixabayImage>> groups;

  final bool underHeader;

  final ValueChanged<PixabayImage> onImageTap;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        underHeader ? AppSpacing.lg - 2 : AppSpacing.xl,
        AppSpacing.gutter,
        0,
      ),
      sliver: SliverList.separated(
        itemCount: groups.length,
        itemBuilder: (BuildContext context, int index) =>
            GalleryImageGroup(images: groups[index], onImageTap: onImageTap),
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(height: AppSpacing.lg),
      ),
    );
  }
}
