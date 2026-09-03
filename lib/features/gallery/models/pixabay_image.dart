/// One Pixabay "hit", parsed into the fields the app actually uses.
class PixabayImage {
  const PixabayImage({
    required this.id,
    required this.pageUrl,
    required this.tags,
    required this.previewUrl,
    required this.webformatUrl,
    required this.largeImageUrl,
    required this.imageWidth,
    required this.imageHeight,
    required this.views,
    required this.downloads,
    required this.likes,
    required this.user,
    required this.userImageUrl,
  });

  factory PixabayImage.fromJson(Map<String, dynamic> json) {
    return PixabayImage(
      id: _readInt(json['id']),
      pageUrl: _readString(json['pageURL']),
      tags: parseTags(json['tags']),
      previewUrl: _readString(json['previewURL']),
      webformatUrl: _readString(json['webformatURL']),
      largeImageUrl: _readString(json['largeImageURL']),
      imageWidth: _readInt(json['imageWidth']),
      imageHeight: _readInt(json['imageHeight']),
      views: _readInt(json['views']),
      downloads: _readInt(json['downloads']),
      likes: _readInt(json['likes']),
      user: _readString(json['user']),
      userImageUrl: _readString(json['userImageURL']),
    );
  }

  final int id;
  final String pageUrl;
  final List<String> tags;
  final String previewUrl;

  /// Medium image, max 640px on the long edge. Valid for 24 hours.
  final String webformatUrl;

  /// Large image, max 1280px on the long edge.
  final String largeImageUrl;
  final int imageWidth;
  final int imageHeight;
  final int views;
  final int downloads;
  final int likes;
  final String user;
  final String userImageUrl;

  static final RegExp _webformatSize = RegExp(r'_640(?=\.[A-Za-z0-9]+$)');

  /// Pixabay documents that `_640` in [webformatUrl] may be swapped for
  /// `_340` to get a smaller variant — right for ~110pt square tiles.
  String get tileUrl => webformatUrl.replaceFirst(_webformatSize, '_340');

  /// Pixabay has no titles; the first few tags stand in for one.
  String get title {
    if (tags.isEmpty) return 'Untitled';
    final text = tags.take(3).join(' · ');
    return text[0].toUpperCase() + text.substring(1);
  }

  double get aspectRatio =>
      imageWidth > 0 && imageHeight > 0 ? imageWidth / imageHeight : 1;

  /// Pixabay sends tags as one comma-separated string.
  static List<String> parseTags(Object? raw) {
    if (raw is! String) return const <String>[];
    return raw
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList(growable: false);
  }

  static int _readInt(Object? value) => value is num ? value.toInt() : 0;

  static String _readString(Object? value) => value is String ? value : '';

  @override
  bool operator ==(Object other) => other is PixabayImage && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'PixabayImage(id: $id, user: $user, tags: $tags)';
}
