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
import 'package:pixabay_image_browser/features/favorites/views/favorites_view.dart';
import 'package:pixabay_image_browser/features/favorites/widgets/favorites_tile.dart';
import 'package:pixabay_image_browser/features/gallery/controllers/gallery_controller.dart';
import 'package:pixabay_image_browser/features/gallery/controllers/gallery_state.dart';
import 'package:pixabay_image_browser/features/gallery/models/pixabay_image.dart';
import 'package:pixabay_image_browser/features/gallery/models/pixabay_page.dart';
import 'package:pixabay_image_browser/features/gallery/repositories/gallery_repository.dart';
import 'package:pixabay_image_browser/features/gallery/views/image_detail_view.dart';
import 'package:pixabay_image_browser/features/gallery/widgets/gallery_image_tile.dart';
import 'package:pixabay_image_browser/features/gallery/widgets/glass_icon_button.dart';
import 'package:pixabay_image_browser/features/gallery/widgets/gallery_search_results_header.dart';
import 'package:pixabay_image_browser/features/home/controllers/home_controller.dart';
import 'package:pixabay_image_browser/features/home/views/home_view.dart';
import 'package:pixabay_image_browser/main.dart';

import '../../../support/auth_fixtures.dart';
import '../../../support/fake_image_cache.dart';
import '../../../support/favorites_fixtures.dart';
import '../../../support/pixabay_fixtures.dart';

class _MockGalleryRepository extends Mock implements GalleryRepository {}

void main() {
  late _MockGalleryRepository gallery;
  late MockAuthRepository auth;
  late FakeFavoritesStorageService storage;

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    installPendingImageCache();
  });

  setUp(() {
    Get.testMode = true;
    gallery = _MockGalleryRepository();
    auth = MockAuthRepository();
    storage = FakeFavoritesStorageService();
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

  Future<void> pumpHome(
    WidgetTester tester, {
    AuthUser? user,
    List<PixabayImage> saved = const <PixabayImage>[],
  }) async {
    when(gallery.getImages).thenAnswer((_) async => pageWith(20));
    if (user != null) storage.seed(user.id, saved);
    Get.put<GalleryRepository>(gallery);
    Get.put<AuthRepository>(stubAuthRepository(auth, user: user));
    registerFavoritesFakes(storage: storage);
    await tester.pumpWidget(const ApertureApp());
    await tester.pump();
    await tester.pump();
    expect(find.byType(GalleryImageTile), findsWidgets);
  }

  Future<void> settleRoute(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  /// Scoped to the pill: the Favourites screen also titles itself so.
  Finder tab(String label) => find.descendant(
    of: find.byType(GlassTabBar),
    matching: find.bySemanticsLabel(label),
  );

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

  testWidgets('a signed-in user tapping Favourites selects that tab', (
    tester,
  ) async {
    await pumpHome(tester, user: sampleUser());

    await tester.tap(tab(GlassTabBar.favouritesLabel));
    await settleRoute(tester);

    expect(find.byType(AuthView), findsNothing);
    expect(home().tab.value, AppTab.favourites);
    expect(find.text(FavoritesView.emptyTitle), findsOneWidget);
    expect(find.byType(GalleryImageTile), findsNothing);
    expect(find.text(ProfileView.guestHeading), findsNothing);
    // the pill reflects the selection: Explore is no longer the active tab
    expect(tab(GlassTabBar.exploreActiveLabel), findsNothing);
    expect(tab(GlassTabBar.exploreLabel), findsOneWidget);

    // a second tap on the selected tab is a no-op
    await tester.tap(tab(GlassTabBar.favouritesLabel));
    await tester.pump();
    expect(home().tab.value, AppTab.favourites);
    expect(tester.takeException(), isNull);
  });

  testWidgets('signing in from the Favourites gate lands on Favourites', (
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

    await tester.tap(tab(GlassTabBar.favouritesLabel));
    await settleRoute(tester);
    expect(find.byType(AuthView), findsOneWidget);
    expect(home().tab.value, AppTab.explore);

    await tester.enterText(find.byType(TextField).at(0), user.email);
    await tester.enterText(find.byType(TextField).at(1), 'correct horse');
    await tester.pump();
    await tester.tap(
      find.widgetWithText(FilledPillButton, AuthView.signInAction),
    );
    await settleRoute(tester);

    expect(find.byType(AuthView), findsNothing);
    expect(home().tab.value, AppTab.favourites);
    expect(find.text(FavoritesView.emptyTitle), findsOneWidget);
  });

  testWidgets('backing out of the Favourites gate forgets the intent', (
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

    await tester.tap(tab(GlassTabBar.favouritesLabel));
    await settleRoute(tester);
    await tester.tap(find.bySemanticsLabel(AuthView.backLabel));
    await settleRoute(tester);
    expect(home().tab.value, AppTab.explore);

    await tester.tap(tab(GlassTabBar.profileLabel));
    await tester.pump();
    await tester.tap(
      find.widgetWithText(FilledPillButton, ProfileView.signInLabel),
    );
    await settleRoute(tester);
    await tester.enterText(find.byType(TextField).at(0), user.email);
    await tester.enterText(find.byType(TextField).at(1), 'correct horse');
    await tester.pump();
    await tester.tap(
      find.widgetWithText(FilledPillButton, AuthView.signInAction),
    );
    await settleRoute(tester);

    expect(home().tab.value, AppTab.profile);
  });

  testWidgets('Explore keeps its query, pages and scroll across Favourites', (
    tester,
  ) async {
    await pumpHome(tester, user: sampleUser());
    when(
      () => gallery.getImages(query: 'mountains'),
    ).thenAnswer((_) async => pageWith(20, firstId: 900));

    await tester.enterText(find.byType(TextField), 'mountains');
    await tester.pump(GalleryController.debounceDuration);
    await tester.pump();
    expect(find.byType(GallerySearchResultsHeader), findsOneWidget);
    feed().jumpTo(600);
    await tester.pump();

    await tester.tap(tab(GlassTabBar.favouritesLabel));
    await tester.pump();
    expect(find.text(FavoritesView.emptyTitle), findsOneWidget);
    expect(find.byType(GalleryImageTile), findsNothing);

    await tester.tap(tab(GlassTabBar.exploreLabel));
    await tester.pump();

    expect(find.byType(GalleryImageTile), findsWidgets);
    // the search field is a lazily built sliver, scrolled away at 600
    final galleryController = Get.find<GalleryController>();
    expect(galleryController.searchController.text, 'mountains');
    expect(
      galleryController.state.value,
      isA<GalleryLoaded>()
          .having((s) => s.query, 'query', 'mountains')
          .having((s) => s.images, 'images', hasLength(20)),
    );
    expect(feed().offset, 600);
    verify(() => gallery.getImages(query: 'mountains')).called(1);
    verify(gallery.getImages).called(1);
  });

  testWidgets('Favourites → Details → back keeps the grid without a reload', (
    tester,
  ) async {
    final image = PixabayImage.fromJson(sampleHit(id: 500, tags: 'dune, sand'));
    await pumpHome(tester, user: sampleUser(), saved: <PixabayImage>[image]);

    await tester.tap(tab(GlassTabBar.favouritesLabel));
    await tester.pump();
    expect(find.byType(FavoritesTile), findsOneWidget);
    final reads = storage.reads;

    await tester.tap(find.bySemanticsLabel(GalleryImageTile.openLabel(image)));
    await settleRoute(tester);
    expect(find.byType(ImageDetailView), findsOneWidget);
    expect(find.text(image.title), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(GlassIconButton.backLabel));
    await settleRoute(tester);

    expect(find.byType(ImageDetailView), findsNothing);
    expect(home().tab.value, AppTab.favourites);
    expect(find.byType(FavoritesTile), findsOneWidget);
    expect(storage.reads, reads);
    verify(gallery.getImages).called(1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a photo saved from the feed opens from both grids', (
    tester,
  ) async {
    // id 100 is also the first feed tile: two heroes with one tag on Home
    final image = PixabayImage.fromJson(sampleHit(id: 100));
    await pumpHome(tester, user: sampleUser(), saved: <PixabayImage>[image]);

    await tester.tap(
      find.bySemanticsLabel(GalleryImageTile.openLabel(image)).first,
    );
    await settleRoute(tester);
    expect(find.byType(ImageDetailView), findsOneWidget);
    await tester.tap(find.bySemanticsLabel(GlassIconButton.backLabel));
    await settleRoute(tester);
    expect(tester.takeException(), isNull);

    await tester.tap(tab(GlassTabBar.favouritesLabel));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel(GalleryImageTile.openLabel(image)));
    await settleRoute(tester);
    expect(find.byType(ImageDetailView), findsOneWidget);
    await tester.tap(find.bySemanticsLabel(GlassIconButton.backLabel));
    await settleRoute(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(FavoritesTile), findsOneWidget);
    expect(home().tab.value, AppTab.favourites);
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

  testWidgets('logging out clears the previous account\'s search', (
    tester,
  ) async {
    await pumpHome(tester, user: sampleUser());
    when(
      () => gallery.getImages(query: 'fog'),
    ).thenAnswer((_) async => pageWith(3, firstId: 900));
    when(auth.signOut).thenAnswer((_) async {
      when(auth.currentUser).thenReturn(null);
    });

    await tester.enterText(find.byType(TextField), 'fog');
    await tester.pump(GalleryController.debounceDuration);
    await tester.pump();
    expect(find.byType(GallerySearchResultsHeader), findsOneWidget);
    feed().jumpTo(300);
    await tester.pump();

    await tester.tap(tab(GlassTabBar.profileLabel));
    await tester.pump();
    await tester.tap(find.text(ProfileView.logOutLabel));
    await tester.pump();
    await tester.pump(GalleryController.scrollToTopDuration);
    expect(find.text(ProfileView.guestHeading), findsOneWidget);

    await tester.tap(tab(GlassTabBar.exploreLabel));
    await tester.pump();

    final galleryController = Get.find<GalleryController>();
    expect(galleryController.searchController.text, isEmpty);
    expect(
      galleryController.state.value,
      isA<GalleryLoaded>().having((s) => s.query, 'query', isEmpty),
    );
    expect(find.byType(GallerySearchResultsHeader), findsNothing);
    expect(feed().offset, 0);
    // the curated page 1 came back from the cached snapshot
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
