import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pixabay_image_browser/core/routes/app_pages.dart';
import 'package:pixabay_image_browser/core/widgets/glass_tab_bar.dart';
import 'package:pixabay_image_browser/core/widgets/pill_button.dart';
import 'package:pixabay_image_browser/features/auth/controllers/auth_controller.dart';
import 'package:pixabay_image_browser/features/auth/models/auth_user.dart';
import 'package:pixabay_image_browser/features/favorites/controllers/favorites_controller.dart';
import 'package:pixabay_image_browser/features/favorites/repositories/favorites_repository.dart';
import 'package:pixabay_image_browser/features/favorites/services/favorites_storage_service.dart';
import 'package:pixabay_image_browser/features/favorites/views/favorites_view.dart';
import 'package:pixabay_image_browser/features/favorites/widgets/favorites_locked_view.dart';
import 'package:pixabay_image_browser/features/favorites/widgets/favorites_storage_error_view.dart';
import 'package:pixabay_image_browser/features/favorites/widgets/favorites_tile.dart';
import 'package:pixabay_image_browser/features/gallery/controllers/gallery_controller.dart';
import 'package:pixabay_image_browser/features/gallery/models/pixabay_image.dart';
import 'package:pixabay_image_browser/features/gallery/views/image_detail_view.dart';
import 'package:pixabay_image_browser/features/gallery/widgets/gallery_image_tile.dart';
import 'package:pixabay_image_browser/features/home/controllers/home_controller.dart';

import '../../../support/auth_fixtures.dart';
import '../../../support/fake_image_cache.dart';
import '../../../support/favorites_fixtures.dart';
import '../../../support/pixabay_fixtures.dart';

class _MockGalleryController extends Mock implements GalleryController {}

void main() {
  late FakeFavoritesStorageService storage;

  setUpAll(() {
    // Fonts fall back to the test environment's defaults; no network.
    GoogleFonts.config.allowRuntimeFetching = false;
    installPendingImageCache();
  });

  setUp(() {
    Get.testMode = true;
    storage = FakeFavoritesStorageService();
  });

  tearDown(Get.reset);

  PixabayImage imageWith(int id, {String tags = 'blossom, bloom, flower'}) =>
      PixabayImage.fromJson(sampleHit(id: id, tags: tags));

  HomeController home() => Get.find<HomeController>();

  Future<void> pumpFavorites(
    WidgetTester tester, {
    AuthUser? user,
    List<PixabayImage> seeded = const <PixabayImage>[],
    String? raw,
  }) async {
    // The load runs inside onInit, so the store must be in place first.
    if (user != null) {
      if (raw != null) {
        storage.store[FavoritesStorageService.keyFor(user.id)] = raw;
      } else {
        storage.seed(user.id, seeded);
      }
    }
    final auth = Get.put(
      AuthController(
        repository: stubAuthRepository(MockAuthRepository(), user: user),
      ),
    );
    Get.put(
      FavoritesController(
        auth: auth,
        repository: FavoritesRepository(storage: storage),
      ),
    );
    Get.put(HomeController(auth: auth, gallery: _MockGalleryController()));
    home().tab.value = AppTab.favourites;
    await tester.pumpWidget(
      GetMaterialApp(home: const FavoritesView(), getPages: AppPages.pages),
    );
    await tester.pump();
    await tester.pump();
  }

  Future<void> settleRoute(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('a signed-in user with nothing saved sees the empty state', (
    tester,
  ) async {
    await pumpFavorites(tester, user: sampleUser());

    expect(find.text(FavoritesView.title), findsOneWidget);
    expect(
      find.text(FavoritesView.countLabel(0).toUpperCase()),
      findsOneWidget,
    );
    expect(find.text(FavoritesView.emptyTitle), findsOneWidget);
    expect(find.text(FavoritesView.emptyBody), findsOneWidget);
    expect(find.byType(FavoritesStorageErrorView), findsNothing);

    await tester.tap(
      find.widgetWithText(PillButton, FavoritesView.browseLabel),
    );
    await tester.pump();

    expect(home().tab.value, AppTab.explore);
  });

  testWidgets('saved images fill a two-column grid, newest first', (
    tester,
  ) async {
    final older = imageWith(1, tags: 'older, photo');
    final newer = imageWith(2, tags: 'newer, photo');
    await pumpFavorites(
      tester,
      user: sampleUser(),
      seeded: <PixabayImage>[older, newer],
    );

    expect(
      find.text(FavoritesView.countLabel(2).toUpperCase()),
      findsOneWidget,
    );
    expect(find.byType(FavoritesTile), findsNWidgets(2));
    expect(find.text(FavoritesView.emptyTitle), findsNothing);
    final tiles = tester.widgetList<FavoritesTile>(find.byType(FavoritesTile));
    expect(tiles.first.image, newer);
    expect(tiles.last.image, older);
    expect(
      tester.getTopLeft(find.byType(FavoritesTile).first).dy,
      tester.getTopLeft(find.byType(FavoritesTile).last).dy,
    );
    expect(
      tester.getSize(find.byType(FavoritesTile).first),
      tester.getSize(find.byType(FavoritesTile).last),
    );
  });

  testWidgets('tapping a saved image opens Details from the stored model', (
    tester,
  ) async {
    final image = imageWith(1);
    await pumpFavorites(
      tester,
      user: sampleUser(),
      seeded: <PixabayImage>[image],
    );
    final readsBefore = storage.reads;

    await tester.tap(find.bySemanticsLabel(GalleryImageTile.openLabel(image)));
    await settleRoute(tester);

    expect(find.byType(ImageDetailView), findsOneWidget);
    expect(find.text(image.title), findsOneWidget);
    expect(storage.reads, readsBefore);
  });

  testWidgets('removing the last favourite shows the empty state', (
    tester,
  ) async {
    final image = imageWith(1);
    final user = sampleUser();
    await pumpFavorites(tester, user: user, seeded: <PixabayImage>[image]);

    await tester.tap(find.bySemanticsLabel(FavoritesTile.removeLabel(image)));
    await tester.pump();

    expect(find.byType(FavoritesTile), findsNothing);
    expect(find.text(FavoritesView.emptyTitle), findsOneWidget);
    await tester.pump();
    expect(storage.saved(user.id), isEmpty);
    expect(find.byType(ImageDetailView), findsNothing);
  });

  testWidgets('a storage read failure shows the error block; Retry recovers', (
    tester,
  ) async {
    storage.failReads = true;
    await pumpFavorites(
      tester,
      user: sampleUser(),
      seeded: <PixabayImage>[imageWith(1)],
    );

    expect(find.text(FavoritesStorageErrorView.title), findsOneWidget);
    expect(find.text(FavoritesStorageErrorView.body), findsOneWidget);
    expect(find.byType(FavoritesTile), findsNothing);

    storage.failReads = false;
    await tester.tap(
      find.widgetWithText(PillButton, FavoritesStorageErrorView.retryLabel),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(FavoritesStorageErrorView), findsNothing);
    expect(find.byType(FavoritesTile), findsOneWidget);
  });

  testWidgets(
    'a damaged store shows the corruption copy and Retry leaves it untouched',
    (tester) async {
      final user = sampleUser();
      await pumpFavorites(tester, user: user, raw: '{"id": 1}');

      expect(find.text(FavoritesStorageErrorView.corruptTitle), findsOneWidget);
      expect(find.text(FavoritesStorageErrorView.corruptBody), findsOneWidget);
      expect(find.text(FavoritesStorageErrorView.title), findsNothing);
      expect(find.byType(FavoritesTile), findsNothing);

      await tester.tap(
        find.widgetWithText(PillButton, FavoritesStorageErrorView.retryLabel),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text(FavoritesStorageErrorView.corruptTitle), findsOneWidget);
      expect(storage.writes, 0);
      expect(
        storage.store[FavoritesStorageService.keyFor(user.id)],
        '{"id": 1}',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('an image that cannot load keeps its entry and still removes', (
    tester,
  ) async {
    installFailingImageCache();
    addTearDown(installPendingImageCache);
    final user = sampleUser();
    // A URL no earlier test has put in the image cache.
    final image = PixabayImage.fromJson(<String, dynamic>{
      ...sampleHit(id: 1),
      'largeImageURL': 'https://example.test/broken_1280.jpg',
    });
    await pumpFavorites(tester, user: user, seeded: <PixabayImage>[image]);
    await tester.pump();

    expect(find.byType(FavoritesTile), findsOneWidget);
    expect(find.byType(GalleryImageFallback), findsOneWidget);
    expect(storage.saved(user.id).map((i) => i.id), <int>[1]);

    await tester.tap(find.bySemanticsLabel(FavoritesTile.removeLabel(image)));
    await tester.pump();
    await tester.pump();

    expect(find.byType(FavoritesTile), findsNothing);
    expect(find.text(FavoritesView.emptyTitle), findsOneWidget);
    expect(storage.saved(user.id), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed removal keeps the tile and shows the toast', (
    tester,
  ) async {
    final image = imageWith(1);
    await pumpFavorites(
      tester,
      user: sampleUser(),
      seeded: <PixabayImage>[image],
    );
    storage.failWrites = true;

    await tester.tap(find.bySemanticsLabel(FavoritesTile.removeLabel(image)));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(FavoritesTile), findsOneWidget);
    expect(find.text(FavoritesView.writeErrorMessage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('without a session the locked state stands in', (tester) async {
    await pumpFavorites(tester);

    expect(find.text(FavoritesView.lockedLabel.toUpperCase()), findsOneWidget);
    expect(find.text(FavoritesLockedView.title), findsOneWidget);
    expect(find.byType(FavoritesTile), findsNothing);
    expect(storage.reads, 0);
  });
}
