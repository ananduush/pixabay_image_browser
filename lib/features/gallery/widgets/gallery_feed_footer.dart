import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../controllers/gallery_state.dart';

/// Below the last group: the next-page spinner, the retry link after a
/// failed page, or "End of results". Idle and refreshing feeds show nothing
/// but keep the 120px gap for the floating tab pill.
class GalleryFeedFooter extends StatelessWidget {
  const GalleryFeedFooter({
    super.key,
    required this.status,
    required this.nextPage,
    required this.onRetry,
  });

  final FeedStatus status;
  final int nextPage;
  final VoidCallback onRetry;

  static const double bottomSpacer = 120;

  static String pageLabel(int page) => 'Page $page';

  static const String endLabel = 'End of results';

  static String failedLabel(int page) => "Couldn't load page $page";

  static const String retryLabel = 'Try again';

  @override
  Widget build(BuildContext context) {
    final Widget? content = switch (status) {
      FeedLoadingMore() => Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 10,
        children: <Widget>[
          const SizedBox.square(
            dimension: 14,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: AppColors.ink,
              backgroundColor: AppColors.inkFill16,
            ),
          ),
          Text(
            pageLabel(nextPage).toUpperCase(),
            style: AppTypography.feedStatus,
          ),
        ],
      ),
      FeedEnd() => Text(
        endLabel.toUpperCase(),
        style: AppTypography.feedStatus,
      ),
      FeedLoadMoreFailed() => Column(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.sm,
        children: <Widget>[
          Text(
            failedLabel(nextPage).toUpperCase(),
            style: AppTypography.feedStatus,
          ),
          GestureDetector(
            onTap: onRetry,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              height: 44,
              child: Center(
                widthFactor: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 1,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.rule20)),
                  ),
                  child: Text(retryLabel, style: AppTypography.link),
                ),
              ),
            ),
          ),
        ],
      ),
      FeedIdle() || FeedRefreshing() => null,
    };
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        content == null ? 0 : AppSpacing.lg,
        AppSpacing.gutter,
        bottomSpacer,
      ),
      child: Center(child: content ?? const SizedBox.shrink()),
    );
  }
}
