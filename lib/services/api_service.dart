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
  final String _baseUrl = 'https://your-api-domain.com/api';
  final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'MonPass-Android/1.0', // User-Agent personnalisé pour identification
  };

  // Empreintes SSL pour le certificate pinning (à mettre à jour avec les vraies empreintes)
  final List<String> _sslPinningHashes = [
    // Remplacez par les empreintes SHA-256 de vos certificats
    'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
    'sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=',
  ];
  
  // Vérifier la connexion réseau
  Future<bool> isNetworkAvailable() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // Initialiser le certificate pinning avec vérification
  Future<bool> _initSSLPinning() async {
    try {
      final result = await SslPinningPlugin.check(
        serverURL: _baseUrl,
        headerHttp: {},
        sha: SslPinningType.SHA256,
        allowedSHAFingerprints: _sslPinningHashes,
        timeout: 30, // Timeout réduit pour une meilleure réactivité
      );
      
      if (!result.contains('CONNECTION_SECURE')) {
        // Enregistrer la tentative potentiellement malveillante
        await _logSecurityIncident("SSL Pinning failed: $result");
        return false;
      }
      
      return true;
    } catch (e) {
      await _logSecurityIncident("SSL Pinning exception: $e");
      return false;
    }
  }

  // Loguer un incident de sécurité localement (pour référence future)
  Future<void> _logSecurityIncident(String message) async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      final incident = {'timestamp': timestamp, 'message': message};
      
      // Récupérer les incidents précédents
      String? storedIncidents = await _secureStorage.getSecuritySetting('incidents');
      List<dynamic> incidents = [];
      
      if (storedIncidents != null) {
        incidents = jsonDecode(storedIncidents);
      }
      
      // Ajouter le nouvel incident et limiter à 20 incidents maximum
      incidents.add(incident);
      if (incidents.length > 20) {
        incidents = incidents.sublist(incidents.length - 20);
      }
      
      // Sauvegarder les incidents
      await _secureStorage.saveSecuritySetting('incidents', jsonEncode(incidents));
    } catch (e) {
      // Ignorer les erreurs - la journalisation ne doit pas bloquer le flux principal
      print('Error logging security incident: $e');
    }
  }

  // Mettre à jour les headers avec le token JWT
  Future<Map<String, String>> _getHeaders() async {
    final Map<String, String> headers = Map.from(_headers);
    final String? token = await _secureStorage.getAuthToken();
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    // Ajouter un timestamp pour éviter la réutilisation des requêtes
    headers['X-Request-Timestamp'] = DateTime.now().millisecondsSinceEpoch.toString();
    
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
      
      _validateResponse(response);
      
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
      
      _validateResponse(response);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Si la vérification est réussie et contient un token JWT, le sauvegarder
        if (data.containsKey('token')) {
          await _secureStorage.saveAuthToken(data['token']);
        }
        
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
      _validateResponse(response);
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
        'device_id': await _getDeviceId(),
      });
      
      return response.statusCode == 200;
    } catch (e) {
      // Enregistrer l'erreur mais ne pas échouer l'application
      await _logSecurityIncident("Sync error: $e");
      return false;
    }
  }

  // Obtenir un identifiant unique pour l'appareil (pour le suivi de synchronisation)
  Future<String> _getDeviceId() async {
    String? deviceId = await _secureStorage.getSecuritySetting('device_id');
    
    if (deviceId == null) {
      // Générer un nouvel ID unique
      deviceId = 'android_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(8)}';
      await _secureStorage.saveSecuritySetting('device_id', deviceId);
    }
    
    return deviceId;
  }

  // Générer une chaîne aléatoire pour l'ID d'appareil
  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return String.fromCharCodes(
      List.generate(length, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
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

    // Vérifier si les en-têtes de sécurité sont présents
    if (!response.headers.containsKey('x-content-type-options') || 
        !response.headers.containsKey('x-frame-options')) {
      // Log warning but don't fail the request
      print('Attention: En-têtes de sécurité manquants dans la réponse');
    }
  }

  // Vérifier la validité du certificat SSL
  Future<bool> verifyCertificate() async {
    return await _initSSLPinning();
  }
}