import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../models/auth_user.dart';
import 'auth_exception.dart';

/// The only file that talks to Supabase. Nothing above this layer sees a
/// Supabase type: users come out as [AuthUser], failures as [AuthException].
class SupabaseAuthService {
  const SupabaseAuthService({required supabase.GoTrueClient this._client});

  /// No Supabase configuration: every call throws
  /// [AuthMissingConfigException] and the SDK is never touched.
  const SupabaseAuthService.unconfigured() : _client = null;

  final supabase.GoTrueClient? _client;

  /// Auth error codes the SDK's [supabase.ErrorCode] enum does not list.
  static const String invalidCredentialsCode = 'invalid_credentials';
  static const String emailAddressInvalidCode = 'email_address_invalid';

  /// Initialises the Supabase SDK once, at startup, restoring any persisted
  /// session. Missing configuration (or a failed initialise) degrades to the
  /// unconfigured service so the app still boots into the Gallery.
  static Future<SupabaseAuthService> initialize({
    required String url,
    required String publishableKey,
  }) async {
    if (url.isEmpty || publishableKey.isEmpty) {
      debugPrint(const AuthMissingConfigException().message);
      return const SupabaseAuthService.unconfigured();
    }
    try {
      final instance = await supabase.Supabase.initialize(
        url: url,
        publishableKey: publishableKey,
        // No email links or OAuth, so no deep-link listener.
        authOptions: const supabase.FlutterAuthClientOptions(
          detectSessionInUri: false,
        ),
      );
      return SupabaseAuthService(client: instance.client.auth);
    } catch (error) {
      debugPrint('SupabaseAuthService: initialise failed: $error');
      return const SupabaseAuthService.unconfigured();
    }
  }

  bool get isConfigured => _client != null;

  supabase.GoTrueClient get _auth =>
      _client ?? (throw const AuthMissingConfigException());

  /// The restored/current user, if any. Synchronous: the SDK restores the
  /// persisted session inside [initialize].
  AuthUser? currentUser() => _toUser(_auth.currentUser);

  /// The session user after every auth event (sign in, sign out, token
  /// refresh, restore, user deleted…); `null` means signed out.
  Stream<AuthUser?> userChanges() => _auth.onAuthStateChange
      .map((supabase.AuthState change) => _toUser(change.session?.user))
      .transform(
        StreamTransformer<AuthUser?, AuthUser?>.fromHandlers(
          handleError:
              (Object error, StackTrace stackTrace, EventSink<AuthUser?> sink) {
                sink.addError(mapError(error), stackTrace);
              },
        ),
      );

  Future<AuthUser> signIn({required String email, required String password}) {
    return _guard(() async {
      final response = await _auth.signInWithPassword(
        email: email,
        password: password,
      );
      return _userFrom(response);
    });
  }

  /// With confirmations disabled (the prepared configuration) Supabase
  /// returns a session at once. A user without a session means the project
  /// now requires confirmation, which is reported rather than hidden.
  Future<AuthUser> signUp({required String email, required String password}) {
    return _guard(() async {
      final response = await _auth.signUp(email: email, password: password);
      if (response.session == null) {
        throw const AuthConfirmationRequiredException();
      }
      return _userFrom(response);
    });
  }

  /// Drops the local session (the SDK emits `signedOut` before revoking on
  /// the server). An already-missing session is not an error.
  Future<void> signOut() {
    return _guard(() async {
      try {
        await _auth.signOut();
      } on supabase.AuthSessionMissingException {
        // Nothing to sign out of.
      }
    });
  }

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } catch (error) {
      throw mapError(error);
    }
  }

  /// Supabase failure → app failure, on structured fields only (type,
  /// `code`, `statusCode`) — never on message text.
  @visibleForTesting
  static AuthException mapError(Object error) {
    return switch (error) {
      AuthException() => error,
      supabase.AuthWeakPasswordException(:final reasons) =>
        AuthWeakPasswordException(reasons: reasons),
      supabase.AuthRetryableFetchException() => const AuthNetworkException(),
      supabase.AuthApiException(
        :final code,
        :final statusCode,
        :final message,
      ) =>
        _mapApiError(code: code, statusCode: statusCode, message: message),
      supabase.AuthException(:final code, :final statusCode, :final message) =>
        _unexpected(message, code: code, statusCode: statusCode),
      _ => _unexpected('$error'),
    };
  }

  static AuthException _mapApiError({
    required String? code,
    required String? statusCode,
    required String message,
  }) {
    if (code == invalidCredentialsCode) {
      return const AuthInvalidCredentialsException();
    }
    if (code == emailAddressInvalidCode) {
      return const AuthInvalidEmailException();
    }
    final known = code == null ? null : supabase.ErrorCode.fromCode(code);
    return switch (known) {
      supabase.ErrorCode.userAlreadyExists ||
      supabase.ErrorCode.emailExists => const AuthEmailInUseException(),
      supabase.ErrorCode.validationFailed => const AuthInvalidEmailException(),
      supabase.ErrorCode.weakPassword => const AuthWeakPasswordException(),
      supabase.ErrorCode.overRequestRateLimit ||
      supabase.ErrorCode.overEmailSendRateLimit =>
        const AuthRateLimitedException(),
      supabase.ErrorCode.emailNotConfirmed =>
        const AuthConfirmationRequiredException(),
      _ when statusCode == '429' => const AuthRateLimitedException(),
      _ => _unexpected(message, code: code, statusCode: statusCode),
    };
  }

  static AuthUnexpectedException _unexpected(
    String message, {
    String? code,
    String? statusCode,
  }) {
    // Structured detail only: never an email or a password.
    debugPrint(
      'SupabaseAuthService: unexpected auth failure '
      'code=$code status=$statusCode',
    );
    return AuthUnexpectedException(message, code: code, statusCode: statusCode);
  }

  static AuthUser _userFrom(supabase.AuthResponse response) {
    final user = response.user ?? response.session?.user;
    if (user == null) {
      throw _unexpected('Auth response carried no user.');
    }
    return _fromUser(user);
  }

  static AuthUser? _toUser(supabase.User? user) =>
      user == null ? null : _fromUser(user);

  static AuthUser _fromUser(supabase.User user) => AuthUser(
    id: user.id,
    email: user.email ?? '',
    createdAt: DateTime.tryParse(user.createdAt),
  );
}
