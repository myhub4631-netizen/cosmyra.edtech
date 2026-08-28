import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../core/services/supabase_service.dart';
import 'pyq_practice_screen.dart';
import 'nta_paper_wise_screen.dart';

class NtaPracticeTestScreen extends StatefulWidget {
  final String activeExam;
  final Function(List<QuestionModel> questions, int timerMinutes, bool isTestMode)? onStartSession;
  final Function(List<QuestionModel> questions)? onStartPractice;

  const NtaPracticeTestScreen({
    Key? key,
    this.activeExam = 'NEET 2026',
    this.onStartSession,
    this.onStartPractice,
  }) : super(key: key);

  @override
  State<NtaPracticeTestScreen> createState() => _NtaPracticeTestScreenState();
}

class _NtaPracticeTestScreenState extends State<NtaPracticeTestScreen> {
  late String _selectedExam;
  String _selectedSubject = 'Physics';
  int _activeNavIndex = 1; // 1 = Practice Tab Selected

  // Stats loaded from Supabase DB
  int _questionsAttempted = 1248;
  double _averageAccuracy = 78.0;
  int _testsTaken = 32;
  String _totalTimeSpent = '56h 24m';

  int _chapterCount = 68;
  int _topicCount = 182;
  int _mockPaperCount = 20;

  bool _isLoading = false;
  bool _showSubScreen = false;
  String _currentMode = ''; // 'chapter_topic' or 'paper_wise'

  @override
  void initState() {
    super.initState();
    _selectedExam = widget.activeExam.contains('NEET') ? 'NEET 2026' : 'JEE Main 2026';
    _fetchLiveMetrics();
  }

  Future<void> _fetchLiveMetrics() async {
    setState(() => _isLoading = true);
    try {
      final cleanExam = _selectedExam.contains('JEE') ? 'JEE Main' : 'NEET';
      final chapters = await SupabaseService.fetchTaxonomyForSubject(
        exam: cleanExam,
        subject: _selectedSubject,
        forceRefresh: true,
      );

      final chCount = chapters.length;
      final tpCount = chapters.fold<int>(0, (sum, c) {
        final topics = (c['topicsList'] as List?) ?? [];
        return sum + topics.length;
      });

      final stats = await SupabaseService.fetchPYQStats(cleanExam);

      if (mounted) {
        setState(() {
          _chapterCount = chCount > 0 ? chCount : 68;
          _topicCount = tpCount > 0 ? tpCount : 182;
          if (stats['availableQuestions'] != null) {
            _questionsAttempted = stats['availableQuestions'];
          }
          if (stats['avgAccuracy'] != null) {
            _averageAccuracy = (stats['avgAccuracy'] as num).toDouble();
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onExamChanged(String? newExam) {
    if (newExam == null) return;
    setState(() {
      _selectedExam = newExam;
      if (newExam.contains('JEE')) {
        if (_selectedSubject == 'Biology') _selectedSubject = 'Physics';
      }
    });
    _fetchLiveMetrics();
  }

  void _onSubjectChanged(String? newSub) {
    if (newSub == null) return;
    setState(() {
      _selectedSubject = newSub;
    });
    _fetchLiveMetrics();
  }

  void _openChapterTopicWise() {
    setState(() {
      _currentMode = 'chapter_topic';
      _showSubScreen = true;
    });
  }

  void _openPaperWiseMockTests() {
    setState(() {
      _currentMode = 'paper_wise';
      _showSubScreen = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSubScreen) {
      if (_currentMode == 'paper_wise') {
        return NtaPaperWiseScreen(
          activeExam: _selectedExam,
          onBack: () => setState(() => _showSubScreen = false),
          onStartSession: (questions, timerMins, isTestMode) {
            if (widget.onStartSession != null) {
              widget.onStartSession!(questions, timerMins, isTestMode);
            }
          },
        );
      }

      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
            onPressed: () => setState(() => _showSubScreen = false),
          ),
          title: const Text(
            'Chapter & Topic-wise Practice',
            style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        body: PYQPracticeScreen(
          activeExam: _selectedExam.contains('JEE') ? 'JEE Main' : 'NEET',
          onStartPYQSession: (questions, timerMins, isTestMode) {
            if (widget.onStartSession != null) {
              widget.onStartSession!(questions, timerMins, isTestMode);
            }
          },
          onStartPractice: (questions, timerMins) {
            if (widget.onStartPractice != null) {
              widget.onStartPractice!(questions);
            }
          },
        ),
      );
    }

    final subjectsList = _selectedExam.contains('JEE')
        ? ['Physics', 'Chemistry', 'Mathematics']
        : ['Physics', 'Chemistry', 'Biology'];

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFD),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            _buildTopAppBar(),

            // Main Scrollable Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchLiveMetrics,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // Exam & Subject Selectors Row
                    _buildExamSubjectDropdowns(subjectsList),

                    const SizedBox(height: 22),

                    // Section: Choose Mode
                    const Text(
                      'Choose Mode',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Card 1: Chapter & Topic-wise
                    _buildModeCard(
                      title: 'Chapter & Topic-wise',
                      showRecommendedBadge: true,
                      description: 'Practice and test questions from chapters and topics',
                      metaText: '$_chapterCount Chapters • $_topicCount Topics',
                      iconData: Icons.menu_book_rounded,
                      iconColor: const Color(0xFF6366F1),
                      iconBgColor: Colors.white,
                      cardBgColor: const Color(0xFFF5F3FF),
                      borderColor: const Color(0xFFEEF2FF),
                      metaColor: const Color(0xFF6366F1),
                      onTap: _openChapterTopicWise,
                    ),

                    const SizedBox(height: 14),

                    // Card 2: Paper-wise (NTA Mock Papers)
                    _buildModeCard(
                      title: 'Paper-wise (NTA Mock Papers)',
                      showRecommendedBadge: false,
                      description: 'Attempt full or part NTA mock papers',
                      metaText: '$_mockPaperCount Papers Available',
                      iconData: Icons.description_outlined,
                      iconColor: const Color(0xFF16A34A),
                      iconBgColor: Colors.white,
                      cardBgColor: const Color(0xFFF0FDF4),
                      borderColor: const Color(0xFFDCFCE7),
                      metaColor: const Color(0xFF16A34A),
                      onTap: _openPaperWiseMockTests,
                    ),

                    const SizedBox(height: 24),

                    // Section: Quick Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Quick Stats',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'View All',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Quick Stats 4 Card Grid Row
                    _buildQuickStatsRow(),

                    const SizedBox(height: 26),

                    // Section: Recent Tests
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Tests',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'View All',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Recent Tests List Items
                    _buildRecentTestTile(
                      title: 'NTA Mock Paper 2',
                      subtitle: 'Full Syllabus  •  180 Questions',
                      score: '82%',
                      scoreColor: const Color(0xFF16A34A),
                      timeAgo: '2 days ago',
                      iconData: Icons.assignment_outlined,
                      iconColor: const Color(0xFF7C3AED),
                      iconBgColor: const Color(0xFFF3E8FF),
                    ),
                    _buildRecentTestTile(
                      title: 'Mechanics – Chapter Test',
                      subtitle: '25 Questions',
                      score: '76%',
                      scoreColor: const Color(0xFFEA580C),
                      timeAgo: '5 days ago',
                      iconData: Icons.show_chart_rounded,
                      iconColor: const Color(0xFFEA580C),
                      iconBgColor: const Color(0xFFFFEDD5),
                    ),
                    _buildRecentTestTile(
                      title: 'Oscillations & Waves – Topic Test',
                      subtitle: '20 Questions',
                      score: '68%',
                      scoreColor: const Color(0xFFD97706),
                      timeAgo: '1 week ago',
                      iconData: Icons.format_list_bulleted_rounded,
                      iconColor: const Color(0xFF2563EB),
                      iconBgColor: const Color(0xFFDBEAFE),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Bottom Navigation Bar
            _buildBottomNavigationBar(),
          ],
        ),
      ),
    );
  }

  // Header Bar
  Widget _buildTopAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: Color(0xFF0F172A), size: 24),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
          Column(
            children: const [
              Text(
                'NTA Practice & Test',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Practice and test with official NTA questions',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF0F172A), size: 24),
                onPressed: () {},
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: const Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Exam & Subject Dropdowns
  Widget _buildExamSubjectDropdowns(List<String> subjectsList) {
    return Row(
      children: [
        // Exam Dropdown
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEEF2FF)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedExam,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF4338CA), size: 20),
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF4338CA)),
                onChanged: _onExamChanged,
                items: ['NEET 2026', 'NEET 2025', 'JEE Main 2026', 'JEE Main 2025'].map((e) {
                  return DropdownMenuItem<String>(
                    value: e,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Exam', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.normal)),
                        Text(e, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF4338CA))),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Subject Dropdown
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEEF2FF)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedSubject,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF4338CA), size: 20),
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF4338CA)),
                onChanged: _onSubjectChanged,
                items: subjectsList.map((s) {
                  return DropdownMenuItem<String>(
                    value: s,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Subject', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.normal)),
                        Text(s, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF4338CA))),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Mode Selection Card Widget
  Widget _buildModeCard({
    required String title,
    required bool showRecommendedBadge,
    required String description,
    required String metaText,
    required IconData iconData,
    required Color iconColor,
    required Color iconBgColor,
    required Color cardBgColor,
    required Color borderColor,
    required Color metaColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Icon(iconData, color: iconColor, size: 26),
                ),
                const SizedBox(width: 14),

                // Card Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (showRecommendedBadge) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Recommended',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6366F1),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        metaText,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: metaColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Chevron Right
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Quick Stats Row
  Widget _buildQuickStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.help_outline_rounded,
            iconColor: const Color(0xFF7C3AED),
            iconBg: const Color(0xFFF3E8FF),
            value: _questionsAttempted >= 1000 ? '1,248' : '$_questionsAttempted',
            label: 'Questions\nAttempted',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            icon: Icons.task_alt_rounded,
            iconColor: const Color(0xFF16A34A),
            iconBg: const Color(0xFFDCFCE7),
            value: '${_averageAccuracy.toStringAsFixed(0)}%',
            label: 'Average\nAccuracy',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            icon: Icons.assignment_outlined,
            iconColor: const Color(0xFFEA580C),
            iconBg: const Color(0xFFFFEDD5),
            value: '$_testsTaken',
            label: 'Tests\nTaken',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            icon: Icons.access_time_rounded,
            iconColor: const Color(0xFF2563EB),
            iconBg: const Color(0xFFDBEAFE),
            value: _totalTimeSpent,
            label: 'Total Time\nSpent',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(color: Color(0x04000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  // Recent Test Tile
  Widget _buildRecentTestTile({
    required String title,
    required String subtitle,
    required String score,
    required Color scoreColor,
    required String timeAgo,
    required IconData iconData,
    required Color iconColor,
    required Color iconBgColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: _openPaperWiseMockTests,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Icon Avatar
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconData, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),

                // Title & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),

                // Right Side Stats & Chevron
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          score,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: scoreColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          timeAgo,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Bottom Navigation Bar
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1.0)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home_outlined, 'Home'),
          _buildNavItem(1, Icons.grid_view_rounded, 'Practice'),
          _buildNavItem(2, Icons.assignment_outlined, 'Test'),
          _buildNavItem(3, Icons.menu_book_outlined, 'PYQ'),
          _buildNavItem(4, Icons.person_outline_rounded, 'Profile'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSel = _activeNavIndex == index;
    return InkWell(
      onTap: () {
        setState(() => _activeNavIndex = index);
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFFF3E8FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSel ? const Color(0xFF6366F1) : const Color(0xFF64748B),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                color: isSel ? const Color(0xFF6366F1) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
