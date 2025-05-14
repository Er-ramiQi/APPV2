// lib/models/security_alert.dart
enum SecurityAlertSeverity {
  info,
  warning,
  critical,
}

enum SecurityAlertCategory {
  password,
  account,
  device,
  network,
  breach,
  other,
}

enum SecurityAlertSource {
  local,
  server,
  api,
}

class SecurityAlert {
  final String id;
  final String title;
  final String description;
  final SecurityAlertSeverity severity;
  final SecurityAlertCategory category;
  final SecurityAlertSource source;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime expiresAt;
  final DateTime? snoozedUntil;
  final bool read;
  final String? actionText;
  final String? actionRoute;
  final Map<String, dynamic>? metadata;

  SecurityAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.category,
    required this.source,
    required this.createdAt,
    required this.expiresAt,
    this.updatedAt,
    this.snoozedUntil,
    this.read = false,
    this.actionText,
    this.actionRoute,
    this.metadata,
  });

  // Vérifier si l'alerte est expirée
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  // Vérifier si l'alerte est reportée (snooze)
  bool get isSnoozed => snoozedUntil != null && DateTime.now().isBefore(snoozedUntil!);

  // Vérifier si l'alerte est active (non expirée et non reportée)
  bool get isActive => !isExpired && !isSnoozed;

  // Couleur associée à la sévérité (pour référence dans l'UI)
  String get severityColor {
    switch (severity) {
      case SecurityAlertSeverity.info:
        return 'blue';
      case SecurityAlertSeverity.warning:
        return 'orange';
      case SecurityAlertSeverity.critical:
        return 'red';
    }
  }

  // Icône associée à la catégorie (pour référence dans l'UI)
  String get categoryIcon {
    switch (category) {
      case SecurityAlertCategory.password:
        return 'lock';
      case SecurityAlertCategory.account:
        return 'person';
      case SecurityAlertCategory.device:
        return 'smartphone';
      case SecurityAlertCategory.network:
        return 'wifi';
      case SecurityAlertCategory.breach:
        return 'warning';
      case SecurityAlertCategory.other:
        return 'info';
    }
  }

  // Créer une copie avec des modifications
  SecurityAlert copyWith({
    String? id,
    String? title,
    String? description,
    SecurityAlertSeverity? severity,
    SecurityAlertCategory? category,
    SecurityAlertSource? source,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
    DateTime? snoozedUntil,
    bool? read,
    String? actionText,
    String? actionRoute,
    Map<String, dynamic>? metadata,
  }) {
    return SecurityAlert(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      category: category ?? this.category,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
      read: read ?? this.read,
      actionText: actionText ?? this.actionText,
      actionRoute: actionRoute ?? this.actionRoute,
      metadata: metadata ?? this.metadata,
    );
  }

  // Convertir en Map pour JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'severity': severity.toString().split('.').last,
      'category': category.toString().split('.').last,
      'source': source.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'snoozed_until': snoozedUntil?.toIso8601String(),
      'read': read,
      'action_text': actionText,
      'action_route': actionRoute,
      'metadata': metadata,
    };
  }

  // Créer à partir d'un Map JSON
  factory SecurityAlert.fromJson(Map<String, dynamic> json) {
    return SecurityAlert(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      severity: _parseSeverity(json['severity']),
      category: _parseCategory(json['category']),
      source: _parseSource(json['source']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      expiresAt: DateTime.parse(json['expires_at']),
      snoozedUntil: json['snoozed_until'] != null ? DateTime.parse(json['snoozed_until']) : null,
      read: json['read'] ?? false,
      actionText: json['action_text'],
      actionRoute: json['action_route'],
      metadata: json['metadata'],
    );
  }

  // Helpers pour parser les énumérations
  static SecurityAlertSeverity _parseSeverity(String value) {
    switch (value) {
      case 'info':
        return SecurityAlertSeverity.info;
      case 'warning':
        return SecurityAlertSeverity.warning;
      case 'critical':
        return SecurityAlertSeverity.critical;
      default:
        return SecurityAlertSeverity.info;
    }
  }

  static SecurityAlertCategory _parseCategory(String value) {
    switch (value) {
      case 'password':
        return SecurityAlertCategory.password;
      case 'account':
        return SecurityAlertCategory.account;
      case 'device':
        return SecurityAlertCategory.device;
      case 'network':
        return SecurityAlertCategory.network;
      case 'breach':
        return SecurityAlertCategory.breach;
      case 'other':
      default:
        return SecurityAlertCategory.other;
    }
  }

  static SecurityAlertSource _parseSource(String value) {
    switch (value) {
      case 'local':
        return SecurityAlertSource.local;
      case 'server':
        return SecurityAlertSource.server;
      case 'api':
        return SecurityAlertSource.api;
      default:
        return SecurityAlertSource.local;
    }
  }
}