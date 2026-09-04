import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'glass_surface.dart';

/// The three destinations in the floating pill.
enum AppTab { explore, favourites, profile }

/// Floating glass pill with the Explore / Favourites / Profile tabs. Every
/// tab reports its tap; what a tap does belongs to the shell.
class GlassTabBar extends StatelessWidget {
  const GlassTabBar({super.key, required this.active, required this.onTap});

  final AppTab active;
  final ValueChanged<AppTab> onTap;

  /// Design offset from the physical bottom edge, home indicator included.
  static const double designBottomInset = 40;

  static const String exploreLabel = 'Explore';
  static const String exploreActiveLabel = 'Explore, scroll to top';
  static const String favouritesLabel = 'Favourites';
  static const String profileLabel = 'Profile';

  static String labelFor(AppTab tab, {required bool active}) => switch (tab) {
    AppTab.explore => active ? exploreActiveLabel : exploreLabel,
    AppTab.favourites => favouritesLabel,
    AppTab.profile => profileLabel,
  };

  static IconData iconFor(AppTab tab) => switch (tab) {
    AppTab.explore => Icons.grid_view_outlined,
    AppTab.favourites => Icons.favorite_outline,
    AppTab.profile => Icons.person_outline,
  };

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
              for (final tab in AppTab.values)
                _Tab(tab: tab, active: tab == active, onTap: () => onTap(tab)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.tab, required this.active, required this.onTap});

  final AppTab tab;
  final bool active;
  final VoidCallback onTap;

  static const double size = 54;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: GlassTabBar.labelFor(tab, active: active),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox.square(
          dimension: size,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? AppColors.ink : Colors.transparent,
            ),
            child: Center(
              child: Icon(
                GlassTabBar.iconFor(tab),
                size: 19,
                color: active ? AppColors.paper : AppColors.text44,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
