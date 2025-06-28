import 'package:get/get.dart';

import '../controllers/scraping_controller.dart';

class ScrapingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ScrapingController>(
      () => ScrapingController(),
    );
  }
}
