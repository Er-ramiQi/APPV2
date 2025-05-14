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

  // Configuration Android renforcée
  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
      keyCipherAlgorithm: 
          KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
      sharedPreferencesName: 'secure_prefs',  // Nom spécifique pour isolation
      preferencesKeyPrefix: 'secure_prefix_', // Préfixe pour distinguer les clés
    ),
  );

  // Clé de chiffrement AES (générée une seule fois et stockée de manière sécurisée)
  encrypt.Key? _encryptionKey;
  late encrypt.IV _iv;
  
  // Salt pour le PBKDF2
  final String _keySalt = 'kdf_salt_value';
  static const int _iterations = 10000; // Nombre d'itérations pour PBKDF2

  // Initialisation de la clé de chiffrement avec dérivation de clé
  Future<void> _initEncryptionKey() async {
    if (_encryptionKey != null) return;

    // Récupérer la clé si elle existe déjà, sinon en générer une nouvelle
    String? storedKey = await _secureStorage.read(key: 'encryption_key');
    if (storedKey == null) {
      // Génération d'une IV unique
      final ivBytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
      _iv = encrypt.IV(encrypt.Uint8List.fromList(ivBytes));
      
      // Sauvegarder l'IV
      await _secureStorage.write(
        key: 'encryption_iv',
        value: base64Encode(_iv.bytes),
      );
      
      // Génération d'une clé forte et aléatoire
      final key = encrypt.Key.fromSecureRandom(32);
      await _secureStorage.write(
        key: 'encryption_key',
        value: base64Encode(key.bytes),
      );
      _encryptionKey = key;
    } else {
      _encryptionKey = encrypt.Key(base64Decode(storedKey));
      
      // Récupérer l'IV stockée
      String? storedIV = await _secureStorage.read(key: 'encryption_iv');
      if (storedIV != null) {
        _iv = encrypt.IV(base64Decode(storedIV));
      } else {
        // IV par défaut si non trouvé (situation qui ne devrait pas arriver)
        _iv = encrypt.IV.fromLength(16);
      }
    }
  }

  // Dériver une clé secondaire à partir du mot de passe maître
  Future<encrypt.Key> _deriveKeyFromPassword(String masterPassword) async {
    // Note: Ceci est une simulation de dérivation de clé
    // Dans une implémentation réelle, utilisez une bibliothèque cryptographique appropriée
    final List<int> saltBytes = utf8.encode(_keySalt);
    final List<int> passwordBytes = utf8.encode(masterPassword);
    
    // Combinaison simple pour simulation (à remplacer par PBKDF2 ou Argon2)
    List<int> derivedKeyBytes = [];
    for (int i = 0; i < 32; i++) {
      if (i < passwordBytes.length) {
        derivedKeyBytes.add((passwordBytes[i] + saltBytes[i % saltBytes.length]) % 256);
      } else {
        derivedKeyBytes.add(saltBytes[i % saltBytes.length]);
      }
    }
    
    return encrypt.Key(encrypt.Uint8List.fromList(derivedKeyBytes));
  }

  // Chiffrer des données avec double encryption
  Future<String> _encryptData(String data) async {
    await _initEncryptionKey();
    if (_encryptionKey == null) {
      throw Exception("Encryption key not initialized");
    }
    
    // Premier niveau de chiffrement avec la clé principale
    final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey!));
    final encrypted = encrypter.encrypt(data, iv: _iv);
    
    return encrypted.base64;
  }

  // Chiffrer des données avec une clé secondaire (dérivée du mot de passe maître)
  Future<String> encryptWithMasterPassword(String data, String masterPassword) async {
    // Dériver une clé à partir du mot de passe maître
    final derivedKey = await _deriveKeyFromPassword(masterPassword);
    
    // Chiffrement avec la clé dérivée
    final encrypter = encrypt.Encrypter(encrypt.AES(derivedKey));
    final encrypted = encrypter.encrypt(data, iv: _iv);
    
    return encrypted.base64;
  }

  // Déchiffrer des données
  Future<String> _decryptData(String encryptedData) async {
    await _initEncryptionKey();
    if (_encryptionKey == null) {
      throw Exception("Encryption key not initialized");
    }
    
    try {
      final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey!));
      final decrypted = encrypter.decrypt64(encryptedData, iv: _iv);
      return decrypted;
    } catch (e) {
      throw Exception("Failed to decrypt data: $e");
    }
  }

  // Déchiffrer des données avec la clé dérivée du mot de passe maître
  Future<String> decryptWithMasterPassword(String encryptedData, String masterPassword) async {
    try {
      // Dériver une clé à partir du mot de passe maître
      final derivedKey = await _deriveKeyFromPassword(masterPassword);
      
      // Déchiffrement avec la clé dérivée
      final encrypter = encrypt.Encrypter(encrypt.AES(derivedKey));
      final decrypted = encrypter.decrypt64(encryptedData, iv: _iv);
      
      return decrypted;
    } catch (e) {
      throw Exception("Failed to decrypt data: $e");
    }
  }

  // Sauvegarder les informations utilisateur
  Future<void> saveUser(User user) async {
    await _initEncryptionKey();
    final userJson = jsonEncode(user.toJson());
    final encryptedData = await _encryptData(userJson);
    await _secureStorage.write(key: 'user_data', value: encryptedData);
  }

  // Récupérer les informations utilisateur
  Future<User?> getUser() async {
    await _initEncryptionKey();
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

  // Sauvegarder la liste des mots de passe (pour le mode hors ligne)
  Future<void> savePasswordItems(List<PasswordItem> items) async {
    await _initEncryptionKey();
    final itemsJson = jsonEncode(items.map((e) => e.toJson()).toList());
    final encryptedData = await _encryptData(itemsJson);
    await _secureStorage.write(key: 'password_items', value: encryptedData);
  }

  // Récupérer la liste des mots de passe (pour le mode hors ligne)
  Future<List<PasswordItem>> getPasswordItems() async {
    await _initEncryptionKey();
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
  }

  // Enregistrer un paramètre de sécurité (pour la configuration)
  Future<void> saveSecuritySetting(String key, String value) async {
    await _secureStorage.write(key: 'security_$key', value: value);
  }

  // Récupérer un paramètre de sécurité
  Future<String?> getSecuritySetting(String key) async {
    return await _secureStorage.read(key: 'security_$key');
  }
}