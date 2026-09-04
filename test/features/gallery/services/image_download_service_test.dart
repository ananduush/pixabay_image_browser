import 'dart:io';

import 'package:file/memory.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gal/gal.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pixabay_image_browser/features/gallery/models/pixabay_image.dart';
import 'package:pixabay_image_browser/features/gallery/services/image_download_exception.dart';
import 'package:pixabay_image_browser/features/gallery/services/image_download_service.dart';

import '../../../support/pixabay_fixtures.dart';

class _MockCache extends Mock implements BaseCacheManager {}

class _FakeLibrary implements PhotoLibrary {
  bool allow = true;
  Object? putError;
  final List<String> saved = <String>[];
  int accessRequests = 0;

  @override
  Future<bool> requestAccess() async {
    accessRequests++;
    return allow;
  }

  @override
  Future<void> putImage(String path) async {
    if (putError != null) throw putError!;
    saved.add(path);
  }
}

void main() {
  late _MockCache cache;
  late _FakeLibrary library;
  late ImageDownloadService service;

  final image = PixabayImage.fromJson(sampleHit());
  // the cache manager hands out `package:file` files, not dart:io ones
  final cached = MemoryFileSystem().file('/cache/35bbf209e13e39d2_1280.jpg');

  setUp(() {
    cache = _MockCache();
    library = _FakeLibrary();
    service = ImageDownloadService(cache: cache, library: library);
  });

  test('hands the cached large image to the photo library', () async {
    when(
      () => cache.getSingleFile(image.largeImageUrl),
    ).thenAnswer((_) async => cached);

    await service.saveToPhotos(image);

    expect(library.saved, <String>[cached.path]);
    expect(library.accessRequests, 1);
    verify(() => cache.getSingleFile(image.largeImageUrl)).called(1);
  });

  test('a fetch that never reaches the cache is an offline failure', () {
    when(
      () => cache.getSingleFile(image.largeImageUrl),
    ).thenThrow(const SocketException('no route'));

    expect(
      () => service.saveToPhotos(image),
      throwsA(isA<ImageDownloadOfflineException>()),
    );
    expect(library.saved, isEmpty);
  });

  test('declined access stops before anything is written', () async {
    when(
      () => cache.getSingleFile(image.largeImageUrl),
    ).thenAnswer((_) async => cached);
    library.allow = false;

    await expectLater(
      service.saveToPhotos(image),
      throwsA(isA<ImageDownloadAccessDeniedException>()),
    );
    expect(library.saved, isEmpty);
  });

  test('the plugin\'s own access denial maps the same way', () {
    when(
      () => cache.getSingleFile(image.largeImageUrl),
    ).thenAnswer((_) async => cached);
    library.putError = GalException(
      type: GalExceptionType.accessDenied,
      platformException: PlatformException(code: 'ACCESS_DENIED'),
      stackTrace: StackTrace.current,
    );

    expect(
      () => service.saveToPhotos(image),
      throwsA(isA<ImageDownloadAccessDeniedException>()),
    );
  });

  test('any other write problem is a plain failure', () {
    when(
      () => cache.getSingleFile(image.largeImageUrl),
    ).thenAnswer((_) async => cached);
    library.putError = GalException(
      type: GalExceptionType.notEnoughSpace,
      platformException: PlatformException(code: 'NOT_ENOUGH_SPACE'),
      stackTrace: StackTrace.current,
    );

    expect(
      () => service.saveToPhotos(image),
      throwsA(isA<ImageDownloadFailedException>()),
    );
  });
}
