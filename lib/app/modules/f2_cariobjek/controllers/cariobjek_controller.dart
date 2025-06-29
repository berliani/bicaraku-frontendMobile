import 'dart:async';
import 'dart:convert';
import 'package:bicaraku/app/routes/app_routes.dart';
import 'package:bicaraku/core/utils/yuv_converter.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:bicaraku/core/network/api_constant.dart';
import 'package:bicaraku/app/data/controllers/activity_controller.dart';
import 'package:bicaraku/app/data/models/activity_history.dart';
import 'package:bicaraku/core/utils/debouncer.dart';

class CariObjekController extends GetxController {
  late CameraController cameraController;
  final isCameraInitialized = false.obs;
  final countdown = 30.obs;
  final instruksi = ''.obs;
  final targetObject = ''.obs;
  final detectedObject = ''.obs;
  var isSpeaking = false.obs;
  var isListening = false.obs;
  var recognizedText = ''.obs;
  var isProcessingSpeech = false.obs;
  var hasFoundObject = false.obs;
  var isReady = false.obs;

  Timer? _countdownTimer;
  final _speechQueue = <String>[].obs;
  late FlutterTts _tts;
  late stt.SpeechToText _speech;
  final _throttler = Throttler(const Duration(milliseconds: 1500));

  // Shared assets
  final correctImage = 'assets/images/correct.png';
  final wrongImage = 'assets/images/wrong.png';

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null && Get.arguments is String) {
      instruksi.value = Get.arguments as String;
      targetObject.value = _extractTargetObject(instruksi.value);
    }
    _initializeServices();
  }

  String _extractTargetObject(String instruksi) {
    return instruksi.replaceAll('"', '').replaceAll('AYO TEMUKAN ', '').trim();
  }

  Future<void> _initializeServices() async {
    await _configureTts();
    await _initializeSpeech();
    await _initializeCamera();
    await _speakInitialInstruction();
  }

  Future<void> _configureTts() async {
    _tts = FlutterTts();
    await _tts.awaitSpeakCompletion(true);
    await _tts.setLanguage("id-ID");
    await _tts.setSpeechRate(0.4);
    await _tts.setPitch(1.0);
  }

  Future<void> _initializeSpeech() async {
    _speech = stt.SpeechToText();
    await _speech.initialize();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      cameraController = CameraController(cameras[0], ResolutionPreset.medium);
      await cameraController.initialize();
      isCameraInitialized.value = true;
    } catch (e) {
      Get.snackbar("Error", "Gagal menginisialisasi kamera");
    }
  }

  Future<void> _speakInitialInstruction() async {
    for (int i = 0; i < 3; i++) {
      await _tts.speak("Ayo cari ${targetObject.value}");
      await Future.delayed(const Duration(milliseconds: 1500));
    }
    
    // Tampilkan dialog konfirmasi setelah instruksi
    Get.dialog(
      _buildConfirmationDialog(),
      barrierDismissible: false,
    );
  }

  Widget _buildConfirmationDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/ready.png',
              width: 100,
              height: 100,
            ),
            const SizedBox(height: 15),
            Text(
              "Cari ${targetObject.value} dan arahkan ke kamera untuk berlatih berbicara",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Get.back();
                isReady.value = true;
                _startCountdown();
                _startImageStream();
                // Suara tambahan setelah klik tombol
                _tts.speak("Ayo mulai cari ${targetObject.value}!");
              },
              child: const Text("Siap! Mulai"),
            ),
          ],
        ),
      ),
    );
  }

  void _startImageStream() {
    cameraController.startImageStream((image) {
      if (isReady.value && !isSpeaking.value && countdown.value > 0 && !hasFoundObject.value) {
        _throttler.call(() => _detectObjectInFrame(image));
      }
    });
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown.value > 0) countdown.value--;
      else {
        _handleTimeout();
        timer.cancel();
      }
    });
  }

  Future<void> _detectObjectInFrame(CameraImage image) async {
    try {
      final imageBytes = convertYUV420ToImage(image);
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.detect}'),
        headers: {'Content-Type': 'application/octet-stream'},
        body: imageBytes,
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        final detectedLabels = List<String>.from(result['detected']);

        if (detectedLabels.isNotEmpty) {
          final closestObject = detectedLabels.first;
          detectedObject.value = closestObject;

          if (closestObject.toLowerCase() == targetObject.value.toLowerCase()) {
            // Hentikan semua proses deteksi
            cameraController.stopImageStream();
            await _handleObjectFound();
          } else {
            // Hentikan sementara deteksi
            cameraController.stopImageStream();
            await _handleWrongObject(closestObject);
          }
        }
      }
    } catch (e) {
      debugPrint("Error deteksi objek: $e");
    }
  }

  Future<void> _handleObjectFound() async {
    hasFoundObject.value = true;
    _countdownTimer?.cancel();

    // Tampilkan notifikasi benar
    Get.dialog(
      _buildCorrectDialog(),
      barrierDismissible: false,
    );

    // Feedback suara langsung
    await _tts.speak("Hore! Kamu berhasil menemukan ${targetObject.value}");
    await Future.delayed(const Duration(seconds: 2));
    
    // Tutup dialog setelah 2 detik
    Get.back();

    // Lanjutkan ke proses spelling
    _speechQueue.add("Sekarang coba ucapkan nama benda tersebut");
    if (!isSpeaking.value) await _processQueue();

    // Simpan riwayat
    final activityController = Get.put(ActivityController());
    activityController.addHistory(ActivityHistory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: "Mencari ${targetObject.value}",
      image: _getImageForObject(targetObject.value),
      date: DateTime.now(),
      isCompleted: true,
      instruksi: instruksi.value,
      points: 0,
    ));
  }

  Widget _buildCorrectDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.5, end: 1.0),
        duration: const Duration(milliseconds: 500),
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    correctImage,
                    width: 150,
                    height: 150,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Benar!",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Kamu menemukan ${targetObject.value}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleWrongObject(String detectedName) async {
    // Tampilkan notifikasi salah
    Get.dialog(
      _buildWrongDialog(detectedName),
      barrierDismissible: false,
    );

    // Feedback suara langsung
    await _tts.speak("Belum tepat!");
    await _tts.speak("Ini $detectedName");
    await _tts.speak("Bukan ${targetObject.value}");

    // Tunggu 3 detik sebelum melanjutkan deteksi
    await Future.delayed(const Duration(seconds: 3));
    Get.back();

    // Lanjutkan deteksi
    if (!hasFoundObject.value && countdown.value > 0) {
      cameraController.startImageStream((image) {
        if (isReady.value && !isSpeaking.value && countdown.value > 0 && !hasFoundObject.value) {
          _throttler.call(() => _detectObjectInFrame(image));
        }
      });
    }
  }

  Widget _buildWrongDialog(String detectedName) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.5, end: 1.0),
        duration: const Duration(milliseconds: 500),
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    wrongImage,
                    width: 150,
                    height: 150,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Belum Tepat!",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Ini $detectedName\nBukan ${targetObject.value}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _processQueue() async {
    while (_speechQueue.isNotEmpty) {
      isSpeaking.value = true;
      final text = _speechQueue.removeAt(0);
      
      if (text == "Sekarang coba ucapkan nama benda tersebut") {
        // Langsung ke instruksi tanpa spelling
        await _tts.speak(text);
        await Future.delayed(const Duration(milliseconds: 1000));
        _startListening();
      } else {
        // Untuk spelling jika diperlukan
        await _tts.speak(text);
        await Future.delayed(const Duration(milliseconds: 1000));
      }
    }
    isSpeaking.value = false;
  }

  Future<void> _startListening() async {
    if (await _speech.initialize()) {
      isListening.value = true;
      _speech.listen(
        onResult: (result) => recognizedText.value = result.recognizedWords,
        localeId: "id_ID",
        listenFor: const Duration(seconds: 5),
      );
    }
  }

  void toggleRecording() {
    if (isListening.value) {
      _speech.stop();
      isListening.value = false;
      _checkSpeechMatch();
    } else if (hasFoundObject.value) {
      _startListening();
    }
  }

  void _checkSpeechMatch() async {
    final input = recognizedText.value.toLowerCase().trim();
    final target = targetObject.value.toLowerCase().trim();

    await _tts.stop();

    if (input == target) {
      await _tts.speak("Hore! Pelafalanmu tepat!");
      await _tts.speak("Kamu hebat!");
      Get.offAllNamed(Routes.HOME);
    } else {
      await _tts.speak("Pelafalanmu belum tepat");
      await _tts.speak("Ayo coba ucapkan lagi");
      recognizedText.value = '';
      _startListening();
    }
  }

  void _handleTimeout() {
    hasFoundObject.value = false;
    cameraController.stopImageStream();

    Get.dialog(_buildTimeoutDialog(), barrierDismissible: false);
    
    _tts.speak("Waktu sudah habis, jangan menyerah ya! Coba lagi lain kali");
    
    final activityController = Get.put(ActivityController());
    activityController.addHistory(ActivityHistory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: "Mencari ${targetObject.value}",
      image: _getImageForObject(targetObject.value),
      date: DateTime.now(),
      isCompleted: false,
      instruksi: instruksi.value,
      points: 0,
    ));
  }

  String _getImageForObject(String object) {
    final objectImages = {
      "BOLA": 'assets/images/f2.cariobjek/1.png',
      "BOTOL": 'assets/images/f2.cariobjek/2.png',
      "KURSI": 'assets/images/f2.cariobjek/3.png',
      "TEMPAT TIDUR": 'assets/images/f2.cariobjek/5.png',
      "TAS": 'assets/images/f2.cariobjek/6.png',
      "TELEVISI": 'assets/images/f2.cariobjek/4.png',
      "LAPTOP": 'assets/images/f2.cariobjek/7.png',
      "KEYBOARD": 'assets/images/f2.cariobjek/8.png',
      "BONEKA": 'assets/images/f2.cariobjek/9.png',
    };
    return objectImages[object] ?? 'assets/images/defaulthistory.png';
  }

  Widget _buildTimeoutDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Image.asset(
                    'assets/images/crying.png',
                    width: 180,
                    height: 180,
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Text(
              "Waktu Habis!",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              "Yah, waktu sudah habis.\nJangan menyerah, coba lagi ya!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, height: 1.4),
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: () {
                Get.back();
                Get.offAllNamed(Routes.CARIOBJEK);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text(
                "COBA LAGI",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    _tts.stop();
    _speechQueue.clear();
    cameraController.dispose();
    if (_speech.isListening) _speech.stop();
    super.onClose();
  }
}