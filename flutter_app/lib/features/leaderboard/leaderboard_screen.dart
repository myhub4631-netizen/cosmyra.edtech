import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../core/services/supabase_service.dart';

enum LeaderboardExam { neet, jeeMain, jeeAdvanced }
enum LeaderboardTimeframe { today, thisWeek, thisMonth, allTime }
enum LeaderboardScope { allIndia, myCity, myState, myCoaching }
enum LeaderboardMainTab { overall, myRank, friends }
enum LeaderboardSystemMode { points, marksAndRanks }

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
  final int correctQuestions; // For Points: +10 pts each. For Marks: +4 marks each
  final int wrongQuestions; // For Marks: -1 mark each
  final int points; // correctQuestions * 10
  final int rankChange; // +112, -5, etc.
  final bool isCrownWinner;
  final String crownType; // gold, silver, bronze, none
  final bool isCurrentUser;
  final String recentSessionType; // Custom Practice, Custom Test, NEET PYQ, NTA Questions, Test Series
  final String categoryScope; // NEET FULL Syllabus, Biology Full syllabus, Chemistry Full Syllabus, Physics Full Syllabus
  final bool meetsMinCriteria; // Attempted across Custom Practice, Custom Test, NEET PYQ, NTA Questions, Test Series

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
    required this.correctQuestions,
    this.wrongQuestions = 0,
    int? points,
    required this.rankChange,
    this.isCrownWinner = false,
    this.crownType = 'none',
    this.isCurrentUser = false,
    this.recentSessionType = 'Custom Test',
    this.categoryScope = 'NEET FULL Syllabus',
    this.meetsMinCriteria = true,
  }) : points = points ?? (correctQuestions * 10);

  double get percentage => maxScore > 0 ? (score / maxScore * 100) : 0.0;
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
  LeaderboardSystemMode _selectedSystemMode = LeaderboardSystemMode.marksAndRanks; // Default toggle
  String _selectedCategory = 'NEET FULL Syllabus';

  bool _isLoading = false;
  List<LeaderboardStudent> _students = [];
  LeaderboardStudent? _currentUserData;

  @override
  void initState() {
    super.initState();
    final examStr = widget.initialExam?.toUpperCase() ?? 'NEET';
    if (examStr.contains('NEET')) {
      _selectedExam = LeaderboardExam.neet;
      _selectedCategory = 'NEET FULL Syllabus';
    } else if (examStr.contains('ADVANCED')) {
      _selectedExam = LeaderboardExam.jeeAdvanced;
      _selectedCategory = 'JEE Advanced Full Syllabus';
    } else {
      _selectedExam = LeaderboardExam.jeeMain;
      _selectedCategory = 'JEE Main Full Syllabus';
    }

    _loadLeaderboardData();
  }

  void _loadLeaderboardData() {
    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 200), () {
      int maxScore = _categoryMaxMarks;
      int totalQs = _categoryTotalQuestions;
      
      List<LeaderboardStudent> mockList = [];
      if (_selectedExam == LeaderboardExam.neet) {
        if (_selectedCategory.contains('Biology')) {
          // Biology Full syllabus (90 Qs, 360 Marks)
          mockList = [
            LeaderboardStudent(
              rank: 1, name: 'Aarav Sharma', coaching: 'Vibrant Academy', avatarUrl: 'https://i.pravatar.cc/150?img=11',
              score: 355, maxScore: 360, percentile: 99.99, accuracy: 98.8, questionsAttempted: 90, correctQuestions: 89, wrongQuestions: 1,
              rankChange: 0, isCrownWinner: true, crownType: 'gold', recentSessionType: 'Custom Test', categoryScope: _selectedCategory, meetsMinCriteria: true,
            ),
            LeaderboardStudent(
              rank: 2, name: 'Rohit Verma', coaching: 'Resonance Kota', avatarUrl: 'https://i.pravatar.cc/150?img=12',
              score: 350, maxScore: 360, percentile: 99.97, accuracy: 97.7, questionsAttempted: 90, correctQuestions: 88, wrongQuestions: 2,
              rankChange: 2, isCrownWinner: true, crownType: 'silver', recentSessionType: 'NEET PYQ', categoryScope: _selectedCategory, meetsMinCriteria: true,
            ),
            LeaderboardStudent(
              rank: 3, name: 'Isha Singh', coaching: 'Allen Career Institute', avatarUrl: 'https://i.pravatar.cc/150?img=25',
              score: 345, maxScore: 360, percentile: 99.95, accuracy: 96.6, questionsAttempted: 90, correctQuestions: 87, wrongQuestions: 3,
              rankChange: -1, isCrownWinner: true, crownType: 'bronze', recentSessionType: 'Test Series', categoryScope: _selectedCategory, meetsMinCriteria: true,
            ),
            LeaderboardStudent(
              rank: 4, name: 'Vedant Gupta', coaching: 'Aakash Institute', avatarUrl: 'https://i.pravatar.cc/150?img=33',
              score: 340, maxScore: 360, percentile: 99.92, accuracy: 95.5, questionsAttempted: 90, correctQuestions: 86, wrongQuestions: 4,
              rankChange: 4, recentSessionType: 'Custom Practice', categoryScope: _selectedCategory, meetsMinCriteria: true,
            ),
            LeaderboardStudent(
              rank: 5, name: 'Ananya Reddy', coaching: 'Narayana Academy', avatarUrl: 'https://i.pravatar.cc/150?img=47',
              score: 335, maxScore: 360, percentile: 99.90, accuracy: 94.4, questionsAttempted: 90, correctQuestions: 85, wrongQuestions: 5,
              rankChange: 1, recentSessionType: 'NTA Questions', categoryScope: _selectedCategory, meetsMinCriteria: true,
            ),
          ];
          _currentUserData = LeaderboardStudent(
            rank: 142,
            name: widget.userProfile?.fullName ?? 'You',
            coaching: 'Cosmyra Student',
            avatarUrl: widget.userProfile?.avatarUrl ?? 'https://i.pravatar.cc/150?img=60',
            score: 305,
            maxScore: 360,
            percentile: 98.89,
            accuracy: 85.5,
            questionsAttempted: 80,
            correctQuestions: 77,
            wrongQuestions: 3,
            rankChange: 112,
            isCurrentUser: true,
            recentSessionType: 'Custom Practice',
            categoryScope: _selectedCategory,
            meetsMinCriteria: true,
          );
        } else if (_selectedCategory.contains('Chemistry') || _selectedCategory.contains('Physics')) {
          // Physics / Chemistry Full Syllabus (45 Qs, 180 Marks)
          mockList = [
            LeaderboardStudent(
              rank: 1, name: 'Aarav Sharma', coaching: 'Vibrant Academy', avatarUrl: 'https://i.pravatar.cc/150?img=11',
              score: 175, maxScore: 180, percentile: 99.99, accuracy: 97.7, questionsAttempted: 45, correctQuestions: 44, wrongQuestions: 1,
              rankChange: 0, isCrownWinner: true, crownType: 'gold', recentSessionType: 'Custom Test', categoryScope: _selectedCategory, meetsMinCriteria: true,
            ),
            LeaderboardStudent(
              rank: 2, name: 'Rohit Verma', coaching: 'Resonance Kota', avatarUrl: 'https://i.pravatar.cc/150?img=12',
              score: 170, maxScore: 180, percentile: 99.97, accuracy: 95.5, questionsAttempted: 45, correctQuestions: 43, wrongQuestions: 2,
              rankChange: 2, isCrownWinner: true, crownType: 'silver', recentSessionType: 'NEET PYQ', categoryScope: _selectedCategory, meetsMinCriteria: true,
            ),
            LeaderboardStudent(
              rank: 3, name: 'Isha Singh', coaching: 'Allen Career Institute', avatarUrl: 'https://i.pravatar.cc/150?img=25',
              score: 166, maxScore: 180, percentile: 99.95, accuracy: 93.3, questionsAttempted: 44, correctQuestions: 42, wrongQuestions: 2,
              rankChange: -1, isCrownWinner: true, crownType: 'bronze', recentSessionType: 'Test Series', categoryScope: _selectedCategory, meetsMinCriteria: true,
            ),
            LeaderboardStudent(
              rank: 4, name: 'Vedant Gupta', coaching: 'Aakash Institute', avatarUrl: 'https://i.pravatar.cc/150?img=33',
              score: 161, maxScore: 180, percentile: 99.92, accuracy: 91.1, questionsAttempted: 44, correctQuestions: 41, wrongQuestions: 3,
              rankChange: 4, recentSessionType: 'Custom Practice', categoryScope: _selectedCategory, meetsMinCriteria: true,
            ),
            LeaderboardStudent(
              rank: 5, name: 'Ananya Reddy', coaching: 'Narayana Academy', avatarUrl: 'https://i.pravatar.cc/150?img=47',
              score: 157, maxScore: 180, percentile: 99.90, accuracy: 88.8, questionsAttempted: 43, correctQuestions: 40, wrongQuestions: 3,
              rankChange: 1, recentSessionType: 'NTA Questions', categoryScope: _selectedCategory, meetsMinCriteria: true,
            ),
          ];
          _currentUserData = LeaderboardStudent(
            rank: 142,
            name: widget.userProfile?.fullName ?? 'You',
            coaching: 'Cosmyra Student',
            avatarUrl: widget.userProfile?.avatarUrl ?? 'https://i.pravatar.cc/150?img=60',
            score: 150,
            maxScore: 180,
            percentile: 98.89,
            accuracy: 84.4,
            questionsAttempted: 40,
            correctQuestions: 38,
            wrongQuestions: 2,
            rankChange: 112,
            isCurrentUser: true,
            recentSessionType: 'Custom Practice',
            categoryScope: _selectedCategory,
            meetsMinCriteria: true,
          );
        } else {
          // NEET FULL Syllabus (180 Qs, 720 Marks)
          mockList = [
            LeaderboardStudent(
              rank: 1, name: 'Aarav Sharma', coaching: 'Vibrant Academy', avatarUrl: 'https://i.pravatar.cc/150?img=11',
              score: 715, maxScore: 720, percentile: 99.99, accuracy: 99.4, questionsAttempted: 180, correctQuestions: 179, wrongQuestions: 1,
              rankChange: 0, isCrownWinner: true, crownType: 'gold', recentSessionType: 'Custom Test', categoryScope: _selectedCategory, meetsMinCriteria: true,
            ),
            LeaderboardStudent(
              rank: 2, name: 'Rohit Verma', coaching: 'Resonance Kota', avatarUrl: 'https://i.pravatar.cc/150?img=12',
              score: 710, maxScore: 720, percentile: 99.97, accuracy: 98.8, questionsAttempted: 180, correctQuestions: 178, wrongQuestions: 2,
              rankChange: 2, isCrownWinner: true, crownType: 'silver', recentSessionType: 'NEET PYQ', categoryScope: _selectedCategory, meetsMinCriteria: true,
            ),
            LeaderboardStudent(
              rank: 3, name: 'Isha Singh', coaching: 'Allen Career Institute', avatarUrl: 'https://i.pravatar.cc/150?img=25',
              score: 705, maxScore: 720, percentile: 99.95, accuracy: 98.3, questionsAttempted: 180, correctQuestions: 177, wrongQuestions: 3,
              rankChange: -1, isCrownWinner: true, crownType: 'bronze', recentSessionType: 'Test Series', categoryScope: _selectedCategory, meetsMinCriteria: true,
            ),
            LeaderboardStudent(
              rank: 4, name: 'Vedant Gupta', coaching: 'Aakash Institute', avatarUrl: 'https://i.pravatar.cc/150?img=33',
              score: 700, maxScore: 720, percentile: 99.92, accuracy: 97.7, questionsAttempted: 180, correctQuestions: 176, wrongQuestions: 4,
              rankChange: 4, recentSessionType: 'Custom Practice', categoryScope: _selectedCategory, meetsMinCriteria: true,
            ),
            LeaderboardStudent(
              rank: 5, name: 'Ananya Reddy', coaching: 'Narayana Academy', avatarUrl: 'https://i.pravatar.cc/150?img=47',
              score: 695, maxScore: 720, percentile: 99.90, accuracy: 97.2, questionsAttempted: 180, correctQuestions: 175, wrongQuestions: 5,
              rankChange: 1, recentSessionType: 'NTA Questions', categoryScope: _selectedCategory, meetsMinCriteria: true,
            ),
          ];
          _currentUserData = LeaderboardStudent(
            rank: 142,
            name: widget.userProfile?.fullName ?? 'You',
            coaching: 'Cosmyra Student',
            avatarUrl: widget.userProfile?.avatarUrl ?? 'https://i.pravatar.cc/150?img=60',
            score: 612,
            maxScore: 720,
            percentile: 98.89,
            accuracy: 85.5,
            questionsAttempted: 158,
            correctQuestions: 154,
            wrongQuestions: 4,
            rankChange: 112,
            isCurrentUser: true,
            recentSessionType: 'Custom Practice',
            categoryScope: _selectedCategory,
            meetsMinCriteria: true,
          );
        }
      } else if (_selectedExam == LeaderboardExam.jeeAdvanced) {
        mockList = [
          LeaderboardStudent(
            rank: 1, name: 'Aarav Sharma', coaching: 'Vibrant Academy', avatarUrl: 'https://i.pravatar.cc/150?img=11',
            score: (maxScore * 0.90).round(), maxScore: maxScore, percentile: 99.99, accuracy: 94.2, questionsAttempted: totalQs, correctQuestions: (totalQs * 0.91).round(), wrongQuestions: 2,
            rankChange: 0, isCrownWinner: true, crownType: 'gold', recentSessionType: 'Test Series', categoryScope: _selectedCategory, meetsMinCriteria: true,
          ),
          LeaderboardStudent(
            rank: 2, name: 'Rohit Verma', coaching: 'Resonance Kota', avatarUrl: 'https://i.pravatar.cc/150?img=12',
            score: (maxScore * 0.88).round(), maxScore: maxScore, percentile: 99.97, accuracy: 92.6, questionsAttempted: totalQs, correctQuestions: (totalQs * 0.89).round(), wrongQuestions: 3,
            rankChange: 1, isCrownWinner: true, crownType: 'silver', recentSessionType: 'Custom Test', categoryScope: _selectedCategory, meetsMinCriteria: true,
          ),
          LeaderboardStudent(
            rank: 3, name: 'Isha Singh', coaching: 'Allen Career Institute', avatarUrl: 'https://i.pravatar.cc/150?img=25',
            score: (maxScore * 0.86).round(), maxScore: maxScore, percentile: 99.95, accuracy: 91.0, questionsAttempted: totalQs, correctQuestions: (totalQs * 0.87).round(), wrongQuestions: 3,
            rankChange: -1, isCrownWinner: true, crownType: 'bronze', recentSessionType: 'NTA Questions', categoryScope: _selectedCategory, meetsMinCriteria: true,
          ),
          LeaderboardStudent(
            rank: 4, name: 'Vedant Gupta', coaching: 'Aakash Institute', avatarUrl: 'https://i.pravatar.cc/150?img=33',
            score: (maxScore * 0.83).round(), maxScore: maxScore, percentile: 99.92, accuracy: 89.4, questionsAttempted: totalQs, correctQuestions: (totalQs * 0.85).round(), wrongQuestions: 4,
            rankChange: 2, recentSessionType: 'Custom Practice', categoryScope: _selectedCategory, meetsMinCriteria: true,
          ),
          LeaderboardStudent(
            rank: 5, name: 'Ananya Reddy', coaching: 'Narayana Academy', avatarUrl: 'https://i.pravatar.cc/150?img=47',
            score: (maxScore * 0.81).round(), maxScore: maxScore, percentile: 99.90, accuracy: 88.8, questionsAttempted: totalQs, correctQuestions: (totalQs * 0.83).round(), wrongQuestions: 4,
            rankChange: 3, recentSessionType: 'JEE PYQ', categoryScope: _selectedCategory, meetsMinCriteria: true,
          ),
        ];
        _currentUserData = LeaderboardStudent(
          rank: 142,
          name: widget.userProfile?.fullName ?? 'You',
          coaching: 'Cosmyra Student',
          avatarUrl: widget.userProfile?.avatarUrl ?? 'https://i.pravatar.cc/150?img=60',
          score: (maxScore * 0.60).round(),
          maxScore: maxScore,
          percentile: 98.89,
          accuracy: 78.5,
          questionsAttempted: (totalQs * 0.80).round(),
          correctQuestions: (totalQs * 0.65).round(),
          wrongQuestions: 4,
          rankChange: 112,
          isCurrentUser: true,
          recentSessionType: 'Custom Practice',
          categoryScope: _selectedCategory,
          meetsMinCriteria: true,
        );
      } else {
        // JEE Main
        mockList = [
          LeaderboardStudent(
            rank: 1, name: 'Aarav Sharma', coaching: 'Vibrant Academy', avatarUrl: 'https://i.pravatar.cc/150?img=11',
            score: (maxScore * 0.95).round(), maxScore: maxScore, percentile: 99.99, accuracy: 95.0, questionsAttempted: totalQs, correctQuestions: (totalQs * 0.96).round(), wrongQuestions: 2,
            rankChange: 0, isCrownWinner: true, crownType: 'gold', recentSessionType: 'Custom Test', categoryScope: _selectedCategory, meetsMinCriteria: true,
          ),
          LeaderboardStudent(
            rank: 2, name: 'Rohit Verma', coaching: 'Resonance Kota', avatarUrl: 'https://i.pravatar.cc/150?img=12',
            score: (maxScore * 0.94).round(), maxScore: maxScore, percentile: 99.97, accuracy: 94.0, questionsAttempted: totalQs, correctQuestions: (totalQs * 0.94).round(), wrongQuestions: 2,
            rankChange: 2, isCrownWinner: true, crownType: 'silver', recentSessionType: 'JEE PYQ', categoryScope: _selectedCategory, meetsMinCriteria: true,
          ),
          LeaderboardStudent(
            rank: 3, name: 'Isha Singh', coaching: 'Allen Career Institute', avatarUrl: 'https://i.pravatar.cc/150?img=25',
            score: (maxScore * 0.92).round(), maxScore: maxScore, percentile: 99.95, accuracy: 92.6, questionsAttempted: totalQs, correctQuestions: (totalQs * 0.93).round(), wrongQuestions: 3,
            rankChange: -1, isCrownWinner: true, crownType: 'bronze', recentSessionType: 'Test Series', categoryScope: _selectedCategory, meetsMinCriteria: true,
          ),
          LeaderboardStudent(
            rank: 4, name: 'Vedant Gupta', coaching: 'Aakash Institute', avatarUrl: 'https://i.pravatar.cc/150?img=33',
            score: (maxScore * 0.91).round(), maxScore: maxScore, percentile: 99.92, accuracy: 92.0, questionsAttempted: totalQs, correctQuestions: (totalQs * 0.92).round(), wrongQuestions: 3,
            rankChange: 3, recentSessionType: 'NTA Questions', categoryScope: _selectedCategory, meetsMinCriteria: true,
          ),
          LeaderboardStudent(
            rank: 5, name: 'Ananya Reddy', coaching: 'Narayana Academy', avatarUrl: 'https://i.pravatar.cc/150?img=47',
            score: (maxScore * 0.89).round(), maxScore: maxScore, percentile: 99.90, accuracy: 91.3, questionsAttempted: totalQs, correctQuestions: (totalQs * 0.90).round(), wrongQuestions: 4,
            rankChange: 1, recentSessionType: 'Custom Practice', categoryScope: _selectedCategory, meetsMinCriteria: true,
          ),
        ];
        _currentUserData = LeaderboardStudent(
          rank: 142,
          name: widget.userProfile?.fullName ?? 'You',
          coaching: 'Cosmyra Student',
          avatarUrl: widget.userProfile?.avatarUrl ?? 'https://i.pravatar.cc/150?img=60',
          score: (maxScore * 0.69).round(),
          maxScore: maxScore,
          percentile: 98.89,
          accuracy: 78.0,
          questionsAttempted: (totalQs * 0.85).round(),
          correctQuestions: (totalQs * 0.72).round(),
          wrongQuestions: 4,
          rankChange: 112,
          isCurrentUser: true,
          recentSessionType: 'Custom Practice',
          categoryScope: _selectedCategory,
          meetsMinCriteria: true,
        );
      }

      // Sort students based on active system mode:
      if (_selectedSystemMode == LeaderboardSystemMode.points) {
        mockList.sort((a, b) => b.points.compareTo(a.points));
      } else {
        // Marks & Ranks: Priority 1 = Percentage (%), Priority 2 = Score
        mockList.sort((a, b) {
          int cmp = b.percentage.compareTo(a.percentage);
          if (cmp != 0) return cmp;
          return b.score.compareTo(a.score);
        });
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
    if (_selectedExam == LeaderboardExam.neet) {
      return '$_selectedCategory - Mock Exam';
    } else if (_selectedExam == LeaderboardExam.jeeAdvanced) {
      return '$_selectedCategory - Advanced Series';
    } else {
      return '$_selectedCategory - Mains Series';
    }
  }

  int get _categoryMaxMarks {
    if (_selectedExam == LeaderboardExam.neet) {
      if (_selectedCategory.contains('Biology')) return 360;
      if (_selectedCategory.contains('Chemistry') || _selectedCategory.contains('Physics')) return 180;
      return 720; // NEET FULL Syllabus
    } else if (_selectedExam == LeaderboardExam.jeeAdvanced) {
      if (_selectedCategory.contains('Physics') || _selectedCategory.contains('Chemistry') || _selectedCategory.contains('Mathematics')) return 120;
      return 360;
    } else {
      if (_selectedCategory.contains('Physics') || _selectedCategory.contains('Chemistry') || _selectedCategory.contains('Mathematics')) return 100;
      return 300;
    }
  }

  int get _categoryTotalQuestions {
    if (_selectedExam == LeaderboardExam.neet) {
      if (_selectedCategory.contains('Biology')) return 90;
      if (_selectedCategory.contains('Chemistry') || _selectedCategory.contains('Physics')) return 45;
      return 180; // NEET FULL Syllabus
    } else if (_selectedExam == LeaderboardExam.jeeAdvanced) {
      if (_selectedCategory.contains('Physics') || _selectedCategory.contains('Chemistry') || _selectedCategory.contains('Mathematics')) return 18;
      return 54;
    } else {
      if (_selectedCategory.contains('Physics') || _selectedCategory.contains('Chemistry') || _selectedCategory.contains('Mathematics')) return 25;
      return 75;
    }
  }

  List<String> get _availableCategories {
    if (_selectedExam == LeaderboardExam.neet) {
      return [
        'NEET FULL Syllabus',
        'Biology Full syllabus',
        'Chemistry Full Syllabus',
        'Physics Full Syllabus',
      ];
    } else if (_selectedExam == LeaderboardExam.jeeAdvanced) {
      return [
        'JEE Advanced Full Syllabus',
        'Physics Full Syllabus',
        'Chemistry Full Syllabus',
        'Mathematics Full Syllabus',
      ];
    } else {
      return [
        'JEE Main Full Syllabus',
        'Physics Full Syllabus',
        'Chemistry Full Syllabus',
        'Mathematics Full Syllabus',
      ];
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

                  // 2. EXAM SELECTOR + RED MARKED SYSTEM TOGGLE + TIME FILTER TABS
                  _buildTopControlBar(),

                  const SizedBox(height: 16),

                  // 3. SYSTEM MODE EXPLANATION / ELIGIBILITY BANNER
                  _buildSystemExplanationBanner(),

                  const SizedBox(height: 16),

                  // 4. TEST CONTEXT CARD
                  _buildTestContextCard(),

                  const SizedBox(height: 16),

                  // 5. YOUR STANDING SUMMARY CARD (Responsive 2x2 grid on mobile)
                  _buildYourStandingCard(),

                  const SizedBox(height: 20),

                  // 6. SCOPE TABS & CATEGORY FILTER ROW
                  _buildScopeFilterRow(),

                  const SizedBox(height: 16),

                  // 7. LEADERBOARD LIST TABLE
                  _buildLeaderboardTable(),

                  const SizedBox(height: 16),

                  // 8. MOTIVATION BANNER
                  _buildMotivationBanner(),

                  const SizedBox(height: 20),

                  // 9. LEADERBOARD INSIGHTS SECTION
                  _buildLeaderboardInsights(),

                  const SizedBox(height: 16),

                  // 10. FAIR & TRANSPARENT FOOTER
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 480;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Leaderboard',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.5),
                        ),
                        Text(
                          'See how you rank among other students',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w400),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isMobile)
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Leaderboard rank shared!'), duration: Duration(seconds: 2)),
                  );
                },
                icon: const Icon(Icons.share_outlined, size: 20, color: Color(0xFF4F46E5)),
                tooltip: 'Share',
              )
            else
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
      },
    );
  }

  // 2. EXAM SELECTOR + RED MARKED SYSTEM TOGGLE + TIME FILTER TABS
  Widget _buildTopControlBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 720;

        final examSegment = Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildExamPill('NEET', LeaderboardExam.neet),
              _buildExamPill('JEE Main', LeaderboardExam.jeeMain),
              _buildExamPill('JEE Advanced', LeaderboardExam.jeeAdvanced),
            ],
          ),
        );

        // RED MARKED TOGGLE: Points vs Marks & Ranks System
        final systemModeSegment = Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFC7D2FE)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSystemModePill('🪙 Based on Points', LeaderboardSystemMode.points),
              _buildSystemModePill('🎯 Marks & Ranks', LeaderboardSystemMode.marksAndRanks),
            ],
          ),
        );

        final timeframeSegment = SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTimeframeChip('Today', LeaderboardTimeframe.today),
              const SizedBox(width: 4),
              _buildTimeframeChip('This Week', LeaderboardTimeframe.thisWeek),
              const SizedBox(width: 4),
              _buildTimeframeChip('This Month', LeaderboardTimeframe.thisMonth),
              const SizedBox(width: 4),
              _buildTimeframeChip('All Time', LeaderboardTimeframe.allTime),
            ],
          ),
        );

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isMobile) ...[
                SingleChildScrollView(scrollDirection: Axis.horizontal, child: examSegment),
                const SizedBox(height: 10),
                SingleChildScrollView(scrollDirection: Axis.horizontal, child: systemModeSegment),
                const SizedBox(height: 10),
                timeframeSegment,
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    examSegment,
                    systemModeSegment,
                    timeframeSegment,
                  ],
                ),
              ],
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 8),
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
      },
    );
  }

  Widget _buildSystemModePill(String label, LeaderboardSystemMode mode) {
    final bool isSelected = _selectedSystemMode == mode;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedSystemMode = mode;
        });
        _loadLeaderboardData();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F46E5) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF4F46E5),
          ),
        ),
      ),
    );
  }

  Widget _buildExamPill(String label, LeaderboardExam exam) {
    final bool isSelected = _selectedExam == exam;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedExam = exam;
          final categories = _availableCategories;
          if (!categories.contains(_selectedCategory)) {
            _selectedCategory = categories.first;
          }
        });
        _loadLeaderboardData();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F46E5) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
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
          fontSize: 11,
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
              fontSize: 13,
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

  // 3. SYSTEM MODE EXPLANATION / ELIGIBILITY BANNER
  Widget _buildSystemExplanationBanner() {
    if (_selectedSystemMode == LeaderboardSystemMode.points) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: Row(
          children: const [
            Icon(Icons.stars, color: Color(0xFF16A34A), size: 22),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Points System: Earn +10 points for every correct option. 0 points for wrong or unattempted questions.',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF15803D)),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_user_outlined, color: Color(0xFF2563EB), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 12, color: Color(0xFF1E40AF)),
                      children: [
                        const TextSpan(text: 'Marks & Ranks Marking Scheme: ', style: TextStyle(fontWeight: FontWeight.w800)),
                        const TextSpan(
                          text: '+4 marks for correct option, -1 mark for wrong option (0 for unattempted).\n',
                        ),
                        const TextSpan(text: 'Rank Priority: ', style: TextStyle(fontWeight: FontWeight.w800)),
                        const TextSpan(
                          text: '1st Priority = Percentage (%) • 2nd Priority = Total Marks.\n',
                        ),
                        const TextSpan(text: 'Minimum Eligibility Criteria: ', style: TextStyle(fontWeight: FontWeight.w800)),
                        TextSpan(
                          text: 'Must have attempted $_selectedCategory ($_categoryTotalQuestions Questions • $_categoryMaxMarks Marks) across Custom Practice, Custom Test, NEET PYQ, NTA Questions, or Test Series.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  // 4. TEST CONTEXT CARD
  Widget _buildTestContextCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _selectedSystemMode == LeaderboardSystemMode.points ? Icons.emoji_events : Icons.verified,
                      color: const Color(0xFF4F46E5),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _examTitle,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text('$_categoryTotalQuestions Questions', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            const Text('•', style: TextStyle(color: Color(0xFF94A3B8))),
                            Text('$_categoryMaxMarks Marks', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            const Text('•', style: TextStyle(color: Color(0xFF94A3B8))),
                            const Text('01 May 2025', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isMobile) ...[
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
                          Text('View Test Details', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w600, fontSize: 12)),
                          SizedBox(width: 4),
                          Icon(Icons.chevron_right, size: 16, color: Color(0xFF4F46E5)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              if (isMobile) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFC7D2FE)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text('View Test Details', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w600, fontSize: 12)),
                        SizedBox(width: 4),
                        Icon(Icons.chevron_right, size: 16, color: Color(0xFF4F46E5)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // 5. YOUR STANDING SUMMARY CARD (4 Horizontal Blocks, 2x2 on Mobile)
  Widget _buildYourStandingCard() {
    final cur = _currentUserData;
    if (cur == null) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 640;

        Widget buildRankBlock() {
          return Row(
            children: [
              CircleAvatar(
                radius: isMobile ? 18 : 22,
                backgroundColor: const Color(0xFFEEF2FF),
                child: Icon(Icons.person, color: const Color(0xFF4F46E5), size: isMobile ? 20 : 24),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedSystemMode == LeaderboardSystemMode.points ? 'Points Rank' : 'Your Rank',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '#${cur.rank} ',
                            style: TextStyle(fontSize: isMobile ? 18 : 22, fontWeight: FontWeight.w900, color: const Color(0xFF4F46E5)),
                          ),
                          const TextSpan(
                            text: '/ 12,845',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        Widget buildScoreOrPointsBlock() {
          if (_selectedSystemMode == LeaderboardSystemMode.points) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Total Points', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  '${cur.points} pts',
                  style: TextStyle(fontSize: isMobile ? 18 : 22, fontWeight: FontWeight.w900, color: const Color(0xFF16A34A)),
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Your Score', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${cur.score} ',
                      style: TextStyle(fontSize: isMobile ? 18 : 22, fontWeight: FontWeight.w900, color: const Color(0xFF4F46E5)),
                    ),
                    TextSpan(
                      text: '/ $_categoryMaxMarks',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        Widget buildAccuracyOrPercentageBlock() {
          if (_selectedSystemMode == LeaderboardSystemMode.points) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Correct Qs (+10)', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  '${cur.correctQuestions} Qs',
                  style: TextStyle(fontSize: isMobile ? 18 : 22, fontWeight: FontWeight.w900, color: const Color(0xFF4F46E5)),
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Percentage %',
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                '${cur.percentage.toStringAsFixed(1)}%',
                style: TextStyle(fontSize: isMobile ? 18 : 22, fontWeight: FontWeight.w900, color: const Color(0xFF4F46E5)),
              ),
            ],
          );
        }

        Widget buildRankChangeBlock() {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.arrow_upward, size: 14, color: Color(0xFF10B981)),
                  const SizedBox(width: 2),
                  Text(
                    '${cur.rankChange}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF10B981)),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              const Text('vs last test', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
            ],
          );
        }

        if (isMobile) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                Row(
                  children: [
                    Expanded(child: buildRankBlock()),
                    Container(width: 1, height: 36, color: const Color(0xFFE2E8F0)),
                    const SizedBox(width: 10),
                    Expanded(child: buildScoreOrPointsBlock()),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                ),
                Row(
                  children: [
                    Expanded(child: buildAccuracyOrPercentageBlock()),
                    Container(width: 1, height: 36, color: const Color(0xFFE2E8F0)),
                    const SizedBox(width: 10),
                    Expanded(child: buildRankChangeBlock()),
                  ],
                ),
              ],
            ),
          );
        }

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
              Expanded(flex: 4, child: buildRankBlock()),
              Container(width: 1, height: 44, color: const Color(0xFFE2E8F0)),
              const SizedBox(width: 14),
              Expanded(flex: 3, child: buildScoreOrPointsBlock()),
              Container(width: 1, height: 44, color: const Color(0xFFE2E8F0)),
              const SizedBox(width: 14),
              Expanded(flex: 3, child: buildAccuracyOrPercentageBlock()),
              Container(width: 1, height: 44, color: const Color(0xFFE2E8F0)),
              const SizedBox(width: 14),
              Expanded(flex: 3, child: buildRankChangeBlock()),
            ],
          ),
        );
      },
    );
  }

  // 6. SCOPE TABS & MARKS CATEGORY DROPDOWN ROW
  Widget _buildScopeFilterRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 640;

        final scopePills = SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
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
        );

        // CATEGORY DROPDOWN: NEET FULL Syllabus (180 Qs, 720 Marks), Biology Full syllabus (90 Qs, 360 Marks), Chemistry Full Syllabus (45 Qs, 180 Marks), Physics Full Syllabus (45 Qs, 180 Marks)
        final filterDropdown = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _availableCategories.contains(_selectedCategory) ? _selectedCategory : _availableCategories.first,
                  isDense: true,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                  items: _availableCategories.map((cat) {
                    return DropdownMenuItem<String>(
                      value: cat,
                      child: Text(cat),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedCategory = val);
                      _loadLeaderboardData();
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(Icons.filter_list, size: 18, color: Color(0xFF475569)),
            ),
          ],
        );

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              scopePills,
              const SizedBox(height: 10),
              filterDropdown,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            scopePills,
            filterDropdown,
          ],
        );
      },
    );
  }

  Widget _buildScopePill(String label, LeaderboardScope scope) {
    final bool isSelected = _selectedScope == scope;
    return InkWell(
      onTap: () => setState(() => _selectedScope = scope),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEF2FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: const Color(0xFFC7D2FE)) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  // 7. LEADERBOARD LIST TABLE (Scrollable container to prevent text overlap on mobile)
  Widget _buildLeaderboardTable() {
    if (_isLoading) {
      return Container(
        height: 200,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final isPointsMode = _selectedSystemMode == LeaderboardSystemMode.points;
    final double tableWidth = isPointsMode ? 560 : 660;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: tableWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Table Header
                Container(
                  width: tableWidth,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 44, child: Text('Rank', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)))),
                      const SizedBox(width: 8),
                      const Expanded(flex: 4, child: Text('Student & Recent Session', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)))),
                      if (isPointsMode) ...[
                        const SizedBox(width: 100, child: Text('Correct Qs (+10)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)), textAlign: TextAlign.right)),
                        const SizedBox(width: 90, child: Text('Total Points', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)), textAlign: TextAlign.right)),
                      ] else ...[
                        const SizedBox(width: 95, child: Text('Percentage %', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)), textAlign: TextAlign.right)),
                        const SizedBox(width: 95, child: Text('Marks (+4/-1)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)), textAlign: TextAlign.right)),
                        const SizedBox(width: 80, child: Text('Percentile', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)), textAlign: TextAlign.right)),
                      ],
                      const SizedBox(width: 32),
                    ],
                  ),
                ),

                // Top Ranks List (#1 - #5)
                SizedBox(
                  width: tableWidth,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _students.length,
                    separatorBuilder: (ctx, idx) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (ctx, idx) {
                      final s = _students[idx];
                      return _buildStudentRow(s, tableWidth);
                    },
                  ),
                ),

                // Dashed Top 1% Separator Banner
                SizedBox(
                  width: tableWidth,
                  child: Padding(
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
                ),

                // Highlighted Current Student Row (#142 You)
                if (_currentUserData != null)
                  Container(
                    width: tableWidth - 24,
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDDD6FE)),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 44,
                          child: Text(
                            '#${_currentUserData!.rank}',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF4F46E5)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: NetworkImage(_currentUserData!.avatarUrl),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Text('You', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF4F46E5))),
                                ],
                              ),
                              Text(
                                '${_currentUserData!.recentSessionType} • ${_currentUserData!.categoryScope}',
                                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        if (isPointsMode) ...[
                          SizedBox(
                            width: 100,
                            child: Text(
                              '${_currentUserData!.correctQuestions} Qs',
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF4F46E5)),
                            ),
                          ),
                          SizedBox(
                            width: 90,
                            child: Text(
                              '${_currentUserData!.points} pts',
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF16A34A)),
                            ),
                          ),
                        ] else ...[
                          SizedBox(
                            width: 95,
                            child: Text(
                              '${_currentUserData!.percentage.toStringAsFixed(1)}%',
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF4F46E5)),
                            ),
                          ),
                          SizedBox(
                            width: 95,
                            child: RichText(
                              textAlign: TextAlign.right,
                              text: TextSpan(
                                children: [
                                  TextSpan(text: '${_currentUserData!.score} ', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF4F46E5))),
                                  TextSpan(text: '/ $_categoryMaxMarks', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: Text(
                              '${_currentUserData!.percentile}%',
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
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
          ),
        ),
      ),
    );
  }

  Widget _buildStudentRow(LeaderboardStudent s, double tableWidth) {
    final isPointsMode = _selectedSystemMode == LeaderboardSystemMode.points;

    Widget rankBadge;
    if (s.rank == 1) {
      rankBadge = Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(color: Color(0xFFFBBF24), shape: BoxShape.circle),
        child: const Center(child: Text('1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
      );
    } else if (s.rank == 2) {
      rankBadge = Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(color: Color(0xFF94A3B8), shape: BoxShape.circle),
        child: const Center(child: Text('2', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
      );
    } else if (s.rank == 3) {
      rankBadge = Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(color: Color(0xFFD97706), shape: BoxShape.circle),
        child: const Center(child: Text('3', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
      );
    } else {
      rankBadge = SizedBox(
        width: 26,
        child: Text('${s.rank}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SizedBox(width: 44, child: rankBadge),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage(s.avatarUrl),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                const SizedBox(height: 1),
                Text(
                  'Achieved in ${s.recentSessionType} • ${s.categoryScope}',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          if (isPointsMode) ...[
            SizedBox(
              width: 100,
              child: Text(
                '${s.correctQuestions} Qs',
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF4F46E5)),
              ),
            ),
            SizedBox(
              width: 90,
              child: Text(
                '${s.points} pts',
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF16A34A)),
              ),
            ),
          ] else ...[
            SizedBox(
              width: 95,
              child: Text(
                '${s.percentage.toStringAsFixed(1)}%',
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF4F46E5)),
              ),
            ),
            SizedBox(
              width: 95,
              child: RichText(
                textAlign: TextAlign.right,
                text: TextSpan(
                  children: [
                    TextSpan(text: '${s.score} ', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF4F46E5))),
                    TextSpan(text: '/ $_categoryMaxMarks', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 80,
              child: Text(
                '${s.percentile}%',
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
              ),
            ),
          ],
          SizedBox(
            width: 32,
            child: s.isCrownWinner
                ? const Text('👑', textAlign: TextAlign.right, style: TextStyle(fontSize: 15))
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // 8. MOTIVATION BANNER
  Widget _buildMotivationBanner() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 500;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.show_chart, color: Color(0xFFD97706), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Keep practicing to improve your rank!',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Consistent practice and mock tests are key to cracking ${_selectedExam == LeaderboardExam.neet ? 'NEET' : 'JEE'}. You\'re ahead of 8,716 students! 🔥 Beat 12 more to reach Top 5%.',
                          style: const TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                        ),
                      ],
                    ),
                  ),
                  if (!isMobile) ...[
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: Row(
                        children: const [
                          Text('View Progress', style: TextStyle(color: Color(0xFFB45309), fontWeight: FontWeight.w700, fontSize: 11)),
                          SizedBox(width: 4),
                          Icon(Icons.chevron_right, size: 14, color: Color(0xFFB45309)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              if (isMobile) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Loading practice targets for rank boost!'), duration: Duration(seconds: 2)),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFF59E0B)),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text('View Progress', style: TextStyle(color: Color(0xFFB45309), fontWeight: FontWeight.w700, fontSize: 12)),
                        SizedBox(width: 4),
                        Icon(Icons.chevron_right, size: 14, color: Color(0xFFB45309)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // 9. LEADERBOARD INSIGHTS SECTION
  Widget _buildLeaderboardInsights() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 640;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Leaderboard Insights', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
            const SizedBox(height: 12),
            if (isMobile) ...[
              _buildInsightCard(
                icon: Icons.people_outline,
                iconBg: const Color(0xFFEEF2FF),
                iconColor: const Color(0xFF4F46E5),
                title: 'Total Students',
                val: '12,845',
                sub: 'Who attempted this test',
              ),
              const SizedBox(height: 10),
              _buildInsightCard(
                icon: Icons.bar_chart_outlined,
                iconBg: const Color(0xFFE0F2FE),
                iconColor: const Color(0xFF0284C7),
                title: _selectedSystemMode == LeaderboardSystemMode.points ? 'Average Points' : 'Average Score',
                val: _selectedSystemMode == LeaderboardSystemMode.points ? '1,240 pts' : '${(_categoryMaxMarks * 0.52).round()} / $_categoryMaxMarks',
                sub: 'Average performance',
              ),
              const SizedBox(height: 10),
              _buildInsightCard(
                icon: Icons.track_changes,
                iconBg: const Color(0xFFDCFCE7),
                iconColor: const Color(0xFF15803D),
                title: _selectedSystemMode == LeaderboardSystemMode.points ? 'Top Points' : 'Top Score',
                val: _selectedSystemMode == LeaderboardSystemMode.points ? '1,800 pts' : '${(_categoryMaxMarks * 0.95).round()} / $_categoryMaxMarks',
                sub: 'By Aarav Sharma',
              ),
            ] else ...[
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
                      title: _selectedSystemMode == LeaderboardSystemMode.points ? 'Average Points' : 'Average Score',
                      val: _selectedSystemMode == LeaderboardSystemMode.points ? '1,240 pts' : '${(_categoryMaxMarks * 0.52).round()} / $_categoryMaxMarks',
                      sub: 'Average performance',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInsightCard(
                      icon: Icons.track_changes,
                      iconBg: const Color(0xFFDCFCE7),
                      iconColor: const Color(0xFF15803D),
                      title: _selectedSystemMode == LeaderboardSystemMode.points ? 'Top Points' : 'Top Score',
                      val: _selectedSystemMode == LeaderboardSystemMode.points ? '1,800 pts' : '${(_categoryMaxMarks * 0.95).round()} / $_categoryMaxMarks',
                      sub: 'By Aarav Sharma',
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
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
      padding: const EdgeInsets.all(12),
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
                Text(val, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                Text(sub, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 10. FAIR & TRANSPARENT FOOTER
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
                Text('Results are calculated based on accurate data and verified test attempts across Practice, Test Series, and PYQs.', style: TextStyle(fontSize: 11, color: Color(0xFF6D28D9))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
