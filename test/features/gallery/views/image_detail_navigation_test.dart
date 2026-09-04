import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pixabay_image_browser/core/routes/app_pages.dart';
import 'package:pixabay_image_browser/core/routes/app_routes.dart';
import 'package:pixabay_image_browser/features/gallery/controllers/gallery_controller.dart';
import 'package:pixabay_image_browser/features/gallery/controllers/gallery_state.dart';
import 'package:pixabay_image_browser/features/gallery/models/pixabay_page.dart';
import 'package:pixabay_image_browser/features/gallery/repositories/gallery_repository.dart';
import 'package:pixabay_image_browser/features/gallery/views/gallery_view.dart';
import 'package:pixabay_image_browser/features/gallery/views/image_detail_view.dart';
import 'package:pixabay_image_browser/features/gallery/views/image_viewer_view.dart';
import 'package:pixabay_image_browser/features/gallery/widgets/gallery_image_tile.dart';
import 'package:pixabay_image_browser/features/gallery/widgets/gallery_search_results_header.dart';
import 'package:pixabay_image_browser/features/gallery/widgets/glass_icon_button.dart';
import 'package:pixabay_image_browser/features/gallery/widgets/image_detail_hero.dart';
import 'package:pixabay_image_browser/features/gallery/widgets/image_detail_tags.dart';

import '../../../support/fake_image_cache.dart';
import '../../../support/pixabay_fixtures.dart';

class _MockRepository extends Mock implements GalleryRepository {}

/// Gallery → Details → back, through the real route table and binding, so
/// the controller's lifetime is the one the app has.
void main() {
  late _MockRepository repository;

  setUpAll(() {
    // Fonts fall back to the test environment's defaults; no network.
    GoogleFonts.config.allowRuntimeFetching = false;
    installPendingImageCache();
  });

  setUp(() {
    Get.testMode = true;
    repository = _MockRepository();
  });

  tearDown(Get.reset);

  PixabayPage pageWith(
    int count, {
    int firstId = 100,
    int totalHits = 500,
    String tags = 'blossom, bloom, flower',
  }) {
    return PixabayPage.fromJson(<String, dynamic>{
      'total': 4692,
      'totalHits': totalHits,
      'hits': <Map<String, dynamic>>[
        for (var i = 0; i < count; i++) sampleHit(id: firstId + i, tags: tags),
      ],
    });
  }

  GalleryController controller() => Get.find<GalleryController>();

  /// The registered repository wins over the binding's lazyPut; the binding
  /// still builds the controller and links it to the gallery route.
  Future<void> pumpApp(WidgetTester tester) async {
    Get.put<GalleryRepository>(repository);
    await tester.pumpWidget(
      GetMaterialApp(initialRoute: AppRoutes.gallery, getPages: AppPages.pages),
    );
    await tester.pump();
    await tester.pump();
  }

  /// One explore page that is also the last, so scrolling never asks for
  /// a page 2 the mock has no answer for.
  Future<void> pumpLoadedFeed(WidgetTester tester, {int hits = 20}) async {
    when(
      repository.getImages,
    ).thenAnswer((_) async => pageWith(hits, totalHits: hits));
    await pumpApp(tester);
    expect(find.byType(GalleryImageTile), findsWidgets);
  }

  /// Route transition plus hero flight.
  Future<void> settleRoute(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> openTile(WidgetTester tester, Finder tile) async {
    await tester.tap(tile);
    await settleRoute(tester);
    expect(find.byType(ImageDetailView), findsOneWidget);
  }

  Future<void> tapBack(WidgetTester tester) async {
    await tester.tap(find.bySemanticsLabel(GlassIconButton.backLabel));
    await settleRoute(tester);
  }

  Future<void> systemBack(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await settleRoute(tester);
  }

  void jumpToBottom() {
    final scroll = controller().scrollController;
    scroll.jumpTo(scroll.position.maxScrollExtent);
  }

  /// First tile whose centre is on screen and clear of the floating tab pill.
  Finder visibleTile(WidgetTester tester) {
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    final clearOfPill = screen.height - 120;
    for (final element in find.byType(GalleryImageTile).evaluate()) {
      final tile = find.byWidget(element.widget);
      final center = tester.getCenter(tile);
      if (center.dy > 0 && center.dy < clearOfPill) return tile;
    }
    fail('no tile is fully visible');
  }

  testWidgets('tapping a tile opens Details for that image', (tester) async {
    await pumpLoadedFeed(tester);
    final tile = tester.widget<GalleryImageTile>(
      find.byType(GalleryImageTile).first,
    );

    await openTile(tester, find.byType(GalleryImageTile).first);

    expect(find.text(tile.image.title), findsOneWidget);
    expect(find.byType(GalleryView, skipOffstage: false), findsOneWidget);
  });

  testWidgets('the glass back button returns without reloading the feed', (
    tester,
  ) async {
    await pumpLoadedFeed(tester);
    await openTile(tester, find.byType(GalleryImageTile).first);

    await tapBack(tester);

    expect(find.byType(ImageDetailView), findsNothing);
    expect(find.byType(GalleryImageTile), findsWidgets);
    expect(tester.takeException(), isNull);
    verify(repository.getImages).called(1);
  });

  testWidgets('system back returns without reloading the feed', (tester) async {
    await pumpLoadedFeed(tester);
    await openTile(tester, find.byType(GalleryImageTile).first);

    await systemBack(tester);

    expect(find.byType(ImageDetailView), findsNothing);
    expect(find.byType(GalleryImageTile), findsWidgets);
    verify(repository.getImages).called(1);
  });

  testWidgets('the scroll position survives a round trip', (tester) async {
    await pumpLoadedFeed(tester);
    controller().scrollController.jumpTo(600);
    await tester.pump();

    await openTile(tester, visibleTile(tester));
    await tapBack(tester);

    expect(controller().scrollController.offset, 600);
    verify(repository.getImages).called(1);
  });

  testWidgets('search query, loaded pages and scroll survive a round trip', (
    tester,
  ) async {
    await pumpLoadedFeed(tester);
    when(
      () => repository.getImages(query: 'fog', page: 1, perPage: 20),
    ).thenAnswer((_) async => pageWith(20, firstId: 1000));
    when(
      () => repository.getImages(query: 'fog', page: 2, perPage: 20),
    ).thenAnswer(
      (_) async => pageWith(
        20,
        firstId: 2000,
        tags: 'glacier, ice, peak',
        totalHits: 40, // ends the feed: no page-3 request
      ),
    );

    await tester.enterText(find.byType(TextField), 'fog');
    await tester.pump(GalleryController.debounceDuration);
    await tester.pump();
    jumpToBottom();
    await tester.pump();
    jumpToBottom();
    await tester.pump();
    expect(
      controller().state.value,
      isA<GalleryLoaded>().having((s) => s.images, 'images', hasLength(40)),
    );
    jumpToBottom();
    await tester.pump();
    final offset = controller().scrollController.offset;
    expect(offset, greaterThan(0));

    await openTile(tester, find.byType(GalleryImageTile).last);
    expect(find.text('Glacier · ice · peak'), findsOneWidget);
    await tapBack(tester);

    expect(controller().searchController.text, 'fog');
    expect(controller().searchFocus.hasFocus, isFalse);
    expect(
      controller().state.value,
      isA<GalleryLoaded>()
          .having((s) => s.query, 'query', 'fog')
          .having((s) => s.page, 'page', 2)
          .having((s) => s.images, 'images', hasLength(40)),
    );
    expect(controller().scrollController.offset, offset);
    // the results header is a lazily built sliver: scroll up to see it
    controller().scrollController.jumpTo(0);
    await tester.pump();
    expect(find.byType(GallerySearchResultsHeader), findsOneWidget);
    verify(
      () => repository.getImages(query: 'fog', page: 1, perPage: 20),
    ).called(1);
    verify(
      () => repository.getImages(query: 'fog', page: 2, perPage: 20),
    ).called(1);
  });

  testWidgets('opening Details drops the keyboard and it stays down', (
    tester,
  ) async {
    await pumpLoadedFeed(tester);
    await tester.showKeyboard(find.byType(TextField));
    await tester.pump();
    expect(controller().searchFocus.hasFocus, isTrue);

    await openTile(tester, find.byType(GalleryImageTile).first);
    expect(controller().searchFocus.hasFocus, isFalse);
    await tapBack(tester);

    expect(controller().searchFocus.hasFocus, isFalse);
  });

  testWidgets('a response repeating an id yields one tile and one hero', (
    tester,
  ) async {
    when(repository.getImages).thenAnswer(
      (_) async => PixabayPage.fromJson(<String, dynamic>{
        'total': 3,
        'totalHits': 3,
        'hits': <Map<String, dynamic>>[
          sampleHit(id: 7),
          sampleHit(id: 7),
          sampleHit(id: 7),
        ],
      }),
    );
    await pumpApp(tester);
    expect(find.byType(GalleryImageTile), findsOneWidget);

    await openTile(tester, find.byType(GalleryImageTile));
    await tapBack(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(GalleryImageTile), findsOneWidget);
  });

  testWidgets('tapping a tag returns to the Gallery and searches for it', (
    tester,
  ) async {
    // a phone-sized surface keeps the chips clear of the floating bar
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpLoadedFeed(tester);
    when(
      () => repository.getImages(query: 'bloom', page: 1, perPage: 20),
    ).thenAnswer((_) async => pageWith(3, firstId: 3000));
    await openTile(tester, find.byType(GalleryImageTile).first);

    await tester.tap(find.bySemanticsLabel(ImageDetailTags.tagLabel('bloom')));
    await settleRoute(tester);

    expect(find.byType(ImageDetailView), findsNothing);
    expect(find.byType(GalleryView), findsOneWidget);
    expect(controller().searchController.text, 'bloom');
    expect(controller().searchFocus.hasFocus, isFalse);
    expect(
      find.text(GallerySearchResultsHeader.queryLabel('bloom')),
      findsOneWidget,
    );
    verify(
      () => repository.getImages(query: 'bloom', page: 1, perPage: 20),
    ).called(1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the hero opens the viewer; close and back unwind the stack', (
    tester,
  ) async {
    await pumpLoadedFeed(tester);
    await openTile(tester, find.byType(GalleryImageTile).first);

    await tester.tap(find.bySemanticsLabel(ImageDetailHero.viewerLabel));
    await settleRoute(tester);
    expect(find.byType(ImageViewerView), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(GlassIconButton.closeLabel));
    await settleRoute(tester);
    expect(find.byType(ImageViewerView), findsNothing);
    expect(find.byType(ImageDetailView), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(ImageDetailHero.viewerLabel));
    await settleRoute(tester);
    await systemBack(tester);
    await systemBack(tester);

    expect(find.byType(ImageViewerView), findsNothing);
    expect(find.byType(ImageDetailView), findsNothing);
    expect(find.byType(GalleryImageTile), findsWidgets);
    expect(tester.takeException(), isNull);
    verify(repository.getImages).called(1);
  });

  testWidgets('Details without an image argument shows the missing view', (
    tester,
  ) async {
    await pumpLoadedFeed(tester);

    Get.toNamed<void>(AppRoutes.imageDetail);
    await settleRoute(tester);
    expect(find.text(ImageDetailMissingView.missingTitle), findsOneWidget);

    await tester.tap(find.text(ImageDetailMissingView.backLabel));
    await settleRoute(tester);

    expect(find.byType(ImageDetailMissingView), findsNothing);
    expect(find.byType(GalleryImageTile), findsWidgets);
  });
}
