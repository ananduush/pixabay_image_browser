import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../services/auth_exception.dart';
import 'auth_controller.dart';
import 'auth_form_state.dart';
import 'auth_state.dart';

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

  final Rxn<AuthFormIssue> issue = Rxn<AuthFormIssue>();

  final RxBool canSubmit = false.obs;

  static const int minPasswordLength = AuthWeakPasswordException.minLength;

  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static bool isValidEmail(String value) => _emailPattern.hasMatch(value);

  AuthState get authState => _auth.state.value;

  bool get isBusy => authState is AuthAuthenticating;

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

  void toggleMode() {
    mode.value = switch (mode.value) {
      AuthMode.signIn => AuthMode.createAccount,
      AuthMode.createAccount => AuthMode.signIn,
    };
    issue.value = null;
    _auth.clearFailure();
    _recompute();
  }

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
