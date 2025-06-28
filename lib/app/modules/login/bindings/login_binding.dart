import 'package:bicaraku/app/data/controllers/user_controller.dart';
import 'package:bicaraku/app/data/repositories/auth_repository.dart';
import 'package:bicaraku/core/network/dio_client.dart';
import 'package:get/get.dart';
import '../controllers/login_controller.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoginController>(() => LoginController());
    Get.lazyPut<UserController>(() => UserController());
    Get.lazyPut<DioClient>(() => DioClient());
    Get.lazyPut<AuthRepository>(() => AuthRepository());
    Get.lazyPut<AuthRepository>(() => AuthRepository());
  }
}
