sealed class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

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

final class AuthInvalidCredentialsException extends AuthException {
  const AuthInvalidCredentialsException()
    : super('The email and password do not match.');
}

final class AuthEmailInUseException extends AuthException {
  const AuthEmailInUseException()
    : super('An account with this email already exists.');
}

final class AuthInvalidEmailException extends AuthException {
  const AuthInvalidEmailException() : super('The email address is not valid.');
}

final class AuthWeakPasswordException extends AuthException {
  const AuthWeakPasswordException({this.reasons = const <String>[]})
    : super('The password must be at least $minLength characters.');

  static const int minLength = 8;

  final List<String> reasons;
}

final class AuthRateLimitedException extends AuthException {
  const AuthRateLimitedException()
    : super('Too many attempts; Supabase asked us to wait.');
}

final class AuthNetworkException extends AuthException {
  const AuthNetworkException() : super('Could not reach Supabase Auth.');
}

final class AuthConfirmationRequiredException extends AuthException {
  const AuthConfirmationRequiredException()
    : super(
        'The account was created but must confirm its email before signing in.',
      );
}

final class AuthUnexpectedException extends AuthException {
  const AuthUnexpectedException(super.message, {this.code, this.statusCode});

  final String? code;
  final String? statusCode;

  String get detail => <String?>[code, statusCode].nonNulls.join(' · ');
}
