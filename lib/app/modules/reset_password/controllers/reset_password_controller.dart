import 'dart:convert';
import 'package:bicaraku/app/routes/app_routes.dart';
import 'package:bicaraku/core/network/api_constant.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class ResetPasswordController extends GetxController {
  final emailController = TextEditingController();
  final isLoading = false.obs;

  Future<void> sendResetCode() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      Get.snackbar("Error", "Email tidak boleh kosong");
      return;
    }

    isLoading.value = true;
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        Get.toNamed(Routes.VERIFY_CODE, arguments: {'email': email});
      } else {
        Get.snackbar("Gagal", data['message']);
      }
    } catch (e) {
      Get.snackbar("Error", "Terjadi kesalahan saat mengirim kode");
    } finally {
      isLoading.value = false;
    }
  }
}
