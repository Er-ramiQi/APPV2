// lib/screens/security_report_screen.dart
import 'package:flutter/material.dart';
import '../config/themes.dart';
import '../services/security_alert_service.dart';
import '../services/threat_detection_service.dart';
import '../services/password_service.dart';
import '../models/security_alert.dart';
import '../widgets/bottom_nav_bar.dart';

class SecurityReportScreen extends StatefulWidget {
  const SecurityReportScreen({Key? key}) : super(key: key);

  @override
  State<SecurityReportScreen> createState() => _SecurityReportScreenState();
}

class _SecurityReportScreenState extends State<SecurityReportScreen> {
  final SecurityAlertService _alertService = SecurityAlertService();
  final ThreatDetectionService _threatService = ThreatDetectionService();
  final PasswordService _passwordService = PasswordService();
  
  bool _isLoading = true;
  int _securityScore = 0;
  List<SecurityAlert> _activeAlerts = [];
  Map<String, dynamic> _passwordStats = {};
  ThreatDetectionService.ThreatLevel _threatLevel = ThreatDetectionService.ThreatLevel.none;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Récupérer les alertes de sécurité
      await _alertService.checkForSecurityAlerts();
      _activeAlerts = _alertService.activeAlerts.where((alert) => alert.isActive).toList();
      
      // Récupérer les statistiques des mots de passe
      _passwordStats = await _passwordService.getPasswordStatistics();
      
      // Récupérer le niveau de menace
      _threatLevel = await _threatService.checkForThreats();
      
      // Calculer le score de sécurité global
      _securityScore = _calculateOverallSecurityScore();
    } catch (e) {
      print('Erreur lors du chargement des données: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Calculer le score de sécurité global
  int _calculateOverallSecurityScore() {
    // Commencer avec le score des mots de passe (sur 100)
    int score = _passwordStats['security_score'] ?? 50;
    
    // Réduire le score en fonction des alertes actives
    int totalAlerts = _activeAlerts.length;
    int criticalAlerts = _activeAlerts.where((a) => a.severity == SecurityAlertSeverity.critical).length;
    int warningAlerts = _activeAlerts.where((a) => a.severity == SecurityAlertSeverity.warning).length;
    
    // Pénalités pour les alertes
    score -= criticalAlerts * 15;
    score -= warningAlerts * 5;
    
    // Pénalités pour le niveau de menace
    switch (_threatLevel) {
      case ThreatDetectionService.ThreatLevel.critical:
        score -= 30;
        break;
      case ThreatDetectionService.ThreatLevel.high:
        score -= 20;
        break;
      case ThreatDetectionService.ThreatLevel.medium:
        score -= 10;
        break;
      case ThreatDetectionService.ThreatLevel.low:
        score -= 5;
        break;
      default:
        break;
    }
    
    // Limiter le score entre 0 et 100
    return score.clamp(0, 100);
  }
  
  // Déterminer la couleur du score de sécurité
  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }
  
  // Déterminer l'évaluation du score
  String _getScoreRating(int score) {
    if (score >= 90) return 'Excellent';
    if (score >= 80) return 'Très bon';
    if (score >= 70) return 'Bon';
    if (score >= 60) return 'Assez bon';
    if (score >= 40) return 'Moyen';
    if (score >= 20) return 'Faible';
    return 'Critique';
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapport de sécurité'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _buildReportContent(),
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
    );
  }
  
  Widget _buildReportContent() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score de sécurité global
            _buildSecurityScoreCard(),
            const SizedBox(height: 20),
            
            // Alertes de sécurité
            _buildSecurityAlertsSection(),
            const SizedBox(height: 20),
            
            // Statistiques des mots de passe
            _buildPasswordStatsSection(),
            const SizedBox(height: 20),
            
            // État de la sécurité de l'appareil
            _buildDeviceSecuritySection(),
            const SizedBox(height: 20),
            
            // Recommandations de sécurité
            _buildRecommendationsSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSecurityScoreCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Score de sécurité global',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Indicateur circulaire du score
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[200],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: _securityScore / 100,
                        strokeWidth: 12,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(_getScoreColor(_securityScore)),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$_securityScore%',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _getScoreRating(_securityScore),
                            style: TextStyle(
                              fontSize: 14,
                              color: _getScoreColor(_securityScore),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Explication du score
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Évaluation de votre sécurité',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getScoreExplanation(),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Dernière mise à jour
            Text(
              'Dernière mise à jour: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} à ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Explication du score en fonction de sa valeur
  String _getScoreExplanation() {
    if (_securityScore >= 80) {
      return 'Votre niveau de sécurité est très bon. Continuez à maintenir de bonnes pratiques de sécurité.';
    } else if (_securityScore >= 60) {
      return 'Votre niveau de sécurité est correct, mais quelques améliorations sont recommandées.';
    } else if (_securityScore >= 40) {
      return 'Votre niveau de sécurité est moyen. Suivez nos recommandations pour l\'améliorer.';
    } else {
      return 'Votre niveau de sécurité est faible. Des actions immédiates sont nécessaires pour protéger vos données.';
    }
  }
  
  Widget _buildSecurityAlertsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppThemes.secondaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Alertes de sécurité',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _activeAlerts.isEmpty ? Colors.green : Colors.amber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_activeAlerts.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_activeAlerts.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Aucune alerte de sécurité active. Votre compte est en bonne santé.',
                  style: TextStyle(color: Colors.green),
                ),
              )
            else
              ..._activeAlerts.map((alert) => _buildAlertItem(alert)).toList(),
            
            if (_activeAlerts.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: TextButton(
                  onPressed: () {
                    // Navigation vers l'écran détaillé des alertes
                  },
                  child: const Text('Voir toutes les alertes'),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAlertItem(SecurityAlert alert) {
    // Déterminer la couleur en fonction de la sévérité
    Color alertColor;
    IconData alertIcon;
    
    switch (alert.severity) {
      case SecurityAlertSeverity.critical:
        alertColor = Colors.red;
        alertIcon = Icons.error;
        break;
      case SecurityAlertSeverity.warning:
        alertColor = Colors.orange;
        alertIcon = Icons.warning;
        break;
      default:
        alertColor = Colors.blue;
        alertIcon = Icons.info;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: alertColor.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(8),
        color: alertColor.withOpacity(0.05),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(alertIcon, color: alertColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alert.description,
                  style: const TextStyle(fontSize: 13),
                ),
                if (alert.actionText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: TextButton(
                      onPressed: () {
                        // Action spécifique à l'alerte
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(alert.actionText!),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () {
              // Ignorer l'alerte
              _alertService.dismissAlert(alert.id);
              setState(() {
                _activeAlerts.removeWhere((a) => a.id == alert.id);
              });
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildPasswordStatsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lock, color: AppThemes.secondaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Santé des mots de passe',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatItem(
                  'Forts',
                  _passwordStats['strong_passwords']?.toString() ?? '0',
                  Colors.green,
                ),
                _buildStatItem(
                  'Moyens',
                  _passwordStats['medium_passwords']?.toString() ?? '0',
                  Colors.orange,
                ),
                _buildStatItem(
                  'Faibles',
                  _passwordStats['weak_passwords']?.toString() ?? '0',
                  Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Problèmes détectés
            if (_passwordStats['reused_passwords'] != null && _passwordStats['reused_passwords'] > 0)
              _buildPasswordIssueItem(
                'Mots de passe réutilisés',
                'Vous utilisez le même mot de passe sur ${_passwordStats['reused_passwords']} comptes différents.',
                Icons.repeat,
                Colors.orange,
              ),
            if (_passwordStats['outdated_passwords'] != null && _passwordStats['outdated_passwords'] > 0)
              _buildPasswordIssueItem(
                'Mots de passe obsolètes',
                '${_passwordStats['outdated_passwords']} mots de passe n\'ont pas été modifiés depuis plus de 90 jours.',
                Icons.update,
                Colors.amber,
              ),
            
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                // Navigation vers l'écran d'analyse des mots de passe
              },
              child: const Text('Analyser mes mots de passe'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPasswordIssueItem(String title, String description, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDeviceSecuritySection() {
    // Couleur en fonction du niveau de menace
    Color threatColor;
    String threatText;
    
    switch (_threatLevel) {
      case ThreatDetectionService.ThreatLevel.critical:
        threatColor = Colors.red;
        threatText = 'Critique';
        break;
      case ThreatDetectionService.ThreatLevel.high:
        threatColor = Colors.redAccent;
        threatText = 'Élevé';
        break;
      case ThreatDetectionService.ThreatLevel.medium:
        threatColor = Colors.orange;
        threatText = 'Moyen';
        break;
      case ThreatDetectionService.ThreatLevel.low:
        threatColor = Colors.amber;
        threatText = 'Faible';
        break;
      default:
        threatColor = Colors.green;
        threatText = 'Aucun';
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.security, color: AppThemes.secondaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Sécurité de l\'appareil',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Niveau de risque:',
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: threatColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: threatColor),
                        ),
                        child: Text(
                          threatText,
                          style: TextStyle(
                            color: threatColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    // Vérification de sécurité approfondie
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppThemes.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Vérifier'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Liste des menaces détectées
            if (_threatService.activeThreatDescriptions.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Problèmes détectés:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._threatService.activeThreatDescriptions.map((threat) => 
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.warning, color: Colors.orange, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              threat,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).toList(),
                ],
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('Aucun problème de sécurité détecté sur cet appareil.'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRecommendationsSection() {
    // Récupérer les recommandations en fonction des problèmes détectés
    List<String> recommendations = _threatService.getSecurityRecommendations();
    
    // Ajouter des recommandations basées sur les mots de passe
    if (_passwordStats['weak_passwords'] != null && _passwordStats['weak_passwords'] > 0) {
      recommendations.add('Renforcez vos mots de passe faibles en utilisant des combinaisons de caractères plus complexes.');
    }
    if (_passwordStats['reused_passwords'] != null && _passwordStats['reused_passwords'] > 0) {
      recommendations.add('Utilisez des mots de passe uniques pour chaque compte afin d\'éviter les compromissions en chaîne.');
    }
    if (_passwordStats['outdated_passwords'] != null && _passwordStats['outdated_passwords'] > 0) {
      recommendations.add('Changez régulièrement vos mots de passe anciens pour maintenir un bon niveau de sécurité.');
    }
    
    // Ajouter des recommandations générales si la liste est vide
    if (recommendations.isEmpty) {
      recommendations = [
        'Continuez à utiliser des mots de passe forts et uniques pour chaque compte.',
        'Activez l\'authentification à deux facteurs sur tous vos comptes sensibles.',
        'Effectuez régulièrement des vérifications de sécurité pour maintenir votre protection.',
      ];
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb, color: AppThemes.secondaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Recommandations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...recommendations.map((recommendation) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.arrow_right, color: AppThemes.primaryColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(recommendation),
                    ),
                  ],
                ),
              ),
            ).toList(),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                // Navigation vers l'écran de conseils de sécurité détaillés
              },
              icon: const Icon(Icons.security),
              label: const Text('Améliorer ma sécurité'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemes.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}