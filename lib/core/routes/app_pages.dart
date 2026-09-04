import 'package:get/get.dart';

import '../../features/gallery/bindings/gallery_binding.dart';
import '../../features/gallery/models/pixabay_image.dart';
import '../../features/gallery/views/gallery_view.dart';
import '../../features/gallery/views/image_detail_view.dart';
import '../../features/gallery/views/image_viewer_view.dart';
import 'app_routes.dart';

abstract final class AppPages {
  static final List<GetPage<dynamic>> pages = <GetPage<dynamic>>[
    GetPage<dynamic>(
      name: AppRoutes.gallery,
      page: () => const GalleryView(),
      binding: GalleryBinding(),
    ),
    // Details and the viewer render the PixabayImage they are given; neither
    // needs a controller, so neither has a binding.
    GetPage<dynamic>(
      name: AppRoutes.imageDetail,
      page: () {
        final Object? args = Get.arguments;
        return args is PixabayImage
            ? ImageDetailView(image: args)
            : const ImageDetailMissingView();
      },
    ),
    GetPage<dynamic>(
      name: AppRoutes.imageViewer,
      // fades so the ink backdrop appears under the hero flight
      transition: Transition.fadeIn,
      page: () {
        final Object? args = Get.arguments;
        return args is PixabayImage
            ? ImageViewerView(image: args)
            : const ImageDetailMissingView();
      },
    ),
  ];
}
