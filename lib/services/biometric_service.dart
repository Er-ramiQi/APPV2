// lib/services/biometric_service.dart
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'secure_storage_service.dart';

class BiometricService {
  // Singleton
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  final SecureStorageService _secureStorage = SecureStorageService();
  
  // Période d'expiration de l'authentification biométrique (en minutes)
  static const int _biometricSessionValidityMinutes = 10;

  // Vérifier si l'authentification biométrique est disponible
  Future<bool> isBiometricAvailable() async {
    try {
      // Vérifier si l'appareil supporte la biométrie
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final canAuthenticate = canCheckBiometrics || await _localAuth.isDeviceSupported();
      
      // Vérifier si la biométrie est activée dans les paramètres de l'application
      final isBiometricEnabled = await _secureStorage.isBiometricEnabled();
      
      return canAuthenticate && isBiometricEnabled;
    } catch (e) {
      print('Erreur lors de la vérification biométrique: $e');
      return false;
    }
  }

  // Obtenir les types de biométrie disponibles
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      print('Erreur lors de la récupération des types biométriques: $e');
      return [];
    }
  }

  // Authentifier avec biométrie
  Future<bool> authenticate({String localizedReason = 'Veuillez vous authentifier pour accéder à vos mots de passe'}) async {
    try {
      // Vérifier si une session biométrique valide existe déjà
      if (await _isSessionValid()) {
        return true;
      }
      
      // Lancer l'authentification
      final bool authenticated = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          useErrorDialogs: true,
        ),
      );
      
      if (authenticated) {
        // Si l'authentification réussit, enregistrer l'horodatage
        await _secureStorage.saveSecuritySetting(
          'last_biometric_auth',
          DateTime.now().toIso8601String(),
        );
      }
      
      return authenticated;
    } on PlatformException catch (e) {
      if (e.code == auth_error.notAvailable ||
          e.code == auth_error.notEnrolled ||
          e.code == auth_error.passcodeNotSet) {
        // Biométrie non disponible, non configurée ou code de déverrouillage non défini
        // Désactiver automatiquement la biométrie pour éviter de futures erreurs
        await _secureStorage.setBiometricEnabled(false);
        return false;
      }
      print('Erreur d\'authentification biométrique: $e');
      return false;
    } catch (e) {
      print('Erreur d\'authentification: $e');
      return false;
    }
  }

  // Activer/désactiver l'authentification biométrique
  Future<bool> setBiometricEnabled(bool enabled) async {
    try {
      if (enabled) {
        // Vérifier si la biométrie est disponible avant d'activer
        final canCheckBiometrics = await _localAuth.canCheckBiometrics;
        final isDeviceSupported = await _localAuth.isDeviceSupported();
        
        if (!canCheckBiometrics || !isDeviceSupported) {
          throw Exception('L\'appareil ne supporte pas l\'authentification biométrique');
        }
        
        // Vérifier si des données biométriques sont enregistrées sur l'appareil
        final availableBiometrics = await _localAuth.getAvailableBiometrics();
        if (availableBiometrics.isEmpty) {
          throw Exception('Aucune donnée biométrique enregistrée sur cet appareil. Configurez d\'abord des données biométriques dans les paramètres de votre appareil.');
        }
        
        // Demander l'authentification avant d'activer
        final authenticated = await authenticate(
          localizedReason: 'Veuillez vous authentifier pour activer la biométrie',
        );
        
        if (!authenticated) {
          throw Exception('Authentification biométrique échouée');
        }
      }
      
      // Sauvegarder le paramètre
      await _secureStorage.setBiometricEnabled(enabled);
      
      // Si désactivé, effacer l'horodatage de la dernière authentification
      if (!enabled) {
        await _secureStorage.saveSecuritySetting('last_biometric_auth', '');
      }
      
      return true;
    } catch (e) {
      print('Erreur lors de la configuration biométrique: $e');
      return false;
    }
  }

  // Vérifier si une session biométrique valide existe
  Future<bool> _isSessionValid() async {
    try {
      final String? lastAuthStr = await _secureStorage.getSecuritySetting('last_biometric_auth');
      
      if (lastAuthStr == null || lastAuthStr.isEmpty) {
        return false;
      }
      
      final DateTime lastAuth = DateTime.parse(lastAuthStr);
      final DateTime now = DateTime.now();
      
      // Vérifier si l'authentification précédente est encore valide
      return now.difference(lastAuth).inMinutes < _biometricSessionValidityMinutes;
    } catch (e) {
      return false;
    }
  }

  // Invalider la session biométrique actuelle
  Future<void> invalidateSession() async {
    await _secureStorage.saveSecuritySetting('last_biometric_auth', '');
  }

  // Obtenir le type biométrique principal à utiliser (pour l'UI)
  Future<String> getPrimaryBiometricType() async {
    try {
      final biometrics = await getAvailableBiometrics();
      
      if (biometrics.isEmpty) {
        return 'Aucun';
      }
      
      if (biometrics.contains(BiometricType.face)) {
        return 'Reconnaissance faciale';
      } else if (biometrics.contains(BiometricType.fingerprint)) {
        return 'Empreinte digitale';
      } else if (biometrics.contains(BiometricType.iris)) {
        return 'Reconnaissance de l\'iris';
      } else {
        return 'Autre biométrie';
      }
    } catch (e) {
      return 'Non disponible';
    }
  }

  // Obtenir l'icône correspondant au type biométrique principal
  String getBiometricIcon() {
    return '🔐'; // Placeholder - à remplacer par une vraie icône
  }
}