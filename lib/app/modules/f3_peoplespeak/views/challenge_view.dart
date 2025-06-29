import 'package:bicaraku/app/modules/f3_peoplespeak/controllers/peoplespeak_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

class ChallengeView extends StatefulWidget {
  final String phrase;
  final String interactiveImage;
  final String previewImageSmall; 

  const ChallengeView({
    super.key,
    required this.phrase,
    required this.interactiveImage,
    required this.previewImageSmall,
  });

  @override
  State<ChallengeView> createState() => _ChallengeViewState();
}

class _ChallengeViewState extends State<ChallengeView> {
  late BerbicaraController controller;
  late VideoPlayerController? _videoController;
  bool _showPopup = true;

  // Syllable mapping for pronunciation guidance
  final Map<String, String> syllableMap = {
    'Mobil Merah': 'Mo - bil | Me - rah',
    'Botol di Meja': 'Bo - tol | di | Me - ja',
    'Anjing Bermain dengan Bola':
        'An - jing | Ber - main | deng - an | Bo - la',
    'Buku Tersusun Rapi di Rak':
        'Bu - ku | Ter - su - sun | Ra - pi | di | Rak',
    'Rusa Sedang Makan Rumput di Lapangan':
        'Ru - sa | Se - dang | Ma - kan | Rum - put | di | La - pang - an',
  };

  @override
  void initState() {
    super.initState();
    controller = Get.put(BerbicaraController(), permanent: true);
    controller.currentSentence.value = widget.phrase;

    if (widget.interactiveImage.endsWith('.mp4')) {
      _videoController = VideoPlayerController.asset(widget.interactiveImage)
        ..initialize().then((_) {
          _videoController?.setLooping(true);
          _videoController?.play();
          setState(() {});
        });
    } else {
      _videoController = null;
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    final controller = Get.find<BerbicaraController>();
    controller.tts.stop();
    controller.speech.stop();
    controller.systemSyllable.value = "";
    controller.userSyllable.value = "";
    controller.syllableResults.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Latihan Pengucapan'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Video or interactive image
            Positioned.fill(
              child:
                  _videoController != null &&
                          _videoController!.value.isInitialized
                      ? VideoPlayer(_videoController!)
                      : Image.asset(widget.interactiveImage, fit: BoxFit.cover),
            ),

            // Pronunciation guide at the top
            if (!_showPopup)
              Positioned(
                top: 30,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(15),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Ucapkan:",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[200],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '"${widget.phrase}"',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),

                      // Tampilkan suku kata dengan feedback ganda
                      _buildDualHighlightSyllableGuide(),

                      const SizedBox(height: 5),
                      Obx(() {
                        final controller = Get.find<BerbicaraController>();
                        return Text(
                          controller.isPlayingInstruction.isTrue
                              ? "Sistem sedang membimbing pengucapan"
                              : controller.isListening.isTrue
                              ? "Silakan ucapkan kalimat di atas"
                              : "Ucapkan perlahan per suku kata",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            fontStyle: FontStyle.italic,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

            // Semi-transparent overlay
            if (_showPopup)
              Positioned.fill(child: Container(color: Colors.black54)),

            // Instruction popup
            if (_showPopup)
              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/iconuser.png',
                        width: 80,
                        height: 80,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Kamu akan mengucapkan:",
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          '"${widget.phrase}"',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        syllableMap[widget.phrase] ?? widget.phrase,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.blueGrey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Arahkan ke mikrofon dan ucapkan dengan jelas",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _showPopup = false;
                          });
                          controller.startPractice(widget.phrase);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Mulai",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Microphone button (only shown after popup is closed)
            if (!_showPopup)
              Positioned(
                bottom: 50,
                left: 0,
                right: 0,
                child: Center(
                  child: Obx(
                    () => FloatingActionButton.large(
                      onPressed: () => controller.toggleRecording(widget.previewImageSmall),
                      backgroundColor:
                          controller.isListening.value
                              ? Colors.red
                              : Theme.of(context).primaryColor,
                      child: Icon(
                        controller.isListening.value ? Icons.stop : Icons.mic,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDualHighlightSyllableGuide() {
    final controller = Get.find<BerbicaraController>();
    final syllables =
        controller.syllablePronunciations[widget.phrase] ?? [widget.phrase];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children:
          syllables.map((syllable) {
            return Obx(() {
              final isSystemActive =
                  controller.systemSyllable.value == syllable;
              final isUserActive = controller.userSyllable.value == syllable;
              final isCorrect = controller.syllableResults[syllable] ?? false;

              // Tentukan warna berdasarkan prioritas
              Color bgColor = Colors.transparent;
              Color borderColor = Colors.white54;
              Color textColor = Colors.orangeAccent;
              double borderWidth = 1;
              double scale = 1.0;

              // Prioritas: Sistem > Pengguna > Benar
              if (isSystemActive) {
                bgColor = Colors.amber.withOpacity(0.6);
                borderColor = Colors.orange;
                textColor = Colors.black;
                borderWidth = 2.5;
                scale = 1.15;
              } else if (isUserActive) {
                bgColor = Colors.blue.withOpacity(0.6);
                borderColor = Colors.lightBlueAccent;
                textColor = Colors.white;
                borderWidth = 2.0;
                scale = 1.1;
              } else if (isCorrect) {
                bgColor = Colors.green.withOpacity(0.5);
                borderColor = Colors.greenAccent;
                textColor = Colors.white;
                borderWidth = 1.5;
              }

              return AnimatedScale(
                duration: const Duration(milliseconds: 300),
                scale: scale,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor, width: borderWidth),
                    boxShadow:
                        isSystemActive || isUserActive
                            ? [
                              BoxShadow(
                                color: borderColor.withOpacity(0.5),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ]
                            : null,
                  ),
                  child: Text(
                    syllable,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),
              );
            });
          }).toList(),
    );
  }
}
