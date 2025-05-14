// models/password_item.dart
class PasswordItem {
  final String id;
  final String title;
  final String username;
  final String password;
  final String website;
  final String notes;
  final DateTime createdAt;
  final DateTime lastModified;
  final String category; // Catégorie du mot de passe
  final bool isFavorite; // Marquer comme favori
  final int strengthScore; // Score de sécurité du mot de passe
  final bool isDeleted; // Flag pour la corbeille
  final String icon; // Icône personnalisée
  final Map<String, dynamic> customFields; // Champs personnalisés

  PasswordItem({
    required this.id,
    required this.title,
    required this.username,
    required this.password,
    this.website = '',
    this.notes = '',
    required this.createdAt,
    required this.lastModified,
    this.category = 'general',
    this.isFavorite = false,
    this.strengthScore = 0,
    this.isDeleted = false,
    this.icon = '',
    this.customFields = const {},
  });

  // Méthode pour créer un objet PasswordItem à partir de JSON
  factory PasswordItem.fromJson(Map<String, dynamic> json) {
    return PasswordItem(
      id: json['id'],
      title: json['title'],
      username: json['username'],
      password: json['password'],
      website: json['website'] ?? '',
      notes: json['notes'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      lastModified: DateTime.parse(json['lastModified']),
      category: json['category'] ?? 'general',
      isFavorite: json['isFavorite'] ?? false,
      strengthScore: json['strengthScore'] ?? 0,
      isDeleted: json['isDeleted'] ?? false,
      icon: json['icon'] ?? '',
      customFields: json['customFields'] ?? {},
    );
  }

  // Méthode pour convertir un objet PasswordItem en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'username': username,
      'password': password,
      'website': website,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
      'category': category,
      'isFavorite': isFavorite,
      'strengthScore': strengthScore,
      'isDeleted': isDeleted,
      'icon': icon,
      'customFields': customFields,
    };
  }

  // Créer une copie avec modifications
  PasswordItem copyWith({
    String? id,
    String? title,
    String? username,
    String? password,
    String? website,
    String? notes,
    DateTime? createdAt,
    DateTime? lastModified,
    String? category,
    bool? isFavorite,
    int? strengthScore,
    bool? isDeleted,
    String? icon,
    Map<String, dynamic>? customFields,
  }) {
    return PasswordItem(
      id: id ?? this.id,
      title: title ?? this.title,
      username: username ?? this.username,
      password: password ?? this.password,
      website: website ?? this.website,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      strengthScore: strengthScore ?? this.strengthScore,
      isDeleted: isDeleted ?? this.isDeleted,
      icon: icon ?? this.icon,
      customFields: customFields ?? this.customFields,
    );
  }

  // Calculer la force du mot de passe (0-100)
  int calculatePasswordStrength() {
    int score = 0;
    
    // Longueur (jusqu'à 30 points)
    score += password.length * 2;
    if (score > 30) score = 30;
    
    // Diversité des caractères (jusqu'à 70 points)
    if (password.contains(RegExp(r'[A-Z]'))) score += 15;
    if (password.contains(RegExp(r'[a-z]'))) score += 15;
    if (password.contains(RegExp(r'[0-9]'))) score += 15;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score += 25;
    
    // Limiter à 100
    if (score > 100) score = 100;
    
    return score;
  }

  // Obtenir la catégorie de force du mot de passe
  String getPasswordStrengthCategory() {
    final int score = strengthScore > 0 ? strengthScore : calculatePasswordStrength();
    
    if (score < 40) return 'Faible';
    if (score < 70) return 'Moyen';
    return 'Fort';
  }

  // Obtenir la couleur associée à la force du mot de passe
  // Utilisable avec MaterialColor en Flutter
  String getPasswordStrengthColor() {
    final int score = strengthScore > 0 ? strengthScore : calculatePasswordStrength();
    
    if (score < 40) return 'red';
    if (score < 70) return 'orange';
    return 'green';
  }
}