import 'package:get/get.dart';

import '../../features/gallery/bindings/gallery_binding.dart';
import '../../features/gallery/views/gallery_view.dart';

abstract final class AppRoutes {
  static const String gallery = '/gallery';
}

abstract final class AppPages {
  static final List<GetPage<dynamic>> pages = <GetPage<dynamic>>[
    GetPage<dynamic>(
      name: AppRoutes.gallery,
      page: () => const GalleryView(),
      binding: GalleryBinding(),
    ),
  ];
}
