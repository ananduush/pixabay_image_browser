import '../models/pixabay_image.dart';
import '../services/pixabay_exception.dart';

/// The Gallery screen is always in exactly one of these states.
///
/// Every state carries the [query] it answers, so search is a mode of the
/// same screen rather than a parallel state machine: an empty query is the
/// curated Explore feed, a non-empty one is a Pixabay keyword search.
sealed class GalleryState {
  const GalleryState({this.query = ''});

  /// Trimmed search term this state answers. Empty means the curated feed.
  final String query;

  bool get isSearch => query.isNotEmpty;
}

final class GalleryLoading extends GalleryState {
  const GalleryLoading({super.query});
}

final class GalleryLoaded extends GalleryState {
  const GalleryLoaded(this.images, {super.query, this.totalHits = 0});

  final List<PixabayImage> images;

  /// Matches Pixabay reports for [query] (the API caps this at 500). Shown
  /// in the results header; not meaningful for the curated feed.
  final int totalHits;

  /// The feed is laid out in groups of four: one hero followed by up to
  /// three square tiles. A trailing group may be partial.
  List<List<PixabayImage>> get groups => groupImages(images);

  static const int groupSize = 4;

  static List<List<PixabayImage>> groupImages(List<PixabayImage> images) {
    return <List<PixabayImage>>[
      for (var i = 0; i < images.length; i += groupSize)
        images.sublist(
          i,
          i + groupSize > images.length ? images.length : i + groupSize,
        ),
    ];
  }
}

final class GalleryFailure extends GalleryState {
  const GalleryFailure(this.error, {super.query});

  final PixabayException error;
}
