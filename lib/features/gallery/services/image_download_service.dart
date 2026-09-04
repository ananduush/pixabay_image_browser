import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:gal/gal.dart';

import '../models/pixabay_image.dart';
import 'image_download_exception.dart';

/// The device photo library, behind a seam so tests never touch `gal`.
abstract interface class PhotoLibrary {
  Future<bool> requestAccess();

  Future<void> putImage(String path);
}

/// Production library: the `gal` plugin (permission prompt included).
final class GalPhotoLibrary implements PhotoLibrary {
  const GalPhotoLibrary();

  @override
  Future<bool> requestAccess() => Gal.requestAccess();

  @override
  Future<void> putImage(String path) => Gal.putImage(path);
}

/// Saves a Pixabay image to the device's Photos library.
///
/// The bytes come through the same cache `CachedNetworkImage` fills, so a
/// photo that has been viewed in Details saves even without a connection;
/// anything else is fetched first.
class ImageDownloadService {
  ImageDownloadService({
    required this._cache,
    this._library = const GalPhotoLibrary(),
  });

  final BaseCacheManager _cache;
  final PhotoLibrary _library;

  Future<void> saveToPhotos(PixabayImage image) async {
    final File file;
    try {
      file = await _cache.getSingleFile(image.largeImageUrl);
    } catch (error) {
      throw ImageDownloadOfflineException(error);
    }
    final bool allowed;
    try {
      allowed = await _library.requestAccess();
    } catch (error) {
      throw ImageDownloadFailedException(error);
    }
    if (!allowed) throw const ImageDownloadAccessDeniedException();
    try {
      await _library.putImage(file.path);
    } on GalException catch (error) {
      if (error.type == GalExceptionType.accessDenied) {
        throw const ImageDownloadAccessDeniedException();
      }
      throw ImageDownloadFailedException(error);
    } catch (error) {
      throw ImageDownloadFailedException(error);
    }
  }
}
