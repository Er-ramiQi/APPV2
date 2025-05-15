// lib/services/password_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import '../models/password_item.dart';
import 'api_service.dart';
import 'secure_storage_service.dart';
import 'sync_service.dart';

class PasswordService {
  // Singleton
  static final PasswordService _instance = PasswordService._internal();
  factory PasswordService() => _instance;
  PasswordService._internal();

  final ApiService _apiService = ApiService();
  final SecureStorageService _secureStorage = SecureStorageService();
  final SyncService _syncService = SyncService();
  
  // Évaluateur de force de mot de passe
  static const int _minPasswordLength = 8;
  static const int _optimalPasswordLength = 16;
  static const String _lowercaseChars = 'abcdefghijklmnopqrstuvwxyz';
  static const String _uppercaseChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _numericChars = '0123456789';
  static const String _specialChars = '!@#\$%^&*()_+-=[]{}|;:,.<>?';
  
  // Vérifier la connexion internet
  Future<bool> _isOnline() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // Récupérer tous les mots de passe
  Future<List<PasswordItem>> getAllPasswords() async {
    try {
      // Vérifier si on est en ligne
      final bool isOnline = await _isOnline();
      
      if (isOnline) {
        // En ligne: récupérer depuis l'API et synchroniser localement
        try {
          final response = await _apiService.get('/passwords');
          
          if (response.statusCode == 200) {
            final List<dynamic> data = json.decode(response.body);
            final List<PasswordItem> passwords = data
                .map((item) => PasswordItem.fromJson(item))
                .toList();
            
            // Mettre à jour le stockage local
            await _secureStorage.savePasswordItems(passwords);
            
            return passwords;
          }
        } catch (e) {
          print('Erreur lors de la récupération des mots de passe en ligne: $e');
          // En cas d'erreur, charger depuis le stockage local
        }
      }
      
      // Hors ligne ou erreur en ligne: récupérer depuis le stockage local
      return await _secureStorage.getPasswordItems();
    } catch (e) {
      // En cas d'erreur, essayer de récupérer depuis le stockage local
      try {
        return await _secureStorage.getPasswordItems();
      } catch (localError) {
        throw Exception('Impossible de récupérer les mots de passe: $e, $localError');
      }
    }
  }

  // Récupérer un mot de passe par ID
  Future<PasswordItem?> getPasswordById(String id) async {
    try {
      // Vérifier si on est en ligne
      final bool isOnline = await _isOnline();
      
      if (isOnline) {
        // En ligne: récupérer depuis l'API
        try {
          final response = await _apiService.get('/passwords/$id');
          
          if (response.statusCode == 200) {
            final Map<String, dynamic> data = json.decode(response.body);
            return PasswordItem.fromJson(data);
          }
        } catch (e) {
          print('Erreur lors de la récupération du mot de passe en ligne: $e');
          // En cas d'erreur, chercher dans le stockage local
        }
      }
      
      // Hors ligne ou erreur en ligne: chercher dans le stockage local
      final List<PasswordItem> localPasswords = await _secureStorage.getPasswordItems();
      return localPasswords.firstWhere(
        (item) => item.id == id,
        orElse: () => throw Exception('Mot de passe non trouvé'),
      );
    } catch (e) {
      throw Exception('Erreur lors de la récupération du mot de passe: $e');
    }
  }

  // Ajouter un nouveau mot de passe
  Future<PasswordItem> addPassword(PasswordItem password) async {
    try {
      // Vérifier la force du mot de passe
      final strengthScore = calculatePasswordStrength(password.password);
      
      // Avertir si le mot de passe est faible (<40)
      if (strengthScore < 40) {
        print('Avertissement: Mot de passe faible (score: $strengthScore)');
      }
      
      // Créer une copie avec le score de force
      final passwordWithScore = password.copyWith(strengthScore: strengthScore);
      
      // Vérifier si on est en ligne
      final bool isOnline = await _isOnline();
      
      if (isOnline) {
        // En ligne: envoyer à l'API
        try {
          final response = await _apiService.post(
            '/passwords',
            body: passwordWithScore.toJson(),
          );
          
          if (response.statusCode == 201) {
            final Map<String, dynamic> data = json.decode(response.body);
            final PasswordItem newPassword = PasswordItem.fromJson(data);
            
            // Mettre à jour le stockage local
            final List<PasswordItem> localPasswords = await _secureStorage.getPasswordItems();
            localPasswords.add(newPassword);
            await _secureStorage.savePasswordItems(localPasswords);
            
            return newPassword;
          } else {
            throw Exception('Échec de l\'ajout du mot de passe: ${response.body}');
          }
        } catch (e) {
          // En cas d'erreur API, continuer avec le stockage local
          print('Erreur lors de l\'ajout du mot de passe en ligne: $e');
        }
      }
      
      // Hors ligne ou erreur en ligne: ajouter uniquement au stockage local
      // Générer un ID temporaire pour le mode hors ligne
      final DateTime now = DateTime.now();
      final String tempId = 'temp_${now.millisecondsSinceEpoch}_${_generateRandomString(8)}';
      final PasswordItem tempPassword = PasswordItem(
        id: tempId,
        title: passwordWithScore.title,
        username: passwordWithScore.username,
        password: passwordWithScore.password,
        website: passwordWithScore.website,
        notes: passwordWithScore.notes,
        category: passwordWithScore.category,
        isFavorite: passwordWithScore.isFavorite,
        strengthScore: strengthScore,
        createdAt: now,
        lastModified: now,
      );
      
      final List<PasswordItem> localPasswords = await _secureStorage.getPasswordItems();
      localPasswords.add(tempPassword);
      await _secureStorage.savePasswordItems(localPasswords);
      
      // Marquer ce mot de passe pour synchronisation ultérieure
      await _syncService.addToSyncQueue('create', tempPassword);
      
      return tempPassword;
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout du mot de passe: $e');
    }
  }

  // Mettre à jour un mot de passe existant
  Future<PasswordItem> updatePassword(PasswordItem password) async {
    try {
      // Recalculer le score de force
      final strengthScore = calculatePasswordStrength(password.password);
      
      // Créer une copie avec le score mis à jour
      final passwordWithScore = password.copyWith(
        strengthScore: strengthScore,
        lastModified: DateTime.now(),
      );
      
      // Vérifier si on est en ligne
      final bool isOnline = await _isOnline();
      
      if (isOnline && !password.id.startsWith('temp_')) {
        // En ligne (et ID non temporaire): envoyer à l'API
        try {
          final response = await _apiService.put(
            '/passwords/${password.id}',
            body: passwordWithScore.toJson(),
          );
          
          if (response.statusCode == 200) {
            final Map<String, dynamic> data = json.decode(response.body);
            final PasswordItem updatedPassword = PasswordItem.fromJson(data);
            
            // Mettre à jour le stockage local
            final List<PasswordItem> localPasswords = await _secureStorage.getPasswordItems();
            final int index = localPasswords.indexWhere((item) => item.id == password.id);
            
            if (index != -1) {
              localPasswords[index] = updatedPassword;
              await _secureStorage.savePasswordItems(localPasswords);
            }
            
            return updatedPassword;
          } else {
            throw Exception('Échec de la mise à jour du mot de passe: ${response.body}');
          }
        } catch (e) {
          // En cas d'erreur API, continuer avec le stockage local
          print('Erreur lors de la mise à jour du mot de passe en ligne: $e');
        }
      }
      
      // Hors ligne ou erreur en ligne: mettre à jour uniquement le stockage local
      final List<PasswordItem> localPasswords = await _secureStorage.getPasswordItems();
      final int index = localPasswords.indexWhere((item) => item.id == password.id);
      
      if (index != -1) {
        localPasswords[index] = passwordWithScore;
        await _secureStorage.savePasswordItems(localPasswords);
        
        // Marquer ce mot de passe pour synchronisation ultérieure
        await _syncService.addToSyncQueue('update', passwordWithScore);
        
        return passwordWithScore;
      } else {
        throw Exception('Mot de passe non trouvé dans le stockage local');
      }
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du mot de passe: $e');
    }
  }

  // Supprimer un mot de passe
  Future<bool> deletePassword(String id) async {
    try {
      // Vérifier si on est en ligne
      final bool isOnline = await _isOnline();
      
      if (isOnline && !id.startsWith('temp_')) {
        // En ligne (et ID non temporaire): envoyer à l'API
        try {
          final response = await _apiService.delete('/passwords/$id');
          
          if (response.statusCode == 200) {
            // Supprimer du stockage local
            final List<PasswordItem> localPasswords = await _secureStorage.getPasswordItems();
            localPasswords.removeWhere((item) => item.id == id);
            await _secureStorage.savePasswordItems(localPasswords);
            
            return true;
          } else {
            throw Exception('Échec de la suppression du mot de passe: ${response.body}');
          }
        } catch (e) {
          // En cas d'erreur API, continuer avec le stockage local
          print('Erreur lors de la suppression du mot de passe en ligne: $e');
        }
      }
      
      // Hors ligne ou erreur en ligne: supprimer du stockage local
      final List<PasswordItem> localPasswords = await _secureStorage.getPasswordItems();
      
      // Récupérer le mot de passe avant de le supprimer pour le marquer pour synchronisation
      final PasswordItem? passwordToDelete = localPasswords.firstWhere(
        (item) => item.id == id,
        orElse: () => throw Exception('Mot de passe non trouvé'),
      );
      
      localPasswords.removeWhere((item) => item.id == id);
      await _secureStorage.savePasswordItems(localPasswords);
      
      // Marquer ce mot de passe pour synchronisation ultérieure
      if (!id.startsWith('temp_') && passwordToDelete != null) {
        await _syncService.addToSyncQueue('delete', passwordToDelete);
      }
      
      return true;
    } catch (e) {
      throw Exception('Erreur lors de la suppression du mot de passe: $e');
    }
  }

  // Rechercher des mots de passe
  Future<List<PasswordItem>> searchPasswords(String query) async {
    final List<PasswordItem> allPasswords = await getAllPasswords();
    
    if (query.isEmpty) {
      return allPasswords;
    }
    
    final queryLower = query.toLowerCase();
    
    // Recherche dans différents champs
    return allPasswords.where((password) {
      return password.title.toLowerCase().contains(queryLower) ||
             password.username.toLowerCase().contains(queryLower) ||
             password.website.toLowerCase().contains(queryLower) ||
             password.notes.toLowerCase().contains(queryLower) ||
             password.category.toLowerCase().contains(queryLower);
    }).toList();
  }

  // Filtrer les mots de passe par catégorie
  Future<List<PasswordItem>> filterPasswordsByCategory(String category) async {
    final List<PasswordItem> allPasswords = await getAllPasswords();
    
    if (category.isEmpty || category.toLowerCase() == 'all' || category.toLowerCase() == 'tout') {
      return allPasswords;
    }
    
    return allPasswords.where((password) {
      return password.category.toLowerCase() == category.toLowerCase();
    }).toList();
  }

  // Obtenir les statistiques des mots de passe
  Future<Map<String, dynamic>> getPasswordStatistics() async {
    final List<PasswordItem> allPasswords = await getAllPasswords();
    
    // Statistiques de base
    int totalPasswords = allPasswords.length;
    int weakPasswords = 0;
    int mediumPasswords = 0;
    int strongPasswords = 0;
    Set<String> uniqueWebsites = {};
    Map<String, int> categoryCounts = {};
    
    // Statistiques de duplication
    int reusedPasswords = 0;
    Map<String, int> passwordHashes = {}; // Pour détecter les réutilisations
    
    // Vérifier l'âge des mots de passe
    int outdatedPasswords = 0; // Mots de passe de plus de 90 jours
    final DateTime now = DateTime.now();
    final DateTime threeMonthsAgo = now.subtract(const Duration(days: 90));
    
    for (var password in allPasswords) {
      // Compteur de force
      final strength = password.getPasswordStrengthCategory();
      if (strength == 'Faible') {
        weakPasswords++;
      } else if (strength == 'Moyen') {
        mediumPasswords++;
      } else {
        strongPasswords++;
      }
      
      // Sites web uniques
      if (password.website.isNotEmpty) {
        String domain = _extractDomain(password.website);
        uniqueWebsites.add(domain);
      }
      
      // Catégories
      String category = password.category.isEmpty ? 'general' : password.category;
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
      
      // Mots de passe réutilisés (par hash)
      String passwordHash = _hashString(password.password);
      passwordHashes[passwordHash] = (passwordHashes[passwordHash] ?? 0) + 1;
      
      // Âge des mots de passe
      if (password.lastModified.isBefore(threeMonthsAgo)) {
        outdatedPasswords++;
      }
    }
    
    // Compter les mots de passe réutilisés
    for (var count in passwordHashes.values) {
      if (count > 1) {
        reusedPasswords++;
      }
    }
    
    // Score de sécurité global (sur 100)
    double securityScore = 100;
    
    // Pénalités
    if (totalPasswords > 0) {
      // Pénalité pour les mots de passe faibles
      securityScore -= (weakPasswords / totalPasswords) * 30;
      
      // Pénalité pour les mots de passe réutilisés
      securityScore -= (reusedPasswords / totalPasswords) * 20;
      
      // Pénalité pour les mots de passe obsolètes
      securityScore -= (outdatedPasswords / totalPasswords) * 15;
    }
    
    // Limiter le score entre 0 et 100
    securityScore = securityScore.clamp(0, 100);
    
    return {
      'total_passwords': totalPasswords,
      'weak_passwords': weakPasswords,
      'medium_passwords': mediumPasswords,
      'strong_passwords': strongPasswords,
      'unique_websites': uniqueWebsites.length,
      'category_counts': categoryCounts,
      'reused_passwords': reusedPasswords,
      'outdated_passwords': outdatedPasswords,
      'security_score': securityScore.round(),
    };
  }

  // Générer un mot de passe sécurisé
  String generateSecurePassword({
    int length = 16,
    bool includeUppercase = true,
    bool includeLowercase = true,
    bool includeNumbers = true,
    bool includeSpecialChars = true,
  }) {
    if (!includeUppercase && !includeLowercase && !includeNumbers && !includeSpecialChars) {
      // Si aucun type de caractère n'est sélectionné, activer les minuscules par défaut
      includeLowercase = true;
    }

    String chars = '';
    if (includeUppercase) chars += _uppercaseChars;
    if (includeLowercase) chars += _lowercaseChars;
    if (includeNumbers) chars += _numericChars;
    if (includeSpecialChars) chars += _specialChars;

    // Générer le mot de passe
    final random = Random.secure();
    
    // S'assurer que le mot de passe contient au moins un caractère de chaque type sélectionné
    List<String> requiredChars = [];
    
    if (includeUppercase) {
      requiredChars.add(_uppercaseChars[random.nextInt(_uppercaseChars.length)]);
    }
    if (includeLowercase) {
      requiredChars.add(_lowercaseChars[random.nextInt(_lowercaseChars.length)]);
    }
    if (includeNumbers) {
      requiredChars.add(_numericChars[random.nextInt(_numericChars.length)]);
    }
    if (includeSpecialChars) {
      requiredChars.add(_specialChars[random.nextInt(_specialChars.length)]);
    }
    
    // Remplir le reste avec des caractères aléatoires
    List<String> passwordChars = List.filled(length, '');
    
    // Placer les caractères requis à des positions aléatoires
    for (String requiredChar in requiredChars) {
      int position;
      do {
        position = random.nextInt(length);
      } while (passwordChars[position].isNotEmpty);
      
      passwordChars[position] = requiredChar;
    }
    
    // Remplir les positions restantes
    for (int i = 0; i < length; i++) {
      if (passwordChars[i].isEmpty) {
        passwordChars[i] = chars[random.nextInt(chars.length)];
      }
    }
    
    // Mélanger une dernière fois
    passwordChars.shuffle(random);
    
    return passwordChars.join('');
  }

  // Calculer la force d'un mot de passe (0-100)
  int calculatePasswordStrength(String password) {
    double score = 0;
    
    // Longueur (jusqu'à 40 points)
    if (password.length >= _minPasswordLength) {
      score += min(40, password.length * 2.5);
    } else {
      // Longueur insuffisante
      score += password.length * 2;
    }
    
    // Diversité des caractères (jusqu'à 60 points)
    int charTypeCount = 0;
    
    if (password.contains(RegExp(r'[a-z]'))) {
      charTypeCount++;
      score += 10;
    }
    
    if (password.contains(RegExp(r'[A-Z]'))) {
      charTypeCount++;
      score += 10;
    }
    
    if (password.contains(RegExp(r'[0-9]'))) {
      charTypeCount++;
      score += 10;
    }
    
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      charTypeCount++;
      score += 20;
    }
    
    // Distribution des caractères (jusqu'à 10 points)
    if (charTypeCount >= 3 && password.length >= _minPasswordLength) {
      score += 10;
    }
    
    // Bonus pour longueur optimale
    if (password.length >= _optimalPasswordLength) {
      score += 10;
    }
    
    // Pénalités pour les schémas courants
    // Pattern séquentiel (123456, abcdef)
    if (_containsSequentialPattern(password)) {
      score -= 10;
    }
    
    // Répétition du même caractère
    if (_containsRepeatedCharacters(password)) {
      score -= 10;
    }
    
    // Limiter le score entre 0 et 100
    return score.round().clamp(0, 100);
  }

  // Vérifier si le mot de passe contient des séquences
  bool _containsSequentialPattern(String password) {
    const sequences = [
      'abcdefghijklmnopqrstuvwxyz',
      'qwertyuiopasdfghjklzxcvbnm',
      '01234567890',
    ];
    
    password = password.toLowerCase();
    
    for (String sequence in sequences) {
      for (int i = 0; i < sequence.length - 2; i++) {
        String pattern = sequence.substring(i, i + 3);
        if (password.contains(pattern)) {
          return true;
        }
      }
    }
    
    return false;
  }

  // Vérifier si le mot de passe contient des caractères répétés
  bool _containsRepeatedCharacters(String password) {
    for (int i = 0; i < password.length - 2; i++) {
      if (password[i] == password[i + 1] && password[i] == password[i + 2]) {
        return true;
      }
    }
    
    return false;
  }

  // Extraire le domaine d'une URL
  String _extractDomain(String url) {
    if (url.isEmpty) return '';
    
    String domain = url.toLowerCase();
    
    // Supprimer le protocole
    if (domain.contains('://')) {
      domain = domain.split('://')[1];
    }
    
    // Supprimer le chemin
    if (domain.contains('/')) {
      domain = domain.split('/')[0];
    }
    
    // Supprimer le port
    if (domain.contains(':')) {
      domain = domain.split(':')[0];
    }
    
    // Supprimer 'www.'
    if (domain.startsWith('www.')) {
      domain = domain.replaceFirst('www.', '');
    }
    
    return domain;
  }

  // Hachage simple pour détecter les duplications (sans stocker le mot de passe)
  String _hashString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Générer une chaîne aléatoire
  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return String.fromCharCodes(
      List.generate(length, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
  }
}