import '../models/pixabay_image.dart';
import '../services/pixabay_exception.dart';

/// The Gallery screen is always in exactly one of these states.
sealed class GalleryState {
  const GalleryState({this.query = ''});

  // empty = curated feed
  final String query;

  bool get isSearch => query.isNotEmpty;
}

final class GalleryLoading extends GalleryState {
  const GalleryLoading({super.query});
}

final class GalleryLoaded extends GalleryState {
  const GalleryLoaded(this.images, {super.query, this.totalHits = 0});

  final List<PixabayImage> images;

  // capped at 500 by pixabay
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
