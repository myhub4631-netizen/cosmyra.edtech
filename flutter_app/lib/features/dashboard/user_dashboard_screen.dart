import 'package:flutter/material.dart';
import '../../models/models.dart';

class UserDashboardScreen extends StatefulWidget {
  final UserProfileModel userProfile;
  final String activeExam;
  final VoidCallback onOpenPractice;
  final VoidCallback onOpenMockTests;
  final VoidCallback onOpenPyqs;
  final VoidCallback onOpenMistakes;

  const UserDashboardScreen({
    Key? key,
    required this.userProfile,
    required this.activeExam,
    required this.onOpenPractice,
    required this.onOpenMockTests,
    required this.onOpenPyqs,
    required this.onOpenMistakes,
  }) : super(key: key);

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  String _selectedExamFilter = 'NEET 2026';
  String _selectedDateRange = 'May 16 - May 22';
  String _performanceTab = 'Questions';
  String _leaderboardTab = 'Daily';
  int _activeSidebarIndex = 0;

  @override
  Widget build(BuildContext context) {
    final displayName = widget.userProfile.fullName.isNotEmpty
        ? widget.userProfile.fullName
        : 'Aman Kumar';

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. LEFT SIDEBAR NAVIGATION
          _buildSidebar(),

          // 2. MAIN CONTENT AREA
          Expanded(
            child: Column(
              children: [
                // Top Header Navbar
                _buildTopNavbar(displayName),

                // Main Scrollable Content Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome Banner Header Row
                        _buildWelcomeHeader(displayName),
                        const SizedBox(height: 24),

                        // Top 4 KPI Metrics Grid Row
                        _buildKpiMetricsGrid(),
                        const SizedBox(height: 28),

                        // Middle Section Row: Continue Where You Left Off + Today's Progress
                        _buildMiddleSectionRow(),
                        const SizedBox(height: 28),

                        // Quick Start Section Header + 5 Cards Grid Row
                        _buildQuickStartSection(),
                        const SizedBox(height: 28),

                        // Bottom Section Row: Performance Overview Line Chart + Leaderboard
                        _buildBottomSectionRow(displayName),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= 1. TOP NAVBAR HEADER =================
  Widget _buildTopNavbar(String displayName) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          // Logo Caps & Brand Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'ExamPrep',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'NEET | JEE',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF059669)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 24),
              IconButton(
                icon: const Icon(Icons.notes_rounded, color: Color(0xFF64748B), size: 22),
                onPressed: () {},
              ),
            ],
          ),

          const SizedBox(width: 32),

          // Search Bar Input Field
          Expanded(
            child: Container(
              height: 42,
              constraints: const BoxConstraints(maxWidth: 480),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search for questions, topics, tests...',
                        hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: const Text('Ctrl /', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 24),

          // Right Header Items: Streak + Notification + User Profile Badge
          Row(
            children: [
              // Flame Streak Counter Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFEDD5)),
                ),
                child: const Row(
                  children: [
                    Text('🔥', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('12', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFEA580C))),
                        Text('Day Streak', style: TextStyle(fontSize: 9, color: Color(0xFFC2410C), fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Notification Bell Icon with Badge
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF64748B), size: 24),
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
                      child: const Text(
                        '3',
                        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 16),

              // User Avatar & Name Pill
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFF2563EB),
                    child: Text(
                      displayName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        '${widget.activeExam} ${widget.userProfile.targetYear}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= 2. LEFT SIDEBAR NAVIGATION =================
  Widget _buildSidebar() {
    final navItems = [
      {'icon': Icons.dashboard_rounded, 'label': 'Dashboard', 'hasArrow': false},
      {'icon': Icons.track_changes_rounded, 'label': 'Practice', 'hasArrow': true},
      {'icon': Icons.edit_note_rounded, 'label': 'Custom Practice', 'hasArrow': false},
      {'icon': Icons.assignment_outlined, 'label': 'Custom Test', 'hasArrow': false},
      {'icon': Icons.menu_book_rounded, 'label': 'PYQ', 'hasArrow': true},
      {'icon': Icons.verified_user_outlined, 'label': 'NTA Questions', 'hasArrow': false},
      {'icon': Icons.bookmark_border_rounded, 'label': 'Bookmarks', 'hasArrow': false},
      {'icon': Icons.cancel_outlined, 'label': 'My Mistakes', 'hasArrow': false},
      {'icon': Icons.calendar_today_rounded, 'label': 'Test Series', 'hasArrow': false},
      {'icon': Icons.bar_chart_rounded, 'label': 'Analytics', 'hasArrow': true},
      {'icon': Icons.emoji_events_outlined, 'label': 'Leaderboard', 'hasArrow': false},
      {'icon': Icons.event_note_rounded, 'label': 'Study Plan', 'hasArrow': false},
      {'icon': Icons.person_outline_rounded, 'label': 'Profile', 'hasArrow': false},
      {'icon': Icons.settings_outlined, 'label': 'Settings', 'hasArrow': false},
      {'icon': Icons.help_outline_rounded, 'label': 'Help & Support', 'hasArrow': false},
      {'icon': Icons.logout_rounded, 'label': 'Logout', 'hasArrow': false},
    ];

    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Scrollable Sidebar Navigation List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: navItems.length,
              itemBuilder: (context, index) {
                final item = navItems[index];
                final isSelected = _activeSidebarIndex == index;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: InkWell(
                    onTap: () {
                      setState(() => _activeSidebarIndex = index);
                      if (index == 1 || index == 2) widget.onOpenPractice();
                      if (index == 3 || index == 8) widget.onOpenMockTests();
                      if (index == 4 || index == 5) widget.onOpenPyqs();
                      if (index == 6 || index == 7) widget.onOpenMistakes();
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFEEF2FF) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item['icon'] as IconData,
                            size: 18,
                            color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item['label'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF334155),
                              ),
                            ),
                          ),
                          if (item['hasArrow'] == true)
                            const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Premium Promo Banner Card
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text('👑', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 8),
                      Text(
                        'Go Premium',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Unlock unlimited tests, detailed analytics, and exclusive features.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Upgrade Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
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
    );
  }

  // ================= 3. WELCOME HEADER ROW =================
  Widget _buildWelcomeHeader(String displayName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Welcome back, ${displayName.split(" ").first}!',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.5),
                ),
                const SizedBox(width: 6),
                const Text('👋', style: TextStyle(fontSize: 22)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "Let's continue your ${widget.activeExam} ${widget.userProfile.targetYear} preparation.",
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w400),
            ),
          ],
        ),

        // Right Filter Action Pills
        Row(
          children: [
            // Exam Filter Dropdown Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.medical_services_outlined, size: 16, color: Color(0xFF10B981)),
                  const SizedBox(width: 8),
                  Text(
                    _selectedExamFilter,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Date Range Picker Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 8),
                  Text(
                    _selectedDateRange,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ================= 4. TOP 4 KPI METRICS GRID ROW =================
  Widget _buildKpiMetricsGrid() {
    final metrics = [
      {
        'title': 'Questions Attempted',
        'value': '1,248',
        'sub': '↑ 18% vs last week',
        'icon': Icons.edit_document,
        'cardBg': const Color(0xFFF0FDF4),
        'borderColor': const Color(0xFFDCFCE7),
        'titleColor': const Color(0xFF166534),
        'iconBg': const Color(0xFFDCFCE7),
        'iconColor': const Color(0xFF16A34A),
      },
      {
        'title': 'Accuracy',
        'value': '72.4%',
        'sub': '↑ 6.3% vs last week',
        'icon': Icons.track_changes_rounded,
        'cardBg': const Color(0xFFEFF6FF),
        'borderColor': const Color(0xFFDBEAFE),
        'titleColor': const Color(0xFF1E40AF),
        'iconBg': const Color(0xFFDBEAFE),
        'iconColor': const Color(0xFF2563EB),
      },
      {
        'title': 'Tests Completed',
        'value': '28',
        'sub': '↑ 4 vs last week',
        'icon': Icons.assignment_turned_in_rounded,
        'cardBg': const Color(0xFFF5F3FF),
        'borderColor': const Color(0xFFDDD6FE),
        'titleColor': const Color(0xFF5B21B6),
        'iconBg': const Color(0xFFDDD6FE),
        'iconColor': const Color(0xFF7C3AED),
      },
      {
        'title': 'Study Streak',
        'value': '12 Days',
        'sub': 'Best: 32 Days',
        'icon': Icons.local_fire_department_rounded,
        'cardBg': const Color(0xFFFFF7ED),
        'borderColor': const Color(0xFFFFEDD5),
        'titleColor': const Color(0xFF9A3412),
        'iconBg': const Color(0xFFFFEDD5),
        'iconColor': const Color(0xFFEA580C),
      },
    ];

    return Row(
      children: metrics.map((m) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: m['cardBg'] as Color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: m['borderColor'] as Color),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m['title'] as String,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: m['titleColor'] as Color),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      m['value'] as String,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      m['sub'] as String,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: m['iconBg'] as Color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(m['icon'] as IconData, color: m['iconColor'] as Color, size: 22),
                ),
              ],
            ),
          ),
        );
      }).toList()..removeLast(), // Clean spacing
    );
  }

  // ================= 5. MIDDLE SECTION ROW =================
  Widget _buildMiddleSectionRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Box: Continue Where You Left Off Card (Flexible width 6)
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Continue Where You Left Off', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    // Physics Arc Curve Illustration Box
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(Icons.show_chart_rounded, size: 40, color: Color(0xFF16A34A)),
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Text('V₀', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),

                    // Details & Progress Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Custom Practice • Physics', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          const Text('Kinematics - Basic Concepts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: const LinearProgressIndicator(
                                    value: 0.6,
                                    minHeight: 6,
                                    backgroundColor: Color(0xFFE2E8F0),
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text('60% Completed', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 20),

                    // Right Play Action Button
                    ElevatedButton.icon(
                      onPressed: widget.onOpenPractice,
                      icon: const Icon(Icons.play_arrow_rounded, size: 18, color: Colors.white),
                      label: const Text('Continue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 24),

        // Right Box: Today's Progress Card (Flexible width 4)
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Today's Progress", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  GestureDetector(
                    onTap: () {},
                    child: const Row(
                      children: [
                        Text('View Analytics', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2563EB))),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF2563EB)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    // Circular Gauge Chart Widget
                    const SizedBox(
                      width: 80,
                      height: 80,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: CircularProgressIndicator(
                              value: 0.65,
                              strokeWidth: 8,
                              backgroundColor: Color(0xFFE2E8F0),
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('65%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                              Text('Daily Goal', style: TextStyle(fontSize: 8, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 20),

                    // Progress Data Details Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Questions Attempted', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                              Text('65 / 100', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: const LinearProgressIndicator(
                              value: 0.65,
                              minHeight: 6,
                              backgroundColor: Color(0xFFE2E8F0),
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Accuracy', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                  SizedBox(height: 2),
                                  Text('74%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Time Spent', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                  SizedBox(height: 2),
                                  Text('2h 15m', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
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

  // ================= 6. QUICK START SECTION =================
  Widget _buildQuickStartSection() {
    final quickCards = [
      {
        'title': 'Custom Practice',
        'subtitle': 'Practice questions by selecting subjects, chapters & topics',
        'icon': Icons.track_changes_rounded,
        'color': Colors.green,
        'cardBg': const Color(0xFFF0FDF4),
        'borderColor': const Color(0xFFDCFCE7),
        'iconBg': const Color(0xFFDCFCE7),
        'onTap': widget.onOpenPractice,
      },
      {
        'title': 'Custom Test',
        'subtitle': 'Create a full-length test and evaluate your performance',
        'icon': Icons.assignment_outlined,
        'color': Colors.blue,
        'cardBg': const Color(0xFFEFF6FF),
        'borderColor': const Color(0xFFDBEAFE),
        'iconBg': const Color(0xFFDBEAFE),
        'onTap': widget.onOpenMockTests,
      },
      {
        'title': 'PYQ Practice',
        'subtitle': 'Practice previous year questions chapter-wise and year-wise',
        'icon': Icons.menu_book_rounded,
        'color': Colors.purple,
        'cardBg': const Color(0xFFF5F3FF),
        'borderColor': const Color(0xFFDDD6FE),
        'iconBg': const Color(0xFFDDD6FE),
        'onTap': widget.onOpenPyqs,
      },
      {
        'title': 'NTA Questions',
        'subtitle': 'Practice NTA pattern questions for better rank',
        'icon': Icons.shield_outlined,
        'color': Colors.orange,
        'cardBg': const Color(0xFFFFF7ED),
        'borderColor': const Color(0xFFFFEDD5),
        'iconBg': const Color(0xFFFFEDD5),
        'onTap': widget.onOpenPyqs,
      },
      {
        'title': 'Test Series',
        'subtitle': 'Attempt mock tests and improve your exam readiness',
        'icon': Icons.calendar_today_outlined,
        'color': Colors.pink,
        'cardBg': const Color(0xFFFDF2F8),
        'borderColor': const Color(0xFFFCE7F3),
        'iconBg': const Color(0xFFFCE7F3),
        'onTap': widget.onOpenMockTests,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Start', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        const SizedBox(height: 14),
        Row(
          children: quickCards.map((c) {
            final MaterialColor col = c['color'] as MaterialColor;
            return Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: InkWell(
                  onTap: c['onTap'] as VoidCallback,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              c['title'] as String,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: col.shade800),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: c['iconBg'] as Color,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(c['icon'] as IconData, size: 16, color: col.shade600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        c['subtitle'] as String,
                        style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
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

  // ================= 7. BOTTOM SECTION ROW =================
  Widget _buildBottomSectionRow(String displayName) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Performance Overview Line Chart (Flex 6)
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Performance Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Row(
                      children: [
                        Text('Last 7 Days', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                        SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Color(0xFF64748B)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    // Metric Selector Vertical Column
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: ['Questions', 'Accuracy', 'Time Spent', 'Tests'].map((tab) {
                        final isSelected = _performanceTab == tab;
                        return GestureDetector(
                          onTap: () => setState(() => _performanceTab = tab),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tab,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(width: 20),

                    // Custom Line Chart Graphics
                    Expanded(
                      child: SizedBox(
                        height: 180,
                        child: CustomPaint(
                          painter: SmoothLineChartPainter(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 24),

        // Right Column: Leaderboard (Daily) (Flex 4)
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Leaderboard (Daily)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  GestureDetector(
                    onTap: () {},
                    child: const Row(
                      children: [
                        Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2563EB))),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF2563EB)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    // Time Filter Tabs Header (Daily / Weekly / Monthly)
                    Row(
                      children: ['Daily', 'Weekly', 'Monthly'].map((t) {
                        final isSelected = _leaderboardTab == t;
                        return GestureDetector(
                          onTap: () => setState(() => _leaderboardTab = t),
                          child: Container(
                            margin: const EdgeInsets.only(right: 24),
                            padding: const EdgeInsets.only(bottom: 6),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Text(
                              t,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Table Columns Header Row
                    const Row(
                      children: [
                        SizedBox(width: 40, child: Text('Rank', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold))),
                        Expanded(child: Text('User', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold))),
                        SizedBox(width: 60, child: Text('Score', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold))),
                        SizedBox(width: 50, child: Text('Accuracy', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold))),
                      ],
                    ),
                    const Divider(height: 20, color: Color(0xFFF1F5F9)),

                    // Rank 1 Row (Gold)
                    _buildLeaderboardRow('🥇', 'Ritik Sharma', '8,420', '93.6%', false),
                    const SizedBox(height: 10),

                    // Rank 2 Row (Silver)
                    _buildLeaderboardRow('🥈', 'Ananya Singh', '7,850', '91.2%', false),
                    const SizedBox(height: 10),

                    // Rank 3 Row (Bronze)
                    _buildLeaderboardRow('🥉', 'Karan Verma', '7,120', '89.4%', false),
                    const SizedBox(height: 10),

                    // Current User Highlighted Row (Rank 15)
                    _buildLeaderboardRow('15', '$displayName (You)', '4,210', '72.4%', true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method for Leaderboard Table Row
  Widget _buildLeaderboardRow(String rank, String name, String score, String accuracy, bool isHighlighted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isHighlighted ? const Color(0xFFEEF2FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              rank,
              style: TextStyle(
                fontSize: rank.length > 2 ? 14 : 12,
                fontWeight: FontWeight.bold,
                color: isHighlighted ? const Color(0xFF2563EB) : const Color(0xFF475569),
              ),
            ),
          ),
          CircleAvatar(
            radius: 12,
            backgroundColor: isHighlighted ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
            child: Text(
              name.substring(0, 1),
              style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
                color: isHighlighted ? const Color(0xFF2563EB) : const Color(0xFF0F172A),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(score, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
          ),
          SizedBox(
            width: 50,
            child: Text(accuracy, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for Smooth Blue Line Chart
class SmoothLineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = const Color(0xFF2563EB)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintDot = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.fill;

    final paintWhiteDot = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final paintGrid = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1;

    // Horizontal Grid Lines & Y-Axis Labels
    final yLabels = ['120', '90', '60', '0'];
    final ySteps = yLabels.length - 1;
    for (int i = 0; i <= ySteps; i++) {
      final y = size.height * (i / ySteps);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }

    // Line Path Points
    final points = [
      Offset(size.width * 0.05, size.height * 0.70),
      Offset(size.width * 0.20, size.height * 0.60),
      Offset(size.width * 0.35, size.height * 0.50),
      Offset(size.width * 0.50, size.height * 0.45),
      Offset(size.width * 0.65, size.height * 0.52),
      Offset(size.width * 0.80, size.height * 0.65),
      Offset(size.width * 0.95, size.height * 0.48),
    ];

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paintLine);

    // Draw Data Dots & Active Tooltip Callout
    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      if (i == 3) {
        // Active dot with highlight
        canvas.drawCircle(pt, 6, paintLine);
        canvas.drawCircle(pt, 4, paintWhiteDot);
      } else {
        canvas.drawCircle(pt, 3.5, paintDot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
