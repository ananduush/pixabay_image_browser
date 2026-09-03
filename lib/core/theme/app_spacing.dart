/// Geometry from the Aperture design: gutter 22, grid gap 7, spacing steps
/// 4 · 8 · 14 · 22 · 26 · 34, image radius 2, chip radius 16.
abstract final class AppSpacing {
  static const double gutter = 22;
  static const double gridGap = 7;

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 14;
  static const double lg = 22;
  static const double xl = 26;
  static const double xxl = 34;
}

abstract final class AppRadius {
  static const double image = 2;
  static const double chip = 16;
}
