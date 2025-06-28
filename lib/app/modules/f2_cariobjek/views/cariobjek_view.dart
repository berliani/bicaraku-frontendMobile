import 'package:bicaraku/app/data/controllers/user_controller.dart';
import 'package:bicaraku/app/routes/app_routes.dart';
import 'package:bicaraku/core/widgets/custom_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CariobjekView extends StatelessWidget {
  const CariobjekView({super.key});

  @override
  Widget build(BuildContext context) {
    final userController = Get.find<UserController>();

    // Tambahkan pengecekan ARGUMENTS di sini
    if (Get.arguments != null && Get.arguments['name'] != null) {
      userController.setUser(Get.arguments['name']);
    }
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Text(
                    'Tantangan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Grid of activity cards
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    buildActivityCard(
                      'assets/images/f2.cariobjek/1.png',
                      '"AYO TEMUKAN BOLA"',
                    ),
                    buildActivityCard(
                      'assets/images/f2.cariobjek/2.png',
                      '"AYO TEMUKAN BOTOL"',
                    ),
                    buildActivityCard(
                      'assets/images/f2.cariobjek/3.png',
                      '"AYO TEMUKAN KURSI"',
                    ),
                    buildActivityCard(
                      'assets/images/f2.cariobjek/5.png',
                      '"AYO TEMUKAN TEMPAT TIDUR"',
                    ),
                    buildActivityCard(
                      'assets/images/f2.cariobjek/6.png',
                      '"AYO TEMUKAN TAS"',
                    ),
                    buildActivityCard(
                      'assets/images/f2.cariobjek/4.png',
                      '"AYO TEMUKAN TELEVISI"',
                    ),
                    buildActivityCard(
                      'assets/images/f2.cariobjek/7.png',
                      '"AYO TEMUKAN LAPTOP"',
                    ),
                     buildActivityCard(
                      'assets/images/f2.cariobjek/8.png',
                      '"AYO TEMUKAN KEYBOARD"',
                    ),
                     buildActivityCard(
                      'assets/images/f2.cariobjek/9.png',
                      '"AYO TEMUKAN BONEKA"',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: const CustomBottomNav(),
    );
  }

  /// Builder function for square activity cards with instruction
  Widget buildActivityCard(String imageAsset, String instruksi) {
    return GestureDetector(
      onTap: () {
        // Navigasi ke kamera sambil kirim instruksi
        Get.toNamed(Routes.CARIOBJEKCAM, arguments: instruksi);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey[200],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(imageAsset, fit: BoxFit.cover),
        ),
      ),
    );
  }
}
