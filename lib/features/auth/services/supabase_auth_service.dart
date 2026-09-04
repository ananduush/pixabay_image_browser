import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../models/auth_user.dart';
import 'auth_exception.dart';

class SupabaseAuthService {
  const SupabaseAuthService({required supabase.GoTrueClient this._client});

  const SupabaseAuthService.unconfigured() : _client = null;

  final supabase.GoTrueClient? _client;

  static const String invalidCredentialsCode = 'invalid_credentials';
  static const String emailAddressInvalidCode = 'email_address_invalid';

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

  AuthUser? currentUser() => _toUser(_auth.currentUser);

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

  Future<AuthUser> signUp({required String email, required String password}) {
    return _guard(() async {
      final response = await _auth.signUp(email: email, password: password);
      if (response.session == null) {
        throw const AuthConfirmationRequiredException();
      }
      return _userFrom(response);
    });
  }

  Future<void> signOut() {
    return _guard(() async {
      try {
        await _auth.signOut();
      } on supabase.AuthSessionMissingException {}
    });
  }

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } catch (error) {
      throw mapError(error);
    }
  }

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
