// main.dart
import 'package:flutter/material.dart';
import 'config/themes.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/password_add_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/password_generator_screen.dart';
import 'services/auth_service.dart';
import 'services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Vérifier la sécurité de l'appareil
  final authService = AuthService();
  final isDeviceSecure = await authService.isDeviceSecure();
  
  // Vérifier si un débogueur est attaché (en mode production seulement)
  final isDebuggerAttached = authService.isDebuggerAttached();
  
  // Si on est en production et que le débogueur est attaché, on considère que c'est une tentative de hack
  if (!isDebuggerAttached && !isDeviceSecure) {
    // Option 1: Limiter les fonctionnalités
    // Option 2: Afficher un avertissement
    print('Appareil non sécurisé détecté (rooté ou jailbreaké)');
  }
  
  // Initialiser le service de synchronisation
  final syncService = SyncService();
  syncService.initialize();
  
  // Configurer une synchronisation périodique (toutes les 15 minutes)
  syncService.setupPeriodicSync();
  
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
    );
  }
}