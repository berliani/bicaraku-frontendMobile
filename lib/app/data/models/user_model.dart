class UserModel {
  final String id;
  final String name;
  final String email;
  final String provider;
  String photoUrl;
  final String? lastLogin;
  int points;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.provider,
    required this.photoUrl,
    this.lastLogin,
    this.points = 0,
  });

  /// Factory untuk parsing dari JSON (pastikan semua dipaksa ke String)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Normalisasi _id (ObjectId atau String)
    final id = json['_id']?.toString() ?? '';

    // Normalisasi provider
    final rawProvider = json['provider']?.toString().toLowerCase() ?? 'email';
    final provider = rawProvider.contains('google') ? 'google' : 'email';

    // Normalisasi photoUrl
    String photoUrl = json['photoUrl']?.toString() ?? '';
    if (photoUrl.isEmpty) {
      // Default foto jika kosong
      photoUrl = 'https://ui-avatars.com/api/?name=User';
    }

    // lastLogin bisa DateTime atau String
    final lastLogin = json['lastLogin']?.toString();

    // points default 0
    final points = json['points'] as int? ?? 0;

    return UserModel(
      id: id,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      provider: provider,
      photoUrl: photoUrl,
      lastLogin: lastLogin,
      points: points,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': id,
      'name': name,
      'email': email,
      'provider': provider,
      'photoUrl': photoUrl,
      'lastLogin': lastLogin,
      'points': points,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? provider,
    String? photoUrl,
    String? lastLogin,
    int? points,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      provider: provider ?? this.provider,
      photoUrl: photoUrl ?? this.photoUrl,
      lastLogin: lastLogin ?? this.lastLogin,
      points: points ?? this.points,
    );
  }
}
