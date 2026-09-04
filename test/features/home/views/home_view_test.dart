import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pixabay_image_browser/core/widgets/filled_pill_button.dart';
import 'package:pixabay_image_browser/core/widgets/glass_tab_bar.dart';
import 'package:pixabay_image_browser/features/auth/models/auth_user.dart';
import 'package:pixabay_image_browser/features/auth/repositories/auth_repository.dart';
import 'package:pixabay_image_browser/features/auth/views/auth_view.dart';
import 'package:pixabay_image_browser/features/auth/views/profile_view.dart';
import 'package:pixabay_image_browser/features/gallery/controllers/gallery_controller.dart';
import 'package:pixabay_image_browser/features/gallery/models/pixabay_page.dart';
import 'package:pixabay_image_browser/features/gallery/repositories/gallery_repository.dart';
import 'package:pixabay_image_browser/features/gallery/widgets/gallery_image_tile.dart';
import 'package:pixabay_image_browser/features/gallery/widgets/gallery_search_results_header.dart';
import 'package:pixabay_image_browser/features/home/controllers/home_controller.dart';
import 'package:pixabay_image_browser/features/home/views/home_view.dart';
import 'package:pixabay_image_browser/main.dart';

import '../../../support/auth_fixtures.dart';
import '../../../support/fake_image_cache.dart';
import '../../../support/pixabay_fixtures.dart';

class _MockGalleryRepository extends Mock implements GalleryRepository {}

void main() {
  late _MockGalleryRepository gallery;
  late MockAuthRepository auth;

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    installPendingImageCache();
  });

  setUp(() {
    Get.testMode = true;
    gallery = _MockGalleryRepository();
    auth = MockAuthRepository();
  });

  tearDown(Get.reset);

  PixabayPage pageWith(int count, {int firstId = 100}) {
    return PixabayPage.fromJson(<String, dynamic>{
      'total': count,
      'totalHits': count,
      'hits': <Map<String, dynamic>>[
        for (var i = 0; i < count; i++) sampleHit(id: firstId + i),
      ],
    });
  }

  Future<void> pumpHome(WidgetTester tester, {AuthUser? user}) async {
    when(gallery.getImages).thenAnswer((_) async => pageWith(20));
    Get.put<GalleryRepository>(gallery);
    Get.put<AuthRepository>(stubAuthRepository(auth, user: user));
    await tester.pumpWidget(const ApertureApp());
    await tester.pump();
    await tester.pump();
    expect(find.byType(GalleryImageTile), findsWidgets);
  }

  Future<void> settleRoute(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Finder tab(String label) => find.bySemanticsLabel(label);

  ScrollController feed() => Get.find<GalleryController>().scrollController;

  HomeController home() => Get.find<HomeController>();

  testWidgets('starts on Explore with the feed under the pill', (tester) async {
    await pumpHome(tester);

    expect(find.byType(HomeView), findsOneWidget);
    expect(find.byType(GlassTabBar), findsOneWidget);
    expect(tab(GlassTabBar.exploreActiveLabel), findsOneWidget);
    expect(find.text(ProfileView.guestHeading), findsNothing);
    expect(home().tab.value, AppTab.explore);
  });

  testWidgets('Profile shows the account tab; Explore comes back untouched', (
    tester,
  ) async {
    await pumpHome(tester);
    feed().jumpTo(600);
    await tester.pump();

    await tester.tap(tab(GlassTabBar.profileLabel));
    await tester.pump();

    expect(home().tab.value, AppTab.profile);
    expect(find.text(ProfileView.guestHeading), findsOneWidget);
    expect(find.byType(GalleryImageTile), findsNothing);

    await tester.tap(tab(GlassTabBar.exploreLabel));
    await tester.pump();

    expect(find.byType(GalleryImageTile), findsWidgets);
    expect(find.text(ProfileView.guestHeading), findsNothing);
    expect(feed().offset, 600);
    verify(gallery.getImages).called(1);
  });

  testWidgets('a search survives a visit to Profile', (tester) async {
    await pumpHome(tester);
    when(
      () => gallery.getImages(query: 'fog'),
    ).thenAnswer((_) async => pageWith(3, firstId: 900));

    await tester.enterText(find.byType(TextField), 'fog');
    await tester.pump(GalleryController.debounceDuration);
    await tester.pump();
    expect(find.byType(GallerySearchResultsHeader), findsOneWidget);

    await tester.tap(tab(GlassTabBar.profileLabel));
    await tester.pump();
    await tester.tap(tab(GlassTabBar.exploreLabel));
    await tester.pump();

    expect(find.byType(GallerySearchResultsHeader), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      'fog',
    );
    verify(() => gallery.getImages(query: 'fog')).called(1);
  });

  testWidgets('tapping the active Explore tab scrolls the feed to the top', (
    tester,
  ) async {
    await pumpHome(tester);
    feed().jumpTo(600);
    await tester.pump();

    await tester.tap(tab(GlassTabBar.exploreActiveLabel));
    await tester.pump();
    await tester.pump(GalleryController.scrollToTopDuration);

    expect(feed().offset, 0);
  });

  testWidgets('a guest tapping Favourites is sent to sign in; Explore stays', (
    tester,
  ) async {
    await pumpHome(tester);

    await tester.tap(tab(GlassTabBar.favouritesLabel));
    await settleRoute(tester);

    expect(find.byType(AuthView), findsOneWidget);
    expect(home().tab.value, AppTab.explore);

    await tester.tap(find.bySemanticsLabel(AuthView.backLabel));
    await settleRoute(tester);

    expect(find.byType(AuthView), findsNothing);
    expect(find.byType(GalleryImageTile), findsWidgets);
    verify(gallery.getImages).called(1);
  });

  testWidgets('a signed-in user tapping Favourites stays put for now', (
    tester,
  ) async {
    await pumpHome(tester, user: sampleUser());

    await tester.tap(tab(GlassTabBar.favouritesLabel));
    await settleRoute(tester);

    expect(find.byType(AuthView), findsNothing);
    expect(home().tab.value, AppTab.explore);
  });

  testWidgets('signing in from Profile returns to Profile with the account', (
    tester,
  ) async {
    await pumpHome(tester);
    final user = sampleUser();
    when(
      () => auth.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => user);

    await tester.tap(tab(GlassTabBar.profileLabel));
    await tester.pump();
    await tester.tap(
      find.widgetWithText(FilledPillButton, ProfileView.signInLabel),
    );
    await settleRoute(tester);
    expect(find.byType(AuthView), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), user.email);
    await tester.enterText(find.byType(TextField).at(1), 'correct horse');
    await tester.pump();
    await tester.tap(
      find.widgetWithText(FilledPillButton, AuthView.signInAction),
    );
    await settleRoute(tester);

    expect(find.byType(AuthView), findsNothing);
    expect(home().tab.value, AppTab.profile);
    expect(find.text(user.email), findsOneWidget);
    expect(find.text(ProfileView.logOutLabel), findsOneWidget);
    verify(gallery.getImages).called(1);
  });

  testWidgets('the pill hides while the keyboard is up', (tester) async {
    await pumpHome(tester);
    addTearDown(tester.view.reset);

    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pump();
    expect(find.byType(GlassTabBar), findsNothing);

    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pump();
    expect(find.byType(GlassTabBar), findsOneWidget);
  });
}
