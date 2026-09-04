import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/filled_pill_button.dart';
import '../../../core/widgets/glass_surface.dart';

class GuestFavouriteSheet extends StatelessWidget {
  const GuestFavouriteSheet({super.key});

  static const String title = 'Sign in to save this image';
  static const String body =
      'Favourites live on this device, so they open instantly and work '
      'offline. Browsing and search stay open to everyone.';
  static const String signInLabel = 'Sign in';
  static const String dismissLabel = 'Not now';

  static const double margin = 12;

  /// Resolves true when the user chose [signInLabel]; false for "Not now",
  /// the scrim, or a swipe down. The caller owns what happens next, so it
  /// can also finish whatever the guest was trying to do once signed in.
  static Future<bool> show(BuildContext context) async {
    final choice = await showModalBottomSheet<bool>(
      context: context,
      barrierColor: AppColors.scrim,
      backgroundColor: Colors.transparent,
      elevation: 0,
      isScrollControlled: true,
      builder: (BuildContext context) => const GuestFavouriteSheet(),
    );
    return choice ?? false;
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
              onPressed: () => Navigator.of(context).pop(true),
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
