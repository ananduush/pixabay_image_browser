import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// "Aperture" wordmark with a small uppercase label on the right.
class GalleryHeader extends StatelessWidget {
  const GalleryHeader({super.key, this.trailingLabel, this.onTrailingTap});

  final String? trailingLabel;
  final VoidCallback? onTrailingTap;

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
            onTrailingTap != null
                ? GestureDetector(
                    onTap: onTrailingTap,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 6, 0, 6),
                      child: Text(
                        label.toUpperCase(),
                        style: AppTypography.headerLabel,
                      ),
                    ),
                  )
                : Text(label.toUpperCase(), style: AppTypography.headerLabel),
        ],
      ),
    );
  }
}
