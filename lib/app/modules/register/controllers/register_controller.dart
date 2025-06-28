import 'package:bicaraku/app/data/repositories/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bicaraku/app/routes/app_routes.dart';

class RegisterController extends GetxController {
  // Deklarasi controller untuk text field
  final emailController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  final AuthRepository _authRepo = Get.find();

  var obscurePassword = true.obs;

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  Future<void> register() async {
    try {
      // Panggil repository dengan parameter yang benar
      await _authRepo.register(
        usernameController.text, // name
        emailController.text, // email
        passwordController.text, // password
      );

      Get.offAllNamed(Routes.LOGIN);
      Get.snackbar("Berhasil", "Akun berhasil didaftarkan");
    } catch (e) {
      Get.snackbar(
        "Error",
        e.toString().replaceAll('Exception:', '').trim(),
        duration: const Duration(seconds: 3),
      );
    }
  }

  @override
  void onClose() {
    // Dispose semua controller
    emailController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
