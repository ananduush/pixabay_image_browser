import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_surface.dart';

/// 44pt glass circle with a single glyph — the design's floating back and
/// close controls over a photograph.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconSize = 15,
  });

  final IconData icon;

  /// Semantics label; the button has no visible text.
  final String label;
  final VoidCallback onTap;
  final double iconSize;

  static const double size = 44;

  static const String backLabel = 'Back';
  static const String closeLabel = 'Close';

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox.square(
          dimension: size,
          child: GlassSurface(
            borderRadius: size / 2,
            child: Center(
              child: Icon(icon, size: iconSize, color: AppColors.ink),
            ),
          ),
        ),
      ),
    );
  }
}
