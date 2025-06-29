class LearningHistoryEntry {
  final String id;
  final String object;
  final DateTime timestamp;

  LearningHistoryEntry({
    required this.id,
    required this.object,
    required this.timestamp,
  });

  factory LearningHistoryEntry.fromJson(Map<String, dynamic> json) {
    return LearningHistoryEntry(
      id: json['id'],
      object: json['object'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'object': object,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}