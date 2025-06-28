import 'dart:convert';
import 'package:bicaraku/app/routes/app_routes.dart';
import 'package:bicaraku/core/network/api_constant.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class CreatePasswordController extends GetxController {
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  final isLoading = false.obs;
  final obscurePassword = true.obs;
  final obscureConfirmPassword = true.obs;

  late String email;

  @override
  void onInit() {
    super.onInit();
    email = Get.arguments['email'] ?? '';
    debugPrint("Email from arguments: $email");
  }

  @override
  void onClose() {
    passwordController.dispose();
    confirmController.dispose();
    super.onClose();
  }

  Future<void> createPassword() async {
    final password = passwordController.text.trim();
    final confirmPassword =
        confirmController.text.trim(); // ✅ fix typo sebelumnya

    if (password.isEmpty || confirmPassword.isEmpty) {
      Get.snackbar("Error", "Semua field harus diisi");
      return;
    }

    if (password != confirmPassword) {
      Get.snackbar("Error", "Password tidak cocok");
      return;
    }

    isLoading.value = true;
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/create-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'new_password': password}),
      );

      // ✅ Tambahkan pengecekan content-type agar aman sebelum decode JSON
      if (response.headers['content-type']?.contains('application/json') ??
          false) {
        final data = jsonDecode(response.body);

        if (response.statusCode == 200) {
          Get.snackbar("Sukses", data['message']);
          Get.offAllNamed(Routes.LOGIN);
        } else {
          Get.snackbar("Gagal", data['message']);
        }
      } else {
        // 🔴 Server membalas HTML atau format lain
        debugPrint("Non-JSON response: ${response.body}");
        Get.snackbar("Error", "Respons dari server tidak sesuai format JSON");
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal membuat password");
      debugPrint("Create password error: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
