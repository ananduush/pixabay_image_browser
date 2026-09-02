/// Failures the Pixabay service can surface. Sealed so callers can switch
/// exhaustively; each maps to a distinct screen in the design.
sealed class PixabayException implements Exception {
  const PixabayException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// No `PIXABAY_API_KEY` was supplied at build time. Raised before any
/// request is made.
final class PixabayMissingKeyException extends PixabayException {
  const PixabayMissingKeyException()
    : super(
        'PIXABAY_API_KEY is not set, so no request was sent.\n\n'
        'Run the app with\n'
        'flutter run --dart-define=PIXABAY_API_KEY=YOUR_KEY\n\n'
        'or put the key in env.json and run\n'
        'flutter run --dart-define-from-file=env.json',
      );
}

/// The device could not reach Pixabay (offline, DNS, timeout).
final class PixabayNetworkException extends PixabayException {
  const PixabayNetworkException([String? detail])
    : super(detail ?? 'Could not reach Pixabay.');
}

/// Pixabay answered, but with an error status or an unreadable body.
final class PixabayApiException extends PixabayException {
  const PixabayApiException({
    required this.path,
    this.statusCode,
    String? message,
  }) : super(message ?? 'Pixabay returned an error.');

  /// HTTP status, when one was received.
  final int? statusCode;

  /// Short request label for the error screen, e.g. `/api/?q=popular`.
  final String path;

  String get requestLabel => 'HTTP ${statusCode ?? '—'} · $path';
}
