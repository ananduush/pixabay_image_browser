import 'package:get/get.dart';

import '../controllers/auth_form_controller.dart';

class AuthFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthFormController>(() => AuthFormController(auth: Get.find()));
  }
}
