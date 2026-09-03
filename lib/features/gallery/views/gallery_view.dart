import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../controllers/gallery_controller.dart';
import '../controllers/gallery_state.dart';
import '../models/pixabay_image.dart';
import '../services/pixabay_exception.dart';
import '../widgets/gallery_chips.dart';
import '../widgets/gallery_error_view.dart';
import '../widgets/gallery_header.dart';
import '../widgets/gallery_image_group.dart';
import '../widgets/gallery_search_field.dart';
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
                () => switch (controller.state.value) {
                  GalleryLoading() => const _LoadingBody(),
                  GalleryLoaded(:final groups) => _FeedBody(groups: groups),
                  GalleryFailure(:final error) => _FailureBody(
                    error: error,
                    onRetry: controller.loadImages,
                  ),
                },
              ),
            ),
          ),
          const GlassTabBar(activeIndex: 0),
        ],
      ),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          GalleryHeader(trailingLabel: GalleryView.headerLabel),
          GallerySearchField(),
          GallerySkeleton(),
        ],
      ),
    );
  }
}

class _FeedBody extends StatelessWidget {
  const _FeedBody({required this.groups});

  final List<List<PixabayImage>> groups;

  /// Room for the floating tab pill above the last group.
  static const double bottomSpacer = 120;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        const SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              GalleryHeader(trailingLabel: GalleryView.headerLabel),
              GallerySearchField(),
              GalleryChips(),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.xl,
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
        ),
      ],
    );
  }
}

class _FailureBody extends StatelessWidget {
  const _FailureBody({required this.error, required this.onRetry});

  final PixabayException error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const GalleryHeader(),
          GalleryErrorView(error: error, onRetry: onRetry),
        ],
      ),
    );
  }
}
