import 'package:flutter/foundation.dart';

import '../../gallery/models/pixabay_image.dart';
import '../services/favorites_storage_exception.dart';

/// Favourites of the signed-in user. Value equality on every variant lets
/// the Rx drop redundant sets so only real changes rebuild the grid.
sealed class FavoritesState {
  const FavoritesState();

  String? get userId => null;

  bool contains(int id) => false;
}

/// No signed-in user: nothing to show or persist.
final class FavoritesInactive extends FavoritesState {
  const FavoritesInactive();

  @override
  bool operator ==(Object other) => other is FavoritesInactive;

  @override
  int get hashCode => (FavoritesInactive).hashCode;
}

final class FavoritesLoading extends FavoritesState {
  const FavoritesLoading(this.userId);

  @override
  final String userId;

  @override
  bool operator ==(Object other) =>
      other is FavoritesLoading && other.userId == userId;

  @override
  int get hashCode => Object.hash(FavoritesLoading, userId);
}

final class FavoritesLoadFailed extends FavoritesState {
  const FavoritesLoadFailed(this.userId, this.error);

  @override
  final String userId;

  final FavoritesStorageException error;

  @override
  bool operator ==(Object other) =>
      other is FavoritesLoadFailed &&
      other.userId == userId &&
      other.error == error;

  @override
  int get hashCode => Object.hash(FavoritesLoadFailed, userId, error);
}

final class FavoritesLoaded extends FavoritesState {
  const FavoritesLoaded(this.userId, this.images);

  @override
  final String userId;

  /// In save order; views decide how to present it.
  final List<PixabayImage> images;

  int get count => images.length;

  @override
  bool contains(int id) => images.any((image) => image.id == id);

  FavoritesLoaded copyWith({List<PixabayImage>? images}) =>
      FavoritesLoaded(userId, images ?? this.images);

  @override
  bool operator ==(Object other) =>
      other is FavoritesLoaded &&
      other.userId == userId &&
      listEquals(other.images, images);

  @override
  int get hashCode =>
      Object.hash(FavoritesLoaded, userId, Object.hashAll(images));
}
