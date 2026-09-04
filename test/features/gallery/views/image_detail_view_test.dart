import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pixabay_image_browser/core/routes/app_pages.dart';
import 'package:pixabay_image_browser/core/widgets/filled_pill_button.dart';
import 'package:pixabay_image_browser/features/auth/controllers/auth_controller.dart';
import 'package:pixabay_image_browser/features/auth/models/auth_user.dart';
import 'package:pixabay_image_browser/features/auth/views/auth_view.dart';
import 'package:pixabay_image_browser/features/auth/widgets/guest_favourite_sheet.dart';
import 'package:pixabay_image_browser/features/gallery/models/pixabay_image.dart';
import 'package:pixabay_image_browser/features/gallery/views/image_detail_view.dart';
import 'package:pixabay_image_browser/features/gallery/widgets/glass_icon_button.dart';
import 'package:pixabay_image_browser/features/gallery/widgets/image_detail_actions.dart';
import 'package:pixabay_image_browser/features/gallery/widgets/image_detail_creator.dart';
import 'package:pixabay_image_browser/features/gallery/widgets/image_detail_hero.dart';
import 'package:pixabay_image_browser/features/gallery/widgets/image_detail_stats.dart';

import '../../../support/auth_fixtures.dart';
import '../../../support/fake_image_cache.dart';
import '../../../support/pixabay_fixtures.dart';

void main() {
  setUpAll(() {
    // Fonts fall back to the test environment's defaults; no network.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    Get.testMode = true;
    installPendingImageCache();
  });

  tearDown(Get.reset);

  PixabayImage imageWith([Map<String, dynamic> overrides = const {}]) =>
      PixabayImage.fromJson(<String, dynamic>{...sampleHit(), ...overrides});

  Future<void> pumpDetails(
    WidgetTester tester,
    PixabayImage image, {
    AuthUser? user,
  }) async {
    Get.put<AuthController>(
      AuthController(
        repository: stubAuthRepository(MockAuthRepository(), user: user),
      ),
    );
    await tester.pumpWidget(
      GetMaterialApp(
        home: ImageDetailView(image: image),
        getPages: AppPages.pages,
      ),
    );
    await tester.pump();
  }

  testWidgets('renders the selected image\'s title, creator, stats and tags', (
    tester,
  ) async {
    final image = imageWith(<String, dynamic>{
      'tags': 'forest, fog, mountains, sunrise',
      'likes': 1284,
      'views': 48210,
      'downloads': 9004,
    });

    await pumpDetails(tester, image);

    expect(find.text(image.title), findsOneWidget);
    expect(find.text(ImageDetailCreator.metaLabel(image)), findsOneWidget);
    expect(find.text('1,284'), findsOneWidget);
    expect(find.text('48,210'), findsOneWidget);
    expect(find.text('9,004'), findsOneWidget);
    expect(
      find.text(ImageDetailStats.likesLabel.toUpperCase()),
      findsOneWidget,
    );
    for (final tag in image.tags) {
      expect(find.text(tag), findsOneWidget);
    }
    expect(find.bySemanticsLabel(GlassIconButton.backLabel), findsOneWidget);
    expect(
      find.bySemanticsLabel(ImageDetailActions.favouriteLabel),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(ImageDetailActions.downloadLabel),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(ImageDetailHero.viewerLabel), findsOneWidget);
  });

  testWidgets('the hero uses the design height, clamped on short screens', (
    tester,
  ) async {
    await pumpDetails(tester, imageWith());

    final context = tester.element(find.byType(ImageDetailHero));
    final size = tester.getSize(find.byType(ImageDetailHero));
    expect(size.height, ImageDetailHero.heightFor(context));
    expect(size.height, lessThan(ImageDetailHero.designHeight));
    expect(size.width, MediaQuery.sizeOf(context).width);
  });

  testWidgets('the hero is 430pt on a tall phone', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpDetails(tester, imageWith());

    expect(
      tester.getSize(find.byType(ImageDetailHero)).height,
      ImageDetailHero.designHeight,
    );
  });

  testWidgets('a failed hero shows the fallback while the details stay', (
    tester,
  ) async {
    installFailingImageCache();
    final image = imageWith(<String, dynamic>{
      'webformatURL': 'https://example.test/broken_640.jpg',
      'largeImageURL': 'https://example.test/broken_1280.jpg',
      'userImageURL': '',
    });

    await pumpDetails(tester, image);
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text(ImageDetailHeroFallback.failedTitle), findsOneWidget);
    expect(find.text(ImageDetailHeroFallback.failedHint), findsOneWidget);
    expect(find.text(image.title), findsOneWidget);
    expect(find.text('7,671'), findsOneWidget);
  });

  testWidgets('a guest tapping favourite gets the sign-in sheet', (
    tester,
  ) async {
    await pumpDetails(tester, imageWith());

    await tester.tap(find.bySemanticsLabel(ImageDetailActions.favouriteLabel));
    await tester.pumpAndSettle();

    expect(find.text(GuestFavouriteSheet.title), findsOneWidget);
    expect(find.text(GuestFavouriteSheet.body), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(GuestFavouriteSheet.dismissLabel));
    await tester.pumpAndSettle();

    expect(find.text(GuestFavouriteSheet.title), findsNothing);
    expect(find.byType(ImageDetailView), findsOneWidget);
  });

  testWidgets('the sheet\'s Sign in closes it and opens the auth screen', (
    tester,
  ) async {
    await pumpDetails(tester, imageWith());

    await tester.tap(find.bySemanticsLabel(ImageDetailActions.favouriteLabel));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(FilledPillButton, GuestFavouriteSheet.signInLabel),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AuthView), findsOneWidget);
    expect(find.text(GuestFavouriteSheet.title), findsNothing);
  });

  testWidgets('favourite stays inert when signed in; download is inert', (
    tester,
  ) async {
    await pumpDetails(tester, imageWith(), user: sampleUser());

    await tester.tap(find.bySemanticsLabel(ImageDetailActions.favouriteLabel));
    await tester.tap(find.bySemanticsLabel(ImageDetailActions.downloadLabel));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(GuestFavouriteSheet.title), findsNothing);
    expect(find.byType(ImageDetailView), findsOneWidget);
  });

  testWidgets('long names, many tags and huge counts fit a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final image = imageWith(<String, dynamic>{
      'user': 'an_extraordinarily_long_pixabay_user_name_that_goes_on',
      'tags': List<String>.generate(
        25,
        (i) => 'an unusually long tag number $i',
      ).join(', '),
      'likes': 1234567890,
      'views': 1234567890,
      'downloads': 1234567890,
    });

    await pumpDetails(tester, image);

    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel(GlassIconButton.backLabel), findsOneWidget);
    expect(
      find.bySemanticsLabel(ImageDetailActions.favouriteLabel),
      findsOneWidget,
    );

    // the whole page scrolls to the last tag with the bar still in place
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -4000),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text(image.tags.last), findsOneWidget);
  });
}
