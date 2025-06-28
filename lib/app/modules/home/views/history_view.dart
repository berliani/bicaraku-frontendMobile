import 'package:bicaraku/app/data/controllers/activity_controller.dart';
import 'package:bicaraku/app/data/models/activity_history.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'package:intl/date_symbol_data_local.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  final ActivityController controller = Get.find<ActivityController>();

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Aktivitas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        actions: [
          Obx(() {
            if (controller.histories.isNotEmpty) {
              return IconButton(
                icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                tooltip: "Hapus Semua Riwayat",
                onPressed: () => _showClearHistoryDialog(context, controller),
              );
            } else {
              return const SizedBox.shrink();
            }
          }),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.histories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/emptyhistory.png', width: 120),
                const SizedBox(height: 20),
                const Text(
                  'Belum ada riwayat aktivitas',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final sortedHistories = [...controller.histories];
        sortedHistories.sort((a, b) => b.date.compareTo(a.date));

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: sortedHistories.length,
          itemBuilder: (context, index) {
            final history = sortedHistories[index];
            return Dismissible(
              key: Key(history.id), // Unique key for Dismissible
              direction:
                  DismissDirection.endToStart, // Swipe from right to left
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (direction) async {
                return await _showDeleteConfirmationDialog(context, history);
              },
              onDismissed: (direction) {
                // This is called after confirmDismiss returns true
                controller.removeHistory(history.id);
              },
              child: _buildHistoryCard(history),
            );
          },
        );
      }),
    );
  }

  Widget _buildHistoryCard(ActivityHistory history) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
            child: Image.asset(
              history.image,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        history.isCompleted
                            ? Icons.check_circle
                            : Icons.access_time,
                        color:
                            history.isCompleted ? Colors.green : Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          history.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(history.date),
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  if (history.points > 0)
                    Text(
                      "+${history.points} Poin",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final formatter = intl.DateFormat('EEEE, d MMMM y', 'id_ID');
    return '${formatter.format(date)} • ${intl.DateFormat.Hm().format(date)}';
  }

  void _showClearHistoryDialog(
    BuildContext context,
    ActivityController controller,
  ) {
    // The dialog is now handled directly by the controller's clearAllHistories()
    // It already uses Get.dialog, so no need for showDialog here directly.
    controller.clearAllHistories();
  }

  Future<bool?> _showDeleteConfirmationDialog(
    BuildContext context,
    ActivityHistory history,
  ) async {
    return await Get.dialog<bool>(
      AlertDialog(
        title: const Text("Hapus Aktivitas"),
        content: Text(
          "Apakah Anda yakin ingin menghapus aktivitas '${history.title}'?",
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
  }
}
