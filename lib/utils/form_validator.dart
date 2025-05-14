// lib/utils/form_validator.dart
class FormValidator {
  // Validation d'un champ obligatoire
  static String? validateRequired(String? value, {String message = 'Ce champ est obligatoire'}) {
    if (value == null || value.isEmpty) {
      return message;
    }
    return null;
  }

  // Validation d'email
  static String? validateEmail(String? value, {String message = 'Veuillez entrer un email valide'}) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer un email';
    }
    
    // Expression régulière pour valider un email
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    
    if (!emailRegex.hasMatch(value)) {
      return message;
    }
    
    return null;
  }

  // Validation de la longueur minimale
  static String? validateMinLength(String? value, int minLength, {String? message}) {
    if (value == null || value.isEmpty) {
      return 'Ce champ est obligatoire';
    }
    
    if (value.length < minLength) {
      return message ?? 'Doit contenir au moins $minLength caractères';
    }
    
    return null;
  }

  // Validation du mot de passe (minimum 8 caractères, majuscule, minuscule, chiffre)
  static String? validatePassword(String? value, {String? message}) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer un mot de passe';
    }
    
    if (value.length < 8) {
      return 'Le mot de passe doit contenir au moins 8 caractères';
    }
    
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Le mot de passe doit contenir au moins une majuscule';
    }
    
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Le mot de passe doit contenir au moins une minuscule';
    }
    
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Le mot de passe doit contenir au moins un chiffre';
    }
    
    return null;
  }

  // Validation de confirmation de mot de passe
  static String? validatePasswordConfirmation(String? value, String password, {String? message}) {
    if (value == null || value.isEmpty) {
      return 'Veuillez confirmer le mot de passe';
    }
    
    if (value != password) {
      return message ?? 'Les mots de passe ne correspondent pas';
    }
    
    return null;
  }

  // Validation de force du mot de passe (retourne un score de 0 à 100)
  static int getPasswordStrength(String password) {
    int score = 0;
    
    // Longueur (jusqu'à 40 points)
    if (password.length >= 8) {
      score += password.length * 2.5 > 40 ? 40 : password.length * 2.5;
    } else {
      score += password.length * 2;
    }
    
    // Types de caractères (jusqu'à 60 points)
    int charTypeCount = 0;
    
    if (RegExp(r'[a-z]').hasMatch(password)) {
      charTypeCount++;
      score += 10;
    }
    
    if (RegExp(r'[A-Z]').hasMatch(password)) {
      charTypeCount++;
      score += 10;
    }
    
    if (RegExp(r'[0-9]').hasMatch(password)) {
      charTypeCount++;
      score += 10;
    }
    
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      charTypeCount++;
      score += 20;
    }
    
    // Bonus pour diversité
    if (charTypeCount >= 3 && password.length >= 8) {
      score += 10;
    }
    
    // Limiter entre 0 et 100
    return score > 100 ? 100 : score;
  }
}