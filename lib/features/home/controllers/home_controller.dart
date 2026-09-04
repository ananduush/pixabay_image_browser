import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/glass_tab_bar.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/controllers/auth_state.dart';
import '../../gallery/controllers/gallery_controller.dart';

/// Which tab the shell shows. Explore and Profile stay mounted side by side,
/// so switching never rebuilds or refetches the feed.
class HomeController extends GetxController {
  HomeController({required this._auth, required this._gallery});

  final AuthController _auth;
  final GalleryController _gallery;

  final Rx<AppTab> tab = Rx<AppTab>(AppTab.explore);

  /// Position in the shell's stack; Favourites has no page yet.
  int get stackIndex => switch (tab.value) {
    AppTab.explore || AppTab.favourites => 0,
    AppTab.profile => 1,
  };

  void onTabTap(AppTab tapped) {
    switch (tapped) {
      case AppTab.explore:
        // Re-tapping the active tab returns to the header.
        if (tab.value == AppTab.explore) {
          _gallery.scrollToTop();
        } else {
          tab.value = AppTab.explore;
        }
      case AppTab.profile:
        tab.value = AppTab.profile;
      case AppTab.favourites:
        _openFavourites();
    }
  }

  /// Favourites need an account: guests go straight to sign in and the tab
  /// stays where it was. Signed-in users wait for the Favourites slice.
  void _openFavourites() {
    switch (_auth.state.value) {
      case AuthGuest() || AuthFailed() || AuthUnavailable():
        Get.toNamed<void>(AppRoutes.auth);
      case AuthRestoring() || AuthAuthenticating() || AuthAuthenticated():
        break;
    }
  }
}
