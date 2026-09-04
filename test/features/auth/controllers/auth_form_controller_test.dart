import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pixabay_image_browser/features/auth/controllers/auth_controller.dart';
import 'package:pixabay_image_browser/features/auth/controllers/auth_form_controller.dart';
import 'package:pixabay_image_browser/features/auth/controllers/auth_form_state.dart';
import 'package:pixabay_image_browser/features/auth/controllers/auth_state.dart';
import 'package:pixabay_image_browser/features/auth/models/auth_user.dart';
import 'package:pixabay_image_browser/features/auth/services/auth_exception.dart';

import '../../../support/auth_fixtures.dart';

void main() {
  late MockAuthRepository repository;
  late AuthController auth;
  late AuthFormController form;

  setUp(() {
    Get.testMode = true;
    repository = stubAuthRepository(MockAuthRepository());
    auth = AuthController(repository: repository)..onInit();
    form = AuthFormController(auth: auth)..onInit();
  });

  tearDown(() {
    form.onClose();
    auth.onClose();
    Get.reset();
  });

  void fill({String email = '', String password = '', String confirm = ''}) {
    form.emailController.text = email;
    form.passwordController.text = password;
    form.confirmController.text = confirm;
  }

  void stubSignIn(Future<AuthUser> Function() answer) {
    when(
      () => repository.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) => answer());
  }

  group('validation', () {
    test('empty fields are incomplete and nothing is sent', () async {
      fill(email: 'sam@aperture.app');

      expect(await form.submit(), isFalse);

      expect(form.issue.value, isA<AuthFormIncomplete>());
      verifyNever(
        () => repository.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
    });

    test('a malformed email is rejected locally', () async {
      fill(email: 'sam@', password: 'password1');

      expect(await form.submit(), isFalse);

      expect(form.issue.value, isA<AuthFormInvalidEmail>());
    });

    test(
      'creating an account needs the confirmation and 8+ characters',
      () async {
        form.toggleMode();
        expect(form.mode.value, AuthMode.createAccount);

        fill(email: 'sam@aperture.app', password: 'short');
        expect(await form.submit(), isFalse);
        expect(form.issue.value, isA<AuthFormIncomplete>());

        fill(email: 'sam@aperture.app', password: 'short', confirm: 'short');
        expect(await form.submit(), isFalse);
        expect(form.issue.value, isA<AuthFormPasswordTooShort>());

        fill(
          email: 'sam@aperture.app',
          password: 'password1',
          confirm: 'password2',
        );
        expect(await form.submit(), isFalse);
        expect(form.issue.value, isA<AuthFormPasswordMismatch>());
      },
    );

    test('editing a field clears the issue', () async {
      await form.submit();
      expect(form.issue.value, isNotNull);

      form.emailController.text = 's';

      expect(form.issue.value, isNull);
    });

    test('canSubmit follows the required fields and the mode', () {
      expect(form.canSubmit.value, isFalse);
      fill(email: 'sam@aperture.app', password: 'pw');
      expect(form.canSubmit.value, isTrue);

      form.toggleMode();
      expect(form.canSubmit.value, isFalse);
      form.confirmController.text = 'pw';
      expect(form.canSubmit.value, isTrue);
    });
  });

  group('submit', () {
    test('signs in with the trimmed email and reports success', () async {
      fill(email: '  sam@aperture.app ', password: 'correct horse');
      stubSignIn(() async => sampleUser());

      expect(await form.submit(), isTrue);

      verify(
        () => repository.signIn(
          email: 'sam@aperture.app',
          password: 'correct horse',
        ),
      ).called(1);
      expect(auth.state.value.isAuthenticated, isTrue);
    });

    test('creates an account in create mode', () async {
      form.toggleMode();
      fill(
        email: 'new@aperture.app',
        password: 'password1',
        confirm: 'password1',
      );
      when(
        () => repository.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => sampleUser(email: 'new@aperture.app'));

      expect(await form.submit(), isTrue);

      verify(
        () =>
            repository.signUp(email: 'new@aperture.app', password: 'password1'),
      ).called(1);
    });

    test(
      'a rejection is exposed as the failure and keeps the values',
      () async {
        fill(email: 'sam@aperture.app', password: 'wrong');
        stubSignIn(() async => throw const AuthInvalidCredentialsException());

        expect(await form.submit(), isFalse);

        expect(form.failure, isA<AuthInvalidCredentialsException>());
        expect(form.emailController.text, 'sam@aperture.app');
        expect(form.passwordController.text, 'wrong');

        // Editing clears the failure so the form is usable again.
        form.passwordController.text = 'wrong2';
        expect(form.failure, isNull);
        expect(auth.state.value, isA<AuthGuest>());
      },
    );

    test('a second submit while busy is ignored', () async {
      fill(email: 'sam@aperture.app', password: 'pw');
      final pending = Completer<AuthUser>();
      stubSignIn(() => pending.future);

      final first = form.submit();
      expect(form.isBusy, isTrue);
      expect(await form.submit(), isFalse);

      pending.complete(sampleUser());
      expect(await first, isTrue);
      verify(
        () => repository.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).called(1);
    });

    test('toggling the mode keeps the text and clears errors', () async {
      fill(email: 'sam@aperture.app', password: 'wrong');
      stubSignIn(() async => throw const AuthInvalidCredentialsException());
      await form.submit();

      form.toggleMode();

      expect(form.mode.value, AuthMode.createAccount);
      expect(form.emailController.text, 'sam@aperture.app');
      expect(form.passwordController.text, 'wrong');
      expect(form.failure, isNull);
      expect(form.issue.value, isNull);
    });
  });
}
