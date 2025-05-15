// screens/home_screen.dart
import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/password_list_item.dart';
import '../models/password_item.dart';
import '../config/themes.dart';
import 'password_generator_screen.dart';
import 'password_detail_screen.dart';
import 'password_add_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Données d'exemple (à remplacer par les données réelles plus tard)
  final List<PasswordItem> _passwordItems = [
    PasswordItem(
      id: '1',
      title: 'Gmail',
      username: 'utilisateur@gmail.com',
      password: 'Mot2Passe!Sécurisé',
      website: 'https://gmail.com',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      lastModified: DateTime.now().subtract(const Duration(days: 5)),
    ),
    PasswordItem(
      id: '2',
      title: 'Facebook',
      username: 'utilisateur@facebook.com',
      password: 'AutreMDP@Secure123',
      website: 'https://facebook.com',
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      lastModified: DateTime.now().subtract(const Duration(days: 2)),
    ),
    // Ajouter plus d'éléments si nécessaire
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 30,
              height: 30,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.shield,
                  color: Colors.white,
                  size: 30,
                );
              },
            ),
            const SizedBox(width: 10),
            const Text('Mes Mots de Passe'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Action de recherche
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Bannière supérieure avec illustration (remplacer l'image par une icône)
          Container(
            width: double.infinity,
            height: 150,
            decoration: const BoxDecoration(
              color: AppThemes.primaryColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                // Section texte
                const Expanded(
                  flex: 3,
                  child: Padding(
                    padding: EdgeInsets.only(left: 20, top: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bienvenue dans votre',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Gestionnaire de Mots de Passe',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Gardez vos mots de passe en sécurité',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Icône à la place de l'image
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Icon(
                      Icons.security,
                      size: 80,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Statistiques
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(
                  context,
                  Icons.lock,
                  _passwordItems.length.toString(),
                  'Mots de passe',
                ),
                _buildStatCard(
                  context,
                  Icons.warning_amber_rounded,
                  '1',
                  'Vulnérables',
                ),
                _buildStatCard(
                  context,
                  Icons.access_time,
                  '3',
                  'À renouveler',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Bouton du générateur de mots de passe
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PasswordGeneratorScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppThemes.primaryColor, AppThemes.secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.enhanced_encryption,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 15),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Générateur de mot de passe',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Créez des mots de passe sécurisés et personnalisés',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Liste des mots de passe
          Expanded(
            child: _passwordItems.isEmpty
                ? const Center(
                    child: Text(
                      'Aucun mot de passe enregistré',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _passwordItems.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      return PasswordListItem(
                        passwordItem: _passwordItems[index],
                        onTap: () {
                          // Navigation avec passage du paramètre passwordItem
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PasswordDetailScreen(
                                passwordItem: _passwordItems[index],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppThemes.secondaryColor,
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PasswordAddScreen(),
            ),
          );
        },
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: AppThemes.primaryColor,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppThemes.textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}