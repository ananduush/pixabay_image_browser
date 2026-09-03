import '../models/pixabay_image.dart';
import '../services/pixabay_exception.dart';

/// The Gallery screen is always in exactly one of these states.
sealed class GalleryState {
  const GalleryState();
}

final class GalleryLoading extends GalleryState {
  const GalleryLoading();
}

final class GalleryLoaded extends GalleryState {
  const GalleryLoaded(this.images);

  final List<PixabayImage> images;

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
  const GalleryFailure(this.error);

  final PixabayException error;
}
