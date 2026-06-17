import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/user_profile.dart';
import 'intake_flow.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                    final profile = UserProfile()..role = 'I Need Support';
                    Navigator.pushNamed(
                      context,
                      '/intake',
                      arguments: profile,
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
                    final profile = UserProfile()..role = 'Caregiver';
                    Navigator.pushNamed(
                      context,
                      '/intake',
                      arguments: profile,
                    );
                  },
                ),
                
                const Spacer(flex: 3),
                
                // Login Button for returning users
                TextButton(
                  onPressed: () {
                    // Quick mock bypass to dashboard for returning users
                    final defaultProfile = UserProfile()
                      ..name = "Demo User"
                      ..role = "I Need Support"
                      ..isStudent = true
                      ..studentInstitution = "CUSAT"
                      ..studentCourse = "B.Tech"
                      ..sensorySensitivity = "High"
                      ..disabilityCertificate = "Obtained"
                      ..incomeRange = "Below \u20b92.5L"
                      ..state = "Kerala";
                    
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/dashboard',
                      (route) => false,
                      arguments: defaultProfile,
                    );
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
