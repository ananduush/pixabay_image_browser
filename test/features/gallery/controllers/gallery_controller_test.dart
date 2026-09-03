import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pixabay_image_browser/features/gallery/controllers/gallery_controller.dart';
import 'package:pixabay_image_browser/features/gallery/controllers/gallery_state.dart';
import 'package:pixabay_image_browser/features/gallery/models/pixabay_image.dart';
import 'package:pixabay_image_browser/features/gallery/models/pixabay_page.dart';
import 'package:pixabay_image_browser/features/gallery/repositories/gallery_repository.dart';
import 'package:pixabay_image_browser/features/gallery/services/pixabay_exception.dart';

import '../../../support/pixabay_fixtures.dart';

class _MockRepository extends Mock implements GalleryRepository {}

void main() {
  late _MockRepository repository;

  setUp(() {
    Get.testMode = true;
    repository = _MockRepository();
  });

  tearDown(Get.reset);

  PixabayPage pageWith(int count) =>
      PixabayPage.fromJson(samplePage(hitCount: count));

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  void stubPage(String query, int page, {int hits = 20, int totalHits = 500}) {
    when(
      () => repository.getImages(query: query, page: page, perPage: 20),
    ).thenAnswer(
      (_) async => PixabayPage.fromJson(
        samplePage(hitCount: hits, firstId: page * 1000, totalHits: totalHits),
      ),
    );
  }

  Completer<PixabayPage> pendingPage(String query, int page) {
    final pending = Completer<PixabayPage>();
    when(
      () => repository.getImages(query: query, page: page, perPage: 20),
    ).thenAnswer((_) => pending.future);
    return pending;
  }

  test('starts in the loading state', () {
    when(repository.getImages).thenAnswer((_) async => pageWith(1));

    final controller = GalleryController(repository: repository);

    expect(controller.state.value, isA<GalleryLoading>());
  });

  test('onInit loads images and exposes them as loaded', () async {
    when(repository.getImages).thenAnswer((_) async => pageWith(5));

    final controller = GalleryController(repository: repository)..onInit();
    await settle();

    final state = controller.state.value;
    expect(state, isA<GalleryLoaded>());
    expect((state as GalleryLoaded).images, hasLength(5));
    verify(repository.getImages).called(1);
  });

  test(
    'a network failure becomes GalleryFailure(PixabayNetworkException)',
    () async {
      when(repository.getImages).thenAnswer(
        (_) => Future<PixabayPage>.error(const PixabayNetworkException()),
      );

      final controller = GalleryController(repository: repository)..onInit();
      await settle();

      expect(
        controller.state.value,
        isA<GalleryFailure>().having(
          (s) => s.error,
          'error',
          isA<PixabayNetworkException>(),
        ),
      );
    },
  );

  test('an API failure becomes GalleryFailure(PixabayApiException)', () async {
    when(repository.getImages).thenAnswer(
      (_) => Future<PixabayPage>.error(
        const PixabayApiException(
          statusCode: 500,
          path: '/api/?editors_choice=true',
        ),
      ),
    );

    final controller = GalleryController(repository: repository)..onInit();
    await settle();

    expect(
      controller.state.value,
      isA<GalleryFailure>().having(
        (s) => (s.error as PixabayApiException).statusCode,
        'statusCode',
        500,
      ),
    );
  });

  test(
    'a missing key becomes GalleryFailure(PixabayMissingKeyException)',
    () async {
      when(repository.getImages).thenAnswer(
        (_) => Future<PixabayPage>.error(const PixabayMissingKeyException()),
      );

      final controller = GalleryController(repository: repository)..onInit();
      await settle();

      expect(
        controller.state.value,
        isA<GalleryFailure>().having(
          (s) => s.error,
          'error',
          isA<PixabayMissingKeyException>(),
        ),
      );
    },
  );

  test('retry goes back through loading and recovers', () async {
    var calls = 0;
    when(repository.getImages).thenAnswer((_) {
      calls++;
      if (calls == 1) {
        return Future<PixabayPage>.error(const PixabayNetworkException());
      }
      return Future<PixabayPage>.value(pageWith(2));
    });
    final controller = GalleryController(repository: repository)..onInit();
    await settle();
    expect(controller.state.value, isA<GalleryFailure>());

    final observed = <GalleryState>[];
    controller.state.listen(observed.add);
    await controller.loadImages();

    expect(observed.map((s) => s.runtimeType), <Type>[
      GalleryLoading,
      GalleryLoaded,
    ]);
    verify(repository.getImages).called(2);
  });

  test('unexpected errors surface a retryable failure and rethrow', () async {
    when(
      repository.getImages,
    ).thenAnswer((_) => Future<PixabayPage>.error(StateError('bug')));

    final controller = GalleryController(repository: repository);

    await expectLater(controller.loadImages(), throwsStateError);
    expect(
      controller.state.value,
      isA<GalleryFailure>().having(
        (s) => s.error,
        'error',
        isA<PixabayUnexpectedException>(),
      ),
    );
  });

  test('GalleryLoaded groups images as hero + up to three tiles', () {
    final images = pageWith(9).hits;

    final groups = GalleryLoaded(images).groups;

    expect(groups.map((g) => g.length), <int>[4, 4, 1]);
    expect(groups.first.first, images.first);
    expect(
      groups.last.single,
      isA<PixabayImage>().having((i) => i.id, 'id', 108),
    );
    expect(const GalleryLoaded(<PixabayImage>[]).groups, isEmpty);
  });

  group('search', () {
    const debounce = GalleryController.debounceDuration;

    GalleryController exploreLoaded(FakeAsync async, {int hits = 3}) {
      when(repository.getImages).thenAnswer((_) async => pageWith(hits));
      final controller = GalleryController(repository: repository)..onInit();
      async.flushMicrotasks();
      expect(controller.state.value, isA<GalleryLoaded>());
      return controller;
    }

    void stubSearch(String query, {int hits = 2}) {
      when(
        () => repository.getImages(query: query),
      ).thenAnswer((_) async => pageWith(hits));
    }

    // same as a keystroke in the text field
    void type(GalleryController controller, String text) {
      controller.searchController.text = text;
      controller.onQueryChanged(text);
    }

    test('debounces keystrokes into one request for the final term', () {
      fakeAsync((async) {
        final controller = exploreLoaded(async);
        stubSearch('cats');

        for (final text in <String>['c', 'ca', 'cat', 'cats']) {
          type(controller, text);
          async.elapse(debounce ~/ 2);
        }
        expect(controller.state.value, isA<GalleryLoaded>());
        verifyNever(
          () => repository.getImages(
            query: any(named: 'query', that: isNotEmpty),
          ),
        );

        async.elapse(debounce);

        verify(() => repository.getImages(query: 'cats')).called(1);
        verifyNever(() => repository.getImages(query: 'c'));
        expect(
          controller.state.value,
          isA<GalleryLoaded>()
              .having((s) => s.query, 'query', 'cats')
              .having((s) => s.images, 'images', hasLength(2))
              .having((s) => s.totalHits, 'totalHits', 500),
        );
      });
    });

    test('shows the searching state while the request is in flight', () {
      fakeAsync((async) {
        final controller = exploreLoaded(async);
        final pending = Completer<PixabayPage>();
        when(
          () => repository.getImages(query: 'fog'),
        ).thenAnswer((_) => pending.future);

        type(controller, 'fog');
        async.elapse(debounce);

        expect(
          controller.state.value,
          isA<GalleryLoading>().having((s) => s.query, 'query', 'fog'),
        );
      });
    });

    test('whitespace-only input stays on Explore without a request', () {
      fakeAsync((async) {
        final controller = exploreLoaded(async);

        type(controller, '   ');
        async.elapse(debounce);

        expect(controller.state.value.isSearch, isFalse);
        verify(repository.getImages).called(1);
        verifyNever(
          () => repository.getImages(
            query: any(named: 'query', that: isNotEmpty),
          ),
        );
      });
    });

    test('deleting the text before the debounce fires sends nothing', () {
      fakeAsync((async) {
        final controller = exploreLoaded(async);

        type(controller, 'f');
        async.elapse(debounce ~/ 2);
        type(controller, '');
        async.elapse(debounce);

        verifyNever(
          () => repository.getImages(
            query: any(named: 'query', that: isNotEmpty),
          ),
        );
        expect(controller.state.value.isSearch, isFalse);
      });
    });

    test('retyping the term already shown does not search again', () {
      fakeAsync((async) {
        final controller = exploreLoaded(async);
        stubSearch('fog');
        type(controller, 'fog');
        async.elapse(debounce);

        type(controller, 'fog ');
        async.elapse(debounce);

        verify(() => repository.getImages(query: 'fog')).called(1);
      });
    });

    test('zero hits is an empty search result, not a failure', () {
      fakeAsync((async) {
        final controller = exploreLoaded(async);
        stubSearch('zzz', hits: 0);

        type(controller, 'zzz');
        async.elapse(debounce);

        expect(
          controller.state.value,
          isA<GalleryLoaded>()
              .having((s) => s.images, 'images', isEmpty)
              .having((s) => s.query, 'query', 'zzz')
              .having((s) => s.isSearch, 'isSearch', isTrue),
        );
      });
    });

    test('a failed search keeps its query and retry re-runs that query', () {
      fakeAsync((async) {
        final controller = exploreLoaded(async);
        var calls = 0;
        when(() => repository.getImages(query: 'fog')).thenAnswer((_) {
          calls++;
          if (calls == 1) {
            return Future<PixabayPage>.error(const PixabayNetworkException());
          }
          return Future<PixabayPage>.value(pageWith(4));
        });
        type(controller, 'fog');
        async.elapse(debounce);
        expect(
          controller.state.value,
          isA<GalleryFailure>()
              .having((s) => s.error, 'error', isA<PixabayNetworkException>())
              .having((s) => s.query, 'query', 'fog'),
        );

        final observed = <GalleryState>[];
        controller.state.listen(observed.add);
        unawaited(controller.retry());
        async.flushMicrotasks();

        expect(observed.map((s) => (s.runtimeType, s.query)), <(Type, String)>[
          (GalleryLoading, 'fog'),
          (GalleryLoaded, 'fog'),
        ]);
        verify(() => repository.getImages(query: 'fog')).called(2);
        verify(repository.getImages).called(1);
      });
    });

    test('retry from an Explore failure reloads the curated feed', () async {
      when(repository.getImages).thenAnswer(
        (_) => Future<PixabayPage>.error(const PixabayNetworkException()),
      );
      final controller = GalleryController(repository: repository)..onInit();
      await settle();

      await controller.retry();

      verify(repository.getImages).called(2);
      verifyNever(
        () => repository.getImages(
          query: any(named: 'query', that: isNotEmpty),
        ),
      );
    });

    test('clearing restores the cached feed instantly without a request', () {
      fakeAsync((async) {
        final controller = exploreLoaded(async, hits: 3);
        stubSearch('fog');
        type(controller, 'fog');
        async.elapse(debounce);

        controller.clearSearch();

        expect(controller.searchController.text, isEmpty);
        expect(
          controller.state.value,
          isA<GalleryLoaded>()
              .having((s) => s.isSearch, 'isSearch', isFalse)
              .having((s) => s.images, 'images', hasLength(3)),
        );
        async.elapse(debounce);
        verify(repository.getImages).called(1);
      });
    });

    test('clearing with nothing cached reloads the curated feed', () {
      fakeAsync((async) {
        final explore = Completer<PixabayPage>();
        when(repository.getImages).thenAnswer((_) => explore.future);
        final controller = GalleryController(repository: repository)..onInit();
        stubSearch('fog');
        type(controller, 'fog');
        async.elapse(debounce);

        controller.clearSearch();

        expect(controller.state.value, isA<GalleryLoading>());
        verify(repository.getImages).called(2);
      });
    });

    test('a search that completes after clearing cannot replace the feed', () {
      fakeAsync((async) {
        final controller = exploreLoaded(async);
        final pending = Completer<PixabayPage>();
        when(
          () => repository.getImages(query: 'fog'),
        ).thenAnswer((_) => pending.future);
        type(controller, 'fog');
        async.elapse(debounce);
        expect(controller.state.value, isA<GalleryLoading>());

        controller.clearSearch();
        pending.complete(pageWith(9));
        async.flushMicrotasks();

        expect(
          controller.state.value,
          isA<GalleryLoaded>()
              .having((s) => s.isSearch, 'isSearch', isFalse)
              .having((s) => s.images, 'images', hasLength(3)),
        );
      });
    });

    test('an older search response cannot overwrite a newer one', () {
      fakeAsync((async) {
        final controller = exploreLoaded(async);
        final mount = Completer<PixabayPage>();
        final mountains = Completer<PixabayPage>();
        when(
          () => repository.getImages(query: 'mount'),
        ).thenAnswer((_) => mount.future);
        when(
          () => repository.getImages(query: 'mountains'),
        ).thenAnswer((_) => mountains.future);

        type(controller, 'mount');
        async.elapse(debounce);
        type(controller, 'mountains');
        async.elapse(debounce);
        verify(() => repository.getImages(query: 'mount')).called(1);
        verify(() => repository.getImages(query: 'mountains')).called(1);

        mountains.complete(pageWith(5));
        async.flushMicrotasks();
        mount.complete(pageWith(1));
        async.flushMicrotasks();

        expect(
          controller.state.value,
          isA<GalleryLoaded>()
              .having((s) => s.query, 'query', 'mountains')
              .having((s) => s.images, 'images', hasLength(5)),
        );
      });
    });

    test('a stale failure cannot overwrite a newer result either', () {
      fakeAsync((async) {
        final controller = exploreLoaded(async);
        final mount = Completer<PixabayPage>();
        when(
          () => repository.getImages(query: 'mount'),
        ).thenAnswer((_) => mount.future);
        stubSearch('mountains');

        type(controller, 'mount');
        async.elapse(debounce);
        type(controller, 'mountains');
        async.elapse(debounce);
        mount.completeError(const PixabayNetworkException());
        async.flushMicrotasks();

        expect(
          controller.state.value,
          isA<GalleryLoaded>().having((s) => s.query, 'query', 'mountains'),
        );
      });
    });

    test('search() runs immediately and mirrors the term into the field', () {
      fakeAsync((async) {
        final controller = exploreLoaded(async);
        stubSearch('ceramic');

        unawaited(controller.search('  ceramic '));
        async.flushMicrotasks();

        expect(controller.searchController.text, 'ceramic');
        expect(
          controller.state.value,
          isA<GalleryLoaded>().having((s) => s.query, 'query', 'ceramic'),
        );
        verify(() => repository.getImages(query: 'ceramic')).called(1);

        unawaited(controller.search('ceramic'));
        async.flushMicrotasks();
        verifyNever(() => repository.getImages(query: 'ceramic'));
      });
    });

    test('search() with a blank term restores Explore', () {
      fakeAsync((async) {
        final controller = exploreLoaded(async);
        stubSearch('fog');
        type(controller, 'fog');
        async.elapse(debounce);

        unawaited(controller.search('   '));
        async.flushMicrotasks();

        expect(controller.searchController.text, isEmpty);
        expect(controller.state.value.isSearch, isFalse);
      });
    });

    test('an unexpected search error is a retryable failure and rethrows', () {
      fakeAsync((async) {
        final controller = exploreLoaded(async);
        when(
          () => repository.getImages(query: 'fog'),
        ).thenAnswer((_) => Future<PixabayPage>.error(StateError('bug')));

        Object? thrown;
        controller.search('fog').catchError((Object error) => thrown = error);
        async.flushMicrotasks();

        expect(thrown, isStateError);
        expect(
          controller.state.value,
          isA<GalleryFailure>()
              .having(
                (s) => s.error,
                'error',
                isA<PixabayUnexpectedException>(),
              )
              .having((s) => s.query, 'query', 'fog'),
        );
      });
    });

    test('retyping a failed query runs it again', () {
      fakeAsync((async) {
        final controller = exploreLoaded(async);
        var calls = 0;
        when(() => repository.getImages(query: 'fog')).thenAnswer((_) {
          calls++;
          if (calls == 1) {
            return Future<PixabayPage>.error(const PixabayNetworkException());
          }
          return Future<PixabayPage>.value(pageWith(2));
        });
        type(controller, 'fog');
        async.elapse(debounce);
        expect(controller.state.value, isA<GalleryFailure>());

        type(controller, 'fogs');
        async.elapse(debounce ~/ 2);
        type(controller, 'fog');
        async.elapse(debounce);

        verify(() => repository.getImages(query: 'fog')).called(2);
        expect(
          controller.state.value,
          isA<GalleryLoaded>().having((s) => s.query, 'query', 'fog'),
        );
      });
    });

    test('picking the suggestion that matches a zero-hit query re-runs it', () {
      fakeAsync((async) {
        final controller = exploreLoaded(async);
        stubSearch('ceramic', hits: 0);
        type(controller, 'ceramic');
        async.elapse(debounce);
        expect(
          controller.state.value,
          isA<GalleryLoaded>().having((s) => s.images, 'images', isEmpty),
        );

        unawaited(controller.search('ceramic'));
        async.flushMicrotasks();

        verify(() => repository.getImages(query: 'ceramic')).called(2);
      });
    });

    test('cancelSearch clears like the pill and also drops focus', () {
      fakeAsync((async) {
        final controller = exploreLoaded(async);
        stubSearch('fog');
        type(controller, 'fog');
        async.elapse(debounce);

        controller.cancelSearch();

        expect(controller.searchController.text, isEmpty);
        expect(controller.state.value.isSearch, isFalse);
        expect(controller.searchFocus.hasFocus, isFalse);
      });
    });

    test('a curated page arriving after a search started is still cached', () {
      fakeAsync((async) {
        final explore = Completer<PixabayPage>();
        when(repository.getImages).thenAnswer((_) => explore.future);
        final controller = GalleryController(repository: repository)..onInit();
        stubSearch('fog');
        type(controller, 'fog');
        async.elapse(debounce);
        expect(
          controller.state.value,
          isA<GalleryLoaded>().having((s) => s.query, 'query', 'fog'),
        );

        explore.complete(pageWith(3));
        async.flushMicrotasks();
        expect(controller.state.value.query, 'fog');

        controller.clearSearch();

        expect(
          controller.state.value,
          isA<GalleryLoaded>()
              .having((s) => s.isSearch, 'isSearch', isFalse)
              .having((s) => s.images, 'images', hasLength(3)),
        );
        verify(repository.getImages).called(1);
      });
    });

    test('retry cancels a pending debounce and runs the typed term', () {
      fakeAsync((async) {
        final controller = exploreLoaded(async);
        when(() => repository.getImages(query: 'fog')).thenAnswer(
          (_) => Future<PixabayPage>.error(const PixabayNetworkException()),
        );
        stubSearch('fogs');
        type(controller, 'fog');
        async.elapse(debounce);
        expect(controller.state.value, isA<GalleryFailure>());

        type(controller, 'fogs');
        unawaited(controller.retry());
        async.flushMicrotasks();
        async.elapse(debounce);

        verify(() => repository.getImages(query: 'fog')).called(1);
        verify(() => repository.getImages(query: 'fogs')).called(1);
        expect(
          controller.state.value,
          isA<GalleryLoaded>().having((s) => s.query, 'query', 'fogs'),
        );
      });
    });

    test('a missing key is logged once, not on every search', () {
      fakeAsync((async) {
        when(repository.getImages).thenAnswer(
          (_) => Future<PixabayPage>.error(const PixabayMissingKeyException()),
        );
        when(
          () => repository.getImages(
            query: any(named: 'query', that: isNotEmpty),
          ),
        ).thenAnswer(
          (_) => Future<PixabayPage>.error(const PixabayMissingKeyException()),
        );
        final logs = <String>[];
        final previous = debugPrint;
        debugPrint = (String? message, {int? wrapWidth}) {
          if (message != null) logs.add(message);
        };
        addTearDown(() => debugPrint = previous);

        final controller = GalleryController(repository: repository)..onInit();
        async.flushMicrotasks();
        type(controller, 'fog');
        async.elapse(debounce);
        type(controller, 'fogs');
        async.elapse(debounce);

        expect(logs, hasLength(1));
        expect(
          controller.state.value,
          isA<GalleryFailure>()
              .having(
                (s) => s.error,
                'error',
                isA<PixabayMissingKeyException>(),
              )
              .having((s) => s.query, 'query', 'fogs'),
        );
      });
    });

    test('onClose cancels a pending debounce', () {
      fakeAsync((async) {
        final controller = exploreLoaded(async);
        stubSearch('fog');

        type(controller, 'fog');
        controller.onClose();
        async.elapse(debounce);

        verifyNever(() => repository.getImages(query: 'fog'));
      });
    });
  });

  group('pagination', () {
    GalleryController exploreLoaded(
      FakeAsync async, {
      int hits = 20,
      int totalHits = 500,
    }) {
      stubPage('', 1, hits: hits, totalHits: totalHits);
      final controller = GalleryController(repository: repository)..onInit();
      async.flushMicrotasks();
      expect(controller.state.value, isA<GalleryLoaded>());
      return controller;
    }

    test('page 1 loads with page == 1 and FeedIdle when 20 < totalHits', () {
      fakeAsync((async) {
        final controller = exploreLoaded(async, hits: 20, totalHits: 500);

        expect(
          controller.state.value,
          isA<GalleryLoaded>()
              .having((s) => s.page, 'page', 1)
              .having((s) => s.status, 'status', isA<FeedIdle>())
              .having((s) => s.images, 'images', hasLength(20)),
        );
      });
    });

    test('page 1 with totalHits: 20 is FeedEnd', () {
      fakeAsync((async) {
        final controller = exploreLoaded(async, hits: 20, totalHits: 20);

        expect(
          controller.state.value,
          isA<GalleryLoaded>().having(
            (s) => s.status,
            'status',
            isA<FeedEnd>(),
          ),
        );
      });
    });

    test('an empty page 1 is FeedEnd', () {
      fakeAsync((async) {
        final controller = exploreLoaded(async, hits: 0);

        expect(
          controller.state.value,
          isA<GalleryLoaded>()
              .having((s) => s.status, 'status', isA<FeedEnd>())
              .having((s) => s.images, 'images', isEmpty),
        );
      });
    });

    test('loadMore requests page 2 with the same query and appends', () {
      fakeAsync((async) {
        final controller = exploreLoaded(async);
        stubPage('', 2);

        unawaited(controller.loadMore());
        async.flushMicrotasks();

        verify(
          () => repository.getImages(query: '', page: 2, perPage: 20),
        ).called(1);
        final state = controller.state.value;
        expect(state, isA<GalleryLoaded>());
        expect(
          state,
          isA<GalleryLoaded>()
              .having((s) => s.page, 'page', 2)
              .having((s) => s.images, 'images', hasLength(40)),
        );
        final images = (state as GalleryLoaded).images;
        expect(images.take(20).map((i) => i.id), [
          for (var i = 0; i < 20; i++) 1000 + i,
        ]);
        expect(images.skip(20).map((i) => i.id), [
          for (var i = 0; i < 20; i++) 2000 + i,
        ]);
      });
    });

    test(
      'loadMore called twice while page 2 is pending issues one request',
      () {
        fakeAsync((async) {
          final controller = exploreLoaded(async);
          pendingPage('', 2);

          unawaited(controller.loadMore());
          unawaited(controller.loadMore());
          async.flushMicrotasks();

          verify(
            () => repository.getImages(query: '', page: 2, perPage: 20),
          ).called(1);
          expect(
            controller.state.value,
            isA<GalleryLoaded>().having(
              (s) => s.status,
              'status',
              isA<FeedLoadingMore>(),
            ),
          );
        });
      },
    );

    test(
      'loadMore during FeedEnd, FeedRefreshing and FeedLoadMoreFailed issues no request',
      () {
        fakeAsync((async) {
          final ended = exploreLoaded(async, hits: 20, totalHits: 20);
          unawaited(ended.loadMore());
          async.flushMicrotasks();
          verifyNever(
            () => repository.getImages(query: '', page: 2, perPage: 20),
          );

          final refreshing = exploreLoaded(async);
          pendingPage('', 1);
          unawaited(refreshing.refreshFeed());
          async.flushMicrotasks();
          unawaited(refreshing.loadMore());
          async.flushMicrotasks();
          verifyNever(
            () => repository.getImages(query: '', page: 2, perPage: 20),
          );

          final failed = exploreLoaded(async);
          var page2Calls = 0;
          when(
            () => repository.getImages(query: '', page: 2, perPage: 20),
          ).thenAnswer((_) {
            page2Calls++;
            return Future<PixabayPage>.error(const PixabayNetworkException());
          });
          unawaited(failed.loadMore());
          async.flushMicrotasks();
          expect(page2Calls, 1);
          unawaited(failed.loadMore());
          async.flushMicrotasks();
          expect(page2Calls, 1);
        });
      },
    );

    test('page-2 failure keeps images, FeedLoadMoreFailed, page still 1', () {
      fakeAsync((async) {
        final controller = exploreLoaded(async);
        const error = PixabayNetworkException();
        when(
          () => repository.getImages(query: '', page: 2, perPage: 20),
        ).thenAnswer((_) => Future<PixabayPage>.error(error));

        unawaited(controller.loadMore());
        async.flushMicrotasks();

        expect(
          controller.state.value,
          isA<GalleryLoaded>()
              .having((s) => s.images, 'images', hasLength(20))
              .having((s) => s.page, 'page', 1)
              .having(
                (s) => s.status,
                'status',
                isA<FeedLoadMoreFailed>().having(
                  (f) => f.error,
                  'error',
                  error,
                ),
              ),
        );
      });
    });

    test(
      'retryLoadMore requests page 2 again, transitions through FeedLoadingMore, appends once',
      () {
        fakeAsync((async) {
          final controller = exploreLoaded(async);
          var calls = 0;
          final retry = Completer<PixabayPage>();
          when(
            () => repository.getImages(query: '', page: 2, perPage: 20),
          ).thenAnswer((_) {
            calls++;
            if (calls == 1) {
              return Future<PixabayPage>.error(const PixabayNetworkException());
            }
            return retry.future;
          });
          unawaited(controller.loadMore());
          async.flushMicrotasks();
          expect(
            controller.state.value,
            isA<GalleryLoaded>().having(
              (s) => s.status,
              'status',
              isA<FeedLoadMoreFailed>(),
            ),
          );

          final observed = <GalleryState>[];
          controller.state.listen(observed.add);
          unawaited(controller.retryLoadMore());
          async.flushMicrotasks();
          expect(
            observed.first,
            isA<GalleryLoaded>().having(
              (s) => s.status,
              'status',
              isA<FeedLoadingMore>(),
            ),
          );

          retry.complete(
            PixabayPage.fromJson(
              samplePage(hitCount: 20, firstId: 2000, totalHits: 500),
            ),
          );
          async.flushMicrotasks();

          verify(
            () => repository.getImages(query: '', page: 2, perPage: 20),
          ).called(2);
          verifyNever(
            () => repository.getImages(query: '', page: 3, perPage: 20),
          );
          expect(
            controller.state.value,
            isA<GalleryLoaded>()
                .having((s) => s.page, 'page', 2)
                .having((s) => s.images, 'images', hasLength(40)),
          );
        });
      },
    );

    test('a page-2 hit sharing an id with page 1 is not appended twice', () {
      fakeAsync((async) {
        final controller = exploreLoaded(async);
        when(
          () => repository.getImages(query: '', page: 2, perPage: 20),
        ).thenAnswer(
          (_) async => PixabayPage.fromJson(
            samplePage(hitCount: 20, firstId: 1000, totalHits: 500),
          ),
        );

        unawaited(controller.loadMore());
        async.flushMicrotasks();

        expect(
          controller.state.value,
          isA<GalleryLoaded>().having((s) => s.images, 'images', hasLength(20)),
        );
      });
    });

    test('an id repeated inside one response is kept once', () {
      fakeAsync((async) {
        when(
          () => repository.getImages(query: '', page: 1, perPage: 20),
        ).thenAnswer(
          (_) async => PixabayPage.fromJson(<String, dynamic>{
            'total': 3,
            'totalHits': 500,
            'hits': <Map<String, dynamic>>[
              sampleHit(id: 1),
              sampleHit(id: 1),
              sampleHit(id: 2),
            ],
          }),
        );

        final controller = GalleryController(repository: repository)..onInit();
        async.flushMicrotasks();

        expect(
          controller.state.value,
          isA<GalleryLoaded>().having(
            (s) => s.images.map((image) => image.id).toList(),
            'ids',
            <int>[1, 2],
          ),
        );
        controller.onClose();
      });
    });

    test('page 2 drops both its internal repeats and page-1 ids', () {
      fakeAsync((async) {
        final controller = exploreLoaded(async, hits: 20);
        when(
          () => repository.getImages(query: '', page: 2, perPage: 20),
        ).thenAnswer(
          (_) async => PixabayPage.fromJson(<String, dynamic>{
            'total': 3,
            'totalHits': 500,
            'hits': <Map<String, dynamic>>[
              sampleHit(id: 1000), // already on page 1
              sampleHit(id: 5000),
              sampleHit(id: 5000),
            ],
          }),
        );

        unawaited(controller.loadMore());
        async.flushMicrotasks();

        expect(
          controller.state.value,
          isA<GalleryLoaded>()
              .having((s) => s.images, 'images', hasLength(21))
              .having((s) => s.images.last.id, 'last id', 5000),
        );
      });
    });

    test('an empty page 2 ends the feed without adding images', () {
      fakeAsync((async) {
        final controller = exploreLoaded(async);
        stubPage('', 2, hits: 0);

        unawaited(controller.loadMore());
        async.flushMicrotasks();

        expect(
          controller.state.value,
          isA<GalleryLoaded>()
              .having((s) => s.status, 'status', isA<FeedEnd>())
              .having((s) => s.images, 'images', hasLength(20))
              .having((s) => s.page, 'page', 2),
        );
      });
    });

    test('a 400 on page 2 ends the feed instead of failing', () {
      fakeAsync((async) {
        final controller = exploreLoaded(async);
        when(
          () => repository.getImages(query: '', page: 2, perPage: 20),
        ).thenAnswer(
          (_) => Future<PixabayPage>.error(
            const PixabayApiException(statusCode: 400, path: '/api/'),
          ),
        );

        unawaited(controller.loadMore());
        async.flushMicrotasks();

        expect(
          controller.state.value,
          isA<GalleryLoaded>()
              .having((s) => s.status, 'status', isA<FeedEnd>())
              .having((s) => s.images, 'images', hasLength(20))
              .having((s) => s.page, 'page', 1),
        );
      });
    });

    test('page-2 response with a smaller totalHits updates totalHits', () {
      fakeAsync((async) {
        final controller = exploreLoaded(async);
        stubPage('', 2, totalHits: 40);

        unawaited(controller.loadMore());
        async.flushMicrotasks();

        expect(
          controller.state.value,
          isA<GalleryLoaded>().having((s) => s.totalHits, 'totalHits', 40),
        );
      });
    });

    test('search then loadMore requests page 2 of that query', () {
      fakeAsync((async) {
        final controller = exploreLoaded(async);
        stubPage('mountains', 1);
        unawaited(controller.search('mountains'));
        async.flushMicrotasks();
        stubPage('mountains', 2);

        unawaited(controller.loadMore());
        async.flushMicrotasks();

        verify(
          () => repository.getImages(query: 'mountains', page: 2, perPage: 20),
        ).called(1);
      });
    });

    test(
      'changing the query while page 2 is pending ignores the late response',
      () {
        fakeAsync((async) {
          final controller = exploreLoaded(async);
          stubPage('mountains', 1);
          unawaited(controller.search('mountains'));
          async.flushMicrotasks();
          final mountainsPage2 = pendingPage('mountains', 2);
          unawaited(controller.loadMore());
          async.flushMicrotasks();

          stubPage('forest', 1);
          unawaited(controller.search('forest'));
          async.flushMicrotasks();
          mountainsPage2.complete(
            PixabayPage.fromJson(
              samplePage(hitCount: 20, firstId: 2000, totalHits: 500),
            ),
          );
          async.flushMicrotasks();

          expect(
            controller.state.value,
            isA<GalleryLoaded>()
                .having((s) => s.query, 'query', 'forest')
                .having((s) => s.images, 'images', hasLength(20))
                .having((s) => s.page, 'page', 1),
          );
        });
      },
    );

    test(
      'clearing search after paginating restores Explore page 1 with no request',
      () {
        fakeAsync((async) {
          final controller = exploreLoaded(async);
          stubPage('fog', 1);
          unawaited(controller.search('fog'));
          async.flushMicrotasks();
          final fogPage2 = pendingPage('fog', 2);
          unawaited(controller.loadMore());
          async.flushMicrotasks();

          controller.clearSearch();

          expect(
            controller.state.value,
            isA<GalleryLoaded>()
                .having((s) => s.isSearch, 'isSearch', isFalse)
                .having((s) => s.images, 'images', hasLength(20))
                .having((s) => s.page, 'page', 1)
                .having((s) => s.status, 'status', isA<FeedIdle>()),
          );
          verify(
            () => repository.getImages(query: '', page: 1, perPage: 20),
          ).called(1);

          fogPage2.complete(
            PixabayPage.fromJson(
              samplePage(hitCount: 20, firstId: 2000, totalHits: 500),
            ),
          );
          async.flushMicrotasks();
          expect(
            controller.state.value,
            isA<GalleryLoaded>()
                .having((s) => s.isSearch, 'isSearch', isFalse)
                .having((s) => s.images, 'images', hasLength(20))
                .having((s) => s.page, 'page', 1),
          );
        });
      },
    );

    test(
      'clearing a short idle search never starts a search page under Explore',
      () {
        fakeAsync((async) {
          final controller = exploreLoaded(async);
          stubPage('fog', 1, hits: 4);
          unawaited(controller.search('fog'));
          async.flushMicrotasks();

          controller.clearSearch();
          stubPage('', 2);
          unawaited(controller.loadMore());
          async.flushMicrotasks();

          verify(
            () => repository.getImages(query: '', page: 2, perPage: 20),
          ).called(1);
          verifyNever(
            () => repository.getImages(query: 'fog', page: 2, perPage: 20),
          );
        });
      },
    );

    test(
      'unexpected error on load-more sets FeedLoadMoreFailed and rethrows',
      () {
        fakeAsync((async) {
          final controller = exploreLoaded(async);
          when(
            () => repository.getImages(query: '', page: 2, perPage: 20),
          ).thenAnswer((_) => Future<PixabayPage>.error(StateError('bug')));

          Object? thrown;
          controller.loadMore().catchError((Object error) => thrown = error);
          async.flushMicrotasks();

          expect(thrown, isStateError);
          expect(
            controller.state.value,
            isA<GalleryLoaded>().having(
              (s) => s.status,
              'status',
              isA<FeedLoadMoreFailed>().having(
                (f) => f.error,
                'error',
                isA<PixabayUnexpectedException>(),
              ),
            ),
          );
        });
      },
    );
  });

  group('refresh', () {
    GalleryController exploreLoaded(FakeAsync async, {int hits = 20}) {
      stubPage('', 1, hits: hits);
      final controller = GalleryController(repository: repository)..onInit();
      async.flushMicrotasks();
      expect(controller.state.value, isA<GalleryLoaded>());
      return controller;
    }

    test(
      'refresh on a loaded feed sets FeedRefreshing then replaces with page 1',
      () {
        fakeAsync((async) {
          final controller = exploreLoaded(async);
          final pending = pendingPage('', 1);
          unawaited(controller.refreshFeed());
          async.flushMicrotasks();

          expect(
            controller.state.value,
            isA<GalleryLoaded>()
                .having((s) => s.status, 'status', isA<FeedRefreshing>())
                .having((s) => s.images, 'images', hasLength(20))
                .having((s) => s.images.first.id, 'firstId', 1000),
          );

          pending.complete(
            PixabayPage.fromJson(
              samplePage(hitCount: 20, firstId: 5000, totalHits: 500),
            ),
          );
          async.flushMicrotasks();

          expect(
            controller.state.value,
            isA<GalleryLoaded>()
                .having((s) => s.page, 'page', 1)
                .having((s) => s.status, 'status', isA<FeedIdle>())
                .having((s) => s.images.first.id, 'firstId', 5000)
                .having((s) => s.images, 'images', hasLength(20)),
          );
        });
      },
    );

    test(
      'refresh in active Search re-requests that query and keeps the text field',
      () {
        fakeAsync((async) {
          final controller = exploreLoaded(async);
          stubPage('fog', 1);
          unawaited(controller.search('fog'));
          async.flushMicrotasks();
          expect(controller.searchController.text, 'fog');

          unawaited(controller.refreshFeed());
          async.flushMicrotasks();

          verify(
            () => repository.getImages(query: 'fog', page: 1, perPage: 20),
          ).called(2);
          expect(
            controller.state.value,
            isA<GalleryLoaded>().having((s) => s.query, 'query', 'fog'),
          );
          expect(controller.searchController.text, 'fog');
        });
      },
    );

    test(
      'a next-page response completing after a refresh started is ignored',
      () {
        fakeAsync((async) {
          final controller = exploreLoaded(async);
          final page2 = pendingPage('', 2);
          unawaited(controller.loadMore());
          async.flushMicrotasks();

          final page1 = pendingPage('', 1);
          unawaited(controller.refreshFeed());
          async.flushMicrotasks();

          page2.complete(
            PixabayPage.fromJson(
              samplePage(hitCount: 20, firstId: 2000, totalHits: 500),
            ),
          );
          async.flushMicrotasks();
          expect(
            controller.state.value,
            isA<GalleryLoaded>()
                .having((s) => s.images, 'images', hasLength(20))
                .having((s) => s.images.first.id, 'firstId', 1000)
                .having((s) => s.status, 'status', isA<FeedRefreshing>()),
          );

          page1.complete(
            PixabayPage.fromJson(
              samplePage(hitCount: 20, firstId: 5000, totalHits: 500),
            ),
          );
          async.flushMicrotasks();
          expect(
            controller.state.value,
            isA<GalleryLoaded>()
                .having((s) => s.images, 'images', hasLength(20))
                .having((s) => s.images.first.id, 'firstId', 5000)
                .having((s) => s.page, 'page', 1),
          );
        });
      },
    );

    test('after a refresh, loadMore requests page 2 again', () {
      fakeAsync((async) {
        final controller = exploreLoaded(async);
        stubPage('', 2);
        unawaited(controller.loadMore());
        async.flushMicrotasks();
        expect(
          controller.state.value,
          isA<GalleryLoaded>().having((s) => s.page, 'page', 2),
        );

        unawaited(controller.refreshFeed());
        async.flushMicrotasks();
        expect(
          controller.state.value,
          isA<GalleryLoaded>().having((s) => s.page, 'page', 1),
        );

        unawaited(controller.loadMore());
        async.flushMicrotasks();
        verify(
          () => repository.getImages(query: '', page: 2, perPage: 20),
        ).called(2);
      });
    });

    test('refresh while already refreshing issues one request', () {
      fakeAsync((async) {
        final controller = exploreLoaded(async);
        pendingPage('', 1);
        unawaited(controller.refreshFeed());
        unawaited(controller.refreshFeed());
        async.flushMicrotasks();

        verify(
          () => repository.getImages(query: '', page: 1, perPage: 20),
        ).called(2);
      });
    });

    test(
      'refresh from GalleryFailure behaves like retry; from GalleryLoading does nothing',
      () {
        fakeAsync((async) {
          final pending = Completer<PixabayPage>();
          var page1Calls = 0;
          when(
            () => repository.getImages(query: '', page: 1, perPage: 20),
          ).thenAnswer((_) {
            page1Calls++;
            if (page1Calls == 1) {
              return Future<PixabayPage>.error(const PixabayNetworkException());
            }
            if (page1Calls == 2) {
              return Future<PixabayPage>.value(
                PixabayPage.fromJson(
                  samplePage(hitCount: 20, firstId: 1000, totalHits: 500),
                ),
              );
            }
            return pending.future;
          });
          final failed = GalleryController(repository: repository)..onInit();
          async.flushMicrotasks();
          expect(failed.state.value, isA<GalleryFailure>());

          unawaited(failed.refreshFeed());
          async.flushMicrotasks();
          expect(failed.state.value, isA<GalleryLoaded>());
          expect(page1Calls, 2);

          final loading = GalleryController(repository: repository)..onInit();
          async.flushMicrotasks();
          expect(loading.state.value, isA<GalleryLoading>());
          unawaited(loading.refreshFeed());
          async.flushMicrotasks();
          expect(page1Calls, 3);
        });
      },
    );

    test('refresh failure becomes GalleryFailure with the query preserved', () {
      fakeAsync((async) {
        final controller = exploreLoaded(async);
        stubPage('fog', 1);
        unawaited(controller.search('fog'));
        async.flushMicrotasks();
        when(
          () => repository.getImages(query: 'fog', page: 1, perPage: 20),
        ).thenAnswer(
          (_) => Future<PixabayPage>.error(const PixabayNetworkException()),
        );

        unawaited(controller.refreshFeed());
        async.flushMicrotasks();

        expect(
          controller.state.value,
          isA<GalleryFailure>()
              .having((s) => s.query, 'query', 'fog')
              .having((s) => s.error, 'error', isA<PixabayNetworkException>()),
        );
      });
    });

    test(
      'an Explore refresh updates the cached snapshot shown after clear',
      () {
        fakeAsync((async) {
          final controller = exploreLoaded(async);
          when(
            () => repository.getImages(query: '', page: 1, perPage: 20),
          ).thenAnswer(
            (_) async => PixabayPage.fromJson(
              samplePage(hitCount: 20, firstId: 5000, totalHits: 500),
            ),
          );
          unawaited(controller.refreshFeed());
          async.flushMicrotasks();

          stubPage('fog', 1);
          unawaited(controller.search('fog'));
          async.flushMicrotasks();
          controller.clearSearch();

          expect(
            controller.state.value,
            isA<GalleryLoaded>()
                .having((s) => s.isSearch, 'isSearch', isFalse)
                .having((s) => s.images.first.id, 'firstId', 5000)
                .having((s) => s.images, 'images', hasLength(20)),
          );
          verify(
            () => repository.getImages(query: '', page: 1, perPage: 20),
          ).called(2);
        });
      },
    );

    test('onClose removes the scroll listener without throwing', () {
      fakeAsync((async) {
        final controller = exploreLoaded(async);
        expect(controller.onClose, returnsNormally);
      });
    });

    test(
      'scrollToTop with no attached scroll view does nothing and does not throw',
      () {
        fakeAsync((async) {
          final controller = exploreLoaded(async);
          final before = controller.state.value;
          expect(controller.scrollToTop, returnsNormally);
          expect(identical(controller.state.value, before), isTrue);
          expect(controller.searchController.text, isEmpty);
          verify(
            () => repository.getImages(query: '', page: 1, perPage: 20),
          ).called(1);
        });
      },
    );
  });

  group('pull gating', () {
    GalleryController exploreLoaded(FakeAsync async) {
      when(repository.getImages).thenAnswer((_) async => pageWith(3));
      final controller = GalleryController(repository: repository)..onInit();
      async.flushMicrotasks();
      expect(controller.state.value, isA<GalleryLoaded>());
      return controller;
    }

    test('refreshFromPull without a finger down does nothing', () {
      fakeAsync((async) {
        final controller = exploreLoaded(async);

        unawaited(controller.refreshFromPull());
        async.flushMicrotasks();

        verify(repository.getImages).called(1);
        expect(
          controller.state.value,
          isA<GalleryLoaded>().having(
            (s) => s.status,
            'status',
            isA<FeedIdle>(),
          ),
        );
      });
    });

    test('refreshFromPull while dragging refreshes page 1', () {
      fakeAsync((async) {
        final controller = exploreLoaded(async);

        controller.onUserDrag(dragging: true);
        unawaited(controller.refreshFromPull());
        async.flushMicrotasks();

        verify(repository.getImages).called(2);
      });
    });

    test('a drag that ended no longer allows a pull refresh', () {
      fakeAsync((async) {
        final controller = exploreLoaded(async);

        controller.onUserDrag(dragging: true);
        controller.onUserDrag(dragging: false);
        unawaited(controller.refreshFromPull());
        async.flushMicrotasks();

        verify(repository.getImages).called(1);
      });
    });
  });
}
