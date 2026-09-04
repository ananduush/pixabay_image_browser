import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pixabay_image_browser/features/auth/controllers/auth_controller.dart';
import 'package:pixabay_image_browser/features/auth/controllers/auth_state.dart';
import 'package:pixabay_image_browser/features/auth/models/auth_user.dart';
import 'package:pixabay_image_browser/features/auth/services/auth_exception.dart';

import '../../../support/auth_fixtures.dart';

void main() {
  late MockAuthRepository repository;
  late StreamController<AuthUser?> changes;

  setUp(() {
    Get.testMode = true;
    repository = MockAuthRepository();
    changes = StreamController<AuthUser?>.broadcast();
  });

  tearDown(() async {
    await changes.close();
    Get.reset();
  });

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  AuthController start({AuthUser? user}) {
    stubAuthRepository(repository, user: user, changes: changes);
    final controller = AuthController(repository: repository);
    addTearDown(controller.onClose);
    return controller..onInit();
  }

  void stubSignIn(Future<AuthUser> Function() answer) {
    when(
      () => repository.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) => answer());
  }

  void stubSignUp(Future<AuthUser> Function() answer) {
    when(
      () => repository.signUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) => answer());
  }

  group('startup', () {
    test(
      'restoring until the snapshot, then guest when there is no session',
      () {
        stubAuthRepository(repository, changes: changes);
        final controller = AuthController(repository: repository);
        addTearDown(controller.onClose);

        expect(controller.state.value, isA<AuthRestoring>());
        controller.onInit();
        expect(controller.state.value, isA<AuthGuest>());
        expect(controller.state.value.isAuthenticated, isFalse);
      },
    );

    test('a restored session is authenticated at once', () {
      final controller = start(user: sampleUser());

      expect(
        controller.state.value,
        isA<AuthAuthenticated>().having(
          (AuthAuthenticated s) => s.user.email,
          'email',
          'sam@aperture.app',
        ),
      );
      expect(controller.state.value.isAuthenticated, isTrue);
    });

    test(
      'missing configuration is unavailable and requests are ignored',
      () async {
        when(
          repository.userChanges,
        ).thenThrow(const AuthMissingConfigException());
        final controller = AuthController(repository: repository)..onInit();
        addTearDown(controller.onClose);

        expect(controller.state.value, isA<AuthUnavailable>());
        expect(
          await controller.signIn(email: 'a@b.c', password: 'pw'),
          isFalse,
        );
        expect(controller.state.value, isA<AuthUnavailable>());
        verifyNever(
          () => repository.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        );
      },
    );
  });

  group('sign in', () {
    test('success authenticates with the returned user', () async {
      final controller = start();
      final user = sampleUser();
      stubSignIn(() async => user);

      final ok = await controller.signIn(
        email: 'sam@aperture.app',
        password: 'correct horse',
      );

      expect(ok, isTrue);
      expect(controller.state.value.user, user);
      verify(
        () => repository.signIn(
          email: 'sam@aperture.app',
          password: 'correct horse',
        ),
      ).called(1);
    });

    test(
      'invalid credentials fail and clearFailure returns to guest',
      () async {
        final controller = start();
        stubSignIn(() async => throw const AuthInvalidCredentialsException());

        final ok = await controller.signIn(email: 'a@b.c', password: 'wrong');

        expect(ok, isFalse);
        expect(
          controller.state.value,
          isA<AuthFailed>()
              .having(
                (AuthFailed s) => s.error,
                'error',
                isA<AuthInvalidCredentialsException>(),
              )
              .having((AuthFailed s) => s.intent, 'intent', AuthIntent.signIn),
        );
        expect(controller.state.value.isAuthenticated, isFalse);

        controller.clearFailure();
        expect(controller.state.value, isA<AuthGuest>());
      },
    );

    test('a second submission while one is in flight is ignored', () async {
      final controller = start();
      final pending = Completer<AuthUser>();
      stubSignIn(() => pending.future);

      final first = controller.signIn(email: 'a@b.c', password: 'pw');
      expect(controller.state.value, isA<AuthAuthenticating>());
      final second = await controller.signIn(email: 'a@b.c', password: 'pw');

      expect(second, isFalse);
      pending.complete(sampleUser());
      expect(await first, isTrue);
      verify(
        () => repository.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).called(1);
    });

    test('an auth event during the request does not pre-empt it', () async {
      final controller = start();
      final pending = Completer<AuthUser>();
      stubSignIn(() => pending.future);

      final result = controller.signIn(email: 'a@b.c', password: 'pw');
      changes.add(sampleUser());
      await settle();
      expect(controller.state.value, isA<AuthAuthenticating>());

      pending.completeError(const AuthNetworkException());
      expect(await result, isFalse);
      expect(
        controller.state.value,
        isA<AuthFailed>().having(
          (AuthFailed s) => s.error,
          'error',
          isA<AuthNetworkException>(),
        ),
      );
    });

    test('an unexpected error becomes a failure and is rethrown', () async {
      final controller = start();
      stubSignIn(() async => throw StateError('bug'));

      await expectLater(
        controller.signIn(email: 'a@b.c', password: 'pw'),
        throwsStateError,
      );
      expect(
        controller.state.value,
        isA<AuthFailed>().having(
          (AuthFailed s) => s.error,
          'error',
          isA<AuthUnexpectedException>(),
        ),
      );
    });
  });

  group('sign up', () {
    test('success authenticates immediately (confirmations are off)', () async {
      final controller = start();
      final user = sampleUser(email: 'new@aperture.app');
      stubSignUp(() async => user);

      final ok = await controller.signUp(
        email: 'new@aperture.app',
        password: 'password1',
      );

      expect(ok, isTrue);
      expect(controller.state.value.user, user);
    });

    test('an existing email fails with the create-account intent', () async {
      final controller = start();
      stubSignUp(() async => throw const AuthEmailInUseException());

      expect(
        await controller.signUp(email: 'a@b.c', password: 'password1'),
        isFalse,
      );
      expect(
        controller.state.value,
        isA<AuthFailed>()
            .having(
              (AuthFailed s) => s.error,
              'error',
              isA<AuthEmailInUseException>(),
            )
            .having(
              (AuthFailed s) => s.intent,
              'intent',
              AuthIntent.createAccount,
            ),
      );
    });

    test(
      'a user without a session is reported, not treated as signed in',
      () async {
        final controller = start();
        stubSignUp(() async => throw const AuthConfirmationRequiredException());

        expect(
          await controller.signUp(email: 'a@b.c', password: 'password1'),
          isFalse,
        );
        expect(controller.state.value.isAuthenticated, isFalse);
        expect(
          controller.state.value,
          isA<AuthFailed>().having(
            (AuthFailed s) => s.error,
            'error',
            isA<AuthConfirmationRequiredException>(),
          ),
        );
      },
    );
  });

  group('sign out', () {
    test('returns to guest and calls the repository once', () async {
      final controller = start(user: sampleUser());
      when(repository.signOut).thenAnswer((_) async {
        when(repository.currentUser).thenReturn(null);
      });

      final signingOut = controller.signOut();
      expect(
        controller.state.value,
        isA<AuthAuthenticated>().having(
          (AuthAuthenticated s) => s.signingOut,
          'signingOut',
          isTrue,
        ),
      );
      await signingOut;

      expect(controller.state.value, isA<AuthGuest>());
      verify(repository.signOut).called(1);
    });

    test('a failed server revoke still leaves a guest', () async {
      final controller = start(user: sampleUser());
      when(repository.signOut).thenAnswer((_) async {
        when(repository.currentUser).thenReturn(null);
        throw const AuthNetworkException();
      });

      await controller.signOut();

      expect(controller.state.value, isA<AuthGuest>());
    });

    test('is ignored while already signing out or as a guest', () async {
      final controller = start();
      await controller.signOut();
      verifyNever(repository.signOut);
    });
  });

  group('auth events', () {
    test('a signed-out event makes an authenticated user a guest', () async {
      final controller = start(user: sampleUser());

      changes.add(null);
      await settle();

      expect(controller.state.value, isA<AuthGuest>());
    });

    test('a session event (restore, refresh, sign in) authenticates', () async {
      final controller = start();
      final user = sampleUser();

      changes.add(user);
      await settle();

      expect(controller.state.value.user, user);
    });

    test('onClose stops listening', () async {
      final controller = start();
      expect(changes.hasListener, isTrue);

      controller.onClose();
      await settle();

      expect(changes.hasListener, isFalse);
    });
  });
}
