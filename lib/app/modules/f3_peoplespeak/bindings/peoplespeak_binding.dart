import 'package:bicaraku/app/data/controllers/user_controller.dart';
import 'package:bicaraku/app/modules/f3_peoplespeak/controllers/peoplespeak_controller.dart';
import 'package:get/get.dart';

class BerbicaraBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BerbicaraController>(() => BerbicaraController());
    Get.lazyPut<UserController>(() => UserController());
  }
}
