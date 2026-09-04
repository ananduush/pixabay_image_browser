import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class FilledPillButton extends StatelessWidget {
  const FilledPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.busyLabel,
    this.enabled = true,
    this.height = defaultHeight,
    this.icon,
  });

  final String label;

  final VoidCallback? onPressed;

  final bool busy;

  final String? busyLabel;

  final bool enabled;
  final double height;

  /// Optional leading glyph (the Details "Saved to favourites" heart).
  final IconData? icon;

  static const double iconSize = 16;

  static const double defaultHeight = 56;
  static const double spinnerSize = 15;

  @override
  Widget build(BuildContext context) {
    final muted = !enabled && !busy;
    final text = busy ? (busyLabel ?? label) : label;
    final radius = BorderRadius.circular(height / 2);
    return Semantics(
      button: true,
      enabled: !busy,
      label: text,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: busy ? null : onPressed,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: radius,
            color: muted ? AppColors.paperFill32 : AppColors.inkButton,
            border: Border.all(
              color: muted ? AppColors.rule10 : AppColors.buttonBorder,
            ),
            boxShadow: muted
                ? null
                : const <BoxShadow>[
                    BoxShadow(
                      color: AppColors.buttonShadow,
                      offset: Offset(0, 10),
                      blurRadius: 30,
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              children: <Widget>[
                if (!muted)
                  const Positioned.fill(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: FractionallySizedBox(
                        heightFactor: 0.52,
                        widthFactor: 1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: <Color>[
                                AppColors.buttonGloss,
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 10,
                    children: <Widget>[
                      if (busy)
                        const SizedBox.square(
                          dimension: spinnerSize,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.6,
                            color: AppColors.paper,
                            backgroundColor: AppColors.paperFill35,
                          ),
                        ),
                      if (icon != null && !busy)
                        Icon(
                          icon,
                          size: iconSize,
                          color: muted ? AppColors.text32 : AppColors.paper,
                        ),
                      Text(
                        text,
                        style: muted
                            ? AppTypography.filledButtonDisabled
                            : AppTypography.filledButton,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
