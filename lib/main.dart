import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'core/config/env.dart';
import 'core/routes/app_pages.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/bindings/auth_binding.dart';
import 'features/auth/services/supabase_auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authService = await SupabaseAuthService.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabasePublishableKey,
  );
  runApp(ApertureApp(authService: authService));
}

class ApertureApp extends StatelessWidget {
  const ApertureApp({super.key, this.authService});

  final SupabaseAuthService? authService;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Aperture',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialBinding: AuthBinding(service: authService),
      initialRoute: AppRoutes.home,
      getPages: AppPages.pages,
    );
  }
}
