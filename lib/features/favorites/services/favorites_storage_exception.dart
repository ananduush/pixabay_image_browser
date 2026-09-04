enum FavoritesStorageOperation { read, write, decode }

/// Local storage refused a favourites read or write, or the stored value
/// could not be decoded ([FavoritesStorageOperation.decode]). [cause] is
/// kept for logs; the UI shows its own copy, never the raw error.
final class FavoritesStorageException implements Exception {
  const FavoritesStorageException({
    required this.operation,
    required this.cause,
  });

  final FavoritesStorageOperation operation;
  final Object cause;

  @override
  String toString() => 'FavoritesStorageException(${operation.name}): $cause';
}
