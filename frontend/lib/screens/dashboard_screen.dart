import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../models/user_profile.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedTabIndex = 0; // 0: Home, 1: Resources, 2: Chat, 3: Profile
  late UserProfile _profile;
  Map<String, dynamic>? _matchedData;
  bool _isInitialized = false;

  // AI Assistant Chat State
  final List<Map<String, String>> _chatMessages = [];
  final TextEditingController _chatController = TextEditingController();
  bool _isChatLoading = false;

  // Action Plan Checklist State (local state copy of tasks)
  List<Map<String, dynamic>> _actionTasks = [];

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

      // Initialize action plan checklist from matched data
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

      // Default AI message
      _chatMessages.add({
        "sender": "ai",
        "text": "Hello! I am your Neuro Guard Assistant. I've configured my responses with your profile (${_profile.name}, Sensory sensitivity: ${_profile.sensorySensitivity}). You can ask me details about the Niramaya Health Insurance Scheme, local state benefits, or how to seek accommodations."
      });

      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  // AI Chat Request
  Future<void> _sendChatMessage() async {
    final query = _chatController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _chatMessages.add({"sender": "user", "text": query});
      _chatController.clear();
      _isChatLoading = true;
    });

    String baseUrl = "http://localhost:5000";
    if (!kIsWeb && Theme.of(context).platform == TargetPlatform.android) {
      baseUrl = "http://10.0.2.2:5000";
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': query,
          'profile': _profile.toJson()
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        setState(() {
          _chatMessages.add({"sender": "ai", "text": body['reply'] ?? "I didn't understand that."});
        });
      } else {
        setState(() {
          _chatMessages.add({"sender": "ai", "text": "Error communicating with intelligence server."});
        });
      }
    } catch (e) {
      setState(() {
        _chatMessages.add({"sender": "ai", "text": "Connection to AI server was lost. Please verify backend is running."});
      });
    } finally {
      setState(() {
        _isChatLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: CosmicTheme.cosmicGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Dashboard Header
              _buildDashboardHeader(),
              
              // Dynamic Body depending on tab selection
              Expanded(
                child: _buildTabContent(),
              ),

              // Amber-highlighted Responsible AI disclosure notice badge
              if (_selectedTabIndex == 0 || _selectedTabIndex == 2)
                _buildAIDisclosureBadge(),

              // Fixed dark bottom navigation dock
              _buildBottomNavigationDock(),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Component Builders ---

  Widget _buildDashboardHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello ${_profile.name.isNotEmpty ? _profile.name : 'User'} 👋',
                style: GoogleFonts.italiana(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _profile.role == 'Caregiver' ? 'Caregiver Dashboard' : 'Self Assessment Plan',
                style: const TextStyle(
                  fontFamily: 'serif',
                  color: Colors.white60,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          
          // Notification shortcuts
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 28),
                onPressed: () {
                  // Show mock notification dialog
                  _showMockNotifications();
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: CosmicTheme.accentAmber,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 10,
                    minHeight: 10,
                  ),
                ),
              )
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
        return _buildResourcesTab();
      case 2:
        return _buildChatTab();
      case 3:
        return _buildProfileTab();
      default:
        return _buildHomeTab();
    }
  }

  // --- TAB 0: Home Dashboard ---
  Widget _buildHomeTab() {
    // Collect customized resources (filtered by sensory levels)
    final listResources = _matchedData != null && _matchedData!['resources'] != null
        ? (_matchedData!['resources'] as List)
        : [];
        
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          
          // 4-Quadrant Grid Card Section
          Text(
            'Essential Tools',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 12),
          _build4QuadrantGrid(),
          
          const SizedBox(height: 28),
          
          // Sensory-Aligned Resources Feed Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Prioritized Accommodations',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: CosmicTheme.accentTeal.withOpacity(0.15),
                  border: Border.all(color: CosmicTheme.accentTeal.withOpacity(0.4)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Sensory: ${_profile.sensorySensitivity}',
                  style: const TextStyle(
                    color: CosmicTheme.accentTeal,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Dynamic feed
          if (listResources.isEmpty)
            _buildFallbackResourceCard()
          else
            ...listResources.map((res) {
              return _buildResourceFeedCard(
                title: res['title'] ?? 'Accommodation Scheme',
                type: res['type'] ?? 'Support',
                desc: res['description'] ?? '',
                category: res['category'] ?? 'General',
              );
            }).toList(),
            
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _build4QuadrantGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.35,
      children: [
        _buildGridButton(
          title: 'Eligibility',
          icon: Icons.assignment_turned_in_rounded,
          color: const Color(0xFF4A90E2),
          onTap: () => setState(() => _selectedTabIndex = 1),
        ),
        _buildGridButton(
          title: 'Resources',
          icon: Icons.bubble_chart_rounded,
          color: CosmicTheme.accentTeal,
          onTap: () => setState(() => _selectedTabIndex = 1),
        ),
        _buildGridButton(
          title: 'Action Plan',
          icon: Icons.checklist_rtl_rounded,
          color: CosmicTheme.accentAmber,
          onTap: () => _showActionPlanModal(),
        ),
        _buildGridButton(
          title: 'AI Assistant',
          icon: Icons.forum_rounded,
          color: const Color(0xFF9B59B6),
          onTap: () => setState(() => _selectedTabIndex = 2),
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
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: CosmicTheme.cardForeground.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 28),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'serif',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResourceFeedCard({
    required String title,
    required String type,
    required String desc,
    required String category,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        border: Border.all(color: Colors.white10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: CosmicTheme.accentTeal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    category.toUpperCase(),
                    style: const TextStyle(
                      color: CosmicTheme.accentTeal,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  type,
                  style: const TextStyle(color: Colors.white38, fontSize: 11, fontFamily: 'serif'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
                fontFamily: 'serif',
              ),
            ),
            const SizedBox(height: 6),
            Text(
              desc,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.3,
                fontFamily: 'serif',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackResourceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: const [
          Icon(Icons.spa_outlined, color: Colors.white30, size: 40),
          SizedBox(height: 8),
          Text(
            'No matching resources found. Review your filters in the Profile tab.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontFamily: 'serif'),
          )
        ],
      ),
    );
  }

  // --- TAB 1: Resources & Benefits ---
  Widget _buildResourcesTab() {
    final listBenefits = _matchedData != null && _matchedData!['benefits'] != null
        ? (_matchedData!['benefits'] as List)
        : [];
    final listResources = _matchedData != null && _matchedData!['resources'] != null
        ? (_matchedData!['resources'] as List)
        : [];

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            indicatorColor: CosmicTheme.accentTeal,
            tabs: [
              Tab(text: 'Government Schemes'),
              Tab(text: 'Accommodations'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Subtab 1: Schemes
                ListView.builder(
                  padding: const EdgeInsets.all(24.0),
                  itemCount: listBenefits.length,
                  itemBuilder: (ctx, index) {
                    final item = listBenefits[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: CosmicTheme.cardForeground,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))],
                      ),
                      padding: const EdgeInsets.all(20),
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
                                style: const TextStyle(color: Colors.black45, fontSize: 11, fontWeight: FontWeight.bold),
                              )
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            item['title'] ?? '',
                            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'serif'),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item['description'] ?? '',
                            style: const TextStyle(color: Colors.black54, fontSize: 13, height: 1.3, fontFamily: 'serif'),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Subtab 2: Accommodations
                ListView.builder(
                  padding: const EdgeInsets.all(24.0),
                  itemCount: listResources.length,
                  itemBuilder: (ctx, index) {
                    final item = listResources[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        border: Border.all(color: Colors.white10),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                (item['category'] ?? 'Support').toString().toUpperCase(),
                                style: const TextStyle(color: CosmicTheme.accentTeal, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                              Text(
                                item['type'] ?? '',
                                style: const TextStyle(color: Colors.white38, fontSize: 11, fontFamily: 'serif'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            item['title'] ?? '',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'serif'),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item['description'] ?? '',
                            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.3, fontFamily: 'serif'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 2: Chat Workspace ---
  Widget _buildChatTab() {
    return Column(
      children: [
        // Dialogue Stream
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _chatMessages.length,
            itemBuilder: (ctx, index) {
              final msg = _chatMessages[index];
              final isAi = msg['sender'] == 'ai';
              return Align(
                alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                  decoration: BoxDecoration(
                    color: isAi ? CosmicTheme.cardForeground : CosmicTheme.accentTeal.withOpacity(0.2),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isAi ? Radius.zero : const Radius.circular(16),
                      bottomRight: isAi ? const Radius.circular(16) : Radius.zero,
                    ),
                  ),
                  child: Text(
                    msg['text'] ?? '',
                    style: TextStyle(
                      color: isAi ? Colors.black87 : Colors.white,
                      fontSize: 14,
                      height: 1.3,
                      fontFamily: 'serif',
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        if (_isChatLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(CosmicTheme.accentTeal)),
            ),
          ),

        // Text Input Bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.black26,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  style: const TextStyle(color: Colors.black87, fontFamily: 'serif'),
                  decoration: const InputDecoration(
                    hintText: 'Ask about Niramaya or sensory plans...',
                  ),
                  onSubmitted: (_) => _sendChatMessage(),
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                backgroundColor: CosmicTheme.accentTeal,
                child: IconButton(
                  icon: const Icon(Icons.send_rounded, color: Colors.white),
                  onPressed: _sendChatMessage,
                ),
              )
            ],
          ),
        )
      ],
    );
  }

  // --- TAB 3: Profile Summary ---
  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              border: Border.all(color: Colors.white10),
              borderRadius: BorderRadius.circular(20),
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
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    _profile.name,
                    style: GoogleFonts.italiana(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                Center(
                  child: Text(
                    'Role: ${_profile.role}',
                    style: const TextStyle(color: Colors.white54, fontFamily: 'serif'),
                  ),
                ),
                const Divider(height: 32, color: Colors.white12),
                
                _buildProfileRow('Age', _profile.age),
                _buildProfileRow('Autism Status', _profile.autismStatus),
                _buildProfileRow('State & Zip', '${_profile.state} (Pincode: ${_profile.pincode})'),
                _buildProfileRow('Certificate', _profile.disabilityCertificate),
                _buildProfileRow('Sensory Threshold', _profile.sensorySensitivity),
                _buildProfileRow('Primary Comms', _profile.communicationMethod),
                _buildProfileRow('Income Bracket', _profile.incomeRange),
                _buildProfileRow('Insurance Opt-in', _profile.insuranceNiramaya ? 'Niramaya Scheme Selected' : 'Standard'),
              ],
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.8), foregroundColor: Colors.white),
            onPressed: () {
              // Reroute back to Role Selection Screen
              Navigator.pushNamedAndRemoveUntil(context, '/role-selection', (route) => false);
            },
            child: const Text('RESET CONFIGURATION ENGINE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
          )
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontFamily: 'serif')),
          Text(value, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontFamily: 'serif')),
        ],
      ),
    );
  }

  // --- ACTION PLAN MODAL SYSTEM ---
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
                  // Modal drag indicator
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
                        Text('Action Plan Roadmap', style: GoogleFonts.italiana(fontSize: 22, fontWeight: FontWeight.bold)),
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
                      padding: const EdgeInsets.all(24),
                      itemCount: _actionTasks.length,
                      itemBuilder: (c, idx) {
                        final task = _actionTasks[idx];
                        final isCompleted = task['status'] == 'completed';
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
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
                              // Update modal AND local class state
                              setModalState(() {
                                _actionTasks[idx]['status'] = val! ? 'completed' : 'pending';
                              });
                              setState(() {
                                _actionTasks[idx]['status'] = val! ? 'completed' : 'pending';
                              });
                            },
                            title: Text(
                              task['task'] ?? '',
                              style: TextStyle(
                                decoration: isCompleted ? TextDecoration.lineThrough : null,
                                color: isCompleted ? Colors.white30 : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'serif',
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                task['details'] ?? '',
                                style: TextStyle(
                                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                                  color: isCompleted ? Colors.white24 : Colors.white60,
                                  fontSize: 12,
                                  fontFamily: 'serif',
                                ),
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

  // --- SUB UI ELEMENTS ---

  Widget _buildAIDisclosureBadge() {
    return Container(
      width: double.infinity,
      color: CosmicTheme.accentAmber.withOpacity(0.15),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.info_outline_rounded, color: CosmicTheme.accentAmber, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Responsible AI: Chat and accommodations are recommendations. Consult authorities or medical boards for official verifications.',
              style: TextStyle(color: CosmicTheme.accentAmber, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'serif'),
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
      backgroundColor: const Color(0xFF1B1D22), // Muted dark base bottom bar
      selectedItemColor: CosmicTheme.accentTeal,
      unselectedItemColor: Colors.white30,
      selectedLabelStyle: const TextStyle(fontFamily: 'serif', fontWeight: FontWeight.bold),
      unselectedLabelStyle: const TextStyle(fontFamily: 'serif'),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.assignment_rounded), label: 'Resources'),
        BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: 'Chat'),
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
            Text(
              '• Niramaya scheme claims portal updated for 2026.',
              style: TextStyle(color: Colors.white70, fontSize: 14, fontFamily: 'serif'),
            ),
            SizedBox(height: 10),
            Text(
              '• Sensory adjustments active for your user profile.',
              style: TextStyle(color: Colors.white70, fontSize: 14, fontFamily: 'serif'),
            ),
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
