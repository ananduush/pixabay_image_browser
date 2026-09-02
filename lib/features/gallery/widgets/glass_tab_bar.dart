import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_surface.dart';
import '../../../core/widgets/glyphs.dart';

/// Floating glass pill with the Explore / Favourites / Profile tabs.
/// Navigation between tabs arrives with those features; for now the pill
/// only shows the active tab and absorbs taps so the feed beneath does not
/// receive them.
class GlassTabBar extends StatelessWidget {
  const GlassTabBar({super.key, required this.activeIndex});

  final int activeIndex;

  /// Design offset from the physical bottom edge, home indicator included.
  static const double designBottomInset = 40;

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return Positioned(
      left: 0,
      right: 0,
      bottom: math.max(designBottomInset, safeBottom + 6),
      child: Center(
        child: AbsorbPointer(
          child: GlassSurface(
            borderRadius: 33,
            padding: const EdgeInsets.all(6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 6,
              children: <Widget>[
                _Tab(
                  active: activeIndex == 0,
                  builder: (Color color) => Glyph.grid(color: color),
                ),
                _Tab(
                  active: activeIndex == 1,
                  builder: (Color color) => Glyph.heart(color: color),
                ),
                _Tab(
                  active: activeIndex == 2,
                  builder: (Color color) => Glyph.person(color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.active, required this.builder});

  final bool active;
  final Widget Function(Color color) builder;

  static const double size = 54;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? AppColors.ink : Colors.transparent,
        ),
        child: Center(
          child: builder(active ? AppColors.paper : AppColors.text44),
        ),
      ),
    );
  }
}
