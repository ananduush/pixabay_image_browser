import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// spinner + caption while a search is in flight
class GallerySearchingView extends StatelessWidget {
  const GallerySearchingView({super.key, required this.query});

  final String query;

  static String message(String query) => 'Searching Pixabay for “$query”';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        120,
        AppSpacing.gutter,
        0,
      ),
      child: Column(
        spacing: AppSpacing.md,
        children: <Widget>[
          const SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(
              strokeWidth: 1.6,
              color: AppColors.ink,
              backgroundColor: AppColors.inkFill16,
            ),
          ),
          Text(
            message(query),
            textAlign: TextAlign.center,
            style: AppTypography.searchStatus,
          ),
        ],
      ),
    );
  }
}
