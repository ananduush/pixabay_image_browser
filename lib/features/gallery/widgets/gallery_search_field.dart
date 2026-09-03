import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// The search affordance as drawn in the design. Search itself is a later
/// slice, so this is presentation only and ignores pointer input.
class GallerySearchField extends StatelessWidget {
  const GallerySearchField({super.key});

  static const String placeholder = 'Search a subject, a mood, a colour';

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          20,
          AppSpacing.gutter,
          0,
        ),
        child: Container(
          padding: const EdgeInsets.only(bottom: 9),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.rule50)),
          ),
          child: Row(
            spacing: 10,
            children: <Widget>[
              const Icon(Icons.search, size: 16, color: AppColors.ink),
              Expanded(
                child: Text(
                  placeholder,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(color: AppColors.text56),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
