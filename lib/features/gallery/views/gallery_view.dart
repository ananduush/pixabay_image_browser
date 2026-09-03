import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../controllers/gallery_controller.dart';
import '../controllers/gallery_state.dart';
import '../models/pixabay_image.dart';
import '../widgets/gallery_chips.dart';
import '../widgets/gallery_error_view.dart';
import '../widgets/gallery_header.dart';
import '../widgets/gallery_image_group.dart';
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
          const GlassTabBar(activeIndex: 0),
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
    return CustomScrollView(
      slivers: <Widget>[
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
          GalleryLoaded(:final groups, :final query, :final totalHits) =>
            <Widget>[
              if (query.isNotEmpty)
                SliverToBoxAdapter(
                  child: GallerySearchResultsHeader(
                    totalHits: totalHits,
                    query: query,
                  ),
                ),
              _GroupsSliver(groups: groups, underHeader: query.isNotEmpty),
            ],
          GalleryFailure(:final error) => <Widget>[
            SliverToBoxAdapter(
              child: GalleryErrorView(error: error, onRetry: controller.retry),
            ),
          ],
        },
      ],
    );
  }
}

class _GroupsSliver extends StatelessWidget {
  const _GroupsSliver({required this.groups, required this.underHeader});

  final List<List<PixabayImage>> groups;

  final bool underHeader;

  /// Room for the floating tab pill above the last group.
  static const double bottomSpacer = 120;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        underHeader ? AppSpacing.lg - 2 : AppSpacing.xl,
        AppSpacing.gutter,
        bottomSpacer,
      ),
      sliver: SliverList.separated(
        itemCount: groups.length,
        itemBuilder: (BuildContext context, int index) =>
            GalleryImageGroup(images: groups[index]),
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(height: AppSpacing.lg),
      ),
    );
  }
}
