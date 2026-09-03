import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// "N images · for “query”" line above search results.
class GallerySearchResultsHeader extends StatelessWidget {
  const GallerySearchResultsHeader({
    super.key,
    required this.totalHits,
    required this.query,
  });

  final int totalHits;
  final String query;

  static String countLabel(int count) =>
      count == 1 ? '1 image' : '$count images';

  static String queryLabel(String query) => 'for “$query”';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.xl,
        AppSpacing.gutter,
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        spacing: AppSpacing.sm,
        children: <Widget>[
          Text(countLabel(totalHits), style: AppTypography.resultCount),
          Expanded(
            child: Text(
              queryLabel(query),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.resultQuery,
            ),
          ),
        ],
      ),
    );
  }
}
