// services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:ssl_pinning_plugin/ssl_pinning_plugin.dart';
import 'secure_storage_service.dart';

class ApiService {
  // Singleton
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final SecureStorageService _secureStorage = SecureStorageService();
  
  // Configuration de l'API
  final String _baseUrl = 'https://your-api-domain.com/api';
  final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Empreintes SSL pour le certificate pinning
  final List<String> _sslPinningHashes = [
    // Remplacez par les empreintes SHA-256 de vos certificats
    'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
    'sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=',
  ];

  // Initialiser le certificate pinning
  Future<bool> _initSSLPinning() async {
    try {
      final result = await SslPinningPlugin.check(
        serverURL: _baseUrl,
        headerHttp: {},
        sha: SslPinningType.SHA256,
        allowedSHAFingerprints: _sslPinningHashes,
        timeout: 60,
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

  // Méthode GET
  Future<http.Response> get(String endpoint, {Map<String, dynamic>? queryParams}) async {
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
      _validateResponse(response);
      return response;
    } on SocketException {
      throw Exception('Pas de connexion internet');
    } catch (e) {
      throw Exception('Erreur de requête: $e');
    }
  }

  // Méthode POST
  Future<http.Response> post(String endpoint, {Map<String, dynamic>? body}) async {
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
      _validateResponse(response);
      return response;
    } on SocketException {
      throw Exception('Pas de connexion internet');
    } catch (e) {
      throw Exception('Erreur de requête: $e');
    }
  }

  // Méthode PUT
  Future<http.Response> put(String endpoint, {Map<String, dynamic>? body}) async {
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
      _validateResponse(response);
      return response;
    } on SocketException {
      throw Exception('Pas de connexion internet');
    } catch (e) {
      throw Exception('Erreur de requête: $e');
    }
  }

  // Méthode DELETE
  Future<http.Response> delete(String endpoint) async {
    // Vérifier le certificate pinning
    final bool isSecure = await _initSSLPinning();
    if (!isSecure) {
      throw Exception('Connexion non sécurisée détectée');
    }

    final headers = await _getHeaders();
    final Uri uri = Uri.parse('$_baseUrl$endpoint');
    
    try {
      final response = await http.delete(uri, headers: headers);
      _validateResponse(response);
      return response;
    } on SocketException {
      throw Exception('Pas de connexion internet');
    } catch (e) {
      throw Exception('Erreur de requête: $e');
    }
  }

  // Valider la réponse HTTP
  void _validateResponse(http.Response response) {
    // Vérifier si la réponse contient un nouveau token et le sauvegarder
    if (response.headers.containsKey('authorization')) {
      final String? newToken = response.headers['authorization']?.replaceFirst('Bearer ', '');
      if (newToken != null && newToken.isNotEmpty) {
        _secureStorage.saveAuthToken(newToken);
      }
    }

    // Gérer les erreurs d'authentification
    if (response.statusCode == 401) {
      _secureStorage.deleteAuthToken();
      throw Exception('Session expirée, veuillez vous reconnecter');
    }
  }
}