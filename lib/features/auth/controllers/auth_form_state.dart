/// Which form the single auth screen is showing.
enum AuthMode { signIn, createAccount }

/// Local validation problems, found before anything is sent to Supabase.
/// Sealed so the view maps each to its copy exhaustively.
sealed class AuthFormIssue {
  const AuthFormIssue();
}

/// Email or password (or the confirmation, when creating) is empty.
final class AuthFormIncomplete extends AuthFormIssue {
  const AuthFormIncomplete();
}

final class AuthFormInvalidEmail extends AuthFormIssue {
  const AuthFormInvalidEmail();
}

/// Create-account only: shorter than the project's minimum.
final class AuthFormPasswordTooShort extends AuthFormIssue {
  const AuthFormPasswordTooShort();
}

/// Create-account only: the confirmation differs.
final class AuthFormPasswordMismatch extends AuthFormIssue {
  const AuthFormPasswordMismatch();
}
