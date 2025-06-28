import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bicaraku/app/routes/app_routes.dart';

class Splash3View extends StatelessWidget {
  const Splash3View({Key? key}) : super(key: key);

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
                      'assets/images/splashscreen/splash3.png',
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Kenali benda di Sekitarmu!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Arahkan kamera ke objek, dengarkan suaranya, dan coba ucapkan!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
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
                      Icon(Icons.circle, size: 10, color: Colors.grey),
                      SizedBox(width: 6),
                      Icon(Icons.circle, size: 10, color: Colors.purpleAccent),
                      SizedBox(width: 6),
                      Icon(Icons.circle, size: 10, color: Colors.grey),
                      SizedBox(width: 6),
                      Icon(Icons.circle, size: 10, color: Colors.grey),
                    ],
                  ),
                  TextButton(
                    onPressed: () => Get.offNamed(Routes.SPLASH4),
                    child: const Text(
                      'Selanjutnya',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
