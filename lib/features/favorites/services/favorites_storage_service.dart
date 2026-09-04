import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../gallery/models/pixabay_image.dart';
import 'favorites_storage_exception.dart';

/// Reads and writes one user's favourites as a JSON list under a per-user
/// key, so accounts on the same device never see each other's saves and
/// logging out leaves the data in place.
///
/// `shared_preferences` (async API) reports write failures to the caller,
/// which the storage-error handling below depends on.
class FavoritesStorageService {
  FavoritesStorageService({required this._preferences});

  final SharedPreferencesAsync _preferences;

  static String keyFor(String userId) => 'favorites.$userId';

  Future<List<PixabayImage>> read(String userId) async {
    final String? raw;
    try {
      raw = await _preferences.getString(keyFor(userId));
    } catch (error) {
      throw FavoritesStorageException(
        operation: FavoritesStorageOperation.read,
        cause: error,
      );
    }
    // Outside the try: a decode failure keeps its own operation.
    return raw == null ? const <PixabayImage>[] : decode(raw);
  }

  Future<void> write(String userId, List<PixabayImage> images) async {
    final encoded = jsonEncode(<Object>[
      for (final image in images) image.toJson(),
    ]);
    try {
      await _preferences.setString(keyFor(userId), encoded);
    } catch (error) {
      throw FavoritesStorageException(
        operation: FavoritesStorageOperation.write,
        cause: error,
      );
    }
  }

  /// A missing key reads as empty (see [read]). Anything present that is
  /// not a JSON list of objects is corruption and throws, so a later save can
  /// never overwrite what was there. Rows with an unusable id (`<= 0`) or a
  /// repeated id are still dropped: they are well-formed but never showable.
  @visibleForTesting
  static List<PixabayImage> decode(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (error) {
      throw FavoritesStorageException(
        operation: FavoritesStorageOperation.decode,
        cause: error,
      );
    }
    if (decoded is! List<dynamic>) {
      throw const FavoritesStorageException(
        operation: FavoritesStorageOperation.decode,
        cause: FormatException('store is not a list'),
      );
    }
    final seen = <int>{};
    final images = <PixabayImage>[];
    for (final entry in decoded) {
      if (entry is! Map<String, dynamic>) {
        throw FavoritesStorageException(
          operation: FavoritesStorageOperation.decode,
          cause: FormatException('entry is not an object', entry),
        );
      }
      final image = PixabayImage.fromJson(entry);
      if (image.id <= 0 || !seen.add(image.id)) continue;
      images.add(image);
    }
    return List<PixabayImage>.unmodifiable(images);
  }
}
