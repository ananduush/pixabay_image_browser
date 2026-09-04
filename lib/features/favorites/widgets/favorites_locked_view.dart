import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/filled_pill_button.dart';
import '../../../core/widgets/state_view.dart';

/// Shown only if the session ends while Favourites is on screen; a guest
/// tapping the tab is sent to sign in instead.
class FavoritesLockedView extends StatelessWidget {
  const FavoritesLockedView({super.key});

  static const String title = 'Favourites need an account';
  static const String body =
      'Sign in and every image you save stays on this device — no sync, no '
      'sharing, available offline.';
  static const String signInLabel = 'Sign in';

  static const double topPadding = 96;

  @override
  Widget build(BuildContext context) {
    return StateView(
      glyph: const Icon(Icons.lock_outline, size: 30, color: AppColors.ink),
      title: title,
      body: body,
      topPadding: topPadding,
      children: <Widget>[
        const SizedBox(height: AppSpacing.xl),
        FilledPillButton(
          label: signInLabel,
          height: 52,
          onPressed: () => Get.toNamed<void>(AppRoutes.auth),
        ),
      ],
    );
  }
}
