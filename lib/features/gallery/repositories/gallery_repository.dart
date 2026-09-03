import '../models/pixabay_page.dart';
import '../services/pixabay_service.dart';

/// Gallery-facing data operations. Thin today; the boundary is what matters
/// (the controller never sees the API service).
class GalleryRepository {
  GalleryRepository({required this._service});

  final PixabayService _service;

  Future<PixabayPage> getImages({
    String query = '',
    int page = 1,
    int perPage = 20,
  }) {
    return _service.fetchImages(query: query, page: page, perPage: perPage);
  }
}
