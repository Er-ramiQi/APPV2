// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:local_auth/local_auth.dart';
import '../services/auth_service.dart';
import '../services/security_service.dart';
import '../config/themes.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _securityService = SecurityService();
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  bool _isLoading = false;
  bool _showOtpScreen = false;
  String? _errorMessage;
  bool _passwordVisible = false;
  
  // Pour suivre l'utilisateur courant en attente de validation OTP
  String _pendingEmail = '';
  
  // Pour afficher un message d'erreur sur l'écran OTP
  String? _otpErrorMessage;
  
  // Pour suivre le nombre de tentatives OTP
  int _otpAttempts = 0;
  
  // Pour identifier les appareils à risque
  bool _isSecurityRisk = false;

  @override
  void initState() {
    super.initState();
    _checkDeviceSecurity();
    _checkBiometric();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  // Vérifier la sécurité de l'appareil
  Future<void> _checkDeviceSecurity() async {
    final isDeviceSecure = await _authService.isDeviceSecure();
    final isDebuggerAttached = _authService.isDebuggerAttached();
    
    if (!isDeviceSecure || isDebuggerAttached) {
      setState(() {
        _isSecurityRisk = true;
      });
    }
  }
  
  // Vérifier si l'authentification biométrique est disponible
  Future<void> _checkBiometric() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      
      if (canCheckBiometrics && isDeviceSupported) {
        // Tenter l'authentification biométrique automatiquement
        final isBiometricEnabled = await _authService.isBiometricAvailable();
        
        if (isBiometricEnabled) {
          final authenticated = await _localAuth.authenticate(
            localizedReason: 'Authentifiez-vous pour accéder à l\'application',
            options: const AuthenticationOptions(
              stickyAuth: true,
              biometricOnly: true,
            ),
          );
          
          if (authenticated) {
            // Rediriger vers l'écran d'accueil
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            }
          }
        }
      }
    } catch (e) {
      // Ignorer les erreurs biométriques
    }
  }

  // Soumettre le formulaire de connexion
  Future<void> _submitLoginForm() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final email = _emailController.text.trim();
        final password = _passwordController.text;

        // Appel au service d'authentification pour la première étape
        final result = await _authService.initiateLogin(email, password);
        
        // Si succès, afficher l'écran de saisie OTP
        if (result) {
          setState(() {
            _isLoading = false;
            _showOtpScreen = true;
            _pendingEmail = email;
            _otpAttempts = 0;
          });
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Identifiants invalides. Veuillez réessayer.';
          });
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Une erreur est survenue: ${e.toString()}';
        });
      }
    }
  }

  // Vérifier le code OTP
  Future<void> _verifyOtp(String otp) async {
    setState(() {
      _isLoading = true;
      _otpErrorMessage = null;
    });

    try {
      // Compter les tentatives
      _otpAttempts++;
      
      // Appel au service pour vérifier l'OTP
      final result = await _authService.verifyOtp(_pendingEmail, otp);
      
      if (result) {
        // Si l'OTP est valide, naviguer vers l'écran d'accueil
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        setState(() {
          _isLoading = false;
          _otpErrorMessage = 'Code OTP invalide. Veuillez réessayer.';
          
          // Après 3 tentatives, revenir à la page de connexion
          if (_otpAttempts >= 3) {
            _showOtpScreen = false;
            _errorMessage = 'Trop de tentatives échouées. Veuillez recommencer.';
          }
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _otpErrorMessage = 'Une erreur est survenue: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _showOtpScreen ? _buildOtpScreen() : _buildLoginScreen(),
      ),
    );
  }

  // Écran de connexion (email/mot de passe)
  Widget _buildLoginScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          // Logo et titre
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppThemes.primaryColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    color: AppThemes.primaryColor,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'SecurPass',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppThemes.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Connexion sécurisée à deux facteurs',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          
          // Avertissement si l'appareil présente un risque de sécurité
          if (_isSecurityRisk)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Attention - Appareil non sécurisé',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Votre appareil présente des risques de sécurité. '
                          'Certaines fonctionnalités peuvent être limitées.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 40),
          
          // Formulaire
          FormBuilder(
            key: _formKey,
            autovalidateMode: AutovalidateMode.disabled,
            child: Column(
              children: [
                // Champ email
                FormBuilderTextField(
                  name: 'email',
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'Entrez votre adresse email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppThemes.primaryColor),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(errorText: 'Veuillez entrer votre email'),
                    FormBuilderValidators.email(errorText: 'Veuillez entrer un email valide'),
                  ]),
                ),
                const SizedBox(height: 20),
                
                // Champ mot de passe
                FormBuilderTextField(
                  name: 'password',
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    hintText: 'Entrez votre mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passwordVisible ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _passwordVisible = !_passwordVisible;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppThemes.primaryColor),
                    ),
                  ),
                  obscureText: !_passwordVisible,
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(errorText: 'Veuillez entrer votre mot de passe'),
                    FormBuilderValidators.minLength(6, errorText: 'Le mot de passe doit contenir au moins 6 caractères'),
                  ]),
                ),
                const SizedBox(height: 12),
                
                // Lien mot de passe oublié
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // Navigation vers la récupération de mot de passe
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppThemes.secondaryColor,
                    ),
                    child: const Text('Mot de passe oublié ?'),
                  ),
                ),
              ],
            ),
          ),
          
          // Message d'erreur
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              margin: const EdgeInsets.only(top: 8, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          
          // Bouton de connexion
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _submitLoginForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThemes.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Se connecter',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
          
          // Lien d'inscription
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Vous n\'avez pas de compte ?'),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterScreen()),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppThemes.secondaryColor,
                ),
                child: const Text('S\'inscrire'),
              ),
            ],
          ),
          
          // Explication de la sécurité à deux facteurs
          const SizedBox(height: 48),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Column(
              children: [
                Row(
                  children: const [
                    Icon(Icons.security, color: AppThemes.secondaryColor),
                    SizedBox(width: 8),
                    Text(
                      'Authentification à deux facteurs',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppThemes.secondaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pour protéger vos données sensibles, nous utilisons une authentification à deux facteurs. Après avoir saisi vos identifiants, vous recevrez un code unique par email pour confirmer votre identité.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Écran de vérification OTP
  Widget _buildOtpScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bouton de retour
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              setState(() {
                _showOtpScreen = false;
                _otpErrorMessage = null;
              });
            },
          ),
          const SizedBox(height: 40),
          
          // Icône et titre
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppThemes.primaryColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.security,
                    color: AppThemes.primaryColor,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Vérification',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppThemes.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Un code de vérification a été envoyé à $_pendingEmail',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          
          // Champ de saisie OTP
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PinCodeTextField(
              appContext: context,
              length: 6, // Code OTP à 6 chiffres
              onChanged: (value) {},
              onCompleted: (otp) {
                // Vérifier l'OTP dès qu'il est complètement saisi
                if (!_isLoading) {
                  _verifyOtp(otp);
                }
              },
              autoFocus: true,
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(8),
                fieldHeight: 50,
                fieldWidth: 40,
                activeFillColor: Colors.white,
                inactiveFillColor: Colors.grey.shade100,
                selectedFillColor: Colors.white,
                activeColor: AppThemes.primaryColor,
                inactiveColor: Colors.grey.shade300,
                selectedColor: AppThemes.secondaryColor,
              ),
              keyboardType: TextInputType.number,
              enableActiveFill: true,
              animationType: AnimationType.scale,
            ),
          ),
          
          // Message d'erreur OTP
          if (_otpErrorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _otpErrorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          
          // Options
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            )
          else
            Column(
              children: [
                // Renvoyer le code
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Vous n\'avez pas reçu le code?',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Vérifiez votre dossier de spam ou demandez un nouveau code.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Renvoyer le code
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Envoyer un nouveau code'),
                  onPressed: () async {
                    try {
                      setState(() {
                        _isLoading = true;
                      });
                      
                      await _authService.resendOtp(_pendingEmail);
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Un nouveau code a été envoyé'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      setState(() {
                        _otpErrorMessage = 'Erreur lors de l\'envoi: ${e.toString()}';
                      });
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppThemes.secondaryColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: AppThemes.secondaryColor),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                ),
              ],
            ),
          
          // Note de sécurité
          const SizedBox(height: 40),
          const Center(
            child: Column(
              children: [
                Icon(Icons.lock, color: Colors.grey),
                SizedBox(height: 8),
                Text(
                  'Ce code expire après 10 minutes',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}