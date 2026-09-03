import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Type scale from the Aperture design.
/// Newsreader carries titles and captions, Instrument Sans everything else.
abstract final class AppTypography {
  static TextStyle serif(
    double size, {
    Color color = AppColors.ink,
    double? height,
    double letterSpacing = 0,
  }) {
    return GoogleFonts.newsreader(
      fontSize: size,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontWeight: FontWeight.w400,
    );
  }

  static TextStyle sans(
    double size, {
    Color color = AppColors.ink,
    FontWeight weight = FontWeight.w400,
    double? height,
    double letterSpacing = 0,
  }) {
    return GoogleFonts.instrumentSans(
      fontSize: size,
      color: color,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Uppercase label: Instrument Sans with tracking expressed in em.
  static TextStyle label(
    double size, {
    Color color = AppColors.text56,
    double tracking = 0.06,
  }) {
    return sans(size, color: color, letterSpacing: size * tracking);
  }

  static TextStyle mono(double size, {Color color = AppColors.text56}) {
    return TextStyle(
      fontFamily: 'Menlo',
      fontFamilyFallback: const <String>['Courier', 'monospace'],
      fontSize: size,
      color: color,
    );
  }

  // Named roles used by the Gallery screen.

  /// "Aperture" wordmark — Newsreader 25, -.01em.
  static TextStyle get brand => serif(25, letterSpacing: -0.25);

  /// Full-screen state title — Newsreader 23.
  static TextStyle get stateTitle => serif(23);

  /// Hero caption title — Newsreader 16.
  static TextStyle get captionTitle => serif(16);

  /// Body / input — Instrument Sans 15.
  static TextStyle get body => sans(15);

  /// Pill button label — Instrument Sans 14.5 medium.
  static TextStyle get button => sans(14.5, weight: FontWeight.w500);

  /// State body copy — Instrument Sans 13.5, line-height 1.6.
  static TextStyle get stateBody =>
      sans(13.5, color: AppColors.text62, height: 1.6);

  /// Category chip — Instrument Sans 12.5.
  static TextStyle chip({bool active = false}) =>
      sans(12.5, color: active ? AppColors.ink : AppColors.text56);

  /// Tile fallback caption — Instrument Sans 11.5.
  static TextStyle get tileFallback => sans(11.5, color: AppColors.text56);

  /// Hero caption creator — Instrument Sans 11.
  static TextStyle get captionMeta => sans(11, color: AppColors.text56);

  /// Header trailing label — Instrument Sans 10.5, +.06em, uppercase.
  static TextStyle get headerLabel => label(10.5);

  // Roles added by the Search slice.

  /// Search "Cancel" — Instrument Sans 14.
  static TextStyle get cancel => sans(14);

  /// "Searching Pixabay for …" caption — Instrument Sans 12.5.
  static TextStyle get searchStatus => sans(12.5, color: AppColors.text62);

  /// Results header count — Newsreader 18.
  static TextStyle get resultCount => serif(18);

  /// Results header "for “…”" — Instrument Sans 12.
  static TextStyle get resultQuery => sans(12, color: AppColors.text56);

  /// Suggestion pill — Instrument Sans 13.
  static TextStyle get suggestion => sans(13);

  /// Empty-state text link ("Back to browsing") — Instrument Sans 13.5.
  static TextStyle get link => sans(13.5, color: AppColors.text62);
}
