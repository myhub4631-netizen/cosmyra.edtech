import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/models.dart';
import '../../core/services/supabase_service.dart';
import '../../shared/widgets/app_avatar.dart';

class AdminLeaderboardScreen extends StatefulWidget {
  final UserProfileModel userProfile;

  const AdminLeaderboardScreen({Key? key, required this.userProfile}) : super(key: key);

  @override
  State<AdminLeaderboardScreen> createState() => _AdminLeaderboardScreenState();
}

class _AdminLeaderboardScreenState extends State<AdminLeaderboardScreen> {
  String _activeMode = 'real'; // 'real', 'custom', or 'demo'
  String _selectedExam = 'NEET UG 2027';
  String _selectedTestSeries = 'All Test Series';
  String _searchQuery = '';
  String _statusFilter = 'All'; // 'All', 'Verified', 'Flagged', 'Disqualified'
  String _selectedTimePeriod = 'all'; // 'all', 'daily', 'weekly', 'monthly'
  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _examOptions = [
    'NEET UG 2027',
    'NEET UG 2026',
    'JEE Main 2026',
    'JEE Advanced 2026',
    'All Exams'
  ];

  final List<String> _testSeriesOptions = [
    'All Test Series',
    'NEET 2027 Full Syllabus Test Series',
    'NEET Beginner Test Series',
    'JEE Main Full Syllabus Series',
    'Physics Booster Chapter Series',
  ];

  final Map<String, String> _timePeriodOptions = {
    'all': 'All Time',
    'daily': 'Daily (24h)',
    'weekly': 'Weekly (7d)',
    'monthly': 'Monthly (30d)',
  };

  List<Map<String, dynamic>> _leaderboardData = [];

  @override
  void initState() {
    super.initState();
    _loadLeaderboardSettings();
  }

  Future<void> _loadLeaderboardSettings() async {
    setState(() => _isLoading = true);
    try {
      final settings = await SupabaseService.getAdminLeaderboardSettings();
      final savedMode = settings['mode'] as String? ?? 'real';
      if (_activeMode.isEmpty) {
        _activeMode = (savedMode == 'real') ? 'real' : 'demo';
      }

      if (_activeMode == 'real') {
        final realResult = await SupabaseService.fetchRealLeaderboardRankings(
          exam: _selectedExam,
          isPointsMode: false,
          timePeriod: _selectedTimePeriod,
          forceRealtime: true,
        );
        final liveRankings = (realResult['rankings'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [];
        _leaderboardData = liveRankings;
      } else {
        final entries = settings['entries'] as List<Map<String, dynamic>>? ?? [];
        if (entries.isNotEmpty) {
          _leaderboardData = List<Map<String, dynamic>>.from(entries);
        } else {
          _leaderboardData = _getDefaultDemoLeaderboard();
        }
      }
    } catch (e) {
      debugPrint('Error loading admin leaderboard data: $e');
      if (_activeMode != 'real') {
        _leaderboardData = _getDefaultDemoLeaderboard();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getDefaultDemoLeaderboard() {
    return [
      {
        'rank': 1,
        'id': 'usr_admin_01',
        'name': 'Mahboob 1md Admin',
        'avatar': 'https://i.pravatar.cc/150?img=33',
        'score': 720,
        'max_score': 720,
        'accuracy': 99.5,
        'tests': 68,
        'points': 7200,
        'target': 'NEET 2027 Full Syllabus Test Series',
        'isVerified': true,
        'isFlagged': false,
        'isDisqualified': false,
        'is_current_user': true,
      },
      {
        'rank': 2,
        'id': 'usr_student_02',
        'name': 'Ninja Neet Jee',
        'avatar': 'https://i.pravatar.cc/150?img=47',
        'score': 715,
        'max_score': 720,
        'accuracy': 98.7,
        'tests': 54,
        'points': 7150,
        'target': 'NEET 2027 Full Syllabus Test Series',
        'isVerified': true,
        'isFlagged': false,
        'isDisqualified': false,
        'is_current_user': false,
      },
      {
        'rank': 3,
        'id': 'usr_student_03',
        'name': 'Abhishek Kumar',
        'avatar': 'https://i.pravatar.cc/150?img=12',
        'score': 710,
        'max_score': 720,
        'accuracy': 97.9,
        'tests': 62,
        'points': 7100,
        'target': 'NEET 2027 Full Syllabus Test Series',
        'isVerified': true,
        'isFlagged': false,
        'isDisqualified': false,
        'is_current_user': false,
      },
      {
        'rank': 4,
        'id': 'usr_student_04',
        'name': 'Earn Money Online',
        'avatar': 'https://i.pravatar.cc/150?img=24',
        'score': 705,
        'max_score': 720,
        'accuracy': 97.1,
        'tests': 49,
        'points': 7050,
        'target': 'NEET 2027 Full Syllabus Test Series',
        'isVerified': false,
        'isFlagged': false,
        'isDisqualified': false,
        'is_current_user': false,
      },
      {
        'rank': 5,
        'id': 'usr_student_05',
        'name': 'Mahboob Hasan',
        'avatar': 'https://i.pravatar.cc/150?img=60',
        'score': 695,
        'max_score': 720,
        'accuracy': 96.3,
        'tests': 58,
        'points': 6950,
        'target': 'NEET 2027 Full Syllabus Test Series',
        'isVerified': true,
        'isFlagged': false,
        'isDisqualified': false,
        'is_current_user': false,
      },
    ];
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    // Recalculate ranks based on score descending
    _leaderboardData.sort((a, b) => ((b['score'] as num?) ?? 0).compareTo((a['score'] as num?) ?? 0));
    for (int i = 0; i < _leaderboardData.length; i++) {
      _leaderboardData[i]['rank'] = i + 1;
    }

    await SupabaseService.saveAdminLeaderboardSettings(
      mode: _activeMode,
      entries: _leaderboardData,
    );
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Leaderboard configurations & entries updated live!'),
          backgroundColor: Color(0xFF059669),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _fetchLiveAttemptsFromSupabase() async {
    setState(() => _isLoading = true);
    try {
      final res = await SupabaseService.fetchRealLeaderboardRankings(
        exam: _selectedExam,
        isPointsMode: false,
        timePeriod: _selectedTimePeriod,
        forceRealtime: true,
      );
      final liveList = (res['rankings'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [];

      setState(() {
        _leaderboardData = liveList;
        _activeMode = 'real';
      });
      await _saveSettings();
    } catch (e) {
      debugPrint('Error fetching live attempts: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredEntries {
    return _leaderboardData.where((item) {
      final name = (item['name'] ?? '').toString().toLowerCase();
      final id = (item['id'] ?? '').toString().toLowerCase();
      final target = (item['target'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase().trim();

      bool matchesSearch = query.isEmpty || name.contains(query) || id.contains(query) || target.contains(query);

      bool matchesSeries = _selectedTestSeries == 'All Test Series' ||
          target.isEmpty ||
          target.contains(_selectedTestSeries.toLowerCase()) ||
          _selectedTestSeries.toLowerCase().contains(target);

      bool matchesStatus = true;
      if (_statusFilter == 'Verified') {
        matchesStatus = item['isVerified'] == true;
      } else if (_statusFilter == 'Flagged') {
        matchesStatus = item['isFlagged'] == true;
      } else if (_statusFilter == 'Disqualified') {
        matchesStatus = item['isDisqualified'] == true;
      }

      return matchesSearch && matchesSeries && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.emoji_events_rounded, color: Color(0xFF2563EB), size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Leaderboard Management',
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                ),
                Text(
                  'Manage Realtime and Marketing test series rankings',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh / Sync',
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF475569)),
            onPressed: _loadLeaderboardSettings,
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: _isSaving ? null : _saveSettings,
            icon: _isSaving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.save_rounded, size: 18),
            label: Text(_isSaving ? 'Saving...' : 'Save & Publish Live'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mode Selector Card
                  _buildModeSelectorCard(isDesktop),
                  const SizedBox(height: 20),

                  // Filter & Action Toolbar
                  _buildToolbarCard(isDesktop),
                  const SizedBox(height: 20),

                  // Leaderboard Entries Table
                  _buildLeaderboardTable(isDesktop),
                ],
              ),
            ),
    );
  }

  Widget _buildModeSelectorCard(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, color: Color(0xFF2563EB), size: 20),
              const SizedBox(width: 8),
              Text(
                'Active Leaderboard Display Mode',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _activeMode == 'real' ? const Color(0xFFDCFCE7) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Active: ${_activeMode == 'real' ? 'REALTIME' : 'MARKETING'} MODE',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _activeMode == 'real' ? const Color(0xFF15803D) : const Color(0xFF1D4ED8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 750) {
                return Row(
                  children: [
                    Expanded(
                      child: _buildModeOptionTile(
                        'real',
                        '1. Realtime Leaderboard',
                        'Shows only real students who either attempted tests in this series or platform and ranks them live accordingly.',
                        Icons.bolt_rounded,
                        const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildModeOptionTile(
                        'demo',
                        '2. Marketing Leaderboard',
                        'A leaderboard created by admin to showcase on new test series, so users can understand how it looks and details.',
                        Icons.campaign_rounded,
                        const Color(0xFF2563EB),
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildModeOptionTile(
                      'real',
                      '1. Realtime Leaderboard',
                      'Shows only real students who either attempted tests in this series or platform and ranks them live accordingly.',
                      Icons.bolt_rounded,
                      const Color(0xFF10B981),
                    ),
                    const SizedBox(height: 12),
                    _buildModeOptionTile(
                      'demo',
                      '2. Marketing Leaderboard',
                      'A leaderboard created by admin to showcase on new test series, so users can understand how it looks and details.',
                      Icons.campaign_rounded,
                      const Color(0xFF2563EB),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModeOptionTile(String mode, String title, String desc, IconData icon, Color activeColor) {
    final isSelected = _activeMode == mode;
    return InkWell(
      onTap: () async {
        setState(() => _activeMode = mode);
        await SupabaseService.saveAdminLeaderboardSettings(
          mode: mode,
          entries: _leaderboardData,
        );
        _loadLeaderboardSettings();
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.06) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFE2E8F0),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Radio<String>(
              value: mode,
              groupValue: _activeMode,
              activeColor: activeColor,
              onChanged: (val) {
                if (val != null) {
                  setState(() => _activeMode = val);
                  _saveSettings();
                }
              },
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 18, color: isSelected ? activeColor : const Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? activeColor : const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B), height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbarCard(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Search Input
              Expanded(
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search student name, ID, or test series...',
                    hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2563EB))),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Filter Status Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _statusFilter,
                    icon: const Icon(Icons.filter_list_rounded, size: 18, color: Color(0xFF64748B)),
                    items: ['All', 'Verified', 'Flagged', 'Disqualified'].map((s) {
                      return DropdownMenuItem(
                        value: s,
                        child: Text('Filter: $s', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _statusFilter = val);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Add Entry Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                onPressed: () => _showAddEditEntryDialog(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text('Add Entry', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Exam Filter Dropdown
              Text('Target Exam: ', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedExam,
                    items: _examOptions.map((e) => DropdownMenuItem(value: e, child: Text(e, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedExam = val);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Test Series Dropdown
              Text('Test Series: ', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedTestSeries,
                    items: _testSeriesOptions.map((e) => DropdownMenuItem(value: e, child: Text(e, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedTestSeries = val);
                        _loadLeaderboardSettings();
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Time Period Dropdown (Daily, Weekly, Monthly, All Time)
              Text('Period: ', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFC7D2FE)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedTimePeriod,
                    icon: const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF4F46E5)),
                    items: _timePeriodOptions.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF4338CA))))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedTimePeriod = val);
                        _loadLeaderboardSettings();
                      }
                    },
                  ),
                ),
              ),
              const Spacer(),

              // Quick Action: Fetch Live Attempts
              TextButton.icon(
                onPressed: _fetchLiveAttemptsFromSupabase,
                icon: const Icon(Icons.cloud_download_rounded, size: 16, color: Color(0xFF2563EB)),
                label: Text('Fetch Live Attempts', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF2563EB))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTable(bool isDesktop) {
    final entries = _filteredEntries;

    if (entries.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            const Icon(Icons.emoji_events_outlined, size: 48, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              'No Leaderboard Entries Found',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF334155)),
            ),
            const SizedBox(height: 6),
            Text(
              'Try changing your search query or filter options, or click "Add Entry" to create one.',
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                const SizedBox(width: 44, child: Text('Rank', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                const Expanded(flex: 3, child: Text('Student Name & ID', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                const Expanded(flex: 3, child: Text('Test Series / Target Exam', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                const SizedBox(width: 90, child: Text('Score', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                const SizedBox(width: 100, child: Text('Points (10/Q)', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                const SizedBox(width: 80, child: Text('Accuracy', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                const SizedBox(width: 100, child: Text('Status', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                const SizedBox(width: 120, child: Text('Actions', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
              ],
            ),
          ),

          // Table Body List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
            itemBuilder: (context, index) {
              final item = entries[index];
              final rank = item['rank'] ?? (index + 1);
              final name = (item['name'] ?? 'Aspirant').toString();
              final avatarUrl = item['avatar']?.toString();
              final sId = item['id']?.toString() ?? '';
              final score = item['score'] ?? 0;
              final maxScore = item['max_score'] ?? 720;
              final correctCount = (item['correct_count'] is num) ? (item['correct_count'] as num).toInt() : (score ~/ 4);
              final points = (item['points'] is num) ? (item['points'] as num).toInt() : (correctCount * 10);
              final accuracy = item['accuracy'] ?? 85.0;
              final target = (item['target'] ?? 'NEET UG').toString();
              final isVerified = item['isVerified'] == true;
              final isFlagged = item['isFlagged'] == true;
              final isDisqualified = item['isDisqualified'] == true;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: isDisqualified
                    ? const Color(0xFFFEF2F2)
                    : (isFlagged ? const Color(0xFFFFFBEB) : (rank == 1 ? const Color(0xFFFFFDF5) : Colors.white)),
                child: Row(
                  children: [
                    // Rank Badge
                    SizedBox(
                      width: 44,
                      child: Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: rank == 1
                              ? const Color(0xFFFEF3C7)
                              : (rank == 2 ? const Color(0xFFF1F5F9) : (rank == 3 ? const Color(0xFFFFF7ED) : const Color(0xFFF8FAFC))),
                          border: Border.all(
                            color: rank == 1
                                ? const Color(0xFFFDE68A)
                                : (rank == 2 ? const Color(0xFFCBD5E1) : (rank == 3 ? const Color(0xFFFFEDD5) : const Color(0xFFE2E8F0))),
                          ),
                        ),
                        child: Text(
                          '#$rank',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: rank == 1
                                ? const Color(0xFFD97706)
                                : (rank == 2 ? const Color(0xFF475569) : (rank == 3 ? const Color(0xFFC2410C) : const Color(0xFF64748B))),
                          ),
                        ),
                      ),
                    ),

                    // Student Name & Avatar
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          AppAvatar(
                            avatarUrl: avatarUrl,
                            name: name,
                            size: 34,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        name,
                                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isVerified) ...[
                                      const SizedBox(width: 4),
                                      const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF2563EB)),
                                    ],
                                  ],
                                ),
                                Text(
                                  sId.isNotEmpty ? 'ID: $sId' : 'Registered Student',
                                  style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Test Series / Target
                    Expanded(
                      flex: 3,
                      child: Text(
                        target,
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Score
                    SizedBox(
                      width: 90,
                      child: Text(
                        '$score / $maxScore',
                        textAlign: TextAlign.right,
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w900, color: const Color(0xFF059669)),
                      ),
                    ),

                    // Total Points (10 points per correct question)
                    SizedBox(
                      width: 100,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$points Pts',
                            textAlign: TextAlign.right,
                            style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w800, color: const Color(0xFF2563EB)),
                          ),
                          Text(
                            '$correctCount Correct',
                            textAlign: TextAlign.right,
                            style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),

                    // Accuracy
                    SizedBox(
                      width: 80,
                      child: Text(
                        '${accuracy.toStringAsFixed(1)}%',
                        textAlign: TextAlign.right,
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF475569)),
                      ),
                    ),

                    // Status Pill
                    SizedBox(
                      width: 100,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDisqualified
                                ? const Color(0xFFFEE2E2)
                                : (isFlagged ? const Color(0xFFFEF3C7) : (isVerified ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9))),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isDisqualified
                                ? 'Disqualified'
                                : (isFlagged ? 'Suspected' : (isVerified ? 'Verified' : 'Standard')),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: isDisqualified
                                  ? const Color(0xFFB91C1C)
                                  : (isFlagged ? const Color(0xFFB45309) : (isVerified ? const Color(0xFF15803D) : const Color(0xFF475569))),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Actions
                    SizedBox(
                      width: 120,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            tooltip: 'Edit Entry & Marks',
                            icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF2563EB)),
                            onPressed: () => _showAddEditEntryDialog(context, item, index),
                          ),
                          IconButton(
                            tooltip: isFlagged ? 'Unflag Score' : 'Flag Cheating / Suspect',
                            icon: Icon(
                              isFlagged ? Icons.warning_amber_rounded : Icons.outlined_flag_rounded,
                              size: 18,
                              color: isFlagged ? const Color(0xFFD97706) : const Color(0xFF64748B),
                            ),
                            onPressed: () {
                              setState(() {
                                item['isFlagged'] = !isFlagged;
                              });
                              _saveSettings();
                            },
                          ),
                          IconButton(
                            tooltip: 'Delete Entry',
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                            onPressed: () {
                              setState(() {
                                _leaderboardData.remove(item);
                              });
                              _saveSettings();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAddEditEntryDialog(BuildContext context, [Map<String, dynamic>? existingItem, int? editIndex]) {
    final nameCtrl = TextEditingController(text: existingItem?['name'] ?? '');
    final idCtrl = TextEditingController(text: existingItem?['id'] ?? 'usr_${DateTime.now().millisecondsSinceEpoch}');
    final avatarCtrl = TextEditingController(text: existingItem?['avatar'] ?? '');
    final scoreCtrl = TextEditingController(text: (existingItem?['score'] ?? 720).toString());
    final maxScoreCtrl = TextEditingController(text: (existingItem?['max_score'] ?? 720).toString());
    final accuracyCtrl = TextEditingController(text: (existingItem?['accuracy'] ?? 98.5).toString());
    final testsCtrl = TextEditingController(text: (existingItem?['tests'] ?? 15).toString());

    String targetExam = existingItem?['target'] ?? _selectedTestSeries;
    bool isVerified = existingItem?['isVerified'] ?? true;
    bool isFlagged = existingItem?['isFlagged'] ?? false;
    bool isDisqualified = existingItem?['isDisqualified'] ?? false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.emoji_events_rounded, color: Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  Text(
                    existingItem != null ? 'Edit Leaderboard Entry' : 'Add New Leaderboard Entry',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 480,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Student Name
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Student Full Name', hintText: 'e.g. Mahboob Hasan'),
                      ),
                      const SizedBox(height: 12),

                      // Student ID / Email
                      TextField(
                        controller: idCtrl,
                        decoration: const InputDecoration(labelText: 'Student ID / Reg Number', hintText: 'e.g. 230145'),
                      ),
                      const SizedBox(height: 12),

                      // Avatar URL
                      TextField(
                        controller: avatarCtrl,
                        onChanged: (_) => setDialogState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Profile Picture / Avatar Image URL',
                          hintText: 'https://lh3.googleusercontent.com/... or Base64',
                        ),
                      ),
                      if (avatarCtrl.text.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Preview: ', style: TextStyle(fontSize: 12)),
                            AppAvatar(avatarUrl: avatarCtrl.text, name: nameCtrl.text.isNotEmpty ? nameCtrl.text : 'User', size: 36),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),

                      // Test Series / Target Exam
                      DropdownButtonFormField<String>(
                        value: _testSeriesOptions.contains(targetExam) ? targetExam : _testSeriesOptions.first,
                        decoration: const InputDecoration(labelText: 'Test Series / Exam Scope'),
                        items: _testSeriesOptions.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => targetExam = val);
                        },
                      ),
                      const SizedBox(height: 12),

                      // Score & Max Marks
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: scoreCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Total Score Marks'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: maxScoreCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Max Marks'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Accuracy & Tests
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: accuracyCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Accuracy %'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: testsCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Tests Attempted'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Status Switches
                      SwitchListTile(
                        title: const Text('Verified Top Ranker (Badge 👑)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        value: isVerified,
                        activeColor: const Color(0xFF059669),
                        onChanged: (val) => setDialogState(() => isVerified = val),
                      ),
                      SwitchListTile(
                        title: const Text('Flag Suspicious / Anti-Cheating (⚠️)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        value: isFlagged,
                        activeColor: const Color(0xFFD97706),
                        onChanged: (val) => setDialogState(() => isFlagged = val),
                      ),
                      SwitchListTile(
                        title: const Text('Disqualify Student (🚫)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        value: isDisqualified,
                        activeColor: const Color(0xFFDC2626),
                        onChanged: (val) => setDialogState(() => isDisqualified = val),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    final scoreVal = int.tryParse(scoreCtrl.text.trim()) ?? 720;
                    final maxVal = int.tryParse(maxScoreCtrl.text.trim()) ?? 720;
                    final accuracyVal = double.tryParse(accuracyCtrl.text.trim()) ?? 98.5;
                    final testsVal = int.tryParse(testsCtrl.text.trim()) ?? 15;

                    final newItem = {
                      'id': idCtrl.text.trim(),
                      'name': nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : 'Aspirant',
                      'avatar': avatarCtrl.text.trim(),
                      'score': scoreVal,
                      'max_score': maxVal,
                      'accuracy': accuracyVal,
                      'tests': testsVal,
                      'points': scoreVal * 10,
                      'target': targetExam,
                      'isVerified': isVerified,
                      'isFlagged': isFlagged,
                      'isDisqualified': isDisqualified,
                    };

                    setState(() {
                      if (existingItem != null) {
                        existingItem.addAll(newItem);
                      } else {
                        _leaderboardData.add(newItem);
                      }
                    });

                    _saveSettings();
                    Navigator.pop(ctx);
                  },
                  child: Text(existingItem != null ? 'Update Entry' : 'Add Entry'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
