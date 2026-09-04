/// Cache-manager fakes for widgets that render `CachedNetworkImage`, so
/// tests never touch disk or the network.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:mocktail/mocktail.dart';

class _FakeCacheManager extends Mock implements BaseCacheManager {}

/// Every image stays on its placeholder: the stream never emits.
void installPendingImageCache() {
  final cacheManager = _FakeCacheManager();
  when(
    () => cacheManager.getFileStream(
      any(),
      key: any(named: 'key'),
      headers: any(named: 'headers'),
      withProgress: any(named: 'withProgress'),
    ),
  ).thenAnswer((_) => const Stream<FileResponse>.empty());
  CachedNetworkImageProvider.defaultCacheManager = cacheManager;
}

/// Every image fails to load, so error builders run.
void installFailingImageCache() {
  final cacheManager = _FakeCacheManager();
  when(
    () => cacheManager.getFileStream(
      any(),
      key: any(named: 'key'),
      headers: any(named: 'headers'),
      withProgress: any(named: 'withProgress'),
    ),
  ).thenAnswer((_) => Stream<FileResponse>.error(Exception('offline')));
  CachedNetworkImageProvider.defaultCacheManager = cacheManager;
}
