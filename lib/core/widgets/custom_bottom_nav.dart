import 'package:bicaraku/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomBottomNav extends StatelessWidget {
  const CustomBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final currentIndex = 0.obs; // Sesuaikan index sesuai halaman

    return Obx(
      () => BottomNavigationBar(
        currentIndex: currentIndex.value,
        backgroundColor: const Color(0xFFFFBF8C),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(
            icon: Icon(Icons.visibility),
            label: 'Melihat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.travel_explore),
            label: 'Temukan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.record_voice_over),
            label: 'Berbicara',
          ),
        ],
        onTap: (index) {
          currentIndex.value = index;
          switch (index) {
            case 0:
              Get.toNamed(Routes.HOME);
              break;
            case 1:
              Get.toNamed(Routes.LOOKNHEAR);
              break;
            case 2:
              Get.toNamed(Routes.CARIOBJEK);
              break;
            case 3:
              Get.toNamed(Routes.PEOPLESPEAK);
              break;
          }
        },
      ),
    );
  }
}
