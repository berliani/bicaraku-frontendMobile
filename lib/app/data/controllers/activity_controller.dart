import 'package:bicaraku/app/data/controllers/total_points_controller.dart';
import 'package:bicaraku/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bicaraku/app/data/models/activity_history.dart';
import 'package:bicaraku/core/network/api_constant.dart';
import 'package:bicaraku/core/network/dio_client.dart';

class ActivityController extends GetxController {
  final RxList<ActivityHistory> histories = <ActivityHistory>[].obs;
  final RxBool isLoading = false.obs;
  final DioClient _dioClient = Get.put(DioClient());

  @override
  void onInit() {
    super.onInit();
    loadHistories();
  }

  Future<void> loadHistories() async {
    try {
      isLoading.value = true;
      final response = await _dioClient.get(ApiConstants.activities);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        histories.assignAll(
          data.map((json) => ActivityHistory.fromJson(json)).toList(),
        );
      }
    } catch (e) {
      print("Error loading histories: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addHistory(ActivityHistory newHistory) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.activities,
        data: newHistory.toJson(),
      );

      if (response.statusCode == 201) {
        // Reload data setelah menambah aktivitas baru
        await loadHistories();
 if (Get.isRegistered<TotalPointsController>()) {
        Get.find<TotalPointsController>().loadTotalPoints();
      } else {
        Get.put(TotalPointsController()).loadTotalPoints();
      }

      Get.snackbar("Berhasil", "Aktivitas berhasil ditambahkan!");
    }
  } catch (e) {
    print("Error adding history: $e");
    Get.snackbar("Error", "Gagal menambahkan riwayat aktivitas: $e");
  }
  }

  Future<void> removeHistory(String id) async {
    try {
      final response = await _dioClient.delete(
        '${ApiConstants.activities}/$id',
      );

      if (response.statusCode == 200) {
        // Remove locally first for immediate UI update
        histories.removeWhere((item) => item.id == id);
        Get.snackbar("Berhasil", "Aktivitas berhasil dihapus.");
      } else {
        Get.snackbar("Error", "Gagal menghapus aktivitas.");
      }
    } catch (e) {
      print("Error removing history: $e");
      Get.snackbar("Error", "Terjadi kesalahan saat menghapus aktivitas.");
    }
  }

  Future<void> clearAllHistories() async {
    try {
      // Tampilkan dialog konfirmasi terlebih dahulu
      final confirm = await Get.dialog(
        AlertDialog(
          title: const Text("Hapus Semua Riwayat"),
          content: const Text(
            "Apakah Anda yakin ingin menghapus semua riwayat aktivitas?",
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text("Batal"),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text("Hapus", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      // Hentikan jika user tidak konfirmasi
      if (confirm != true) return;

      // Cek apakah pemanggilan berasal dari halaman HISTORY
      if (Get.currentRoute != Routes.HISTORY) {
        print("Pencegahan: clearAllHistories dipanggil dari luar HistoryView");
        Get.snackbar("Gagal", "Aksi ini hanya diizinkan dari halaman Riwayat");
        return;
      }

      // Hapus data jika sudah konfirmasi dan rute valid
      final response = await _dioClient.delete(ApiConstants.activities);
      if (response.statusCode == 200) {
        histories.clear();
        Get.snackbar("Berhasil", "Semua riwayat aktivitas telah dihapus");
      } else {
        Get.snackbar("Error", "Gagal menghapus riwayat aktivitas");
      }
    } catch (e) {
      print("Error clearing histories: $e");
      Get.snackbar("Error", "Terjadi kesalahan saat menghapus riwayat");
    }
  }
}
