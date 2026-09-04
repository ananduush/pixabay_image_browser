import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/config/env.dart';
import 'core/routes/app_pages.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/bindings/auth_binding.dart';
import 'features/auth/services/supabase_auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Every weight the app uses ships in assets/google_fonts; never fetch.
  GoogleFonts.config.allowRuntimeFetching = false;
  LicenseRegistry.addLicense(_fontLicenses);
  final authService = await SupabaseAuthService.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabasePublishableKey,
  );
  runApp(ApertureApp(authService: authService));
}

/// The bundled fonts are OFL 1.1; their notices belong on the licences page.
Stream<LicenseEntry> _fontLicenses() async* {
  for (final family in const <String>['InstrumentSans', 'Newsreader']) {
    yield LicenseEntryWithLineBreaks(<String>[
      family,
    ], await rootBundle.loadString('assets/google_fonts/OFL-$family.txt'));
  }
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
