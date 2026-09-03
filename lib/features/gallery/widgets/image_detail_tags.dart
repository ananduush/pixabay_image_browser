import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Pixabay's tags as wrapping chips. Tapping one searches for it.
class ImageDetailTags extends StatelessWidget {
  const ImageDetailTags({super.key, required this.tags, this.onTagTap});

  final List<String> tags;
  final ValueChanged<String>? onTagTap;

  static String tagLabel(String tag) => 'Search $tag';

  /// Pixabay often repeats a tag ("woman, woman, portrait"); one chip each,
  /// first spelling wins, order kept.
  static List<String> uniqueTags(List<String> tags) {
    final seen = <String>{};
    return <String>[
      for (final tag in tags)
        if (seen.add(tag.toLowerCase())) tag,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final chips = uniqueTags(tags);
    if (chips.isEmpty) return const SizedBox.shrink();
    final onTagTap = this.onTagTap;
    return Wrap(
      spacing: AppSpacing.gridGap,
      runSpacing: AppSpacing.gridGap,
      children: <Widget>[
        for (final tag in chips)
          _TagChip(
            tag: tag,
            onTap: onTagTap == null ? null : () => onTagTap(tag),
          ),
      ],
    );
  }
}

/// ~29pt tall as designed — a secondary target, so it sits below the 44pt
/// rule that the icon-only controls follow.
class _TagChip extends StatelessWidget {
  const _TagChip({required this.tag, this.onTap});

  final String tag;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: ImageDetailTags.tagLabel(tag),
      // "Search fog" replaces the bare chip text for screen readers
      excludeSemantics: true,
      child: Material(
        color: AppColors.inkFill55,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.chip)),
          side: BorderSide(color: AppColors.chipBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            // Wrap bounds each chip to the row width, so an absurd tag is
            // ellipsised on its own line instead of overflowing.
            child: Text(
              tag,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.tag,
            ),
          ),
        ),
      ),
    );
  }
}
