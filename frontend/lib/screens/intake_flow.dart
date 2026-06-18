import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../theme.dart';
import '../models/user_profile.dart';
import '../config.dart';

class IntakeFlowScreen extends StatefulWidget {
  const IntakeFlowScreen({super.key});

  @override
  State<IntakeFlowScreen> createState() => _IntakeFlowScreenState();
}

class _IntakeFlowScreenState extends State<IntakeFlowScreen> {
  late UserProfile _profile;
  bool _isInitialized = false;
  int _currentStepIndex = 0;

  // Controllers for text inputs
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _institutionController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _employeeRoleController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();

  // Selected values for student/employee router
  bool? _isStudentSelected;
  bool? _isEmployeeSelected;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      // Fetch profile passed from role selection
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is UserProfile) {
        _profile = args;
      } else {
        _profile = UserProfile();
      }
      
      // Sync controllers with initial values
      _nameController.text = _profile.name;
      _ageController.text = _profile.age;
      _institutionController.text = _profile.studentInstitution;
      _companyController.text = _profile.employeeCompany;
      _employeeRoleController.text = _profile.employeeRole;
      _pincodeController.text = _profile.pincode;

      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _institutionController.dispose();
    _companyController.dispose();
    _employeeRoleController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  // API Call helper
  Future<Map<String, dynamic>?> _submitProfileToBackend() async {
    // Determine Backend URL
    final baseUrl = AppConfig.getBaseUrl(context);

    try {
      print("Submitting profile to $baseUrl/api/match...");
      final response = await http.post(
        Uri.parse('$baseUrl/api/match'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(_profile.toJson()),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print("Backend returned error status: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Network error connecting to backend: $e");
      return null;
    }
  }

  // Navigation Logic with custom branching
  void _nextStep() {
    // Save current field entries to model
    _saveCurrentFields();

    setState(() {
      if (_currentStepIndex == 1) { // Router step
        _profile.isStudent = _isStudentSelected ?? false;
        _profile.isEmployee = _isEmployeeSelected ?? false;

        if (_profile.isStudent) {
          _currentStepIndex = 2; // Move to Student Branch
        } else if (_profile.isEmployee) {
          _currentStepIndex = 3; // Move to Employee Branch
        } else {
          _currentStepIndex = 4; // Move to Demographics
        }
      } else if (_currentStepIndex == 2) { // Student Branch
        if (_profile.isEmployee) {
          _currentStepIndex = 3; // Move to Employee Branch
        } else {
          _currentStepIndex = 4; // Move to Demographics
        }
      } else if (_currentStepIndex == 3) { // Employee Branch
        _currentStepIndex = 4; // Move to Demographics
      } else {
        _currentStepIndex++;
      }
    });
  }

  void _previousStep() {
    setState(() {
      if (_currentStepIndex == 4) { // Demographics step
        if (_profile.isEmployee) {
          _currentStepIndex = 3;
        } else if (_profile.isStudent) {
          _currentStepIndex = 2;
        } else {
          _currentStepIndex = 1;
        }
      } else if (_currentStepIndex == 3) { // Employee step
        if (_profile.isStudent) {
          _currentStepIndex = 2;
        } else {
          _currentStepIndex = 1;
        }
      } else if (_currentStepIndex == 2) { // Student step
        _currentStepIndex = 1;
      } else {
        _currentStepIndex--;
      }
    });
  }

  void _saveCurrentFields() {
    _profile.name = _nameController.text;
    _profile.age = _ageController.text;
    _profile.studentInstitution = _institutionController.text;
    _profile.employeeCompany = _companyController.text;
    _profile.employeeRole = _employeeRoleController.text;
    _profile.pincode = _pincodeController.text;
  }

  // Returns progress percentage and text depending on screen index
  double _getProgress() {
    switch (_currentStepIndex) {
      case 0: return 0.20; // 20% checkpoint
      case 1: return 0.50; // 50% checkpoint
      case 2: return 0.60;
      case 3: return 0.70;
      case 4: return 0.80; // 80% checkpoint
      case 5: return 0.85; // Introduction Gate
      case 6: return 0.90; // Deep Assessment
      case 7: return 0.95; // Financial / Final
      default: return 1.00;
    }
  }

  String _getProgressText() {
    switch (_currentStepIndex) {
      case 0: return "20% DONE";
      case 1: return "50% DONE";
      case 4: return "80% DONE";
      case 5: return "PREPARING ENGINE";
      case 6: return "90% DONE";
      case 7: return "95% DONE";
      default: return "IN PROGRESS";
    }
  }

  bool _isNextEnabled() {
    if (_currentStepIndex == 0) {
      return _nameController.text.trim().isNotEmpty && _ageController.text.trim().isNotEmpty;
    }
    if (_currentStepIndex == 1) {
      // Status Router requires both selections to be made
      return _isStudentSelected != null && _isEmployeeSelected != null;
    }
    if (_currentStepIndex == 2) {
      // Student Branch validation
      return _institutionController.text.trim().isNotEmpty;
    }
    if (_currentStepIndex == 3) {
      // Employee Branch validation
      return _companyController.text.trim().isNotEmpty && _employeeRoleController.text.trim().isNotEmpty;
    }
    if (_currentStepIndex == 4) {
      // Demographics validation
      return _pincodeController.text.trim().isNotEmpty;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isSupport = _profile.role == 'I Need Support';
    final progress = _getProgress();
    final progressText = _getProgressText();
    final nextEnabled = _isNextEnabled();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          // Use Cosmic gradient for Gate Screen, otherwise clean primary background
          gradient: (_currentStepIndex == 5) ? CosmicTheme.cosmicGradient : null,
          color: (_currentStepIndex != 5) ? CosmicTheme.primaryBackground : null,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Navigation Bar
              if (_currentStepIndex != 5) _buildTopHeader(isSupport),

              // Progress Bar Section
              if (_currentStepIndex != 5) _buildLocalProgressBar(progress, progressText),

              // Step Main Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  child: _buildStepContent(),
                ),
              ),

              // Bottom Navigation Controls
              if (_currentStepIndex != 5) _buildBottomNavbar(nextEnabled),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Builder Methods ---

  Widget _buildTopHeader(bool isSupport) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          if (_currentStepIndex > 0)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
              onPressed: _previousStep,
            )
          else
            const SizedBox(width: 48),
          Expanded(
            child: Center(
              child: Text(
                isSupport ? 'Personal Assessment' : 'Caregiver Benchmark Setup',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  letterSpacing: 1.5,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 48), // Spacer to balance back button
        ],
      ),
    );
  }

  Widget _buildLocalProgressBar(double progress, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: CosmicTheme.accentTeal,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(CosmicTheme.accentTeal),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavbar(bool nextEnabled) {
    // If router step is locked, render empty space or disabled appearance
    final showFloatButton = _currentStepIndex != 1 || nextEnabled;

    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left page counter
          Text(
            'Step ${_currentStepIndex + 1} of 8',
            style: const TextStyle(color: Colors.white54, fontFamily: 'serif'),
          ),
          
          // Right Nav button
          if (showFloatButton)
            FloatingActionButton(
              mini: true,
              backgroundColor: nextEnabled ? CosmicTheme.cardForeground : Colors.white12,
              foregroundColor: nextEnabled ? Colors.black87 : Colors.white30,
              onPressed: nextEnabled ? _nextStep : null,
              child: const Icon(Icons.arrow_forward_rounded),
            )
          else
            // Inactive empty state as per specification
            const SizedBox(width: 48, height: 48),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStepIndex) {
      case 0: return _buildStepUserInputs();
      case 1: return _buildStepStatusRouter();
      case 2: return _buildStepStudentBranch();
      case 3: return _buildStepEmployeeBranch();
      case 4: return _buildStepDemographics();
      case 5: return _buildStepGateScreen();
      case 6: return _buildStepDeepAssessment();
      case 7: return _buildStepFinancialFilter();
      default: return const SizedBox.shrink();
    }
  }

  // --- Step 0 (Screen 3): User Details (20% Checkpoint) ---
  Widget _buildStepUserInputs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _buildSectionHeader('Profile Intake', 'Enter basic profile parameters'),
        const SizedBox(height: 24),
        
        // Name Text Field
        const Text('Name of the individual:', style: TextStyle(fontFamily: 'serif', color: Colors.white70)),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          style: const TextStyle(color: Colors.black87, fontFamily: 'serif'),
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Enter name',
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Age Text Field
        const Text('Age:', style: TextStyle(fontFamily: 'serif', color: Colors.white70)),
        const SizedBox(height: 8),
        TextField(
          controller: _ageController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.black87, fontFamily: 'serif'),
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'e.g. 21',
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Autism Diagnosis Radio Choices
        const Text('Autism Diagnosis Status:', style: TextStyle(fontFamily: 'serif', color: Colors.white70)),
        const SizedBox(height: 10),
        _buildChoiceRadio('Yes', _profile.autismStatus, (val) {
          setState(() { _profile.autismStatus = val!; });
        }),
        _buildChoiceRadio('No', _profile.autismStatus, (val) {
          setState(() { _profile.autismStatus = val!; });
        }),
        _buildChoiceRadio('Undiagnosed', _profile.autismStatus, (val) {
          setState(() { _profile.autismStatus = val!; });
        }),
      ],
    );
  }

  // --- Step 1 (Screen 4): Status Router (50% Checkpoint) ---
  Widget _buildStepStatusRouter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _buildSectionHeader('Occupational Status', 'Confirm current student and employee pathways'),
        const SizedBox(height: 28),
        
        // Ask: Are you a student?
        const Text('Are you a student?', style: TextStyle(fontSize: 16, fontFamily: 'serif', fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildRouterSelectionCard('YES', _isStudentSelected == true, () {
                setState(() { _isStudentSelected = true; });
              }),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildRouterSelectionCard('NO', _isStudentSelected == false, () {
                setState(() { _isStudentSelected = false; });
              }),
            ),
          ],
        ),
        
        const SizedBox(height: 32),
        
        // Ask: Are you an employee?
        const Text('Are you currently employed / an employee?', style: TextStyle(fontSize: 16, fontFamily: 'serif', fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildRouterSelectionCard('YES', _isEmployeeSelected == true, () {
                setState(() { _isEmployeeSelected = true; });
              }),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildRouterSelectionCard('NO', _isEmployeeSelected == false, () {
                setState(() { _isEmployeeSelected = false; });
              }),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isStudentSelected == null || _isEmployeeSelected == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              '* Make selections above to unlock the navigation arrow.',
              style: TextStyle(color: CosmicTheme.accentAmber, fontSize: 13, fontStyle: FontStyle.italic),
            ),
          ),
      ],
    );
  }

  // --- Step 2 (Screen 5): Student Branch ---
  Widget _buildStepStudentBranch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _buildSectionHeader('Educational Credentials', 'Academic information intake branch'),
        const SizedBox(height: 20),
        
        // Highest level achieved
        const Text('Highest Education Level Achieved:', style: TextStyle(fontFamily: 'serif', color: Colors.white70)),
        const SizedBox(height: 8),
        _buildDropdownButton(
          value: _profile.studentHighest,
          items: ['10th', '12th', 'Graduate', 'Post Graduate', 'Diploma'],
          onChanged: (val) => setState(() => _profile.studentHighest = val!),
        ),
        
        const SizedBox(height: 20),
        
        // Current status
        const Text('Current Academic Enrollment:', style: TextStyle(fontFamily: 'serif', color: Colors.white70)),
        const SizedBox(height: 8),
        _buildDropdownButton(
          value: _profile.studentStatus,
          items: ['Schooling', 'College', 'ITI', 'Not Enrolled'],
          onChanged: (val) => setState(() => _profile.studentStatus = val!),
        ),
        
        const SizedBox(height: 20),
        
        // Institutional name tag (hint: CUSAT)
        const Text('Institutional Name / school:', style: TextStyle(fontFamily: 'serif', color: Colors.white70)),
        const SizedBox(height: 8),
        TextField(
          controller: _institutionController,
          style: const TextStyle(color: Colors.black87, fontFamily: 'serif'),
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'e.g. CUSAT',
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Course specific categories
        const Text('Course Stream / Specialty:', style: TextStyle(fontFamily: 'serif', color: Colors.white70)),
        const SizedBox(height: 8),
        _buildDropdownButton(
          value: _profile.studentCourse,
          items: ['B.Tech', 'M.Tech', 'IMSC', 'B.Sc', 'B.Com', 'BBA'],
          onChanged: (val) => setState(() => _profile.studentCourse = val!),
        ),
      ],
    );
  }

  // --- Step 3 (Screen 6): Employee Branch ---
  Widget _buildStepEmployeeBranch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _buildSectionHeader('Workplace Details', 'Professional configuration branch'),
        const SizedBox(height: 20),
        
        // Company Name
        const Text('Company Name:', style: TextStyle(fontFamily: 'serif', color: Colors.white70)),
        const SizedBox(height: 8),
        TextField(
          controller: _companyController,
          style: const TextStyle(color: Colors.black87, fontFamily: 'serif'),
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'e.g. Google',
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Professional Role
        const Text('Current Professional Role / Title:', style: TextStyle(fontFamily: 'serif', color: Colors.white70)),
        const SizedBox(height: 8),
        TextField(
          controller: _employeeRoleController,
          style: const TextStyle(color: Colors.black87, fontFamily: 'serif'),
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'e.g. Engineer',
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Corporate accommodation or employment support pathways desired?
        const Text('Corporate Accommodation support desired?', style: TextStyle(fontFamily: 'serif', color: Colors.white70)),
        const SizedBox(height: 12),
        Column(
          children: ['YES', 'NO', 'UNSURE'].map((opt) {
            final active = _profile.employeeSupportDesired == opt;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: GestureDetector(
                onTap: () => setState(() => _profile.employeeSupportDesired = opt),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: active ? CosmicTheme.accentTeal.withOpacity(0.25) : Colors.white10,
                    border: Border.all(
                      color: active ? CosmicTheme.accentTeal : Colors.white24,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        opt,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: active ? Colors.white : Colors.white70,
                          fontSize: 15,
                        ),
                      ),
                      Icon(
                        active ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                        color: active ? CosmicTheme.accentTeal : Colors.white30,
                      )
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // --- Step 4 (Screen 7): Demographic Mapping (80% Checkpoint) ---
  Widget _buildStepDemographics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _buildSectionHeader('Demographics & Region', 'Match location filters for local benefits'),
        const SizedBox(height: 24),
        
        // State selection
        const Text('Select State:', style: TextStyle(fontFamily: 'serif', color: Colors.white70)),
        const SizedBox(height: 8),
        _buildDropdownButton(
          value: _profile.state,
          items: ['Kerala', 'Tamil Nadu', 'Karnataka', 'Maharashtra', 'Delhi'],
          onChanged: (val) => setState(() => _profile.state = val!),
        ),
        
        const SizedBox(height: 24),
        
        // Pincode / Postal reference
        const Text('Pincode / Postal Reference:', style: TextStyle(fontFamily: 'serif', color: Colors.white70)),
        const SizedBox(height: 8),
        TextField(
          controller: _pincodeController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.black87, fontFamily: 'serif'),
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'e.g. 682022',
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'We use state filters to check regional pension grants and local medical assessment frameworks.',
          style: TextStyle(fontSize: 13, color: Colors.white38, fontStyle: FontStyle.italic, fontFamily: 'serif'),
        ),
      ],
    );
  }

  // --- Step 5 (Screen 8): Support Introduction Gate Screen ---
  Widget _buildStepGateScreen() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          // Large App Header
          Center(
            child: Text(
              'Neuro Guard',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 38,
                letterSpacing: 2.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'PROFILE ALIGNMENT ENGINE',
              style: TextStyle(
                color: CosmicTheme.accentTeal,
                fontSize: 14,
                letterSpacing: 3,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          const SizedBox(height: 48),
          
          const Text(
            'We are configuring your support structures:',
            style: TextStyle(fontSize: 16, fontFamily: 'serif', color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          
          // Benefit Translation detail card
          _buildGateFeatureRow(
            Icons.gavel_rounded,
            'Government Benefit Translation',
            'Decodes income rules, disability states, and national schemes automatically.',
          ),
          const SizedBox(height: 20),
          
          // Action Plan detail card
          _buildGateFeatureRow(
            Icons.playlist_add_check_circle_rounded,
            'Custom Action Plan Milestones',
            'Creates simple step-check roadmaps matching student or employee statuses.',
          ),
          const SizedBox(height: 20),
          
          // Therapy & accommodation detail card
          _buildGateFeatureRow(
            Icons.spa_rounded,
            'Therapy & Accommodation Filters',
            'Screens environment guidelines matching your sensory limits and communication styles.',
          ),
          
          const SizedBox(height: 52),
          
          // Expanded CTA Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: CosmicTheme.cardForeground,
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
            onPressed: _nextStep,
            child: const Text(
              'START THE QUESTIONNAIRE',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Step 6 (Screen 9): Deep Autism Support Assessment Screen ---
  Widget _buildStepDeepAssessment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _buildSectionHeader('Deep Functional Support', 'Safely assess communication and sensory accommodation levels'),
        const SizedBox(height: 20),
        
        // 1. Disability Certificate Validation Status
        _buildAssessmentSectionCard(
          title: 'Government Disability Certificate Status',
          child: Column(
            children: ['Obtained', 'Pending', 'Looking to apply'].map((opt) {
              return RadioListTile<String>(
                title: Text(opt, style: const TextStyle(color: Colors.black87, fontFamily: 'serif')),
                value: opt,
                activeColor: CosmicTheme.gradientMid,
                groupValue: _profile.disabilityCertificate,
                onChanged: (val) => setState(() => _profile.disabilityCertificate = val!),
              );
            }).toList(),
          ),
        ),
        
        const SizedBox(height: 20),
        
        // 2. Communication Method
        _buildAssessmentSectionCard(
          title: 'Primary Communication Method',
          child: Column(
            children: ['Verbal', 'Non-verbal/AAC devices', 'Gestures'].map((opt) {
              return RadioListTile<String>(
                title: Text(opt, style: const TextStyle(color: Colors.black87, fontFamily: 'serif')),
                value: opt,
                activeColor: CosmicTheme.gradientMid,
                groupValue: _profile.communicationMethod,
                onChanged: (val) => setState(() => _profile.communicationMethod = val!),
              );
            }).toList(),
          ),
        ),
        
        const SizedBox(height: 20),
        
        // 3. Environmental Sensory Sensitivity
        _buildAssessmentSectionCard(
          title: 'Sensory Sensitivity Trigger Levels',
          child: Column(
            children: ['High', 'Moderate', 'None'].map((opt) {
              return RadioListTile<String>(
                title: Text(opt, style: const TextStyle(color: Colors.black87, fontFamily: 'serif')),
                value: opt,
                activeColor: CosmicTheme.gradientMid,
                groupValue: _profile.sensorySensitivity,
                onChanged: (val) => setState(() => _profile.sensorySensitivity = val!),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // --- Step 7 (Screen 10): Financial Conditions & AI Filter Screen ---
  Widget _buildStepFinancialFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _buildSectionHeader('Financial & Pathway Configuration', 'Personalize scholarships and scheme structures'),
        const SizedBox(height: 20),
        
        // 1. Family Income Boundaries
        const Text('Family Income Boundaries:', style: TextStyle(fontFamily: 'serif', color: Colors.white70)),
        const SizedBox(height: 8),
        _buildDropdownButton(
          value: _profile.incomeRange,
          items: ['Below \u20b92.5L', '\u20b92.5L - \u20b98L', 'Above \u20b98L'],
          onChanged: (val) => setState(() => _profile.incomeRange = val!),
        ),
        
        const SizedBox(height: 24),
        
        // 2. Targeted Paths
        const Text('Select Your Primary Focus Track:', style: TextStyle(fontFamily: 'serif', color: Colors.white70)),
        const SizedBox(height: 8),
        _buildDropdownButton(
          value: _profile.targetedPath,
          items: ['Academic grants', 'Vocational training', 'Neurodivergent-friendly corporate jobs'],
          onChanged: (val) => setState(() => _profile.targetedPath = val!),
        ),
        
        const SizedBox(height: 28),
        
        // 3. Insurance Configurations (Niramaya)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Request Niramaya Scheme Alignment',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'serif'),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Align recommendations with the official Niramaya Health Insurance system.',
                      style: TextStyle(fontSize: 12, color: Colors.white38, fontFamily: 'serif'),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _profile.insuranceNiramaya,
                activeColor: CosmicTheme.accentTeal,
                onChanged: (val) => setState(() => _profile.insuranceNiramaya = val),
              )
            ],
          ),
        ),
        
        const SizedBox(height: 44),
        
        // COMPLETE Button - Executes backend check and routes to Dashboard
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: CosmicTheme.accentTeal,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: () async {
            // Show loading dialog
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => const Center(
                child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(CosmicTheme.accentTeal)),
              ),
            );

            // Fetch matched recommendation datasets from Flask backend
            final responseData = await _submitProfileToBackend();
            
            // Dismiss loading dialog
            Navigator.pop(context);

            // Navigate and clear routes to prevent backwards questionnaire page loop
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/dashboard',
              (route) => false,
              arguments: {
                'profile': _profile,
                'matchedData': responseData,
              },
            );
          },
          child: const Text(
            'COMPLETE CONFIGURATION',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // --- Sub UI Elements & Widgets ---

  Widget _buildSectionHeader(String heading, String subheading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          heading,
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: 4),
        Text(
          subheading,
          style: const TextStyle(fontSize: 14, color: Colors.white54, fontFamily: 'serif'),
        ),
      ],
    );
  }

  Widget _buildChoiceRadio(String label, String groupValue, ValueChanged<String?> onChanged) {
    return Theme(
      data: Theme.of(context).copyWith(
        unselectedWidgetColor: Colors.white38,
      ),
      child: RadioListTile<String>(
        title: Text(label, style: const TextStyle(color: Colors.white, fontFamily: 'serif')),
        value: label,
        activeColor: CosmicTheme.accentTeal,
        groupValue: groupValue,
        onChanged: onChanged,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildRouterSelectionCard(String label, bool active, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: active ? CosmicTheme.accentTeal.withOpacity(0.2) : CosmicTheme.cardForeground,
            border: Border.all(
              color: active ? CosmicTheme.accentTeal : Colors.transparent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: active ? Colors.white : Colors.black87,
              fontFamily: 'serif',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownButton({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: CosmicTheme.cardForeground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: CosmicTheme.cardForeground,
          iconEnabledColor: Colors.black87,
          isExpanded: true,
          style: const TextStyle(color: Colors.black87, fontSize: 16, fontFamily: 'serif'),
          items: items.map((String val) {
            return DropdownMenuItem<String>(
              value: val,
              child: Text(val),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildGateFeatureRow(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: CosmicTheme.accentTeal, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white, fontFamily: 'serif'),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: const TextStyle(fontSize: 13, color: Colors.white70, fontFamily: 'serif'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAssessmentSectionCard({required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        // Semi-transparent surface block as per specifications
        color: CosmicTheme.cardForeground.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: const BoxDecoration(
              color: CosmicTheme.gradientMid,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.white,
                fontFamily: 'serif',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: child,
          ),
        ],
      ),
    );
  }
}
