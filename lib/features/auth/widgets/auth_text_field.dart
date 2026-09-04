import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.focusNode,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
    this.hintBelow,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  final String? hintBelow;

  static const double focusedRule = 1.5;
  static const double restingRule = 1;

  @override
  Widget build(BuildContext context) {
    final hintBelow = this.hintBelow;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(label.toUpperCase(), style: AppTypography.fieldLabel),
        ListenableBuilder(
          listenable: focusNode,
          builder: (BuildContext context, Widget? child) {
            final focused = focusNode.hasFocus;
            final rule = focused ? focusedRule : restingRule;
            return Container(
              padding: EdgeInsets.only(
                top: 10,
                bottom: 10 + (focusedRule - rule),
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: focused ? AppColors.ink : AppColors.rule50,
                    width: rule,
                  ),
                ),
              ),
              child: child,
            );
          },
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            autofillHints: autofillHints,
            autocorrect: !obscureText,
            enableSuggestions: !obscureText,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            style: AppTypography.input,
            cursorColor: AppColors.ink,
            decoration: InputDecoration.collapsed(
              hintText: hint,
              hintStyle: AppTypography.input.copyWith(color: AppColors.text56),
            ),
          ),
        ),
        if (hintBelow != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(hintBelow, style: AppTypography.fieldHint),
          ),
      ],
    );
  }
}
