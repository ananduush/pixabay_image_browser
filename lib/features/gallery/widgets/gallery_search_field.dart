import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// The search row from the design: glyph, borderless input on a bottom
/// rule, a round clear pill while there is text, and "Cancel" while the
/// keyboard is up.
///
/// Text and focus both live in controller-owned objects ([controller],
/// [focusNode]) so search logic can drive the field and dismiss the
/// keyboard from any exit.
class GallerySearchField extends StatelessWidget {
  const GallerySearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.onCancel,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  /// The clear pill: empties the query, keeps the keyboard.
  final VoidCallback onClear;

  /// Cancel: empties the query and dismisses the keyboard.
  final VoidCallback onCancel;

  static const String placeholder = 'Search a subject, a mood, a colour';
  static const String cancelLabel = 'Cancel';

  /// Accessibility label of the clear pill.
  static const String clearLabel = 'Clear search';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        20,
        AppSpacing.gutter,
        0,
      ),
      child: ListenableBuilder(
        listenable: Listenable.merge(<Listenable>[controller, focusNode]),
        builder: (BuildContext context, Widget? child) {
          final hasText = controller.text.isNotEmpty;
          return Row(
            spacing: 12,
            children: <Widget>[
              Expanded(
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
                        child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          onChanged: onChanged,
                          onSubmitted: onSubmitted,
                          textInputAction: TextInputAction.search,
                          style: AppTypography.body,
                          cursorColor: AppColors.ink,
                          decoration: InputDecoration.collapsed(
                            hintText: GallerySearchField.placeholder,
                            hintStyle: AppTypography.body.copyWith(
                              color: AppColors.text56,
                            ),
                          ),
                        ),
                      ),
                      if (hasText) _ClearPill(onTap: onClear),
                    ],
                  ),
                ),
              ),
              if (focusNode.hasFocus)
                Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: GestureDetector(
                    onTap: onCancel,
                    behavior: HitTestBehavior.opaque,
                    child: Text(
                      GallerySearchField.cancelLabel,
                      style: AppTypography.cancel,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// 20px round "×" that clears the query.
class _ClearPill extends StatelessWidget {
  const _ClearPill({required this.onTap});

  final VoidCallback onTap;

  static const double size = 20;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: GallerySearchField.clearLabel,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: AppColors.inkFill9,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close, size: 12, color: AppColors.ink),
        ),
      ),
    );
  }
}
