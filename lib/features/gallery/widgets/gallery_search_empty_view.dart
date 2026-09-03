import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'gallery_state_view.dart';

/// zero-hit search state
class GallerySearchEmptyView extends StatelessWidget {
  const GallerySearchEmptyView({
    super.key,
    required this.query,
    required this.onSuggestion,
    required this.onBack,
  });

  final String query;
  final ValueChanged<String> onSuggestion;
  final VoidCallback onBack;

  static String title(String query) => 'Nothing for “$query”';
  static const String body =
      'Pixabay has no images under that word. Shorter or plainer terms '
      'usually land better.';
  static const List<String> suggestions = <String>[
    'fog',
    'ceramic',
    'desert',
    'portrait',
    'coast',
  ];
  static const String backLabel = 'Back to browsing';

  @override
  Widget build(BuildContext context) {
    return GalleryStateView(
      glyph: const Icon(Icons.search_off, size: 36, color: AppColors.rule35),
      title: title(query),
      body: body,
      topPadding: 96,
      children: <Widget>[
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.center,
          children: <Widget>[
            for (final term in suggestions)
              _SuggestionPill(term: term, onTap: () => onSuggestion(term)),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        GestureDetector(
          onTap: onBack,
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
                child: Text(backLabel, style: AppTypography.link),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SuggestionPill extends StatelessWidget {
  const _SuggestionPill({required this.term, required this.onTap});

  final String term;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.inkFill55,
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.chip)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Text(term, style: AppTypography.suggestion),
        ),
      ),
    );
  }
}
