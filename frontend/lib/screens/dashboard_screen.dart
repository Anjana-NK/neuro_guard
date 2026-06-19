import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';
import '../models/user_profile.dart';
import '../config.dart';
import '../services/tts_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  int _selectedTabIndex = 0; // 0: Home, 1: Analysis, 2: RAG Search, 3: Centers, 4: Profile
  late UserProfile _profile;
  Map<String, dynamic>? _matchedData;
  bool _isInitialized = false;

  // Checklist Roadmap State
  List<Map<String, dynamic>> _actionTasks = [];

  // RAG Search State
  final TextEditingController _ragSearchController = TextEditingController();
  bool _isRagLoading = false;
  String _ragAnswer = "";
  List<dynamic> _ragSources = [];

  // Chatbot State
  final List<Map<String, String>> _chatMessages = [];
  bool _isChatLoading = false;
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  // Nearby Centers State
  List<dynamic> _nearbyCenters = [];
  bool _isCentersLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        _profile = args['profile'] as UserProfile;
        _matchedData = args['matchedData'] as Map<String, dynamic>?;
      } else if (args is UserProfile) {
        _profile = args;
      } else {
        _profile = UserProfile();
      }

      // Sync/Initialize Action Checklist from matchedData
      if (_matchedData != null && _matchedData!['actionPlan'] != null) {
        final List originalTasks = _matchedData!['actionPlan'];
        _actionTasks = originalTasks.map((t) => Map<String, dynamic>.from(t)).toList();
      } else {
        _actionTasks = [
          {
            "task": "Register on the National Swavlamban Card (UDID) Portal",
            "status": "pending",
            "priority": "high",
            "details": "Create an account on swavlambancard.gov.in to apply for disability verification."
          },
          {
            "task": "Create daily structured schedule",
            "status": "pending",
            "priority": "medium",
            "details": "Use visual tools and calendar blocks to establish daily workflows."
          }
        ];
      }

      // Initialize Chatbot welcome message
      if (_chatMessages.isEmpty) {
        _chatMessages.add({
          'sender': 'bot',
          'text': 'Hello ${_profile.name.isNotEmpty ? _profile.name : "there"}! I am your Neuro Guard Assistant. I can help you understand government benefits, accommodations, and sensory adjustments tailored to your profile. Ask me anything!'
        });
      }

      // Fetch nearby centers
      _fetchNearbyCenters();

      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _ragSearchController.dispose();
    _chatController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  // --- API Integrations ---

  Future<void> _fetchNearbyCenters() async {
    setState(() => _isCentersLoading = true);
    
    final baseUrl = AppConfig.getBaseUrl(context);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/centers/nearby'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'state': _profile.state,
          'pincode': _profile.pincode
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        setState(() {
          _nearbyCenters = body['centers'] ?? [];
          _isCentersLoading = false;
        });
      } else {
        setState(() => _isCentersLoading = false);
      }
    } catch (e) {
      setState(() => _isCentersLoading = false);
    }
  }

  Future<void> _queryRAG(String query) async {
    if (query.trim().isEmpty) return;
    
    setState(() {
      _isRagLoading = true;
      _ragAnswer = "";
      _ragSources = [];
    });

    final baseUrl = AppConfig.getBaseUrl(context);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/rag'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': query,
          'profile': _profile.toJson()
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        setState(() {
          _ragAnswer = body['answer'] ?? "No answer received.";
          _ragSources = body['sources'] ?? [];
          _isRagLoading = false;
        });
      } else {
        setState(() {
          _ragAnswer = "Error executing query. Status code: ${response.statusCode}";
          _isRagLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _ragAnswer = "Failed to communicate with the Knowledge Base server.";
        _isRagLoading = false;
      });
    }
  }

  Future<void> _downloadPDFReport() async {
    final baseUrl = AppConfig.getBaseUrl(context);

    final queryParams = Uri(queryParameters: {
      'name': _profile.name,
      'role': _profile.role,
      'age': _profile.age,
      'autismStatus': _profile.autismStatus,
      'sensorySensitivity': _profile.sensorySensitivity,
      'communicationMethod': _profile.communicationMethod,
      'incomeRange': _profile.incomeRange,
      'state': _profile.state,
      'pincode': _profile.pincode,
    }).query;

    final downloadUrl = "$baseUrl/api/report/pdf?$queryParams";
    final uri = Uri.parse(downloadUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not trigger PDF report download link.')),
        );
      }
    }
  }

  // --- Voice Assistant Commands Action Parser ---
  void _executeVoiceCommand(String rawCommand) {
    final cmd = rawCommand.toLowerCase();
    
    // Switch tabs
    if (cmd.contains("analysis") || cmd.contains("chart") || cmd.contains("അനാലിസിസ്") || cmd.contains("विश्लेषण") || cmd.contains("பகுப்பாய்வு")) {
      setState(() => _selectedTabIndex = 1);
    } else if (cmd.contains("search") || cmd.contains("scheme") || cmd.contains("തിരയുക") || cmd.contains("योजना") || cmd.contains("முகப்பு")) {
      setState(() => _selectedTabIndex = 2);
    } else if (cmd.contains("center") || cmd.contains("സ്ഥാപനങ്ങൾ") || cmd.contains("केंद्र") || cmd.contains("மையங்கள்")) {
      setState(() => _selectedTabIndex = 3);
    } else if (cmd.contains("profile") || cmd.contains("history") || cmd.contains("പ്രൊഫൈൽ") || cmd.contains("ഇതിഹാസം")) {
      setState(() => _selectedTabIndex = 4);
    } else if (cmd.contains("home") || cmd.contains("ഹോം") || cmd.contains("होम") || cmd.contains("முகப்பு")) {
      setState(() => _selectedTabIndex = 0);
    }

    // Execute queries
    if (cmd.contains("explain niramaya") || cmd.contains("നിരാമയ വിശദീകരിക്കുക") || cmd.contains("निरामय समझाएं") || cmd.contains("நிராமயா விளக்கு")) {
      setState(() => _selectedTabIndex = 2);
      _sendChatMessage("Explain Niramaya Health Insurance Scheme guidelines");
    } else if (cmd.contains("explain udid") || cmd.contains("സ്വവലംബൻ") || cmd.contains("यूडीआईडी")) {
      setState(() => _selectedTabIndex = 2);
      _sendChatMessage("How to apply for Swavlamban UDID card");
    }
  }

  Future<void> _sendChatMessage(String text) async {
    if (text.trim().isEmpty) return;
    
    setState(() {
      _chatMessages.add({
        'sender': 'user',
        'text': text.trim(),
      });
      _isChatLoading = true;
    });
    
    _chatController.clear();
    
    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    final baseUrl = AppConfig.getBaseUrl(context);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': text,
          'profile': _profile.toJson()
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final reply = body['reply'] as String? ?? "No reply received.";
        setState(() {
          _chatMessages.add({
            'sender': 'bot',
            'text': reply,
          });
          _isChatLoading = false;
        });
      } else {
        setState(() {
          _chatMessages.add({
            'sender': 'bot',
            'text': 'Sorry, I encountered an error communicating with the chat server (code ${response.statusCode}).',
          });
          _isChatLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _chatMessages.add({
          'sender': 'bot',
          'text': 'Failed to reach the chatbot server. Please check your network connection.',
        });
        _isChatLoading = false;
      });
    }

    // Scroll to bottom again
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSchemesModal(List benefits) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: CosmicTheme.primaryBackground,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                height: 4,
                width: 40,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Matched Support Schemes', style: GoogleFonts.italiana(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(ctx),
                    )
                  ],
                ),
              ),
              const Divider(color: Colors.white12),
              Expanded(
                child: benefits.isEmpty
                    ? Center(child: _buildFallbackCard("No matching schemes found."))
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: benefits.length,
                        itemBuilder: (c, idx) {
                          final item = benefits[idx];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.04),
                              border: Border.all(color: Colors.white10),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: CosmicTheme.gradientMid,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        item['badge'] ?? 'Scheme',
                                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Text(
                                      item['authority'] ?? '',
                                      style: const TextStyle(color: Colors.white38, fontSize: 11, fontFamily: 'serif'),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  item['title'] ?? '',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'serif'),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item['description'] ?? '',
                                  style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.3, fontFamily: 'serif'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Checklist state syncing back to Firestore ---
  void _updateTaskStatusInFirestore(int idx, String status) async {
    // Optimistic state updates
    setState(() {
      _actionTasks[idx]['status'] = status;
    });

    final baseUrl = AppConfig.getBaseUrl(context);

    try {
      // Re-submit updated checklist state to Firestore matching routes
      await http.post(
        Uri.parse('$baseUrl/api/match'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          ..._profile.toJson(),
          'actionPlan': _actionTasks
        }),
      );
    } catch (e) {
      // Fail silently or log
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      floatingActionButton: _buildGlobalVoiceAssistantFAB(),
      body: Container(
        decoration: BoxDecoration(
          gradient: CosmicTheme.cosmicGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildDashboardHeader(),
              
              // Dynamic Content Tab view
              Expanded(
                child: _buildTabContent(),
              ),

              // AI Badge Disclaimer
              _buildAIDisclosureBadge(),

              // Navigation Dock
              _buildBottomNavigationDock(),
            ],
          ),
        ),
      ),
    );
  }

  // --- Header & Layout builders ---

  Widget _buildDashboardHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: CosmicTheme.accentTeal.withOpacity(0.2),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    errorBuilder: (c, e, s) => const Icon(Icons.security_rounded, color: CosmicTheme.accentTeal),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello ${_profile.name.isNotEmpty ? _profile.name : 'User'} 👋',
                    style: GoogleFonts.italiana(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _profile.role == 'Caregiver' ? 'Caregiver Dashboard' : 'Self Assessment Support',
                    style: const TextStyle(
                      fontFamily: 'serif',
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.history_rounded, color: Colors.white70),
                onPressed: () => Navigator.pushNamed(context, '/history', arguments: _profile),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: Colors.white70),
                onPressed: _showMockNotifications,
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildAnalysisTab();
      case 2:
        return _buildRAGSearchTab();
      case 3:
        return _buildNearbyCentersTab();
      case 4:
        return _buildProfileTab();
      default:
        return _buildHomeTab();
    }
  }

  // ================= TAB 0: HOME DASHBOARD =================
  Widget _buildHomeTab() {
    final similarMatches = _matchedData != null && _matchedData!['similarRecommendations'] != null
        ? (_matchedData!['similarRecommendations'] as List)
        : [];

    final aiExplanationText = _matchedData != null && _matchedData!['aiExplanation'] != null
        ? _matchedData!['aiExplanation'] as String
        : "Complete the intake flow to generate personalized recommendations.";

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          
          // Essential Quick Grid
          Text('Essential Services', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17)),
          const SizedBox(height: 10),
          _build4QuadrantGrid(),
          const SizedBox(height: 24),
          
          // Similar Profile Recommendations Panel
          Text('Community Insights (Similar Profiles)', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17)),
          const SizedBox(height: 10),
          if (similarMatches.isEmpty)
            _buildFallbackCard("No profile recommendations available.")
          else
            ...similarMatches.map((item) {
              return _buildSimilarProfileCard(item);
            }).toList(),
          const SizedBox(height: 24),

          // AI Explanation Narrative
          Text('AI Explanation & Matching Insights', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white.withOpacity(0.06), Colors.white.withOpacity(0.02)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: CosmicTheme.accentTeal.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.auto_awesome_rounded, color: CosmicTheme.accentTeal, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Decoded Schemes Summary',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'serif', fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  aiExplanationText,
                  style: const TextStyle(color: Colors.white70, height: 1.4, fontSize: 13, fontFamily: 'serif'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _build4QuadrantGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.4,
      children: [
        _buildGridButton(
          title: 'Analysis & Risks',
          icon: Icons.analytics_outlined,
          color: const Color(0xFF4A90E2),
          onTap: () => setState(() => _selectedTabIndex = 1),
        ),
        _buildGridButton(
          title: 'AI Chatbot',
          icon: Icons.forum_rounded,
          color: CosmicTheme.accentTeal,
          onTap: () => setState(() => _selectedTabIndex = 2),
        ),
        _buildGridButton(
          title: 'Action Roadmap',
          icon: Icons.checklist_rtl_rounded,
          color: CosmicTheme.accentAmber,
          onTap: _showActionPlanModal,
        ),
        _buildGridButton(
          title: 'Support Centers',
          icon: Icons.map_outlined,
          color: const Color(0xFF9B59B6),
          onTap: () => setState(() => _selectedTabIndex = 3),
        ),
      ],
    );
  }

  Widget _buildGridButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 28),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                fontFamily: 'serif',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimilarProfileCard(dynamic item) {
    final name = item['anonymized_name'] ?? 'Peer';
    final state = item['state'] ?? 'Kerala';
    final sensory = item['sensory'] ?? 'None';
    final schemes = (item['claimed_schemes'] as List?) ?? [];
    final matchPct = item['similarity'] ?? '80%';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14, fontFamily: 'serif'),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: CosmicTheme.accentTeal.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Match Similarity: $matchPct',
                  style: const TextStyle(color: CosmicTheme.accentTeal, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Location: $state | Sensory sensitivity: $sensory',
            style: const TextStyle(color: Colors.white38, fontSize: 12, fontFamily: 'serif'),
          ),
          const SizedBox(height: 10),
          const Text(
            'Acquired Schemes:',
            style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'serif'),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: schemes.map((s) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  s.toString(),
                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'serif'),
                ),
              );
            }).toList(),
          )
        ],
      ),
    );
  }

  // ================= TAB 1: ANALYSIS & RISKS =================
  Widget _buildAnalysisTab() {
    final riskData = _matchedData != null && _matchedData!['riskAssessment'] != null
        ? _matchedData!['riskAssessment'] as Map<String, dynamic>
        : {};

    // Compute metrics
    int sensoryVal = riskData['sensory_overload_risk'] != null ? riskData['sensory_overload_risk']['score'] : 10;
    int commsVal = riskData['communication_barrier'] != null ? riskData['communication_barrier']['score'] : 15;
    int stressVal = riskData['academic_workplace_stress'] != null ? riskData['academic_workplace_stress']['score'] : 20;
    int finVal = riskData['financial_need'] != null ? riskData['financial_need']['score'] : 25;

    int completedTasks = _actionTasks.where((t) => t['status'] == 'completed').length;
    int totalTasks = _actionTasks.length;
    double progressPct = totalTasks > 0 ? completedTasks / totalTasks : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Progress Tracker Chart
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 90,
                  height: 90,
                  child: CustomPaint(
                    painter: ProgressRingPainter(progressPct),
                    child: Center(
                      child: Text(
                        '${(progressPct * 100).toInt()}%',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Roadmap Progress',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white, fontFamily: 'serif'),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$completedTasks of $totalTasks milestones complete.',
                        style: const TextStyle(color: Colors.white54, fontSize: 13, fontFamily: 'serif'),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          backgroundColor: CosmicTheme.accentTeal.withOpacity(0.15),
                          foregroundColor: CosmicTheme.accentTeal,
                          side: const BorderSide(color: CosmicTheme.accentTeal),
                        ),
                        onPressed: _showActionPlanModal,
                        child: const Text('MANAGE TASKS', style: TextStyle(fontSize: 12)),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. Risk Prediction Radar/Bar Chart
          Text('Risk & Challenge Assessment', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17)),
          const SizedBox(height: 10),
          Container(
            height: 200,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white10),
            ),
            child: CustomPaint(
              size: Size.infinite,
              painter: RiskBarChartPainter(
                sensory: sensoryVal.toDouble(),
                comms: commsVal.toDouble(),
                stress: stressVal.toDouble(),
                financial: finVal.toDouble(),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 3. AI Predictive Insight details
          if (riskData.isNotEmpty)
            ...riskData.entries.where((e) => e.key != 'summary').map((e) {
              final title = e.key.replaceFirst('risk', '').replaceAll('_', ' ').trim().toUpperCase();
              final score = e.value['score'] ?? 0;
              final level = e.value['level'] ?? 'LOW';
              final advice = e.value['advice'] ?? '';
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white70, fontFamily: 'serif'),
                        ),
                        Text(
                          '$score% ($level)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: level == 'HIGH' ? CosmicTheme.accentAmber : CosmicTheme.accentTeal,
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      advice,
                      style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.3, fontFamily: 'serif'),
                    ),
                  ],
                ),
              );
            }).toList()
        ],
      ),
    );
  }

  Widget _buildRAGSearchTab() {
    final benefits = _matchedData != null && _matchedData!['benefits'] != null
        ? (_matchedData!['benefits'] as List)
        : [];

    return Column(
      children: [
        // Chat Header with Action Buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Support Chatbot',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white, fontFamily: 'serif'),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Profile-aware guidance & accommodations',
                      style: TextStyle(fontSize: 11, color: Colors.white54, fontFamily: 'serif'),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: CosmicTheme.accentTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.list_alt_rounded, size: 16),
                label: const Text('SCHEMES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () => _showSchemesModal(benefits),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Colors.white12),

        // Chat Messages List
        Expanded(
          child: ListView.builder(
            controller: _chatScrollController,
            padding: const EdgeInsets.all(20),
            itemCount: _chatMessages.length + (_isChatLoading ? 1 : 0),
            itemBuilder: (ctx, idx) {
              if (idx == _chatMessages.length) {
                // Loading indicator bubble
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12, right: 60),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(CosmicTheme.accentTeal),
                      ),
                    ),
                  ),
                );
              }

              final msg = _chatMessages[idx];
              final isBot = msg['sender'] == 'bot';
              final bubbleColor = isBot ? Colors.white.withOpacity(0.05) : CosmicTheme.accentTeal.withOpacity(0.15);
              final borderColor = isBot ? Colors.white.withOpacity(0.08) : CosmicTheme.accentTeal.withOpacity(0.3);
              final textStyle = TextStyle(
                color: isBot ? Colors.white.withOpacity(0.9) : Colors.white,
                fontSize: 13.5,
                height: 1.4,
                fontFamily: 'serif',
              );

              return Align(
                alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  margin: EdgeInsets.only(
                    bottom: 12,
                    left: isBot ? 0 : 60,
                    right: isBot ? 60 : 0,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isBot ? Radius.zero : const Radius.circular(16),
                      bottomRight: isBot ? const Radius.circular(16) : Radius.zero,
                    ),
                    border: Border.all(color: borderColor),
                  ),
                  child: Text(msg['text'] ?? '', style: textStyle),
                ),
              );
            },
          ),
        ),

        // Quick Suggestion Chips
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildChatSuggestionChip("Explain Niramaya Insurance"),
              _buildChatSuggestionChip("How to get UDID card"),
              _buildChatSuggestionChip("CBSE Concessions"),
              _buildChatSuggestionChip("Corporate Accommodations"),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Chat Input Row
        Padding(
          padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0, top: 4.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  style: const TextStyle(color: Colors.black87, fontFamily: 'serif'),
                  decoration: const InputDecoration(
                    hintText: 'Ask Neuro Guard a question...',
                    contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  ),
                  onSubmitted: _sendChatMessage,
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _sendChatMessage(_chatController.text),
                child: Container(
                  height: 52,
                  width: 52,
                  decoration: BoxDecoration(
                    color: CosmicTheme.accentTeal,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.send_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatSuggestionChip(String query) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        backgroundColor: const Color(0xFF203A43),
        surfaceTintColor: Colors.transparent,
        side: const BorderSide(color: CosmicTheme.accentTeal, width: 1.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        label: Text(query, style: const TextStyle(fontSize: 11, fontFamily: 'serif', color: Colors.white)),
        onPressed: () => _sendChatMessage(query),
      ),
    );
  }

  // ================= TAB 3: NEARBY CENTERS =================
  Widget _buildNearbyCentersTab() {
    return _isCentersLoading
        ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(CosmicTheme.accentTeal)))
        : ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: _nearbyCenters.length,
            itemBuilder: (ctx, index) {
              final center = _nearbyCenters[index];
              final name = center['name'] ?? 'Support Center';
              final city = center['city'] ?? '';
              final state = center['state'] ?? '';
              final address = center['address'] ?? '';
              final phone = center['phone'] ?? '';
              final web = center['website'] ?? '';
              final services = (center['services'] as List?) ?? [];

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  border: Border.all(color: Colors.white10),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white, fontFamily: 'serif'),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$city, $state',
                      style: const TextStyle(color: CosmicTheme.accentTeal, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'serif'),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      address,
                      style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.3, fontFamily: 'serif'),
                    ),
                    const SizedBox(height: 12),
                    if (phone.isNotEmpty || web.isNotEmpty)
                      Row(
                        children: [
                          if (phone.isNotEmpty) ...[
                            const Icon(Icons.phone_rounded, color: Colors.white38, size: 14),
                            const SizedBox(width: 4),
                            Text(phone, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                            const SizedBox(width: 16),
                          ],
                          if (web.isNotEmpty) ...[
                            const Icon(Icons.language_rounded, color: Colors.white38, size: 14),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () async {
                                final uri = Uri.parse(web);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                }
                              },
                              child: Text(
                                'Website',
                                style: TextStyle(
                                  color: Colors.blueAccent.shade100,
                                  fontSize: 11,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ]
                        ],
                      ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: services.map((s) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            s.toString(),
                            style: const TextStyle(color: Colors.white54, fontSize: 10),
                          ),
                        );
                      }).toList(),
                    )
                  ],
                ),
              );
            },
          );
  }

  // ================= TAB 4: PROFILE & HISTORY =================
  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              border: Border.all(color: Colors.white10),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: CosmicTheme.gradientMid,
                    child: Icon(Icons.person_rounded, size: 40, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    _profile.name,
                    style: GoogleFonts.italiana(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                Center(
                  child: Text(
                    'Profile Role: ${_profile.role}',
                    style: const TextStyle(color: Colors.white54, fontFamily: 'serif'),
                  ),
                ),
                const Divider(height: 28, color: Colors.white12),
                
                _buildProfileRow('Age Reference', _profile.age),
                _buildProfileRow('Diagnosis Verified', _profile.autismStatus),
                _buildProfileRow('State jurisdiction', _profile.state),
                _buildProfileRow('Area Pincode', _profile.pincode),
                _buildProfileRow('UDID Certificate', _profile.disabilityCertificate),
                _buildProfileRow('Communication style', _profile.communicationMethod),
                _buildProfileRow('Sensory Threshold', _profile.sensorySensitivity),
                _buildProfileRow('Income Bracket', _profile.incomeRange),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Download report CTA
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: CosmicTheme.accentTeal,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.picture_as_pdf_rounded),
            label: const Text('DOWNLOAD PDF ASSESSMENT REPORT', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: _downloadPDFReport,
          ),
          const SizedBox(height: 14),

          // Transition to history timeline
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.08),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.history_rounded),
            label: const Text('VIEW ASSESSMENT TIMELINE HISTORY', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.pushNamed(context, '/history', arguments: _profile),
          ),
          const SizedBox(height: 20),

          // Reroute back to Role Selection Screen
          TextButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, '/role-selection', (route) => false);
            },
            child: const Text(
              'RESET CONFIGURATION ENGINE',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.redAccent, decoration: TextDecoration.underline),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontFamily: 'serif', fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontFamily: 'serif', fontSize: 13)),
        ],
      ),
    );
  }

  // ================= ACTION CHECKLIST ROADMAP SHEET =================
  void _showActionPlanModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: const BoxDecoration(
                color: CosmicTheme.primaryBackground,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Action Plan Roadmap', style: GoogleFonts.italiana(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                  ),
                  
                  const Divider(color: Colors.white12),

                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _actionTasks.length,
                      itemBuilder: (c, idx) {
                        final task = _actionTasks[idx];
                        final isCompleted = task['status'] == 'completed';
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(isCompleted ? 0.02 : 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isCompleted ? Colors.transparent : Colors.white10),
                          ),
                          child: CheckboxListTile(
                            activeColor: CosmicTheme.accentTeal,
                            checkColor: Colors.black87,
                            value: isCompleted,
                            onChanged: (bool? val) {
                              final newStatus = val! ? 'completed' : 'pending';
                              setModalState(() {
                                _actionTasks[idx]['status'] = newStatus;
                              });
                              _updateTaskStatusInFirestore(idx, newStatus);
                            },
                            title: Text(
                              task['task'] ?? '',
                              style: TextStyle(
                                decoration: isCompleted ? TextDecoration.lineThrough : null,
                                color: isCompleted ? Colors.white30 : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'serif',
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
            );
          }
        );
      },
    );
  }

  // ================= MULTILINGUAL VOICE ASSISTANT OVERLAY =================
  Widget _buildGlobalVoiceAssistantFAB() {
    return FloatingActionButton(
      backgroundColor: CosmicTheme.accentTeal,
      child: const Icon(Icons.mic_none_rounded, color: Colors.white),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) {
            return const VoiceAssistantDrawer();
          },
        ).then((cmd) {
          if (cmd is String && cmd.isNotEmpty) {
            _executeVoiceCommand(cmd);
          }
        });
      },
    );
  }

  // ================= GENERAL WIDGETS =================
  Widget _buildFallbackCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: Colors.white30, fontFamily: 'serif', fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildAIDisclosureBadge() {
    return Container(
      width: double.infinity,
      color: CosmicTheme.accentAmber.withOpacity(0.12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.info_outline_rounded, color: CosmicTheme.accentAmber, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Responsible AI: Information and charts are guide recommendations. Verify with clinicians.',
              style: TextStyle(color: CosmicTheme.accentAmber, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'serif'),
              textAlign: TextAlign.center,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBottomNavigationDock() {
    return BottomNavigationBar(
      currentIndex: _selectedTabIndex,
      onTap: (index) => setState(() => _selectedTabIndex = index),
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFF1B1D22),
      selectedItemColor: CosmicTheme.accentTeal,
      unselectedItemColor: Colors.white30,
      selectedLabelStyle: const TextStyle(fontFamily: 'serif', fontWeight: FontWeight.bold, fontSize: 10),
      unselectedLabelStyle: const TextStyle(fontFamily: 'serif', fontSize: 10),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), label: 'Analysis'),
        BottomNavigationBarItem(icon: Icon(Icons.forum_rounded), label: 'AI Chatbot'),
        BottomNavigationBarItem(icon: Icon(Icons.location_on_outlined), label: 'Centers'),
        BottomNavigationBarItem(icon: Icon(Icons.account_circle_rounded), label: 'Profile'),
      ],
    );
  }

  void _showMockNotifications() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CosmicTheme.primaryBackground,
        title: Text('Updates & Alerts', style: GoogleFonts.italiana(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('• Niramaya scheme claims portal updated for 2026.', style: TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'serif')),
            SizedBox(height: 10),
            Text('• Sensory adjustments active for your user profile.', style: TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'serif')),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('DISMISS', style: TextStyle(color: CosmicTheme.accentTeal)),
            onPressed: () => Navigator.pop(ctx),
          )
        ],
      ),
    );
  }
}

// ================= CUSTOM PAINTERS =================

class ProgressRingPainter extends CustomPainter {
  final double progress;
  ProgressRingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    final backgroundPaint = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    final activePaint = Paint()
      ..color = CosmicTheme.accentTeal
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8;

    canvas.drawCircle(center, radius, backgroundPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.570796, // -90 degrees in radians
      progress * 6.283185, // 360 degrees in radians
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class RiskBarChartPainter extends CustomPainter {
  final double sensory;
  final double comms;
  final double stress;
  final double financial;

  RiskBarChartPainter({
    required this.sensory,
    required this.comms,
    required this.stress,
    required this.financial,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double padding = 24.0;
    final double graphHeight = size.height - 40;
    final double barWidth = 32.0;
    final double spacing = (size.width - (barWidth * 4) - (padding * 2)) / 3;

    final labels = ["Sensory", "Comms", "Stress", "Financial"];
    final values = [sensory, comms, stress, financial];

    for (int i = 0; i < 4; i++) {
      final double x = padding + (i * (barWidth + spacing));
      final double barHeight = (values[i] / 100) * graphHeight;
      final double y = size.height - barHeight - 20;

      // Draw background track
      final trackRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, 20, barWidth, graphHeight),
        const Radius.circular(8),
      );
      canvas.drawRRect(trackRect, Paint()..color = Colors.white12);

      // Draw glowing active bar
      final activePaint = Paint()
        ..shader = LinearGradient(
          colors: [
            values[i] > 70 ? CosmicTheme.accentAmber : CosmicTheme.accentTeal,
            values[i] > 70 ? Colors.deepOrange : CosmicTheme.gradientBottom,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(x, y, barWidth, barHeight))
        ..style = PaintingStyle.fill;

      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(8),
      );
      canvas.drawRRect(barRect, activePaint);

      // Draw Value Text
      final valuePainter = TextPainter(
        text: TextSpan(
          text: '${values[i].toInt()}%',
          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'serif'),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      valuePainter.paint(canvas, Offset(x + (barWidth - valuePainter.width) / 2, y - 14));

      // Draw Label
      final labelPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'serif'),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      labelPainter.paint(canvas, Offset(x + (barWidth - labelPainter.width) / 2, size.height - 12));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ================= VOICE ASSISTANT DRAWER COMPONENT =================

class VoiceAssistantDrawer extends StatefulWidget {
  const VoiceAssistantDrawer({super.key});

  @override
  State<VoiceAssistantDrawer> createState() => _VoiceAssistantDrawerState();
}

class _VoiceAssistantDrawerState extends State<VoiceAssistantDrawer> with SingleTickerProviderStateMixin {
  String _activeLanguage = "English";
  String _assistantStatus = "Listening...";
  String _speechResult = "";
  String _assistantReplyText = "";
  bool _isSpeaking = false;
  late AnimationController _waveformController;

  @override
  void initState() {
    super.initState();
    _waveformController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _waveformController.dispose();
    TtsService.stop();
    super.dispose();
  }

  // Mock voice prompt mapping based on selected language
  Map<String, List<String>> get _suggestions => {
    "English": ["Show Analysis", "Show Nearby Centers", "Explain Niramaya", "Help"],
    "Malayalam": ["അനാലിസിസ് കാണിക്കുക", "സ്ഥാപനങ്ങൾ കാണിക്കുക", "നിരാമയ വിശദീകരിക്കുക"],
    "Hindi": ["विश्लेषण दिखाएं", "केंद्र दिखाएं", "निरामय समझाएं"],
    "Tamil": ["பகுப்பாய்வு காட்டு", "மையங்களை காட்டு", "நிராமயா விளக்கு"]
  };

  void _triggerCommand(String text) async {
    setState(() {
      _speechResult = text;
      _assistantStatus = "Processing...";
    });

    await Future.delayed(const Duration(milliseconds: 1000));

    // Mock response generation based on language
    String reply = "Analyzing command...";
    if (_activeLanguage == "Malayalam") {
      reply = "കമാൻഡ് സ്വീകരിച്ചു. ആവശ്യമുള്ള വിവരങ്ങൾ സ്ക്രീനിൽ കാണിക്കുന്നു.";
    } else if (_activeLanguage == "Hindi") {
      reply = "निर्देश स्वीकार किया गया। जानकारी दिखाई जा रही है।";
    } else if (_activeLanguage == "Tamil") {
      reply = "கட்டளை ஏற்றுக்கொள்ளப்பட்டது. விவரங்கள் திரையில் காட்டப்படும்.";
    } else {
      reply = "Command executed successfully. Navigating...";
    }

    if (text.toLowerCase().contains("niramaya") || text.contains("നിരാമയ") || text.contains("निरामय") || text.contains("நிராமயா")) {
      reply += " RAG search triggered for Niramaya Scheme.";
    }

    setState(() {
      _assistantReplyText = reply;
      _assistantStatus = "Speaking...";
      _isSpeaking = true;
    });

    // Speak using TTS service
    await TtsService.speak(reply, _activeLanguage);

    // Simulate speech playback delay before completing navigation
    await Future.delayed(const Duration(milliseconds: 3000));
    
    if (mounted) {
      setState(() {
        _isSpeaking = false;
        _assistantStatus = "Listening...";
      });
      Navigator.pop(context, text); // Send command back to dashboard screen
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Color(0xFF1B1D22),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              height: 4,
              width: 40,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Voice Assistant',
                style: GoogleFonts.italiana(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              // Language Dropdown selector
              DropdownButton<String>(
                value: _activeLanguage,
                dropdownColor: const Color(0xFF2C2F36),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                icon: const Icon(Icons.translate_rounded, color: CosmicTheme.accentTeal, size: 18),
                underline: const SizedBox(),
                items: ["English", "Malayalam", "Hindi", "Tamil"].map((l) {
                  return DropdownMenuItem(value: l, child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(l),
                  ));
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _activeLanguage = val!;
                    _assistantReplyText = "";
                  });
                },
              )
            ],
          ),
          const SizedBox(height: 16),

          // Glowing Waveform visual feedback
          Container(
            height: 80,
            alignment: Alignment.center,
            child: AnimatedBuilder(
              animation: _waveformController,
              builder: (ctx, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(10, (idx) {
                    double height = 15.0 + (10 - idx).abs() * 3.0 * (1.0 + _waveformController.value);
                    if (_isSpeaking) {
                      height *= 0.5; // smaller spikes when speaking vs listening
                    }
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 4,
                      height: height % 50.0,
                      decoration: BoxDecoration(
                        color: _isSpeaking ? CosmicTheme.accentAmber : CosmicTheme.accentTeal,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
          Center(
            child: Text(
              _assistantStatus,
              style: TextStyle(
                color: _isSpeaking ? CosmicTheme.accentAmber : CosmicTheme.accentTeal,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Speech Output
          if (_speechResult.isNotEmpty)
            Text(
              'You said: "${_speechResult}"',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontStyle: FontStyle.italic, fontSize: 12, fontFamily: 'serif'),
            ),
          const SizedBox(height: 8),
          if (_assistantReplyText.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _assistantReplyText,
                style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3, fontFamily: 'serif'),
                textAlign: TextAlign.center,
              ),
            ),
          
          const Spacer(),

          // Chips selection suggestions
          const Text(
            'Quick Commands:',
            style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _suggestions[_activeLanguage]!.map((suggestion) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ActionChip(
                    backgroundColor: const Color(0xFF203A43),
                    surfaceTintColor: Colors.transparent,
                    side: const BorderSide(color: CosmicTheme.accentTeal, width: 1.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    label: Text(suggestion, style: const TextStyle(fontSize: 12, fontFamily: 'serif', color: Colors.white)),
                    onPressed: () => _triggerCommand(suggestion),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Keyboard fallback input bar
          TextField(
            style: const TextStyle(color: Colors.black87, fontFamily: 'serif'),
            decoration: InputDecoration(
              hintText: 'Type voice instruction / command...',
              suffixIcon: const Icon(Icons.keyboard_rounded, color: Colors.black45),
            ),
            onSubmitted: _triggerCommand,
          ),
        ],
      ),
    );
  }
}
