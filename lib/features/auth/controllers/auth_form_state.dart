enum AuthMode { signIn, createAccount }

sealed class AuthFormIssue {
  const AuthFormIssue();
}

final class AuthFormIncomplete extends AuthFormIssue {
  const AuthFormIncomplete();
}

final class AuthFormInvalidEmail extends AuthFormIssue {
  const AuthFormInvalidEmail();
}

final class AuthFormPasswordTooShort extends AuthFormIssue {
  const AuthFormPasswordTooShort();
}

final class AuthFormPasswordMismatch extends AuthFormIssue {
  const AuthFormPasswordMismatch();
}
