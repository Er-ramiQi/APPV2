// screens/password_add_screen.dart
import 'package:flutter/material.dart';
import '../config/themes.dart';
import '../widgets/bottom_nav_bar.dart';
import 'password_generator_screen.dart';
import 'dart:math';
class PasswordAddScreen extends StatefulWidget {
  const PasswordAddScreen({super.key});

  @override
  State<PasswordAddScreen> createState() => _PasswordAddScreenState();
}

class _PasswordAddScreenState extends State<PasswordAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _websiteController = TextEditingController();
  final _notesController = TextEditingController();

  bool _passwordVisible = false;

  @override
  void dispose() {
    _titleController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _websiteController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Fonction pour ouvrir le générateur de mots de passe avancé
  void _openPasswordGenerator() async {
    final generatedPassword = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PasswordGeneratorScreen(),
      ),
    );
    
    if (generatedPassword != null && generatedPassword is String) {
      setState(() {
        _passwordController.text = generatedPassword;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un mot de passe'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec illustration
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppThemes.primaryColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_circle,
                    color: AppThemes.primaryColor,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  'Ajouter un nouveau mot de passe',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Formulaire
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre',
                  hintText: 'Ex: Gmail, Facebook, etc.',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un titre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Nom d\'utilisateur ou Email',
                  hintText: 'Ex: utilisateur@exemple.com',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nom d\'utilisateur ou email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                obscureText: !_passwordVisible,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  hintText: 'Entrez votre mot de passe',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _passwordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppThemes.secondaryColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _passwordVisible = !_passwordVisible;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un mot de passe';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.enhanced_encryption, size: 16),
                    label: const Text('Ouvrir le générateur avancé'),
                    onPressed: _openPasswordGenerator,
                    style: TextButton.styleFrom(
                      foregroundColor: AppThemes.secondaryColor,
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Générer'),
                    onPressed: () {
                      // Générer un mot de passe aléatoire simple
                      setState(() {
                        _passwordController.text = _generateStrongPassword(16);
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppThemes.secondaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _websiteController,
                decoration: const InputDecoration(
                  labelText: 'Site web (optionnel)',
                  hintText: 'Ex: https://exemple.com',
                  prefixIcon: Icon(Icons.language),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optionnel)',
                  hintText: 'Informations supplémentaires',
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _savePassword,
                  child: const Text(
                    'Enregistrer',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }

  void _savePassword() {
    if (_formKey.currentState!.validate()) {
      // Enregistrer le mot de passe (à implémenter plus tard)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mot de passe enregistré avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  String _generateStrongPassword(int length) {
    const String upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const String lower = 'abcdefghijklmnopqrstuvwxyz';
    const String numbers = '0123456789';
    const String special = '!@#\$%^&*()_+{}|:<>?';

    String chars = '';
    chars += upper;
    chars += lower;
    chars += numbers;
    chars += special;

    String password = '';
    final random = Random.secure();
    for (int i = 0; i < length; i++) {
      password += chars[random.nextInt(chars.length)];
    }

    // S'assurer que le mot de passe contient au moins un caractère de chaque catégorie
    if (!password.contains(RegExp(r'[A-Z]'))) {
      int pos = random.nextInt(password.length);
      password = password.substring(0, pos) + 
                upper[random.nextInt(upper.length)] + 
                password.substring(pos + 1);
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      int pos = random.nextInt(password.length);
      password = password.substring(0, pos) + 
                lower[random.nextInt(lower.length)] + 
                password.substring(pos + 1);
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      int pos = random.nextInt(password.length);
      password = password.substring(0, pos) + 
                numbers[random.nextInt(numbers.length)] + 
                password.substring(pos + 1);
    }
    if (!password.contains(RegExp(r'[!@#\$%^&*()_+{}|:<>?]'))) {
      int pos = random.nextInt(password.length);
      password = password.substring(0, pos) + 
                special[random.nextInt(special.length)] + 
                password.substring(pos + 1);
    }

    return password;
  }
}