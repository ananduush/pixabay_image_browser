import 'package:get/get.dart';

import '../../gallery/bindings/gallery_binding.dart';
import '../controllers/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    GalleryBinding().dependencies();
    Get.lazyPut<HomeController>(
      () => HomeController(auth: Get.find(), gallery: Get.find()),
    );
  }
}
