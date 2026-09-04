import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../repositories/auth_repository.dart';
import '../services/supabase_auth_service.dart';

/// App-scoped: AuthController → AuthRepository → SupabaseAuthService.
/// Runs as the `initialBinding`, before any route, so the app knows whether
/// a session exists without the sign-in screen ever opening.
class AuthBinding extends Bindings {
  AuthBinding({this.service});

  /// The service built in `main` (null in tests, or when Supabase is not
  /// configured: every auth call then reports the missing configuration).
  final SupabaseAuthService? service;

  @override
  void dependencies() {
    Get.lazyPut<SupabaseAuthService>(
      () => service ?? const SupabaseAuthService.unconfigured(),
    );
    Get.lazyPut<AuthRepository>(() => AuthRepository(service: Get.find()));
    // Built now and kept for the app's lifetime.
    Get.put<AuthController>(
      AuthController(repository: Get.find()),
      permanent: true,
    );
  }
}
