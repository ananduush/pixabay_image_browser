import '../models/auth_user.dart';
import '../services/supabase_auth_service.dart';

/// Application-level auth API. Thin today; the boundary is what matters
/// (the controller never sees Supabase).
class AuthRepository {
  AuthRepository({required this._service});

  final SupabaseAuthService _service;

  /// Restored/current user, or `null` for a guest.
  /// Throws `AuthMissingConfigException` when Supabase is not configured.
  AuthUser? currentUser() => _service.currentUser();

  /// The session user after every auth event; `null` means signed out.
  Stream<AuthUser?> userChanges() => _service.userChanges();

  Future<AuthUser> signIn({required String email, required String password}) =>
      _service.signIn(email: email, password: password);

  Future<AuthUser> signUp({required String email, required String password}) =>
      _service.signUp(email: email, password: password);

  Future<void> signOut() => _service.signOut();
}
