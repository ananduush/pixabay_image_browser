import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Outlined pill — the design's secondary action ("Try again", "Log out").
/// A null [onPressed] disables it.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = defaultHeight,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;

  static const double defaultHeight = 48;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const StadiumBorder(side: BorderSide(color: AppColors.rule50)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: Center(
              widthFactor: 1,
              child: Text(label, style: AppTypography.button),
            ),
          ),
        ),
      ),
    );
  }
}
