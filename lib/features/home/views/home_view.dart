import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_tab_bar.dart';
import '../../auth/views/profile_view.dart';
import '../../favorites/views/favorites_view.dart';
import '../../gallery/views/gallery_view.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final keyboardUp = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      backgroundColor: AppColors.paper,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Obx(() {
              final tab = controller.tab.value;
              // Offstage tabs stay mounted (that is what preserves their
              // state), but the hero scan still walks them, so only the
              // visible grid may offer heroes: Explore and Favourites can
              // show the same photo, and one tag per route is the rule.
              return IndexedStack(
                index: controller.stackIndex,
                children: <Widget>[
                  HeroMode(
                    enabled: tab == AppTab.explore,
                    child: const GalleryView(),
                  ),
                  HeroMode(
                    enabled: tab == AppTab.favourites,
                    child: const FavoritesView(),
                  ),
                  const ProfileView(),
                ],
              );
            }),
          ),
          if (!keyboardUp)
            Obx(
              () => GlassTabBar(
                active: controller.tab.value,
                onTap: controller.onTabTap,
              ),
            ),
        ],
      ),
    );
  }
}
