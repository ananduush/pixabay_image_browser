import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_tab_bar.dart';
import '../../auth/views/profile_view.dart';
import '../../gallery/views/gallery_view.dart';
import '../controllers/home_controller.dart';

/// Tabbed shell: Explore and Profile kept alive in an [IndexedStack] under
/// the floating glass pill. The pill hides while the keyboard is up.
class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final keyboardUp = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      backgroundColor: AppColors.paper,
      // each tab's own Scaffold handles the keyboard, exactly as before
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Obx(
              () => IndexedStack(
                index: controller.stackIndex,
                children: const <Widget>[GalleryView(), ProfileView()],
              ),
            ),
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
