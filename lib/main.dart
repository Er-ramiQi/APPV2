// main.dart
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
import 'services/security_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Bloquer l'orientation en portrait uniquement pour Android
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialiser les services
  final securityService = SecurityService();
  await securityService.initialize();
  
  final authService = AuthService();
  
  // Vérifier la sécurité de l'appareil
  final isDeviceSecure = await authService.isDeviceSecure();
  
  // Vérifier si un débogueur est attaché
  final isDebuggerAttached = securityService.isDebuggerAttached();
  
  // Si on est en production et que l'appareil n'est pas sécurisé
  if (!isDebuggerAttached && !isDeviceSecure) {
    // Dans une app réelle, vous pourriez vouloir :
    // 1. Limiter l'accès aux données sensibles
    // 2. Forcer une authentification supplémentaire
    // 3. Présenter un avertissement à l'utilisateur
    print('Appareil non sécurisé détecté (rooté)');
  }
  
  // Initialiser le service de synchronisation
  final syncService = SyncService();
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