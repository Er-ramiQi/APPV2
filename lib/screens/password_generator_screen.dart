// screens/password_generator_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../config/themes.dart';
import '../widgets/bottom_nav_bar.dart';

class PasswordGeneratorScreen extends StatefulWidget {
  const PasswordGeneratorScreen({super.key});

  @override
  State<PasswordGeneratorScreen> createState() => _PasswordGeneratorScreenState();
}

class _PasswordGeneratorScreenState extends State<PasswordGeneratorScreen> {
  // Paramètres du générateur
  double _passwordLength = 12;
  bool _includeUppercase = true;
  bool _includeLowercase = true;
  bool _includeNumbers = true;
  bool _includeSpecialChars = true;
  String _generatedPassword = '';
  bool _passwordVisible = true;
  
  // Force du mot de passe
  String _passwordStrength = '';
  Color _strengthColor = Colors.grey;
  double _strengthPercent = 0.0;

  @override
  void initState() {
    super.initState();
    _generatePassword();
  }

  void _generatePassword() {
    if (!_includeUppercase && !_includeLowercase && !_includeNumbers && !_includeSpecialChars) {
      // Si aucun type de caractère n'est sélectionné, activer les minuscules par défaut
      setState(() {
        _includeLowercase = true;
      });
    }

    const String uppercaseChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const String lowercaseChars = 'abcdefghijklmnopqrstuvwxyz';
    const String numberChars = '0123456789';
    const String specialChars = '!@#\$%^&*()_+{}|:<>?-=[]\\;\',./';

    String chars = '';
    if (_includeUppercase) chars += uppercaseChars;
    if (_includeLowercase) chars += lowercaseChars;
    if (_includeNumbers) chars += numberChars;
    if (_includeSpecialChars) chars += specialChars;

    // Générer le mot de passe
    String password = '';
    final random = Random.secure();
    for (int i = 0; i < _passwordLength; i++) {
      password += chars[random.nextInt(chars.length)];
    }

    // S'assurer que le mot de passe contient au moins un caractère de chaque type sélectionné
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasNumber = password.contains(RegExp(r'[0-9]'));
    
    // Utilisation de la méthode alternative sans expression régulière complexe
    bool hasSpecialChar = _includeSpecialChars && 
        password.split('').any((char) => specialChars.contains(char));

    // Remplacer des caractères si nécessaire pour satisfaire les exigences
    if (_includeUppercase && !hasUppercase) {
      int pos = random.nextInt(password.length);
      password = password.substring(0, pos) + 
                uppercaseChars[random.nextInt(uppercaseChars.length)] + 
                password.substring(pos + 1);
    }
    if (_includeLowercase && !hasLowercase) {
      int pos = random.nextInt(password.length);
      password = password.substring(0, pos) + 
                lowercaseChars[random.nextInt(lowercaseChars.length)] + 
                password.substring(pos + 1);
    }
    if (_includeNumbers && !hasNumber) {
      int pos = random.nextInt(password.length);
      password = password.substring(0, pos) + 
                numberChars[random.nextInt(numberChars.length)] + 
                password.substring(pos + 1);
    }
    if (_includeSpecialChars && !hasSpecialChar) {
      int pos = random.nextInt(password.length);
      password = password.substring(0, pos) + 
                specialChars[random.nextInt(specialChars.length)] + 
                password.substring(pos + 1);
    }

    setState(() {
      _generatedPassword = password;
      _evaluatePasswordStrength(password);
    });
  }

  void _evaluatePasswordStrength(String password) {
    // Facteurs de force du mot de passe
    int length = password.length;
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasNumbers = password.contains(RegExp(r'[0-9]'));
    
    // Utilisation de la méthode alternative sans expression régulière complexe
    const String specialChars = '!@#\$%^&*()_+{}|:<>?-=[]\\;\',./';
    bool hasSpecialChars = password.split('').any((char) => specialChars.contains(char));
    
    int typesCount = 0;
    if (hasUppercase) typesCount++;
    if (hasLowercase) typesCount++;
    if (hasNumbers) typesCount++;
    if (hasSpecialChars) typesCount++;

    // Calcul du score (sur 100)
    double score = 0;
    
    // Longueur (40 points max)
    score += min(40, length * 2.5);
    
    // Diversité (60 points max)
    score += typesCount * 15;

    // Bonus pour combinaisons optimales
    if (hasUppercase && hasLowercase && hasNumbers && hasSpecialChars && length >= 12) {
      score = min(100, score + 10);
    }
    
    // Déterminer la force
    String strength;
    Color color;
    
    if (score < 40) {
      strength = 'Faible';
      color = Colors.red;
    } else if (score < 70) {
      strength = 'Moyen';
      color = Colors.orange;
    } else {
      strength = 'Fort';
      color = Colors.green;
    }

    setState(() {
      _passwordStrength = strength;
      _strengthColor = color;
      _strengthPercent = score / 100;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Générateur de Mot de Passe'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
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
                  Icons.enhanced_encryption,
                  color: AppThemes.primaryColor,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text(
                'Créez un mot de passe sécurisé',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Affichage du mot de passe généré
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Mot de passe généré',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              _passwordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: AppThemes.primaryColor,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _passwordVisible = !_passwordVisible;
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.copy,
                              color: AppThemes.primaryColor,
                              size: 20,
                            ),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _generatedPassword));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Mot de passe copié dans le presse-papiers'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.refresh,
                              color: AppThemes.primaryColor,
                              size: 20,
                            ),
                            onPressed: _generatePassword,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 15,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _passwordVisible
                          ? _generatedPassword
                          : '•' * _generatedPassword.length,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: _passwordVisible ? 0 : 2,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Indicateur de force
                  Row(
                    children: [
                      const Text(
                        'Force: ',
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _passwordStrength,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _strengthColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  LinearProgressIndicator(
                    value: _strengthPercent,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(_strengthColor),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Options de génération
            const Text(
              'Personnaliser le mot de passe',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // Longueur du mot de passe
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Longueur:'),
                Text(
                  '${_passwordLength.toInt()} caractères',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Slider(
              value: _passwordLength,
              min: 4,
              max: 32,
              divisions: 28,
              activeColor: AppThemes.primaryColor,
              label: _passwordLength.toInt().toString(),
              onChanged: (value) {
                setState(() {
                  _passwordLength = value;
                });
              },
              onChangeEnd: (value) {
                _generatePassword();
              },
            ),
            const SizedBox(height: 15),
            // Types de caractères
            const Text(
              'Types de caractères:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            CheckboxListTile(
              title: const Text('Majuscules (A-Z)'),
              value: _includeUppercase,
              activeColor: AppThemes.primaryColor,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              onChanged: (value) {
                setState(() {
                  _includeUppercase = value!;
                });
                _generatePassword();
              },
            ),
            CheckboxListTile(
              title: const Text('Minuscules (a-z)'),
              value: _includeLowercase,
              activeColor: AppThemes.primaryColor,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              onChanged: (value) {
                setState(() {
                  _includeLowercase = value!;
                });
                _generatePassword();
              },
            ),
            CheckboxListTile(
              title: const Text('Chiffres (0-9)'),
              value: _includeNumbers,
              activeColor: AppThemes.primaryColor,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              onChanged: (value) {
                setState(() {
                  _includeNumbers = value!;
                });
                _generatePassword();
              },
            ),
            CheckboxListTile(
              title: const Text('Caractères spéciaux (!@#\$%^&*)'),
              value: _includeSpecialChars,
              activeColor: AppThemes.primaryColor,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              onChanged: (value) {
                setState(() {
                  _includeSpecialChars = value!;
                });
                _generatePassword();
              },
            ),
            const SizedBox(height: 20),
            // Conseils de sécurité
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppThemes.primaryColor.withOpacity(0.5),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Conseils pour un mot de passe sécurisé:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppThemes.primaryColor,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '• Utilisez au moins 12 caractères\n'
                    '• Combinez majuscules, minuscules, chiffres et symboles\n'
                    '• Évitez les informations personnelles\n'
                    '• Utilisez un mot de passe unique pour chaque compte\n'
                    '• Changez vos mots de passe régulièrement',
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _generatePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppThemes.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text(
                      'Générer un nouveau mot de passe',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Navigation vers l'écran d'ajout avec le mot de passe pré-rempli
                      Navigator.pop(context, _generatedPassword);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppThemes.primaryColor,
                      side: const BorderSide(color: AppThemes.primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text(
                      'Utiliser ce mot de passe',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }
}