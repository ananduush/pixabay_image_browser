import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/pill_button.dart';

/// The design's local-storage error block: critical top rule, title, body
/// and an outlined Retry.
class FavoritesStorageErrorView extends StatelessWidget {
  const FavoritesStorageErrorView({super.key, required this.onRetry});

  final VoidCallback onRetry;

  static const String title = "Saved images couldn't be read";
  static const String body =
      'Local storage on this device refused the read. Your favourites are '
      'not lost — retrying usually clears it.';
  static const String retryLabel = 'Retry';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.xl,
        AppSpacing.gutter,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.critical),
            bottom: BorderSide(color: AppColors.rule9),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              spacing: 9,
              children: <Widget>[
                const Icon(
                  Icons.error_outline,
                  size: 15,
                  color: AppColors.critical,
                ),
                Expanded(child: Text(title, style: AppTypography.errorTitle)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(body, style: AppTypography.errorBody),
            const SizedBox(height: 16),
            PillButton(label: retryLabel, height: 44, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
