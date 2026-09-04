/// In-memory favourites storage for tests: same JSON shape as the real
/// service, no platform channel, switchable failures.
library;

import 'dart:convert';

import 'package:get/get.dart';
import 'package:pixabay_image_browser/features/favorites/repositories/favorites_repository.dart';
import 'package:pixabay_image_browser/features/favorites/services/favorites_storage_exception.dart';
import 'package:pixabay_image_browser/features/favorites/services/favorites_storage_service.dart';
import 'package:pixabay_image_browser/features/gallery/models/pixabay_image.dart';

class FakeFavoritesStorageService implements FavoritesStorageService {
  final Map<String, String> store = <String, String>{};

  bool failReads = false;
  bool failWrites = false;

  int reads = 0;
  int writes = 0;

  /// Seeds [images] for [userId] the way the real service would write them.
  void seed(String userId, List<PixabayImage> images) {
    store[FavoritesStorageService.keyFor(userId)] = jsonEncode(<Object>[
      for (final image in images) image.toJson(),
    ]);
  }

  List<PixabayImage> saved(String userId) {
    final raw = store[FavoritesStorageService.keyFor(userId)];
    return raw == null
        ? const <PixabayImage>[]
        : FavoritesStorageService.decode(raw);
  }

  @override
  Future<List<PixabayImage>> read(String userId) async {
    reads++;
    if (failReads) {
      throw FavoritesStorageException(
        operation: FavoritesStorageOperation.read,
        cause: StateError('read refused'),
      );
    }
    return saved(userId);
  }

  @override
  Future<void> write(String userId, List<PixabayImage> images) async {
    writes++;
    if (failWrites) {
      throw FavoritesStorageException(
        operation: FavoritesStorageOperation.write,
        cause: StateError('write refused'),
      );
    }
    seed(userId, images);
  }
}

/// Registers a repository over [storage] before a binding can build the real
/// one, so `SharedPreferencesAsync` is never constructed under test.
FakeFavoritesStorageService registerFavoritesFakes({
  FakeFavoritesStorageService? storage,
}) {
  final fake = storage ?? FakeFavoritesStorageService();
  Get.put<FavoritesRepository>(FavoritesRepository(storage: fake));
  return fake;
}
