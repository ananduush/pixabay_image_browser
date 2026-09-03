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

/// What the loaded feed is doing at its edge. Exactly one at a time.
sealed class FeedStatus {
  const FeedStatus();
}

/// More pages may exist; nothing in flight.
final class FeedIdle extends FeedStatus {
  const FeedIdle();
}

/// The next page (`GalleryLoaded.nextPage`) is in flight.
final class FeedLoadingMore extends FeedStatus {
  const FeedLoadingMore();
}

/// The next page failed; images already loaded are kept.
final class FeedLoadMoreFailed extends FeedStatus {
  const FeedLoadMoreFailed(this.error);

  final PixabayException error;
}

/// Pixabay has nothing beyond `page`.
final class FeedEnd extends FeedStatus {
  const FeedEnd();
}

/// Page 1 is being re-fetched; current images stay visible meanwhile.
final class FeedRefreshing extends FeedStatus {
  const FeedRefreshing();
}

final class GalleryLoaded extends GalleryState {
  const GalleryLoaded(
    this.images, {
    super.query,
    this.totalHits = 0,
    this.page = 1,
    this.status = const FeedIdle(),
  });

  final List<PixabayImage> images;

  // capped at 500 by pixabay
  final int totalHits;

  /// last page merged into [images], 1-based
  final int page;

  final FeedStatus status;

  int get nextPage => page + 1;

  GalleryLoaded copyWith({
    List<PixabayImage>? images,
    int? totalHits,
    int? page,
    FeedStatus? status,
  }) {
    return GalleryLoaded(
      images ?? this.images,
      query: query,
      totalHits: totalHits ?? this.totalHits,
      page: page ?? this.page,
      status: status ?? this.status,
    );
  }

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
