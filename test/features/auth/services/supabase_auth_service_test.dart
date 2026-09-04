import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pixabay_image_browser/features/auth/models/auth_user.dart';
import 'package:pixabay_image_browser/features/auth/services/auth_exception.dart';
import 'package:pixabay_image_browser/features/auth/services/supabase_auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class _MockGoTrueClient extends Mock implements supabase.GoTrueClient {}

/// The only test that touches Supabase types — and only in memory.
void main() {
  supabase.User user({String email = 'sam@aperture.app'}) {
    final parsed = supabase.User.fromJson(<String, dynamic>{
      'id': '27183e01-fdea-4259-886d-19530b352bf8',
      'aud': 'authenticated',
      'email': email,
      'created_at': '2026-09-04T07:10:30Z',
      'app_metadata': <String, dynamic>{'provider': 'email'},
      'user_metadata': <String, dynamic>{},
    });
    return parsed ?? (throw StateError('fixture user did not parse'));
  }

  supabase.Session session(supabase.User user) {
    final parsed = supabase.Session.fromJson(<String, dynamic>{
      'access_token': 'access',
      'refresh_token': 'refresh',
      'token_type': 'bearer',
      'expires_in': 3600,
      'user': user.toJson(),
    });
    return parsed ?? (throw StateError('fixture session did not parse'));
  }

  group('unconfigured', () {
    const service = SupabaseAuthService.unconfigured();

    test('reports the missing configuration from every call', () async {
      expect(service.isConfigured, isFalse);
      expect(service.currentUser, throwsA(isA<AuthMissingConfigException>()));
      expect(service.userChanges, throwsA(isA<AuthMissingConfigException>()));
      await expectLater(
        service.signIn(email: 'a@b.c', password: 'pw'),
        throwsA(isA<AuthMissingConfigException>()),
      );
      await expectLater(
        service.signUp(email: 'a@b.c', password: 'pw'),
        throwsA(isA<AuthMissingConfigException>()),
      );
      await expectLater(
        service.signOut(),
        throwsA(isA<AuthMissingConfigException>()),
      );
    });

    test('the message carries the run instructions', () {
      expect(
        const AuthMissingConfigException().message,
        allOf(
          contains('SUPABASE_URL'),
          contains('SUPABASE_PUBLISHABLE_KEY'),
          contains('--dart-define-from-file=env.json'),
        ),
      );
    });
  });

  group('with a client', () {
    late _MockGoTrueClient client;
    late SupabaseAuthService service;

    setUp(() {
      client = _MockGoTrueClient();
      service = SupabaseAuthService(client: client);
    });

    test('currentUser maps the restored session user', () {
      final u = user();
      when(() => client.currentUser).thenReturn(u);

      expect(
        service.currentUser(),
        AuthUser(
          id: u.id,
          email: 'sam@aperture.app',
          createdAt: DateTime.utc(2026, 9, 4, 7, 10, 30),
        ),
      );
    });

    test('currentUser is null for a guest', () {
      when(() => client.currentUser).thenReturn(null);
      expect(service.currentUser(), isNull);
    });

    test('signIn returns the session user', () async {
      final u = user();
      when(
        () => client.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => supabase.AuthResponse(session: session(u)));

      final result = await service.signIn(
        email: 'sam@aperture.app',
        password: 'pw',
      );

      expect(result.id, u.id);
      expect(result.email, 'sam@aperture.app');
    });

    test('signUp without a session means confirmation is required', () async {
      when(
        () => client.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => supabase.AuthResponse(user: user()));

      await expectLater(
        service.signUp(email: 'sam@aperture.app', password: 'password1'),
        throwsA(isA<AuthConfirmationRequiredException>()),
      );
    });

    test('signUp with a session is signed in at once', () async {
      final u = user();
      when(
        () => client.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => supabase.AuthResponse(session: session(u)));

      final result = await service.signUp(
        email: 'sam@aperture.app',
        password: 'password1',
      );

      expect(result.id, u.id);
    });

    test('signOut ignores an already-missing session', () async {
      when(
        () => client.signOut(),
      ).thenThrow(supabase.AuthSessionMissingException());

      await expectLater(service.signOut(), completes);
    });

    test('signOut maps a transport failure', () async {
      when(
        () => client.signOut(),
      ).thenThrow(supabase.AuthRetryableFetchException());

      await expectLater(
        service.signOut(),
        throwsA(isA<AuthNetworkException>()),
      );
    });

    test('userChanges maps every event to the session user or null', () async {
      final events = StreamController<supabase.AuthState>();
      when(() => client.onAuthStateChange).thenAnswer((_) => events.stream);
      final u = user();

      final seen = service.userChanges().toList();
      events
        ..add(supabase.AuthState(supabase.AuthChangeEvent.signedIn, session(u)))
        ..add(supabase.AuthState(supabase.AuthChangeEvent.signedOut, null));
      unawaited(events.close());

      expect((await seen).map((AuthUser? x) => x?.id), <String?>[u.id, null]);
    });

    test('userChanges maps stream errors too', () async {
      final events = StreamController<supabase.AuthState>();
      when(() => client.onAuthStateChange).thenAnswer((_) => events.stream);

      final first = service.userChanges().first;
      events.addError(supabase.AuthRetryableFetchException());
      unawaited(events.close());

      await expectLater(first, throwsA(isA<AuthNetworkException>()));
    });
  });

  group('mapError', () {
    AuthException map(Object error) => SupabaseAuthService.mapError(error);

    test('keeps app exceptions as they are', () {
      const own = AuthInvalidEmailException();
      expect(map(own), same(own));
    });

    test('invalid_credentials', () {
      expect(
        map(
          const supabase.AuthApiException(
            'Invalid login credentials',
            statusCode: '400',
            code: 'invalid_credentials',
          ),
        ),
        isA<AuthInvalidCredentialsException>(),
      );
    });

    test('user_already_exists and email_exists', () {
      for (final code in <String>['user_already_exists', 'email_exists']) {
        expect(
          map(supabase.AuthApiException('x', statusCode: '422', code: code)),
          isA<AuthEmailInUseException>(),
          reason: code,
        );
      }
    });

    test('email_address_invalid and validation_failed', () {
      for (final code in <String>[
        'email_address_invalid',
        'validation_failed',
      ]) {
        expect(
          map(supabase.AuthApiException('x', statusCode: '400', code: code)),
          isA<AuthInvalidEmailException>(),
          reason: code,
        );
      }
    });

    test('weak passwords carry the backend reasons', () {
      final mapped = map(
        supabase.AuthWeakPasswordException(
          message: 'Password should be at least 8 characters.',
          statusCode: '422',
          reasons: <String>['length'],
        ),
      );
      expect(
        mapped,
        isA<AuthWeakPasswordException>().having(
          (AuthWeakPasswordException e) => e.reasons,
          'reasons',
          <String>['length'],
        ),
      );
      expect(
        map(
          const supabase.AuthApiException(
            'x',
            statusCode: '422',
            code: 'weak_password',
          ),
        ),
        isA<AuthWeakPasswordException>(),
      );
    });

    test('rate limits, by code or by status', () {
      expect(
        map(
          const supabase.AuthApiException(
            'x',
            statusCode: '429',
            code: 'over_request_rate_limit',
          ),
        ),
        isA<AuthRateLimitedException>(),
      );
      expect(
        map(const supabase.AuthApiException('x', statusCode: '429')),
        isA<AuthRateLimitedException>(),
      );
    });

    test('email_not_confirmed', () {
      expect(
        map(
          const supabase.AuthApiException(
            'x',
            statusCode: '400',
            code: 'email_not_confirmed',
          ),
        ),
        isA<AuthConfirmationRequiredException>(),
      );
    });

    test('transport failures and 5xx are network errors', () {
      expect(
        map(supabase.AuthRetryableFetchException(statusCode: '503')),
        isA<AuthNetworkException>(),
      );
    });

    test('anything else is unexpected, with the structured detail kept', () {
      final mapped = map(
        const supabase.AuthApiException(
          'Signups not allowed for this instance',
          statusCode: '422',
          code: 'signup_disabled',
        ),
      );
      expect(
        mapped,
        isA<AuthUnexpectedException>()
            .having(
              (AuthUnexpectedException e) => e.code,
              'code',
              'signup_disabled',
            )
            .having(
              (AuthUnexpectedException e) => e.detail,
              'detail',
              'signup_disabled · 422',
            ),
      );
      expect(map(StateError('boom')), isA<AuthUnexpectedException>());
    });
  });
}
