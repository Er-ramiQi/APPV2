// lib/services/secure_storage_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:convert';
import 'dart:math';
import '../models/password_item.dart';
import '../models/user.dart';

class SecureStorageService {
  // Singleton
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  // Configuration Android sécurisée
  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // Clé de chiffrement AES (générée une seule fois et stockée de manière sécurisée)
  encrypt.Key? _encryptionKey;
  encrypt.IV? _iv;

  // Initialisation de la clé de chiffrement
  Future<void> _initEncryptionKey() async {
    if (_encryptionKey != null && _iv != null) return;

    // Récupérer la clé si elle existe déjà, sinon en générer une nouvelle
    String? storedKey = await _secureStorage.read(key: 'encryption_key');
    String? storedIV = await _secureStorage.read(key: 'encryption_iv');
    
    if (storedKey == null) {
      // Génération d'une clé forte et aléatoire
      final key = encrypt.Key.fromSecureRandom(32);
      await _secureStorage.write(
        key: 'encryption_key',
        value: base64Encode(key.bytes),
      );
      _encryptionKey = key;
      
      // Génération d'une IV unique
      final ivBytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
      _iv = encrypt.IV(encrypt.Uint8List.fromList(ivBytes));
      
      // Sauvegarder l'IV
      await _secureStorage.write(
        key: 'encryption_iv',
        value: base64Encode(_iv!.bytes),
      );
    } else {
      _encryptionKey = encrypt.Key(base64Decode(storedKey));
      
      if (storedIV != null) {
        _iv = encrypt.IV(base64Decode(storedIV));
      } else {
        // IV par défaut si non trouvé (situation qui ne devrait pas arriver)
        _iv = encrypt.IV.fromLength(16);
      }
    }
  }

  // Chiffrer des données
  Future<String> _encryptData(String data) async {
    await _initEncryptionKey();
    if (_encryptionKey == null || _iv == null) {
      throw Exception("Encryption key not initialized");
    }
    
    final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey!));
    final encrypted = encrypter.encrypt(data, iv: _iv!);
    
    return encrypted.base64;
  }

  // Déchiffrer des données
  Future<String> _decryptData(String encryptedData) async {
    await _initEncryptionKey();
    if (_encryptionKey == null || _iv == null) {
      throw Exception("Encryption key not initialized");
    }
    
    try {
      final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey!));
      final decrypted = encrypter.decrypt64(encryptedData, iv: _iv!);
      return decrypted;
    } catch (e) {
      throw Exception("Failed to decrypt data: $e");
    }
  }

  // Sauvegarder les informations utilisateur
  Future<void> saveUser(User user) async {
    final userJson = jsonEncode(user.toJson());
    final encryptedData = await _encryptData(userJson);
    await _secureStorage.write(key: 'user_data', value: encryptedData);
  }

  // Récupérer les informations utilisateur
  Future<User?> getUser() async {
    final encryptedData = await _secureStorage.read(key: 'user_data');
    if (encryptedData == null) return null;
    
    final decryptedData = await _decryptData(encryptedData);
    final userMap = jsonDecode(decryptedData);
    return User.fromJson(userMap);
  }

  // Sauvegarder le token d'authentification
  Future<void> saveAuthToken(String token) async {
    await _secureStorage.write(key: 'auth_token', value: token);
  }

  // Récupérer le token d'authentification
  Future<String?> getAuthToken() async {
    return await _secureStorage.read(key: 'auth_token');
  }

  // Supprimer le token d'authentification (déconnexion)
  Future<void> deleteAuthToken() async {
    await _secureStorage.delete(key: 'auth_token');
  }

  // Sauvegarder la liste des mots de passe
  Future<void> savePasswordItems(List<PasswordItem> items) async {
    final itemsJson = jsonEncode(items.map((e) => e.toJson()).toList());
    final encryptedData = await _encryptData(itemsJson);
    await _secureStorage.write(key: 'password_items', value: encryptedData);
  }

  // Récupérer la liste des mots de passe
  Future<List<PasswordItem>> getPasswordItems() async {
    final encryptedData = await _secureStorage.read(key: 'password_items');
    if (encryptedData == null) return [];
    
    final decryptedData = await _decryptData(encryptedData);
    final itemsMap = jsonDecode(decryptedData) as List;
    return itemsMap.map((e) => PasswordItem.fromJson(e)).toList();
  }

  // Enregistrer le mot de passe maître (haché)
  Future<void> saveMasterPasswordHash(String passwordHash) async {
    await _secureStorage.write(key: 'master_password_hash', value: passwordHash);
  }

  // Récupérer le hash du mot de passe maître
  Future<String?> getMasterPasswordHash() async {
    return await _secureStorage.read(key: 'master_password_hash');
  }

  // Vérifier si les données biométriques sont activées
  Future<bool> isBiometricEnabled() async {
    final value = await _secureStorage.read(key: 'biometric_enabled');
    return value == 'true';
  }

  // Activer/désactiver l'authentification biométrique
  Future<void> setBiometricEnabled(bool enabled) async {
    await _secureStorage.write(
      key: 'biometric_enabled',
      value: enabled.toString(),
    );
  }

  // Effacer toutes les données stockées (réinitialisation)
  Future<void> clearAllData() async {
    await _secureStorage.deleteAll();
    _encryptionKey = null;
    _iv = null;
  }

  // Enregistrer/récupérer un paramètre de sécurité
  Future<void> saveSecuritySetting(String key, String value) async {
    await _secureStorage.write(key: 'security_$key', value: value);
  }

  Future<String?> getSecuritySetting(String key) async {
    return await _secureStorage.read(key: 'security_$key');
  }
}