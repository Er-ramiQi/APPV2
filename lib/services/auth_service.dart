// lib/services/auth_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'secure_storage_service.dart';

class AuthService {
  // Singleton
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiService _apiService = ApiService();
  final SecureStorageService _secureStorage = SecureStorageService();
  final LocalAuthentication _localAuth = LocalAuthentication();

  // Nombres de tentatives échouées pour le verrouillage
  static const int _maxLoginAttempts = 5;
  static const int _lockDurationMinutes = 15;

  // Première étape de connexion : envoi email/mot de passe
  Future<bool> initiateLogin(String email, String password) async {
    try {
      // Vérifier si le compte est verrouillé
      if (await _isAccountLocked()) {
        throw Exception('Compte temporairement verrouillé suite à plusieurs tentatives échouées');
      }
      
      // Vérifier si nous sommes en mode hors ligne
      final bool isOnline = await _apiService.isNetworkAvailable();
      
      if (isOnline) {
        // Mode en ligne: demander un OTP
        final response = await _apiService.requestOtp(email);
        
        if (response['success'] == true) {
          // Stocker l'email pour la prochaine étape
          await _secureStorage.saveSecuritySetting('pending_auth_email', email);
          
          // Enregistrer le hash du mot de passe pour validation locale
          final passwordHash = _hashPassword(password);
          await _secureStorage.saveSecuritySetting('pending_auth_password_hash', passwordHash);
          
          // Réinitialiser le compteur de tentatives
          await _resetFailedAttempts();
          
          return true;
        } else {
          // Incrémenter le compteur de tentatives échouées
          await _incrementFailedAttempts();
          return false;
        }
      } else {
        // Mode hors ligne: vérifier les identifiants localement
        final User? user = await _secureStorage.getUser();
        final String? storedPasswordHash = await _secureStorage.getMasterPasswordHash();
        
        if (user != null && user.email == email && storedPasswordHash != null) {
          // Vérifier le mot de passe
          final passwordHash = _hashPassword(password);
          
          if (storedPasswordHash == passwordHash) {
            // Réinitialiser le compteur de tentatives
            await _resetFailedAttempts();
            return true;
          }
        }
        
        // Incrémenter le compteur de tentatives échouées
        await _incrementFailedAttempts();
        return false;
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Hacher le mot de passe pour stockage ou comparaison sécurisée
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Incrémenter le compteur de tentatives échouées
  Future<void> _incrementFailedAttempts() async {
    String? attemptsStr = await _secureStorage.getSecuritySetting('failed_login_attempts');
    int attempts = attemptsStr != null ? int.parse(attemptsStr) : 0;
    attempts++;
    
    await _secureStorage.saveSecuritySetting('failed_login_attempts', attempts.toString());
    
    // Si le nombre maximum de tentatives est atteint, verrouiller le compte
    if (attempts >= _maxLoginAttempts) {
      final lockUntil = DateTime.now().add(const Duration(minutes: _lockDurationMinutes));
      await _secureStorage.saveSecuritySetting('account_locked_until', lockUntil.toIso8601String());
    }
  }

  // Réinitialiser le compteur de tentatives échouées
  Future<void> _resetFailedAttempts() async {
    await _secureStorage.saveSecuritySetting('failed_login_attempts', '0');
    await _secureStorage.saveSecuritySetting('account_locked_until', '');
  }

  // Vérifier si le compte est verrouillé
  Future<bool> _isAccountLocked() async {
    String? lockedUntilStr = await _secureStorage.getSecuritySetting('account_locked_until');
    
    if (lockedUntilStr != null && lockedUntilStr.isNotEmpty) {
      DateTime lockedUntil = DateTime.parse(lockedUntilStr);
      
      if (DateTime.now().isBefore(lockedUntil)) {
        return true;
      } else {
        // La période de verrouillage est terminée
        await _resetFailedAttempts();
        return false;
      }
    }
    
    return false;
  }

  // Deuxième étape : vérification du code OTP
  Future<bool> verifyOtp(String email, String otp) async {
    try {
      // Vérifier si l'email correspond à celui en attente
      String? pendingEmail = await _secureStorage.getSecuritySetting('pending_auth_email');
      
      if (pendingEmail != email) {
        throw Exception('Session expirée ou invalide');
      }
      
      final response = await _apiService.verifyOtp(email, otp);
      
      if (response['success'] == true) {
        // Authentification réussie
        final String? token = response['token'];
        final Map<String, dynamic>? userData = response['user'];
        
        if (token != null) {
          await _secureStorage.saveAuthToken(token);
        }
        
        if (userData != null) {
          final user = User.fromJson(userData);
          await _secureStorage.saveUser(user);
          
          // Sauvegarder le hash du mot de passe maître pour les vérifications hors ligne
          String? pendingPasswordHash = await _secureStorage.getSecuritySetting('pending_auth_password_hash');
          if (pendingPasswordHash != null) {
            await _secureStorage.saveMasterPasswordHash(pendingPasswordHash);
          }
        }
        
        // Nettoyer les informations de connexion en attente
        await _secureStorage.saveSecuritySetting('pending_auth_email', '');
        await _secureStorage.saveSecuritySetting('pending_auth_password_hash', '');
        
        return true;
      } else {
        return false;
      }
    } catch (e) {
      throw Exception('Erreur de vérification OTP: $e');
    }
  }

  // Renvoyer un nouveau code OTP
  Future<bool> resendOtp(String email) async {
    try {
      final response = await _apiService.requestOtp(email);
      return response['success'] == true;
    } catch (e) {
      throw Exception('Erreur lors du renvoi d\'OTP: $e');
    }
  }

  // Vérifier si l'utilisateur est connecté
  Future<bool> isLoggedIn() async {
    try {
      final token = await _secureStorage.getAuthToken();
      
      if (token == null) {
        return false;
      }
      
      // Vérifier si le token a expiré
      final isTokenValid = await _validateToken(token);
      return isTokenValid;
    } catch (e) {
      return false;
    }
  }

  // Validation simplifiée du token
  Future<bool> _validateToken(String token) async {
    // Dans une implémentation réelle, vérifier la validité du JWT
    // Cette méthode est simplifiée
    
    // Vérifier si nous sommes en ligne
    final bool isOnline = await _apiService.isNetworkAvailable();
    
    if (isOnline) {
      // Vérifier le token avec le serveur
      try {
        final response = await _apiService.get('/auth/validate-token');
        return response.statusCode == 200;
      } catch (e) {
        return false;
      }
    } else {
      // Mode hors ligne : considérer le token comme valide
      return true;
    }
  }

  // Déconnexion
  Future<void> logout() async {
    try {
      // Appel au backend pour invalider le token (si en ligne)
      final isOnline = await _apiService.isNetworkAvailable();
      
      if (isOnline) {
        final token = await _secureStorage.getAuthToken();
        if (token != null) {
          try {
            await _apiService.post('/auth/logout');
          } catch (e) {
            // Ignorer les erreurs lors de la déconnexion en ligne
            print('Erreur lors de la déconnexion en ligne: $e');
          }
        }
      }
    } finally {
      // Supprimer les données de session locales
      await _secureStorage.deleteAuthToken();
    }
  }

  // ===== Méthodes d'authentification biométrique =====

  // Vérifier si l'authentification biométrique est disponible
  Future<bool> isBiometricAvailable() async {
    try {
      // Vérifier si l'appareil supporte la biométrie
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final canAuthenticate =
          canCheckBiometrics || await _localAuth.isDeviceSupported();

      // Vérifier si la biométrie est activée pour cette application
      final isEnabled = await _secureStorage.isBiometricEnabled();

      return canAuthenticate && isEnabled;
    } catch (e) {
      print('Erreur lors de la vérification biométrique: $e');
      return false;
    }
  }

  // Activer/désactiver l'authentification biométrique
  Future<void> setBiometricEnabled(bool enabled) async {
    if (enabled) {
      // Vérifier si l'appareil supporte la biométrie avant d'activer
      final canAuthenticate = await _localAuth.canCheckBiometrics && 
                               await _localAuth.isDeviceSupported();
      
      if (!canAuthenticate) {
        throw Exception('L\'appareil ne supporte pas l\'authentification biométrique');
      }
      
      // Vérifier si des empreintes sont enregistrées
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        throw Exception('Aucune donnée biométrique enregistrée sur l\'appareil');
      }
    }
    
    await _secureStorage.setBiometricEnabled(enabled);
  }

  // Authentifier avec biométrie
  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason:
            'Veuillez vous authentifier pour accéder à vos mots de passe',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,  // Forcer l'utilisation de la biométrie uniquement
        ),
      );
    } on PlatformException catch (e) {
      if (e.code == auth_error.notAvailable ||
          e.code == auth_error.notEnrolled ||
          e.code == auth_error.passcodeNotSet) {
        // Biométrie non disponible ou non configurée
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

  // ===== Méthodes d'inscription =====

  // Inscription d'un nouvel utilisateur
  Future<bool> register(String name, String email, String password) async {
    try {
      // Vérifier la qualité du mot de passe
      if (!_isPasswordStrong(password)) {
        throw Exception('Le mot de passe n\'est pas assez fort. Il doit contenir au moins 8 caractères dont des majuscules, minuscules, chiffres et symboles.');
      }

      // Générer le hash du mot de passe
      final passwordHash = _hashPassword(password);
      
      // Appel à l'API pour l'inscription
      final response = await _apiService.post(
        '/auth/register',
        body: {
          'name': name,
          'email': email,
          'password': password,  // Le serveur devrait effectuer son propre hachage
        },
      );

      if (response.statusCode == 201) {
        // Stocker le hash du mot de passe localement pour les futures connexions hors ligne
        await _secureStorage.saveMasterPasswordHash(passwordHash);
        return true;
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Erreur lors de l\'inscription');
      }
    } catch (e) {
      throw Exception('Erreur d\'inscription: $e');
    }
  }

  // Vérifier si le mot de passe est suffisamment fort
  bool _isPasswordStrong(String password) {
    // Au moins 8 caractères
    if (password.length < 8) return false;
    
    // Au moins une majuscule
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    
    // Au moins une minuscule
    if (!password.contains(RegExp(r'[a-z]'))) return false;
    
    // Au moins un chiffre
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    
    // Au moins un caractère spécial
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return false;
    
    return true;
  }

  // Générer un mot de passe fort
  String generateStrongPassword({int length = 16}) {
    const String upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const String lower = 'abcdefghijklmnopqrstuvwxyz';
    const String numbers = '0123456789';
    const String special = '!@#\$%^&*()_+{}|:<>?';

    final random = Random.secure();
    final List<String> charPool = [
      upper[random.nextInt(upper.length)],
      lower[random.nextInt(lower.length)],
      numbers[random.nextInt(numbers.length)],
      special[random.nextInt(special.length)],
    ];

    // Remplir le reste avec des caractères aléatoires
    for (int i = charPool.length; i < length; i++) {
      const pool = upper + lower + numbers + special;
      charPool.add(pool[random.nextInt(pool.length)]);
    }

    // Mélanger les caractères
    charPool.shuffle(random);
    return charPool.join();
  }
}

// Pour éviter les erreurs de compilation, nous ajoutons une classe User simulée
// Dans une vraie application, cette classe serait importée depuis models/user.dart
class User {
  final String id;
  final String name;
  final String email;
  
  User({required this.id, required this.name, required this.email});
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }
}