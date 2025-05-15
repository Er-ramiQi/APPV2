// screens/settings_screen.dart
import 'package:flutter/material.dart';
import '../config/themes.dart';
import '../widgets/bottom_nav_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _biometricAuth = true;
  bool _autoLock = true;
  int _autoLockTime = 3; // en minutes
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            const Center(
              child: Icon(
                Icons.settings,
                size: 70,
                color: AppThemes.primaryColor,
              ),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text(
                'Paramètres de l\'application',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Sécurité
            _buildSectionTitle('Sécurité'),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Authentification biométrique'),
                      subtitle: const Text(
                        'Utilisez votre empreinte digitale ou reconnaissance faciale pour déverrouiller l\'application',
                      ),
                      value: _biometricAuth,
                      activeColor: AppThemes.primaryColor,
                      onChanged: (value) {
                        setState(() {
                          _biometricAuth = value;
                        });
                      },
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('Verrouillage automatique'),
                      subtitle: const Text(
                        'Verrouiller automatiquement l\'application après une période d\'inactivité',
                      ),
                      value: _autoLock,
                      activeColor: AppThemes.primaryColor,
                      onChanged: (value) {
                        setState(() {
                          _autoLock = value;
                        });
                      },
                    ),
                    if (_autoLock)
                      Padding(
                        padding: const EdgeInsets.only(left: 15, right: 15, top: 10),
                        child: Row(
                          children: [
                            const Text('Délai de verrouillage:'),
                            const Spacer(),
                            DropdownButton<int>(
                              value: _autoLockTime,
                              items: [1, 3, 5, 10, 15, 30].map((int value) {
                                return DropdownMenuItem<int>(
                                  value: value,
                                  child: Text('$value min'),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                setState(() {
                                  _autoLockTime = newValue!;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    const Divider(),
                    ListTile(
                      title: const Text('Changer le code PIN'),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                      onTap: () {
                        // Navigation vers l'écran de changement de PIN
                      },
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('Modifier la phrase de récupération'),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                      onTap: () {
                        // Navigation vers l'écran de modification de la phrase de récupération
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),

            // Notifications
            _buildSectionTitle('Notifications'),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Activer les notifications'),
                      subtitle: const Text(
                        'Recevoir des notifications concernant la sécurité de vos mots de passe',
                      ),
                      value: _notificationsEnabled,
                      activeColor: AppThemes.primaryColor,
                      onChanged: (value) {
                        setState(() {
                          _notificationsEnabled = value;
                        });
                      },
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('Fréquence des rappels'),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                      enabled: _notificationsEnabled,
                      onTap: () {
                        // Navigation vers l'écran de paramètres de rappels
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),

            // Apparence
            _buildSectionTitle('Apparence'),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
              child: const Padding(
                padding: EdgeInsets.all(15),
                child: Column(
                  children: [
                    ListTile(
                      title: Text('Thème'),
                      subtitle: Text('Clair'),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                    Divider(),
                    ListTile(
                      title: Text('Taille du texte'),
                      subtitle: Text('Normal'),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),

            // Données et stockage
            _buildSectionTitle('Données et stockage'),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
              child: const Padding(
                padding: EdgeInsets.all(15),
                child: Column(
                  children: [
                    ListTile(
                      title: Text('Sauvegarde automatique'),
                      subtitle: Text('Activer la sauvegarde automatique de vos données'),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                    Divider(),
                    ListTile(
                      title: Text('Exporter les données'),
                      subtitle: Text('Exporter vos mots de passe dans un fichier chiffré'),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                    Divider(),
                    ListTile(
                      title: Text('Importer les données'),
                      subtitle: Text('Importer des mots de passe depuis un fichier'),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                    Divider(),
                    ListTile(
                      title: Text('Effacer toutes les données'),
                      subtitle: Text('Supprimer définitivement toutes vos données'),
                      trailing: Icon(
                        Icons.delete_forever,
                        size: 20,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),

            // À propos
            _buildSectionTitle('À propos'),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
              child: const Padding(
                padding: EdgeInsets.all(15),
                child: Column(
                  children: [
                    ListTile(
                      title: Text('Version de l\'application'),
                      subtitle: Text('1.0.0'),
                    ),
                    Divider(),
                    ListTile(
                      title: Text('Conditions d\'utilisation'),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                    Divider(),
                    ListTile(
                      title: Text('Politique de confidentialité'),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                    Divider(),
                    ListTile(
                      title: Text('Licences open source'),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppThemes.primaryColor,
        ),
      ),
    );
  }
}