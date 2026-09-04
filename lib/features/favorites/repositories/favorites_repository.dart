import '../../gallery/models/pixabay_image.dart';
import '../services/favorites_storage_service.dart';

/// Domain boundary for one user's favourites. Identity is the Pixabay `id`:
/// adding an image that is already saved is a no-op, so the store can never
/// hold duplicates whatever the UI does.
class FavoritesRepository {
  FavoritesRepository({required this._storage});

  final FavoritesStorageService _storage;

  Future<List<PixabayImage>> load(String userId) => _storage.read(userId);

  Future<List<PixabayImage>> add(String userId, PixabayImage image) async {
    final current = await _storage.read(userId);
    if (current.any((saved) => saved.id == image.id)) return current;
    final next = List<PixabayImage>.unmodifiable(<PixabayImage>[
      ...current,
      image,
    ]);
    await _storage.write(userId, next);
    return next;
  }

  Future<List<PixabayImage>> remove(String userId, int id) async {
    final current = await _storage.read(userId);
    if (!current.any((saved) => saved.id == id)) return current;
    final next = List<PixabayImage>.unmodifiable(
      current.where((saved) => saved.id != id),
    );
    await _storage.write(userId, next);
    return next;
  }
}
