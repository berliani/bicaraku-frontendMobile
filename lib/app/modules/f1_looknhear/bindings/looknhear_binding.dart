import 'package:bicaraku/app/data/controllers/user_controller.dart';
import 'package:bicaraku/app/modules/f1_looknhear/controllers/looknhear_controller.dart';
import 'package:bicaraku/core/network/dio_client.dart';
import 'package:get/get.dart';


class CariobjekBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LooknhearController>(() => LooknhearController());
    Get.lazyPut<UserController>(() => UserController());
    Get.lazyPut<DioClient>(() => DioClient());
  }
}
