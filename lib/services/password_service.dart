// services/password_service.dart
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/password_item.dart';
import 'api_service.dart';
import 'secure_storage_service.dart';

class PasswordService {
  // Singleton
  static final PasswordService _instance = PasswordService._internal();
  factory PasswordService() => _instance;
  PasswordService._internal();

  final ApiService _apiService = ApiService();
  final SecureStorageService _secureStorage = SecureStorageService();
  
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
        final response = await _apiService.get('/passwords');
        
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          final List<PasswordItem> passwords = data
              .map((item) => PasswordItem.fromJson(item))
              .toList();
          
          // Mettre à jour le stockage local
          await _secureStorage.savePasswordItems(passwords);
          
          return passwords;
        } else {
          // En cas d'erreur, essayer de récupérer depuis le stockage local
          return await _secureStorage.getPasswordItems();
        }
      } else {
        // Hors ligne: récupérer depuis le stockage local
        return await _secureStorage.getPasswordItems();
      }
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
        final response = await _apiService.get('/passwords/$id');
        
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          return PasswordItem.fromJson(data);
        } else {
          // En cas d'erreur, chercher dans le stockage local
          final List<PasswordItem> localPasswords = await _secureStorage.getPasswordItems();
          return localPasswords.firstWhere(
            (item) => item.id == id,
            orElse: () => throw Exception('Mot de passe non trouvé'),
          );
        }
      } else {
        // Hors ligne: chercher dans le stockage local
        final List<PasswordItem> localPasswords = await _secureStorage.getPasswordItems();
        return localPasswords.firstWhere(
          (item) => item.id == id,
          orElse: () => throw Exception('Mot de passe non trouvé'),
        );
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération du mot de passe: $e');
    }
  }

  // Ajouter un nouveau mot de passe
  Future<PasswordItem> addPassword(PasswordItem password) async {
    try {
      // Vérifier si on est en ligne
      final bool isOnline = await _isOnline();
      
      if (isOnline) {
        // En ligne: envoyer à l'API
        final response = await _apiService.post(
          '/passwords',
          body: password.toJson(),
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
      } else {
        // Hors ligne: ajouter uniquement au stockage local
        // Générer un ID temporaire pour le mode hors ligne
        final DateTime now = DateTime.now();
        final String tempId = 'temp_${now.millisecondsSinceEpoch}';
        final PasswordItem tempPassword = PasswordItem(
          id: tempId,
          title: password.title,
          username: password.username,
          password: password.password,
          website: password.website,
          notes: password.notes,
          createdAt: now,
          lastModified: now,
        );
        
        final List<PasswordItem> localPasswords = await _secureStorage.getPasswordItems();
        localPasswords.add(tempPassword);
        await _secureStorage.savePasswordItems(localPasswords);
        
        // Marquer ce mot de passe pour synchronisation ultérieure
        await _markForSync('add', tempPassword);
        
        return tempPassword;
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout du mot de passe: $e');
    }
  }

  // Mettre à jour un mot de passe existant
  Future<PasswordItem> updatePassword(PasswordItem password) async {
    try {
      // Vérifier si on est en ligne
      final bool isOnline = await _isOnline();
      
      if (isOnline) {
        // En ligne: envoyer à l'API
        final response = await _apiService.put(
          '/passwords/${password.id}',
          body: password.toJson(),
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
      } else {
        // Hors ligne: mettre à jour uniquement le stockage local
        final List<PasswordItem> localPasswords = await _secureStorage.getPasswordItems();
        final int index = localPasswords.indexWhere((item) => item.id == password.id);
        
        if (index != -1) {
          // Mettre à jour avec la date de modification
          final PasswordItem updatedPassword = PasswordItem(
            id: password.id,
            title: password.title,
            username: password.username,
            password: password.password,
            website: password.website,
            notes: password.notes,
            createdAt: localPasswords[index].createdAt,
            lastModified: DateTime.now(),
          );
          
          localPasswords[index] = updatedPassword;
          await _secureStorage.savePasswordItems(localPasswords);
          
          // Marquer ce mot de passe pour synchronisation ultérieure
          await _markForSync('update', updatedPassword);
          
          return updatedPassword;
        } else {
          throw Exception('Mot de passe non trouvé dans le stockage local');
        }
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
      
      if (isOnline) {
        // En ligne: envoyer à l'API
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
      } else {
        // Hors ligne: supprimer du stockage local
        final List<PasswordItem> localPasswords = await _secureStorage.getPasswordItems();
        
        // Récupérer le mot de passe avant de le supprimer pour le marquer pour synchronisation
        final PasswordItem passwordToDelete = localPasswords.firstWhere(
          (item) => item.id == id,
          orElse: () => throw Exception('Mot de passe non trouvé'),
        );
        
        localPasswords.removeWhere((item) => item.id == id);
        await _secureStorage.savePasswordItems(localPasswords);
        
        // Marquer ce mot de passe pour synchronisation ultérieure
        if (!id.startsWith('temp_')) {
          await _markForSync('delete', passwordToDelete);
        }
        
        return true;
      }
    } catch (e) {
      throw Exception('Erreur lors de la suppression du mot de passe: $e');
    }
  }

  // Marquer un mot de passe pour synchronisation
  Future<void> _markForSync(String action, PasswordItem password) async {
    try {
      // Récupérer les éléments à synchroniser
      String? syncDataString = await _secureStorage._secureStorage.read(key: 'sync_queue');
      List<Map<String, dynamic>> syncQueue = [];
      
      final List<dynamic> data = json.decode(syncDataString);
      syncQueue = data.cast<Map<String, dynamic>>();
          
      // Ajouter l'élément à la file d'attente
      syncQueue.add({
        'action': action,
        'password': password.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      // Sauvegarder la file d'attente mise à jour
      await _secureStorage._secureStorage.write(
        key: 'sync_queue',
        value: jsonEncode(syncQueue),
      );
    } catch (e) {
      print('Erreur lors du marquage pour synchronisation: $e');
    }
  }

  // Synchroniser les modifications locales avec le serveur
  Future<bool> syncWithServer() async {
    try {
      // Vérifier si on est en ligne
      final bool isOnline = await _isOnline();
      if (!isOnline) return false;
      
      // Récupérer la file d'attente de synchronisation
      String? syncDataString = await _secureStorage._secureStorage.read(key: 'sync_queue'); // Rien à synchroniser
      
      final List<dynamic> data = json.decode(syncDataString);
      final List<Map<String, dynamic>> syncQueue = data.cast<Map<String, dynamic>>();
      
      if (syncQueue.isEmpty) return true; // File d'attente vide
      
      // Traiter chaque élément de la file d'attente
      for (final item in syncQueue) {
        final String action = item['action'];
        final PasswordItem password = PasswordItem.fromJson(item['password']);
        
        switch (action) {
          case 'add':
            // Si c'est un ajout avec un ID temporaire
            if (password.id.startsWith('temp_')) {
              // Créer un nouveau mot de passe sans l'ID
              final Map<String, dynamic> newPasswordData = password.toJson();
              newPasswordData.remove('id'); // Laisser le serveur générer un ID
              
              final response = await _apiService.post(
                '/passwords',
                body: newPasswordData,
              );
              
              if (response.statusCode == 201) {
                // Mettre à jour l'ID local avec celui du serveur
                final Map<String, dynamic> serverData = json.decode(response.body);
                final PasswordItem serverPassword = PasswordItem.fromJson(serverData);
                
                final List<PasswordItem> localPasswords = await _secureStorage.getPasswordItems();
                final int index = localPasswords.indexWhere((p) => p.id == password.id);
                
                if (index != -1) {
                  localPasswords[index] = serverPassword;
                  await _secureStorage.savePasswordItems(localPasswords);
                }
              }
            } else {
              await _apiService.post('/passwords', body: password.toJson());
            }
            break;
            
          case 'update':
            await _apiService.put('/passwords/${password.id}', body: password.toJson());
            break;
            
          case 'delete':
            await _apiService.delete('/passwords/${password.id}');
            break;
        }
      }
      
      // Vider la file d'attente après synchronisation
      await _secureStorage._secureStorage.write(key: 'sync_queue', value: jsonEncode([]));
      
      // Rafraîchir les données locales depuis le serveur
      final response = await _apiService.get('/passwords');
      if (response.statusCode == 200) {
        final List<dynamic> serverData = json.decode(response.body);
        final List<PasswordItem> passwords = serverData
            .map((item) => PasswordItem.fromJson(item))
            .toList();
        
        await _secureStorage.savePasswordItems(passwords);
      }
      
      return true;
    } catch (e) {
      print('Erreur lors de la synchronisation: $e');
      return false;
    }
  }
}