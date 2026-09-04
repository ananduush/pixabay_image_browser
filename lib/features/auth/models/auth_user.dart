/// The signed-in account as the app sees it: the stable Supabase user id and
/// the email used to sign in. There is no profiles table, so nothing else.
final class AuthUser {
  const AuthUser({required this.id, required this.email, this.createdAt});

  /// Supabase `User.id` — a UUID that later namespaces local favourites.
  final String id;

  final String email;

  /// When the account was created, if Supabase reported it.
  final DateTime? createdAt;

  /// Upper-cased first letter of the email; empty when the email is empty.
  String get initial {
    final trimmed = email.trim();
    return trimmed.isEmpty ? '' : trimmed[0].toUpperCase();
  }

  @override
  bool operator ==(Object other) =>
      other is AuthUser &&
      other.id == id &&
      other.email == email &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, email, createdAt);

  @override
  String toString() => 'AuthUser($id, $email)';
}
