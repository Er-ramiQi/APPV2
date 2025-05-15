// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'config/themes.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/password_add_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/password_generator_screen.dart';
import 'services/auth_service.dart';
import 'services/sync_service.dart';
import 'services/secure_storage_service.dart';
import 'services/biometric_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Bloquer l'orientation en portrait uniquement pour Android
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialiser les services
  final secureStorage = SecureStorageService();
  final authService = AuthService();
  final biometricService = BiometricService();
  final syncService = SyncService();
  
  // Initialiser le service de synchronisation
  await syncService.initialize();
  
  runApp(const PasswordManagerApp());
}

class PasswordManagerApp extends StatelessWidget {
  const PasswordManagerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestionnaire de Mots de Passe',
      theme: AppThemes.lightTheme,
      home: const SplashScreen(), // Écran de démarrage
      routes: {
        '/home': (context) => const HomeScreen(),
        '/password-add': (context) => const PasswordAddScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/password-generator': (context) => const PasswordGeneratorScreen(),
      },
      debugShowCheckedModeBanner: false,
      // Configurer des gestionnaires d'erreur pour capturer les erreurs
      builder: (context, child) {
        return MediaQuery(
          // Fixer la taille du texte pour éviter les problèmes de sécurité
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child!,
        );
      },
    );
  }
}