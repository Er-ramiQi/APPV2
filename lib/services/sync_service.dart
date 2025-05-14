// lib/services/sync_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'secure_storage_service.dart';
import 'security_service.dart';
import '../models/password_item.dart';

class SyncService {
  // Singleton
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final ApiService _apiService = ApiService();
  final SecureStorageService _secureStorage = SecureStorageService();
  final SecurityService _securityService = SecurityService();
  
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isSyncing = false;
  
  // Constantes de configuration
  static const int _syncIntervalMinutes = 15; // Intervalle de synchronisation en minutes
  static const int _maxSyncQueueSize = 100; // Taille maximale de la file d'attente
  
  // Initialiser le service de synchronisation
  Future<void> initialize() async {
    // Vérifier d'abord la sécurité de l'appareil
    final bool isDeviceSecure = await _securityService.isDeviceSecure();
    if (!isDeviceSecure) {
      if (kDebugMode) {
        print('Appareil non sécurisé détecté, synchronisation désactivée');
      }
      return;
    }
    
    // Écouter les changements de connectivité
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      // Lorsque la connexion est rétablie, tenter une synchronisation
      if (result != ConnectivityResult.none) {
        syncIfNeeded();
      }
    });
    
    // Tenter une synchronisation au démarrage
    await syncIfNeeded();
    
    // Configurer une synchronisation périodique
    setupPeriodicSync();
  }

  // Nettoyer les ressources
  void dispose() {
    _connectivitySubscription?.cancel();
  }

  // Déclencher une synchronisation si nécessaire
  Future<bool> syncIfNeeded() async {
    // Éviter les synchronisations simultanées
    if (_isSyncing) return false;
    
    // Vérifier s'il y a des changements à synchroniser
    final bool hasChanges = await hasUnsyncedData();
    if (!hasChanges) return true; // Tout est déjà synchronisé
    
    _isSyncing = true;
    bool success = false;
    
    try {
      // Vérifier la connectivité
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        _isSyncing = false;
        return false;
      }
      
      // Vérifier si l'utilisateur est authentifié
      final String? authToken = await _secureStorage.getAuthToken();
      if (authToken == null) {
        _isSyncing = false;
        return false; // L'utilisateur n'est pas connecté
      }
      
      // Synchroniser les données
      success = await _syncWithServer();
      
      // Si la synchronisation échoue, réessayer plus tard
      if (!success) {
        await _scheduleRetry();
      }
      
      return success;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur de synchronisation: $e');
      }
      await _scheduleRetry();
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  // Planifier une nouvelle tentative de synchronisation
  Future<void> _scheduleRetry() async {
    // Récupérer le nombre d'échecs précédents
    String? retriesStr = await _secureStorage.getSecuritySetting('sync_retries');
    int retries = retriesStr != null ? int.parse(retriesStr) : 0;
    
    // Incrémenter et sauvegarder
    retries++;
    await _secureStorage.saveSecuritySetting('sync_retries', retries.toString());
    
    // Calculer le délai avec backoff exponentiel (1min, 2min, 4min, 8min...)
    int delayMinutes = 1 << (retries - 1);
    if (delayMinutes > 60) delayMinutes = 60; // Max 1h
    
    // Sauvegarder l'heure de la prochaine tentative
    final nextRetry = DateTime.now().add(Duration(minutes: delayMinutes));
    await _secureStorage.saveSecuritySetting('next_sync_retry', nextRetry.toIso8601String());
  }

  // Synchroniser avec le serveur
  Future<bool> _syncWithServer() async {
    try {
      // Récupérer la file d'attente de synchronisation
      final List<Map<String, dynamic>> syncQueue = await _getSyncQueue();
      
      if (syncQueue.isEmpty) {
        // File d'attente vide, rien à synchroniser
        return true;
      }
      
      // Envoyer les données au serveur
      final response = await _apiService.syncPasswords(syncQueue);
      
      if (response) {
        // Synchronisation réussie, vider la file d'attente
        await _clearSyncQueue();
        
        // Réinitialiser le compteur de tentatives
        await _secureStorage.saveSecuritySetting('sync_retries', '0');
        
        // Mettre à jour la dernière synchronisation réussie
        await _secureStorage.saveSecuritySetting(
          'last_sync_success', 
          DateTime.now().toIso8601String()
        );
        
        return true;
      } else {
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la synchronisation: $e');
      }
      return false;
    }
  }

  // Ajouter une opération à la file d'attente de synchronisation
  Future<void> addToSyncQueue(String operation, PasswordItem item) async {
    try {
      // Récupérer la file d'attente existante
      final List<Map<String, dynamic>> queue = await _getSyncQueue();
      
      // Limiter la taille de la file
      if (queue.length >= _maxSyncQueueSize) {
        // Supprimer les entrées les plus anciennes
        queue.removeRange(0, queue.length - _maxSyncQueueSize + 1);
      }
      
      // Ajouter la nouvelle opération
      queue.add({
        'operation': operation, // 'create', 'update', 'delete'
        'item': item.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      // Sauvegarder la file mise à jour
      await _saveSyncQueue(queue);
      
      // Tenter de synchroniser immédiatement si possible
      unawaited(syncIfNeeded());
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de l\'ajout à la file de synchronisation: $e');
      }
    }
  }

  // Récupérer la file d'attente de synchronisation
  Future<List<Map<String, dynamic>>> _getSyncQueue() async {
    try {
      final String? queueJson = await _secureStorage.getSecuritySetting('sync_queue');
      
      if (queueJson == null || queueJson.isEmpty) {
        return [];
      }
      
      final List<dynamic> decodedList = jsonDecode(queueJson);
      return List<Map<String, dynamic>>.from(decodedList);
    } catch (e) {
      // En cas d'erreur, renvoyer une file vide
      return [];
    }
  }

  // Sauvegarder la file d'attente
  Future<void> _saveSyncQueue(List<Map<String, dynamic>> queue) async {
    final String queueJson = jsonEncode(queue);
    await _secureStorage.saveSecuritySetting('sync_queue', queueJson);
  }

  // Vider la file d'attente
  Future<void> _clearSyncQueue() async {
    await _secureStorage.saveSecuritySetting('sync_queue', '[]');
  }

  // Vérifier s'il y a des données à synchroniser
  Future<bool> hasUnsyncedData() async {
    try {
      final List<Map<String, dynamic>> queue = await _getSyncQueue();
      return queue.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Définir un intervalle de synchronisation périodique
  void setupPeriodicSync({Duration? interval}) {
    final syncInterval = interval ?? const Duration(minutes: _syncIntervalMinutes);
    
    Timer.periodic(syncInterval, (timer) {
      syncIfNeeded();
    });
  }

  // Forcer une synchronisation immédiate
  Future<bool> forceSync() async {
    return await syncIfNeeded();
  }

  // Obtenir la date de la dernière synchronisation réussie
  Future<DateTime?> getLastSyncTime() async {
    try {
      final String? lastSyncStr = await _secureStorage.getSecuritySetting('last_sync_success');
      
      if (lastSyncStr == null || lastSyncStr.isEmpty) {
        return null;
      }
      
      return DateTime.parse(lastSyncStr);
    } catch (e) {
      return null;
    }
  }

  // Récupérer le statut de synchronisation
  Future<Map<String, dynamic>> getSyncStatus() async {
    final DateTime? lastSync = await getLastSyncTime();
    final bool hasPending = await hasUnsyncedData();
    final String? retriesStr = await _secureStorage.getSecuritySetting('sync_retries');
    final int retries = retriesStr != null ? int.parse(retriesStr) : 0;
    
    return {
      'last_sync': lastSync?.toIso8601String(),
      'has_pending_changes': hasPending,
      'retry_count': retries,
      'is_syncing': _isSyncing,
    };
  }

  // Réinitialiser l'état de synchronisation (en cas de problème)
  Future<void> resetSyncState() async {
    await _clearSyncQueue();
    await _secureStorage.saveSecuritySetting('sync_retries', '0');
    await _secureStorage.saveSecuritySetting('next_sync_retry', '');
  }
}