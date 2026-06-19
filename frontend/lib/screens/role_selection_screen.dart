import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import '../config.dart';
import '../theme.dart';
import '../models/user_profile.dart';
import 'intake_flow.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final userProfile = args is UserProfile ? args : UserProfile();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: CosmicTheme.cosmicGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 2),
                
                // Header Title
                Center(
                  child: Text(
                    'Who is the User',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Select a profile type to personalize your matching recommendations',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const Spacer(flex: 2),
                
                // Option 1: I Need Support
                _buildRoleOptionCard(
                  context: context,
                  title: 'I Need Support',
                  description: 'Start a personalized self-assessment to discover your custom benefits, accommodations, and action milestones.',
                  icon: Icons.accessibility_new_rounded,
                  onTap: () {
                    userProfile.role = 'I Need Support';
                    Navigator.pushNamed(
                      context,
                      '/intake',
                      arguments: userProfile,
                    );
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Option 2: Caregiver
                _buildRoleOptionCard(
                  context: context,
                  title: 'Caregiver',
                  description: 'Look up support benchmarks, schemes, and custom sensory adjustments on behalf of a dependent or relative.',
                  icon: Icons.favorite_rounded,
                  onTap: () {
                    userProfile.role = 'Caregiver';
                    Navigator.pushNamed(
                      context,
                      '/intake',
                      arguments: userProfile,
                    );
                  },
                ),
                
                const Spacer(flex: 3),
                
                // Login Button for returning users
                TextButton(
                  onPressed: () {
                    _showReturningUserDialog(context, userProfile.email);
                  },
                  child: Text(
                    'LOGIN AS RETURNING USER',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: Colors.white.withOpacity(0.9),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showReturningUserDialog(BuildContext context, String initialEmail) {
    final emailController = TextEditingController(text: initialEmail == 'user@example.com' ? '' : initialEmail);
    showDialog(
      context: context,
      builder: (ctx) {
        bool isDialogLoading = false;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: CosmicTheme.primaryBackground,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white10)),
              title: Text('Load Existing Profile', style: GoogleFonts.italiana(color: Colors.white, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Enter your registered email address to load your assessment data.', style: TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'serif')),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    style: const TextStyle(color: Colors.black87, fontFamily: 'serif'),
                    decoration: const InputDecoration(
                      hintText: 'email@example.com',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('CANCEL', style: TextStyle(color: Colors.white30)),
                  onPressed: () => Navigator.pop(dialogContext),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CosmicTheme.accentTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isDialogLoading ? null : () async {
                    final email = emailController.text.trim();
                    if (email.isEmpty) return;

                    setDialogState(() {
                      isDialogLoading = true;
                    });

                    final baseUrl = AppConfig.getBaseUrl(context);
                    try {
                      final response = await http.get(Uri.parse('$baseUrl/api/history?email=$email'));
                      if (response.statusCode == 200) {
                        final body = jsonDecode(response.body);
                        final history = body['history'] as List?;
                        if (history != null && history.isNotEmpty) {
                          final latest = history[0];
                          final pData = latest['profile'] ?? {};
                          final profile = UserProfile()
                            ..name = pData['name'] ?? ''
                            ..role = pData['role'] ?? 'I Need Support'
                            ..age = pData['age'] ?? ''
                            ..autismStatus = pData['autismStatus'] ?? 'No'
                            ..isStudent = pData['isStudent'] ?? false
                            ..studentHighest = pData['studentHighest'] ?? 'Graduate'
                            ..studentStatus = pData['studentStatus'] ?? 'College'
                            ..studentInstitution = pData['studentInstitution'] ?? ''
                            ..studentCourse = pData['studentCourse'] ?? 'B.Tech'
                            ..isEmployee = pData['isEmployee'] ?? false
                            ..employeeCompany = pData['employeeCompany'] ?? ''
                            ..employeeRole = pData['employeeRole'] ?? ''
                            ..employeeSupportDesired = pData['employeeSupportDesired'] ?? 'UNSURE'
                            ..state = pData['state'] ?? 'Kerala'
                            ..pincode = pData['pincode'] ?? ''
                            ..disabilityCertificate = pData['disabilityCertificate'] ?? 'Looking to apply'
                            ..communicationMethod = pData['communicationMethod'] ?? 'Verbal'
                            ..sensorySensitivity = pData['sensorySensitivity'] ?? 'None'
                            ..incomeRange = pData['incomeRange'] ?? 'Below \u20b92.5L'
                            ..targetedPath = pData['targetedPath'] ?? 'Academic grants'
                            ..insuranceNiramaya = pData['insuranceNiramaya'] ?? false
                            ..email = pData['email'] ?? '';
                          final matchedData = latest['result'] ?? {};

                          if (context.mounted) {
                            Navigator.pop(dialogContext);
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/dashboard',
                              (route) => false,
                              arguments: {
                                'profile': profile,
                                'matchedData': matchedData,
                              },
                            );
                          }
                          return;
                        }
                      }
                    } catch (e) {
                      print("Error fetching profile: $e");
                    }

                    if (dialogContext.mounted) {
                      setDialogState(() {
                        isDialogLoading = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No profile assessment history found for this email.')),
                      );
                    }
                  },
                  child: isDialogLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                      : const Text('LOAD'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  Widget _buildRoleOptionCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: CosmicTheme.cardForeground,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Container
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CosmicTheme.gradientMid,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 18),
                // Text Area
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: const TextStyle(
                          fontFamily: 'serif',
                          color: Colors.black54,
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Center(
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.black45,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
