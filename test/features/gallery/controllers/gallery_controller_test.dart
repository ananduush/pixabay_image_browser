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

    /// A controller whose curated feed has already loaded (and is cached).
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

    /// What the TextField does on a keystroke: update the controller's
    /// text, then report the change.
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
            query: any(named: 'query', that: isNotNull),
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
            query: any(named: 'query', that: isNotNull),
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
            query: any(named: 'query', that: isNotNull),
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
        // Retrying a search never falls back to the curated feed.
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
          query: any(named: 'query', that: isNotNull),
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
        // Explore never finished, so there is no page to restore.
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
        // The second search is issued while the first is still in flight.
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

        // Repeating the term already shown is a no-op.
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

        // Edit away and back before the debounce fires: "fog" again.
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

        // The superseded curated response lands now.
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

        // Keep typing, then tap "Try again" before the debounce fires.
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
            query: any(named: 'query', that: isNotNull),
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
}
