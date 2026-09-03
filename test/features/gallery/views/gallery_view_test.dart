import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pixabay_image_browser/features/gallery/controllers/gallery_controller.dart';
import 'package:pixabay_image_browser/features/gallery/models/pixabay_page.dart';
import 'package:pixabay_image_browser/features/gallery/repositories/gallery_repository.dart';
import 'package:pixabay_image_browser/features/gallery/services/pixabay_exception.dart';
import 'package:pixabay_image_browser/features/gallery/views/gallery_view.dart';
import 'package:pixabay_image_browser/features/gallery/widgets/gallery_chips.dart';
import 'package:pixabay_image_browser/features/gallery/widgets/gallery_error_view.dart';
import 'package:pixabay_image_browser/features/gallery/widgets/gallery_image_group.dart';
import 'package:pixabay_image_browser/features/gallery/widgets/gallery_search_empty_view.dart';
import 'package:pixabay_image_browser/features/gallery/widgets/gallery_search_field.dart';
import 'package:pixabay_image_browser/features/gallery/widgets/gallery_search_results_header.dart';
import 'package:pixabay_image_browser/features/gallery/widgets/gallery_searching_view.dart';
import 'package:pixabay_image_browser/features/gallery/widgets/gallery_skeleton.dart';
import 'package:pixabay_image_browser/features/gallery/widgets/glass_tab_bar.dart';

import '../../../support/pixabay_fixtures.dart';

class _MockRepository extends Mock implements GalleryRepository {}

// keeps tiles on the placeholder, no disk or http
class _FakeCacheManager extends Mock implements BaseCacheManager {}

void main() {
  late _MockRepository repository;

  setUpAll(() {
    // Fonts fall back to the test environment's defaults; no network.
    GoogleFonts.config.allowRuntimeFetching = false;
    final cacheManager = _FakeCacheManager();
    when(
      () => cacheManager.getFileStream(
        any(),
        key: any(named: 'key'),
        headers: any(named: 'headers'),
        withProgress: any(named: 'withProgress'),
      ),
    ).thenAnswer((_) => const Stream<FileResponse>.empty());
    CachedNetworkImageProvider.defaultCacheManager = cacheManager;
  });

  setUp(() {
    Get.testMode = true;
    repository = _MockRepository();
  });

  tearDown(Get.reset);

  Future<void> pumpGallery(WidgetTester tester) async {
    Get.put(GalleryController(repository: repository));
    await tester.pumpWidget(const GetMaterialApp(home: GalleryView()));
    await tester.pump();
  }

  testWidgets('shows the skeleton while the first page is loading', (
    tester,
  ) async {
    final never = Completer<PixabayPage>();
    when(repository.getImages).thenAnswer((_) => never.future);

    await pumpGallery(tester);

    expect(find.text('Aperture'), findsOneWidget);
    expect(find.byType(GallerySkeleton), findsOneWidget);
    expect(find.byType(GallerySearchField), findsOneWidget);
    expect(find.byType(GlassTabBar), findsOneWidget);
    expect(find.text(GalleryErrorView.retryLabel), findsNothing);
  });

  testWidgets('shows the offline screen and retries on tap', (tester) async {
    when(repository.getImages).thenAnswer(
      (_) => Future<PixabayPage>.error(const PixabayNetworkException()),
    );

    await pumpGallery(tester);

    expect(find.text(GalleryErrorView.offlineTitle), findsOneWidget);
    expect(find.byType(GallerySearchField), findsOneWidget);

    await tester.tap(find.text(GalleryErrorView.retryLabel));
    await tester.pump();

    verify(repository.getImages).called(2);
  });

  testWidgets('shows the API error screen with the request label', (
    tester,
  ) async {
    when(repository.getImages).thenAnswer(
      (_) => Future<PixabayPage>.error(
        const PixabayApiException(
          statusCode: 500,
          path: '/api/?editors_choice=true',
        ),
      ),
    );

    await pumpGallery(tester);

    expect(find.text(GalleryErrorView.apiTitle), findsOneWidget);
    expect(find.text('HTTP 500 · /api/?editors_choice=true'), findsOneWidget);
    expect(find.text(GalleryErrorView.retryLabel), findsOneWidget);
  });

  testWidgets('shows the missing-key instructions without a retry button', (
    tester,
  ) async {
    when(repository.getImages).thenAnswer(
      (_) => Future<PixabayPage>.error(const PixabayMissingKeyException()),
    );

    await pumpGallery(tester);

    expect(find.text(GalleryErrorView.missingKeyTitle), findsOneWidget);
    expect(
      find.textContaining('--dart-define=PIXABAY_API_KEY'),
      findsOneWidget,
    );
    expect(find.text(GalleryErrorView.retryLabel), findsNothing);
  });

  group('search', () {
    const debounce = GalleryController.debounceDuration;

    PixabayPage pageWith(int count) =>
        PixabayPage.fromJson(samplePage(hitCount: count));

    Future<void> pumpLoadedFeed(WidgetTester tester, {int hits = 4}) async {
      when(repository.getImages).thenAnswer((_) async => pageWith(hits));
      await pumpGallery(tester);
      expect(find.byType(GalleryChips), findsOneWidget);
    }

    Future<void> typeAndWait(WidgetTester tester, String text) async {
      await tester.enterText(find.byType(TextField), text);
      await tester.pump(debounce);
      await tester.pump();
    }

    testWidgets('typing keeps focus through the searching state', (
      tester,
    ) async {
      await pumpLoadedFeed(tester);
      final pending = Completer<PixabayPage>();
      when(
        () => repository.getImages(query: 'fog'),
      ).thenAnswer((_) => pending.future);

      await tester.tap(find.byType(TextField));
      await tester.pump();
      await typeAndWait(tester, 'fog');

      expect(find.text(GallerySearchingView.message('fog')), findsOneWidget);
      expect(find.byType(GalleryChips), findsNothing);
      expect(find.byType(GalleryImageGroup), findsNothing);
      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.focusNode.hasFocus, isTrue);
      expect(editable.controller.text, 'fog');

      pending.complete(pageWith(0));
      await tester.pump();

      expect(find.text(GallerySearchEmptyView.title('fog')), findsOneWidget);
      expect(find.text(GallerySearchEmptyView.body), findsOneWidget);
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders results with the header instead of chips', (
      tester,
    ) async {
      await pumpLoadedFeed(tester);
      when(
        () => repository.getImages(query: 'fog'),
      ).thenAnswer((_) async => pageWith(5));

      await typeAndWait(tester, 'fog');

      expect(
        find.text(GallerySearchResultsHeader.countLabel(500)),
        findsOneWidget,
      );
      expect(
        find.text(GallerySearchResultsHeader.queryLabel('fog')),
        findsOneWidget,
      );
      // lazy sliver, only one group fits
      expect(find.byType(GalleryImageGroup), findsAtLeastNWidgets(1));
      expect(find.byType(GalleryChips), findsNothing);
      expect(
        find.bySemanticsLabel(GallerySearchField.clearLabel),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty state suggestions search immediately', (tester) async {
      await pumpLoadedFeed(tester);
      when(
        () => repository.getImages(query: 'zzz'),
      ).thenAnswer((_) async => pageWith(0));
      when(
        () => repository.getImages(query: 'ceramic'),
      ).thenAnswer((_) async => pageWith(3));
      await typeAndWait(tester, 'zzz');
      expect(find.text(GallerySearchEmptyView.title('zzz')), findsOneWidget);

      await tester.tap(find.text('ceramic'));
      await tester.pump();

      verify(() => repository.getImages(query: 'ceramic')).called(1);
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        'ceramic',
      );
      expect(
        find.text(GallerySearchResultsHeader.queryLabel('ceramic')),
        findsOneWidget,
      );
    });

    testWidgets('"Back to browsing" restores the feed without a request', (
      tester,
    ) async {
      await pumpLoadedFeed(tester);
      when(
        () => repository.getImages(query: 'zzz'),
      ).thenAnswer((_) async => pageWith(0));
      await typeAndWait(tester, 'zzz');

      await tester.tap(find.text(GallerySearchEmptyView.backLabel));
      await tester.pump();

      expect(find.byType(GalleryChips), findsOneWidget);
      expect(find.byType(GalleryImageGroup), findsOneWidget);
      expect(find.byType(GallerySkeleton), findsNothing);
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        isEmpty,
      );
      verify(repository.getImages).called(1);
    });

    testWidgets('the clear pill restores the feed and keeps the keyboard', (
      tester,
    ) async {
      await pumpLoadedFeed(tester);
      when(
        () => repository.getImages(query: 'fog'),
      ).thenAnswer((_) async => pageWith(5));
      expect(
        find.bySemanticsLabel(GallerySearchField.clearLabel),
        findsNothing,
      );

      await tester.tap(find.byType(TextField));
      await tester.pump();
      await typeAndWait(tester, 'fog');
      await tester.tap(find.bySemanticsLabel(GallerySearchField.clearLabel));
      await tester.pump();

      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );
      expect(find.text(GallerySearchField.cancelLabel), findsOneWidget);
      expect(
        find.bySemanticsLabel(GallerySearchField.clearLabel),
        findsNothing,
      );
      expect(find.byType(GalleryChips), findsOneWidget);
      expect(
        find.text(GallerySearchResultsHeader.queryLabel('fog')),
        findsNothing,
      );
      verify(repository.getImages).called(1);
    });

    testWidgets('a failed search keeps the field and retries the query', (
      tester,
    ) async {
      await pumpLoadedFeed(tester);
      var calls = 0;
      when(() => repository.getImages(query: 'fog')).thenAnswer((_) {
        calls++;
        if (calls == 1) {
          return Future<PixabayPage>.error(const PixabayNetworkException());
        }
        return Future<PixabayPage>.value(pageWith(2));
      });
      await typeAndWait(tester, 'fog');

      expect(find.text(GalleryErrorView.offlineTitle), findsOneWidget);
      expect(find.byType(GallerySearchField), findsOneWidget);
      expect(find.byType(GalleryChips), findsNothing);

      await tester.tap(find.text(GalleryErrorView.retryLabel));
      await tester.pump();
      await tester.pump();

      verify(() => repository.getImages(query: 'fog')).called(2);
      verify(repository.getImages).called(1);
      expect(
        find.text(GallerySearchResultsHeader.queryLabel('fog')),
        findsOneWidget,
      );
    });

    testWidgets('"Back to browsing" also dismisses the keyboard', (
      tester,
    ) async {
      await pumpLoadedFeed(tester);
      when(
        () => repository.getImages(query: 'zzz'),
      ).thenAnswer((_) async => pageWith(0));
      await tester.tap(find.byType(TextField));
      await tester.pump();
      await typeAndWait(tester, 'zzz');
      expect(find.text(GallerySearchField.cancelLabel), findsOneWidget);

      await tester.tap(find.text(GallerySearchEmptyView.backLabel));
      await tester.pump();

      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isFalse,
      );
      expect(find.text(GallerySearchField.cancelLabel), findsNothing);
    });

    testWidgets('the skeleton can be scrolled back to the header', (
      tester,
    ) async {
      when(repository.getImages).thenAnswer(
        (_) => Future<PixabayPage>.error(const PixabayNetworkException()),
      );
      await pumpGallery(tester);
      when(
        () => repository.getImages(query: 'fog'),
      ).thenAnswer((_) async => pageWith(20));
      await typeAndWait(tester, 'fog');
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -2000));
      await tester.pump();
      expect(find.text('Aperture'), findsNothing);

      final reload = Completer<PixabayPage>();
      when(repository.getImages).thenAnswer((_) => reload.future);
      // pill is off-screen here
      Get.find<GalleryController>().clearSearch();
      await tester.pump();
      expect(find.byType(GallerySkeleton), findsOneWidget);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, 2000));
      await tester.pump();

      expect(find.text('Aperture'), findsOneWidget);
    });

    testWidgets('clearing a scrolled result list lands on the header', (
      tester,
    ) async {
      await pumpLoadedFeed(tester, hits: 20);
      when(
        () => repository.getImages(query: 'fog'),
      ).thenAnswer((_) async => pageWith(20));
      await typeAndWait(tester, 'fog');
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -2000));
      await tester.pump();
      expect(find.text('Aperture'), findsNothing);

      Get.find<GalleryController>().clearSearch();
      await tester.pump();

      expect(find.text('Aperture'), findsOneWidget);
      expect(find.byType(GalleryChips), findsOneWidget);
    });

    testWidgets('the API error caption names the searched query', (
      tester,
    ) async {
      await pumpLoadedFeed(tester);
      when(() => repository.getImages(query: 'fog')).thenAnswer(
        (_) => Future<PixabayPage>.error(
          const PixabayApiException(statusCode: 500, path: '/api/?q=fog'),
        ),
      );

      await typeAndWait(tester, 'fog');

      expect(find.text(GalleryErrorView.apiTitle), findsOneWidget);
      expect(find.text('HTTP 500 · /api/?q=fog'), findsOneWidget);
    });
  });
}
