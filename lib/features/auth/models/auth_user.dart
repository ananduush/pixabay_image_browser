final class AuthUser {
  const AuthUser({required this.id, required this.email, this.createdAt});

  final String id;

  final String email;

  final DateTime? createdAt;

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
