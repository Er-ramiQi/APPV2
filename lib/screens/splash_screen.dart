// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../config/themes.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  final AuthService _authService = AuthService();
  final BiometricService _biometricService = BiometricService();
  
  // État pour indiquer si l'authentification est en cours
  bool _isAuthenticating = false;
  
  // Messages d'état
  String _statusMessage = 'Initialisation...';

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
    
    // Vérifier l'authentification après un court délai pour l'animation
    Future.delayed(const Duration(seconds: 1), () {
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
          
          final authenticated = await _biometricService.authenticate();
          
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
                child: const Icon(
                  Icons.shield_outlined,
                  color: AppThemes.primaryColor,
                  size: 80,
                ),
              ),
            ),
            const SizedBox(height: 40),
            // Nom de l'application
            FadeTransition(
              opacity: _animation,
              child: const Text(
                'MonPass',
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
            if (_isAuthenticating)
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