import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/pixabay_image.dart';
import '../services/image_download_exception.dart';
import '../services/image_download_service.dart';
import 'image_detail_state.dart';

/// Route-scoped state for Image Details: today only the download.
class ImageDetailController extends GetxController {
  ImageDetailController({required this._downloads});

  final ImageDownloadService _downloads;

  final Rx<DownloadStatus> download = Rx<DownloadStatus>(const DownloadIdle());

  bool get isSaving => download.value is DownloadSaving;

  /// Saves [image] to Photos; a tap while one is running is ignored. The
  /// returned status is the one the view should report on.
  Future<DownloadStatus> saveToPhotos(PixabayImage image) async {
    if (isSaving) return download.value;
    download.value = const DownloadSaving();
    try {
      await _downloads.saveToPhotos(image);
      download.value = const DownloadSaved();
    } on ImageDownloadException catch (error) {
      debugPrint('ImageDetailController: download failed: $error');
      download.value = DownloadFailed(error);
    }
    return download.value;
  }
}
