import 'package:get/get.dart';
import 'package:bicaraku/core/network/api_constant.dart';
import 'package:bicaraku/core/network/dio_client.dart';

class TotalPointsController extends GetxController {
  final DioClient _dioClient = Get.find<DioClient>();
  final RxInt totalPoints = 0.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadTotalPoints();
  }

  Future<void> loadTotalPoints() async {
    try {
      isLoading.value = true;
      final response = await _dioClient.get(ApiConstants.totalPoints);
      if (response.statusCode == 200) {
        totalPoints.value = response.data['total_points'] ?? 0;
      }
    } catch (e) {
      print("Error loading total points: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void updatePoints(int points) {
    totalPoints.value += points;
  }
}