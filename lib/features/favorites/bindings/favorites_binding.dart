import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/favorites_controller.dart';
import '../repositories/favorites_repository.dart';
import '../services/favorites_storage_service.dart';

class FavoritesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FavoritesStorageService>(
      () => FavoritesStorageService(preferences: SharedPreferencesAsync()),
    );
    Get.lazyPut<FavoritesRepository>(
      () => FavoritesRepository(storage: Get.find()),
    );
    // Eager on purpose: GetX ties a lazy instance to whichever route is
    // current at its first `find`, and Details may be the first to ask.
    // Putting it here pins it to Home for the app's life and starts the auth
    // subscription before the first frame.
    Get.put<FavoritesController>(
      FavoritesController(auth: Get.find(), repository: Get.find()),
    );
  }
}
