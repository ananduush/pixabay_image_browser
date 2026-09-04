import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../repositories/auth_repository.dart';
import '../services/supabase_auth_service.dart';

class AuthBinding extends Bindings {
  AuthBinding({this.service});

  final SupabaseAuthService? service;

  @override
  void dependencies() {
    Get.lazyPut<SupabaseAuthService>(
      () => service ?? const SupabaseAuthService.unconfigured(),
    );
    Get.lazyPut<AuthRepository>(() => AuthRepository(service: Get.find()));
    Get.put<AuthController>(
      AuthController(repository: Get.find()),
      permanent: true,
    );
  }
}
