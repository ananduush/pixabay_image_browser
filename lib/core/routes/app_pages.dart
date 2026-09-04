import 'package:get/get.dart';

import '../../features/auth/bindings/auth_form_binding.dart';
import '../../features/auth/views/auth_view.dart';
import '../../features/gallery/bindings/image_detail_binding.dart';
import '../../features/gallery/models/pixabay_image.dart';
import '../../features/home/bindings/home_binding.dart';
import '../../features/home/views/home_view.dart';
import '../../features/gallery/views/image_detail_view.dart';
import '../../features/gallery/views/image_viewer_view.dart';
import 'app_routes.dart';

abstract final class AppPages {
  static final List<GetPage<dynamic>> pages = <GetPage<dynamic>>[
    GetPage<dynamic>(
      name: AppRoutes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.auth,
      page: () => const AuthView(),
      binding: AuthFormBinding(),
    ),
    // Details and the viewer render the PixabayImage they are given; the
    // Details binding only exists for the download.
    GetPage<dynamic>(
      name: AppRoutes.imageDetail,
      binding: ImageDetailBinding(),
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
