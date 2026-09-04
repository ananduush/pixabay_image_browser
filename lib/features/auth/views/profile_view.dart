import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/filled_pill_button.dart';
import '../../../core/widgets/pill_button.dart';
import '../../favorites/controllers/favorites_controller.dart';
import '../../home/controllers/home_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/auth_state.dart';
import '../models/auth_user.dart';
import '../services/auth_exception.dart';
import '../widgets/profile_identity.dart';
import '../widgets/profile_rows.dart';

class ProfileView extends GetView<AuthController> {
  const ProfileView({super.key});

  static const String title = 'Profile';

  static const String guestHeading = 'Browsing works without an account.';
  static const String guestBody =
      'Signing in adds one thing: Favourites. Saved images are written to '
      'this device only, so they open instantly and work offline.';
  static const String signInLabel = 'Sign in';

  static const String logOutLabel = 'Log out';
  static const String loggingOutLabel = 'Logging out';

  static const String unavailableHeading = 'Accounts are not configured';

  static const String sourceLabel = 'Image source';
  static const String sourceValue = 'Pixabay';
  static const String versionLabel = 'Version';

  static const String version = '1.0.0';

  static const String savedImagesLabel = 'Saved images';

  /// Shown until the favourites list has loaded.
  static const String savedImagesUnknown = '—';

  static const String logoutFootnote =
      'Logging out keeps your saved images on the device.';

  static const double bottomSpacer = 130;

  FavoritesController get _favorites => Get.find<FavoritesController>();

  static String savedImagesValue(int? count) =>
      count?.toString() ?? savedImagesUnknown;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.md,
            AppSpacing.gutter,
            bottomSpacer,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(title, style: AppTypography.sectionTitle),
              Obx(
                () => switch (controller.state.value) {
                  AuthRestoring() => const SizedBox.shrink(),
                  AuthAuthenticated(:final user, :final signingOut) =>
                    _SignedIn(
                      user: user,
                      signingOut: signingOut,
                      // read inside this Obx so the row tracks the count
                      savedImages: savedImagesValue(_favorites.count),
                      onSavedImagesTap:
                          Get.find<HomeController>().showFavourites,
                      onLogOut: controller.signOut,
                    ),
                  AuthUnavailable(:final error) => _Unavailable(error: error),
                  AuthGuest() ||
                  AuthAuthenticating() ||
                  AuthFailed() => const _Guest(),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Guest extends StatelessWidget {
  const _Guest();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(ProfileView.guestHeading, style: AppTypography.profileHeading),
          const SizedBox(height: 12),
          Text(ProfileView.guestBody, style: AppTypography.lead),
          const SizedBox(height: AppSpacing.xl),
          FilledPillButton(
            label: ProfileView.signInLabel,
            onPressed: () => Get.toNamed<void>(AppRoutes.auth),
          ),
          const SizedBox(height: AppSpacing.xxl),
          const _AboutRows(),
        ],
      ),
    );
  }
}

class _SignedIn extends StatelessWidget {
  const _SignedIn({
    required this.user,
    required this.signingOut,
    required this.savedImages,
    required this.onSavedImagesTap,
    required this.onLogOut,
  });

  final AuthUser user;
  final bool signingOut;
  final String savedImages;
  final VoidCallback onSavedImagesTap;
  final VoidCallback onLogOut;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ProfileIdentity(user: user),
          const SizedBox(height: 30),
          ProfileRows(
            children: <ProfileRow>[
              ProfileRow(
                label: ProfileView.savedImagesLabel,
                value: savedImages,
                onTap: onSavedImagesTap,
              ),
              ..._AboutRows.rows,
            ],
          ),
          const SizedBox(height: 30),
          PillButton(
            label: signingOut
                ? ProfileView.loggingOutLabel
                : ProfileView.logOutLabel,
            height: 52,
            onPressed: signingOut ? null : onLogOut,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            ProfileView.logoutFootnote,
            textAlign: TextAlign.center,
            style: AppTypography.footnote,
          ),
        ],
      ),
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.error});

  final AuthMissingConfigException error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            ProfileView.unavailableHeading,
            style: AppTypography.profileHeading,
          ),
          const SizedBox(height: 12),
          Text(error.message, style: AppTypography.mono(11)),
          const SizedBox(height: AppSpacing.xxl),
          const _AboutRows(),
        ],
      ),
    );
  }
}

class _AboutRows extends StatelessWidget {
  const _AboutRows();

  static const List<ProfileRow> rows = <ProfileRow>[
    ProfileRow(label: ProfileView.sourceLabel, value: ProfileView.sourceValue),
    ProfileRow(label: ProfileView.versionLabel, value: ProfileView.version),
  ];

  @override
  Widget build(BuildContext context) {
    return const ProfileRows(children: rows);
  }
}
