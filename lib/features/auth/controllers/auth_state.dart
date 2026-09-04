import '../models/auth_user.dart';
import '../services/auth_exception.dart';

enum AuthIntent { signIn, createAccount }

sealed class AuthState {
  const AuthState();

  AuthUser? get user => null;

  bool get isAuthenticated => user != null;
}

final class AuthRestoring extends AuthState {
  const AuthRestoring();
}

final class AuthGuest extends AuthState {
  const AuthGuest();
}

final class AuthAuthenticating extends AuthState {
  const AuthAuthenticating(this.intent);

  final AuthIntent intent;
}

final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user, {this.signingOut = false});

  @override
  final AuthUser user;

  final bool signingOut;
}

final class AuthFailed extends AuthState {
  const AuthFailed(this.error, {required this.intent});

  final AuthException error;

  final AuthIntent intent;
}

final class AuthUnavailable extends AuthState {
  const AuthUnavailable(this.error);

  final AuthMissingConfigException error;
}
