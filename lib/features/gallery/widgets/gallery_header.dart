import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// "Aperture" wordmark with a small uppercase label on the right.
class GalleryHeader extends StatelessWidget {
  const GalleryHeader({super.key, this.trailingLabel});

  final String? trailingLabel;

  @override
  Widget build(BuildContext context) {
    final label = trailingLabel;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.md,
        AppSpacing.gutter,
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text('Aperture', style: AppTypography.brand),
          if (label != null)
            Text(label.toUpperCase(), style: AppTypography.headerLabel),
        ],
      ),
    );
  }
}
