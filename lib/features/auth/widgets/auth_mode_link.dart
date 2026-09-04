import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../controllers/auth_form_state.dart';

/// Text link under the primary action that flips the screen between
/// signing in and creating an account.
class AuthModeLink extends StatelessWidget {
  const AuthModeLink({super.key, required this.mode, required this.onTap});

  /// The mode currently shown; the link offers the other one.
  final AuthMode mode;
  final VoidCallback onTap;

  static const String toCreatePrompt = 'New to Aperture?';
  static const String toCreateAction = 'Create an account';
  static const String toSignInPrompt = 'Already have an account?';
  static const String toSignInAction = 'Sign in';

  static String promptFor(AuthMode mode) => switch (mode) {
    AuthMode.signIn => toCreatePrompt,
    AuthMode.createAccount => toSignInPrompt,
  };

  static String actionFor(AuthMode mode) => switch (mode) {
    AuthMode.signIn => toCreateAction,
    AuthMode.createAccount => toSignInAction,
  };

  @override
  Widget build(BuildContext context) {
    final prompt = promptFor(mode);
    final action = actionFor(mode);
    return Semantics(
      button: true,
      label: '$prompt $action',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text.rich(
            TextSpan(
              children: <InlineSpan>[
                TextSpan(text: '$prompt ', style: AppTypography.link),
                TextSpan(
                  text: action,
                  style: AppTypography.link.copyWith(
                    color: AppColors.ink,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
