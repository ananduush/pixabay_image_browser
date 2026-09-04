import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../controllers/auth_form_state.dart';
import '../services/auth_exception.dart';

/// Critical glyph plus one line of copy under the fields. Owns the user
/// copy for every [AuthException] and [AuthFormIssue], the way
/// `GalleryErrorView` owns the Pixabay failure copy.
class AuthErrorRow extends StatelessWidget {
  const AuthErrorRow({super.key, required this.message});

  final String message;

  static const String incompleteCopy =
      'Enter an email and a password to continue.';
  static const String invalidEmailCopy = 'Enter a valid email address.';
  static const String passwordTooShortCopy =
      'Use at least ${AuthWeakPasswordException.minLength} characters for '
      'your password.';
  static const String passwordMismatchCopy = "Passwords don't match.";
  static const String invalidCredentialsCopy =
      "That email and password don't match.";
  static const String emailInUseCopy =
      'An account with this email already exists. Sign in instead.';
  static const String rateLimitedCopy =
      'Too many attempts. Wait a moment, then try again.';
  static const String networkCopy =
      "Can't reach the sign-in service. Check your connection and try again.";
  static const String confirmationRequiredCopy =
      'Check your inbox to confirm this email, then sign in.';
  static const String unexpectedCopy = 'Something went wrong. Try again.';

  static String issueCopy(AuthFormIssue issue) => switch (issue) {
    AuthFormIncomplete() => incompleteCopy,
    AuthFormInvalidEmail() => invalidEmailCopy,
    AuthFormPasswordTooShort() => passwordTooShortCopy,
    AuthFormPasswordMismatch() => passwordMismatchCopy,
  };

  static String errorCopy(AuthException error) => switch (error) {
    AuthInvalidCredentialsException() => invalidCredentialsCopy,
    AuthEmailInUseException() => emailInUseCopy,
    AuthInvalidEmailException() => invalidEmailCopy,
    AuthWeakPasswordException() => passwordTooShortCopy,
    AuthRateLimitedException() => rateLimitedCopy,
    AuthNetworkException() => networkCopy,
    AuthConfirmationRequiredException() => confirmationRequiredCopy,
    AuthUnexpectedException() => unexpectedCopy,
    // developer-facing: the run instructions themselves
    AuthMissingConfigException(:final message) => message,
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(Icons.error_outline, size: 14, color: AppColors.critical),
        ),
        Expanded(child: Text(message, style: AppTypography.formError)),
      ],
    );
  }
}
