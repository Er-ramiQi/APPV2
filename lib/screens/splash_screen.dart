// screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../config/themes.dart';
import 'home_screen.dart';
// À créer
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  final AuthService _authService = AuthService();
  
  // État pour indiquer si l'authentification est en cours
  bool _isAuthenticating = false;
  
  // Messages d'état
  String _statusMessage = 'Chargement...';

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _animationController.forward();
    
    // Vérifier l'authentification après un court délai
    Timer(const Duration(seconds: 2), () {
      _checkAuth();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Vérifier l'état de l'authentification
  Future<void> _checkAuth() async {
    setState(() {
      _isAuthenticating = true;
      _statusMessage = 'Vérification de l\'authentification...';
    });
    
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      
      if (isLoggedIn) {
        // Utilisateur déjà connecté
        final isBiometricEnabled = await _authService.isBiometricAvailable();
        
        if (isBiometricEnabled) {
          // Authentification biométrique activée
          setState(() {
            _statusMessage = 'Authentification biométrique requise...';
          });
          
          final authenticated = await _authService.authenticateWithBiometrics();
          
          if (authenticated) {
            _navigateToHome();
          } else {
            // L'authentification biométrique a échoué
            _navigateToLogin();
          }
        } else {
          // Pas d'authentification biométrique
          _navigateToHome();
        }
      } else {
        // Utilisateur non connecté
        _navigateToLogin();
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Erreur d\'authentification';
      });
      
      // En cas d'erreur, rediriger vers l'écran de connexion après un délai
      Timer(const Duration(seconds: 2), () {
        _navigateToLogin();
      });
    }
  }

  // Naviguer vers l'écran d'accueil
  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  // Naviguer vers l'écran de connexion
  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemes.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo avec animation
            ScaleTransition(
              scale: _animation,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(15),
                child: Image.asset(
                  'assets/images/logo.png',
                  errorBuilder: (context, error, stackTrace) {
                    // Afficher une icône par défaut si l'image ne peut pas être chargée
                    return const Icon(
                      Icons.shield_outlined,
                      color: AppThemes.primaryColor,
                      size: 80,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 40),
            // Nom de l'application
            FadeTransition(
              opacity: _animation,
              child: const Text(
                'SecurPass',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 15),
            // Slogan
            FadeTransition(
              opacity: _animation,
              child: const Text(
                'Vos mots de passe. En sécurité.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 50),
            // Message d'état
            Text(
              _statusMessage,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            // Indicateur de chargement
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }
}

// Classe fictive pour éviter les erreurs de compilation
// À remplacer par votre propre implémentation
class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexion'),
      ),
      body: const Center(
        child: Text('Écran de connexion à implémenter'),
      ),
    );
  }
}