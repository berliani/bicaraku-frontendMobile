import 'dart:convert';
import 'package:bicaraku/app/routes/app_routes.dart';
import 'package:bicaraku/core/network/api_constant.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class VerifyCodeController extends GetxController {
  final codeController = TextEditingController();
  final isLoading = false.obs;
  String email = '';

  @override
  void onInit() {
    super.onInit();
    email = Get.arguments['email'] ?? '';
  }

  Future<void> verifyCode() async {
    final code = codeController.text.trim();
    if (code.isEmpty || code.length != 6) {
      Get.snackbar("Error", "Kode verifikasi harus 6 digit");
      return;
    }

    isLoading.value = true;
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}/api/reset-password?email=$email&code=$code',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final message = data['message'] ?? 'Kode berhasil diverifikasi';

        // Cukup kirim email via arguments
        Get.offNamed(Routes.CREATE_PASSWORD, arguments: {'email': email});

        Future.delayed(const Duration(milliseconds: 500), () {
          Get.snackbar("Sukses", message);
        });
      } else {
        final data = jsonDecode(response.body);
        Get.snackbar("Gagal", data['message'] ?? 'Verifikasi gagal');
      }
    } catch (e) {
      debugPrint('verifyCode error: $e');
      Get.snackbar("Error", "Terjadi kesalahan saat verifikasi kode");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resendCode() async {
    if (email.isEmpty) {
      Get.snackbar("Error", "Email tidak tersedia");
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
        Get.snackbar("Berhasil", data['message']);
      } else {
        Get.snackbar("Gagal", data['message']);
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal mengirim ulang kode");
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    codeController.dispose();
    super.onClose();
  }
}
