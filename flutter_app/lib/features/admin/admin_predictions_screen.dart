import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/models.dart';

class AdminPredictionsScreen extends StatefulWidget {
  final UserProfileModel userProfile;

  const AdminPredictionsScreen({Key? key, required this.userProfile}) : super(key: key);

  @override
  State<AdminPredictionsScreen> createState() => _AdminPredictionsScreenState();
}

class _AdminPredictionsScreenState extends State<AdminPredictionsScreen> {
  String _selectedExamFilter = 'All Exams';
  String _selectedYearFilter = 'All Years';
  String _selectedStatusFilter = 'All Status';
  String _selectedTypeFilter = 'All Types';
  String _searchQuery = '';
  String _sortBy = 'Latest First';

  final List<Map<String, dynamic>> _predictions = [
    {
      'title': 'NEET UG Prediction - 24 May 2025',
      'tag': "Today's Prediction",
      'tagColor': const Color(0xFF10B981),
      'exam': 'NEET UG',
      'examColor': const Color(0xFF8B5CF6),
      'date': '24 May 2025',
      'type': 'Daily',
      'accuracy': '68 – 72%',
      'attempts': '2,842',
      'status': 'Published',
      'statusColor': const Color(0xFF10B981),
      'icon': Icons.person_outline,
    },
    {
      'title': 'NEET UG Prediction - 25 May 2025',
      'tag': 'Tomorrow',
      'tagColor': const Color(0xFF3B82F6),
      'exam': 'NEET UG',
      'examColor': const Color(0xFF8B5CF6),
      'date': '25 May 2025',
      'type': 'Daily',
      'accuracy': '-',
      'attempts': '-',
      'status': 'Scheduled',
      'statusColor': const Color(0xFFF59E0B),
      'icon': Icons.calendar_today_outlined,
    },
    {
      'title': 'NEET UG Prediction - 26 May 2025',
      'tag': 'Upcoming',
      'tagColor': const Color(0xFF10B981),
      'exam': 'NEET UG',
      'examColor': const Color(0xFF8B5CF6),
      'date': '26 May 2025',
      'type': 'Daily',
      'accuracy': '-',
      'attempts': '-',
      'status': 'Scheduled',
      'statusColor': const Color(0xFFF59E0B),
      'icon': Icons.edit_calendar_outlined,
    },
    {
      'title': 'JEE Main Prediction - 26 May 2025',
      'tag': 'Upcoming',
      'tagColor': const Color(0xFFF59E0B),
      'exam': 'JEE Main',
      'examColor': const Color(0xFF3B82F6),
      'date': '26 May 2025',
      'type': 'Daily',
      'accuracy': '-',
      'attempts': '-',
      'status': 'Scheduled',
      'statusColor': const Color(0xFFF59E0B),
      'icon': Icons.description_outlined,
    },
    {
      'title': 'NEET UG Prediction - 10 May 2025',
      'tag': '',
      'tagColor': Colors.transparent,
      'exam': 'NEET UG',
      'examColor': const Color(0xFF8B5CF6),
      'date': '10 May 2025',
      'type': 'Daily',
      'accuracy': '70 – 74%',
      'attempts': '5,231',
      'status': 'Completed',
      'statusColor': const Color(0xFF0D9488),
      'icon': Icons.hexagon_outlined,
    },
    {
      'title': 'JEE Main Prediction - 09 May 2025',
      'tag': '',
      'tagColor': Colors.transparent,
      'exam': 'JEE Main',
      'examColor': const Color(0xFF3B82F6),
      'date': '09 May 2025',
      'type': 'Daily',
      'accuracy': '69 – 73%',
      'attempts': '4,892',
      'status': 'Completed',
      'statusColor': const Color(0xFF0D9488),
      'icon': Icons.camera_alt_outlined,
    },
    {
      'title': 'NEET UG Prediction - 2024 (Analysis)',
      'tag': '',
      'tagColor': Colors.transparent,
      'exam': 'NEET UG',
      'examColor': const Color(0xFF8B5CF6),
      'date': '12 May 2024',
      'type': 'Yearly',
      'accuracy': '72.8%',
      'attempts': '8,231',
      'status': 'Completed',
      'statusColor': const Color(0xFF0D9488),
      'icon': Icons.star_border_rounded,
    },
    {
      'title': 'JEE Main Prediction - 2024 (Analysis)',
      'tag': '',
      'tagColor': Colors.transparent,
      'exam': 'JEE Main',
      'examColor': const Color(0xFF3B82F6),
      'date': '12 Apr 2024',
      'type': 'Yearly',
      'accuracy': '73.6%',
      'attempts': '7,926',
      'status': 'Completed',
      'statusColor': const Color(0xFF0D9488),
      'icon': Icons.star_border_rounded,
    },
  ];

  void _openCreatePredictionModal() {
    final titleCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Create Paper Prediction Set', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop()),
                ],
              ),
              const SizedBox(height: 16),
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Prediction Title (e.g. NEET 2026 Expected Questions)')),
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
                          _predictions.insert(0, {
                            'title': titleCtrl.text,
                            'tag': 'Upcoming',
                            'tagColor': const Color(0xFF10B981),
                            'exam': 'NEET UG',
                            'examColor': const Color(0xFF8B5CF6),
                            'date': 'Tomorrow',
                            'type': 'Daily',
                            'accuracy': '-',
                            'attempts': '-',
                            'status': 'Scheduled',
                            'statusColor': const Color(0xFFF59E0B),
                            'icon': Icons.auto_awesome_outlined,
                          });
                        });
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Prediction "${titleCtrl.text}" created!')));
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
                    child: const Text('Create Prediction'),
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
      body: Column(
        children: [
          // Top Header Bar
          _buildAdminHeader(),

          // Main Scrollable Body Canvas
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Breadcrumb + Title Row
                  _buildBreadcrumbAndTitleRow(),
                  const SizedBox(height: 24),

                  // Top 6 Metrics Cards Row
                  _buildTopMetricsRow(),
                  const SizedBox(height: 24),

                  // Main Content Area: Left (Filters + Table) & Right (Analytics & Quick Actions Stack)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Section: Filters + Predictions Table
                      Expanded(
                        flex: 8,
                        child: Column(
                          children: [
                            _buildFilterControlCard(),
                            const SizedBox(height: 20),
                            _buildPredictionsTableCard(),
                          ],
                        ),
                      ),

                      const SizedBox(width: 20),

                      // Right Section: Accuracy Trend + Exam Wise + Top Performers + Quick Actions
                      SizedBox(
                        width: 320,
                        child: Column(
                          children: [
                            _buildAccuracyTrendCard(),
                            const SizedBox(height: 20),
                            _buildExamWiseAccuracyCard(),
                            const SizedBox(height: 20),
                            _buildTopPerformingPredictionsCard(),
                            const SizedBox(height: 20),
                            _buildQuickActionsCard(),
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
      ),
    );
  }

  // ================= 1. TOP HEADER BAR =================
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
          const Icon(Icons.menu, color: Color(0xFF64748B)),
          const SizedBox(width: 20),

          // Search Input Bar
          Expanded(
            child: Container(
              height: 38,
              constraints: const BoxConstraints(maxWidth: 460),
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
                        hintText: 'Search students, tests, questions...',
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

          // Header Right Icons & Avatar
          Row(
            children: [
              Stack(
                children: [
                  IconButton(icon: const Icon(Icons.notifications_none_rounded, size: 22, color: Color(0xFF64748B)), onPressed: () {}),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: const Text('12', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              Stack(
                children: [
                  IconButton(icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20, color: Color(0xFF64748B)), onPressed: () {}),
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
              IconButton(icon: const Icon(Icons.help_outline_rounded, size: 20, color: Color(0xFF64748B)), onPressed: () {}),
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
                  Text('Mahboob Hasan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Text('Super Admin', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= 2. BREADCRUMB & TITLE ROW =================
  Widget _buildBreadcrumbAndTitleRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text('Dashboard', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            Text('  >  ', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            Text('Paper Prediction', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            Text('  >  ', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            Text('Manage Predictions', style: TextStyle(fontSize: 11, color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Paper Prediction Management', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                SizedBox(height: 2),
                Text('Create, manage and analyze NEET & JEE Main paper predictions', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              ],
            ),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.settings_outlined, size: 16, color: Color(0xFF4F46E5)),
                  label: const Text('Prediction Settings', style: TextStyle(fontSize: 12, color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.upload_file_outlined, size: 16, color: Color(0xFF4F46E5)),
                  label: const Text('Import Questions', style: TextStyle(fontSize: 12, color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _openCreatePredictionModal,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Create New Prediction', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ================= 3. TOP 6 METRICS CARDS ROW =================
  Widget _buildTopMetricsRow() {
    return Row(
      children: [
        Expanded(child: _buildMetricCard('Total Predictions', '156', 'across all exams', '↑ 12 this month', Icons.emoji_events_outlined, const Color(0xFF8B5CF6))),
        const SizedBox(width: 12),
        Expanded(child: _buildMetricCard('Average Accuracy', '68.7%', 'All time average', '↑ 5.3% vs last month', Icons.track_changes_outlined, const Color(0xFF10B981))),
        const SizedBox(width: 12),
        Expanded(child: _buildMetricCard('Total Attempts', '24,582', 'Across all predictions', '↑ 18.6% this month', Icons.calculate_outlined, const Color(0xFF3B82F6))),
        const SizedBox(width: 12),
        Expanded(child: _buildMetricCard('Students Participated', '8,732', 'Unique students', '↑ 14.2% this month', Icons.star_border_rounded, const Color(0xFFF59E0B))),
        const SizedBox(width: 12),
        Expanded(child: _buildMetricCardWithLink('Top Accuracy (NEET)', '72.8%', 'NEET UG 2024', Icons.emoji_events_outlined, const Color(0xFFEC4899))),
        const SizedBox(width: 12),
        Expanded(child: _buildMetricCardWithLink('Top Accuracy (JEE)', '73.6%', 'JEE Main 2024', Icons.emoji_events_outlined, const Color(0xFF8B5CF6))),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, String sub1, String sub2, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          Text(sub1, style: const TextStyle(fontSize: 9.5, color: Colors.grey)),
          const SizedBox(height: 6),
          Text(sub2, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
        ],
      ),
    );
  }

  Widget _buildMetricCardWithLink(String title, String value, String sub, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontSize: 9.5, color: Colors.grey)),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
            child: const Text('View details', style: TextStyle(fontSize: 10, color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ================= 4. FILTER CONTROL PANEL CARD =================
  Widget _buildFilterControlCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(child: _buildFilterDropdown('Exam', _selectedExamFilter, ['All Exams', 'NEET UG', 'JEE Main'], (v) => setState(() => _selectedExamFilter = v!))),
          const SizedBox(width: 10),
          Expanded(child: _buildFilterDropdown('Year', _selectedYearFilter, ['All Years', '2025', '2024'], (v) => setState(() => _selectedYearFilter = v!))),
          const SizedBox(width: 10),
          Expanded(child: _buildFilterDropdown('Status', _selectedStatusFilter, ['All Status', 'Published', 'Scheduled', 'Completed'], (v) => setState(() => _selectedStatusFilter = v!))),
          const SizedBox(width: 10),
          Expanded(child: _buildFilterDropdown('Type', _selectedTypeFilter, ['All Types', 'Daily', 'Yearly'], (v) => setState(() => _selectedTypeFilter = v!))),
          const SizedBox(width: 12),

          // Search Input
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 14),
                Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, size: 16, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          onChanged: (v) => setState(() => _searchQuery = v),
                          decoration: const InputDecoration(
                            hintText: 'Search prediction title...',
                            hintStyle: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          Column(
            children: [
              const SizedBox(height: 14),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.filter_alt_outlined, size: 14, color: Color(0xFF4F46E5)),
                    label: const Text('Filter', style: TextStyle(fontSize: 11, color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Reset', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFCBD5E1)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  // ================= 5. PREDICTIONS TABLE CARD =================
  Widget _buildPredictionsTableCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Table Card Header Row
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('All Predictions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(10)),
                      child: const Text('156', style: TextStyle(color: Color(0xFF4F46E5), fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text('Sort by: ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFCBD5E1)), borderRadius: BorderRadius.circular(6)),
                      child: const Text('Latest First ∨', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.format_list_bulleted_rounded, size: 18, color: Color(0xFF4F46E5)),
                    const SizedBox(width: 8),
                    const Icon(Icons.grid_view_rounded, size: 18, color: Color(0xFF94A3B8)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Table Headers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFFF8FAFC),
            child: const Row(
              children: [
                Expanded(flex: 4, child: Text('PREDICTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                Expanded(flex: 2, child: Text('EXAM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                Expanded(flex: 2, child: Text('DATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                Expanded(flex: 2, child: Text('TYPE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                Expanded(flex: 2, child: Text('ACCURACY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                Expanded(flex: 2, child: Text('ATTEMPTS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                Expanded(flex: 2, child: Text('STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                SizedBox(width: 110, child: Center(child: Text('ACTIONS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))))),
              ],
            ),
          ),
          const Divider(height: 1),

          // Prediction Rows
          ..._predictions
              .where((p) => p['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase()))
              .map((row) => _buildPredictionRow(row))
              .toList(),

          const Divider(height: 1),

          // Pagination Footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Showing 1 to 8 of 156 predictions', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                Row(
                  children: [
                    _buildPageBtn('<', false),
                    _buildPageBtn('1', true),
                    _buildPageBtn('2', false),
                    _buildPageBtn('3', false),
                    _buildPageBtn('4', false),
                    _buildPageBtn('5', false),
                    const Text(' ... ', style: TextStyle(color: Colors.grey)),
                    _buildPageBtn('16', false),
                    _buildPageBtn('>', false),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFCBD5E1)), borderRadius: BorderRadius.circular(6)),
                      child: const Text('10 / page ∨', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionRow(Map<String, dynamic> row) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Prediction Title & Badge Icon
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(8)),
                      child: Icon(row['icon'] as IconData, size: 16, color: const Color(0xFF4F46E5)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(row['title'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          if (row['tag'].toString().isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: (row['tagColor'] as Color).withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                              child: Text(row['tag'], style: TextStyle(color: row['tagColor'] as Color, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Exam
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: (row['examColor'] as Color).withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                      child: Text(row['exam'], style: TextStyle(color: row['examColor'] as Color, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              // Date
              Expanded(flex: 2, child: Text(row['date'], style: const TextStyle(fontSize: 11, color: Color(0xFF475569)))),

              // Type
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                      child: Text(row['type'], style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),

              // Accuracy
              Expanded(
                flex: 2,
                child: Text(
                  row['accuracy'],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: row['accuracy'] != '-' ? const Color(0xFF10B981) : Colors.grey,
                  ),
                ),
              ),

              // Attempts
              Expanded(flex: 2, child: Text(row['attempts'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),

              // Status Badge
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: (row['statusColor'] as Color).withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 4, height: 4, decoration: BoxDecoration(color: row['statusColor'] as Color, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          Text(row['status'], style: TextStyle(color: row['statusColor'] as Color, fontSize: 9.5, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Actions
              SizedBox(
                width: 110,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(icon: const Icon(Icons.remove_red_eye_outlined, size: 14, color: Color(0xFF4F46E5)), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.bar_chart_rounded, size: 14, color: Color(0xFF4F46E5)), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.edit_outlined, size: 14, color: Color(0xFF64748B)), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.more_vert_rounded, size: 14, color: Color(0xFF64748B)), onPressed: () {}),
                  ],
                ),
              ),
            ],
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

  // ================= 6. RIGHT SIDEBAR ANALYTICS CARDS =================
  Widget _buildAccuracyTrendCard() {
    return Container(
      padding: const EdgeInsets.all(18),
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
              Text('Accuracy Trend (Last 6 Months)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              Text('All Exams ∨', style: TextStyle(fontSize: 9.5, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 16),

          // Line Chart
          SizedBox(
            height: 120,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final titles = ['Dec \'24', 'Jan \'25', 'Feb \'25', 'Mar \'25', 'Apr \'25', 'May \'25'];
                        if (val.toInt() >= 0 && val.toInt() < titles.length) {
                          return Text(titles[val.toInt()], style: const TextStyle(fontSize: 8, color: Colors.grey));
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 58),
                      FlSpot(1, 68),
                      FlSpot(2, 74),
                      FlSpot(3, 62),
                      FlSpot(4, 68),
                      FlSpot(5, 85),
                    ],
                    isCurved: true,
                    color: const Color(0xFF4F46E5),
                    barWidth: 2,
                    dotData: FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
            child: const Text('View Full Analytics →', style: TextStyle(fontSize: 11, color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildExamWiseAccuracyCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Exam Wise Accuracy', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 14),

          Row(
            children: [
              // Donut Chart
              SizedBox(
                width: 90,
                height: 90,
                child: Stack(
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 28,
                        sections: [
                          PieChartSectionData(color: const Color(0xFF4F46E5), value: 69.2, radius: 10, showTitle: false),
                          PieChartSectionData(color: const Color(0xFF3B82F6), value: 67.8, radius: 10, showTitle: false),
                          PieChartSectionData(color: const Color(0xFFF59E0B), value: 54.1, radius: 10, showTitle: false),
                        ],
                      ),
                    ),
                    const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('68.7%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          Text('Overall', style: TextStyle(fontSize: 7, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Legend
              const Expanded(
                child: Column(
                  children: [
                    _LegendRow('NEET UG', '69.2%', Color(0xFF4F46E5)),
                    SizedBox(height: 6),
                    _LegendRow('JEE Main', '67.8%', Color(0xFF3B82F6)),
                    SizedBox(height: 6),
                    _LegendRow('Others', '54.1%', Color(0xFFF59E0B)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
            child: const Text('View Detailed Report →', style: TextStyle(fontSize: 11, color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPerformingPredictionsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
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
              const Text('Top Performing Predictions', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              TextButton(onPressed: () {}, child: const Text('View All', style: TextStyle(fontSize: 10, color: Color(0xFF4F46E5), fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 10),
          _buildTopRow('🥇', 'NEET UG Prediction 2024', '72.8%'),
          _buildTopRow('🥈', 'JEE Main Prediction 2024', '73.6%'),
          _buildTopRow('🥉', 'NEET UG Prediction - 10 May 2025', '70.5%'),
        ],
      ),
    );
  }

  Widget _buildTopRow(String medal, String title, String acc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(medal, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)), overflow: TextOverflow.ellipsis)),
          Text(acc, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Actions', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildQuickBtn('Create Daily Prediction', Icons.calendar_today_outlined, _openCreatePredictionModal)),
              const SizedBox(width: 8),
              Expanded(child: _buildQuickBtn('Add Questions', Icons.add, () {})),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildQuickBtn('Send Notification', Icons.send_outlined, () {})),
              const SizedBox(width: 8),
              Expanded(child: _buildQuickBtn('View Student Results', Icons.bar_chart_rounded, () {})),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickBtn(String label, IconData icon, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 12, color: const Color(0xFF4F46E5)),
      label: Text(label, style: const TextStyle(fontSize: 9.5, color: Color(0xFF334155), fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFCBD5E1)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final String label;
  final String percent;
  final Color color;

  const _LegendRow(this.label, this.percent, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
          ],
        ),
        Text(percent, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
      ],
    );
  }
}
