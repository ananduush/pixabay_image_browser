import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pixabay_image_browser/core/theme/app_theme.dart';
import 'package:pixabay_image_browser/core/theme/app_typography.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  const bundled = <String>[
    'assets/google_fonts/InstrumentSans-Regular.ttf',
    'assets/google_fonts/InstrumentSans-Medium.ttf',
    'assets/google_fonts/Newsreader-Regular.ttf',
  ];

  testWidgets('bundles every font variant the typography uses', (tester) async {
    await tester.runAsync(() async {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      expect(manifest.listAssets(), containsAll(bundled));
    });
  });

  testWidgets('every requested font loads from assets without fetching', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Column(
            children: <Widget>[
              Text('brand', style: AppTypography.brand),
              Text('body', style: AppTypography.body),
              Text('button', style: AppTypography.button),
            ],
          ),
        ),
      );
      // Rejects if any variant was neither bundled nor fetchable.
      await GoogleFonts.pendingFonts();
    });
    expect(tester.takeException(), isNull);
  });
}
