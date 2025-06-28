class ActivityHistory {
  final String id;
  final String title;
  final String image;
  final DateTime date;
  final bool isCompleted;
  final String instruksi;
  final int points;

  ActivityHistory({
    required this.id,
    required this.title,
    required this.image,
    required this.date,
    required this.isCompleted,
    required this.instruksi,
    required this.points,
  });

  factory ActivityHistory.fromJson(Map<String, dynamic> json) {
    return ActivityHistory(
      id: json['id'],
      title: json['title'],
      image: json['image'],
      date: DateTime.parse(json['date']),
      isCompleted: json['isCompleted'],
      instruksi: json['instruksi'],
      points: json['points'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'image': image,
      'date': date.toIso8601String(),
      'isCompleted': isCompleted,
      'instruksi': instruksi,
      'points': points,
    };
  }
}