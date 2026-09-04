import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/auth_user.dart';
import '../repositories/auth_repository.dart';
import '../services/auth_exception.dart';
import 'auth_state.dart';

/// App-scoped authentication state. Supabase is the only source of truth:
/// the state is a snapshot of its session at startup and then follows its
/// auth events. There is no separate "logged in" flag and no token copy.
class AuthController extends GetxController {
  AuthController({required this._repository});

  final AuthRepository _repository;

  final Rx<AuthState> state = Rx<AuthState>(const AuthRestoring());

  StreamSubscription<AuthUser?>? _subscription;

  @override
  void onInit() {
    super.onInit();
    try {
      // Subscribe first, then snapshot, so nothing between the two is missed.
      _subscription = _repository.userChanges().listen(
        _onUserChanged,
        onError: _onStreamError,
      );
      _apply(_repository.currentUser());
    } on AuthMissingConfigException catch (error) {
      debugPrint(error.message);
      state.value = AuthUnavailable(error);
    }
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }

  /// Email/password sign in. Returns `true` when the session was created;
  /// a failure lands in [AuthFailed]. Ignored while a request is in flight.
  Future<bool> signIn({required String email, required String password}) {
    return _authenticate(
      AuthIntent.signIn,
      () => _repository.signIn(email: email, password: password),
    );
  }

  /// Account creation. With confirmations disabled the user is signed in at
  /// once; otherwise [AuthFailed] carries [AuthConfirmationRequiredException].
  Future<bool> signUp({required String email, required String password}) {
    return _authenticate(
      AuthIntent.createAccount,
      () => _repository.signUp(email: email, password: password),
    );
  }

  /// Back to [AuthGuest] after a failed attempt (the form was edited or left).
  void clearFailure() {
    if (state.value is AuthFailed) state.value = const AuthGuest();
  }

  /// Signs out of Supabase. The SDK drops the local session before the
  /// server revoke, so the app is a guest even if the revoke fails. Gallery
  /// and search state are untouched.
  Future<void> signOut() async {
    if (state.value case AuthAuthenticated(:final user, signingOut: false)) {
      state.value = AuthAuthenticated(user, signingOut: true);
    } else {
      return;
    }
    try {
      await _repository.signOut();
    } on AuthException catch (error) {
      debugPrint('AuthController: sign-out revoke failed: $error');
    } finally {
      _apply(_repository.currentUser());
    }
  }

  Future<bool> _authenticate(
    AuthIntent intent,
    Future<AuthUser> Function() request,
  ) async {
    // Duplicate submissions and unusable states are ignored.
    if (state.value
        case AuthAuthenticating() || AuthUnavailable() || AuthRestoring()) {
      return false;
    }
    state.value = AuthAuthenticating(intent);
    try {
      _apply(await request());
      return true;
    } on AuthException catch (error) {
      state.value = AuthFailed(error, intent: intent);
      return false;
    } catch (error) {
      // A bug, not an auth outcome: show a failure but keep it visible to
      // crash reporting.
      state.value = AuthFailed(
        AuthUnexpectedException('$error'),
        intent: intent,
      );
      rethrow;
    }
  }

  void _onUserChanged(AuthUser? user) {
    // The in-flight request decides its own outcome.
    if (state.value is AuthAuthenticating) return;
    _apply(user);
  }

  void _onStreamError(Object error) {
    debugPrint('AuthController: auth event error: $error');
  }

  void _apply(AuthUser? user) {
    state.value = user == null ? const AuthGuest() : AuthAuthenticated(user);
  }
}
