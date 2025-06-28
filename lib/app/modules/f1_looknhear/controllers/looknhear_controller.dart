import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:bicaraku/core/utils/pronunciation.dart'; 
import 'package:audioplayers/audioplayers.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:bicaraku/app/data/controllers/user_controller.dart'; 

class LooknhearController extends GetxController {
  var detectedObject = "".obs;
  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer(); // Initialize AudioPlayer
  var isSpeaking = false.obs;
  final _speechQueue = <String>[].obs;
  final stt.SpeechToText _speech = stt.SpeechToText();
  var isListening = false.obs;
  var recognizedText = "".obs;
  final correctImage = 'assets/images/correct.png';
  final wrongImage = 'assets/images/wrong.png';
  final wrongAudio = 'audio/wrong.wav'; // Path for audioplayers
  final correctAudio = 'audio/correct.wav'; // Path for audioplayers

  // === RIWAYAT BELAJAR ===
  // final storage = GetStorage(); // No longer used for learning history
  var learningHistory = <Map<String, dynamic>>[].obs;
  var mostDetectedObjects = <String, int>{}.obs;
  var hasDetected = false.obs; // Inisialisasi dengan false

  // UserController dependency
  final UserController _userController = Get.find<UserController>();
  static const String _learningHistoryKeyPrefix = 'learning_history_';

  // Helper to get user-specific storage key
  String _getLearningHistoryStorageKey() {
    final userId = _userController.user?.id;
    if (userId == null || userId.isEmpty) {
      // Fallback for cases where user might not be logged in or ID is missing
      return '${_learningHistoryKeyPrefix}guest';
    }
    return '$_learningHistoryKeyPrefix$userId';
  }

  // === Detected Object ===
  void detectNewObject(String newObject) {
    detectedObject.value = newObject;
    // Simpan riwayat segera setelah objek terdeteksi
    _saveLearningHistory(newObject);
  }

  RxBool isProcessingSpeech = false.obs;

  Future<void> toggleRecording() async {
    if (isListening.value) {
      stopListening();
    } else {
      if (detectedObject.value.isEmpty) {
        Get.snackbar("Info", "Tidak ada objek yang terdeteksi");
        return;
      }
      // Hentikan TTS jika sedang berbicara
      if (isSpeaking.value) {
        stopSpeaking();
      }
      await startListening(detectedObject.value);
    }
  }

  Future<void> clearLearningHistory() async {
    learningHistory.clear();
    mostDetectedObjects.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_getLearningHistoryStorageKey());
    update(); // Memperbarui UI
    Get.snackbar(
      "Berhasil",
      "Riwayat belajar telah dihapus",
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> removeHistoryItem(int index) async {
    if (index >= 0 && index < learningHistory.length) {
      final removedObject = learningHistory[index]['object'];
      learningHistory.removeAt(index);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _getLearningHistoryStorageKey(), json.encode(learningHistory.toList()));
      _calculateMostDetected();

      Get.snackbar(
        "Dihapus",
        "$removedObject telah dihapus dari riwayat",
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

  @override
  void onInit() {
    super.onInit();
    _configureTts();

   

    // Initial load of learning history based on current user
    _loadLearningHistory();
  }

  Future<void> _loadLearningHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_getLearningHistoryStorageKey());
    if (jsonString != null) {
      try {
        learningHistory.value = List<Map<String, dynamic>>.from(json.decode(jsonString));
        _calculateMostDetected();
      } catch (e) {
        print("Error decoding learning history: $e");
        learningHistory.clear(); // Clear corrupted data
      }
    } else {
      learningHistory.clear();
    }
  }

  Future<void> _saveLearningHistory(String object) async {
    // Add new entry
    learningHistory.add({
      'object': object,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Save to local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _getLearningHistoryStorageKey(), json.encode(learningHistory.toList()));

    _calculateMostDetected();
  }

  void _calculateMostDetected() {
    final counts = <String, int>{};
    for (var entry in learningHistory) {
      final object = entry['object'] as String;
      counts[object] = (counts[object] ?? 0) + 1;
    }

    // Sort from most frequent
    final sortedEntries =
        counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    mostDetectedObjects.value = Map.fromEntries(sortedEntries);
  }

  Future<void> _configureTts() async {
    await _flutterTts.awaitSpeakCompletion(
      true,
    ); // Tunggu sampai selesai bicara
    await _flutterTts.setSpeechRate(0.5); // Kecepatan sedang
    await _flutterTts.setPitch(1.1); // Sedikit lebih tinggi untuk suara ramah
    await _flutterTts.setLanguage("id-ID");

    try {
      // Coba set voice lebih natural (tergantung platform)
      await _flutterTts.setVoice({
        'name': 'id-id-x-dfc#female_2-local',
        'locale': 'id-ID',
      });
    } catch (e) {
      print("Voice not available, using default: $e");
    }
  }

  Future<void> speakInitialGuidance() async {
    stopSpeaking(); // Stop any existing speech
    await _speechWithPause("Ayo mulai!", pause: 400);
    await _speechWithPause("Arahkan kamera ke benda", pause: 300);
    await _speechWithPause("Kita akan belajar bersama", pause: 500);
  }

  Future<void> speakDetectedObject(String object) async {
    _speechQueue.add(object);
    if (!isSpeaking.value) {
      await _processQueue();
    }
  }

  Future<void> _processQueue() async {
    while (_speechQueue.isNotEmpty) {
      isSpeaking.value = true;
      final object = _speechQueue.removeAt(0);

      // Bicara dengan pola lebih natural
      for (int i = 0; i < 3; i++) {
        if (_speechQueue.isNotEmpty) break;

        // 1. Sebutkan objek lengkap dulu
        await _speechWithPause("Ini adalah");
        await _speechWithPause(object, pause: 800);

        // 2. Mengeja dengan ritme
        await _spellWord(object);

        // 3. Beri jeda antar pengulangan
        await Future.delayed(const Duration(milliseconds: 1200));
      }

      // Instruksi dengan kalimat lebih natural
      if (_speechQueue.isEmpty) {
        await _speechWithPause("Sekarang", pause: 400);
        await _speechWithPause("coba kamu ucapkan", pause: 300);
        await _speechWithPause(object, pause: 800);
      }
    }
    isSpeaking.value = false;
  }

  Future<void> _spellWord(String word) async {
    final syllables = _splitIntoSyllables(word); // Using the improved split

    await _speechWithPause(" ", pause: 500);

    for (int i = 0; i < syllables.length; i++) {
      // Beri penekanan berbeda di suku kata terakhir
      if (i == syllables.length - 1) {
        await _flutterTts.setPitch(1.3); // Naikkan pitch untuk penekanan
        await _flutterTts.speak(syllables[i]);
        await _flutterTts.setPitch(1.1); // Kembalikan ke normal
      } else {
        await _speechWithPause(syllables[i], pause: 400);
      }

      // Jeda lebih panjang antar suku kata
      if (i < syllables.length - 1) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  Future<void> _speechWithPause(String text, {int pause = 300}) async {
    await _flutterTts.speak(text);
    await Future.delayed(Duration(milliseconds: pause));
  }

  void _checkSpeechMatch() async {
    final input = recognizedText.value.toLowerCase().trim();
    final target = detectedObject.value.toLowerCase().trim();

    await _flutterTts.stop();

    if (input == target) {
      await _audioPlayer.play(AssetSource(correctAudio)); // Play correct sound
      // Feedback lebih ekspresif
      await _speechWithPause("Hore!", pause: 400);
      await _speechWithPause("Kamu benar!", pause: 300);
      await _speechWithPause("$target", pause: 400);
      await _speechWithPause("Ayo lanjutkan!", pause: 500);
      // SIMPAN KE RIWAYAT BELAJAR
      _saveLearningHistory(target);

      Get.dialog(_buildFeedbackDialog(true, target), barrierDismissible: false);
    } else {
      await _audioPlayer.play(AssetSource(wrongAudio)); // Play wrong sound
      // Feedback lebih mendukung
      await _speechWithPause("Oops...", pause: 500);
      await _speechWithPause("Hampir tepat!", pause: 400);
      await _speechWithPause("Coba lagi ya", pause: 600);

      Get.dialog(
        _buildFeedbackDialog(false, target),
        barrierDismissible: false,
      );
    }

    await Future.delayed(const Duration(seconds: 3));
    Get.back();
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
              padding: EdgeInsets.all(20),
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
                  SizedBox(height: 15),
                  Text(
                    isCorrect ? "Selamat!" : "Ayo coba lagi",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isCorrect ? Colors.green : Colors.orange,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    isCorrect
                        ? "Kamu berhasil mengucapkan\n\"$object\""
                        : "Ucapkan \"$object\"",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<String> _splitIntoSyllables(String word) {
    final key = word.toLowerCase().trim();
    if (pronunciationExceptions.containsKey(key)) {
      return pronunciationExceptions[key]!;
    } // Fallback: Jika tidak ditemukan, kembalikan satu suku kata utuh
    return [word];
  }

  void stopSpeaking() {
    _flutterTts.stop();
    _speechQueue.clear();
    isSpeaking.value = false;
  }

  Future<void> startListening(String expectedObject) async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == "done" || status == "notListening") {
          isListening.value = false;
          isProcessingSpeech.value = true;
          Future.delayed(const Duration(milliseconds: 500), () {
            _checkSpeechMatch();
            isProcessingSpeech.value = false;
          });
        }
      },
      onError: (error) {
        isListening.value = false;
        isProcessingSpeech.value = false;
        print("STT Error: $error");
        Get.snackbar("Error", "Gagal mendengarkan: $error");
      },
    );

    if (available) {
      isListening.value = true;
      recognizedText.value = "";
      _speech.listen(
        onResult: (result) {
          recognizedText.value = result.recognizedWords;
        },
        pauseFor: const Duration(seconds: 2),
        listenFor: const Duration(seconds: 5),
        localeId: "id_ID",
      );
    } else {
      Get.snackbar("Error", "Speech recognition not available");
    }
  }

  void resetAllSpeech() {
    stopSpeaking(); // Hentikan semua ucapan
    recognizedText.value = ""; // Reset teks yang diakui
    detectedObject.value = ""; // Reset objek terdeteksi
    isProcessingSpeech.value = false; // Reset status pemrosesan
    hasDetected.value = false; // Reset status deteksi
  }

  void stopListening() {
    _speech.stop();
    // No need to call _checkSpeechMatch here immediately, it will be called by onStatus "done"
  }

  @override
  void onClose() {
    stopSpeaking();
    _audioPlayer.dispose(); // Dispose audio player when controller closes
    _speech.cancel(); // Cancel any ongoing speech recognition
    super.onClose();
  }
}