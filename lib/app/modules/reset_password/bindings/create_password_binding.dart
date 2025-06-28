import 'package:bicaraku/app/modules/reset_password/controllers/create_password_controller.dart';
import 'package:get/get.dart';

class CreatePasswordBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CreatePasswordController>(() => CreatePasswordController());
  }
}
