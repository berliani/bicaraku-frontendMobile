import 'package:bicaraku/app/data/controllers/total_points_controller.dart';
import 'package:bicaraku/app/modules/f3_peoplespeak/views/challenge_view.dart';
import 'package:bicaraku/core/widgets/custom_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PeopleSpeakView extends StatelessWidget {
  final List<Map<String, dynamic>> levels = [
    {
      'previewImage': 'assets/images/f3.peoplespeak/2.png',
      'phrase': 'Mobil Merah',
      'interactiveImage': 'assets/images/f3.peoplespeak/video/mobilmerah2.mp4',
      'previewImageSmall': 'assets/images/f3.peoplespeak/c_2kata.png',
    },
    {
      'previewImage': 'assets/images/f3.peoplespeak/3.png',
      'phrase': 'Botol di Meja',
      'interactiveImage': 'assets/images/f3.peoplespeak/video/botoldimeja.mp4',
      'previewImageSmall': 'assets/images/f3.peoplespeak/c_3kata.png',
    },
    {
      'previewImage': 'assets/images/f3.peoplespeak/4.png',
      'phrase': 'Anjing Bermain dengan Bola',
      'interactiveImage': 'assets/images/f3.peoplespeak/video/anjingmainbola.mp4',
      'previewImageSmall': 'assets/images/f3.peoplespeak/c_4kata.png',
    },
    {
      'previewImage': 'assets/images/f3.peoplespeak/5.png',
      'phrase': 'Buku Tersusun Rapi di Rak',
      'interactiveImage': 'assets/images/f3.peoplespeak/video/bukudirak.mp4',
      'previewImageSmall': 'assets/images/f3.peoplespeak/c_5kata.png',
    },
    {
      'previewImage': 'assets/images/f3.peoplespeak/6.png',
      'phrase': 'Rusa Sedang Makan Rumput di Lapangan',
      'interactiveImage': 'assets/images/f3.peoplespeak/video/rusamakan.mp4',
      'previewImageSmall': 'assets/images/f3.peoplespeak/c_6kata2.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final pointsController = Get.put(TotalPointsController());

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pilih Latihan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Obx(() {
                    return Text(
                      '${pointsController.totalPoints.value} Poin',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.purple,
                      ),
                    );
                  }),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: levels.length,
                itemBuilder: (context, index) => _buildLevelCard(levels[index]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(),
    );
  }

  Widget _buildLevelCard(Map<String, dynamic> level) {
    return GestureDetector(
      onTap:
          () => Get.to(
            () => ChallengeView(
              phrase: level['phrase'],
              interactiveImage: level['interactiveImage'],
              previewImageSmall: level['previewImageSmall'], // Kirim previewImage
            ),
          ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
            image: AssetImage(level['previewImage']),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
      ),
    );
  }
}
