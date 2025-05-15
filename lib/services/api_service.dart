// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:ssl_pinning_plugin/ssl_pinning_plugin.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'secure_storage_service.dart';

class ApiService {
  // Singleton
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final SecureStorageService _secureStorage = SecureStorageService();
  
  // Configuration de l'API
  final String _baseUrl = 'https://api.example.com/api';
  final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'MonPass-Android/1.0',
  };

  // Empreintes SSL pour le certificate pinning (à mettre à jour avec les vraies empreintes)
  final List<String> _sslPinningHashes = [
    'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',  // À remplacer avec les vraies empreintes
    'sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=',  // À remplacer avec les vraies empreintes
  ];
  
  // Vérifier la connexion réseau
  Future<bool> isNetworkAvailable() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // Initialiser le certificate pinning
  Future<bool> _initSSLPinning() async {
    try {
      final result = await SslPinningPlugin.check(
        serverURL: _baseUrl,
        headerHttp: {},
        sha: SslPinningType.SHA256,
        allowedSHAFingerprints: _sslPinningHashes,
        timeout: 30,
      );
      
      return result.contains('CONNECTION_SECURE');
    } catch (e) {
      return false;
    }
  }

  // Mettre à jour les headers avec le token JWT
  Future<Map<String, String>> _getHeaders() async {
    final Map<String, String> headers = Map.from(_headers);
    final String? token = await _secureStorage.getAuthToken();
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  // API pour l'authentification OTP
  Future<Map<String, dynamic>> requestOtp(String email) async {
    final bool isNetworkConnected = await isNetworkAvailable();
    if (!isNetworkConnected) {
      throw Exception('Pas de connexion internet');
    }
    
    final bool isSecure = await _initSSLPinning();
    if (!isSecure) {
      throw Exception('Connexion non sécurisée détectée');
    }
    
    final headers = await _getHeaders();
    final Uri uri = Uri.parse('$_baseUrl/auth/request-otp');
    
    try {
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode({'email': email}),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('Échec de la demande OTP: ${response.body}');
      }
    } on SocketException {
      throw Exception('Pas de connexion internet');
    } catch (e) {
      throw Exception('Erreur de requête: $e');
    }
  }

  // Vérifier le code OTP
  Future<Map<String, dynamic>> verifyOtp(String email, String otpCode) async {
    final bool isNetworkConnected = await isNetworkAvailable();
    if (!isNetworkConnected) {
      throw Exception('Pas de connexion internet');
    }
    
    final bool isSecure = await _initSSLPinning();
    if (!isSecure) {
      throw Exception('Connexion non sécurisée détectée');
    }
    
    final headers = await _getHeaders();
    final Uri uri = Uri.parse('$_baseUrl/auth/verify-otp');
    
    try {
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode({
          'email': email,
          'otp_code': otpCode
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('Échec de la vérification OTP: ${response.body}');
      }
    } on SocketException {
      throw Exception('Pas de connexion internet');
    } catch (e) {
      throw Exception('Erreur de requête: $e');
    }
  }

  // Méthode GET
  Future<http.Response> get(String endpoint, {Map<String, dynamic>? queryParams}) async {
    // Vérifier la connexion réseau
    final bool isNetworkConnected = await isNetworkAvailable();
    if (!isNetworkConnected) {
      throw Exception('Pas de connexion internet');
    }
    
    // Vérifier le certificate pinning
    final bool isSecure = await _initSSLPinning();
    if (!isSecure) {
      throw Exception('Connexion non sécurisée détectée');
    }

    final headers = await _getHeaders();
    Uri uri = Uri.parse('$_baseUrl$endpoint');
    
    if (queryParams != null) {
      uri = uri.replace(queryParameters: queryParams);
    }
    
    try {
      final response = await http.get(uri, headers: headers);
      return response;
    } on SocketException {
      throw Exception('Pas de connexion internet');
    } catch (e) {
      throw Exception('Erreur de requête: $e');
    }
  }

  // Méthode POST
  Future<http.Response> post(String endpoint, {Map<String, dynamic>? body}) async {
    // Vérifier la connexion réseau
    final bool isNetworkConnected = await isNetworkAvailable();
    if (!isNetworkConnected) {
      throw Exception('Pas de connexion internet');
    }
    
    // Vérifier le certificate pinning
    final bool isSecure = await _initSSLPinning();
    if (!isSecure) {
      throw Exception('Connexion non sécurisée détectée');
    }

    final headers = await _getHeaders();
    final Uri uri = Uri.parse('$_baseUrl$endpoint');
    
    try {
      final response = await http.post(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return response;
    } on SocketException {
      throw Exception('Pas de connexion internet');
    } catch (e) {
      throw Exception('Erreur de requête: $e');
    }
  }

  // Méthode PUT
  Future<http.Response> put(String endpoint, {Map<String, dynamic>? body}) async {
    // Vérifier la connexion réseau
    final bool isNetworkConnected = await isNetworkAvailable();
    if (!isNetworkConnected) {
      throw Exception('Pas de connexion internet');
    }
    
    // Vérifier le certificate pinning
    final bool isSecure = await _initSSLPinning();
    if (!isSecure) {
      throw Exception('Connexion non sécurisée détectée');
    }

    final headers = await _getHeaders();
    final Uri uri = Uri.parse('$_baseUrl$endpoint');
    
    try {
      final response = await http.put(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return response;
    } on SocketException {
      throw Exception('Pas de connexion internet');
    } catch (e) {
      throw Exception('Erreur de requête: $e');
    }
  }

  // Méthode DELETE
  Future<http.Response> delete(String endpoint) async {
    // Vérifier la connexion réseau
    final bool isNetworkConnected = await isNetworkAvailable();
    if (!isNetworkConnected) {
      throw Exception('Pas de connexion internet');
    }
    
    // Vérifier le certificate pinning
    final bool isSecure = await _initSSLPinning();
    if (!isSecure) {
      throw Exception('Connexion non sécurisée détectée');
    }

    final headers = await _getHeaders();
    final Uri uri = Uri.parse('$_baseUrl$endpoint');
    
    try {
      final response = await http.delete(uri, headers: headers);
      return response;
    } on SocketException {
      throw Exception('Pas de connexion internet');
    } catch (e) {
      throw Exception('Erreur de requête: $e');
    }
  }

  // Synchronisation avec le serveur
  Future<bool> syncPasswords(List<Map<String, dynamic>> passwordsData) async {
    try {
      final response = await post('/sync/passwords', body: {
        'data': passwordsData,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}