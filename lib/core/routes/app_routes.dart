/// Route names. The page table lives in `app_pages.dart` so views can import
/// these constants without a routes ↔ views import cycle.
abstract final class AppRoutes {
  static const String home = '/';

  static const String auth = '/auth';

  static const String imageDetail = '/gallery/image';
  static const String imageViewer = '/gallery/image/view';
}
