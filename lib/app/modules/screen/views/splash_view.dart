import 'package:bicaraku/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SplashView extends StatefulWidget {
  const SplashView({Key? key}) : super(key: key);

  @override
  State<SplashView> createState() => _SplashState();
}

class _SplashState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    // Setelah 3 detik, pindah ke splash2
    Future.delayed(const Duration(seconds: 2), () {
      Get.offNamed(Routes.SPLASH2);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Gambar Splash
            SizedBox(
              width: 300, // Atur ukuran gambar di sini
              height: 300,
              child: Image(
                image: AssetImage('assets/images/splashscreen/splash.png'),
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: 24), // Jarak antara gambar dan loading
            // Loading Indicator
            CircularProgressIndicator(color: Color.fromARGB(255, 201, 71, 224),
  strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}
