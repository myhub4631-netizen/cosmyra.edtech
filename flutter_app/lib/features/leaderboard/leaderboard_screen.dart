import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../core/services/supabase_service.dart';

enum LeaderboardExam { neet, jeeMain, jeeAdvanced }
enum LeaderboardTimeframe { today, thisWeek, thisMonth, allTime }
enum LeaderboardScope { allIndia, myCity, myState, myCoaching }
enum LeaderboardMainTab { overall, myRank, friends }

class LeaderboardStudent {
  final int rank;
  final String name;
  final String coaching;
  final String avatarUrl;
  final int score;
  final int maxScore;
  final double percentile;
  final double accuracy;
  final int questionsAttempted;
  final int rankChange; // +112, -5, etc.
  final bool isCrownWinner;
  final String crownType; // gold, silver, bronze, none
  final bool isCurrentUser;

  LeaderboardStudent({
    required this.rank,
    required this.name,
    required this.coaching,
    required this.avatarUrl,
    required this.score,
    required this.maxScore,
    required this.percentile,
    required this.accuracy,
    required this.questionsAttempted,
    required this.rankChange,
    this.isCrownWinner = false,
    this.crownType = 'none',
    this.isCurrentUser = false,
  });
}

class LeaderboardScreen extends StatefulWidget {
  final UserProfileModel? userProfile;
  final String? initialExam;
  final VoidCallback? onBack;

  const LeaderboardScreen({
    Key? key,
    this.userProfile,
    this.initialExam,
    this.onBack,
  }) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late LeaderboardExam _selectedExam;
  LeaderboardTimeframe _selectedTimeframe = LeaderboardTimeframe.thisWeek;
  LeaderboardScope _selectedScope = LeaderboardScope.allIndia;
  LeaderboardMainTab _selectedTab = LeaderboardMainTab.overall;
  String _selectedCategory = 'All Categories';

  bool _isLoading = false;
  List<LeaderboardStudent> _students = [];
  LeaderboardStudent? _currentUserData;

  @override
  void initState() {
    super.initState();
    final examStr = widget.initialExam?.toUpperCase() ?? 'JEE MAIN';
    if (examStr.contains('NEET')) {
      _selectedExam = LeaderboardExam.neet;
    } else if (examStr.contains('ADVANCED')) {
      _selectedExam = LeaderboardExam.jeeAdvanced;
    } else {
      _selectedExam = LeaderboardExam.jeeMain;
    }

    _loadLeaderboardData();
  }

  void _loadLeaderboardData() {
    setState(() => _isLoading = true);

    // Realistic Mock Data for NEET, JEE Main, and JEE Advanced
    Future.delayed(const Duration(milliseconds: 200), () {
      int maxScore = _selectedExam == LeaderboardExam.neet ? 720 : (_selectedExam == LeaderboardExam.jeeAdvanced ? 360 : 300);
      
      List<LeaderboardStudent> mockList = [];
      if (_selectedExam == LeaderboardExam.neet) {
        mockList = [
          LeaderboardStudent(rank: 1, name: 'Aarav Sharma', coaching: 'Vibrant Academy', avatarUrl: 'https://i.pravatar.cc/150?img=11', score: 715, maxScore: 720, percentile: 99.99, accuracy: 99.2, questionsAttempted: 180, rankChange: 0, isCrownWinner: true, crownType: 'gold'),
          LeaderboardStudent(rank: 2, name: 'Rohit Verma', coaching: 'Resonance Kota', avatarUrl: 'https://i.pravatar.cc/150?img=12', score: 710, maxScore: 720, percentile: 99.97, accuracy: 98.6, questionsAttempted: 180, rankChange: 2, isCrownWinner: true, crownType: 'silver'),
          LeaderboardStudent(rank: 3, name: 'Isha Singh', coaching: 'Allen Career Institute', avatarUrl: 'https://i.pravatar.cc/150?img=25', score: 705, maxScore: 720, percentile: 99.95, accuracy: 98.0, questionsAttempted: 178, rankChange: -1, isCrownWinner: true, crownType: 'bronze'),
          LeaderboardStudent(rank: 4, name: 'Vedant Gupta', coaching: 'Aakash Institute', avatarUrl: 'https://i.pravatar.cc/150?img=33', score: 700, maxScore: 720, percentile: 99.92, accuracy: 97.4, questionsAttempted: 176, rankChange: 4),
          LeaderboardStudent(rank: 5, name: 'Ananya Reddy', coaching: 'Narayana Academy', avatarUrl: 'https://i.pravatar.cc/150?img=47', score: 695, maxScore: 720, percentile: 99.90, accuracy: 96.8, questionsAttempted: 175, rankChange: 1),
        ];
        _currentUserData = LeaderboardStudent(
          rank: 142,
          name: widget.userProfile?.fullName ?? 'You',
          coaching: 'Cosmyra Student',
          avatarUrl: widget.userProfile?.avatarUrl ?? 'https://i.pravatar.cc/150?img=60',
          score: 612,
          maxScore: 720,
          percentile: 98.89,
          accuracy: 85.0,
          questionsAttempted: 162,
          rankChange: 112,
          isCurrentUser: true,
        );
      } else if (_selectedExam == LeaderboardExam.jeeAdvanced) {
        mockList = [
          LeaderboardStudent(rank: 1, name: 'Aarav Sharma', coaching: 'Vibrant Academy', avatarUrl: 'https://i.pravatar.cc/150?img=11', score: 325, maxScore: 360, percentile: 99.99, accuracy: 94.2, questionsAttempted: 90, rankChange: 0, isCrownWinner: true, crownType: 'gold'),
          LeaderboardStudent(rank: 2, name: 'Rohit Verma', coaching: 'Resonance Kota', avatarUrl: 'https://i.pravatar.cc/150?img=12', score: 318, maxScore: 360, percentile: 99.97, accuracy: 92.6, questionsAttempted: 88, rankChange: 1, isCrownWinner: true, crownType: 'silver'),
          LeaderboardStudent(rank: 3, name: 'Isha Singh', coaching: 'Allen Career Institute', avatarUrl: 'https://i.pravatar.cc/150?img=25', score: 310, maxScore: 360, percentile: 99.95, accuracy: 91.0, questionsAttempted: 86, rankChange: -1, isCrownWinner: true, crownType: 'bronze'),
          LeaderboardStudent(rank: 4, name: 'Vedant Gupta', coaching: 'Aakash Institute', avatarUrl: 'https://i.pravatar.cc/150?img=33', score: 302, maxScore: 360, percentile: 99.92, accuracy: 89.4, questionsAttempted: 84, rankChange: 2),
          LeaderboardStudent(rank: 5, name: 'Ananya Reddy', coaching: 'Narayana Academy', avatarUrl: 'https://i.pravatar.cc/150?img=47', score: 295, maxScore: 360, percentile: 99.90, accuracy: 88.8, questionsAttempted: 82, rankChange: 3),
        ];
        _currentUserData = LeaderboardStudent(
          rank: 142,
          name: widget.userProfile?.fullName ?? 'You',
          coaching: 'Cosmyra Student',
          avatarUrl: widget.userProfile?.avatarUrl ?? 'https://i.pravatar.cc/150?img=60',
          score: 215,
          maxScore: 360,
          percentile: 98.89,
          accuracy: 78.5,
          questionsAttempted: 74,
          rankChange: 112,
          isCurrentUser: true,
        );
      } else {
        // JEE Main (Matches reference image)
        mockList = [
          LeaderboardStudent(rank: 1, name: 'Aarav Sharma', coaching: 'Vibrant Academy', avatarUrl: 'https://i.pravatar.cc/150?img=11', score: 285, maxScore: 300, percentile: 99.99, accuracy: 95.0, questionsAttempted: 75, rankChange: 0, isCrownWinner: true, crownType: 'gold'),
          LeaderboardStudent(rank: 2, name: 'Rohit Verma', coaching: 'Resonance Kota', avatarUrl: 'https://i.pravatar.cc/150?img=12', score: 282, maxScore: 300, percentile: 99.97, accuracy: 94.0, questionsAttempted: 75, rankChange: 2, isCrownWinner: true, crownType: 'silver'),
          LeaderboardStudent(rank: 3, name: 'Isha Singh', coaching: 'Allen Career Institute', avatarUrl: 'https://i.pravatar.cc/150?img=25', score: 278, maxScore: 300, percentile: 99.95, accuracy: 92.6, questionsAttempted: 74, rankChange: -1, isCrownWinner: true, crownType: 'bronze'),
          LeaderboardStudent(rank: 4, name: 'Vedant Gupta', coaching: 'Aakash Institute', avatarUrl: 'https://i.pravatar.cc/150?img=33', score: 276, maxScore: 300, percentile: 99.92, accuracy: 92.0, questionsAttempted: 74, rankChange: 3),
          LeaderboardStudent(rank: 5, name: 'Ananya Reddy', coaching: 'Narayana Academy', avatarUrl: 'https://i.pravatar.cc/150?img=47', score: 274, maxScore: 300, percentile: 99.90, accuracy: 91.3, questionsAttempted: 73, rankChange: 1),
        ];
        _currentUserData = LeaderboardStudent(
          rank: 142,
          name: widget.userProfile?.fullName ?? 'You',
          coaching: 'Cosmyra Student',
          avatarUrl: widget.userProfile?.avatarUrl ?? 'https://i.pravatar.cc/150?img=60',
          score: 208,
          maxScore: 300,
          percentile: 98.89,
          accuracy: 78.0,
          questionsAttempted: 68,
          rankChange: 112,
          isCurrentUser: true,
        );
      }

      if (mounted) {
        setState(() {
          _students = mockList;
          _isLoading = false;
        });
      }
    });
  }

  String get _examTitle {
    switch (_selectedExam) {
      case LeaderboardExam.neet:
        return 'NEET Full Length Test - 01';
      case LeaderboardExam.jeeAdvanced:
        return 'JEE Advanced Mock Test - 03';
      case LeaderboardExam.jeeMain:
      default:
        return 'JEE Main Full Test - 05';
    }
  }

  int get _examMaxMarks {
    switch (_selectedExam) {
      case LeaderboardExam.neet:
        return 720;
      case LeaderboardExam.jeeAdvanced:
        return 360;
      case LeaderboardExam.jeeMain:
      default:
        return 300;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. HEADER BAR
                  _buildHeaderBar(context),

                  const SizedBox(height: 20),

                  // 2. EXAM SELECTOR + TIME FILTER TABS
                  _buildTopControlBar(),

                  const SizedBox(height: 16),

                  // 3. TEST CONTEXT CARD (JEE Main Full Test - 05)
                  _buildTestContextCard(),

                  const SizedBox(height: 16),

                  // 4. YOUR STANDING SUMMARY CARD (4 Horizontal Blocks)
                  _buildYourStandingCard(),

                  const SizedBox(height: 20),

                  // 5. SCOPE TABS & CATEGORY FILTER ROW
                  _buildScopeFilterRow(),

                  const SizedBox(height: 16),

                  // 6. LEADERBOARD LIST TABLE
                  _buildLeaderboardTable(),

                  const SizedBox(height: 16),

                  // 7. MOTIVATION & AIM HIGHER BANNER
                  _buildMotivationBanner(),

                  const SizedBox(height: 20),

                  // 8. LEADERBOARD INSIGHTS SECTION
                  _buildLeaderboardInsights(),

                  const SizedBox(height: 16),

                  // 9. FAIR & TRANSPARENT FOOTER
                  _buildFairTransparentFooter(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 1. HEADER BAR
  Widget _buildHeaderBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            InkWell(
              onTap: widget.onBack ?? () => Navigator.of(context).maybePop(),
              borderRadius: BorderRadius.circular(10),
              child: const Padding(
                padding: EdgeInsets.all(6.0),
                child: Icon(Icons.arrow_back, size: 22, color: Color(0xFF0F172A)),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Leaderboard',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.5),
                ),
                Text(
                  'See how you rank among other students',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ],
        ),
        OutlinedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Leaderboard rank shared to clipboard!'), duration: Duration(seconds: 2)),
            );
          },
          icon: const Icon(Icons.share_outlined, size: 16, color: Color(0xFF4F46E5)),
          label: const Text('Share', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w600, fontSize: 13)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFC7D2FE)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
      ],
    );
  }

  // 2. EXAM SELECTOR + TIME FILTER TABS
  Widget _buildTopControlBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Row 1: Exam Selector & Timeframe Filter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Exam Segmented Switch
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildExamPill('NEET', LeaderboardExam.neet),
                    _buildExamPill('JEE Main', LeaderboardExam.jeeMain),
                    _buildExamPill('JEE Advanced', LeaderboardExam.jeeAdvanced),
                  ],
                ),
              ),

              // Timeframe Switch
              Wrap(
                spacing: 6,
                children: [
                  _buildTimeframeChip('Today', LeaderboardTimeframe.today),
                  _buildTimeframeChip('This Week', LeaderboardTimeframe.thisWeek),
                  _buildTimeframeChip('This Month', LeaderboardTimeframe.thisMonth),
                  _buildTimeframeChip('All Time', LeaderboardTimeframe.allTime),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 8),

          // Row 2: Main Tabs (Overall | My Rank | Friends)
          Row(
            children: [
              _buildMainTabItem('Overall', LeaderboardMainTab.overall),
              const SizedBox(width: 20),
              _buildMainTabItem('My Rank', LeaderboardMainTab.myRank),
              const SizedBox(width: 20),
              _buildMainTabItem('Friends', LeaderboardMainTab.friends),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExamPill(String label, LeaderboardExam exam) {
    final bool isSelected = _selectedExam == exam;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedExam = exam;
        });
        _loadLeaderboardData();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F46E5) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeframeChip(String label, LeaderboardTimeframe timeframe) {
    final bool isSelected = _selectedTimeframe == timeframe;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF475569),
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      selected: isSelected,
      selectedColor: const Color(0xFF4F46E5),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1)),
      ),
      onSelected: (val) {
        setState(() => _selectedTimeframe = timeframe);
        _loadLeaderboardData();
      },
    );
  }

  Widget _buildMainTabItem(String label, LeaderboardMainTab tab) {
    final bool isSelected = _selectedTab == tab;
    return InkWell(
      onTap: () => setState(() => _selectedTab = tab),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 3,
            width: 32,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF4F46E5) : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  // 3. TEST CONTEXT CARD
  Widget _buildTestContextCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.emoji_events_outlined, color: Color(0xFF4F46E5), size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _examTitle,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.help_outline, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text('30 Questions', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    const SizedBox(width: 8),
                    const Text('•', style: TextStyle(color: Color(0xFF94A3B8))),
                    const SizedBox(width: 8),
                    const Icon(Icons.stars_outlined, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text('$_examMaxMarks Marks', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    const SizedBox(width: 8),
                    const Text('•', style: TextStyle(color: Color(0xFF94A3B8))),
                    const SizedBox(width: 8),
                    const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    const Text('01 May 2025', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFC7D2FE)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: Row(
              children: const [
                Text('View Test Details', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w600, fontSize: 13)),
                SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 16, color: Color(0xFF4F46E5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 4. YOUR STANDING SUMMARY CARD (4 Horizontal Blocks)
  Widget _buildYourStandingCard() {
    final cur = _currentUserData;
    if (cur == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Avatar + Your Rank Block
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFEEF2FF),
            child: const Icon(Icons.person, color: Color(0xFF4F46E5), size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your Rank', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${cur.rank} ',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF4F46E5)),
                      ),
                      const TextSpan(
                        text: '/ 12,845',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Container(width: 1, height: 44, color: const Color(0xFFE2E8F0)),
          const SizedBox(width: 16),

          // Your Score Block
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your Score', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${cur.score} ',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF4F46E5)),
                      ),
                      TextSpan(
                        text: '/ ${_examMaxMarks}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Container(width: 1, height: 44, color: const Color(0xFFE2E8F0)),
          const SizedBox(width: 16),

          // Percentile / Accuracy Block
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedExam == LeaderboardExam.neet ? 'Accuracy' : 'Percentile',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_selectedExam == LeaderboardExam.neet ? cur.accuracy : cur.percentile}%',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF4F46E5)),
                ),
              ],
            ),
          ),

          Container(width: 1, height: 44, color: const Color(0xFFE2E8F0)),
          const SizedBox(width: 16),

          // Rank Change Block
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.arrow_upward, size: 14, color: Color(0xFF10B981)),
                    const SizedBox(width: 2),
                    Text(
                      '${cur.rankChange}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF10B981)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text('vs last test', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 5. SCOPE TABS & CATEGORY FILTER ROW
  Widget _buildScopeFilterRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left Pills
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              _buildScopePill('All India', LeaderboardScope.allIndia),
              _buildScopePill('My City', LeaderboardScope.myCity),
              _buildScopePill('My State', LeaderboardScope.myState),
              _buildScopePill('My Coaching', LeaderboardScope.myCoaching),
            ],
          ),
        ),

        // Right Filter Dropdown
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isDense: true,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                  items: const [
                    DropdownMenuItem(value: 'All Categories', child: Text('All Categories')),
                    DropdownMenuItem(value: 'General', child: Text('General')),
                    DropdownMenuItem(value: 'OBC-NCL', child: Text('OBC-NCL')),
                    DropdownMenuItem(value: 'EWS', child: Text('EWS')),
                    DropdownMenuItem(value: 'SC/ST', child: Text('SC/ST')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCategory = val);
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(Icons.filter_list, size: 20, color: Color(0xFF475569)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScopePill(String label, LeaderboardScope scope) {
    final bool isSelected = _selectedScope == scope;
    return InkWell(
      onTap: () => setState(() => _selectedScope = scope),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEF2FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: const Color(0xFFC7D2FE)) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  // 6. LEADERBOARD LIST TABLE
  Widget _buildLeaderboardTable() {
    if (_isLoading) {
      return Container(
        height: 200,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              children: const [
                SizedBox(width: 48, child: Text('Rank', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)))),
                SizedBox(width: 12),
                Expanded(flex: 4, child: Text('Student', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)))),
                Expanded(flex: 3, child: Text('Score', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)), textAlign: TextAlign.right)),
                Expanded(flex: 3, child: Text('Percentile', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)), textAlign: TextAlign.right)),
                SizedBox(width: 32),
              ],
            ),
          ),

          // Top Ranks List (#1 - #5)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _students.length,
            separatorBuilder: (ctx, idx) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
            itemBuilder: (ctx, idx) {
              final s = _students[idx];
              return _buildStudentRow(s);
            },
          ),

          // Dashed Top 1% Separator Banner
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                const Expanded(child: Divider(color: Color(0xFFC7D2FE), thickness: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Top 1% Students', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF4F46E5))),
                  ),
                ),
                const Expanded(child: Divider(color: Color(0xFFC7D2FE), thickness: 1)),
              ],
            ),
          ),

          // Highlighted Current Student Row (#142 You)
          if (_currentUserData != null)
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDDD6FE)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    child: Text(
                      '${_currentUserData!.rank}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF4F46E5)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: NetworkImage(_currentUserData!.avatarUrl),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Text('You', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF4F46E5))),
                          ],
                        ),
                        Text(_currentUserData!.coaching, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: RichText(
                      textAlign: TextAlign.right,
                      text: TextSpan(
                        children: [
                          TextSpan(text: '${_currentUserData!.score} ', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF4F46E5))),
                          TextSpan(text: '/ $_examMaxMarks', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      '${_currentUserData!.percentile}%',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF4F46E5)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      const Icon(Icons.arrow_upward, size: 12, color: Color(0xFF10B981)),
                      Text('${_currentUserData!.rankChange}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF10B981))),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStudentRow(LeaderboardStudent s) {
    Widget rankBadge;
    if (s.rank == 1) {
      rankBadge = Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(color: Color(0xFFFBBF24), shape: BoxShape.circle),
        child: const Center(child: Text('1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
      );
    } else if (s.rank == 2) {
      rankBadge = Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(color: Color(0xFF94A3B8), shape: BoxShape.circle),
        child: const Center(child: Text('2', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
      );
    } else if (s.rank == 3) {
      rankBadge = Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(color: Color(0xFFD97706), shape: BoxShape.circle),
        child: const Center(child: Text('3', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
      );
    } else {
      rankBadge = SizedBox(
        width: 28,
        child: Text('${s.rank}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          SizedBox(width: 48, child: rankBadge),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage(s.avatarUrl),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                Text(s.coaching, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: RichText(
              textAlign: TextAlign.right,
              text: TextSpan(
                children: [
                  TextSpan(text: '${s.score} ', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF4F46E5))),
                  TextSpan(text: '/ $_examMaxMarks', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              '${s.percentile}%',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF4F46E5)),
            ),
          ),
          SizedBox(
            width: 32,
            child: s.isCrownWinner
                ? const Text('👑', textAlign: TextAlign.right, style: TextStyle(fontSize: 16))
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // 7. MOTIVATION & AIM HIGHER BANNER
  Widget _buildMotivationBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.show_chart, color: Color(0xFFD97706), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Keep practicing to improve your rank!',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
                ),
                const SizedBox(height: 2),
                Text(
                  'Consistent practice and mock tests are the key to cracking ${_selectedExam == LeaderboardExam.neet ? 'NEET' : 'JEE'}. You\'re ahead of 8,716 students! 🔥 Beat 12 more to reach Top 5%.',
                  style: const TextStyle(fontSize: 12, color: Color(0xFFB45309)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Loading practice targets for rank boost!'), duration: Duration(seconds: 2)),
              );
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFF59E0B)),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: Row(
              children: const [
                Text('View Progress', style: TextStyle(color: Color(0xFFB45309), fontWeight: FontWeight.w700, fontSize: 12)),
                SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 16, color: Color(0xFFB45309)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 8. LEADERBOARD INSIGHTS SECTION
  Widget _buildLeaderboardInsights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Leaderboard Insights', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildInsightCard(
                icon: Icons.people_outline,
                iconBg: const Color(0xFFEEF2FF),
                iconColor: const Color(0xFF4F46E5),
                title: 'Total Students',
                val: '12,845',
                sub: 'Who attempted this test',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInsightCard(
                icon: Icons.bar_chart_outlined,
                iconBg: const Color(0xFFE0F2FE),
                iconColor: const Color(0xFF0284C7),
                title: 'Average Score',
                val: '${(_examMaxMarks * 0.52).round()} / $_examMaxMarks',
                sub: 'Average performance',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInsightCard(
                icon: Icons.track_changes,
                iconBg: const Color(0xFFDCFCE7),
                iconColor: const Color(0xFF15803D),
                title: 'Top Score',
                val: '${(_examMaxMarks * 0.95).round()} / $_examMaxMarks',
                sub: 'By Aarav Sharma',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInsightCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String val,
    required String sub,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(val, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                Text(sub, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 9. FAIR & TRANSPARENT FOOTER
  Widget _buildFairTransparentFooter() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDD6FE)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Color(0xFF8B5CF6), shape: BoxShape.circle),
            child: const Icon(Icons.shield_outlined, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fair & Transparent', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF4C1D95))),
                Text('Results are calculated based on accurate data and verified test attempts.', style: TextStyle(fontSize: 11, color: Color(0xFF6D28D9))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
