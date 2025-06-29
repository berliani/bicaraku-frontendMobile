import 'package:bicaraku/app/data/controllers/user_controller.dart';
import 'package:bicaraku/app/modules/f1_looknhear/controllers/looknhear_controller.dart';
import 'package:bicaraku/core/widgets/custom_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LooknhearView extends StatefulWidget {
  const LooknhearView({super.key});

 @override
  State<LooknhearView> createState() => _LooknhearViewState();
}

class _LooknhearViewState extends State<LooknhearView> {
  final userController = Get.put(UserController());
  late LooknhearController lookController;

  @override
  void initState() {
    super.initState();
     lookController = Get.put(LooknhearController());
    
    // Hentikan semua ucapan saat masuk ke halaman utama
    WidgetsBinding.instance.addPostFrameCallback((_) {
      lookController.resetAllSpeech();
    });
  }
  
  Widget build(BuildContext context) {
    final userController = Get.put(UserController());
    // Tambahkan pengecekan ARGUMENTS di sini
    if (Get.arguments != null && Get.arguments['name'] != null) {
      userController.setUser(Get.arguments['name']);
    }
    return Scaffold(
      bottomNavigationBar: const CustomBottomNav(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            // supaya bisa scroll di layar kecil
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/iconfitur.png'),
                  const SizedBox(height: 30),
                  const Text(
                    'Ayo kenali benda disekitarmu dengan kamera. Semoga berhasil!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    onPressed: () {

                      Get.toNamed('/looknhearcam');
                    },
                    icon: const Icon(Icons.play_arrow, color: Colors.black),
                    label: const Text(
                      'Mulai',
                      style: TextStyle(color: Colors.black),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent[100],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
