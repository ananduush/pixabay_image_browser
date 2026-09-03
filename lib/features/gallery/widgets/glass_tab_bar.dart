import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_surface.dart';

/// Floating glass pill with the Explore / Favourites / Profile tabs.
/// The active tab scrolls the feed to the top; inactive tabs are still
/// non-functional visuals.
class GlassTabBar extends StatelessWidget {
  const GlassTabBar({super.key, required this.activeIndex, this.onActiveTap});

  final int activeIndex;
  final VoidCallback? onActiveTap;

  /// Design offset from the physical bottom edge, home indicator included.
  static const double designBottomInset = 40;

  static const String activeTabLabel = 'Explore, scroll to top';

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return Positioned(
      left: 0,
      right: 0,
      bottom: math.max(designBottomInset, safeBottom + 6),
      child: Center(
        child: GlassSurface(
          borderRadius: 33,
          padding: const EdgeInsets.all(6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: <Widget>[
              _Tab(
                active: activeIndex == 0,
                icon: Icons.grid_view_outlined,
                onTap: onActiveTap,
              ),
              _Tab(
                active: activeIndex == 1,
                icon: Icons.favorite_outline,
                onTap: onActiveTap,
              ),
              _Tab(
                active: activeIndex == 2,
                icon: Icons.person_outline,
                onTap: onActiveTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.active, required this.icon, this.onTap});

  final bool active;
  final IconData icon;
  final VoidCallback? onTap;

  static const double size = 54;

  @override
  Widget build(BuildContext context) {
    final tab = SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? AppColors.ink : Colors.transparent,
        ),
        child: Center(
          child: Icon(
            icon,
            size: 19,
            color: active ? AppColors.paper : AppColors.text44,
          ),
        ),
      ),
    );
    if (active) {
      return Semantics(
        button: true,
        label: GlassTabBar.activeTabLabel,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: tab,
        ),
      );
    }
    return AbsorbPointer(child: tab);
  }
}
