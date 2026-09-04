import '../models/auth_user.dart';
import '../services/auth_exception.dart';

/// What the user was trying to do when a request was in flight or failed.
enum AuthIntent { signIn, createAccount }

/// App-wide authentication state, derived only from the Supabase session
/// (snapshot at startup, then the auth event stream). Sealed so views and
/// the shell can switch exhaustively.
sealed class AuthState {
  const AuthState();

  AuthUser? get user => null;

  bool get isAuthenticated => user != null;
}

/// Startup, before the persisted session has been inspected.
final class AuthRestoring extends AuthState {
  const AuthRestoring();
}

/// No session. Browsing works; accounts are available.
final class AuthGuest extends AuthState {
  const AuthGuest();
}

/// A sign-in or sign-up request is in flight (still a guest).
final class AuthAuthenticating extends AuthState {
  const AuthAuthenticating(this.intent);

  final AuthIntent intent;
}

/// A Supabase session exists.
final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user, {this.signingOut = false});

  @override
  final AuthUser user;

  /// Sign-out request in flight.
  final bool signingOut;
}

/// The last sign-in or sign-up attempt failed (still a guest). Cleared when
/// the user edits the form or leaves it.
final class AuthFailed extends AuthState {
  const AuthFailed(this.error, {required this.intent});

  final AuthException error;

  final AuthIntent intent;
}

/// Supabase is not configured for this build; accounts cannot be used at
/// all. Browsing is unaffected.
final class AuthUnavailable extends AuthState {
  const AuthUnavailable(this.error);

  final AuthMissingConfigException error;
}
