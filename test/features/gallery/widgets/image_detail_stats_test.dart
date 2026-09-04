import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pixabay_image_browser/features/gallery/models/pixabay_image.dart';
import 'package:pixabay_image_browser/features/gallery/widgets/image_detail_stats.dart';

import '../../../support/pixabay_fixtures.dart';

void main() {
  setUpAll(() {
    // Fonts fall back to the test environment's defaults; no network.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('formatCount', () {
    test('groups thousands with commas and leaves small numbers alone', () {
      expect(ImageDetailStats.formatCount(0), '0');
      expect(ImageDetailStats.formatCount(999), '999');
      expect(ImageDetailStats.formatCount(1000), '1,000');
      expect(ImageDetailStats.formatCount(48210), '48,210');
      expect(ImageDetailStats.formatCount(1234567), '1,234,567');
    });
  });

  testWidgets('renders the three labelled, formatted metrics', (tester) async {
    final image = PixabayImage.fromJson(<String, dynamic>{
      ...sampleHit(),
      'likes': 1284,
      'views': 48210,
      'downloads': 9004,
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ImageDetailStats(image: image)),
      ),
    );

    expect(find.text('LIKES'), findsOneWidget);
    expect(find.text('VIEWS'), findsOneWidget);
    expect(find.text('DOWNLOADS'), findsOneWidget);
    expect(find.text('1,284'), findsOneWidget);
    expect(find.text('48,210'), findsOneWidget);
    expect(find.text('9,004'), findsOneWidget);
  });

  testWidgets('huge values fit a narrow screen without overflowing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final image = PixabayImage.fromJson(<String, dynamic>{
      ...sampleHit(),
      'likes': 1234567890,
      'views': 1234567890,
      'downloads': 1234567890,
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ImageDetailStats(image: image)),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('1,234,567,890'), findsNWidgets(3));
  });
}
