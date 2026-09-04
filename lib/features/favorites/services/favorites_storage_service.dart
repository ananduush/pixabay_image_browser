import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../gallery/models/pixabay_image.dart';
import 'favorites_storage_exception.dart';

/// Reads and writes one user's favourites as a JSON list under a per-user
/// key, so accounts on the same device never see each other's saves and
/// logging out leaves the data in place.
///
/// `shared_preferences` was chosen over the previously declared (and never
/// used) `get_storage`: its async API reports write failures to the caller,
/// whereas GetStorage's `write` resolves before the disk flush and swallows
/// flush errors, which would make the storage-error handling below
/// impossible. It is maintained by the Flutter team and is trivial to fake.
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

  /// Malformed entries are dropped and an undecodable value reads as empty:
  /// a corrupt store must never lock the user out of saving again.
  @visibleForTesting
  static List<PixabayImage> decode(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (error) {
      debugPrint('FavoritesStorageService: unreadable store, $error');
      return const <PixabayImage>[];
    }
    if (decoded is! List<dynamic>) {
      debugPrint('FavoritesStorageService: store is not a list');
      return const <PixabayImage>[];
    }
    final seen = <int>{};
    final images = <PixabayImage>[];
    for (final entry in decoded) {
      if (entry is! Map<String, dynamic>) continue;
      final image = PixabayImage.fromJson(entry);
      if (image.id <= 0 || !seen.add(image.id)) continue;
      images.add(image);
    }
    return List<PixabayImage>.unmodifiable(images);
  }
}
