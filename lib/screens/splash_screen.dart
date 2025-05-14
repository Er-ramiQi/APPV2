// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../config/themes.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';
import '../services/security_service.dart';
import '../services/threat_detection_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  final AuthService _authService = AuthService();
  final SecurityService _securityService = SecurityService();
  final ThreatDetectionService _threatDetection = ThreatDetectionService();
  
  // État pour indiquer si l'authentification est en cours
  bool _isAuthenticating = false;
  
  // Messages d'état
  String _statusMessage = 'Initialisation...';
  String? _securityWarning;

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
    
    // Initialiser les services de sécurité
    _initializeServices();
  }
  
  // Initialiser les services et effectuer les vérifications de sécurité
  Future<void> _initializeServices() async {
    try {
      setState(() {
        _statusMessage = 'Vérification de la sécurité...';
      });
      
      // Initialiser le service de sécurité
      await _securityService.initialize();
      
      // Initialiser le service de détection des menaces
      await _threatDetection.initialize();
      
      // Vérifier les menaces
      final threatLevel = await _threatDetection.checkForThreats();
      
      // Si des menaces graves sont détectées, afficher un avertissement
      if (_threatDetection.isHighRisk) {
        setState(() {
          _securityWarning = 'Avertissement : Problèmes de sécurité détectés sur cet appareil';
        });
        
        // Attendre quelques secondes pour que l'utilisateur voie l'avertissement
        await Future.delayed(const Duration(seconds: 3));
      }
      
      // Vérifier l'authentification après un court délai
      _checkAuth();
    } catch (e) {
      print('Erreur lors de l\'initialisation: $e');
      setState(() {
        _statusMessage = 'Erreur d\'initialisation. Veuillez redémarrer l\'application.';
      });
    }
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
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppThemes.primaryColor,
              AppThemes.secondaryColor,
            ],
          ),
        ),
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
                'Protection maximale pour vos mots de passe',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 50),
            // Avertissement de sécurité si nécessaire
            if (_securityWarning != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _securityWarning!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Message d'état
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _statusMessage,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            // Indicateur de chargement
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.8)),
            ),
            const SizedBox(height: 80),
            // Information sur la version
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Version 1.0.0',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}