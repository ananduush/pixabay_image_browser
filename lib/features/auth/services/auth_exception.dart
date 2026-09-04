/// Failures the Auth feature can surface. Sealed so callers can switch
/// exhaustively; the Supabase-specific cause never leaves the service.
///
/// `message` is the developer-facing description; user copy lives in the
/// widgets that render these.
sealed class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY were not supplied, so Supabase was
/// never initialised. Browsing still works; only accounts are unavailable.
final class AuthMissingConfigException extends AuthException {
  const AuthMissingConfigException()
    : super(
        'SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY are not set, so accounts '
        'are unavailable.\n\n'
        'Run the app with\n'
        'flutter run --dart-define=SUPABASE_URL=https://<ref>.supabase.co '
        '--dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...\n\n'
        'or put both keys in env.json and run\n'
        'flutter run --dart-define-from-file=env.json',
      );
}

/// Wrong email/password combination.
final class AuthInvalidCredentialsException extends AuthException {
  const AuthInvalidCredentialsException()
    : super('The email and password do not match.');
}

/// Sign-up with an email that already has an account.
final class AuthEmailInUseException extends AuthException {
  const AuthEmailInUseException()
    : super('An account with this email already exists.');
}

/// The backend rejected the email address itself.
final class AuthInvalidEmailException extends AuthException {
  const AuthInvalidEmailException() : super('The email address is not valid.');
}

/// The password does not meet the project's policy (8+ characters, no
/// character-class rules — see supabase/config.toml).
final class AuthWeakPasswordException extends AuthException {
  const AuthWeakPasswordException({this.reasons = const <String>[]})
    : super('The password must be at least $minLength characters.');

  /// Mirrors `minimum_password_length` in supabase/config.toml.
  static const int minLength = 8;

  /// Backend reason codes, e.g. `length`. Informational only.
  final List<String> reasons;
}

/// Supabase throttled the request.
final class AuthRateLimitedException extends AuthException {
  const AuthRateLimitedException()
    : super('Too many attempts; Supabase asked us to wait.');
}

/// Offline, DNS failure, timeout or a 5xx from Supabase.
final class AuthNetworkException extends AuthException {
  const AuthNetworkException() : super('Could not reach Supabase Auth.');
}

/// Sign-up created a user without a session: the project requires email
/// confirmation. Not expected with the current configuration
/// (`enable_confirmations = false`), but handled truthfully if it changes.
final class AuthConfirmationRequiredException extends AuthException {
  const AuthConfirmationRequiredException()
    : super(
        'The account was created but must confirm its email before signing in.',
      );
}

/// Anything the mapping does not recognise: still shown as an error, with
/// the structured detail kept for debugging.
final class AuthUnexpectedException extends AuthException {
  const AuthUnexpectedException(super.message, {this.code, this.statusCode});

  final String? code;
  final String? statusCode;

  /// `code · status`, for a mono detail line; empty when neither is known.
  String get detail => <String?>[code, statusCode].nonNulls.join(' · ');
}
