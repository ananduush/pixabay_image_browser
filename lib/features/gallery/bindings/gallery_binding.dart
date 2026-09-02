import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../../core/config/env.dart';
import '../controllers/gallery_controller.dart';
import '../repositories/gallery_repository.dart';
import '../services/pixabay_service.dart';

/// GalleryController → GalleryRepository → PixabayService → Dio.
class GalleryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<Dio>(PixabayService.createDio);
    Get.lazyPut<PixabayService>(
      () => PixabayService(dio: Get.find(), apiKey: Env.pixabayApiKey),
    );
    Get.lazyPut<GalleryRepository>(
      () => GalleryRepository(service: Get.find()),
    );
    Get.lazyPut<GalleryController>(
      () => GalleryController(repository: Get.find()),
    );
  }
}
