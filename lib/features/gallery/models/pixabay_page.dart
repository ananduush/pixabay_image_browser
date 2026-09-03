import 'pixabay_image.dart';

/// One page of results from the Pixabay `/api/` endpoint.
class PixabayPage {
  const PixabayPage({
    required this.total,
    required this.totalHits,
    required this.hits,
  });

  factory PixabayPage.fromJson(Map<String, dynamic> json) {
    final rawHits = json['hits'];
    final hits = rawHits is List
        ? rawHits
              .whereType<Map<String, dynamic>>()
              .map(PixabayImage.fromJson)
              .toList(growable: false)
        : const <PixabayImage>[];
    return PixabayPage(
      total: _readInt(json['total']),
      totalHits: _readInt(json['totalHits']),
      hits: hits,
    );
  }

  /// Total matches on Pixabay.
  final int total;

  /// Matches reachable through the API (capped at 500 per query).
  final int totalHits;
  final List<PixabayImage> hits;

  static int _readInt(Object? value) => value is num ? value.toInt() : 0;
}
