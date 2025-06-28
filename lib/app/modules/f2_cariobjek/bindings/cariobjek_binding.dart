import 'package:bicaraku/app/data/controllers/user_controller.dart';
import 'package:get/get.dart';
import '../controllers/cariobjek_controller.dart';

class CariobjekBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CariObjekController>(() => CariObjekController());
    Get.lazyPut<UserController>(() => UserController());
  }
}
