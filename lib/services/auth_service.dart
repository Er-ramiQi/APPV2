// services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:flutter/services.dart';

class AuthService {
  // Singleton
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Configuration
  final String _baseUrl = 'https://your-api-domain.com/api';
  final _secureStorage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();

  // Clés pour le stockage sécurisé
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userInfoKey = 'user_info';
  static const String _biometricEnabledKey = 'biometric_enabled';

  // En-têtes HTTP
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // Première étape de connexion : envoi email/mot de passe pour obtenir OTP
  Future<bool> initiateLogin(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        // Connexion réussie, OTP envoyé
        return true;
      } else if (response.statusCode == 401) {
        // Identifiants incorrects
        return false;
      } else {
        // Autres erreurs
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Une erreur s\'est produite');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Deuxième étape : vérification du code OTP
  Future<bool> verifyOtp(String email, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/verify-otp'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'otp': otp,
        }),
      );

      if (response.statusCode == 200) {
        // OTP valide, récupérer le token et infos utilisateur
        final data = jsonDecode(response.body);
        final token = data['token'];
        final refreshToken = data['refresh_token'];
        final userInfo = data['user'];

        // Stocker le token de manière sécurisée
        await _secureStorage.write(key: _tokenKey, value: token);
        await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
        await _secureStorage.write(
            key: _userInfoKey, value: jsonEncode(userInfo));

        return true;
      } else {
        // OTP invalide ou autre erreur
        return false;
      }
    } catch (e) {
      throw Exception('Erreur de vérification OTP: $e');
    }
  }

  // Renvoyer un nouveau code OTP
  Future<bool> resendOtp(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/resend-otp'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erreur lors du renvoi d\'OTP: $e');
    }
  }

  // Vérifier si l'utilisateur est connecté
  Future<bool> isLoggedIn() async {
    final token = await _secureStorage.read(key: _tokenKey);
    return token != null;
  }

  // Récupérer le token d'authentification
  Future<String?> getAuthToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  // Récupérer les informations utilisateur
  Future<Map<String, dynamic>?> getUserInfo() async {
    final userInfoString = await _secureStorage.read(key: _userInfoKey);
    if (userInfoString == null) return null;
    return jsonDecode(userInfoString);
  }

  // Déconnexion
  Future<void> logout() async {
    try {
      // Appel au backend pour invalider le token (optionnel)
      final token = await getAuthToken();
      if (token != null) {
        await http.post(
          Uri.parse('$_baseUrl/auth/logout'),
          headers: {
            ..._headers,
            'Authorization': 'Bearer $token',
          },
        );
      }
    } catch (e) {
      // Ignorer les erreurs lors de la déconnexion
      print('Erreur lors de la déconnexion: $e');
    } finally {
      // Supprimer les données locales
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      await _secureStorage.delete(key: _userInfoKey);
    }
  }

  // Vérifier et rafraîchir le token
  Future<String?> refreshTokenIfNeeded() async {
    final token = await _secureStorage.read(key: _tokenKey);
    final refreshToken = await _secureStorage.read(key: _refreshTokenKey);

    if (token == null || refreshToken == null) {
      return null;
    }

    try {
      // Vérifier si le token est expiré (à implémenter avec jwt_decoder)
      bool isExpired = _isTokenExpired(token);

      if (isExpired) {
        // Rafraîchir le token
        final response = await http.post(
          Uri.parse('$_baseUrl/auth/refresh-token'),
          headers: _headers,
          body: jsonEncode({
            'refresh_token': refreshToken,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final newToken = data['token'];
          final newRefreshToken = data['refresh_token'];

          // Mettre à jour les tokens
          await _secureStorage.write(key: _tokenKey, value: newToken);
          await _secureStorage.write(
              key: _refreshTokenKey, value: newRefreshToken);

          return newToken;
        } else {
          // Échec du rafraîchissement, déconnexion
          await logout();
          return null;
        }
      }

      return token;
    } catch (e) {
      print('Erreur lors du rafraîchissement du token: $e');
      return token; // Renvoyer le token actuel en cas d'erreur
    }
  }

  // Méthode simplifiée pour vérifier si un token est expiré
  // À remplacer par une vérification réelle du JWT
  bool _isTokenExpired(String token) {
    // Dans une implémentation réelle, utilisez un package comme jwt_decoder
    // pour décoder le token et vérifier sa date d'expiration
    return false;
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
      final isEnabled = await isBiometricEnabled();

      return canAuthenticate && isEnabled;
    } catch (e) {
      print('Erreur lors de la vérification biométrique: $e');
      return false;
    }
  }

  // Vérifier si la biométrie est activée
  Future<bool> isBiometricEnabled() async {
    final value = await _secureStorage.read(key: _biometricEnabledKey);
    return value == 'true';
  }

  // Activer/désactiver l'authentification biométrique
  Future<void> setBiometricEnabled(bool enabled) async {
    await _secureStorage.write(
      key: _biometricEnabledKey,
      value: enabled.toString(),
    );
  }

  // Authentifier avec biométrie
  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason:
            'Veuillez vous authentifier pour accéder à l\'application',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } on PlatformException catch (e) {
      if (e.code == auth_error.notAvailable ||
          e.code == auth_error.notEnrolled ||
          e.code == auth_error.passcodeNotSet) {
        // Biométrie non disponible ou non configurée
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
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        // Inscription réussie, redirection vers la connexion
        return true;
      } else {
        // Erreur d'inscription
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Erreur lors de l\'inscription');
      }
    } catch (e) {
      throw Exception('Erreur d\'inscription: $e');
    }
  }
}