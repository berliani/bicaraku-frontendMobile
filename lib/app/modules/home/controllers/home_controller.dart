import 'package:bicaraku/app/data/controllers/user_controller.dart';
import 'package:bicaraku/app/routes/app_routes.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {
  final UserController userController = Get.put(UserController());

  @override
  void onReady() {
    super.onReady();
    // Verify user is logged in
    if (userController.user == null) {
      Get.offAllNamed(Routes.LOGIN);
    }
  }
}