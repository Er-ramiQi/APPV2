// screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../services/auth_service.dart';
import '../config/themes.dart';
import 'home_screen.dart';

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
  
  bool _isLoading = false;
  bool _showOtpScreen = false;
  String? _errorMessage;
  
  // Pour suivre l'utilisateur courant en attente de validation OTP
  String _pendingEmail = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
      _errorMessage = null;
    });

    try {
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
          _errorMessage = 'Code OTP invalide. Veuillez réessayer.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Une erreur est survenue: ${e.toString()}';
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
          const SizedBox(height: 60),
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
                  'Connectez-vous pour accéder à vos mots de passe',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
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
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Entrez votre adresse email',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
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
                  decoration: const InputDecoration(
                    labelText: 'Mot de passe',
                    hintText: 'Entrez votre mot de passe',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
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
                    child: const Text('Mot de passe oublié ?'),
                  ),
                ),
              ],
            ),
          ),
          
          // Message d'erreur
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
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
                borderRadius: BorderRadius.circular(8),
              ),
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
                  // Navigation vers l'inscription
                },
                child: const Text('S\'inscrire'),
              ),
            ],
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 60),
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
                _verifyOtp(otp);
              },
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(8),
                fieldHeight: 50,
                fieldWidth: 40,
                activeFillColor: Colors.white,
                inactiveFillColor: Colors.white,
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
          
          // Message d'erreur
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
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
                TextButton.icon(
                  onPressed: () async {
                    // Réinitialiser l'envoi d'OTP
                    try {
                      await _authService.resendOtp(_pendingEmail);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Un nouveau code a été envoyé'),
                        ),
                      );
                    } catch (e) {
                      setState(() {
                        _errorMessage = 'Erreur lors de l\'envoi: ${e.toString()}';
                      });
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Renvoyer le code'),
                ),
                
                // Retour à la connexion
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showOtpScreen = false;
                      _errorMessage = null;
                    });
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Retour à la connexion'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}