import 'package:flutter/material.dart';

class MockTestsScreen extends StatefulWidget {
  final VoidCallback onStartTest;
  final VoidCallback? onTakeTestBanner;

  const MockTestsScreen({
    Key? key,
    required this.onStartTest,
    this.onTakeTestBanner,
  }) : super(key: key);

  @override
  State<MockTestsScreen> createState() => _MockTestsScreenState();
}

class _MockTestsScreenState extends State<MockTestsScreen> {
  int _selectedTab = 0; // 0: All Tests, 1: Full Test, 2: Chapter Test, 3: Subject Test
  String _selectedClass = 'Class 12';
  String _selectedExam = 'NEET';
  String _selectedSubject = 'All Subjects';

  final Set<int> _bookmarkedIndices = {};

  final List<Map<String, dynamic>> _mockTests = [
    {
      'title': 'NEET 2024 Mock Test - 1',
      'isLatest': true,
      'subjects': 'All Subjects',
      'syllabus': 'Full Syllabus',
      'questions': 180,
      'marks': 720,
      'duration': '3:20 Hrs',
      'badgeColor': const Color(0xFFDCFCE7),
      'iconColor': const Color(0xFF16A34A),
    },
    {
      'title': 'NEET 2024 Mock Test - 2',
      'isLatest': false,
      'subjects': 'All Subjects',
      'syllabus': 'Full Syllabus',
      'questions': 180,
      'marks': 720,
      'duration': '3:20 Hrs',
      'badgeColor': const Color(0xFFFFEDD5),
      'iconColor': const Color(0xFFEA580C),
    },
    {
      'title': 'NEET 2024 Mock Test - 3',
      'isLatest': false,
      'subjects': 'All Subjects',
      'syllabus': 'Full Syllabus',
      'questions': 180,
      'marks': 720,
      'duration': '3:20 Hrs',
      'badgeColor': const Color(0xFFF3E8FF),
      'iconColor': const Color(0xFF9333EA),
    },
    {
      'title': 'NEET 2024 Mock Test - 4',
      'isLatest': false,
      'subjects': 'All Subjects',
      'syllabus': 'Full Syllabus',
      'questions': 180,
      'marks': 720,
      'duration': '3:20 Hrs',
      'badgeColor': const Color(0xFFE0F2FE),
      'iconColor': const Color(0xFF0284C7),
    },
  ];

  void _showPreviewDialog(Map<String, dynamic> testData) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      testData['title'],
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildPreviewRow(Icons.help_outline, 'Total Questions', '${testData['questions']} MCQs'),
                    const SizedBox(height: 8),
                    _buildPreviewRow(Icons.emoji_events_outlined, 'Maximum Marks', '${testData['marks']} Marks'),
                    const SizedBox(height: 8),
                    _buildPreviewRow(Icons.timer_outlined, 'Duration', testData['duration']),
                    const SizedBox(height: 8),
                    _buildPreviewRow(Icons.menu_book_outlined, 'Syllabus', testData['syllabus']),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      child: const Text('Close', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        widget.onStartTest();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4338CA),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Start Test Now', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Color(0xFF1E1B4B), size: 24),
          onPressed: () {},
        ),
        title: const Text(
          'Mock Tests',
          style: TextStyle(
            color: Color(0xFF1E1B4B),
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Color(0xFF1E1B4B), size: 24),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HERO BANNER CARD
            _buildHeroBanner(),
            const SizedBox(height: 16),

            // 2. METRICS STATS ROW (4 Cards)
            _buildMetricsStatsRow(),
            const SizedBox(height: 20),

            // 3. SEGMENTED TAB BAR
            _buildSegmentedTabBar(),
            const SizedBox(height: 16),

            // 4. FILTER DROPDOWNS ROW
            _buildFilterDropdownsRow(),
            const SizedBox(height: 24),

            // 5. SECTION TITLE ROW
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Full Length Mock Tests',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                InkWell(
                  onTap: () {},
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 6. MOCK TEST CARDS LIST
            ...List.generate(_mockTests.length, (index) => _buildMockTestCard(_mockTests[index], index)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ================= 1. HERO BANNER =================
  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF3730A3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background Decorative Sparkles & Circles
            Positioned(
              top: -20,
              right: 60,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -40,
              right: 140,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.04),
                ),
              ),
            ),
            Positioned(
              top: 24,
              right: 150,
              child: Icon(Icons.star, color: Colors.white.withOpacity(0.4), size: 12),
            ),
            Positioned(
              bottom: 30,
              right: 20,
              child: Icon(Icons.star, color: Colors.white.withOpacity(0.3), size: 14),
            ),

            // Content Layout
            Padding(
              padding: const EdgeInsets.all(22.0),
              child: Row(
                children: [
                  // Left Text Column
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Assess Yourself.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        const Text(
                          'Improve Every Day.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Take full length mock tests simulating the real exam.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: widget.onTakeTestBanner ?? widget.onStartTest,
                          icon: const Text(
                            'Take a Test',
                            style: TextStyle(
                              color: Color(0xFF4338CA),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          label: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Color(0xFF4338CA),
                            size: 16,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF4338CA),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Right Vector Illustration Graphic
                  Expanded(
                    flex: 5,
                    child: SizedBox(
                      height: 140,
                      child: Stack(
                        alignment: Alignment.centerRight,
                        children: [
                          // Clipboard Illustration
                          Positioned(
                            right: 36,
                            top: 8,
                            child: Transform.rotate(
                              angle: -0.08,
                              child: Container(
                                width: 85,
                                height: 110,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.only(top: 20, left: 10, right: 10, bottom: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildCheckRow(true),
                                    const SizedBox(height: 6),
                                    _buildCheckRow(true),
                                    const SizedBox(height: 6),
                                    _buildCheckRow(true),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Clipboard Blue Top Clip
                          Positioned(
                            right: 64,
                            top: 4,
                            child: Container(
                              width: 28,
                              height: 12,
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          // Clock/Stopwatch Graphic
                          Positioned(
                            right: 0,
                            bottom: 10,
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(color: const Color(0xFF6366F1), width: 4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Clock Dial Hands
                                  Positioned(
                                    top: 14,
                                    child: Container(
                                      width: 2,
                                      height: 14,
                                      color: const Color(0xFF4F46E5),
                                    ),
                                  ),
                                  Positioned(
                                    right: 14,
                                    child: Container(
                                      width: 12,
                                      height: 2,
                                      color: const Color(0xFF4F46E5),
                                    ),
                                  ),
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF4F46E5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckRow(bool isChecked) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1),
            borderRadius: BorderRadius.circular(3),
          ),
          child: const Icon(Icons.check, size: 10, color: Colors.white),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }

  // ================= 2. METRICS STATS ROW =================
  Widget _buildMetricsStatsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard(
            icon: Icons.assignment_outlined,
            iconBg: const Color(0xFFE0F2FE),
            iconColor: const Color(0xFF0284C7),
            value: '32',
            label: 'Tests Taken',
          ),
          _buildStatCard(
            icon: Icons.speed_rounded,
            iconBg: const Color(0xFFFEF3C7),
            iconColor: const Color(0xFFD97706),
            value: '78%',
            label: 'Avg. Score',
          ),
          _buildStatCard(
            icon: Icons.trending_up_rounded,
            iconBg: const Color(0xFFDCFCE7),
            iconColor: const Color(0xFF16A34A),
            value: '1280',
            label: 'Best Score',
          ),
          _buildStatCard(
            icon: Icons.workspace_premium_outlined,
            iconBg: const Color(0xFFF3E8FF),
            iconColor: const Color(0xFF9333EA),
            value: '15',
            label: 'Hours Practiced',
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ================= 3. SEGMENTED TAB BAR =================
  Widget _buildSegmentedTabBar() {
    final tabs = ['All Tests', 'Full Test', 'Chapter Test', 'Subject Test'];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedTab == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  tabs[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ================= 4. FILTER DROPDOWNS ROW =================
  Widget _buildFilterDropdownsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildFilterDropdown(
            value: _selectedClass,
            items: const ['Class 11', 'Class 12', 'Dropper'],
            onChanged: (val) => setState(() => _selectedClass = val!),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildFilterDropdown(
            value: _selectedExam,
            items: const ['NEET', 'JEE Main', 'JEE Adv'],
            onChanged: (val) => setState(() => _selectedExam = val!),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 12,
          child: _buildFilterDropdown(
            value: _selectedSubject,
            items: const ['All Subjects', 'Physics', 'Chemistry', 'Biology'],
            onChanged: (val) => setState(() => _selectedSubject = val!),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE0E7FF)),
          ),
          child: const Icon(
            Icons.tune_rounded,
            color: Color(0xFF4F46E5),
            size: 18,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ================= 6. MOCK TEST CARDS =================
  Widget _buildMockTestCard(Map<String, dynamic> test, int index) {
    final isBookmarked = _bookmarkedIndices.contains(index);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Badge + Title + Bookmark
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: test['badgeColor'] as Color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.assignment_outlined,
                  color: test['iconColor'] as Color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            test['title'],
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (test['isLatest'] == true) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Latest',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF15803D),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${test['subjects']}  •  ${test['syllabus']}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                  color: isBookmarked ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8),
                  size: 22,
                ),
                onPressed: () {
                  setState(() {
                    if (isBookmarked) {
                      _bookmarkedIndices.remove(index);
                    } else {
                      _bookmarkedIndices.add(index);
                    }
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Info Meta Row: Questions, Marks, Duration
          Row(
            children: [
              _buildMetaItem(Icons.description_outlined, '${test['questions']} Qs'),
              const SizedBox(width: 20),
              _buildMetaItem(Icons.emoji_events_outlined, '${test['marks']} Marks'),
              const SizedBox(width: 20),
              _buildMetaItem(Icons.access_time_rounded, test['duration']),
            ],
          ),
          const SizedBox(height: 16),

          // Action Buttons: Preview & Start Test
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showPreviewDialog(test),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    side: const BorderSide(color: Color(0xFF818CF8)),
                  ),
                  child: const Text(
                    'Preview',
                    style: TextStyle(
                      color: Color(0xFF4F46E5),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.onStartTest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4338CA),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Start Test',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaItem(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF64748B)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            color: Color(0xFF475569),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
