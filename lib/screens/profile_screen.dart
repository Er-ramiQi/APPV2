// screens/profile_screen.dart
import 'package:flutter/material.dart';
import '../config/themes.dart';
import '../widgets/bottom_nav_bar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Données utilisateur d'exemple (à remplacer par les données réelles)
    const String userName = 'Jean Dupont';
    const String userEmail = 'jean.dupont@example.com';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // En-tête du profil avec photo et informations
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppThemes.primaryColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: AppThemes.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    userName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    userEmail,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 15),
                  OutlinedButton(
                    onPressed: () {
                      // Action pour modifier le profil
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('Modifier le profil'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Statistiques
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Statistiques',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            context,
                            '15',
                            'Mots de passe',
                            Icons.vpn_key,
                          ),
                          _buildStatItem(
                            context,
                            '3',
                            'Catégories',
                            Icons.category,
                          ),
                          _buildStatItem(
                            context,
                            '87%',
                            'Sécurité',
                            Icons.shield,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Options du profil
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Options du compte',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      _buildOptionItem(
                        context,
                        'Sécurité du compte',
                        Icons.security,
                        () {
                          // Action
                        },
                      ),
                      _buildOptionItem(
                        context,
                        'Sauvegarder les données',
                        Icons.backup,
                        () {
                          // Action
                        },
                      ),
                      _buildOptionItem(
                        context,
                        'Restaurer les données',
                        Icons.restore,
                        () {
                          // Action
                        },
                      ),
                      _buildOptionItem(
                        context,
                        'Supprimer le compte',
                        Icons.delete_forever,
                        () {
                          // Action
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Êtes-vous sûr ?'),
                              content: const Text(
                                'Cette action supprimera définitivement votre compte et toutes vos données. Cette action est irréversible.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Annuler'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    // Supprimer le compte
                                    Navigator.pop(context);
                                  },
                                  child: const Text(
                                    'Supprimer',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        color: Colors.red,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Aide et support
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Aide et support',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      _buildOptionItem(
                        context,
                        'FAQ',
                        Icons.help,
                        () {
                          // Action
                        },
                      ),
                      _buildOptionItem(
                        context,
                        'Contactez-nous',
                        Icons.contact_support,
                        () {
                          // Action
                        },
                      ),
                      _buildOptionItem(
                        context,
                        'À propos de l\'application',
                        Icons.info,
                        () {
                          // Action
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppThemes.primaryColor,
          size: 30,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildOptionItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap, {
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: color ?? AppThemes.primaryColor,
              size: 24,
            ),
            const SizedBox(width: 15),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: color,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}