// lib/services/security_service.dart
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:root_check/root_check.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'secure_storage_service.dart';

class SecurityService {
  // Singleton
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  final SecureStorageService _secureStorage = SecureStorageService();
  
  // Timer pour vérifications périodiques
  Timer? _securityCheckTimer;
  
  // Initialiser le service de sécurité
  Future<void> initialize() async {
    try {
      // Vérifier l'intégrité de l'application au démarrage
      await _checkAppIntegrity();
      
      // Configurer une vérification périodique
      _securityCheckTimer = Timer.periodic(
        const Duration(minutes: 5),
        (_) => _performSecurityChecks(),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Erreur d\'initialisation du service de sécurité: $e');
      }
    }
  }

  // Nettoyer les ressources
  void dispose() {
    _securityCheckTimer?.cancel();
  }

  // Vérifier si l'appareil est rooté ou compromis
  Future<bool> isDeviceSecure() async {
    try {
      bool isRooted = await RootCheck.isRooted ?? false;
      bool isDevMode = await _isInDeveloperMode();
      bool isEmulator = await _isEmulator();
      
      // Enregistrer le résultat pour référence future
      await _secureStorage.saveSecuritySetting('device_rooted', isRooted.toString());
      await _secureStorage.saveSecuritySetting('device_dev_mode', isDevMode.toString());
      await _secureStorage.saveSecuritySetting('device_emulator', isEmulator.toString());
      
      // Un appareil est considéré comme sécurisé s'il n'est pas rooté
      // Le mode développeur et l'émulateur sont des drapeaux, mais pas bloquants
      return !isRooted;
    } catch (e) {
      // En cas d'erreur, considérer l'appareil comme non sécurisé
      if (kDebugMode) {
        print('Erreur lors de la vérification de la sécurité: $e');
      }
      return false;
    }
  }

  // Vérifier si l'application s'exécute sur un émulateur
  Future<bool> _isEmulator() async {
    try {
      // Cette vérification est simplifiée
      // Une implémentation réelle utiliserait des méthodes natives pour la détection
      String? brand = await _getDeviceBrand();
      String? model = await _getDeviceModel();
      
      if (brand == null || model == null) return false;
      
      // Mots-clés communs pour les émulateurs
      final List<String> emulatorKeywords = [
        'emulator', 'simulator', 'sdk', 'virtual', 'genymotion',
        'nox', 'bluestacks', 'android sdk'
      ];
      
      brand = brand.toLowerCase();
      model = model.toLowerCase();
      
      for (String keyword in emulatorKeywords) {
        if (brand.contains(keyword) || model.contains(keyword)) {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  // Récupérer la marque de l'appareil
  Future<String?> _getDeviceBrand() async {
    try {
      // Cette méthode est simplifiée
      // Une implémentation réelle utiliserait la plateforme native
      return 'unknown';
    } catch (e) {
      return null;
    }
  }

  // Récupérer le modèle de l'appareil
  Future<String?> _getDeviceModel() async {
    try {
      // Cette méthode est simplifiée
      // Une implémentation réelle utiliserait la plateforme native
      return 'unknown';
    } catch (e) {
      return null;
    }
  }

  // Vérifier si le mode développeur est activé
  Future<bool> _isInDeveloperMode() async {
    try {
      // Cette méthode est simplifiée
      // Une implémentation réelle utiliserait une méthode native pour détecter
      // le mode développeur sur Android
      return false;
    } catch (e) {
      return false;
    }
  }

  // Vérifier si un débogueur est attaché
  bool isDebuggerAttached() {
    // En développement, toujours retourner false
    if (kDebugMode) return false;
    
    // Cette méthode est simplifiée
    // Une implémentation réelle utiliserait des méthodes natives pour la détection
    return false;
  }

  // Vérifier l'intégrité de l'application
  Future<bool> _checkAppIntegrity() async {
    try {
      // Vérifier la signature de l'application
      bool isSignatureValid = await _verifyAppSignature();
      
      // Vérifier la version de l'application
      bool isVersionValid = await _verifyAppVersion();
      
      // Enregistrer les résultats
      await _secureStorage.saveSecuritySetting('app_signature_valid', isSignatureValid.toString());
      await _secureStorage.saveSecuritySetting('app_version_valid', isVersionValid.toString());
      
      return isSignatureValid && isVersionValid;
    } catch (e) {
      return false;
    }
  }

  // Vérifier la signature de l'application
  Future<bool> _verifyAppSignature() async {
    // Cette méthode est simplifiée
    // Une implémentation réelle comparerait la signature de l'APK avec une valeur attendue
    return true;
  }

  // Vérifier la version de l'application
  Future<bool> _verifyAppVersion() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String version = packageInfo.version;
      
      // Comparer avec la version minimale requise (à définir selon vos besoins)
      String minVersion = '1.0.0';
      
      // Logique de comparaison simplifiée
      return _isVersionHigherOrEqual(version, minVersion);
    } catch (e) {
      return false;
    }
  }

  // Comparer des versions sémantiques
  bool _isVersionHigherOrEqual(String version, String minVersion) {
    List<int> versionParts = version.split('.').map(int.parse).toList();
    List<int> minVersionParts = minVersion.split('.').map(int.parse).toList();
    
    for (int i = 0; i < 3; i++) {
      int vPart = i < versionParts.length ? versionParts[i] : 0;
      int mPart = i < minVersionParts.length ? minVersionParts[i] : 0;
      
      if (vPart > mPart) return true;
      if (vPart < mPart) return false;
    }
    
    return true; // Les versions sont égales
  }

  // Effectuer les vérifications de sécurité périodiques
  Future<void> _performSecurityChecks() async {
    try {
      // Vérifier si l'appareil est toujours sécurisé
      bool isSecure = await isDeviceSecure();
      
      // Vérifier si un débogueur a été attaché
      bool hasDebugger = isDebuggerAttached();
      
      // Enregistrer les résultats
      await _secureStorage.saveSecuritySetting('device_secure', isSecure.toString());
      await _secureStorage.saveSecuritySetting('debugger_attached', hasDebugger.toString());
      
      // En cas de problème de sécurité détecté, on pourrait:
      // 1. Enregistrer l'incident
      // 2. Désactiver certaines fonctionnalités sensibles
      // 3. Demander une re-authentification
      if (!isSecure || hasDebugger) {
        await _logSecurityIncident('Problème de sécurité détecté');
      }
    } catch (e) {
      // Ignorer les erreurs pour ne pas perturber l'expérience utilisateur
      if (kDebugMode) {
        print('Erreur lors des vérifications de sécurité: $e');
      }
    }
  }

  // Enregistrer un incident de sécurité
  Future<void> _logSecurityIncident(String description) async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      final incident = {
        'timestamp': timestamp,
        'description': description,
      };
      
      // Récupérer les incidents précédents
      String? incidentsJson = await _secureStorage.getSecuritySetting('security_incidents');
      List<dynamic> incidents = [];
      
      if (incidentsJson != null && incidentsJson.isNotEmpty) {
        incidents = jsonDecode(incidentsJson);
      }
      
      // Ajouter le nouvel incident
      incidents.add(incident);
      
      // Limiter à 20 incidents pour économiser l'espace
      if (incidents.length > 20) {
        incidents = incidents.sublist(incidents.length - 20);
      }
      
      // Enregistrer
      await _secureStorage.saveSecuritySetting(
        'security_incidents',
        jsonEncode(incidents),
      );
    } catch (e) {
      // Ignorer les erreurs
    }
  }

  // Vérifier la sécurité réseau
  Future<bool> checkNetworkSecurity() async {
    try {
      // Vérifier que le certificat SSL est valide
      bool isCertValid = await _verifySslCertificate();
      return isCertValid;
    } catch (e) {
      return false;
    }
  }

  // Vérifier le certificat SSL
  Future<bool> _verifySslCertificate() async {
    // Cette méthode est simplifiée
    // Une implémentation réelle ferait une vraie vérification de certificate pinning
    return true;
  }

  // Vérifier l'intégrité des fichiers sensibles
  Future<bool> verifyFileIntegrity() async {
    try {
      // Cette méthode est simplifiée
      // Une implémentation réelle vérifierait l'intégrité des fichiers de configuration
      // et des données sensibles
      return true;
    } catch (e) {
      return false;
    }
  }

  // Obtenir un rapport de sécurité complet
  Future<Map<String, bool>> getSecurityReport() async {
    bool isDeviceRooted = !(await isDeviceSecure());
    bool hasDebugger = isDebuggerAttached();
    bool isEmulator = await _isEmulator();
    bool isDevMode = await _isInDeveloperMode();
    bool isAppIntegrityOk = await _checkAppIntegrity();
    bool isNetworkSecure = await checkNetworkSecurity();
    
    return {
      'device_rooted': isDeviceRooted,
      'debugger_attached': hasDebugger,
      'running_on_emulator': isEmulator,
      'developer_mode_enabled': isDevMode,
      'app_integrity_ok': isAppIntegrityOk,
      'network_secure': isNetworkSecure,
    };
  }
}