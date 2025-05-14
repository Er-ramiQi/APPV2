// services/secure_storage_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:convert';
import '../models/password_item.dart';
import '../models/user.dart';

class SecureStorageService {
  // Singleton
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  // Initialisation du secure storage
  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
      keyCipherAlgorithm: 
          KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
      synchronizable: false,
    ),
  );

  // Clé de chiffrement AES (générée une seule fois et stockée de manière sécurisée)
  encrypt.Key? _encryptionKey;
  final _iv = encrypt.IV.fromLength(16);

  // Initialisation de la clé de chiffrement
  Future<void> _initEncryptionKey() async {
    if (_encryptionKey != null) return;

    // Récupérer la clé si elle existe déjà, sinon en générer une nouvelle
    String? storedKey = await _secureStorage.read(key: 'encryption_key');
    if (storedKey == null) {
      final key = encrypt.Key.fromSecureRandom(32);
      await _secureStorage.write(
        key: 'encryption_key',
        value: base64Encode(key.bytes),
      );
      _encryptionKey = key;
    } else {
      _encryptionKey = encrypt.Key(base64Decode(storedKey));
    }
  }

  // Chiffrer des données
  String _encryptData(String data) {
    if (_encryptionKey == null) {
      throw Exception("Encryption key not initialized");
    }
    final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey!));
    final encrypted = encrypter.encrypt(data, iv: _iv);
    return encrypted.base64;
  }

  // Déchiffrer des données
  String _decryptData(String encryptedData) {
    if (_encryptionKey == null) {
      throw Exception("Encryption key not initialized");
    }
    final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey!));
    final decrypted = encrypter.decrypt64(encryptedData, iv: _iv);
    return decrypted;
  }

  // Sauvegarder les informations utilisateur
  Future<void> saveUser(User user) async {
    await _initEncryptionKey();
    final userJson = jsonEncode(user.toJson());
    final encryptedData = _encryptData(userJson);
    await _secureStorage.write(key: 'user_data', value: encryptedData);
  }

  // Récupérer les informations utilisateur
  Future<User?> getUser() async {
    await _initEncryptionKey();
    final encryptedData = await _secureStorage.read(key: 'user_data');
    if (encryptedData == null) return null;
    
    final decryptedData = _decryptData(encryptedData);
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

  // Sauvegarder la liste des mots de passe (pour le mode hors ligne)
  Future<void> savePasswordItems(List<PasswordItem> items) async {
    await _initEncryptionKey();
    final itemsJson = jsonEncode(items.map((e) => e.toJson()).toList());
    final encryptedData = _encryptData(itemsJson);
    await _secureStorage.write(key: 'password_items', value: encryptedData);
  }

  // Récupérer la liste des mots de passe (pour le mode hors ligne)
  Future<List<PasswordItem>> getPasswordItems() async {
    await _initEncryptionKey();
    final encryptedData = await _secureStorage.read(key: 'password_items');
    if (encryptedData == null) return [];
    
    final decryptedData = _decryptData(encryptedData);
    final itemsMap = jsonDecode(decryptedData) as List;
    return itemsMap.map((e) => PasswordItem.fromJson(e)).toList();
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
  }
}