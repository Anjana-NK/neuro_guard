import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';
import '../theme.dart';
import '../models/user_profile.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleStandardLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address')),
      );
      return;
    }

    // Standard Email Regex Match
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address (e.g., user@example.com)')),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your password')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final name = email.split('@')[0];
    final profile = UserProfile()
      ..name = name
      ..email = email;

    await _attemptProfileLogin(email, profile);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _attemptProfileLogin(String email, UserProfile fallbackProfile) async {
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

          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              '/dashboard',
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
      print("Failed to fetch history during login: $e");
    }

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/role-selection', arguments: fallbackProfile);
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _isGoogleLoading = true;
    });

    final profile = UserProfile()
      ..name = "Google User"
      ..email = "google.user@gmail.com";

    await _attemptProfileLogin("google.user@gmail.com", profile);

    if (mounted) {
      setState(() {
        _isGoogleLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: CosmicTheme.cosmicGradient,
            ),
          ),
          
          // Floating background ambient glowing circles
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CosmicTheme.accentTeal.withOpacity(0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CosmicTheme.accentAmber.withOpacity(0.1),
              ),
            ),
          ),

          // Main Login Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // App logo image
                      Center(
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: CosmicTheme.accentTeal.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(55),
                            child: Image.asset(
                              'assets/images/app_logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: CosmicTheme.gradientMid,
                                  child: const Icon(Icons.security_rounded, size: 55, color: Colors.white70),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Heading Text
                      Center(
                        child: Text(
                          'NEURO GUARD',
                          style: GoogleFonts.italiana(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 3,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                          'Personalized Neurodivergent Support & Safety Navigation',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'serif',
                            color: Colors.white60,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Glassmorphic Login Box
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.12),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Access Portal',
                              style: GoogleFonts.italiana(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            
                            // Email Field
                            const Text(
                              'Email or Username',
                              style: TextStyle(fontFamily: 'serif', color: Colors.white70, fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _emailController,
                              style: const TextStyle(color: Colors.black87, fontFamily: 'serif'),
                              decoration: const InputDecoration(
                                hintText: 'email@example.com',
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Password Field
                            const Text(
                              'Password',
                              style: TextStyle(fontFamily: 'serif', color: Colors.white70, fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _passwordController,
                              obscureText: true,
                              style: const TextStyle(color: Colors.black87, fontFamily: 'serif'),
                              decoration: const InputDecoration(
                                hintText: '••••••••',
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Submit Button
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: CosmicTheme.accentTeal,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: _isLoading ? null : _handleStandardLogin,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'LOG IN',
                                      style: TextStyle(
                                        letterSpacing: 1.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Sign in with Google Button
                      _isGoogleLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation(CosmicTheme.accentTeal),
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white24),
                                color: Colors.white.withOpacity(0.04),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: _handleGoogleLogin,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Google Icon Mock
                                      Container(
                                        width: 22,
                                        height: 22,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                        ),
                                        alignment: Alignment.center,
                                        child: const Text(
                                          'G',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      const Text(
                                        'Sign in with Google',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          fontFamily: 'serif',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
