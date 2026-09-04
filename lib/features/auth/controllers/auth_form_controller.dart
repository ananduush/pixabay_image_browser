import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../services/auth_exception.dart';
import 'auth_controller.dart';
import 'auth_form_state.dart';
import 'auth_state.dart';

/// The sign-in / create-account form. Scoped to the auth route so the typed
/// values live exactly as long as the screen; the outcome of a submission is
/// app state on [AuthController].
class AuthFormController extends GetxController {
  AuthFormController({required this._auth});

  final AuthController _auth;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  final FocusNode emailFocus = FocusNode(debugLabel: 'email');
  final FocusNode passwordFocus = FocusNode(debugLabel: 'password');
  final FocusNode confirmFocus = FocusNode(debugLabel: 'confirm password');

  final Rx<AuthMode> mode = Rx<AuthMode>(AuthMode.signIn);

  /// Local validation problem from the last submit; cleared on edit.
  final Rxn<AuthFormIssue> issue = Rxn<AuthFormIssue>();

  /// Every required field has something in it. Drives the button's muted
  /// look only: submitting an incomplete form still explains what is missing.
  final RxBool canSubmit = false.obs;

  /// Mirrors `minimum_password_length` in supabase/config.toml.
  static const int minPasswordLength = AuthWeakPasswordException.minLength;

  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static bool isValidEmail(String value) => _emailPattern.hasMatch(value);

  /// App-wide auth state, for the busy look and the failure copy.
  AuthState get authState => _auth.state.value;

  bool get isBusy => authState is AuthAuthenticating;

  /// The last rejected attempt, until the user edits or leaves.
  AuthException? get failure => switch (authState) {
    AuthFailed(:final error) => error,
    _ => null,
  };

  @override
  void onInit() {
    super.onInit();
    emailController.addListener(_onFieldChanged);
    passwordController.addListener(_onFieldChanged);
    confirmController.addListener(_onFieldChanged);
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    confirmFocus.dispose();
    _auth.clearFailure();
    super.onClose();
  }

  /// Flip between signing in and creating an account. Typed values stay.
  void toggleMode() {
    mode.value = switch (mode.value) {
      AuthMode.signIn => AuthMode.createAccount,
      AuthMode.createAccount => AuthMode.signIn,
    };
    issue.value = null;
    _auth.clearFailure();
    _recompute();
  }

  /// Local checks, in the order the design explains them.
  AuthFormIssue? validate() {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final creating = mode.value == AuthMode.createAccount;
    if (email.isEmpty ||
        password.isEmpty ||
        (creating && confirmController.text.isEmpty)) {
      return const AuthFormIncomplete();
    }
    if (!isValidEmail(email)) return const AuthFormInvalidEmail();
    if (creating && password.length < minPasswordLength) {
      return const AuthFormPasswordTooShort();
    }
    if (creating && confirmController.text != password) {
      return const AuthFormPasswordMismatch();
    }
    return null;
  }

  /// Validates, then asks [AuthController] to sign in or sign up.
  /// Returns `true` once a session exists. A second call while a request is
  /// in flight is ignored.
  Future<bool> submit() async {
    if (isBusy) return false;
    final problem = validate();
    if (problem != null) {
      issue.value = problem;
      return false;
    }
    issue.value = null;
    final email = emailController.text.trim();
    final password = passwordController.text;
    return switch (mode.value) {
      AuthMode.signIn => _auth.signIn(email: email, password: password),
      AuthMode.createAccount => _auth.signUp(email: email, password: password),
    };
  }

  void _onFieldChanged() {
    issue.value = null;
    _auth.clearFailure();
    _recompute();
  }

  void _recompute() {
    final creating = mode.value == AuthMode.createAccount;
    canSubmit.value =
        emailController.text.trim().isNotEmpty &&
        passwordController.text.isNotEmpty &&
        (!creating || confirmController.text.isNotEmpty);
  }
}
