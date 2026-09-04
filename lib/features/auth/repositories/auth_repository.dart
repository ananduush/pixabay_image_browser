import '../models/auth_user.dart';
import '../services/supabase_auth_service.dart';

class AuthRepository {
  AuthRepository({required this._service});

  final SupabaseAuthService _service;

  AuthUser? currentUser() => _service.currentUser();

  Stream<AuthUser?> userChanges() => _service.userChanges();

  Future<AuthUser> signIn({required String email, required String password}) =>
      _service.signIn(email: email, password: password);

  Future<AuthUser> signUp({required String email, required String password}) =>
      _service.signUp(email: email, password: password);

  Future<void> signOut() => _service.signOut();
}
