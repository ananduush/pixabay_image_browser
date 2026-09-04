/// Why a download did not reach the Photos library. Copy lives on the
/// Details widgets; these carry only the cause.
sealed class ImageDownloadException implements Exception {
  const ImageDownloadException();
}

/// The bytes are not cached and the network did not deliver them.
final class ImageDownloadOfflineException extends ImageDownloadException {
  const ImageDownloadOfflineException(this.cause);

  final Object cause;

  @override
  String toString() => 'ImageDownloadOfflineException: $cause';
}

/// The user declined (or has revoked) Photos access.
final class ImageDownloadAccessDeniedException extends ImageDownloadException {
  const ImageDownloadAccessDeniedException();
}

/// Anything else the platform refused: disk full, unsupported format…
final class ImageDownloadFailedException extends ImageDownloadException {
  const ImageDownloadFailedException(this.cause);

  final Object cause;

  @override
  String toString() => 'ImageDownloadFailedException: $cause';
}
