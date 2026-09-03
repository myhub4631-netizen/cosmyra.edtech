import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import '../../models/models.dart';
import '../../core/services/supabase_service.dart';
import '../../shared/widgets/latex_view.dart';
import '../../shared/utils/smooth_page_route.dart';
import 'admin_user_management_screen.dart';
import 'admin_questions_bank_dashboard.dart';
import 'admin_question_builder_screen.dart';
import 'admin_chapters_topics_screen.dart';
import 'admin_bulk_upload_step1_screen.dart';
import '../auth/login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final UserProfileModel userProfile;

  const AdminDashboardScreen({Key? key, required this.userProfile}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  String _activeTab = 'Dashboard';
  bool _isLoading = false;

  List<QuestionModel> _questionBank = [];
  List<ReportModel> _reports = [];

  final _searchController = TextEditingController();

  // CSV Import preview state
  List<List<dynamic>> _csvRowsPreview = [];
  List<String> _csvImportErrors = [];

  int _totalRealUsers = 0;

  Future<void> _handleLogout() async {
    await SupabaseService.logoutUserSession();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged out successfully.'),
          backgroundColor: Color(0xFF64748B),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);
    final questions = await SupabaseService.fetchQuestions(limit: 100);
    final reports = await SupabaseService.getReportedQuestions();
    final profiles = await SupabaseService.fetchAllProfiles();
    setState(() {
      _questionBank = questions;
      _reports = reports;
      _totalRealUsers = profiles.length;
      _isLoading = false;
    });
  }

  void _openQuestionEditor({QuestionModel? questionToEdit}) {
    final textCtrl = TextEditingController(text: questionToEdit?.questionText ?? '');
    final optACtrl = TextEditingController(text: questionToEdit != null && questionToEdit.options.isNotEmpty ? questionToEdit.options[0].optionText : '');
    final optBCtrl = TextEditingController(text: questionToEdit != null && questionToEdit.options.length > 1 ? questionToEdit.options[1].optionText : '');
    final optCCtrl = TextEditingController(text: questionToEdit != null && questionToEdit.options.length > 2 ? questionToEdit.options[2].optionText : '');
    final optDCtrl = TextEditingController(text: questionToEdit != null && questionToEdit.options.length > 3 ? questionToEdit.options[3].optionText : '');
    final explCtrl = TextEditingController(text: questionToEdit?.explanation ?? '');
    final solCtrl = TextEditingController(text: questionToEdit?.solution ?? '');

    int correctIndex = 2; // Default Option C
    String difficulty = questionToEdit?.difficulty ?? 'medium';
    String source = questionToEdit?.source ?? 'pyq';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 700,
            height: 750,
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      questionToEdit == null ? 'Create New Question' : 'Edit Question',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop()),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    children: [
                      // Question Text Input
                      TextField(
                        controller: textCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Question Text (Supports LaTeX e.g. \$E = mc^2\$)',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) => setDialogState(() {}),
                      ),
                      const SizedBox(height: 12),
                      const Text('Live LaTeX Preview:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.2)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: LaTeXView(text: textCtrl.text.isEmpty ? 'Question LaTeX preview will appear here...' : textCtrl.text),
                      ),
                      const SizedBox(height: 20),

                      // Options Inputs
                      TextField(controller: optACtrl, decoration: const InputDecoration(labelText: 'Option A')),
                      const SizedBox(height: 8),
                      TextField(controller: optBCtrl, decoration: const InputDecoration(labelText: 'Option B')),
                      const SizedBox(height: 8),
                      TextField(controller: optCCtrl, decoration: const InputDecoration(labelText: 'Option C')),
                      const SizedBox(height: 8),
                      TextField(controller: optDCtrl, decoration: const InputDecoration(labelText: 'Option D')),
                      const SizedBox(height: 16),

                      // Correct Answer Index Selection
                      Row(
                        children: [
                          const Text('Correct Answer: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 12),
                          DropdownButton<int>(
                            value: correctIndex,
                            items: const [
                              DropdownMenuItem(value: 0, child: Text('Option A')),
                              DropdownMenuItem(value: 1, child: Text('Option B')),
                              DropdownMenuItem(value: 2, child: Text('Option C')),
                              DropdownMenuItem(value: 3, child: Text('Option D')),
                            ],
                            onChanged: (val) {
                              if (val != null) setDialogState(() => correctIndex = val);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Explanation & Solution
                      TextField(controller: explCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Explanation')),
                      const SizedBox(height: 12),
                      TextField(controller: solCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Step-by-Step Solution')),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        final newQuestion = QuestionModel(
                          id: questionToEdit?.id ?? 'q-${DateTime.now().millisecondsSinceEpoch}',
                          examId: '11111111-1111-1111-1111-111111111111',
                          subjectId: 'a1111111-1111-1111-1111-111111111111',
                          chapterId: 'b1111111-1111-1111-1111-111111111111',
                          questionText: textCtrl.text,
                          qType: 'single_correct',
                          difficulty: difficulty,
                          source: source,
                          marks: 4.0,
                          negativeMarks: 1.0,
                          explanation: explCtrl.text,
                          solution: solCtrl.text,
                          options: [
                            QuestionOptionModel(id: 'o1', questionId: '', optionIndex: 0, optionText: optACtrl.text, isCorrect: correctIndex == 0),
                            QuestionOptionModel(id: 'o2', questionId: '', optionIndex: 1, optionText: optBCtrl.text, isCorrect: correctIndex == 1),
                            QuestionOptionModel(id: 'o3', questionId: '', optionIndex: 2, optionText: optCCtrl.text, isCorrect: correctIndex == 2),
                            QuestionOptionModel(id: 'o4', questionId: '', optionIndex: 3, optionText: optDCtrl.text, isCorrect: correctIndex == 3),
                          ],
                        );

                        await SupabaseService.saveQuestion(newQuestion);
                        Navigator.of(ctx).pop();
                        _loadAdminData();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Question saved successfully to Supabase!')));
                      },
                      child: const Text('Save & Publish Question'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndValidateCSV() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.single.bytes != null) {
        final csvString = utf8.decode(result.files.single.bytes!);
        List<List<dynamic>> rows = const CsvToListConverter().convert(csvString);

        List<String> errors = [];
        if (rows.isEmpty || rows.length < 2) {
          errors.add('CSV file is empty or missing headers.');
        } else {
          for (int i = 1; i < rows.length; i++) {
            final row = rows[i];
            if (row.length < 5) {
              errors.add('Row $i has insufficient columns.');
            }
          }
        }

        setState(() {
          _csvRowsPreview = rows;
          _csvImportErrors = errors;
        });
      }
    } catch (e) {
      debugPrint('CSV pick error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // 1. LEFT SIDEBAR NAVIGATION (Dark Navy #0B0F19)
          if (isDesktop) _buildAdminSidebar(),

          // 2. MAIN ADMIN DASHBOARD CONTENT AREA
          Expanded(
            child: Column(
              children: [
                // Top Header Bar
                _buildAdminHeader(),

                // Main Scrollable Dashboard Canvas
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title & Subtitle + Date Range Picker & Export Button Header
                        _buildTitleRow(),
                        const SizedBox(height: 20),

                        // Top 6 Metrics Cards Row
                        _buildTopMetricsRow(),
                        const SizedBox(height: 24),

                        // Middle Row: Donut Chart + Recent Activity Feed + Top Performing Exams
                        _buildMiddleOverviewRow(),
                        const SizedBox(height: 24),

                        // Bottom Charts Row: Question Attempts + Accuracy Trends + Difficulty Donut
                        _buildBottomChartsRow(),
                        const SizedBox(height: 28),

                        // Quick Management Grid (2x5 cards)
                        _buildQuickManagementSection(),
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

  // ================= 1. LEFT SIDEBAR =================
  Widget _buildAdminSidebar() {
    return Container(
      width: 240,
      color: const Color(0xFF0B0F19),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Logo & Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/cosmyra_logo.png',
                    height: 28,
                    fit: BoxFit.contain,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('ADMIN', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Sidebar Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildSidebarTile('Dashboard', Icons.dashboard_rounded, true, onTap: () => context.go('/admin')),
                
                const SizedBox(height: 16),
                _buildSidebarSectionLabel('CONTENT MANAGEMENT'),
                
                // Prominent Separate Primary Button for Upload Questions (Step 1)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/admin/questions/upload'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      elevation: 3,
                      shadowColor: const Color(0xFF4F46E5).withOpacity(0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.cloud_upload_rounded, size: 18, color: Colors.white),
                    label: const Text(
                      'Upload Questions (Step 1)',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                _buildSidebarTile('Test Series Manager', Icons.track_changes_rounded, false, onTap: () => context.go('/admin/test-series-manager')),
                _buildSidebarTile('Recommendation Manager', Icons.recommend_rounded, false, onTap: () => context.go('/admin/recommendations')),
                _buildSidebarTile('Paper Predictions', Icons.note_alt_outlined, false, onTap: () => context.go('/admin/predictions')),
                _buildSidebarTile('Question & Paper Bank', Icons.quiz_outlined, false, onTap: () => context.go('/admin/questions')),
                _buildSidebarTile('Upload Questions (Step 1)', Icons.cloud_upload_outlined, false, onTap: () => context.go('/admin/questions/upload')),
                _buildSidebarTile('CSV Bulk Import', Icons.upload_file_outlined, false, onTap: () => context.go('/admin/questions/upload')),
                _buildSidebarTile('Exam Hierarchy', Icons.account_tree_outlined, false, onTap: () => context.go('/admin/hierarchy')),
                _buildSidebarTile('Pricing & Plans', Icons.sell_outlined, false, onTap: () => context.go('/admin/pricing')),
                _buildSidebarTile('Coupon Management', Icons.discount_outlined, false, onTap: () => context.go('/admin/coupons')),
                _buildSidebarTile('Banner Management', Icons.view_carousel_rounded, false, onTap: () => context.go('/admin/banners')),
                _buildSidebarTile('Chapters & Topics', Icons.auto_stories_rounded, false, onTap: () => context.go('/admin/chapters')),
                _buildSidebarTile('Tags & Topics', Icons.label_outline_rounded, false, onTap: () => context.go('/admin/topics')),
                _buildSidebarTile('PYQs & Papers', Icons.description_outlined, false, onTap: () => context.go('/admin/papers')),
                _buildSidebarTile('Mistake Book', Icons.history_edu_outlined, false, onTap: () => context.go('/mistakes')),
                _buildSidebarTile('Bookmarks', Icons.bookmark_outline_rounded, false, onTap: () => context.go('/bookmarks')),

                const SizedBox(height: 16),
                _buildSidebarSectionLabel('USERS & ROLES'),
                _buildSidebarTile('User Management', Icons.people_outline_rounded, false, onTap: () => context.go('/admin/users')),
                _buildSidebarTile('Roles & Permissions', Icons.admin_panel_settings_outlined, false, onTap: () => context.go('/superadmin/roles')),
                _buildSidebarTile('Activity Logs', Icons.list_alt_rounded, false, onTap: () => context.go('/superadmin/audit-logs')),

                const SizedBox(height: 16),
                _buildSidebarSectionLabel('REPORTS & ANALYTICS'),
                _buildSidebarTile('Analytics Dashboard', Icons.bar_chart_rounded, false, onTap: () => context.go('/admin/analytics')),
                _buildSidebarTile('Question Reports', Icons.outlined_flag_rounded, false, onTap: () => context.go('/admin/questions')),
                _buildSidebarTile('Student Performance', Icons.insights_rounded, false, onTap: () => context.go('/admin/analytics')),
                _buildSidebarTile('Leaderboard', Icons.leaderboard_outlined, false, onTap: () => context.go('/admin/leaderboard')),

                const SizedBox(height: 16),
                _buildSidebarSectionLabel('WEBSITE & CMS MANAGER'),
                _buildSidebarTile('Page Manager (All Pages)', Icons.article_outlined, false, onTap: () => context.go('/admin/pages')),
                _buildSidebarTile('Blog & Articles', Icons.edit_note_rounded, false, onTap: () => context.go('/admin/blog')),
                _buildSidebarTile('Navigation & Menus', Icons.menu_open_rounded, false, onTap: () => context.go('/admin/navigation')),
                _buildSidebarTile('SEO & Tracking Manager', Icons.travel_explore_rounded, false, onTap: () => context.go('/admin/seo')),
                _buildSidebarTile('Privacy Policy (CMS)', Icons.policy_outlined, false, onTap: () => context.go('/admin/privacy-policy')),
                _buildSidebarTile('Terms of Service (CMS)', Icons.gavel_rounded, false, onTap: () => context.go('/admin/terms')),

                const SizedBox(height: 16),
                _buildSidebarSectionLabel('SYSTEM & SETTINGS'),
                _buildSidebarTile('System Settings', Icons.settings_outlined, false, onTap: () => context.go('/admin/settings')),
                _buildSidebarTile('Notification Center', Icons.notifications_none_rounded, false, onTap: () => context.go('/admin/notifications')),
                _buildSidebarTile('Backup & Restore', Icons.cloud_sync_outlined, false),
                _buildSidebarTile('Integrations', Icons.hub_outlined, false),

                const SizedBox(height: 24),
                // Need Help Card Widget
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [const Color(0xFF4F46E5).withOpacity(0.95), const Color(0xFF7C3AED).withOpacity(0.95)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.info_outline_rounded, color: Colors.amber, size: 16),
                              SizedBox(width: 6),
                              Text('Need Help?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                          InkWell(
                            onTap: () {},
                            child: const Icon(Icons.close, color: Colors.white70, size: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text('Check documentation', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          elevation: 0,
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('View Docs →', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // User Profile Footer with Working Logout Action
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage('https://i.pravatar.cc/100?img=33'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userProfile.fullName.trim().isNotEmpty ? widget.userProfile.fullName : 'Admin User',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.userProfile.isSuperAdmin ? 'Super Administrator' : 'Administrator',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 18),
                  tooltip: 'Logout',
                  onPressed: _handleLogout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8, top: 4),
      child: Text(
        label,
        style: const TextStyle(color: Color(0xFF475569), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
      ),
    );
  }



  Widget _buildSidebarTile(String title, IconData icon, bool isActive, {bool hasDropdown = false, bool isExpanded = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () => setState(() => _activeTab = title),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF4F46E5) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isActive ? Colors.white : const Color(0xFF94A3B8)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isActive ? Colors.white : const Color(0xFFCBD5E1),
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
            if (hasDropdown)
              Icon(
                isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: isActive ? Colors.white : const Color(0xFF64748B),
              ),
          ],
        ),
      ),
    );
  }

  // ================= 2. TOP HEADER BAR =================
  Widget _buildAdminHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          // Search Input Bar
          Expanded(
            child: Container(
              height: 38,
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search questions, topics, users, reports...',
                        hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: const Text('⌘ K', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),

          // Header Right Actions
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _openQuestionEditor(),
                icon: const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFF4F46E5)),
                label: const Text('Quick Actions', style: TextStyle(color: Color(0xFF4F46E5), fontSize: 12, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE0E7FF)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(icon: const Icon(Icons.dark_mode_outlined, size: 20, color: Color(0xFF64748B)), onPressed: () {}),
              Stack(
                children: [
                  IconButton(icon: const Icon(Icons.notifications_none_rounded, size: 22, color: Color(0xFF64748B)), onPressed: () {}),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: const Text('8', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
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
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userProfile.fullName.trim().isNotEmpty ? widget.userProfile.fullName : 'Admin User',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    widget.userProfile.isSuperAdmin ? 'Super Administrator' : 'Administrator',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout_rounded, size: 14, color: Color(0xFFEF4444)),
                label: const Text('Logout', style: TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFEE2E2)),
                  backgroundColor: const Color(0xFFFEF2F2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= 3. TITLE & DATE RANGE ROW =================
  Widget _buildTitleRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Admin Control Dashboard', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            SizedBox(height: 2),
            Text("Welcome back! Here's what's happening with your Cosmyra platform.", style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          ],
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF64748B)),
                  SizedBox(width: 8),
                  Text('Aug 17 - Aug 24, 2026', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                  SizedBox(width: 6),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.file_download_outlined, size: 16, color: Color(0xFF4F46E5)),
              label: const Text('Export Report', style: TextStyle(color: Color(0xFF4F46E5), fontSize: 12, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE0E7FF)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ================= 4. TOP 6 METRICS CARDS ROW =================
  Widget _buildTopMetricsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth > 1200 ? 6 : (constraints.maxWidth > 800 ? 3 : 2);
        return GridView.count(
          crossAxisCount: count,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.8,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildMetricCard(
              title: 'Total Students',
              value: '$_totalRealUsers',
              trend: '↑ Live synced',
              subtext: '100% real Supabase profiles',
              icon: Icons.people_outline_rounded,
              iconColor: const Color(0xFF6366F1),
              trendColor: const Color(0xFF10B981),
            ),
            _buildMetricCard(
              title: 'Total Questions',
              value: '54,200',
              trend: '↑ 8.4%',
              subtext: '8400 PYQs · 12,500 NTA',
              icon: Icons.layers_outlined,
              iconColor: const Color(0xFF10B981),
              trendColor: const Color(0xFF10B981),
            ),
            _buildMetricCard(
              title: "Today's Attempts",
              value: '3,290',
              trend: '↑ 18.6%',
              subtext: 'Peak: 1,200 attempts/hr',
              icon: Icons.show_chart_rounded,
              iconColor: const Color(0xFF3B82F6),
              trendColor: const Color(0xFF10B981),
            ),
            _buildMetricCard(
              title: 'Accuracy Rate',
              value: '84.5%',
              trend: '↑ 2.3%',
              subtext: 'Average this week',
              icon: Icons.adjust_rounded,
              iconColor: const Color(0xFF0D9488),
              trendColor: const Color(0xFF10B981),
            ),
            _buildMetricCard(
              title: 'Pending Reports',
              value: '5',
              trend: 'Requires attention',
              subtext: '',
              icon: Icons.outlined_flag_rounded,
              iconColor: const Color(0xFFEF4444),
              trendColor: const Color(0xFFEF4444),
            ),
            _buildMetricCard(
              title: 'System Health',
              value: '99.9%',
              trend: 'All systems operational',
              subtext: '',
              icon: Icons.verified_user_outlined,
              iconColor: const Color(0xFF10B981),
              trendColor: const Color(0xFF10B981),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String trend,
    required String subtext,
    required IconData icon,
    required Color iconColor,
    required Color trendColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: iconColor, size: 16),
              ),
            ],
          ),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          Row(
            children: [
              Text(trend, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: trendColor)),
              if (subtext.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(subtext, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ================= 5. MIDDLE OVERVIEW ROW =================
  Widget _buildMiddleOverviewRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Donut Chart: Question Bank Overview
        Expanded(
          flex: 4,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(SmoothPageRoute(child: AdminQuestionsBankDashboard(userProfile: widget.userProfile)));
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Question Bank Overview', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      const Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF4F46E5)),
                    ],
                  ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    SizedBox(
                      height: 160,
                      width: 160,
                      child: Stack(
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 3,
                              centerSpaceRadius: 55,
                              sections: [
                                PieChartSectionData(color: const Color(0xFF8B5CF6), value: 22.9, radius: 18, showTitle: false),
                                PieChartSectionData(color: const Color(0xFF10B981), value: 20.7, radius: 18, showTitle: false),
                                PieChartSectionData(color: const Color(0xFF3B82F6), value: 19.9, radius: 18, showTitle: false),
                                PieChartSectionData(color: const Color(0xFFEC4899), value: 16.9, radius: 18, showTitle: false),
                                PieChartSectionData(color: const Color(0xFFF59E0B), value: 19.4, radius: 18, showTitle: false),
                              ],
                            ),
                          ),
                          const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('54,200', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text('Total Questions', style: TextStyle(fontSize: 9, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        children: [
                          _buildLegendRow('Physics', '12,450 (22.9%)', const Color(0xFF8B5CF6)),
                          _buildLegendRow('Chemistry', '11,230 (20.7%)', const Color(0xFF10B981)),
                          _buildLegendRow('Botany', '10,800 (19.9%)', const Color(0xFF3B82F6)),
                          _buildLegendRow('Zoology', '9,200 (16.9%)', const Color(0xFFEC4899)),
                          _buildLegendRow('Mathematics', '10,520 (19.4%)', const Color(0xFFF59E0B)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),

        const SizedBox(width: 16),

        // Recent Activity Feed
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Recent Activity', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    TextButton(onPressed: () {}, child: const Text('View All', style: TextStyle(fontSize: 12, color: Color(0xFF4F46E5)))),
                  ],
                ),
                const SizedBox(height: 12),
                _buildActivityTile('Admin User', 'Imported 2,450 questions via CSV', '2 min ago', Icons.description_outlined, const Color(0xFF10B981)),
                _buildActivityTile('System', 'Automated backup completed', '15 min ago', Icons.cloud_done_outlined, const Color(0xFF8B5CF6)),
                _buildActivityTile('Moderator', 'Reviewed 120 questions', '1 hour ago', Icons.person_outline, const Color(0xFF3B82F6)),
                _buildActivityTile('Admin User', 'Created new topic: Organic Chemistry', '2 hours ago', Icons.edit_note_outlined, const Color(0xFFF59E0B)),
                _buildActivityTile('System', 'Weekly analytics report generated', '3 hours ago', Icons.assessment_outlined, const Color(0xFF6366F1)),
              ],
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Top Performing Exams
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Top Performing Exams', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    TextButton(onPressed: () {}, child: const Text('View All', style: TextStyle(fontSize: 12, color: Color(0xFF4F46E5)))),
                  ],
                ),
                const SizedBox(height: 12),
                _buildExamPerformanceRow('NEET UG 2026 Mock Test 15', 'Avg Score: 612/720', '85.0%', const Color(0xFF10B981), Icons.medical_services_outlined, const Color(0xFF10B981)),
                _buildExamPerformanceRow('JEE Main 2025 Paper 8', 'Avg Score: 285/300', '82.3%', const Color(0xFF10B981), Icons.school_outlined, const Color(0xFF8B5CF6)),
                _buildExamPerformanceRow('JEE Advanced 2025 Mock 7', 'Avg Score: 598/720', '80.6%', const Color(0xFF10B981), Icons.shield_outlined, const Color(0xFFF59E0B)),
                _buildExamPerformanceRow('NEET UG 2025 Full Test 24', 'Avg Score: 598/720', '78.9%', const Color(0xFF10B981), Icons.medical_services_outlined, const Color(0xFF10B981)),
                _buildExamPerformanceRow('NEET UG 2026 Chapter Test', 'Avg Score: 156/180', '77.3%', const Color(0xFF10B981), Icons.article_outlined, const Color(0xFF3B82F6)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendRow(String title, String detail, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(detail, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildActivityTile(String author, String text, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$author: $text', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamPerformanceRow(String name, String avgScore, String percent, Color percentColor, IconData icon, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                Text(avgScore, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          Text(percent, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: percentColor)),
        ],
      ),
    );
  }

  // ================= 6. BOTTOM CHARTS ROW =================
  Widget _buildBottomChartsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chart 1: Question Attempts (This Week)
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Question Attempts (This Week)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    Text('This Week ∨', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 140,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) {
                              const d = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                              if (val.toInt() >= 0 && val.toInt() < d.length) {
                                return Text(d[val.toInt()], style: const TextStyle(fontSize: 10, color: Colors.grey));
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: const [
                            FlSpot(0, 1200),
                            FlSpot(1, 900),
                            FlSpot(2, 1850),
                            FlSpot(3, 1100),
                            FlSpot(4, 1600),
                            FlSpot(5, 1750),
                            FlSpot(6, 1300),
                          ],
                          isCurved: true,
                          color: const Color(0xFF6366F1),
                          barWidth: 2.5,
                          dotData: const FlDotData(show: true),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Chart 2: Accuracy Trends (This Week)
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Accuracy Trends (This Week)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    Text('This Week ∨', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 140,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) {
                              const d = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                              if (val.toInt() >= 0 && val.toInt() < d.length) {
                                return Text(d[val.toInt()], style: const TextStyle(fontSize: 10, color: Colors.grey));
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: const [
                            FlSpot(0, 70),
                            FlSpot(1, 62),
                            FlSpot(2, 68),
                            FlSpot(3, 75),
                            FlSpot(4, 85.2),
                            FlSpot(5, 78),
                            FlSpot(6, 82),
                          ],
                          isCurved: true,
                          color: const Color(0xFF10B981),
                          barWidth: 2.5,
                          dotData: const FlDotData(show: true),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Donut 3: Difficulty Distribution
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Difficulty Distribution', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(
                      height: 120,
                      width: 120,
                      child: Stack(
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 3,
                              centerSpaceRadius: 40,
                              sections: [
                                PieChartSectionData(color: const Color(0xFF10B981), value: 23.7, radius: 14, showTitle: false),
                                PieChartSectionData(color: const Color(0xFF3B82F6), value: 46.9, radius: 14, showTitle: false),
                                PieChartSectionData(color: const Color(0xFFEF4444), value: 21.9, radius: 14, showTitle: false),
                                PieChartSectionData(color: const Color(0xFF8B5CF6), value: 5.5, radius: 14, showTitle: false),
                              ],
                            ),
                          ),
                          const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('54,200', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('Total Questions', style: TextStyle(fontSize: 8, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          _buildLegendRow('Easy', '12,850 (23.7%)', const Color(0xFF10B981)),
                          _buildLegendRow('Medium', '25,450 (46.9%)', const Color(0xFF3B82F6)),
                          _buildLegendRow('Hard', '11,900 (21.9%)', const Color(0xFFEF4444)),
                          _buildLegendRow('Mixed', '3,000 (5.5%)', const Color(0xFF8B5CF6)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ================= 7. QUICK MANAGEMENT SECTION (10 CARDS) =================
  Widget _buildQuickManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Management', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width >= 1200 ? 5 : 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildQuickActionCard('Questions Bank', 'Manage & organize all question modules', Icons.quiz_outlined, const Color(0xFF4F46E5), () async {
              await Navigator.of(context).push(SmoothPageRoute(child: AdminQuestionsBankDashboard(userProfile: widget.userProfile)));
              _loadAdminData();
            }),
            _buildQuickActionCard('Add New Question', 'Create single question', Icons.add_circle_outline_rounded, const Color(0xFF6366F1), () async {
              await Navigator.of(context).push(SmoothPageRoute(child: AdminQuestionBuilderScreen(userProfile: widget.userProfile)));
              _loadAdminData();
            }),
            _buildQuickActionCard('Bulk Import Questions', 'Upload via CSV/Excel', Icons.cloud_upload_outlined, const Color(0xFF10B981), () {
              Navigator.of(context).push(SmoothPageRoute(child: AdminQuestionsBankDashboard(userProfile: widget.userProfile)));
            }),
            _buildQuickActionCard('Manage Topics', 'Create & organize topics', Icons.folder_open_outlined, const Color(0xFFF59E0B), () {}),
            _buildQuickActionCard('Paper Predictions', 'Manage prediction sets & PYQs', Icons.note_alt_outlined, const Color(0xFFEC4899), () => Navigator.pushNamed(context, '/admin/predictions')),
            _buildQuickActionCard('User Management', 'Manage students & roles', Icons.people_outline_rounded, const Color(0xFF3B82F6), () {
              Navigator.of(context).push(SmoothPageRoute(child: AdminUserManagementScreen(userProfile: widget.userProfile)));
            }),
            _buildQuickActionCard('Question Reports', 'View detailed reports', Icons.bar_chart_rounded, const Color(0xFF8B5CF6), () {}),
            _buildQuickActionCard('Performance Analytics', 'Detailed performance data', Icons.trending_up_rounded, const Color(0xFF0D9488), () {}),
            _buildQuickActionCard('System Settings', 'Configure platform settings', Icons.settings_outlined, const Color(0xFF64748B), () {}),
            _buildQuickActionCard('Backup & Restore', 'Data backup management', Icons.backup_outlined, const Color(0xFF3B82F6), () {}),
            _buildQuickActionCard('Notification Center', 'Send announcements', Icons.notifications_active_outlined, const Color(0xFFF59E0B), () {}, badgeCount: 3),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap, {int? badgeCount}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (badgeCount != null)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: Text('$badgeCount', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A)), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
