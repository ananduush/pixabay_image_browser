import 'dart:async';

import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/glass_tab_bar.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/controllers/auth_state.dart';
import '../../gallery/controllers/gallery_controller.dart';

class HomeController extends GetxController {
  HomeController({required this._auth, required this._gallery});

  final AuthController _auth;
  final GalleryController _gallery;

  final Rx<AppTab> tab = Rx<AppTab>(AppTab.explore);

  StreamSubscription<AuthState>? _authSubscription;

  /// A guest asked for Favourites and was sent to sign in. If they come
  /// back signed in, land them there; if they back out, forget it.
  bool _favouritesPending = false;

  /// Who was signed in at the last auth event; a change to null is a
  /// sign-out.
  String? _userId;

  int get stackIndex => switch (tab.value) {
    AppTab.explore => 0,
    AppTab.favourites => 1,
    AppTab.profile => 2,
  };

  @override
  void onInit() {
    super.onInit();
    _authSubscription = _auth.state.listen(_onAuthChanged);
    _userId = _auth.state.value.user?.id;
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    super.onClose();
  }

  void onTabTap(AppTab tapped) {
    switch (tapped) {
      case AppTab.explore:
        if (tab.value == AppTab.explore) {
          _gallery.scrollToTop();
        } else {
          showExplore();
        }
      case AppTab.profile:
        _favouritesPending = false;
        tab.value = AppTab.profile;
      case AppTab.favourites:
        _openFavourites();
    }
  }

  void showExplore() {
    _favouritesPending = false;
    tab.value = AppTab.explore;
  }

  void showFavourites() {
    tab.value = AppTab.favourites;
  }

  void _openFavourites() {
    switch (_auth.state.value) {
      case AuthGuest() || AuthFailed() || AuthUnavailable():
        _favouritesPending = true;
        unawaited(
          Get.toNamed<void>(
            AppRoutes.auth,
          )?.whenComplete(() => _favouritesPending = false),
        );
      case AuthAuthenticated():
        tab.value = AppTab.favourites;
      case AuthRestoring() || AuthAuthenticating():
        break;
    }
  }

  void _onAuthChanged(AuthState state) {
    final userId = state.user?.id;
    final signedOut = _userId != null && userId == null;
    _userId = userId;
    if (signedOut) _resetExplore();
    if (!_favouritesPending || state is! AuthAuthenticated) return;
    _favouritesPending = false;
    tab.value = AppTab.favourites;
  }

  /// A search belongs to the session that ran it. Signing out returns
  /// Explore to the curated feed at the top so the next person on the
  /// device does not inherit the previous account's query.
  void _resetExplore() {
    _gallery.cancelSearch();
    _gallery.scrollToTop();
  }
}
