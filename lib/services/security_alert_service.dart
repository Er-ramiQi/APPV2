// lib/services/security_alert_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'secure_storage_service.dart';
import 'api_service.dart';
import 'password_service.dart';
import '../models/security_alert.dart';

class SecurityAlertService {
  // Singleton
  static final SecurityAlertService _instance = SecurityAlertService._internal();
  factory SecurityAlertService() => _instance;
  SecurityAlertService._internal();

  final SecureStorageService _secureStorage = SecureStorageService();
  final ApiService _apiService = ApiService();
  final PasswordService _passwordService = PasswordService();
  
  // Intervalle de vérification des alertes (en heures)
  static const int _alertCheckIntervalHours = 12;
  
  // Timer pour les vérifications périodiques
  Timer? _alertCheckTimer;
  
  // Liste des alertes actives
  List<SecurityAlert> _activeAlerts = [];
  
  // Stream controller pour notifier des changements
  final _alertsStreamController = StreamController<List<SecurityAlert>>.broadcast();
  
  // Stream pour écouter les mises à jour des alertes
  Stream<List<SecurityAlert>> get alertsStream => _alertsStreamController.stream;
  
  // Getter pour les alertes actives
  List<SecurityAlert> get activeAlerts => List.unmodifiable(_activeAlerts);

  // Initialiser le service
  Future<void> initialize() async {
    try {
      // Charger les alertes stockées localement
      await _loadStoredAlerts();
      
      // Première vérification des alertes
      await checkForSecurityAlerts();
      
      // Configurer une vérification périodique
      _alertCheckTimer = Timer.periodic(
        Duration(hours: _alertCheckIntervalHours),
        (_) => checkForSecurityAlerts(),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de l\'initialisation du service d\'alertes: $e');
      }
    }
  }

  // Libérer les ressources
  void dispose() {
    _alertCheckTimer?.cancel();
    _alertsStreamController.close();
  }

  // Charger les alertes stockées localement
  Future<void> _loadStoredAlerts() async {
    try {
      final String? storedAlertsJson = await _secureStorage.getSecuritySetting('security_alerts');
      
      if (storedAlertsJson != null && storedAlertsJson.isNotEmpty) {
        final List<dynamic> alertsData = jsonDecode(storedAlertsJson);
        _activeAlerts = alertsData.map((data) => SecurityAlert.fromJson(data)).toList();
        
        // Filtrer les alertes expirées
        _activeAlerts = _activeAlerts.where((alert) => !alert.isExpired).toList();
        
        // Notifier les écouteurs
        _alertsStreamController.add(_activeAlerts);
      }
    } catch (e) {
      // Initialiser une liste vide en cas d'erreur
      _activeAlerts = [];
    }
  }

  // Sauvegarder les alertes localement
  Future<void> _storeAlerts() async {
    try {
      // Filtrer les alertes expirées avant de sauvegarder
      final alertsToStore = _activeAlerts.where((alert) => !alert.isExpired).toList();
      
      final String alertsJson = jsonEncode(alertsToStore.map((a) => a.toJson()).toList());
      await _secureStorage.saveSecuritySetting('security_alerts', alertsJson);
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la sauvegarde des alertes: $e');
      }
    }
  }

  // Vérifier les alertes de sécurité
  Future<void> checkForSecurityAlerts() async {
    try {
      // Vérifier d'abord les alertes locales (mots de passe réutilisés, faibles, etc.)
      await _checkLocalSecurityIssues();
      
      // Vérifier les alertes en ligne si une connexion est disponible
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        await _checkOnlineSecurityAlerts();
      }
      
      // Mise à jour du stockage
      await _storeAlerts();
      
      // Notifier les écouteurs
      _alertsStreamController.add(_activeAlerts);
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la vérification des alertes: $e');
      }
    }
  }

  // Vérifier les problèmes de sécurité locaux
  Future<void> _checkLocalSecurityIssues() async {
    // Obtenir les statistiques des mots de passe
    final stats = await _passwordService.getPasswordStatistics();
    
    // Alerter pour les mots de passe faibles
    if (stats['weak_passwords'] > 0) {
      _addOrUpdateAlert(
        SecurityAlert(
          id: 'weak_passwords',
          title: 'Mots de passe faibles détectés',
          description: 'Vous avez ${stats['weak_passwords']} mot(s) de passe considéré(s) comme faible(s). Renforcez-les pour améliorer votre sécurité.',
          severity: SecurityAlertSeverity.warning,
          source: SecurityAlertSource.local,
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 30)),
          category: SecurityAlertCategory.password,
          actionText: 'Renforcer mes mots de passe',
          actionRoute: '/security/weak-passwords',
        ),
      );
    }
    
    // Alerter pour les mots de passe réutilisés
    if (stats['reused_passwords'] > 0) {
      _addOrUpdateAlert(
        SecurityAlert(
          id: 'reused_passwords',
          title: 'Mots de passe réutilisés',
          description: 'Vous utilisez le même mot de passe pour ${stats['reused_passwords']} comptes différents. Utilisez des mots de passe uniques pour chaque compte.',
          severity: SecurityAlertSeverity.warning,
          source: SecurityAlertSource.local,
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 14)),
          category: SecurityAlertCategory.password,
          actionText: 'Voir les détails',
          actionRoute: '/security/reused-passwords',
        ),
      );
    }
    
    // Alerter pour les mots de passe anciens
    if (stats['outdated_passwords'] > 0) {
      _addOrUpdateAlert(
        SecurityAlert(
          id: 'outdated_passwords',
          title: 'Mots de passe obsolètes',
          description: 'Vous avez ${stats['outdated_passwords']} mot(s) de passe qui n\'ont pas été modifiés depuis plus de 90 jours.',
          severity: SecurityAlertSeverity.info,
          source: SecurityAlertSource.local,
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 7)),
          category: SecurityAlertCategory.password,
          actionText: 'Voir les détails',
          actionRoute: '/security/outdated-passwords',
        ),
      );
    }
  }

  // Vérifier les alertes en ligne
  Future<void> _checkOnlineSecurityAlerts() async {
    try {
      // Appel à l'API pour récupérer les alertes de sécurité
      final response = await _apiService.get('/security/alerts');
      
      if (response.statusCode == 200) {
        final List<dynamic> alertsData = jsonDecode(response.body);
        
        for (var alertData in alertsData) {
          final alert = SecurityAlert.fromJson(alertData);
          
          // Ajouter ou mettre à jour l'alerte
          _addOrUpdateAlert(alert);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la récupération des alertes en ligne: $e');
      }
    }
  }

  // Ajouter ou mettre à jour une alerte
  void _addOrUpdateAlert(SecurityAlert alert) {
    // Vérifier si l'alerte n'est pas expirée
    if (alert.isExpired) return;
    
    // Vérifier si l'alerte existe déjà
    final existingIndex = _activeAlerts.indexWhere((a) => a.id == alert.id);
    
    if (existingIndex >= 0) {
      // Mettre à jour l'alerte existante
      _activeAlerts[existingIndex] = alert;
    } else {
      // Ajouter la nouvelle alerte
      _activeAlerts.add(alert);
    }
  }

  // Marquer une alerte comme lue
  Future<void> markAlertAsRead(String alertId) async {
    final index = _activeAlerts.indexWhere((a) => a.id == alertId);
    
    if (index >= 0) {
      final alert = _activeAlerts[index];
      final updatedAlert = alert.copyWith(
        read: true,
        updatedAt: DateTime.now(),
      );
      
      _activeAlerts[index] = updatedAlert;
      
      // Sauvegarder et notifier
      await _storeAlerts();
      _alertsStreamController.add(_activeAlerts);
    }
  }

  // Ignorer une alerte (la masquer)
  Future<void> dismissAlert(String alertId) async {
    _activeAlerts.removeWhere((a) => a.id == alertId);
    
    // Sauvegarder et notifier
    await _storeAlerts();
    _alertsStreamController.add(_activeAlerts);
  }

  // Ignorer temporairement une alerte (jusqu'à la prochaine vérification)
  Future<void> snoozeAlert(String alertId, {Duration duration = const Duration(days: 1)}) async {
    final index = _activeAlerts.indexWhere((a) => a.id == alertId);
    
    if (index >= 0) {
      final alert = _activeAlerts[index];
      final updatedAlert = alert.copyWith(
        snoozedUntil: DateTime.now().add(duration),
        updatedAt: DateTime.now(),
      );
      
      _activeAlerts[index] = updatedAlert;
      
      // Sauvegarder et notifier
      await _storeAlerts();
      _alertsStreamController.add(_activeAlerts);
    }
  }

  // Obtenir le nombre d'alertes par sévérité
  Map<SecurityAlertSeverity, int> getAlertCountsBySeverity() {
    final counts = <SecurityAlertSeverity, int>{
      SecurityAlertSeverity.info: 0,
      SecurityAlertSeverity.warning: 0,
      SecurityAlertSeverity.critical: 0,
    };
    
    for (var alert in _activeAlerts) {
      if (!alert.isExpired && !alert.isSnoozed) {
        counts[alert.severity] = (counts[alert.severity] ?? 0) + 1;
      }
    }
    
    return counts;
  }

  // Obtenir le nombre total d'alertes non lues
  int getUnreadAlertCount() {
    return _activeAlerts.where((a) => !a.read && !a.isExpired && !a.isSnoozed).length;
  }

  // Obtenir les alertes par catégorie
  List<SecurityAlert> getAlertsByCategory(SecurityAlertCategory category) {
    return _activeAlerts
        .where((a) => a.category == category && !a.isExpired && !a.isSnoozed)
        .toList();
  }

  // Obtenir les alertes critiques
  List<SecurityAlert> getCriticalAlerts() {
    return _activeAlerts
        .where((a) => a.severity == SecurityAlertSeverity.critical && !a.isExpired && !a.isSnoozed)
        .toList();
  }
}