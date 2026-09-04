import 'package:get/get.dart';

import '../../favorites/bindings/favorites_binding.dart';
import '../../gallery/bindings/gallery_binding.dart';
import '../controllers/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    GalleryBinding().dependencies();
    FavoritesBinding().dependencies();
    Get.lazyPut<HomeController>(
      () => HomeController(auth: Get.find(), gallery: Get.find()),
    );
  }
}
