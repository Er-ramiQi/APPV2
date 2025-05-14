// lib/services/threat_detection_service.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:root_check/root_check.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'secure_storage_service.dart';
import 'api_service.dart';

/// Service de détection et gestion des menaces pour l'application
class ThreatDetectionService {
  // Singleton
  static final ThreatDetectionService _instance = ThreatDetectionService._internal();
  factory ThreatDetectionService() => _instance;
  ThreatDetectionService._internal();

  final SecureStorageService _secureStorage = SecureStorageService();
  final ApiService _apiService = ApiService();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  
  // Niveau de risque
  enum ThreatLevel { none, low, medium, high, critical }
  
  // État actuel des menaces
  ThreatLevel _currentThreatLevel = ThreatLevel.none;
  List<String> _activeThreatDescriptions = [];
  
  // Timer pour les vérifications périodiques
  Timer? _threatCheckTimer;
  
  // Initialisé ?
  bool _isInitialized = false;

  // Getters
  ThreatLevel get currentThreatLevel => _currentThreatLevel;
  List<String> get activeThreatDescriptions => List.unmodifiable(_activeThreatDescriptions);
  bool get isHighRisk => _currentThreatLevel == ThreatLevel.high || 
                         _currentThreatLevel == ThreatLevel.critical;

  // Initialiser le service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Première vérification des menaces
      await checkForThreats();
      
      // Configurer une vérification périodique toutes les 5 minutes
      _threatCheckTimer = Timer.periodic(
        const Duration(minutes: 5),
        (_) => checkForThreats(),
      );
      
      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de l\'initialisation du service de détection des menaces: $e');
      }
    }
  }

  // Libérer les ressources
  void dispose() {
    _threatCheckTimer?.cancel();
  }

  // Vérifier la présence de menaces
  Future<ThreatLevel> checkForThreats() async {
    try {
      _activeThreatDescriptions = [];
      int threatScore = 0;
      
      // Vérifications diverses
      final isRooted = await RootCheck.isRooted ?? false;
      final isEmulator = await _isEmulator();
      final isDevMode = await _isInDeveloperMode();
      final isDebuggerAttached = _isDebuggerAttached();
      final tamperingDetected = await _detectTampering();
      final networkIssues = await _checkNetworkSecurity();
      
      // Attribution des scores de risque
      if (isRooted) {
        threatScore += 70;  // Risque très élevé
        _activeThreatDescriptions.add('Appareil rooté détecté');
      }
      
      if (isEmulator) {
        threatScore += 40;  // Risque modéré
        _activeThreatDescriptions.add('Application exécutée sur un émulateur');
      }
      
      if (isDevMode) {
        threatScore += 20;  // Risque faible
        _activeThreatDescriptions.add('Mode développeur activé');
      }
      
      if (isDebuggerAttached) {
        threatScore += 60;  // Risque élevé
        _activeThreatDescriptions.add('Débogueur détecté');
      }
      
      if (tamperingDetected) {
        threatScore += 80;  // Risque très élevé
        _activeThreatDescriptions.add('Altération de l\'application détectée');
      }
      
      if (networkIssues) {
        threatScore += 50;  // Risque élevé
        _activeThreatDescriptions.add('Problème de sécurité réseau détecté');
      }
      
      // Actualiser le niveau de menace en fonction du score
      if (threatScore >= 80) {
        _currentThreatLevel = ThreatLevel.critical;
      } else if (threatScore >= 60) {
        _currentThreatLevel = ThreatLevel.high;
      } else if (threatScore >= 30) {
        _currentThreatLevel = ThreatLevel.medium;
      } else if (threatScore > 0) {
        _currentThreatLevel = ThreatLevel.low;
      } else {
        _currentThreatLevel = ThreatLevel.none;
      }
      
      // Enregistrer l'état des menaces
      await _logThreatStatus();
      
      // Rapport au serveur si en ligne (pour les menaces élevées)
      if (_currentThreatLevel == ThreatLevel.high || 
          _currentThreatLevel == ThreatLevel.critical) {
        await _reportThreatToServer();
      }
      
      return _currentThreatLevel;
    } catch (e) {
      // En cas d'erreur, considérer un risque moyen par précaution
      _currentThreatLevel = ThreatLevel.medium;
      _activeThreatDescriptions = ['Erreur lors de la vérification des menaces'];
      return _currentThreatLevel;
    }
  }

  // Vérifier si l'application s'exécute sur un émulateur
  Future<bool> _isEmulator() async {
    try {
      if (!Platform.isAndroid) return false;
      
      final androidInfo = await _deviceInfo.androidInfo;
      
      // Combinaison de plusieurs indicateurs
      final bool isEmulator = androidInfo.isPhysicalDevice == false ||
                              androidInfo.product.contains('sdk') ||
                              androidInfo.fingerprint.contains('generic') ||
                              androidInfo.model.contains('Emulator') ||
                              androidInfo.model.contains('Android SDK');
                              
      return isEmulator;
    } catch (e) {
      return false;
    }
  }

  // Vérifier si le mode développeur est activé
  // Note: Cette méthode nécessite une implémentation native complète pour être fiable
  Future<bool> _isInDeveloperMode() async {
    try {
      // Implémentation simplifiée, à remplacer par un canal natif pour Android
      return false;
    } catch (e) {
      return false;
    }
  }

  // Vérifier si un débogueur est attaché
  bool _isDebuggerAttached() {
    // En développement, toujours retourner false
    if (kDebugMode) return false;
    
    // Cette méthode est simplifiée et nécessite une implémentation native
    return false;
  }

  // Détecter toute modification de l'application
  Future<bool> _detectTampering() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String appVersion = packageInfo.version;
      final String buildNumber = packageInfo.buildNumber;
      
      // Vérifier si la version de l'application correspond à la dernière version officielle
      // Cette vérification nécessite une API serveur pour être fiable
      final bool isVersionCorrect = await _verifyAppVersion(appVersion, buildNumber);
      
      // Vérifier l'intégrité de l'application (signature, etc.)
      final bool isSignatureValid = await _verifyAppSignature();
      
      return !isVersionCorrect || !isSignatureValid;
    } catch (e) {
      // En cas d'erreur, considérer qu'il y a un risque
      return true;
    }
  }

  // Vérifier la version de l'application auprès du serveur
  Future<bool> _verifyAppVersion(String version, String buildNumber) async {
    try {
      // Vérifier la connexion Internet
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        // Sans connexion, considérer la version comme correcte
        return true;
      }
      
      // Vérifier auprès du serveur
      final response = await _apiService.get('/app/version');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final latestVersion = data['version'];
        final minimumVersion = data['minimum_version'];
        
        // Vérifier si la version actuelle est supérieure à la version minimale requise
        return _compareVersions(version, minimumVersion) >= 0;
      } else {
        // En cas d'échec, accepter la version actuelle
        return true;
      }
    } catch (e) {
      // En cas d'erreur, accepter la version actuelle
      return true;
    }
  }

  // Comparer deux versions sémantiques (format: x.y.z)
  int _compareVersions(String v1, String v2) {
    List<int> v1Parts = v1.split('.').map(int.parse).toList();
    List<int> v2Parts = v2.split('.').map(int.parse).toList();
    
    for (int i = 0; i < 3; i++) {
      int v1Part = i < v1Parts.length ? v1Parts[i] : 0;
      int v2Part = i < v2Parts.length ? v2Parts[i] : 0;
      
      if (v1Part > v2Part) return 1;
      if (v1Part < v2Part) return -1;
    }
    
    return 0; // Versions égales
  }

  // Vérifier la signature de l'application
  Future<bool> _verifyAppSignature() async {
    // Cette méthode nécessite une implémentation native
    // Pour une vraie application, utilisez un canal de plateforme pour vérifier la signature
    return true;
  }

  // Vérifier la sécurité du réseau
  Future<bool> _checkNetworkSecurity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        // Sans connexion Internet, pas de problème réseau
        return false;
      }
      
      // Vérifier le certificat SSL
      final bool isCertValid = await _apiService.verifyCertificate();
      
      return !isCertValid;
    } catch (e) {
      // En cas d'erreur, considérer qu'il y a un problème
      return true;
    }
  }

  // Enregistrer l'état des menaces
  Future<void> _logThreatStatus() async {
    try {
      // Enregistrer le niveau de menace
      await _secureStorage.saveSecuritySetting(
        'threat_level', 
        _currentThreatLevel.toString()
      );
      
      // Enregistrer la liste des menaces
      await _secureStorage.saveSecuritySetting(
        'active_threats', 
        jsonEncode(_activeThreatDescriptions)
      );
      
      // Enregistrer l'horodatage
      await _secureStorage.saveSecuritySetting(
        'last_threat_check', 
        DateTime.now().toIso8601String()
      );
    } catch (e) {
      // Ignorer les erreurs pour ne pas perturber l'application
    }
  }

  // Signaler une menace au serveur (pour analyse et statistiques)
  Future<void> _reportThreatToServer() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return; // Sans connexion, impossible de signaler
      }
      
      // Récupérer l'identifiant de l'appareil
      String? deviceId = await _secureStorage.getSecuritySetting('device_id');
      if (deviceId == null) {
        // Générer un nouvel ID si nécessaire
        deviceId = 'android_${DateTime.now().millisecondsSinceEpoch}';
        await _secureStorage.saveSecuritySetting('device_id', deviceId);
      }
      
      // Collecter des informations sur l'appareil (non sensibles)
      final androidInfo = await _deviceInfo.androidInfo;
      
      // Données à envoyer
      final reportData = {
        'device_id': deviceId,
        'threat_level': _currentThreatLevel.toString(),
        'threats': _activeThreatDescriptions,
        'os_version': androidInfo.version.release,
        'device_model': androidInfo.model,
        'app_version': (await PackageInfo.fromPlatform()).version,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // Envoyer au serveur de façon anonymisée
      await _apiService.post('/security/report', body: reportData);
    } catch (e) {
      // Ignorer les erreurs pour ne pas perturber l'application
    }
  }

  // Obtenir des recommandations de sécurité basées sur les menaces actuelles
  List<String> getSecurityRecommendations() {
    List<String> recommendations = [];
    
    for (String threat in _activeThreatDescriptions) {
      if (threat.contains('rooté')) {
        recommendations.add('Votre appareil est rooté, ce qui constitue un risque de sécurité majeur pour vos mots de passe. Envisagez d'utiliser un appareil non-rooté pour les données sensibles.');
      }
      
      if (threat.contains('émulateur')) {
        recommendations.add('L\'utilisation d\'un émulateur n\'est pas recommandée pour une application de mots de passe. Utilisez un appareil physique pour une meilleure sécurité.');
      }
      
      if (threat.contains('développeur')) {
        recommendations.add('Le mode développeur est activé sur votre appareil. Pour une sécurité optimale, désactivez-le dans les paramètres système.');
      }
      
      if (threat.contains('débogueur')) {
        recommendations.add('Un débogueur est attaché à l\'application, ce qui peut compromettre la sécurité. Redémarrez l\'application dans des conditions normales.');
      }
      
      if (threat.contains('altération')) {
        recommendations.add('L\'intégrité de l\'application semble compromise. Réinstallez l\'application depuis une source officielle.');
      }
      
      if (threat.contains('réseau')) {
        recommendations.add('Un problème de sécurité réseau a été détecté. Évitez les réseaux Wi-Fi publics et utilisez un VPN si possible.');
      }
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('Aucun problème de sécurité détecté. Continuez à respecter les bonnes pratiques de sécurité.');
    }
    
    return recommendations;
  }
}