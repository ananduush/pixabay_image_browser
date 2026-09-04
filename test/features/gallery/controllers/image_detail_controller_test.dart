import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pixabay_image_browser/features/gallery/controllers/image_detail_controller.dart';
import 'package:pixabay_image_browser/features/gallery/controllers/image_detail_state.dart';
import 'package:pixabay_image_browser/features/gallery/models/pixabay_image.dart';
import 'package:pixabay_image_browser/features/gallery/services/image_download_exception.dart';
import 'package:pixabay_image_browser/features/gallery/services/image_download_service.dart';

import '../../../support/pixabay_fixtures.dart';

class _MockDownloads extends Mock implements ImageDownloadService {}

void main() {
  late _MockDownloads downloads;
  late ImageDetailController controller;

  final image = PixabayImage.fromJson(sampleHit());

  setUp(() {
    downloads = _MockDownloads();
    controller = ImageDetailController(downloads: downloads);
  });

  test('starts idle', () {
    expect(controller.download.value, const DownloadIdle());
    expect(controller.isSaving, isFalse);
  });

  test('a save runs through saving to saved', () async {
    final pending = Completer<void>();
    when(() => downloads.saveToPhotos(image)).thenAnswer((_) => pending.future);

    final result = controller.saveToPhotos(image);
    expect(controller.download.value, const DownloadSaving());
    expect(controller.isSaving, isTrue);

    pending.complete();
    expect(await result, const DownloadSaved());
    expect(controller.isSaving, isFalse);
  });

  test('a second tap while saving is ignored', () async {
    final pending = Completer<void>();
    when(() => downloads.saveToPhotos(image)).thenAnswer((_) => pending.future);

    final first = controller.saveToPhotos(image);
    expect(await controller.saveToPhotos(image), const DownloadSaving());

    pending.complete();
    await first;
    verify(() => downloads.saveToPhotos(image)).called(1);
  });

  test('a failure is kept with its cause and does not throw', () async {
    const error = ImageDownloadAccessDeniedException();
    when(() => downloads.saveToPhotos(image)).thenThrow(error);

    final result = await controller.saveToPhotos(image);

    expect(
      result,
      isA<DownloadFailed>().having((s) => s.error, 'error', error),
    );
    expect(controller.isSaving, isFalse);
  });
}
