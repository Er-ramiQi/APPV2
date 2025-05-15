// screens/password_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/password_item.dart';
import '../config/themes.dart';
import '../widgets/bottom_nav_bar.dart';

class PasswordDetailScreen extends StatefulWidget {
  // Ajout du paramètre passwordItem pour résoudre l'erreur
  final PasswordItem passwordItem;
  
  const PasswordDetailScreen({
    super.key, 
    required this.passwordItem,
  });

  @override
  State<PasswordDetailScreen> createState() => _PasswordDetailScreenState();
}

class _PasswordDetailScreenState extends State<PasswordDetailScreen> {
  bool _passwordVisible = false;

  @override
  Widget build(BuildContext context) {
    // Utiliser widget.passwordItem au lieu de récupérer depuis les arguments
    final passwordItem = widget.passwordItem;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du mot de passe'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navigation vers l'écran d'édition
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              // Afficher une boîte de dialogue de confirmation
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Supprimer ce mot de passe ?'),
                  content: const Text(
                    'Cette action est irréversible. Êtes-vous sûr de vouloir supprimer ce mot de passe ?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () {
                        // Supprimer le mot de passe et revenir à l'écran d'accueil
                        Navigator.pop(context); // Fermer la boîte de dialogue
                        Navigator.pop(context); // Retourner à l'écran d'accueil
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
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Entête avec le titre et l'icône
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppThemes.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      passwordItem.title.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: AppThemes.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 30,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passwordItem.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ajouté le ${_formatDate(passwordItem.createdAt)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Informations du mot de passe
            _buildDetailItem(
              context,
              'Nom d\'utilisateur',
              passwordItem.username,
              Icons.person,
            ),
            _buildPasswordDetailItem(
              context,
              'Mot de passe',
              passwordItem.password,
            ),
            if (passwordItem.website.isNotEmpty)
              _buildDetailItem(
                context,
                'Site web',
                passwordItem.website,
                Icons.language,
              ),
            if (passwordItem.notes.isNotEmpty)
              _buildDetailItem(
                context,
                'Notes',
                passwordItem.notes,
                Icons.note,
              ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),

            // Informations supplémentaires
            const Text(
              'Informations supplémentaires',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            _buildInfoItem(
              'Dernière modification',
              _formatDate(passwordItem.lastModified),
              Icons.update,
            ),
            _buildInfoItem(
              'Niveau de sécurité',
              _getPasswordStrength(passwordItem.password),
              Icons.shield,
              _getPasswordStrengthColor(passwordItem.password),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildDetailItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                icon,
                color: AppThemes.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.copy,
                  color: AppThemes.secondaryColor,
                  size: 20,
                ),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$label copié dans le presse-papiers'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildPasswordDetailItem(
    BuildContext context,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.lock,
                color: AppThemes.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _passwordVisible ? value : '••••••••••••',
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  _passwordVisible ? Icons.visibility_off : Icons.visibility,
                  color: AppThemes.secondaryColor,
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
                  color: AppThemes.secondaryColor,
                  size: 20,
                ),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));
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
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    String label,
    String value,
    IconData icon, [
    Color? color,
  ]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Icon(
            icon,
            color: color ?? AppThemes.primaryColor,
            size: 18,
          ),
          const SizedBox(width: 10),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getPasswordStrength(String password) {
    if (password.length < 8) {
      return 'Faible';
    } else if (password.length >= 12 &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[a-z]')) &&
        password.contains(RegExp(r'[0-9]')) &&
        password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Fort';
    } else {
      return 'Moyen';
    }
  }

  Color _getPasswordStrengthColor(String password) {
    final strength = _getPasswordStrength(password);
    if (strength == 'Faible') {
      return Colors.red;
    } else if (strength == 'Moyen') {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
}