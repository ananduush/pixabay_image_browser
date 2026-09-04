import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';

import '../controllers/image_detail_controller.dart';
import '../services/image_download_service.dart';

/// ImageDetailController → ImageDownloadService → image cache + Photos.
class ImageDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ImageDownloadService>(
      () => ImageDownloadService(
        // the cache CachedNetworkImage already filled for this photo
        cache: CachedNetworkImageProvider.defaultCacheManager,
      ),
    );
    Get.lazyPut<ImageDetailController>(
      () => ImageDetailController(downloads: Get.find()),
    );
  }
}
