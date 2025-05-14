// widgets/password_list_item.dart
import 'package:flutter/material.dart';
import '../models/password_item.dart';
import '../config/themes.dart';

class PasswordListItem extends StatelessWidget {
  final PasswordItem passwordItem;
  final VoidCallback onTap;

  const PasswordListItem({
    Key? key,
    required this.passwordItem,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icône ou première lettre du service
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppThemes.primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  passwordItem.title.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: AppThemes.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Détails du mot de passe
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    passwordItem.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    passwordItem.username,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // Icônes d'action
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.copy,
                    color: AppThemes.secondaryColor,
                    size: 20,
                  ),
                  onPressed: () {
                    // Copier le mot de passe dans le presse-papiers
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Mot de passe copié dans le presse-papiers'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}