/// Route names. The page table lives in `app_pages.dart` so views can import
/// these constants without a routes ↔ views import cycle.
abstract final class AppRoutes {
  /// The tabbed shell (Explore, Profile); Explore is the default tab.
  static const String home = '/';

  /// Sign in / create account, pushed over whatever needed it.
  static const String auth = '/auth';

  static const String imageDetail = '/gallery/image';
  static const String imageViewer = '/gallery/image/view';
}
