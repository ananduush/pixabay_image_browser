import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pixabay_image_browser/features/gallery/models/pixabay_image.dart';
import 'package:pixabay_image_browser/features/gallery/widgets/image_detail_creator.dart';

import '../../../support/fake_image_cache.dart';
import '../../../support/pixabay_fixtures.dart';

void main() {
  setUpAll(() {
    // Fonts fall back to the test environment's defaults; no network.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(installPendingImageCache);

  PixabayImage imageWith(Map<String, dynamic> overrides) =>
      PixabayImage.fromJson(<String, dynamic>{...sampleHit(), ...overrides});

  Future<void> pump(WidgetTester tester, PixabayImage image) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ImageDetailCreator(image: image)),
        ),
      );

  group('metaLabel', () {
    test('joins the uploader and the dimensions', () {
      expect(
        ImageDetailCreator.metaLabel(imageWith(<String, dynamic>{})),
        'by Josch13 · 4000 × 2250',
      );
    });

    test('omits the dimensions when Pixabay sent none', () {
      expect(
        ImageDetailCreator.metaLabel(
          imageWith(<String, dynamic>{'imageWidth': 0}),
        ),
        'by Josch13',
      );
    });

    test('falls back to an unknown uploader', () {
      expect(
        ImageDetailCreator.metaLabel(imageWith(<String, dynamic>{'user': ' '})),
        'by ${ImageDetailCreator.unknownUser} · 4000 × 2250',
      );
    });
  });

  test('initialFor upper-cases the first character', () {
    expect(ImageDetailCreator.initialFor('josch13'), 'J');
    expect(ImageDetailCreator.initialFor('  anna'), 'A');
    expect(ImageDetailCreator.initialFor(''), '');
  });

  testWidgets('shows the avatar image when Pixabay provides one', (
    tester,
  ) async {
    await pump(tester, imageWith(<String, dynamic>{}));

    expect(find.byType(CachedNetworkImage), findsOneWidget);
    expect(find.text('by Josch13 · 4000 × 2250'), findsOneWidget);
    // still on the placeholder, which is the initial
    expect(find.text('J'), findsOneWidget);
  });

  testWidgets('a missing avatar URL shows the initial instead', (tester) async {
    await pump(tester, imageWith(<String, dynamic>{'userImageURL': ''}));

    expect(find.byType(CachedNetworkImage), findsNothing);
    expect(find.text('J'), findsOneWidget);
  });

  testWidgets('a missing avatar and name show the person glyph', (
    tester,
  ) async {
    await pump(
      tester,
      imageWith(<String, dynamic>{'userImageURL': '', 'user': ''}),
    );

    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(
      find.text('by ${ImageDetailCreator.unknownUser} · 4000 × 2250'),
      findsOneWidget,
    );
  });

  testWidgets('a failed avatar download falls back to the initial', (
    tester,
  ) async {
    installFailingImageCache();
    await pump(
      tester,
      imageWith(<String, dynamic>{
        'userImageURL': 'https://example.test/creator-broken.jpg',
      }),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('J'), findsOneWidget);
  });

  testWidgets('a long uploader name ellipsises on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pump(
      tester,
      imageWith(<String, dynamic>{
        'user': 'an_extraordinarily_long_pixabay_user_name_that_goes_on',
      }),
    );

    expect(tester.takeException(), isNull);
  });
}
