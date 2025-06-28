import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:bicaraku/core/network/api_constant.dart';

class HistoryActivityController extends GetxController {
  var isLoading = true.obs;
  var activityList = <Map<String, dynamic>>[].obs;
  final storage = GetStorage();

  @override
  void onInit() {
    final args = Get.arguments;
    final type = args?['type'];
    fetchActivity(type);
    super.onInit();
  }

  Future<String> getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        final device = "${info.manufacturer} ${info.model}";
        print("🟢 DEVICE ANDROID: $device");
        return device;
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        final device = "${info.name} ${info.model}";
        print("🟢 DEVICE IOS: $device");
        return device;
      } else {
        print("🔴 PLATFORM UNKNOWN");
        return "Unknown Device";
      }
    } catch (e) {
      print("❌ ERROR GETTING DEVICE INFO: $e");
      return "Unknown Device";
    }
  }

  Future<void> login(String email, String password) async {
    try {
      final deviceInfo = await getDeviceInfo();
      print("📲 DEVICE INFO TERBACA: $deviceInfo");

      final jsonBody = jsonEncode({
        'email': email,
        'password': password,
        'device_info': deviceInfo,
      });

      print("📤 JSON YANG DIKIRIM KE SERVER: $jsonBody");

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonBody,
      );

      final jsonResponse = json.decode(response.body);

      if (response.statusCode == 200) {
        final token = jsonResponse['token'];
        storage.write('token', token);

        Get.snackbar('Berhasil', 'Login sukses');
        fetchActivity(null);
      } else {
        Get.snackbar('Gagal', jsonResponse['message'] ?? 'Login gagal');
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal login: $e');
    }
  }

  Future<void> fetchActivity(String? type) async {
    try {
      isLoading(true);
      final token = storage.read('token');

      final uri =
          type != null
              ? Uri.parse(
                '${ApiConstants.baseUrl}/api/history-activity?type=$type',
              )
              : Uri.parse('${ApiConstants.baseUrl}/api/history-activity');

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        activityList.value = List<Map<String, dynamic>>.from(jsonData['data']);
      } else {
        Get.snackbar("Gagal", "Tidak bisa mengambil data aktivitas");
      }
    } catch (e) {
      Get.snackbar("Error", "Terjadi kesalahan: $e");
    } finally {
      isLoading(false);
    }
  }

  Future<void> deleteHistoryByType(String type) async {
    final token = storage.read('token');
    if (token == null) return;

    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/api/history-activity'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'type': type}),
      );

      if (response.statusCode == 200) {
        activityList.removeWhere((item) => item['type'] == type);
        Get.snackbar("Berhasil", "Semua riwayat $type berhasil dihapus");
      } else {
        Get.snackbar("Error", "Gagal menghapus riwayat: ${response.body}");
      }
    } catch (e) {
      Get.snackbar("Error", "Terjadi kesalahan: $e");
    }
  }
}
