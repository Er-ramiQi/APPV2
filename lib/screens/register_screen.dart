// screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../services/auth_service.dart';
import '../config/themes.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Soumettre le formulaire d'inscription
  Future<void> _submitRegisterForm() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      // Vérifier si les mots de passe correspondent
      if (_passwordController.text != _confirmPasswordController.text) {
        setState(() {
          _errorMessage = 'Les mots de passe ne correspondent pas';
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final name = _nameController.text.trim();
        final email = _emailController.text.trim();
        final password = _passwordController.text;

        // Appel au service d'authentification pour l'inscription
        final result = await _authService.register(name, email, password);
        
        if (result) {
          // Si l'inscription est réussie, rediriger vers la connexion
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Inscription réussie. Veuillez vous connecter.'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Rediriger vers la page de connexion
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          }
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Échec de l\'inscription. Veuillez réessayer.';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Titre et sous-titre
              const Text(
                'Créer un compte',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppThemes.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Inscrivez-vous pour gérer vos mots de passe en toute sécurité',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 40),
              
              // Formulaire d'inscription
              FormBuilder(
                key: _formKey,
                autovalidateMode: AutovalidateMode.disabled,
                child: Column(
                  children: [
                    // Champ nom
                    FormBuilderTextField(
                      name: 'name',
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom complet',
                        hintText: 'Entrez votre nom',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(errorText: 'Veuillez entrer votre nom'),
                        FormBuilderValidators.minLength(2, errorText: 'Le nom doit contenir au moins 2 caractères'),
                      ]),
                    ),
                    const SizedBox(height: 20),
                    
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
                        hintText: 'Créez un mot de passe sécurisé',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(errorText: 'Veuillez entrer un mot de passe'),
                        FormBuilderValidators.minLength(6, errorText: 'Le mot de passe doit contenir au moins 6 caractères'),
                      ]),
                    ),
                    const SizedBox(height: 20),
                    
                    // Champ confirmation de mot de passe
                    FormBuilderTextField(
                      name: 'confirmPassword',
                      controller: _confirmPasswordController,
                      decoration: const InputDecoration(
                        labelText: 'Confirmer le mot de passe',
                        hintText: 'Confirmez votre mot de passe',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(errorText: 'Veuillez confirmer votre mot de passe'),
                      ]),
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
              
              // Bouton d'inscription
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitRegisterForm,
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
                        'S\'inscrire',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
              
              // Lien de connexion
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Vous avez déjà un compte ?'),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                    child: const Text('Se connecter'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}