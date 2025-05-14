// models/user.dart
class User {
  final String id;
  final String name;
  final String email;
  final String photoUrl;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final bool isEmailVerified;
  final String role; // 'admin', 'user', etc.
  final Map<String, dynamic> settings; // préférences utilisateur

  User({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl = '',
    required this.createdAt,
    required this.lastLoginAt,
    this.isEmailVerified = false,
    this.role = 'user',
    this.settings = const {},
  });

  // Méthode pour créer un objet User à partir de JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      photoUrl: json['photoUrl'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      lastLoginAt: DateTime.parse(json['lastLoginAt']),
      isEmailVerified: json['isEmailVerified'] ?? false,
      role: json['role'] ?? 'user',
      settings: json['settings'] ?? {},
    );
  }

  // Méthode pour convertir un objet User en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'isEmailVerified': isEmailVerified,
      'role': role,
      'settings': settings,
    };
  }

  // Créer une copie avec modifications
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isEmailVerified,
    String? role,
    Map<String, dynamic>? settings,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      role: role ?? this.role,
      settings: settings ?? this.settings,
    );
  }
}