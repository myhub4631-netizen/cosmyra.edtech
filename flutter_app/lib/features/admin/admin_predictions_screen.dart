import 'package:flutter/material.dart';
import '../../models/models.dart';

class AdminPredictionsScreen extends StatefulWidget {
  final UserProfileModel userProfile;

  const AdminPredictionsScreen({Key? key, required this.userProfile}) : super(key: key);

  @override
  State<AdminPredictionsScreen> createState() => _AdminPredictionsScreenState();
}

class _AdminPredictionsScreenState extends State<AdminPredictionsScreen> {
  // Sidebar accordion expansion state
  bool _paperPredictionExpanded = true;
  String _activeSubTab = 'All Papers';

  // Filter state
  String _selectedYear = 'Select Year';
  String _selectedSubject = 'Select Subject';
  String _selectedStatus = 'Select Status';
  String _searchQuery = '';

  // Form configuration state for selected paper
  int _selectedPaperIndex = 0;

  final List<Map<String, dynamic>> _predictionPapers = [
    {
      'title': 'NEET 2024 Paper Prediction Set - 1',
      'year': '2024',
      'set': '1',
      'subjects': ['Physics', 'Chemistry', 'Biology'],
      'questions': 180,
      'marks': 540,
      'duration': '3:20 Hrs',
      'status': 'Published',
      'statusColor': const Color(0xFF10B981),
      'statusBg': const Color(0xFFDCFCE7),
    },
    {
      'title': 'NEET 2024 Paper Prediction Set - 2',
      'year': '2024',
      'set': '2',
      'subjects': ['Physics', 'Chemistry', 'Biology'],
      'questions': 180,
      'marks': 540,
      'duration': '3:20 Hrs',
      'status': 'Published',
      'statusColor': const Color(0xFF10B981),
      'statusBg': const Color(0xFFDCFCE7),
    },
    {
      'title': 'NEET 2024 Paper Prediction Set - 3',
      'year': '2024',
      'set': '3',
      'subjects': ['Physics', 'Chemistry', 'Biology'],
      'questions': 180,
      'marks': 540,
      'duration': '3:20 Hrs',
      'status': 'Published',
      'statusColor': const Color(0xFF10B981),
      'statusBg': const Color(0xFFDCFCE7),
    },
    {
      'title': 'NEET 2024 Paper Prediction Set - 4',
      'year': '2024',
      'set': '4',
      'subjects': ['Physics', 'Chemistry', 'Biology'],
      'questions': 180,
      'marks': 540,
      'duration': '3:20 Hrs',
      'status': 'Draft',
      'statusColor': const Color(0xFFF59E0B),
      'statusBg': const Color(0xFFFEF3C7),
    },
    {
      'title': 'NEET 2023 Paper Prediction Set - 1',
      'year': '2023',
      'set': '1',
      'subjects': ['Physics', 'Chemistry', 'Biology'],
      'questions': 180,
      'marks': 540,
      'duration': '3:20 Hrs',
      'status': 'Published',
      'statusColor': const Color(0xFF10B981),
      'statusBg': const Color(0xFFDCFCE7),
    },
    {
      'title': 'NEET 2023 Paper Prediction Set - 2',
      'year': '2023',
      'set': '2',
      'subjects': ['Physics', 'Chemistry', 'Biology'],
      'questions': 180,
      'marks': 540,
      'duration': '3:20 Hrs',
      'status': 'Archived',
      'statusColor': const Color(0xFFEF4444),
      'statusBg': const Color(0xFFFEE2E2),
    },
    {
      'title': 'NEET 2022 Paper Prediction Set - 1',
      'year': '2022',
      'set': '1',
      'subjects': ['Physics', 'Chemistry', 'Biology'],
      'questions': 180,
      'marks': 540,
      'duration': '3:20 Hrs',
      'status': 'Published',
      'statusColor': const Color(0xFF10B981),
      'statusBg': const Color(0xFFDCFCE7),
    },
    {
      'title': 'NEET 2022 Paper Prediction Set - 2',
      'year': '2022',
      'set': '2',
      'subjects': ['Physics', 'Chemistry', 'Biology'],
      'questions': 180,
      'marks': 540,
      'duration': '3:20 Hrs',
      'status': 'Draft',
      'statusColor': const Color(0xFFF59E0B),
      'statusBg': const Color(0xFFFEF3C7),
    },
    {
      'title': 'NEET 2021 Paper Prediction Set - 1',
      'year': '2021',
      'set': '1',
      'subjects': ['Physics', 'Chemistry', 'Biology'],
      'questions': 180,
      'marks': 540,
      'duration': '3:20 Hrs',
      'status': 'Published',
      'statusColor': const Color(0xFF10B981),
      'statusBg': const Color(0xFFDCFCE7),
    },
    {
      'title': 'NEET 2021 Paper Prediction Set - 2',
      'year': '2021',
      'set': '2',
      'subjects': ['Physics', 'Chemistry', 'Biology'],
      'questions': 180,
      'marks': 540,
      'duration': '3:20 Hrs',
      'status': 'Archived',
      'statusColor': const Color(0xFFEF4444),
      'statusBg': const Color(0xFFFEE2E2),
    },
  ];

  // Paper Form Controls
  late TextEditingController _titleCtrl;
  late TextEditingController _descriptionCtrl;
  late TextEditingController _sortOrderCtrl;
  late TextEditingController _negativeMarksCtrl;

  bool _physicsChecked = true;
  bool _chemistryChecked = true;
  bool _biologyChecked = true;

  String _visibilityOption = 'Visible to All Users';
  bool _featuredToggle = true;

  bool _showSolutions = true;
  bool _showAnalysis = true;
  bool _allowDownload = true;
  bool _negativeMarking = true;
  bool _shuffleQuestions = false;
  bool _shuffleOptions = false;

  @override
  void initState() {
    super.initState();
    _loadPaperData(0);
  }

  void _loadPaperData(int index) {
    _selectedPaperIndex = index;
    final paper = _predictionPapers[index];
    _titleCtrl = TextEditingController(text: paper['title']);
    _descriptionCtrl = TextEditingController(text: 'This paper is based on latest pattern analysis and contains most important questions');
    _sortOrderCtrl = TextEditingController(text: '1');
    _negativeMarksCtrl = TextEditingController(text: '1');
  }

  void _addNewPaperModal() {
    final titleCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Add New Prediction Paper', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop()),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Paper Title',
                  hintText: 'e.g. NEET 2025 Prediction Set - 1',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (titleCtrl.text.isNotEmpty) {
                        setState(() {
                          _predictionPapers.insert(0, {
                            'title': titleCtrl.text,
                            'year': '2025',
                            'set': '1',
                            'subjects': ['Physics', 'Chemistry', 'Biology'],
                            'questions': 180,
                            'marks': 540,
                            'duration': '3:20 Hrs',
                            'status': 'Draft',
                            'statusColor': const Color(0xFFF59E0B),
                            'statusBg': const Color(0xFFFEF3C7),
                          });
                          _loadPaperData(0);
                        });
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Paper "${titleCtrl.text}" created!')));
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
                    child: const Text('Create Paper'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // 1. Dark Left Navigation Sidebar
          _buildDarkSidebar(),

          // 2. Main Content Body Area
          Expanded(
            child: Column(
              children: [
                // Top Header Bar
                _buildTopHeader(),

                // Scrollable Content Canvas
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title + Breadcrumb + Action Button
                        _buildPageHeaderRow(),
                        const SizedBox(height: 24),

                        // Top 4 Summary Metrics Cards
                        _buildSummaryMetricsCards(),
                        const SizedBox(height: 24),

                        // Filter Control Bar
                        _buildFilterControlBar(),
                        const SizedBox(height: 24),

                        // Prediction Papers Table Card
                        _buildPredictionPapersTable(),
                        const SizedBox(height: 32),

                        // Lower Detailed Configuration Panel (3 Columns + Advanced Options)
                        _buildDetailedConfigurationPanel(),
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

  // ================= 1. DARK LEFT SIDEBAR =================
  Widget _buildDarkSidebar() {
    return Container(
      width: 250,
      color: const Color(0xFF0B0F19),
      child: Column(
        children: [
          // App Brand Logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4F46E5)]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ExamPrep', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Admin Panel', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF1E293B), height: 1),

          // Nav Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 12, bottom: 8),
                  child: Text('MAIN', style: TextStyle(color: Color(0xFF475569), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                ),
                _buildNavItem(Icons.dashboard_outlined, 'Dashboard', false, onTap: () => Navigator.pushNamed(context, '/admin')),
                _buildNavItem(Icons.account_tree_outlined, 'Exam Hierarchy', false, onTap: () => Navigator.pushNamed(context, '/admin/hierarchy')),
                _buildNavItem(Icons.sell_outlined, 'Pricing & Plans', false, onTap: () => Navigator.pushNamed(context, '/admin/pricing')),
                _buildNavItem(Icons.leaderboard_outlined, 'Leaderboard', false, onTap: () => Navigator.pushNamed(context, '/admin/leaderboard')),
                _buildNavItem(Icons.play_circle_outline, 'Practice', false),

                // Active Accordion: Paper Prediction
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        dense: true,
                        horizontalTitleGap: 8,
                        leading: const Icon(Icons.note_alt_outlined, color: Colors.white, size: 18),
                        title: const Text('Paper Prediction', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        trailing: Icon(_paperPredictionExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.white, size: 18),
                        onTap: () => setState(() => _paperPredictionExpanded = !_paperPredictionExpanded),
                      ),
                      if (_paperPredictionExpanded) ...[
                        _buildSubNavItem('All Papers', _activeSubTab == 'All Papers'),
                        _buildSubNavItem('Add New Paper', false, onTap: _addNewPaperModal),
                        _buildSubNavItem('Categories', false),
                        _buildSubNavItem('Subjects', false),
                        _buildSubNavItem('Years', false),
                        const SizedBox(height: 6),
                      ],
                    ],
                  ),
                ),

                _buildNavItem(Icons.help_outline_rounded, 'Questions', false),
                _buildNavItem(Icons.bar_chart_outlined, 'Reports', false),
                _buildNavItem(Icons.show_chart_rounded, 'Analytics', false),
                _buildNavItem(Icons.payment_outlined, 'Payments', false),
                _buildNavItem(Icons.notifications_none_rounded, 'Notifications', false),
                _buildNavItem(Icons.local_offer_outlined, 'Offers & Coupons', false),
                _buildNavItem(Icons.article_outlined, 'Content', false),
                _buildNavItem(Icons.settings_outlined, 'Settings', false),
              ],
            ),
          ),

          // Upgrade to Pro Banner Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF4338CA)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle),
                  child: const Icon(Icons.emoji_events, color: Colors.white, size: 16),
                ),
                const SizedBox(height: 10),
                const Text('Upgrade to Pro', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text(
                  'Unlock advanced features and grow your platform.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFC7D2FE), fontSize: 10),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: const Text('Upgrade Now', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF1E293B) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        horizontalTitleGap: 8,
        leading: Icon(icon, color: isActive ? Colors.white : const Color(0xFF94A3B8), size: 18),
        title: Text(label, style: TextStyle(color: isActive ? Colors.white : const Color(0xFFCBD5E1), fontSize: 12.5)),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSubNavItem(String label, bool isActive, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(left: 36, right: 12, top: 2, bottom: 2),
      decoration: BoxDecoration(
        color: isActive ? Colors.white.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        title: Row(
          children: [
            Container(width: 4, height: 4, decoration: BoxDecoration(color: isActive ? Colors.white : const Color(0xFFA5B4FC), shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isActive ? Colors.white : const Color(0xFFE0E7FF), fontSize: 11.5, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
        onTap: onTap ?? () => setState(() => _activeSubTab = label),
      ),
    );
  }

  // ================= 2. TOP HEADER BAR =================
  Widget _buildTopHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          const Icon(Icons.menu, color: Color(0xFF64748B)),
          const SizedBox(width: 20),

          // Search Box
          Container(
            width: 320,
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.search, size: 16, color: Color(0xFF94A3B8)),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search anything...',
                      hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Notifications & Admin Avatar
          Row(
            children: [
              Stack(
                children: [
                  IconButton(icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF64748B), size: 22), onPressed: () {}),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: const Text('5', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              const CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage('https://i.pravatar.cc/100?img=33'),
              ),
              const SizedBox(width: 8),
              const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Admin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  Text('Super Admin', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= 3. PAGE TITLE & BREADCRUMB =================
  Widget _buildPageHeaderRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Paper Prediction', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            SizedBox(height: 4),
            Row(
              children: [
                Text('Dashboard', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                Text('  >  ', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                Text('Paper Prediction', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                Text('  >  ', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                Text('All Papers', style: TextStyle(fontSize: 11, color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _addNewPaperModal,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add New Prediction Paper', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  // ================= 4. SUMMARY METRICS CARDS =================
  Widget _buildSummaryMetricsCards() {
    return Row(
      children: [
        Expanded(child: _buildMetricCard('Total Papers', '128', 'All Prediction Papers', Icons.description_outlined, const Color(0xFF4F46E5), const Color(0xFFEEF2FF))),
        const SizedBox(width: 16),
        Expanded(child: _buildMetricCard('Published', '96', 'Visible to students', Icons.check_circle_outline, const Color(0xFF10B981), const Color(0xFFECFDF5))),
        const SizedBox(width: 16),
        Expanded(child: _buildMetricCard('Draft', '22', 'Saved as draft', Icons.access_time, const Color(0xFFF59E0B), const Color(0xFFFFFBEB))),
        const SizedBox(width: 16),
        Expanded(child: _buildMetricCard('Archived', '10', 'Not visible', Icons.delete_outline, const Color(0xFFEF4444), const Color(0xFFFEF2F2))),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, String sub, IconData icon, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              const SizedBox(height: 2),
              Text(sub, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
            ],
          ),
        ],
      ),
    );
  }

  // ================= 5. FILTER CONTROL BAR =================
  Widget _buildFilterControlBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // Search Input
          Expanded(
            flex: 3,
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFCBD5E1)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 16, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: const InputDecoration(
                        hintText: 'Search papers by title, set name...',
                        hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Year Dropdown
          Expanded(flex: 2, child: _buildDropdown(_selectedYear, ['Select Year', '2024', '2023', '2022', '2021'], (v) => setState(() => _selectedYear = v!))),
          const SizedBox(width: 12),

          // Subject Dropdown
          Expanded(flex: 2, child: _buildDropdown(_selectedSubject, ['Select Subject', 'Physics', 'Chemistry', 'Biology'], (v) => setState(() => _selectedSubject = v!))),
          const SizedBox(width: 12),

          // Status Dropdown
          Expanded(flex: 2, child: _buildDropdown(_selectedStatus, ['Select Status', 'Published', 'Draft', 'Archived'], (v) => setState(() => _selectedStatus = v!))),
          const SizedBox(width: 12),

          // Filters Button
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.tune, size: 14, color: Color(0xFF4F46E5)),
            label: const Text('Filters', style: TextStyle(fontSize: 12, color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEEF2FF),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 8),

          // Reset Button
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _selectedYear = 'Select Year';
                _selectedSubject = 'Select Subject';
                _selectedStatus = 'Select Status';
                _searchQuery = '';
              });
            },
            icon: const Icon(Icons.refresh_rounded, size: 14, color: Color(0xFF64748B)),
            label: const Text('Reset', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFCBD5E1)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ================= 6. PREDICTION PAPERS TABLE =================
  Widget _buildPredictionPapersTable() {
    final filteredPapers = _predictionPapers.where((paper) {
      final matchesSearch = paper['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesYear = _selectedYear == 'Select Year' || paper['year'] == _selectedYear;
      final matchesStatus = _selectedStatus == 'Select Status' || paper['status'] == _selectedStatus;
      return matchesSearch && matchesYear && matchesStatus;
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.all(18),
            child: Text('Prediction Papers (${filteredPapers.length})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          ),
          const Divider(height: 1),

          // Columns Header Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFFF8FAFC),
            child: const Row(
              children: [
                SizedBox(width: 40, child: Icon(Icons.check_box_outline_blank, size: 16, color: Colors.grey)),
                Expanded(flex: 5, child: Text('TITLE & SET', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                Expanded(flex: 4, child: Text('SUBJECTS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                Expanded(flex: 2, child: Text('YEAR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                Expanded(flex: 2, child: Text('QUESTIONS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                Expanded(flex: 2, child: Text('MARKS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                Expanded(flex: 2, child: Text('DURATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                Expanded(flex: 2, child: Text('STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                SizedBox(width: 100, child: Center(child: Text('ACTIONS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))))),
              ],
            ),
          ),
          const Divider(height: 1),

          // Paper List Rows
          ...List.generate(filteredPapers.length, (idx) => _buildPaperRow(filteredPapers[idx], idx)),

          const Divider(height: 1),

          // Footer Pagination Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                const Text('Show ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(border: Border.all(color: const Color(0xFFCBD5E1)), borderRadius: BorderRadius.circular(6)),
                  child: const Text('10 ∨', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const Text('  entries', style: TextStyle(fontSize: 12, color: Colors.grey)),

                const Spacer(),

                Row(
                  children: [
                    _buildPageBtn('<', false),
                    _buildPageBtn('1', true),
                    _buildPageBtn('2', false),
                    _buildPageBtn('3', false),
                    const Text(' ... ', style: TextStyle(color: Colors.grey)),
                    _buildPageBtn('13', false),
                    _buildPageBtn('>', false),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaperRow(Map<String, dynamic> paper, int index) {
    final isSelected = _selectedPaperIndex == index;

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _loadPaperData(index)),
          child: Container(
            color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const SizedBox(
                  width: 40,
                  child: Row(
                    children: [
                      Icon(Icons.check_box_outline_blank, size: 16, color: Color(0xFF94A3B8)),
                      SizedBox(width: 4),
                      Icon(Icons.drag_indicator, size: 14, color: Color(0xFFCBD5E1)),
                    ],
                  ),
                ),

                // Title
                Expanded(
                  flex: 5,
                  child: Text(paper['title'], style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                ),

                // Subjects Pills
                Expanded(
                  flex: 4,
                  child: Row(
                    children: (paper['subjects'] as List<String>).map((sub) {
                      Color color = const Color(0xFF3B82F6);
                      if (sub == 'Chemistry') color = const Color(0xFF0D9488);
                      if (sub == 'Biology') color = const Color(0xFF10B981);
                      return Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                        child: Text(sub, style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.bold)),
                      );
                    }).toList(),
                  ),
                ),

                // Year
                Expanded(flex: 2, child: Text(paper['year'], style: const TextStyle(fontSize: 12, color: Color(0xFF475569)))),

                // Questions
                Expanded(flex: 2, child: Text('${paper['questions']}', style: const TextStyle(fontSize: 12, color: Color(0xFF475569)))),

                // Marks
                Expanded(flex: 2, child: Text('${paper['marks']}', style: const TextStyle(fontSize: 12, color: Color(0xFF475569)))),

                // Duration
                Expanded(flex: 2, child: Text(paper['duration'], style: const TextStyle(fontSize: 12, color: Color(0xFF475569)))),

                // Status Badge
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: paper['statusBg'] as Color, borderRadius: BorderRadius.circular(12)),
                        child: Text(paper['status'], style: TextStyle(color: paper['statusColor'] as Color, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),

                // Actions
                SizedBox(
                  width: 100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(icon: const Icon(Icons.remove_red_eye_outlined, size: 15, color: Color(0xFF64748B)), onPressed: () {}),
                      IconButton(icon: const Icon(Icons.edit_outlined, size: 15, color: Color(0xFF64748B)), onPressed: () {}),
                      IconButton(icon: const Icon(Icons.more_horiz, size: 15, color: Color(0xFF64748B)), onPressed: () {}),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildPageBtn(String label, bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF4F46E5) : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isActive ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1)),
      ),
      child: Text(
        label,
        style: TextStyle(color: isActive ? Colors.white : const Color(0xFF475569), fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ================= 7. LOWER DETAILED CONFIGURATION PANEL =================
  Widget _buildDetailedConfigurationPanel() {
    return Column(
      children: [
        // 3 Column Configuration Cards
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Column 1: Paper Details
            Expanded(child: _buildPaperDetailsColumn()),
            const SizedBox(width: 20),

            // Column 2: Paper Status & Visibility
            Expanded(child: _buildPaperStatusVisibilityColumn()),
            const SizedBox(width: 20),

            // Column 3: Paper Settings
            Expanded(child: _buildPaperSettingsColumn()),
          ],
        ),
        const SizedBox(height: 24),

        // Advanced Options Row Grid
        _buildAdvancedOptionsGrid(),
        const SizedBox(height: 32),

        // Bottom Action Buttons Footer
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paper saved as Draft')));
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF4F46E5)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Save as Draft', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paper configuration updated successfully!')));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: const Text('Update Paper', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaperDetailsColumn() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Paper Details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Title', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                    Text(_titleCtrl.text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  ],
                ),
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Year', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                  Text('2024', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Set Number', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                  Text('1', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                ],
              ),
              Text('1', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 16),

          const Text('Description', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
          const SizedBox(height: 6),
          TextField(
            controller: _descriptionCtrl,
            maxLines: 3,
            style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
              contentPadding: const EdgeInsets.all(10),
            ),
          ),
          const SizedBox(height: 16),

          const Text('Subjects', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
          const SizedBox(height: 6),
          Row(
            children: [
              Checkbox(value: _physicsChecked, onChanged: (v) => setState(() => _physicsChecked = v!), activeColor: const Color(0xFF4F46E5)),
              const Text('Physics', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              Checkbox(value: _chemistryChecked, onChanged: (v) => setState(() => _chemistryChecked = v!), activeColor: const Color(0xFF4F46E5)),
              const Text('Chemistry', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              Checkbox(value: _biologyChecked, onChanged: (v) => setState(() => _biologyChecked = v!), activeColor: const Color(0xFF4F46E5)),
              const Text('Biology', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(child: _buildMetricMiniBadge('Total Questions', '180', Icons.description_outlined, const Color(0xFFEEF2FF), const Color(0xFF4F46E5))),
              const SizedBox(width: 8),
              Expanded(child: _buildMetricMiniBadge('Total Marks', '540', Icons.emoji_events_outlined, const Color(0xFFFEF3C7), const Color(0xFFF59E0B))),
              const SizedBox(width: 8),
              Expanded(child: _buildMetricMiniBadge('Duration', '3:20 Hrs', Icons.access_time_rounded, const Color(0xFFEEF2FF), const Color(0xFF3B82F6))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricMiniBadge(String label, String val, IconData icon, Color bg, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 8.5, color: Colors.grey)),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              Container(padding: const EdgeInsets.all(2), decoration: BoxDecoration(color: bg, shape: BoxShape.circle), child: Icon(icon, size: 10, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaperStatusVisibilityColumn() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Paper Status & Visibility', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
          const SizedBox(height: 16),

          const Text('Status', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
          const SizedBox(height: 4),
          _buildDropdown('Published', ['Published', 'Draft', 'Archived'], (v) {}),
          const SizedBox(height: 16),

          const Text('Visibility', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
          const SizedBox(height: 4),
          RadioListTile<String>(
            value: 'Visible to All Users',
            groupValue: _visibilityOption,
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Visible to All Users', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            activeColor: const Color(0xFF4F46E5),
            onChanged: (v) => setState(() => _visibilityOption = v!),
          ),
          RadioListTile<String>(
            value: 'Visible to Specific Users',
            groupValue: _visibilityOption,
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Visible to Specific Users', style: TextStyle(fontSize: 11)),
            activeColor: const Color(0xFF4F46E5),
            onChanged: (v) => setState(() => _visibilityOption = v!),
          ),
          RadioListTile<String>(
            value: 'Hide (Admin Only)',
            groupValue: _visibilityOption,
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Hide (Admin Only)', style: TextStyle(fontSize: 11)),
            activeColor: const Color(0xFF4F46E5),
            onChanged: (v) => setState(() => _visibilityOption = v!),
          ),
          const SizedBox(height: 12),

          const Text('Publish Date', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
          const SizedBox(height: 4),
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFFCBD5E1)), borderRadius: BorderRadius.circular(8)),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('12/05/2024 10:30 AM', style: TextStyle(fontSize: 11, color: Color(0xFF475569))),
                Icon(Icons.calendar_month_outlined, size: 16, color: Color(0xFF64748B)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Featured Paper', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              Switch(value: _featuredToggle, onChanged: (v) => setState(() => _featuredToggle = v), activeColor: const Color(0xFF4F46E5)),
            ],
          ),
          const SizedBox(height: 12),

          const Text('Sort Order', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
          const SizedBox(height: 4),
          TextField(
            controller: _sortOrderCtrl,
            style: const TextStyle(fontSize: 11),
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
          const SizedBox(height: 2),
          const Text('Lower numbers show first', style: TextStyle(fontSize: 9, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildPaperSettingsColumn() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Paper Settings', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
          const SizedBox(height: 16),

          _buildToggleRow('Show Solutions', 'Allow students to view solutions after attempt', _showSolutions, (v) => setState(() => _showSolutions = v)),
          const SizedBox(height: 10),
          _buildToggleRow('Show Analysis', 'Show detailed performance analysis', _showAnalysis, (v) => setState(() => _showAnalysis = v)),
          const SizedBox(height: 10),
          _buildToggleRow('Allow Download', 'Allow students to download PDF', _allowDownload, (v) => setState(() => _allowDownload = v)),
          const SizedBox(height: 10),
          _buildToggleRow('Negative Marking', 'Marks deducted for wrong answer', _negativeMarking, (v) => setState(() => _negativeMarking = v)),
          const SizedBox(height: 6),

          if (_negativeMarking) ...[
            const Text('Negative Marks', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
            const SizedBox(height: 4),
            TextField(
              controller: _negativeMarksCtrl,
              style: const TextStyle(fontSize: 11),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
            const SizedBox(height: 2),
            const Text('Marks deducted for wrong answer', style: TextStyle(fontSize: 9, color: Colors.grey)),
            const SizedBox(height: 10),
          ],

          _buildToggleRow('Shuffle Questions', 'Questions will be shuffled for each user', _shuffleQuestions, (v) => setState(() => _shuffleQuestions = v)),
          const SizedBox(height: 10),
          _buildToggleRow('Shuffle Options', 'Options will be shuffled for each user', _shuffleOptions, (v) => setState(() => _shuffleOptions = v)),
        ],
      ),
    );
  }

  Widget _buildToggleRow(String label, String sub, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              Text(sub, style: const TextStyle(fontSize: 9, color: Colors.grey)),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged, activeColor: const Color(0xFF4F46E5)),
      ],
    );
  }

  // ================= ADVANCED OPTIONS GRID =================
  Widget _buildAdvancedOptionsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Advanced Options', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildAdvCard('Add Instructions', 'Set paper instructions', Icons.article_outlined)),
            const SizedBox(width: 12),
            Expanded(child: _buildAdvCard('Add Tags', 'Add relevant tags', Icons.local_offer_outlined)),
            const SizedBox(width: 12),
            Expanded(child: _buildAdvCard('Attach Solutions', 'Upload solution PDF', Icons.file_present_outlined)),
            const SizedBox(width: 12),
            Expanded(child: _buildAdvCard('SEO Settings', 'Meta title & description', Icons.language_outlined)),
            const SizedBox(width: 12),
            Expanded(child: _buildAdvCard('Set Reminder', 'Notify users', Icons.notifications_active_outlined)),
            const SizedBox(width: 12),
            Expanded(child: _buildAdvCard('View Analytics', 'Paper performance', Icons.bar_chart_outlined)),
          ],
        ),
      ],
    );
  }

  Widget _buildAdvCard(String title, String sub, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: const Color(0xFF4F46E5)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                Text(sub, style: const TextStyle(fontSize: 8.5, color: Colors.grey), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
