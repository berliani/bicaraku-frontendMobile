import 'package:get/get.dart';

import '../controllers/history_activity_controller.dart';

class HistoryActivityBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HistoryActivityController>(
      () => HistoryActivityController(),
    );
  }
}
