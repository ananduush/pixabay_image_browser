import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Category row from the design. Static for now — the feed is always
/// "Editor's picks" until category browsing exists.
class GalleryChips extends StatelessWidget {
  const GalleryChips({super.key});

  static const List<String> labels = <String>[
    "Editor's picks",
    'Nature',
    'Interiors',
    'People',
    'Abstract',
  ];

  @override
  Widget build(BuildContext context) {
    // The row is wider than a 320–375pt screen minus the gutters, so it
    // scrolls horizontally instead of overflowing.
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        child: Row(
          spacing: 20,
          children: <Widget>[
            for (final (index, label) in labels.indexed)
              _Chip(label: label, active: index == 0),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      maxLines: 1,
      softWrap: false,
      style: AppTypography.chip(active: active),
    );
    if (!active) return text;
    return Container(
      padding: const EdgeInsets.only(bottom: 3),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.ink)),
      ),
      child: text,
    );
  }
}
