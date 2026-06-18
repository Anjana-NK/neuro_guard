import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../models/user_profile.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> _historyList = [];
  bool _isLoading = true;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    String baseUrl = "http://localhost:5000";
    if (!kIsWeb && Theme.of(context).platform == TargetPlatform.android) {
      baseUrl = "http://10.0.2.2:5000";
    }

    try {
      final response = await http.get(Uri.parse('$baseUrl/api/history'));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        setState(() {
          _historyList = body['history'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Server returned error: ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to connect to history server.";
        _isLoading = false;
      });
    }
  }

  void _reloadSession(Map<String, dynamic> item) {
    // Reconstruct UserProfile from dynamic map
    final pData = item['profile'] ?? {};
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
      ..insuranceNiramaya = pData['insuranceNiramaya'] ?? false;

    final matchedData = item['result'] ?? {};

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: CosmicTheme.gradientTop,
        title: Text('Assessment History', style: GoogleFonts.italiana(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: CosmicTheme.cosmicGradient),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(CosmicTheme.accentTeal)))
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                          const SizedBox(height: 12),
                          Text(_errorMessage, style: const TextStyle(color: Colors.white70, fontFamily: 'serif')),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isLoading = true;
                                _errorMessage = "";
                              });
                              _fetchHistory();
                            },
                            child: const Text('RETRY'),
                          )
                        ],
                      ),
                    ),
                  )
                : _historyList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.history_toggle_off_rounded, color: Colors.white30, size: 64),
                            const SizedBox(height: 16),
                            const Text(
                              'No past assessments found in Firestore.',
                              style: TextStyle(color: Colors.white54, fontSize: 16, fontFamily: 'serif'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _historyList.length,
                        itemBuilder: (ctx, index) {
                          final item = _historyList[index];
                          final prof = item['profile'] ?? {};
                          final name = prof['name'] ?? 'User';
                          final role = prof['role'] ?? 'Self';
                          final state = prof['state'] ?? 'Kerala';
                          final dateText = item['timestamp'] != null
                              ? "Session ${item['timestamp']}"
                              : "Saved Session #${index + 1}";

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              border: Border.all(color: Colors.white12),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              title: Text(
                                name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white, fontFamily: 'serif'),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'Role: $role | Location: $state\n$dateText',
                                  style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.3, fontFamily: 'serif'),
                                ),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios_rounded, color: CosmicTheme.accentTeal, size: 18),
                              onTap: () => _reloadSession(item),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
