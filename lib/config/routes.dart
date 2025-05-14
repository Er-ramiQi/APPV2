// config/routes.dart
import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/password_detail_screen.dart';
import '../screens/password_add_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/password_generator_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String passwordDetail = '/password-detail';
  static const String passwordAdd = '/password-add';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String passwordGenerator = '/password-generator';
  static final Map<String, WidgetBuilder> routes = {
    home: (context) => const HomeScreen(),
    passwordDetail: (context) => const PasswordDetailScreen(),
    passwordAdd: (context) => const PasswordAddScreen(),
    profile: (context) => const ProfileScreen(),
    settings: (context) => const SettingsScreen(),
    passwordGenerator: (context) => const PasswordGeneratorScreen(),
  };
}