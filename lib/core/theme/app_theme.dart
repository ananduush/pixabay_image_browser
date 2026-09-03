import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.ink,
        brightness: Brightness.light,
        surface: AppColors.paper,
      ),
      scaffoldBackgroundColor: AppColors.paper,
      splashFactory: NoSplash.splashFactory,
      visualDensity: VisualDensity.standard,
    );
    return base.copyWith(
      textTheme: GoogleFonts.instrumentSansTextTheme(
        base.textTheme,
      ).apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
    );
  }
}
