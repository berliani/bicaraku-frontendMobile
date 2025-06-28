import 'package:bicaraku/app/modules/f2_cariobjek/controllers/cariobjek_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';

class CariobjekcamView extends GetView<CariObjekController> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        controller.onClose();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Obx(() {
            if (!controller.isCameraInitialized.value) {
              return const Center(child: CircularProgressIndicator());
            }

            return Stack(
              children: [
                // Camera Preview
                Positioned.fill(
                  child: CameraPreview(controller.cameraController),
                ),

                // Header
                Positioned(
                  top: 20,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Get.back(),
                      ),
                      Obx(() => Text(
                        "Mencari: ${controller.targetObject.value}",
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                      )),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),

                // Timer
                Positioned(
                  top: 70,
                  left: 20,
                  child: Obx(() => Text(
                    "Sisa Waktu: 00:${controller.countdown.value.toString().padLeft(2, '0')}",
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  )),
                ),

                // Status
                Positioned(
                  top: 70,
                  right: 20,
                  child: Obx(() {
                    if (controller.isProcessingSpeech.value) {
                      return const Text("Memproses...", style: TextStyle(color: Colors.white));
                    } else if (controller.isListening.value) {
                      return const Text("Mendengarkan...", style: TextStyle(color: Colors.white));
                    } else if (controller.recognizedText.isNotEmpty) {
                      return Text("Anda: ${controller.recognizedText.value}", style: const TextStyle(color: Colors.white));
                    }
                    return const SizedBox();
                  }),
                ),

                // Tombol Mikrofon
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Obx(() {
                      // Hanya tampilkan tombol jika objek sudah ditemukan
                      if (controller.hasFoundObject.value) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: controller.isListening.value ? 85 : 70,
                          height: controller.isListening.value ? 85 : 70,
                          decoration: BoxDecoration(
                            color: controller.isListening.value
                                ? Colors.red
                                : Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: controller.isListening.value
                                ? [BoxShadow(
                                    color: Colors.red.withOpacity(0.8),
                                    blurRadius: 15,
                                    spreadRadius: 3,
                                  )]
                                : null,
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.mic,
                              size: controller.isListening.value ? 38 : 32,
                              color: controller.isListening.value
                                  ? Colors.white
                                  : Colors.black,
                            ),
                            onPressed: controller.toggleRecording,
                          ),
                        );
                      }
                      return const SizedBox();
                    }),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}