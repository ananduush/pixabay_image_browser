import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/filled_pill_button.dart';
import '../../../core/widgets/glass_surface.dart';

/// Glass sheet over Image Details when a guest taps "Save to favourites".
/// "Sign in" closes the sheet and opens the auth screen; "Not now" closes it.
class GuestFavouriteSheet extends StatelessWidget {
  const GuestFavouriteSheet({super.key});

  static const String title = 'Sign in to save this image';
  static const String body =
      'Favourites live on this device, so they open instantly and work '
      'offline. Browsing and search stay open to everyone.';
  static const String signInLabel = 'Sign in';
  static const String dismissLabel = 'Not now';

  static const double margin = 12;

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      barrierColor: AppColors.scrim,
      backgroundColor: Colors.transparent,
      elevation: 0,
      // content-sized: never capped at the default fraction of the screen
      isScrollControlled: true,
      builder: (BuildContext context) => const GuestFavouriteSheet(),
    );
  }

  void _signIn(BuildContext context) {
    Navigator.of(context).pop();
    Get.toNamed<void>(AppRoutes.auth);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(margin),
      child: GlassSurface(
        borderRadius: 30,
        blurSigma: 34,
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.handle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(title, style: AppTypography.sheetTitle),
            const SizedBox(height: 9),
            Text(body, style: AppTypography.sheetBody),
            const SizedBox(height: 22),
            FilledPillButton(
              label: signInLabel,
              height: 54,
              onPressed: () => _signIn(context),
            ),
            const SizedBox(height: 8),
            Semantics(
              button: true,
              label: dismissLabel,
              excludeSemantics: true,
              child: GestureDetector(
                onTap: Navigator.of(context).pop,
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  height: 48,
                  child: Center(
                    child: Text(
                      dismissLabel,
                      style: AppTypography.sheetDismiss,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
