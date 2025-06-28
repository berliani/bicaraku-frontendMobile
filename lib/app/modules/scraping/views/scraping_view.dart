import 'dart:convert';
import 'package:bicaraku/app/modules/f1_looknhear/controllers/looknhear_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:bicaraku/core/widgets/custom_bottom_nav.dart';

const List<String> stopWords = [
  'yang',
  'dan',
  'di',
  'ke',
  'dari',
  'untuk',
  'dengan',
  'atau',
  'pada',
  'oleh',
  'sebagai',
  'adalah',
  'itu',
  'ini',
  'saat',
  'karena',
  'dalam',
  'juga',
  'agar',
  'bagi',
  'maka',
  'sebuah',
  'lebih',
  'kurang',
  'tersebut',
  'akan',
  'telah',
  'bila',
  'bisa',
  'mungkin',
  'mulai',
  'kecil',
];

class ScrapingView extends StatefulWidget {
  const ScrapingView({super.key});

  @override
  State<ScrapingView> createState() => _ScrapingViewState();
}

class _ScrapingViewState extends State<ScrapingView> {
  int _selectedTabIndex = 0; // Changed to 0 for Riwayat Belajar
  bool showVisualization = true;
  List<dynamic> articles = [];
  Map<String, dynamic> keywords = {};
  bool isLoading = true;

  final LooknhearController looknhearController = Get.put(
    LooknhearController(),
  );

  @override
  void initState() {
    super.initState();
    fetchScrapingData();
  }

  Widget buildTabButton(int index, String title, Color? activeColor) {
    final bool isSelected = _selectedTabIndex == index;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: SizedBox(
        width: 110,
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              _selectedTabIndex = index;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? activeColor : Colors.grey[300],
            foregroundColor: isSelected ? Colors.white : Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10),
            elevation: isSelected ? 4 : 0,
            shadowColor: isSelected ? activeColor : Colors.transparent,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Future<void> fetchScrapingData() async {
    final response = await http.get(
      Uri.parse("https://fadiyahdesi-scraping.hf.space/api/dashboard"),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        articles = data['articles'];
        keywords = Map<String, dynamic>.from(data['keywords']);
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Map<String, int> get articleCountBySource {
    final map = <String, int>{};
    for (var article in articles) {
      final source = article['source'];
      map[source] = (map[source] ?? 0) + 1;
    }
    return map;
  }

  Widget buildBarChart() {
    final items =
        keywords.entries
            .where((entry) => !stopWords.contains(entry.key.toLowerCase()))
            .toList();

    if (items.isEmpty) return const Text("Tidak ada data keyword");

    items.sort((a, b) => (b.value as int).compareTo(a.value as int));
    final topItems = items.take(7).toList();
    final max = topItems.first.value as int;

    // Hitung kelipatan 100 terdekat ke atas
    final yStep = 100;
    final yMax = ((max / yStep).ceil()) * yStep;

    return SizedBox(
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Sumbu Y
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              (yMax ~/ yStep) + 1,
              (index) => SizedBox(
                height: 150 / (yMax ~/ yStep),
                child: Text(
                  '${yMax - (index * yStep)}',
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Bar Chart
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children:
                  topItems.map((entry) {
                    final label = entry.key;
                    final value = entry.value as int;
                    final barHeight = (value / yMax) * 150;

                    return Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: barHeight,
                            width: 12,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(
                                255,
                                255,
                                241,
                                51,
                              ).withOpacity(0.7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            label,
                            style: const TextStyle(fontSize: 10),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildKeywordGrid() {
    final filteredItems =
        keywords.entries
            .where((entry) => !stopWords.contains(entry.key.toLowerCase()))
            .toList();

    if (filteredItems.isEmpty) return const Text("Tidak ada keyword.");

    filteredItems.sort((a, b) => (b.value as int).compareTo(a.value as int));
    final max = filteredItems.first.value as int;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          filteredItems.map((entry) {
            final scale = (entry.value as int) / max;
            final fontSize = 14.0 + (scale * 16); // 14 - 30
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1 + (scale * 0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                entry.key,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget buildPieChart() {
    final data = articleCountBySource;
    final total = data.values.fold(0, (a, b) => a + b);
    if (data.isEmpty) return const Text("Tidak ada data artikel.");

    final Map<String, Color> sourceColors = {
      "Haibunda": const Color.fromARGB(255, 255, 155, 74),
      "Wikipedia": Colors.purpleAccent,
      "Hellosehat": const Color.fromARGB(255, 255, 241, 51),
    };

    return SizedBox(
      height: 200,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children:
            data.entries.map((e) {
              final percent = ((e.value / total) * 100).toStringAsFixed(1);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: sourceColors[e.key] ?? Colors.grey,
                    child: Text(
                      "${e.value}",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${e.key} ($percent%)",
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              );
            }).toList(),
      ),
    );
  }

  Widget buildVisualizationView() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      children: [
        const Text(
          "Top Keywords",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        buildBarChart(),
        const SizedBox(height: 20),

        const Text(
          "Total Artikel",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        buildPieChart(),

        const Text(
          "Tag Cloud",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        buildKeywordGrid(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget buildArticleView() {
    final filteredArticles =
        articles.where((article) {
          final url = article['url'] as String?;
          return url != null && url.isNotEmpty;
        }).toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      itemCount: filteredArticles.length,
      itemBuilder: (context, index) {
        final article = filteredArticles[index];
        final title = article['title'] ?? '';
        final source = article['source'] ?? '';
        final url = article['url'] ?? '';

        return GestureDetector(
          onTap: () async {
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.platformDefault);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tidak bisa membuka link')),
              );
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Icon(Icons.open_in_new, color: Colors.purple),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  "Sumber: $source",
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===== TAMBAHKAN METHOD UNTUK RIWAYAT BELAJAR =====
  Widget buildLearningHistoryView() {
    return Obx(() {
      if (looknhearController.learningHistory.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/emptyhistory.png',
                width: 180,
                height: 180,
              ),
              const SizedBox(height: 20),
              const Text(
                'Belum ada riwayat belajar',
                style: TextStyle(fontSize: 16, color: Color.fromARGB(179, 0, 0, 0)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Get.toNamed("/looknhear"); // Kembali ke halaman utama
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent[100],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text('Mulai Belajar'),
              ),
            ],
          ),
        );
      }

      return Column(
        children: [
          // TOMBOL HAPUS RIWAYAT
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16, top: 8),
              child: ElevatedButton.icon(
                onPressed: () {
                  _showClearHistoryDialog();
                },
                icon: const Icon(Icons.delete, size: 20),
                label: const Text('Hapus Riwayat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),

          // GRAFIK DAN DAFTAR RIWAYAT
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Objek Paling Sering Dipelajari',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 0, 0, 0),
                  ),
                ),
                const SizedBox(height: 16),
                _buildBarChartForLearningHistory(),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Riwayat Belajar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                    ),
                    Text(
                      'Total: ${looknhearController.learningHistory.length}',
                      style: const TextStyle(
                        color: Color.fromARGB(179, 0, 0, 0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildHistoryList(),
              ],
            ),
          ),
        ],
      );
    });
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Hapus Riwayat"),
          content: const Text(
            "Apakah Anda yakin ingin menghapus semua riwayat belajar?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            TextButton(
              onPressed: () {
                looknhearController.clearLearningHistory();
                Navigator.pop(context);
              },
              child: const Text("Hapus", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBarChartForLearningHistory() {
    final items = looknhearController.mostDetectedObjects.entries.toList();
    if (items.isEmpty) {
      return const Center(
        child: Text(
          "Belum ada riwayat belajar",
          style: TextStyle(color: Color.fromARGB(179, 0, 0, 0)),
        ),
      );
    }
    items.sort((a, b) => b.value.compareTo(a.value));
    final max = items.first.value.toDouble();

    // Daftar warna untuk setiap batang
    final List<Color> barColors = [
      Colors.pinkAccent.shade100,
      Colors.blueAccent.shade100,
      Colors.greenAccent.shade100,
      Colors.amberAccent.shade100,
      Colors.purpleAccent.shade100,
      Colors.cyanAccent.shade100,
      Colors.deepOrangeAccent.shade100,
      Colors.limeAccent.shade100,
      Colors.indigoAccent.shade100,
      Colors.tealAccent.shade100,
    ];

    return Container(
      height: 260, // Tinggi ditambah untuk menampung label
      padding: const EdgeInsets.only(top: 16, bottom: 24),
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children:
                items.asMap().entries.map((entryWithIndex) {
                  final index = entryWithIndex.key;
                  final entry = entryWithIndex.value;
                  final heightPercent = entry.value / max;
                  final color = barColors[index % barColors.length];
                  final objectName = entry.key;
                  final count = entry.value;

                  return Container(
                    width: 70, // Lebar cukup untuk nama objek
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Nilai count di atas batang
                        Text(
                          '$count',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(179, 126, 126, 126),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Batang grafik
                        Container(
                          height: 150 * heightPercent,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                            gradient: LinearGradient(
                              colors: [color, color.withOpacity(0.7)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Nama objek di bawah batang
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 6,
                          ),
                          child: Text(
                            objectName,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color.fromARGB(255, 18, 18, 18),
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return Obx(() {
      // Pastikan controller sudah diinisialisasi

      return ListView.builder(
        shrinkWrap: true,

        physics: const NeverScrollableScrollPhysics(),

        itemCount: looknhearController.learningHistory.length,

        itemBuilder: (context, index) {
          final entry = looknhearController.learningHistory[index];

          // PERBAIKAN: Handle kemungkinan format timestamp invalid

          DateTime date;

          try {
            date = DateTime.parse(entry['timestamp']);
          } catch (e) {
            date = DateTime.now();
          }

          return Dismissible(
            key: Key(entry['timestamp']),

            background: Container(
              color: Colors.red,

              alignment: Alignment.centerRight,

              padding: const EdgeInsets.only(right: 20),

              child: const Icon(Icons.delete, color: Colors.white),
            ),

            direction: DismissDirection.endToStart,

            confirmDismiss: (direction) async {
              return await showDialog(
                context: context,

                builder:
                    (context) => AlertDialog(
                      title: const Text("Hapus Item"),

                      content: const Text(
                        "Apakah Anda yakin ingin menghapus item ini?",
                      ),

                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),

                          child: const Text("Batal"),
                        ),

                        TextButton(
                          onPressed: () => Navigator.pop(context, true),

                          child: const Text(
                            "Hapus",

                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
              );
            },

            onDismissed: (direction) {
              looknhearController.removeHistoryItem(index);
            },

            child: Card(
              child: ListTile(
                title: Text(entry['object'] ?? 'Unknown Object'), // Handle null

                subtitle: Text(
                  '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                ),

                leading: const Icon(Icons.history, color: Colors.purple),
              ),
            ),
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( 
      backgroundColor: Colors.white,

      bottomNavigationBar: const CustomBottomNav(),

      body: SafeArea(
        child: Column(
          children: [
            // ROW: Tombol Back dan Tombol-Tombol Tab
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,

                vertical: 12,
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  // Tombol Back dan Judul
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),

                        onPressed: () => Get.back(),
                      ),

                      const SizedBox(width: 4),

                      const Text(
                        'Infografis',

                        style: TextStyle(
                          fontSize: 20,

                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Tab Bar (horizontal scrollable)
                  SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      children: [
                        buildTabButton(
                          0,
                          'Riwayat Belajar',
                          Colors.pinkAccent[100],
                        ),
                        const SizedBox(width: 8),
                        buildTabButton(1, 'Visualisasi', Colors.purple[300]),
                        const SizedBox(width: 8),
                        buildTabButton(2, 'Artikel', Colors.orangeAccent),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // BODY CONTENT
            Expanded(
              child:
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _selectedTabIndex == 0
                      ? buildLearningHistoryView()
                      : _selectedTabIndex == 1
                      ? buildVisualizationView()
                      : buildArticleView(),
            ),
          ],
        ),
      ),
    );
  }
}
