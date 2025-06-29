import 'package:bicaraku/app/data/models/learning_history_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:bicaraku/core/utils/pronunciation.dart';
import 'package:audioplayers/audioplayers.dart';

import 'package:bicaraku/app/data/controllers/user_controller.dart';
import 'package:bicaraku/core/network/dio_client.dart';
import 'package:bicaraku/core/network/api_constant.dart';
import 'package:bicaraku/app/routes/app_routes.dart';

class LooknhearController extends GetxController {
  var detectedObject = "".obs;
  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  var isSpeaking = false.obs;
  final _speechQueue = <String>[].obs;
  final stt.SpeechToText _speech = stt.SpeechToText();
  var isListening = false.obs;
  var recognizedText = "".obs;
  final correctImage = 'assets/images/correct.png';
  final wrongImage = 'assets/images/wrong.png';
  final wrongAudio = 'audio/wrong.wav';
  final correctAudio = 'audio/correct.wav';

  final RxList<LearningHistoryEntry> learningHistory =
      <LearningHistoryEntry>[].obs;
  var mostDetectedObjects = <String, int>{}.obs;
  var hasDetected = false.obs;

  final UserController _userController = Get.find<UserController>();
  final DioClient _dioClient = Get.put(DioClient());
  final _identificationQueue = <String>[].obs;
  final _pronunciationQueue = <String>[].obs;
  var systemSyllable = "".obs;
  var userSyllable = "".obs;
  var syllableResults = <String, bool>{}.obs;

  RxBool isProcessingSpeech = false.obs;
  RxBool isLoadingHistory = false.obs;
  var speechInitialized = false.obs;
  var isCameraGuiding = false.obs; 

  var showSyllableGuide = false.obs;

  @override
  void onInit() {
    super.onInit();
    _configureTts();
    _initSpeech(); // Initialize speech here

    ever(_userController.userRx, (user) {
      if (user != null) {
        _loadLearningHistory();
      } else {
        learningHistory.clear();
        mostDetectedObjects.clear();
      }
    });

    if (_userController.user != null) {
      _loadLearningHistory();
    }
  }

  // Pisahkan fungsi identifikasi objek dan panduan pengucapan
  Future<void> speakObjectIdentification(String object) async {
    if (!isCameraGuiding.value) {
      _identificationQueue.add(object); // Gunakan antrian identifikasi
      if (!isSpeaking.value) {
        await _processIdentification();
      }
    }
  }

  Future<void> _processIdentification() async {
    while (_identificationQueue.isNotEmpty) {
      isSpeaking.value = true;
      final object = _identificationQueue.removeAt(0);
      await _flutterTts.setSpeechRate(0.4);

      await _speechWithPause("Ini adalah");
      await _speechWithPause(object, pause: 800);
      await _speechWithPause("Sekarang klik tombol biru ya");
      await _speechWithPause("Kita belajar mengucapkan bersama!", pause: 600);
      await _flutterTts.setSpeechRate(0.5);
    }
    isSpeaking.value = false;
  }

  Future<void> startPronunciationGuide() async {
    if (detectedObject.value.isEmpty) return;

    // Hentikan semua proses sebelumnya
    stopSpeaking();

    showSyllableGuide.value = true;
    systemSyllable.value = "";
    userSyllable.value = "";
    syllableResults.clear();
    recognizedText.value = "";

    // Gunakan antrian panduan khusus
    _pronunciationQueue.add(detectedObject.value);
    await _processPronunciationGuide(); // Langsung proses tanpa cek antrian
  }

  Future<void> _processPronunciationGuide() async {
    isSpeaking.value = true;
    while (_pronunciationQueue.isNotEmpty) {
      final object = _pronunciationQueue.removeAt(0);

      await _speechWithPause("Sekarang", pause: 400);
      await _speechWithPause("coba kamu ucapkan", pause: 300);
      await _speakSyllables(object);
      await _speechWithPause(object, pause: 800);

      await Future.delayed(const Duration(milliseconds: 500));
      await startListening();
    }

    isSpeaking.value = false;
  }

  Future<void> _initSpeech() async {
    try {
      speechInitialized.value = await _speech.initialize(
        onStatus: (status) {
          if (status == "done" || status == "notListening") {
            isListening.value = false;
            // Trigger final check only if it's not a manual stop
            if (!isProcessingSpeech.value) {
              // Add a 2-second delay before checking pronunciation
              Future.delayed(const Duration(seconds: 1), () {
                _checkSpeechMatch();
              });
            }
          }
        },
        onError: (error) {
          isListening.value = false;
          print("STT Error: $error");
          Get.snackbar("Error", "Gagal mendengarkan: ${error.errorMsg}");
        },
      );
      if (!speechInitialized.value) {
        Get.snackbar(
          "Error",
          "Akses mikrofon tidak diizinkan. Pastikan izin telah diberikan.",
        );
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal inisialisasi Speech-to-Text: $e");
      print("STT Initialization Error: $e");
    }
  }

  List<String> getSyllablesForObject(String object) {
    final normalizedObject = object.toLowerCase().trim();
    return pronunciationExceptions[normalizedObject] ?? [object];
  }

  void _checkSyllablePronunciation(
    String recognizedWords,
    String targetObject,
  ) {
    final input = recognizedWords.toLowerCase();
    final syllables = getSyllablesForObject(targetObject);

    final Map<String, bool> currentResults = {
      for (var s in syllables) s: false,
    };

    for (String syllable in syllables) {
      final lowerSyllable = syllable.toLowerCase();
      if (input.contains(lowerSyllable)) {
        currentResults[syllable] = true;

        userSyllable.value = syllable;
        Future.delayed(const Duration(milliseconds: 200), () {
          if (userSyllable.value == syllable) {
            userSyllable.value = "";
          }
        });
      }
    }
    syllableResults.value = currentResults;
  }

  void detectNewObject(String newObject) {
    detectedObject.value = newObject;
    hasDetected.value = true;
    systemSyllable.value = "";
    userSyllable.value = "";
    syllableResults.clear();
    recognizedText.value = "";
  }

  Future<void> toggleRecording() async {
    if (isListening.value) {
      await _stopListening();
    } else {
      if (detectedObject.value.isEmpty) {
        Get.snackbar("Info", "Tidak ada objek yang terdeteksi");
        return;
      }
      if (isSpeaking.value) {
        stopSpeaking(); // Stop system speech before starting listening
      }
      await startListening();
    }
  }

  Future<void> clearLearningHistory() async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text("Hapus Semua Riwayat Belajar"),
        content: const Text(
          "Apakah Anda yakin ingin menghapus semua riwayat belajar Anda?",
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await _dioClient.delete(ApiConstants.learningHistory);
      if (response.statusCode == 200) {
        learningHistory.clear();
        mostDetectedObjects.clear();
        Get.snackbar(
          "Berhasil",
          "Semua riwayat belajar telah dihapus",
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          "Error",
          "Gagal menghapus riwayat belajar: ${response.statusCode}",
        );
      }
    } catch (e) {
      print("Error clearing learning history: $e");
      Get.snackbar("Error", "Terjadi kesalahan saat menghapus riwayat: $e");
    }
  }

  Future<void> removeHistoryItem(String id) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text("Hapus Item Riwayat"),
        content: const Text(
          "Apakah Anda yakin ingin menghapus item riwayat ini?",
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await _dioClient.delete(
        '${ApiConstants.learningHistory}/$id',
      );
      if (response.statusCode == 200) {
        learningHistory.removeWhere((item) => item.id == id);
        _calculateMostDetected();
        Get.snackbar(
          "Dihapus",
          "Item riwayat telah dihapus",
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          "Error",
          "Gagal menghapus item riwayat: ${response.statusCode}",
        );
      }
    } catch (e) {
      print("Error removing history item: $e");
      Get.snackbar("Error", "Terjadi kesalahan saat menghapus item: $e");
    }
  }

  Future<void> _loadLearningHistory() async {
    isLoadingHistory.value = true;
    try {
      final response = await _dioClient.get(ApiConstants.learningHistory);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        learningHistory.assignAll(
          data
              .map(
                (json) =>
                    LearningHistoryEntry.fromJson(json as Map<String, dynamic>),
              )
              .toList(),
        );
        _calculateMostDetected();
      } else {
        print(
          "Error loading learning history from API: ${response.statusCode}",
        );
        learningHistory.clear();
      }
    } catch (e) {
      print("Error loading learning history: $e");
      learningHistory.clear();
    } finally {
      isLoadingHistory.value = false;
    }
  }

  Future<void> _saveLearningHistory(String object) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.learningHistory,
        data: {'object': object},
      );

      if (response.statusCode == 201) {
        await _loadLearningHistory();
        print("Learning history saved and reloaded.");
      } else {
        print("Failed to save learning history: ${response.statusCode}");
      }
    } catch (e) {
      print("Error saving learning history: $e");
    }
  }

  void _calculateMostDetected() {
    final counts = <String, int>{};
    for (var entry in learningHistory) {
      final object = entry.object;
      counts[object] = (counts[object] ?? 0) + 1;
    }

    final sortedEntries =
        counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    mostDetectedObjects.value = Map.fromEntries(sortedEntries);
  }

  Future<void> _configureTts() async {
    await _flutterTts.awaitSpeakCompletion(true);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.1);
    await _flutterTts.setLanguage("id-ID");
    try {
      await _flutterTts.setVoice({
        'name': 'id-id-x-dfc#female_2-local',
        'locale': 'id-ID',
      });
    } catch (e) {
      print("Voice not available, using default: $e");
    }
  }

  Future<void> playInitialGuidance() async {
    isCameraGuiding.value = true; 
    stopSpeaking(); // Ensure no other speech is active

    await _speechWithPause("Ayo mulai!", pause: 400);
    await _speechWithPause("Arahkan kamera ke benda sekitar Anda", pause: 300);
    await _speechWithPause("Kita akan belajar bersama", pause: 500);

    isCameraGuiding.value = false; // Set to false after guidance finishes
    
  }

  Future<void> speakDetectedObject(String object) async {
    
    if (!isCameraGuiding.value) {
      _speechQueue.add(object);
      if (!isSpeaking.value) {
        await _processQueue();
      }
    }
  }

  Future<void> _processQueue() async {
    while (_speechQueue.isNotEmpty) {
      isSpeaking.value = true;
      final object = _speechQueue.removeAt(0);

      await _speechWithPause("Ini adalah");
      await _speechWithPause(object, pause: 800);

      await _speakSyllables(object);

      await _speechWithPause("Sekarang", pause: 400);
      await _speechWithPause("coba kamu ucapkan", pause: 300);
      await _speechWithPause(object, pause: 800);
    }
    isSpeaking.value = false;
  }

  Future<void> _speakSyllables(String object) async {
    final syllables = getSyllablesForObject(object);
    await _flutterTts.setSpeechRate(0.2);

    for (String syllable in syllables) {
      systemSyllable.value = syllable;
      await _flutterTts.speak(syllable);
      await Future.delayed(const Duration(milliseconds: 500));
    }
    systemSyllable.value = "";
    await _flutterTts.setSpeechRate(0.5);
  }

  Future<void> _speechWithPause(String text, {int pause = 300}) async {
    await _flutterTts.speak(text);
    await Future.delayed(Duration(milliseconds: pause));
  }

  void _checkSpeechMatch() async {
    final input = recognizedText.value.toLowerCase().trim();
    final target = detectedObject.value.toLowerCase().trim();

    await _flutterTts.stop();

    _checkSyllablePronunciation(recognizedText.value, detectedObject.value);

    if (input == target) {
      await _audioPlayer.play(AssetSource(correctAudio));
      await _speechWithPause("Hore!", pause: 400);
      await _speechWithPause("Kamu benar!", pause: 300);
      await _speechWithPause("$target", pause: 400);
      await _speechWithPause("Ayo lanjutkan!", pause: 500);

      _saveLearningHistory(target);

      Get.dialog(_buildFeedbackDialog(true, target), barrierDismissible: false);
      await Future.delayed(const Duration(seconds: 2));
      Get.back(); // Dismiss the dialog
      Get.offNamed(Routes.LOOKNHEAR);
    } else {
      await _audioPlayer.play(AssetSource(wrongAudio));
      await _speechWithPause("Oops...", pause: 500);
      await _speechWithPause("Hampir tepat!", pause: 400);
      await _speechWithPause("Coba lagi ya", pause: 600);

      Get.dialog(
        _buildFeedbackDialog(false, target),
        barrierDismissible: false,
      );
      await Future.delayed(const Duration(seconds: 2));
      Get.back();
    }
  }

  Widget _buildFeedbackDialog(bool isCorrect, String object) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.5, end: 1.0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    isCorrect ? correctImage : wrongImage,
                    width: 150,
                    height: 150,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    isCorrect ? "Selamat!" : "Ayo coba lagi",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isCorrect ? Colors.green : Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isCorrect
                        ? "Kamu berhasil mengucapkan\n\"$object\""
                        : "Ucapkan \"$object\"",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  if (!isCorrect) _buildSyllableResultPreviewInDialog(),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: () {
                      Get.back();
                    },
                    child: Text(isCorrect ? "Oke" : "Coba Lagi"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCorrect ? Colors.green : Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSyllableResultPreviewInDialog() {
    final syllables = getSyllablesForObject(detectedObject.value);

    return Obx(() {
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children:
            syllables.map((syllable) {
              final isCorrect = syllableResults[syllable] ?? false;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color:
                      isCorrect
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: isCorrect ? Colors.green : Colors.red,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      syllable,
                      style: TextStyle(
                        fontSize: 16,
                        color: isCorrect ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Icon(
                      isCorrect ? Icons.check : Icons.close,
                      size: 16,
                      color: isCorrect ? Colors.green : Colors.red,
                    ),
                  ],
                ),
              );
            }).toList(),
      );
    });
  }

  void stopSpeaking() {
    _flutterTts.stop();
    _identificationQueue.clear(); // Reset antrian identifikasi
    _pronunciationQueue.clear(); // Reset antrian panduan
    isSpeaking.value = false;
    systemSyllable.value = "";
  }

  Future<void> toggleMic() async {
    if (isListening.value) {
      await _stopListening();
    } else {
      if (detectedObject.value.isEmpty) {
        Get.snackbar("Info", "Tidak ada objek terdeteksi");
        return;
      }
      stopSpeaking(); // stop TTS jika sedang bicara
      await startListening();
    }
  }

  Future<void> startListening() async {
    if (!speechInitialized.value) {
      Get.snackbar("Error", "Speech recognition belum diinisialisasi.");
      return;
    }

    try {
      isListening.value = true;
      recognizedText.value = "";
      userSyllable.value = "";
      syllableResults.value = {
        for (var s in getSyllablesForObject(detectedObject.value)) s: false,
      };

      await _speech.listen(
        onResult: (result) {
          recognizedText.value = result.recognizedWords;
          _checkSyllablePronunciation(
            result.recognizedWords,
            detectedObject.value,
          );
        },
        localeId: "id_ID",
        listenFor: const Duration(seconds: 5),
      );
    } catch (e) {
      isListening.value = false;
      Get.snackbar("Error", "Gagal memulai rekaman: $e");
    }
  }

  // Perbaikan fungsi stopListening
  Future<void> _stopListening() async {
    try {
      isProcessingSpeech.value = true;
      await _speech.stop();
      await Future.delayed(const Duration(milliseconds: 500));
      _checkSpeechMatch();
    } catch (e) {
      Get.snackbar("Error", "Gagal menghentikan rekaman");
    } finally {
      isProcessingSpeech.value = false;
      isListening.value = false;
    }
  }

  // Tambahkan reset untuk deteksi objek
  void resetDetection() {
    detectedObject.value = "";
    hasDetected.value = false;
    resetAllSpeech();
  }

  void resetAllSpeech() {
    stopSpeaking();
    _speech.cancel();
    _audioPlayer.stop();
    _identificationQueue.clear();
    _pronunciationQueue.clear();
    _speechQueue.clear();
    isSpeaking.value = false;
    isListening.value = false;
    isProcessingSpeech.value = false;
    detectedObject.value = "";
    recognizedText.value = "";
    systemSyllable.value = "";
    userSyllable.value = "";
    syllableResults.clear();
    showSyllableGuide.value = false;
    hasDetected.value = false;
  }

  @override
  void onClose() {
    stopSpeaking();
    _audioPlayer.dispose();
    _speech.cancel();
    super.onClose();
  }
}
