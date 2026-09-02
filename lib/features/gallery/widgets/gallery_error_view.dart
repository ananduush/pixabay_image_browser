import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glyphs.dart';
import '../../../core/widgets/pill_button.dart';
import '../services/pixabay_exception.dart';

/// Full-screen failure states from the design: offline, API error and the
/// developer-facing missing-key screen.
class GalleryErrorView extends StatelessWidget {
  const GalleryErrorView({
    super.key,
    required this.error,
    required this.onRetry,
  });

  final PixabayException error;
  final VoidCallback onRetry;

  static const String offlineTitle = 'No connection';
  static const String offlineBody =
      'Pixabay needs the network. Your saved images are still available on '
      'the Favourites tab.';
  static const String apiTitle = "Pixabay didn't answer";
  static const String apiBody =
      'The image service returned an error. Nothing is wrong with your '
      'device.';
  static const String missingKeyTitle = 'API key missing';
  static const String retryLabel = 'Try again';

  @override
  Widget build(BuildContext context) {
    final (
      Widget glyph,
      String title,
      String body,
      String? detail,
      bool retry,
    ) = switch (error) {
      PixabayNetworkException() => (
        Glyph.wifiOff(),
        offlineTitle,
        offlineBody,
        null,
        true,
      ),
      PixabayApiException(:final requestLabel) => (
        Glyph.alert(),
        apiTitle,
        apiBody,
        requestLabel,
        true,
      ),
      PixabayMissingKeyException(:final message) => (
        Glyph.alert(),
        missingKeyTitle,
        message,
        null,
        false,
      ),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        110,
        AppSpacing.xxl,
        0,
      ),
      child: Column(
        children: <Widget>[
          glyph,
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.stateTitle,
          ),
          const SizedBox(height: 9),
          Text(
            body,
            textAlign: TextAlign.center,
            style: AppTypography.stateBody,
          ),
          if (detail != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: AppTypography.mono(11),
            ),
          ],
          if (retry) ...<Widget>[
            const SizedBox(height: 24),
            PillButton(label: retryLabel, onPressed: onRetry),
          ],
        ],
      ),
    );
  }
}
