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
}
