import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/history_activity_controller.dart';

class HistoryActivityView extends GetView<HistoryActivityController> {
  const HistoryActivityView({super.key});

  String formatTime(String timestamp) {
    final utcTime = DateTime.parse(timestamp);
    final wibTime = utcTime.add(const Duration(hours: 7));
    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(wibTime) + ' WIB';
  }

  void _confirmDeleteHistoryByType(String type) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 5),
            Flexible(
              child: Text("Riwayat Aktivitas", overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        content: Text(
          "Apakah Anda yakin ingin menghapus semua riwayat aktivitas $type? Tindakan ini tidak dapat dibatalkan.",
          style: const TextStyle(fontSize: 15),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              "Batal",
              style: TextStyle(color: Colors.blueGrey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deleteHistoryByType(type);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              "Hapus Riwayat",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Riwayat Aktivitas"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
            onPressed: () {
              if (controller.activityList.isNotEmpty) {
                final type = controller.activityList.first['type'];
                _confirmDeleteHistoryByType(type);
              } else {
                Get.snackbar("Kosong", "Tidak ada riwayat untuk dihapus.");
              }
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.activityList.isEmpty) {
          return const Center(child: Text("Tidak ada aktivitas ditemukan."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.activityList.length,
          itemBuilder: (context, index) {
            final item = controller.activityList[index];
            return Card(
              color: Colors.grey[100],
              child: ListTile(
                leading: const Icon(Icons.history),
                title: Text(item['type'].toUpperCase()),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item['detail'] != null)
                      Text("Detail: ${item['detail']}"),
                    Text("Waktu: ${formatTime(item['timestamp'])}"),
                    if (item['device_info'] != null)
                      Text(
                        "Perangkat: ${item['device_info'] ?? 'Perangkat tidak diketahui'}",
                      ),
                    if (item['logout_time'] != null)
                      Text("Logout: ${formatTime(item['logout_time'])}"),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
