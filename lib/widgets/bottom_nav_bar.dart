import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({
    Key? key,
    required this.currentIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Accueil',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.category),
          label: 'Catégories',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profil',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Paramètres',
        ),
      ],
      onTap: (index) {
        if (index == currentIndex) return;

        switch (index) {
          case 0:
            // Utiliser MaterialPageRoute au lieu de pushReplacementNamed
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
            break;
          case 2:
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
            break;
          case 3:
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
            break;
        }
      },
    );
  }
}
