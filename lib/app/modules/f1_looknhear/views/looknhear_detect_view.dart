import 'package:bicaraku/core/network/api_constant.dart';
import 'package:bicaraku/core/utils/yuv_converter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../controllers/looknhear_controller.dart';
import 'package:bicaraku/core/utils/debouncer.dart';

class LooknhearDetectView extends StatefulWidget {
  const LooknhearDetectView({super.key});

  @override
  State<LooknhearDetectView> createState() => _LooknhearDetectViewState();
}

class _LooknhearDetectViewState extends State<LooknhearDetectView> {
  final lookController = Get.find<LooknhearController>();
  CameraController? cameraController;
  bool isCameraInitialized = false;
  bool isDetecting = false; // Flag untuk memastikan hanya satu deteksi aktif

  // Gunakan throttler kustom
  final _throttler = Throttler(
    const Duration(milliseconds: 1000),
  );

  @override
  void initState() {
    super.initState();
    initCamera();
    lookController.speakInitialGuidance();
  }

  Future<void> initCamera() async {
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      Get.snackbar("Izin Ditolak", "Aplikasi membutuhkan akses kamera.");
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        Get.snackbar("Error", "Tidak ditemukan kamera");
        return;
      }

      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      cameraController = CameraController(
        backCamera,
        ResolutionPreset.medium, // Kembali ke medium dulu, high bisa berat
        enableAudio: false,
      );

      await cameraController!.initialize();
      await cameraController!.setFlashMode(FlashMode.off);

      setState(() => isCameraInitialized = true);
      _startImageStream();
    } catch (e) {
      Get.snackbar("Error", "Gagal mengakses kamera: $e");
      print("Camera error: $e");
    }
  }

  void _startImageStream() {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return;
    }

    if (cameraController!.value.isStreamingImages) {
      cameraController!.stopImageStream();
    }

    cameraController!.startImageStream((CameraImage image) {
      if (!lookController.isSpeaking.value &&
          !lookController.hasDetected.value &&
          !isDetecting) {
        _throttler.call(() {
          detectObjectInFrame(image);
        });
      }
    });
  }

  Future<void> detectObjectInFrame(CameraImage image) async {
    if (isDetecting) {
      return;
    }

    setState(() => isDetecting = true);
    if (lookController.isSpeaking.value) {
      lookController.stopSpeaking();
    }

    try {
      final imageBytes = convertYUV420ToImage(image);
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.detect}'),
        headers: {'Content-Type': 'application/octet-stream'},
        body: imageBytes,
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        final detected = result['detected'];

        if (detected is List && detected.isNotEmpty) {
          final closestObject = detected.first?.toString() ?? 'unknown'; // Safe access
          lookController.detectNewObject(closestObject);
          lookController.hasDetected.value = true;

          await lookController.speakDetectedObject(closestObject);
        } else {
          print("Tidak ada objek terdeteksi");

        }
      } else {
        print("Backend error: ${response.statusCode} - ${response.body}");
        Get.snackbar(
          "Error",
          "Backend error: ${response.statusCode}",
        );
      }
    } catch (e) {
      print("Error during detection: $e");
      Get.snackbar(
        "Error",
        "Terjadi kesalahan: ${e.toString().split(":").first}",
      );
    } finally {
      setState(() => isDetecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: isCameraInitialized
            ? Stack(
                children: [
                  Positioned.fill(
                    top: 80,
                    bottom: 95,
                    child: CameraPreview(cameraController!),
                  ),
                  Positioned(
                    top: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back_ios,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                Get.back();
                              },
                            ),
                            const Text(
                              "Melihat dan Mendengar",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 40),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Obx(() {
                          final obj = lookController.detectedObject.value;
                          return Text(
                            obj.isNotEmpty
                                ? "Objek: $obj"
                                : "Arahkan Kamera ke Objek",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        children: [
                          Obx(() {
                            if (lookController.isProcessingSpeech.value) {
                              return const Text(
                                "Memproses...",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              );
                            } else if (lookController.isListening.value) {
                              return const Text(
                                "Mendengarkan...",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              );
                            } else if (lookController
                                .recognizedText.isNotEmpty) {
                              return Text(
                                "Anda mengucapkan: ${lookController.recognizedText.value}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              );
                            }
                            return const SizedBox();
                          }),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Obx(
                                () => Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    color: lookController.isListening.value
                                        ? Colors.red
                                        : Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.mic,
                                      size: 32,
                                      color: lookController.isListening.value
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                    onPressed: lookController.toggleRecording,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 30),
                              Container(
                                width: 55,
                                height: 55,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.refresh,
                                    size: 28,
                                    color: Colors.black,
                                  ),
                                  onPressed: () {
                                    lookController.resetAllSpeech();
                                    _throttler.cancel(); // Reset throttler
                                    // Restart image stream to re-enable detection
                                    _startImageStream();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
      ),
    );
  }

  @override
  void dispose() {
    print("LooknhearDetectView dispose CALLED!"); // Log for debugging
    lookController.resetAllSpeech(); // Reset controller's state
    lookController.stopSpeaking(); // Ensure TTS stops
    _throttler.cancel(); // Cancel any pending throttled calls
    cameraController?.stopImageStream(); // Stop the camera image stream
    cameraController?.dispose(); // Dispose the camera controller
    super.dispose();
  }
}
