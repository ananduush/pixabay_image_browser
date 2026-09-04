import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Type scale from the Aperture design.
/// Newsreader carries titles and captions, Instrument Sans everything else.
///
/// Only Instrument Sans Regular/Medium and Newsreader Regular are bundled
/// (assets/google_fonts) and runtime fetching is off, so a new weight or an
/// italic needs its static file added there or it falls back to the
/// platform font.
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

  /// search cancel — Instrument Sans 14.
  static TextStyle get cancel => sans(14);

  /// searching caption — Instrument Sans 12.5.
  static TextStyle get searchStatus => sans(12.5, color: AppColors.text62);

  /// result count — Newsreader 18.
  static TextStyle get resultCount => serif(18);

  /// result query — Instrument Sans 12.
  static TextStyle get resultQuery => sans(12, color: AppColors.text56);

  /// suggestion pill — Instrument Sans 13.
  static TextStyle get suggestion => sans(13);

  /// text link — Instrument Sans 13.5.
  static TextStyle get link => sans(13.5, color: AppColors.text62);

  /// feed footer caption ("PAGE 3", "END OF RESULTS") — Instrument Sans 11, +.06em, uppercase.
  static TextStyle get feedStatus => label(11);

  /// refresh pill — Instrument Sans 12 medium.
  static TextStyle get refreshStatus => sans(12, weight: FontWeight.w500);

  /// pull hint — Instrument Sans 12, 62% ink.
  static TextStyle get refreshHint => sans(12, color: AppColors.text62);

  // Named roles used by Image Details.

  /// Detail title — Newsreader 29, line-height 1.15, -.015em.
  static TextStyle get detailTitle =>
      serif(29, height: 1.15, letterSpacing: -0.435);

  /// Detail creator line / failed-hero title — Instrument Sans 13, 62% ink.
  static TextStyle get detailMeta => sans(13, color: AppColors.text62);

  /// Failed-hero hint — Instrument Sans 12, 56% ink.
  static TextStyle get detailHint => sans(12, color: AppColors.text56);

  /// Metric value — Newsreader 19.
  static TextStyle get metric => serif(19);

  /// Metric label — Instrument Sans 10, +.07em, uppercase.
  static TextStyle get metricLabel => label(10, tracking: 0.07);

  /// Tag chip — Instrument Sans 12.5.
  static TextStyle get tag => sans(12.5);

  /// Floating action label — Instrument Sans 15 medium.
  static TextStyle get actionLabel => sans(15, weight: FontWeight.w500);

  /// Avatar fallback initial — Newsreader 12.
  static TextStyle get avatarInitial => serif(12);

  static TextStyle get screenTitle =>
      serif(32, height: 1.15, letterSpacing: -0.48);

  static TextStyle get sectionTitle => serif(25);

  static TextStyle get profileHeading => serif(27, height: 1.2);

  static TextStyle get lead => sans(14, color: AppColors.text62, height: 1.65);

  static TextStyle get fieldLabel => label(10.5, tracking: 0.08);

  static TextStyle get input => sans(17);

  static TextStyle get fieldHint => sans(12, color: AppColors.text56);

  static TextStyle get formError => sans(13, color: AppColors.critical);

  static TextStyle get filledButton =>
      sans(15, color: AppColors.paper, weight: FontWeight.w500);

  static TextStyle get filledButtonDisabled =>
      sans(15, color: AppColors.text32, weight: FontWeight.w500);

  static TextStyle get profileName => serif(20);

  static TextStyle get profileMeta => sans(13, color: AppColors.text62);

  static TextStyle get rowKey => sans(14, color: AppColors.text55);

  static TextStyle get rowValue => sans(14);

  static TextStyle get sheetTitle => serif(24, height: 1.2);

  static TextStyle get sheetBody =>
      sans(13.5, color: AppColors.text55, height: 1.6);

  static TextStyle get sheetDismiss => sans(14, color: AppColors.text62);

  static TextStyle get avatarInitialLarge => serif(20);

  // Named roles used by Favourites.

  /// Inline error title — Instrument Sans 14 medium, critical.
  static TextStyle get errorTitle =>
      sans(14, color: AppColors.critical, weight: FontWeight.w500);

  /// Inline error body — Instrument Sans 13, 62% ink, line-height 1.6.
  static TextStyle get errorBody =>
      sans(13, color: AppColors.text62, height: 1.6);

  /// Toast message — Instrument Sans 13 medium on ink.
  static TextStyle get toast =>
      sans(13, color: AppColors.paper, weight: FontWeight.w500);

  /// Centred footnote — Instrument Sans 12, 56% ink, line-height 1.6.
  static TextStyle get footnote =>
      sans(12, color: AppColors.text56, height: 1.6);
}
