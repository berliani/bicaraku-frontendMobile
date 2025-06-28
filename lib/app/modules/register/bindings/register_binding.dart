import 'package:bicaraku/app/data/repositories/auth_repository.dart';
import 'package:bicaraku/core/network/dio_client.dart';
import 'package:get/get.dart';
import '../controllers/register_controller.dart';

class RegisterBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RegisterController>(() => RegisterController());
    Get.lazyPut<AuthRepository>(() => AuthRepository());
    Get.lazyPut<DioClient>(() => DioClient());
  }
}
