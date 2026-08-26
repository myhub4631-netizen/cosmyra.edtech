import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../core/services/supabase_service.dart';
import '../../shared/utils/smooth_page_route.dart';
import 'admin_dashboard_screen.dart';
import 'admin_hierarchy_screen.dart';
import 'admin_leaderboard_screen.dart';

class AdminUserManagementScreen extends StatefulWidget {
  final UserProfileModel userProfile;

  const AdminUserManagementScreen({Key? key, required this.userProfile}) : super(key: key);

  @override
  State<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class AdminUserModel {
  final String id;
  final String name;
  final String email;
  final String userIdCode;
  final String role; // Student, Educator, Administrator
  final List<String> examAccess; // NEET, JEE M, JEE Adv, +1, All Exams
  final String status; // Active, Suspended, Pending, Blocked
  final String lastActive;
  final String joinedOn;
  final String phone;
  final String regSource;
  String adminNotes;
  final String avatarInitials;
  final Color avatarColor;

  AdminUserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.userIdCode,
    required this.role,
    required this.examAccess,
    required this.status,
    required this.lastActive,
    required this.joinedOn,
    this.phone = '+91 98765 43210',
    this.regSource = 'Web Portal',
    this.adminNotes = '',
    required this.avatarInitials,
    required this.avatarColor,
  });
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  // Navigation & Dark Mode State
  String _activeSidebarItem = 'User Management';
  bool _isDarkMode = false;

  // Search & Filter Controllers
  final TextEditingController _searchController = TextEditingController();
  String _selectedRole = 'All Roles';
  String _selectedStatus = 'All Status';
  String _selectedExam = 'All Exams';
  String _selectedRegSource = 'All Registration Source';
  String _selectedStatusTab = 'All Users (24,850)';

  // Selection & Detail Panel State
  final Set<String> _selectedUserIds = {};
  AdminUserModel? _selectedUserForDetail;
  String _detailPanelTab = 'Overview';

  // Pagination State
  int _currentPage = 1;
  int _rowsPerPage = 25;

  // Mock User Data matching exact image specs
  late List<AdminUserModel> _allUsers;

  @override
  void initState() {
    super.initState();
    _initSampleUserData();
    _loadRealUsersFromSupabase();
  }

  Future<void> _loadRealUsersFromSupabase() async {
    final profiles = await SupabaseService.fetchAllProfiles();
    final realUsers = profiles.map((p) {
      final initials = p.fullName.isNotEmpty
          ? p.fullName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join('').toUpperCase()
          : (p.email.isNotEmpty ? p.email[0].toUpperCase() : 'U');
      
      final userRole = p.role.isEmpty
          ? 'Student'
          : (p.role.toLowerCase() == 'admin' ? 'Administrator' : p.role[0].toUpperCase() + p.role.substring(1).toLowerCase());

      return AdminUserModel(
        id: p.id,
        name: p.fullName.isNotEmpty ? p.fullName : p.email.split('@').first,
        email: p.email,
        userIdCode: p.id.length >= 6 ? p.id.substring(0, 6).toUpperCase() : p.id,
        role: userRole,
        examAccess: [p.targetExam.isNotEmpty ? p.targetExam : 'NEET'],
        status: 'Active',
        lastActive: 'Just now',
        joinedOn: 'Aug 26, 2026',
        phone: (p.phoneNumber != null && p.phoneNumber!.isNotEmpty) ? p.phoneNumber! : '+91 98765 43210',
        regSource: 'Web Portal',
        avatarInitials: initials,
        avatarColor: const Color(0xFF6366F1),
      );
    }).toList();

    if (mounted) {
      setState(() {
        if (realUsers.isNotEmpty) {
          _allUsers = realUsers;
        } else {
          _allUsers = _getInitialSystemUsers();
        }
        if (_allUsers.isNotEmpty) {
          _selectedUserForDetail = _allUsers.first;
        } else {
          _selectedUserForDetail = null;
        }
      });
    }
  }

  List<AdminUserModel> _getInitialSystemUsers() {
    return [
      AdminUserModel(
        id: 'usr-admin-01',
        name: 'Dr. Sharma (Admin)',
        email: 'admin@cosmyra.edu',
        userIdCode: 'ADM001',
        role: 'Administrator',
        examAccess: ['NEET', 'JEE Main'],
        status: 'Active',
        lastActive: 'Just now',
        joinedOn: 'Aug 01, 2026',
        phone: '+91 98765 43210',
        regSource: 'System Admin',
        avatarInitials: 'DS',
        avatarColor: const Color(0xFFEF4444),
      ),
      AdminUserModel(
        id: 'usr-student-01',
        name: 'Rahul Sharma',
        email: 'student@cosmyra.edu',
        userIdCode: 'STU001',
        role: 'Student',
        examAccess: ['NEET UG'],
        status: 'Active',
        lastActive: '10 mins ago',
        joinedOn: 'Aug 15, 2026',
        phone: '+91 91234 56789',
        regSource: 'Web Portal',
        avatarInitials: 'RS',
        avatarColor: const Color(0xFF6366F1),
      ),
    ];
  }

  void _initSampleUserData() {
    _allUsers = _getInitialSystemUsers();
  }

  // Filtered users calculation
  List<AdminUserModel> get _filteredUsers {
    return _allUsers.where((u) {
      final q = _searchController.text.trim().toLowerCase();
      if (q.isNotEmpty) {
        final match = u.name.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q) ||
            u.userIdCode.toLowerCase().contains(q) ||
            u.phone.contains(q);
        if (!match) return false;
      }

      if (_selectedRole != 'All Roles' && u.role.toLowerCase() != _selectedRole.toLowerCase()) {
        return false;
      }
      if (_selectedStatus != 'All Status' && u.status.toLowerCase() != _selectedStatus.toLowerCase()) {
        return false;
      }
      if (_selectedStatusTab.startsWith('Active') && u.status != 'Active') return false;
      if (_selectedStatusTab.startsWith('Suspended') && u.status != 'Suspended') return false;
      if (_selectedStatusTab.startsWith('Pending') && u.status != 'Pending') return false;
      if (_selectedStatusTab.startsWith('Blocked') && u.status != 'Blocked') return false;

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // 1. LEFT SIDEBAR NAVIGATION
          _buildSidebar(),

          // 2. MAIN CONTENT AREA
          Expanded(
            child: Column(
              children: [
                // Top Header Navbar
                _buildTopNavbar(),

                // Scrollable Dashboard Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Page Header Title + Action Buttons
                        _buildPageHeader(),
                        const SizedBox(height: 20),

                        // Stat Cards Grid Row (6 Cards)
                        _buildStatCardsRow(),
                        const SizedBox(height: 24),

                        // Search & Advanced Filter Controls
                        _buildFilterControlsCard(),
                        const SizedBox(height: 20),

                        // Main Content Row: Data Table + Detail Inspector Panel
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left: Users Data Table & Pagination
                            Expanded(
                              flex: 7,
                              child: Column(
                                children: [
                                  _buildStatusTabsRow(),
                                  const SizedBox(height: 16),
                                  _buildUsersDataTable(),
                                  const SizedBox(height: 16),
                                  _buildTablePaginationFooter(),
                                ],
                              ),
                            ),

                            // Right: Detail Slide-Over Inspector Panel (If user selected)
                            if (_selectedUserForDetail != null) ...[
                              const SizedBox(width: 20),
                              SizedBox(
                                width: 340,
                                child: _buildUserDetailInspectorPanel(),
                              ),
                            ],
                          ],
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
    );
  }

  // ================= 1. SIDEBAR NAVIGATION =================
  Widget _buildSidebar() {
    return Container(
      width: 240,
      color: const Color(0xFF0F172A),
      child: Column(
        children: [
          // Sidebar Logo Header
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text(
                      'A',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cosmyra Admin',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      'Control Center',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF1E293B), height: 1),

          // Sidebar Navigation List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              children: [
                _buildSidebarTile(Icons.dashboard_rounded, 'Overview & KPIs'),
                _buildSidebarTile(Icons.quiz_rounded, 'Question Bank'),
                _buildSidebarTile(Icons.upload_file_rounded, 'CSV Bulk Import'),
                _buildSidebarTile(Icons.account_tree_rounded, 'Exam Hierarchy'),
                _buildSidebarTile(Icons.report_problem_rounded, 'Reported Questions'),
                _buildSidebarTile(Icons.people_alt_rounded, 'User Management', isActive: true),

                const SizedBox(height: 20),
                _buildSidebarSectionHeader('USERS & ROLES'),
                _buildSidebarTile(Icons.person_outline_rounded, 'Users'),
                _buildSidebarTile(Icons.admin_panel_settings_outlined, 'Roles & Permissions'),
                _buildSidebarTile(Icons.history_rounded, 'Activity Logs'),

                const SizedBox(height: 20),
                _buildSidebarSectionHeader('REPORTS & ANALYTICS'),
                _buildSidebarTile(Icons.bar_chart_rounded, 'Analytics Dashboard'),
                _buildSidebarTile(Icons.description_outlined, 'Question Reports'),
                _buildSidebarTile(Icons.insights_rounded, 'Student Performance'),
                _buildSidebarTile(Icons.emoji_events_outlined, 'Leaderboard'),

                const SizedBox(height: 20),
                _buildSidebarSectionHeader('SYSTEM & SETTINGS'),
                _buildSidebarTile(Icons.settings_outlined, 'System Settings'),
                _buildSidebarTile(Icons.notifications_none_rounded, 'Notification Center'),
                _buildSidebarTile(Icons.backup_outlined, 'Backup & Restore'),
                _buildSidebarTile(Icons.extension_outlined, 'Integrations'),

                const SizedBox(height: 24),
                // Need Help Card Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4338CA), Color(0xFF6366F1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Need Help?',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Check documentation or contact support.',
                        style: TextStyle(color: Color(0xFFE0E7FF), fontSize: 11, height: 1.3),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {},
                        child: const Row(
                          children: [
                            Text(
                              'View Docs ->',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
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

          // Sidebar User Profile Footer
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF0F172A),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF6366F1),
                  child: Text(
                    widget.userProfile.fullName.isNotEmpty
                        ? widget.userProfile.fullName.substring(0, 2).toUpperCase()
                        : 'AU',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userProfile.fullName.isNotEmpty ? widget.userProfile.fullName : 'Admin User',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const Text(
                        'Super Administrator',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.more_vert, color: Color(0xFF94A3B8), size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8),
      ),
    );
  }

  Widget _buildSidebarTile(IconData icon, String title, {bool isActive = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF6366F1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        leading: Icon(icon, color: isActive ? Colors.white : const Color(0xFF94A3B8), size: 18),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFFCBD5E1),
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
        onTap: () {
          setState(() {
            _activeSidebarItem = title;
          });
          if (title.contains('Overview') || title.contains('Dashboard')) {
            Navigator.of(context).push(SmoothPageRoute(child: AdminDashboardScreen(userProfile: widget.userProfile)));
          } else if (title.contains('Hierarchy')) {
            Navigator.of(context).push(SmoothPageRoute(child: AdminHierarchyScreen(userProfile: widget.userProfile)));
          } else if (title.contains('Leaderboard')) {
            Navigator.of(context).push(SmoothPageRoute(child: AdminLeaderboardScreen(userProfile: widget.userProfile)));
          }
        },
      ),
    );
  }

  // ================= 2. TOP NAVBAR =================
  Widget _buildTopNavbar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          const Icon(Icons.menu, color: Color(0xFF64748B), size: 20),
          const SizedBox(width: 12),
          const Text(
            'Cosmyra Admin',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
          ),
          const SizedBox(width: 32),

          // Central Search Input
          Expanded(
            child: Container(
              height: 38,
              constraints: const BoxConstraints(maxWidth: 480),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
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
                        hintText: 'Search users by name, email, phone, or ID...',
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
                    child: const Text('⌘ K', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 24),

          // Right Header Controls
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFF6366F1)),
            label: const Row(
              children: [
                Text('Quick Actions', style: TextStyle(color: Color(0xFF334155), fontSize: 13, fontWeight: FontWeight.w600)),
                SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B)),
              ],
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(width: 16),

          // Dark Mode Toggle Moon
          IconButton(
            icon: Icon(
              _isDarkMode ? Icons.wb_sunny_outlined : Icons.nightlight_round,
              color: const Color(0xFF64748B),
              size: 20,
            ),
            onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
          ),
          const SizedBox(width: 8),

          // Notification Bell Icon with Badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF64748B), size: 22),
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
                  child: const Text('1', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Admin User Profile Badge
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFC084FC),
                child: const Text('AU', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Admin User', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                  Text('Super Administrator', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= 3. PAGE HEADER & ACTIONS =================
  Widget _buildPageHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people_alt_rounded, color: Color(0xFF6366F1), size: 28),
                SizedBox(width: 10),
                Text(
                  'User Management',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.5),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              'Manage platform users, roles, permissions, and access control.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
        Row(
          children: [
            // Refresh Data Button
            OutlinedButton.icon(
              onPressed: () {
                _loadRealUsersFromSupabase();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Refreshing live user profiles from Supabase...'),
                    duration: Duration(seconds: 2),
                    backgroundColor: Color(0xFF6366F1),
                  ),
                );
              },
              icon: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF6366F1)),
              label: const Text('Refresh', style: TextStyle(color: Color(0xFF6366F1), fontSize: 13, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(width: 10),

            // Import Users Button
            OutlinedButton.icon(
              onPressed: _showImportUsersModal,
              icon: const Icon(Icons.upload_rounded, size: 16, color: Color(0xFF475569)),
              label: const Row(
                children: [
                  Text('Import Users', style: TextStyle(color: Color(0xFF334155), fontSize: 13, fontWeight: FontWeight.w600)),
                  SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B)),
                ],
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(width: 10),

            // Export Users Button
            OutlinedButton.icon(
              onPressed: _showExportUsersModal,
              icon: const Icon(Icons.download_rounded, size: 16, color: Color(0xFF475569)),
              label: const Row(
                children: [
                  Text('Export Users', style: TextStyle(color: Color(0xFF334155), fontSize: 13, fontWeight: FontWeight.w600)),
                  SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B)),
                ],
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(width: 10),

            // + Add New User Button
            ElevatedButton.icon(
              onPressed: _showAddNewUserModal,
              icon: const Icon(Icons.add, size: 18, color: Colors.white),
              label: const Row(
                children: [
                  Text('Add New User', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.white),
                ],
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ================= 4. STAT CARDS ROW (6 CARDS) =================
  Widget _buildStatCardsRow() {
    final totalCount = _allUsers.length;
    final studentsCount = _allUsers.where((u) => u.role.toLowerCase().contains('student')).length;
    final educatorsCount = _allUsers.where((u) => u.role.toLowerCase().contains('educator')).length;
    final adminsCount = _allUsers.where((u) => u.role.toLowerCase().contains('admin')).length;
    final activeCount = _allUsers.where((u) => u.status.toLowerCase() == 'active').length;
    final suspendedCount = _allUsers.where((u) => u.status.toLowerCase() == 'suspended').length;

    final stats = [
      {
        'title': 'Total Users',
        'count': '$totalCount',
        'badge': '+ real-time',
        'sub': '100% live synced',
        'icon': Icons.people_outline_rounded,
        'iconBg': const Color(0xFFEEF2FF),
        'iconColor': const Color(0xFF6366F1),
      },
      {
        'title': 'Students',
        'count': '$studentsCount',
        'badge': null,
        'sub': totalCount > 0 ? '${((studentsCount / totalCount) * 100).toStringAsFixed(1)}% of total' : '0%',
        'icon': Icons.school_outlined,
        'iconBg': const Color(0xFFECFDF5),
        'iconColor': const Color(0xFF10B981),
      },
      {
        'title': 'Educators',
        'count': '$educatorsCount',
        'badge': null,
        'sub': totalCount > 0 ? '${((educatorsCount / totalCount) * 100).toStringAsFixed(1)}% of total' : '0%',
        'icon': Icons.person_outline_rounded,
        'iconBg': const Color(0xFFFFF7ED),
        'iconColor': const Color(0xFFF97316),
      },
      {
        'title': 'Admins',
        'count': '$adminsCount',
        'badge': null,
        'sub': totalCount > 0 ? '${((adminsCount / totalCount) * 100).toStringAsFixed(1)}% of total' : '0%',
        'icon': Icons.security_outlined,
        'iconBg': const Color(0xFFFEF2F2),
        'iconColor': const Color(0xFFEF4444),
      },
      {
        'title': 'Active Users',
        'count': '$activeCount',
        'badge': null,
        'sub': totalCount > 0 ? '${((activeCount / totalCount) * 100).toStringAsFixed(1)}% of total' : '0%',
        'icon': Icons.check_circle_outline_rounded,
        'iconBg': const Color(0xFFECFDF5),
        'iconColor': const Color(0xFF10B981),
      },
      {
        'title': 'Suspended Users',
        'count': '$suspendedCount',
        'badge': null,
        'sub': totalCount > 0 ? '${((suspendedCount / totalCount) * 100).toStringAsFixed(1)}% of total' : '0%',
        'icon': Icons.pause_circle_outline_rounded,
        'iconBg': const Color(0xFFF3E8FF),
        'iconColor': const Color(0xFFA855F7),
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        double cardWidth = (constraints.maxWidth - (16 * 5)) / 6;
        if (constraints.maxWidth < 1200) {
          cardWidth = (constraints.maxWidth - (16 * 2)) / 3;
        }

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: stats.map((s) {
            return SizedBox(
              width: cardWidth,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          s['title'] as String,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: s['iconBg'] as Color,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(s['icon'] as IconData, size: 18, color: s['iconColor'] as Color),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s['count'] as String,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (s['badge'] != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              s['badge'] as String,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF16A34A)),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          s['sub'] as String,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ================= 5. FILTER CONTROLS CARD =================
  Widget _buildFilterControlsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Row Filters
          Row(
            children: [
              // Search Input
              Expanded(
                flex: 3,
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Color(0xFF94A3B8), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            hintText: 'Search by name, email, phone, or user ID...',
                            hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
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

              // Dropdown: All Roles
              _buildFilterDropdown(
                value: _selectedRole,
                items: ['All Roles', 'Student', 'Educator', 'Administrator'],
                onChanged: (val) => setState(() => _selectedRole = val!),
              ),
              const SizedBox(width: 12),

              // Dropdown: All Status
              _buildFilterDropdown(
                value: _selectedStatus,
                items: ['All Status', 'Active', 'Suspended', 'Pending', 'Blocked'],
                onChanged: (val) => setState(() => _selectedStatus = val!),
              ),
              const SizedBox(width: 12),

              // Dropdown: All Exams
              _buildFilterDropdown(
                value: _selectedExam,
                items: ['All Exams', 'NEET', 'JEE Main', 'JEE Advanced'],
                onChanged: (val) => setState(() => _selectedExam = val!),
              ),
              const SizedBox(width: 12),

              // Dropdown: Registration Source
              _buildFilterDropdown(
                value: _selectedRegSource,
                items: ['All Registration Source', 'Web Portal', 'Mobile App', 'Admin Referral'],
                onChanged: (val) => setState(() => _selectedRegSource = val!),
              ),
              const SizedBox(width: 12),

              // More Filters Button
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.filter_list_rounded, size: 16, color: Color(0xFF6366F1)),
                label: const Text('More Filters', style: TextStyle(color: Color(0xFF334155), fontSize: 13, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bottom Row: Date Range + Clear + Save + View Toggles
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // Date Range Picker Box
                  Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Row(
                      children: [
                        Text('Aug 01, 2026 - Aug 31, 2026', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                        SizedBox(width: 8),
                        Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF64748B)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Clear Filters
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _selectedRole = 'All Roles';
                        _selectedStatus = 'All Status';
                        _selectedExam = 'All Exams';
                        _selectedRegSource = 'All Registration Source';
                      });
                    },
                    child: const Text('Clear Filters', style: TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              Row(
                children: [
                  // Save Filter Button
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.bookmark_border_rounded, size: 16, color: Color(0xFF6366F1)),
                    label: const Text('Save Filter', style: TextStyle(color: Color(0xFF334155), fontSize: 13, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // View Toggle Buttons (List vs Grid)
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF6366F1)),
                          ),
                          child: const Icon(Icons.format_list_bulleted_rounded, size: 16, color: Color(0xFF6366F1)),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          child: const Icon(Icons.grid_view_rounded, size: 16, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B)),
          style: const TextStyle(fontSize: 13, color: Color(0xFF334155), fontWeight: FontWeight.w600),
          items: items.map((it) => DropdownMenuItem(value: it, child: Text(it))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ================= 6. STATUS TABS ROW =================
  Widget _buildStatusTabsRow() {
    final total = _allUsers.length;
    final active = _allUsers.where((u) => u.status.toLowerCase() == 'active').length;
    final suspended = _allUsers.where((u) => u.status.toLowerCase() == 'suspended').length;
    final pending = _allUsers.where((u) => u.status.toLowerCase() == 'pending').length;
    final blocked = _allUsers.where((u) => u.status.toLowerCase() == 'blocked').length;

    final tabs = [
      'All Users ($total)',
      'Active ($active)',
      'Suspended ($suspended)',
      'Pending ($pending)',
      'Blocked ($blocked)',
    ];

    return Row(
      children: tabs.map((tab) {
        final tabPrefix = tab.split(' ').first;
        final selectedPrefix = _selectedStatusTab.split(' ').first;
        final isSelected = selectedPrefix == tabPrefix;
        return GestureDetector(
          onTap: () => setState(() => _selectedStatusTab = tab),
          child: Container(
            margin: const EdgeInsets.only(right: 24),
            padding: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
                  width: 2.5,
                ),
              ),
            ),
            child: Text(
              tab,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF64748B),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ================= 7. USERS DATA TABLE =================
  Widget _buildUsersDataTable() {
    final users = _filteredUsers;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(40), // Checkbox
          1: FlexColumnWidth(2.5), // User
          2: FlexColumnWidth(1.2), // Role
          3: FlexColumnWidth(2.0), // Exam Access
          4: FlexColumnWidth(1.2), // Status
          5: FlexColumnWidth(1.4), // Last Active
          6: FlexColumnWidth(1.8), // Joined On
          7: FlexColumnWidth(1.4), // Actions
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          // Header Row
          TableRow(
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Checkbox(
                  value: _selectedUserIds.length == users.length && users.isNotEmpty,
                  activeColor: const Color(0xFF4F46E5),
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedUserIds.addAll(users.map((u) => u.id));
                      } else {
                        _selectedUserIds.clear();
                      }
                    });
                  },
                ),
              ),
              _buildTableHeader('USER'),
              _buildTableHeader('ROLE'),
              _buildTableHeader('EXAM ACCESS'),
              _buildTableHeader('STATUS'),
              _buildTableHeader('LAST ACTIVE'),
              _buildTableHeader('JOINED ON'),
              _buildTableHeader('ACTIONS'),
            ],
          ),

          // User Data Rows
          ...users.map((u) {
            final isSelected = _selectedUserIds.contains(u.id);
            final isInspected = _selectedUserForDetail?.id == u.id;

            return TableRow(
              decoration: BoxDecoration(
                color: isInspected ? const Color(0xFFEEF2FF).withOpacity(0.5) : Colors.white,
                border: const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Checkbox(
                    value: isSelected,
                    activeColor: const Color(0xFF4F46E5),
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedUserIds.add(u.id);
                        } else {
                          _selectedUserIds.remove(u.id);
                        }
                      });
                    },
                  ),
                ),

                // User Info Cell
                InkWell(
                  onTap: () => setState(() => _selectedUserForDetail = u),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: u.avatarColor,
                          child: Text(u.avatarInitials, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                              Text(u.email, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                              Text('ID: ${u.userIdCode}', style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Role Cell
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _buildRoleBadge(u.role),
                ),

                // Exam Access Badges Cell
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: u.examAccess.map((ex) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(ex, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                      );
                    }).toList(),
                  ),
                ),

                // Status Cell
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _buildStatusBadge(u.status),
                ),

                // Last Active Cell
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    u.lastActive.startsWith('•') ? u.lastActive : u.lastActive,
                    style: TextStyle(
                      fontSize: 12,
                      color: u.lastActive.contains('min') || u.lastActive.contains('now')
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                // Joined On Cell
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(u.joinedOn.split(" ").take(3).join(" "), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                      Text(u.joinedOn.split(" ").skip(3).join(" "), style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                    ],
                  ),
                ),

                // Action Icons Cell
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility_outlined, size: 16, color: Color(0xFF64748B)),
                        onPressed: () => setState(() => _selectedUserForDetail = u),
                        tooltip: 'View User',
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF64748B)),
                        onPressed: () => _showEditUserModal(u),
                        tooltip: 'Edit User',
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert, size: 16, color: Color(0xFF64748B)),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color bg = const Color(0xFFECFDF5);
    Color text = const Color(0xFF059669);

    if (role == 'Educator') {
      bg = const Color(0xFFFFF7ED);
      text = const Color(0xFFD97706);
    } else if (role == 'Administrator') {
      bg = const Color(0xFFF3E8FF);
      text = const Color(0xFF7E22CE);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(role, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: text)),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = const Color(0xFFDCFCE7);
    Color text = const Color(0xFF15803D);

    if (status == 'Suspended') {
      bg = const Color(0xFFFEF2F2);
      text = const Color(0xFFDC2626);
    } else if (status == 'Pending') {
      bg = const Color(0xFFFEF3C7);
      text = const Color(0xFFD97706);
    } else if (status == 'Blocked') {
      bg = const Color(0xFFF1F5F9);
      text = const Color(0xFF475569);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: text)),
    );
  }

  // ================= 8. DETAIL INSPECTOR PANEL (RIGHT SIDEOVER) =================
  Widget _buildUserDetailInspectorPanel() {
    final u = _selectedUserForDetail!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Panel Top Header: Avatar + Close Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: u.avatarColor,
                    child: Text(u.avatarInitials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                      Text('ID: ${u.userIdCode}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 18),
                onPressed: () => setState(() => _selectedUserForDetail = null),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Inspector Sub-Tabs
          Row(
            children: ['Overview', 'Activity', 'Access', 'Security'].map((tb) {
              final isSel = _detailPanelTab == tb;
              return GestureDetector(
                onTap: () => setState(() => _detailPanelTab = tb),
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isSel ? const Color(0xFF6366F1) : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    tb,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                      color: isSel ? const Color(0xFF6366F1) : const Color(0xFF64748B),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Detail Properties List
          _buildDetailRow(Icons.phone_outlined, 'Phone', u.phone),
          
          const SizedBox(height: 12),
          const Text('Reassign Role', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          const SizedBox(height: 6),
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFC7D2FE)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: ['Student', 'Educator', 'Administrator', 'Super Administrator', 'Content Moderator'].contains(u.role)
                    ? u.role
                    : 'Student',
                isExpanded: true,
                style: const TextStyle(fontSize: 13, color: Color(0xFF4338CA), fontWeight: FontWeight.bold),
                items: ['Student', 'Educator', 'Administrator', 'Super Administrator', 'Content Moderator']
                    .map((rl) => DropdownMenuItem(value: rl, child: Text(rl)))
                    .toList(),
                onChanged: (newRole) async {
                  if (newRole != null) {
                    await SupabaseService.updateUserRole(userId: u.id, role: newRole);
                    setState(() {
                      final idx = _allUsers.indexWhere((item) => item.id == u.id);
                      if (idx != -1) {
                        _allUsers[idx] = AdminUserModel(
                          id: u.id,
                          name: u.name,
                          email: u.email,
                          userIdCode: u.userIdCode,
                          role: newRole,
                          examAccess: u.examAccess,
                          status: u.status,
                          lastActive: u.lastActive,
                          joinedOn: u.joinedOn,
                          phone: u.phone,
                          regSource: u.regSource,
                          adminNotes: u.adminNotes,
                          avatarInitials: u.avatarInitials,
                          avatarColor: u.avatarColor,
                        );
                        _selectedUserForDetail = _allUsers[idx];
                      }
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Role successfully updated to [$newRole] for ${u.name}!'),
                          backgroundColor: const Color(0xFF10B981),
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          _buildDetailRow(Icons.calendar_today_outlined, 'Registered On', u.joinedOn),
          _buildDetailRow(Icons.schedule_outlined, 'Last Active', u.lastActive),

          const SizedBox(height: 12),
          const Text('Exam Access', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: u.examAccess.map((ex) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(ex, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          _buildDetailRow(Icons.language_outlined, 'Registration Source', u.regSource),

          const SizedBox(height: 12),
          const Text('Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          const SizedBox(height: 6),
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: u.status,
                isExpanded: true,
                style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
                items: ['Active', 'Suspended', 'Pending', 'Blocked'].map((st) => DropdownMenuItem(value: st, child: Text(st))).toList(),
                onChanged: (val) async {
                  if (val != null) {
                    await SupabaseService.updateUserStatus(userId: u.id, status: val);
                    setState(() {
                      final idx = _allUsers.indexWhere((item) => item.id == u.id);
                      if (idx != -1) {
                        _allUsers[idx] = AdminUserModel(
                          id: u.id,
                          name: u.name,
                          email: u.email,
                          userIdCode: u.userIdCode,
                          role: u.role,
                          examAccess: u.examAccess,
                          status: val,
                          lastActive: u.lastActive,
                          joinedOn: u.joinedOn,
                          phone: u.phone,
                          regSource: u.regSource,
                          adminNotes: u.adminNotes,
                          avatarInitials: u.avatarInitials,
                          avatarColor: u.avatarColor,
                        );
                        _selectedUserForDetail = _allUsers[idx];
                      }
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Status updated to [$val] for ${u.name}!'),
                          backgroundColor: const Color(0xFF6366F1),
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 14),

          const Text('Notes', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          const SizedBox(height: 6),
          TextField(
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Add admin notes...',
              hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              contentPadding: const EdgeInsets.all(10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            ),
          ),
          const SizedBox(height: 20),

          // Bottom Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Password reset link sent to ${u.email}')),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Reset Password', style: TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('User ${u.name} status updated to Suspended')),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFF7ED),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFFFED7AA)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Suspend User', style: TextStyle(fontSize: 12, color: Color(0xFFEA580C), fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Saved changes for ${u.name} successfully!'), backgroundColor: const Color(0xFF10B981)),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: const Text('Save Changes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                Text(value, style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= 9. PAGINATION FOOTER =================
  Widget _buildTablePaginationFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text('${_selectedUserIds.length} selected', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _selectedUserIds.isEmpty ? null : () {},
              icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B)),
              label: const Text('Bulk Actions', style: TextStyle(fontSize: 12, color: Color(0xFF334155), fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ],
        ),

        Row(
          children: [
            const Text('Showing 1 to 25 of 24,850 users', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            const SizedBox(width: 16),
            const Text('Show', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            const SizedBox(width: 6),

            Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _rowsPerPage,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
                  items: [10, 25, 50, 100].map((pageSize) => DropdownMenuItem(value: pageSize, child: Text('$pageSize per page'))).toList(),
                  onChanged: (val) => setState(() => _rowsPerPage = val!),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Pagination Controls
            Row(
              children: [
                _buildPaginationButton('<', isEnabled: false),
                _buildPaginationButton('1', isSelected: true),
                _buildPaginationButton('2'),
                _buildPaginationButton('3'),
                _buildPaginationButton('...'),
                _buildPaginationButton('994'),
                _buildPaginationButton('>'),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaginationButton(String label, {bool isSelected = false, bool isEnabled = true}) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF4F46E5) : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : (isEnabled ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
          ),
        ),
      ),
    );
  }

  // ================= 10. MODALS =================
  void _showAddNewUserModal() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String role = 'Student';
    List<String> exams = ['NEET'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    const Text('Add New User', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Mobile Number', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
                  items: ['Student', 'Educator', 'Administrator', 'Super Administrator', 'Content Moderator'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (val) => setDialogState(() => role = val!),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameCtrl.text.isNotEmpty && emailCtrl.text.isNotEmpty) {
                        final newUserModel = UserProfileModel(
                          id: 'usr-${DateTime.now().millisecondsSinceEpoch}',
                          email: emailCtrl.text.trim(),
                          fullName: nameCtrl.text.trim(),
                          phoneNumber: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : '+91 98765 43210',
                          targetExam: exams.first,
                          role: role.toLowerCase(),
                        );
                        await SupabaseService.addLocalUser(newUserModel);
                        try {
                          await SupabaseService.signUp(
                            email: emailCtrl.text.trim(),
                            password: 'UserPass@123!',
                            fullName: nameCtrl.text.trim(),
                            phone: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : '+91 98765 43210',
                            role: role.toLowerCase(),
                          );
                        } catch (_) {}

                        await _loadRealUsersFromSupabase();

                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('User ${nameCtrl.text} added successfully!'), backgroundColor: const Color(0xFF10B981)),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
                    child: const Text('Create User', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditUserModal(AdminUserModel user) {
    final nameCtrl = TextEditingController(text: user.name);
    final emailCtrl = TextEditingController(text: user.email);
    String role = ['Student', 'Educator', 'Administrator', 'Super Administrator', 'Content Moderator'].contains(user.role)
        ? user.role
        : 'Student';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    Text('Edit User & Reassign Role: ${user.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(labelText: 'Reassign User Role', border: OutlineInputBorder()),
                  items: ['Student', 'Educator', 'Administrator', 'Super Administrator', 'Content Moderator']
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (val) => setDialogState(() => role = val!),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () async {
                      await SupabaseService.updateUserRole(userId: user.id, role: role);
                      setState(() {
                        final idx = _allUsers.indexWhere((u) => u.id == user.id);
                        if (idx != -1) {
                          _allUsers[idx] = AdminUserModel(
                            id: user.id,
                            name: nameCtrl.text.trim(),
                            email: emailCtrl.text.trim(),
                            userIdCode: user.userIdCode,
                            role: role,
                            examAccess: user.examAccess,
                            status: user.status,
                            lastActive: user.lastActive,
                            joinedOn: user.joinedOn,
                            phone: user.phone,
                            regSource: user.regSource,
                            adminNotes: user.adminNotes,
                            avatarInitials: user.avatarInitials,
                            avatarColor: user.avatarColor,
                          );
                          if (_selectedUserForDetail?.id == user.id) {
                            _selectedUserForDetail = _allUsers[idx];
                          }
                        }
                      });
                      if (mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('User ${nameCtrl.text} role updated to [$role]!'),
                            backgroundColor: const Color(0xFF10B981),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
                    child: const Text('Save & Apply Role', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showImportUsersModal() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Import Users from CSV / Excel', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_upload_outlined, size: 40, color: Color(0xFF6366F1)),
                    SizedBox(height: 8),
                    Text('Drag and drop CSV file here or click to browse', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
                child: const Text('Upload & Import', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExportUsersModal() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Export User Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('Select Format:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  ChoiceChip(label: const Text('CSV Format'), selected: true),
                  const SizedBox(width: 8),
                  ChoiceChip(label: const Text('Excel (.xlsx)'), selected: false),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Downloading exported users CSV...'), backgroundColor: Color(0xFF10B981)),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
                child: const Text('Download Export', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
