import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../controllers/looknhear_controller.dart';
import 'package:bicaraku/core/network/api_constant.dart';
import 'package:bicaraku/core/utils/yuv_converter.dart';
import 'package:bicaraku/core/utils/debouncer.dart';

class LooknhearDetectView extends StatefulWidget {
  const LooknhearDetectView({super.key});

  @override
  State<LooknhearDetectView> createState() => _LooknhearDetectViewState();
}

class _LooknhearDetectViewState extends State<LooknhearDetectView> {
  final lookController = Get.put(LooknhearController());
  CameraController? cameraController;
  bool isCameraInitialized = false;
  bool isDetecting = false;
  String? cameraError;
  final _throttler = Throttler(const Duration(milliseconds: 1000));

  @override
  void initState() {
    super.initState();
    lookController.resetAllSpeech();
    _initAndDisplayCameraThenGuide();
  }

  Future<void> _initAndDisplayCameraThenGuide() async {
    await initCamera();
    if (isCameraInitialized) {
      await lookController.playInitialGuidance();
      _startImageStream();
    }
  }

  Future<void> initCamera() async {
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      setState(() => cameraError = "Izin kamera ditolak");
      return;
    }

    try {
      final cameras = await availableCameras();
      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      cameraController = CameraController(backCamera, ResolutionPreset.high);
      await cameraController!.initialize();
      await cameraController!.setFlashMode(FlashMode.off);

      if (mounted) {
        setState(() => isCameraInitialized = true);
      }
    } catch (e) {
      setState(() => cameraError = "Gagal akses kamera: $e");
    }
  }

  void _startImageStream() {
    if (cameraController == null || !cameraController!.value.isInitialized)
      return;
    if (cameraController!.value.isStreamingImages) {
      cameraController!.stopImageStream();
    }

    cameraController!.startImageStream((image) {
      if (!lookController.hasDetected.value && !isDetecting) {
        _throttler.call(() => detectObjectInFrame(image));
      }
    });
  }

  Future<void> detectObjectInFrame(CameraImage image) async {
    if (isDetecting) return;
    setState(() => isDetecting = true);

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
          final obj = detected.first.toString();
          lookController.detectNewObject(obj);
          cameraController?.stopImageStream();
          await lookController.speakObjectIdentification(obj);
        }
      }
    } catch (e) {
      print("Detection error: $e");
    } finally {
      setState(() => isDetecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          lookController.resetAllSpeech();
          Get.back();
        }
      },

      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child:
              isCameraInitialized
                  ? Stack(
                    fit: StackFit.expand,
                    children: [
                      CameraPreview(cameraController!),
                      _buildOverlayContent(),
                    ],
                  )
                  : cameraError != null
                  ? Center(
                    child: Text(
                      cameraError!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  )
                  : const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  Widget _buildOverlayContent() {
    return Stack(
      children: [
        // Header
        Positioned(
          top: 10,
          left: 10,
          right: 10,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Get.back(),
              ),
              Obx(
                () => Text(
                  lookController.detectedObject.value.isNotEmpty
                      ? "Objek: ${lookController.detectedObject.value}"
                      : "Arahkan kamera",
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),

        // Tombol Ucapkan Objek
        Obx(() {
          if (lookController.hasDetected.value &&
              !lookController.showSyllableGuide.value) {
            return Positioned(
              bottom: 150,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton(
                  onPressed: () {
                    cameraController?.stopImageStream();
                    lookController.startPronunciationGuide();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "Ucapkan Objek",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            );
          }
          return const SizedBox();
        }),

        // Panduan suku kata
        Obx(() {
          if (lookController.showSyllableGuide.value) {
            return Positioned(
              top: MediaQuery.of(context).size.height * 0.2,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  const Text(
                    "Ucapkan:",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    lookController.detectedObject.value,
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildDualHighlightSyllableGuide(),
                ],
              ),
            );
          }
          return const SizedBox();
        }),

        // Status pengenalan suara
        Positioned(
          bottom: 120,
          left: 0,
          right: 0,
          child: Obx(() {
            if (lookController.isProcessingSpeech.value) {
              return const Center(
                child: Text(
                  "Memproses...",
                  style: TextStyle(color: Colors.white),
                ),
              );
            } else if (lookController.isListening.value) {
              return Center(
                child: Text(
                  "Mendengarkan: ${lookController.recognizedText.value}",
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }
            return const SizedBox();
          }),
        ),

        // Tombol kontrol bawah
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Obx(() {
                final isListening = lookController.isListening.value;
                return Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: isListening ? Colors.red : Colors.purpleAccent,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      isListening ? Icons.stop : Icons.mic,
                      color: Colors.white,
                      size: 32,
                    ),
                    onPressed: lookController.toggleRecording,
                  ),
                );
              }),
              const SizedBox(width: 20),
              Container(
                width: 55,
                height: 55,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.black),
                  onPressed: () {
                    lookController.resetDetection();
                    _throttler.cancel();
                    _startImageStream();
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDualHighlightSyllableGuide() {
    return Obx(() {
      final syllables = lookController.getSyllablesForObject(
        lookController.detectedObject.value,
      );

      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 8,
        children:
            syllables.map((syllable) {
              final isSystemActive =
                  lookController.systemSyllable.value == syllable;
              final isUserActive =
                  lookController.userSyllable.value == syllable;
              final isCorrect =
                  lookController.syllableResults[syllable] ?? false;

              Color bgColor = Colors.transparent;
              Color borderColor = Colors.white54;
              Color textColor = Colors.orangeAccent;
              double scale = 1.0;

              if (isSystemActive) {
                bgColor = Colors.amber.withOpacity(0.6);
                borderColor = Colors.orange;
                textColor = Colors.black;
                scale = 1.15;
              } else if (isUserActive) {
                bgColor = Colors.blue.withOpacity(0.6);
                borderColor = Colors.lightBlueAccent;
                textColor = Colors.white;
                scale = 1.1;
              } else if (isCorrect) {
                bgColor = Colors.green.withOpacity(0.5);
                borderColor = Colors.greenAccent;
                textColor = Colors.white;
              }

              return AnimatedScale(
                duration: const Duration(milliseconds: 300),
                scale: scale,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor, width: 2),
                  ),
                  child: Text(
                    syllable,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              );
            }).toList(),
      );
    });
  }

  @override
  void dispose() {
    lookController.resetAllSpeech();
    Get.closeAllSnackbars();
    _throttler.cancel();
    cameraController?.stopImageStream();
    cameraController?.dispose();
    super.dispose();
  }
}
