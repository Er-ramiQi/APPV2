// services/sync_service.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'password_service.dart';

class SyncService {
  // Singleton
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final PasswordService _passwordService = PasswordService();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isSyncing = false;
  
  // Initialiser le service de synchronisation
  void initialize() {
    // Écouter les changements de connectivité
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      // Lorsque la connexion est rétablie, tenter une synchronisation
      if (result != ConnectivityResult.none) {
        syncIfNeeded();
      }
    });
    
    // Tenter une synchronisation au démarrage
    syncIfNeeded();
  }

  // Nettoyer les ressources
  void dispose() {
    _connectivitySubscription?.cancel();
  }

  // Déclencher une synchronisation si nécessaire
  Future<bool> syncIfNeeded() async {
    // Éviter les synchronisations simultanées
    if (_isSyncing) return false;
    
    _isSyncing = true;
    bool success = false;
    
    try {
      // Vérifier la connectivité
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        _isSyncing = false;
        return false;
      }
      
      // Synchroniser les données
      success = await _passwordService.syncWithServer();
      
      return success;
    } catch (e) {
      print('Erreur de synchronisation: $e');
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  // Vérifier s'il y a des données à synchroniser
  Future<bool> hasUnsyncedData() async {
    try {
      final secureStorage = SecureStorageService();
      final syncQueueString = await secureStorage._secureStorage.read(key: 'sync_queue');
      
      if (syncQueueString == null || syncQueueString == '[]') {
        return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Définir un intervalle de synchronisation périodique
  void setupPeriodicSync({Duration interval = const Duration(minutes: 15)}) {
    Timer.periodic(interval, (timer) {
      syncIfNeeded();
    });
  }

  // Forcer une synchronisation immédiate
  Future<bool> forceSync() async {
    return await syncIfNeeded();
  }
}