import 'package:bicaraku/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Splash2View extends StatelessWidget {
  const Splash2View({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/splashscreen/splash2.png',
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Kenali benda, dengarkan suaranya, dan ucapkan bersama!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Bantu Si Kecil Berbicara Lebih Lancar dengan Cara Interaktif!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Get.offNamed(Routes.LOGIN),
                    child: const Text(
                      'Lewati',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                  Row(
                    children: const [
                      Icon(Icons.circle, size: 10, color: Colors.yellowAccent),
                      SizedBox(width: 6),
                      Icon(Icons.circle, size: 10, color: Colors.grey),
                      SizedBox(width: 6),
                      Icon(Icons.circle, size: 10, color: Colors.grey),
                      SizedBox(width: 6),
                      Icon(Icons.circle, size: 10, color: Colors.grey),
                    ],
                  ),
                  TextButton(
                    onPressed: () => Get.toNamed(Routes.SPLASH3),
                    child: const Text(
                      'Selanjutnya',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
