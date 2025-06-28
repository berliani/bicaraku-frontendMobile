import 'dart:convert';
import 'dart:io';
import 'package:bicaraku/app/data/controllers/user_controller.dart';
import 'package:bicaraku/core/network/api_constant.dart';
import 'package:bicaraku/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:bicaraku/app/data/models/user_model.dart';

class ProfilController extends GetxController {
  final emailController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final obscurePassword = true.obs;
  final storage = GetStorage();
  final token = GetStorage().read('token');
  var isLoading = false.obs;
  var userData = <String, dynamic>{}.obs;
  var avatarPath = ''.obs;
  final ImagePicker picker = ImagePicker();
  final userController = Get.find<UserController>();

  @override
  void onInit() {
    super.onInit();
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    if (token == null) return;

    isLoading.value = true;
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.profil}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        userData.value = data['user'] ?? {};

        emailController.text = userData['email'] ?? '';
        usernameController.text = userData['name'] ?? '';
        final receivedPhotoUrl = userData['photoUrl'] ?? '';
        print(
          'DEBUG (Flutter): Photo URL received from API: $receivedPhotoUrl',
        );

        avatarPath.value = receivedPhotoUrl; // Update Obx variable
        userController.setUser(UserModel.fromJson(userData));
      } else if (response.statusCode == 401) {
        Get.snackbar("Error", "Sesi habis. Silakan login kembali");
        logout();
      } else {
        Get.snackbar("Error", "Gagal ambil profil: ${response.statusCode}");
      }
    } catch (e) {
      Get.snackbar("Error", "Terjadi error: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickImage() async {
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        avatarPath.value = pickedFile.path;
        await uploadAvatar(File(pickedFile.path));
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal memilih gambar: ${e.toString()}");
    }
  }

  Future<void> uploadAvatar(File imageFile) async {
    if (token == null) return;

    isLoading.value = true;
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}/api/profil/avatar'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        await http.MultipartFile.fromPath('avatar', imageFile.path),
      );

      var response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseBody);
        avatarPath.value = jsonResponse['photoUrl'];

        userController.updateUserInfo(photoUrl: jsonResponse['photoUrl']);
        update();

        Get.snackbar("Sukses", "Foto profil berhasil diubah");
      } else {
        final errorMsg = _parseErrorMessage(responseBody);
        Get.snackbar("Error", "Gagal upload avatar: $errorMsg");
      }
    } catch (e) {
      Get.snackbar("Error", "Upload gagal: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProfile() async {
    if (token == null) return;

    final data = {
      'name': usernameController.text,
      'email': emailController.text,
    };

    if (passwordController.text.isNotEmpty) {
      data['password'] = passwordController.text;
    }

    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.profil}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        Get.snackbar("Sukses", "Profil berhasil diperbarui");

        await fetchUserProfile();

        passwordController.clear();
      } else {
        final error =
            jsonDecode(response.body)['message'] ?? 'Error tidak diketahui';
        Get.snackbar("Error", "Gagal update profil: $error");
      }
    } catch (e) {
      Get.snackbar("Error", "Terjadi kesalahan: ${e.toString()}");
    }
  }

  Future<void> addHistory(String type) async {
    final token = storage.read('token') ?? '';
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/history-activity'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'type': type}),
      );

      if (response.statusCode == 201) {
        print("✅ Berhasil mencatat aktivitas: $type");
      } else {
        print(
          "⚠️ Gagal mencatat aktivitas: ${response.statusCode} ${response.body}",
        );
      }
    } catch (e) {
      print("❌ Error saat mencatat aktivitas: $e");
    }
  }

  Future<void> deleteAccount() async {
    if (token == null) return;

    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.deleteAccount}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        Get.snackbar("Berhasil", "Akun berhasil dihapus");
        storage.erase();
        Get.offAllNamed(Routes.LOGIN);
      } else {
        Get.snackbar("Error", "Gagal menghapus akun");
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
  }

  void logout() {
    storage.erase();
    Get.offAllNamed(Routes.LOGIN);
  }

  String _parseErrorMessage(String responseBody) {
    try {
      final json = jsonDecode(responseBody);
      return json['message'] ?? responseBody;
    } catch (_) {
      return responseBody;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
