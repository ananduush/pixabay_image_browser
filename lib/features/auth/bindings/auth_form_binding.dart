import 'package:get/get.dart';

import '../controllers/auth_form_controller.dart';

/// Auth route scope: the form dies with the screen, the session does not.
class AuthFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthFormController>(() => AuthFormController(auth: Get.find()));
  }
}
