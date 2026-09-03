import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/models.dart';
import '../../core/services/supabase_service.dart';
import '../../shared/utils/smooth_page_route.dart';
import 'admin_dashboard_screen.dart';
import 'admin_user_management_screen.dart';

class AdminPricingScreen extends StatefulWidget {
  final UserProfileModel userProfile;

  const AdminPricingScreen({Key? key, required this.userProfile}) : super(key: key);

  @override
  State<AdminPricingScreen> createState() => _AdminPricingScreenState();
}

class _AdminPricingScreenState extends State<AdminPricingScreen> {
  String _activeTab = 'Plans'; // Plans, Features, Plan Comparisons, Subscribers, Settings
  bool _showInactivePlans = false;
  String _selectedDefaultPlan = 'Pro (8 Months)';
  bool _allowDowngrade = true;
  bool _allowUpgrade = true;
  bool _autoRenewal = true;

  // Feature Toggles Matrix State
  bool _f1Trial = false, _f1Starter = true, _f1Pro = true, _f1Ultimate = true;
  bool _f2Trial = false, _f2Starter = true, _f2Pro = true, _f2Ultimate = true;
  bool _f3Trial = false, _f3Starter = false, _f3Pro = true, _f3Ultimate = true;

  void _openCreatePlanModal() {
    final titleCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final durationCtrl = TextEditingController();

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
                  const Text('Create New Subscription Plan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop()),
                ],
              ),
              const SizedBox(height: 16),
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Plan Name (e.g. Super Pro)')),
              const SizedBox(height: 12),
              TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Price in INR (₹)')),
              const SizedBox(height: 12),
              TextField(controller: durationCtrl, decoration: const InputDecoration(labelText: 'Duration (e.g. 6 Months)')),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('New Subscription Plan created successfully!')),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
                    child: const Text('Create & Publish Plan'),
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
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // 1. LEFT DARK SIDEBAR NAVIGATION (#0B0F19)
          if (isDesktop) _buildAdminSidebar(),

          // 2. MAIN PRICING & PLANS CONTENT AREA
          Expanded(
            child: Column(
              children: [
                // Top Header Bar
                _buildAdminHeader(),

                // Main Scrollable Canvas
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Page Title & Subtitle + "+ Create New Plan" Button
                        _buildTitleRow(),
                        const SizedBox(height: 20),

                        // Sub-navigation Tabs (Plans, Features, Plan Comparisons, Subscribers, Settings)
                        _buildSubNavTabs(),
                        const SizedBox(height: 24),

                        // Top 5 Metrics Cards Row
                        _buildTopMetricsRow(),
                        const SizedBox(height: 24),

                        // Main Content: Dynamic Tabs
                        if (_activeTab == 'Orders & Transactions')
                          _buildOrdersTabContent()
                        else if (_activeTab == 'Coupons & Offers')
                          _buildCouponsTabContent()
                        else if (_activeTab == 'Subscribers')
                          _buildSubscribersTabContent()
                        else if (_activeTab == 'Settings')
                          _buildPlanSettingsCard()
                        else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left Section: Subscription Plan Cards + Features Matrix
                              Expanded(
                                flex: 8,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Subscription Plans Header & Toggle
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Subscription Plans', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                            SizedBox(height: 2),
                                            Text('Create and manage plans with pricing, duration and features.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            const Text('Show Inactive Plans', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                            const SizedBox(width: 8),
                                            Switch(
                                              value: _showInactivePlans,
                                              activeColor: const Color(0xFF4F46E5),
                                              onChanged: (val) => setState(() => _showInactivePlans = val),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    // 4 Plan Cards Grid
                                    _buildPlanCardsGrid(),
                                    const SizedBox(height: 28),

                                    // Bottom Section: Plan Features Management Table
                                    _buildPlanFeaturesTable(),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 20),

                              // Right Section: Plan Settings + Quick Actions + Plan Performance Stack
                              SizedBox(
                                width: 300,
                                child: Column(
                                  children: [
                                    _buildPlanSettingsCard(),
                                    const SizedBox(height: 20),
                                    _buildQuickActionsCard(),
                                    const SizedBox(height: 20),
                                    _buildPlanPerformanceCard(),
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
          ),
        ],
      ),
    );
  }

  // ================= 1. LEFT SIDEBAR NAVIGATION =================
  Widget _buildAdminSidebar() {
    return Container(
      width: 240,
      color: const Color(0xFF0B0F19),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Logo & Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cosmyra', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Admin Panel', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Sidebar Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                 _buildSidebarSectionLabel('MAIN'),
                _buildSidebarTile('Dashboard', Icons.dashboard_outlined, false, onTap: () {
                  Navigator.of(context).push(SmoothPageRoute(child: AdminDashboardScreen(userProfile: widget.userProfile)));
                }),
                _buildSidebarTile('Paper Prediction', Icons.note_alt_outlined, false, onTap: () => Navigator.pushNamed(context, '/admin/predictions')),
                _buildSidebarTile('Exam Hierarchy', Icons.account_tree_outlined, false, onTap: () => Navigator.pushNamed(context, '/admin/hierarchy')),
                _buildSidebarTile('Users', Icons.people_outline_rounded, false, onTap: () {
                  Navigator.of(context).push(SmoothPageRoute(child: AdminUserManagementScreen(userProfile: widget.userProfile)));
                }),
                _buildSidebarTile('Exams', Icons.assignment_outlined, false),
                _buildSidebarTile('Subjects', Icons.book_outlined, false),
                _buildSidebarTile('Chapters', Icons.folder_open_outlined, false, onTap: () => Navigator.pushNamed(context, '/admin/chapters')),
                _buildSidebarTile('Topics', Icons.label_outline_rounded, false, onTap: () => Navigator.pushNamed(context, '/admin/chapters')),
                _buildSidebarTile('Questions', Icons.help_outline_rounded, false),
                _buildSidebarTile('Question Banks', Icons.layers_outlined, false),
                _buildSidebarTile('Tests', Icons.quiz_outlined, false),
                _buildSidebarTile('Practice Sets', Icons.play_circle_outline_rounded, false),

                const SizedBox(height: 16),
                _buildSidebarSectionLabel('BUSINESS'),
                _buildSidebarTile('Subscriptions', Icons.card_membership_outlined, false, hasDropdown: true),
                _buildSidebarTile('Pricing & Plans', Icons.monetization_on_outlined, true, onTap: () => Navigator.pushNamed(context, '/admin/pricing')),
                _buildSidebarTile('Coupons & Offers', Icons.local_offer_outlined, false),
                _buildSidebarTile('Transactions', Icons.receipt_long_outlined, false),
                _buildSidebarTile('Refunds', Icons.replay_rounded, false),
                _buildSidebarTile('Invoices', Icons.description_outlined, false),

                const SizedBox(height: 16),
                _buildSidebarSectionLabel('CONTENT & ENGAGEMENT'),
                _buildSidebarTile('Paper Prediction', Icons.auto_awesome_outlined, false, onTap: () => Navigator.pushNamed(context, '/admin/predictions')),
                _buildSidebarTile('Announcements', Icons.campaign_outlined, false),
                _buildSidebarTile('Notifications', Icons.notifications_none_rounded, false),
                _buildSidebarTile('Banners', Icons.view_carousel_outlined, false),

                const SizedBox(height: 16),
                _buildSidebarSectionLabel('REPORTS & ANALYTICS'),
                _buildSidebarTile('Analytics', Icons.bar_chart_rounded, false),
                _buildSidebarTile('Leaderboard', Icons.emoji_events_outlined, false, onTap: () => Navigator.pushNamed(context, '/admin/leaderboard')),
                _buildSidebarTile('Student Performance', Icons.insights_rounded, false),
                _buildSidebarTile('Sales Reports', Icons.trending_up_rounded, false),
                _buildSidebarTile('System Logs', Icons.list_alt_rounded, false),

                const SizedBox(height: 16),
                _buildSidebarSectionLabel('SYSTEM'),
                _buildSidebarTile('Settings', Icons.settings_outlined, false),
                _buildSidebarTile('Roles & Permissions', Icons.admin_panel_settings_outlined, false),
                const SizedBox(height: 20),
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

  Widget _buildSidebarTile(String title, IconData icon, bool isActive, {bool hasDropdown = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
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
              Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: isActive ? Colors.white : const Color(0xFF64748B)),
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
                        hintText: 'Search anything...',
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

          // Header Right Utilities
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
                      child: const Text('5', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
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
                  Text('Admin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Text('Super Admin', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= 3. PAGE TITLE ROW =================
  Widget _buildTitleRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pricing & Plans', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            SizedBox(height: 2),
            Text('Manage subscription plans, pricing, features and user access.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _openCreatePlanModal,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Create New Plan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  // ================= 4. SUB-NAVIGATION TABS =================
  Widget _buildSubNavTabs() {
    final tabs = ['Plans', 'Orders & Transactions', 'Coupons & Offers', 'Subscribers', 'Settings'];
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: tabs.map((t) {
          final isSelected = _activeTab == t;
          return InkWell(
            onTap: () => setState(() => _activeTab = t),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? const Color(0xFF4F46E5) : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                t,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ================= 5. TOP 5 METRICS CARDS ROW =================
  Widget _buildTopMetricsRow() {
    return Row(
      children: [
        Expanded(child: _buildMetricCard('Total Plans', '4', 'Active plans', '', Icons.person_outline, const Color(0xFF8B5CF6))),
        const SizedBox(width: 12),
        Expanded(child: _buildMetricCard('Active Subscribers', '12,840', '+12.6% vs last 30 days', '', Icons.description_outlined, const Color(0xFF10B981))),
        const SizedBox(width: 12),
        Expanded(child: _buildMetricCard('Monthly Revenue', '₹28,76,540', '+18.3% vs last 30 days', '', Icons.calendar_today_outlined, const Color(0xFF3B82F6))),
        const SizedBox(width: 12),
        Expanded(child: _buildMetricCard('Annual Revenue', '₹3,24,18,230', '+22.1% vs last 30 days', '', Icons.inventory_2_outlined, const Color(0xFFF59E0B))),
        const SizedBox(width: 12),
        Expanded(child: _buildMetricCard('Conversion Rate', '18.42%', '+2.4% vs last 30 days', '', Icons.insights_rounded, const Color(0xFF8B5CF6))),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, String trend, String subtext, IconData icon, Color color) {
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
              Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 4),
          Row(
            children: [
              if (trend.isNotEmpty) ...[
                const Icon(Icons.trending_up, color: Color(0xFF10B981), size: 12),
                const SizedBox(width: 4),
                Expanded(child: Text(trend, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981)), overflow: TextOverflow.ellipsis)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ================= 6. SUBSCRIPTION PLAN CARDS GRID (4 CARDS) =================
  Widget _buildPlanCardsGrid() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildPlanCard('Trial Pass', '1 Month', 'Trial', '₹99', '/ month', 'Try Cosmyra for 30 days with limited access.', '30 Days', '100', '5 / Month', '15', Icons.star_border_rounded, Colors.amber, false)),
        const SizedBox(width: 12),
        Expanded(child: _buildPlanCard('Starter', '4 Months', 'Starter', '₹249', '/ 4 months', 'Short-term plan for focused preparation.', '4 Months', 'Unlimited', '10 / Month', '22', Icons.rocket_launch_outlined, const Color(0xFF10B981), false)),
        const SizedBox(width: 12),
        Expanded(child: _buildPlanCard('Pro', '8 Months', 'Most Popular', '₹449', '/ 8 months', 'Best for serious NEET & JEE aspirants.', '8 Months', 'Unlimited', 'Unlimited', '35', Icons.workspace_premium_outlined, const Color(0xFF8B5CF6), true)),
        const SizedBox(width: 12),
        Expanded(child: _buildPlanCard('Ultimate', '1 Year', 'Ultimate', '₹689', '/ year', 'Complete preparation with advanced AI.', '1 Year', 'Unlimited', 'Unlimited', '50', Icons.diamond_outlined, const Color(0xFF3B82F6), false)),
      ],
    );
  }

  Widget _buildPlanCard(
    String title,
    String durationTitle,
    String badgeText,
    String price,
    String priceUnit,
    String description,
    String durationVal,
    String maxQuestionsVal,
    String mockTestsVal,
    String featuresCount,
    IconData icon,
    Color themeColor,
    bool isPopular,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPopular ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
              width: isPopular ? 2 : 1,
            ),
            boxShadow: isPopular
                ? [BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.1), blurRadius: 16, offset: const Offset(0, 4))]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isPopular) const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: themeColor.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(icon, color: themeColor, size: 20),
                  ),
                  if (!isPopular)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: themeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(badgeText, style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 10)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              Text(durationTitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 12),

              // Price
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(price, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(width: 4),
                  Text(priceUnit, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 8),
              Text(description, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)), maxLines: 2),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Details List
              _buildPlanDetailRow('Status', 'Active', isStatusBadge: true),
              _buildPlanDetailRow('Duration', durationVal),
              _buildPlanDetailRow('Max Questions / Day', maxQuestionsVal),
              _buildPlanDetailRow('Mock Tests', mockTestsVal),
              _buildPlanDetailRow('Features', featuresCount),
              _buildPlanDetailRow('Created On', '12 May 2025'),
              const SizedBox(height: 16),

              // Card Actions
              Row(
                children: [
                  Expanded(
                    child: isPopular
                        ? ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Edit Plan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          )
                        : OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Edit Plan', style: TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      padding: const EdgeInsets.all(12),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Icon(Icons.more_horiz, size: 16, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Most Popular Top Badge
        if (isPopular)
          Positioned(
            top: -12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Most Popular', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlanDetailRow(String label, String val, {bool isStatusBadge = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          if (isStatusBadge)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
              child: const Text('Active', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 10)),
            )
          else
            Text(val, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }

  // ================= 7. PLAN SETTINGS CARD =================
  Widget _buildPlanSettingsCard() {
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
          const Text('Plan Settings', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 14),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Currency', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              Text('INR (₹)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tax (GST)', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              Text('18%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Default Plan', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFCBD5E1)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedDefaultPlan,
                isExpanded: true,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                items: const [
                  DropdownMenuItem(value: 'Pro (8 Months)', child: Text('Pro (8 Months)')),
                  DropdownMenuItem(value: 'Starter (4 Months)', child: Text('Starter (4 Months)')),
                  DropdownMenuItem(value: 'Ultimate (1 Year)', child: Text('Ultimate (1 Year)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedDefaultPlan = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildToggleRow('Allow Plan Downgrade', _allowDowngrade, (val) => setState(() => _allowDowngrade = val)),
          _buildToggleRow('Allow Plan Upgrade', _allowUpgrade, (val) => setState(() => _allowUpgrade = val)),
          _buildToggleRow('Auto Renewal', _autoRenewal, (val) => setState(() => _autoRenewal = val)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plan settings saved!')));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('Save Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow(String label, bool val, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          Switch(
            value: val,
            activeColor: const Color(0xFF4F46E5),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // ================= 8. QUICK ACTIONS CARD =================
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
          const Text('Quick Actions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 12),
          _buildQuickActionItem('+ Add New Plan', Icons.add, const Color(0xFF4F46E5), _openCreatePlanModal),
          _buildQuickActionItem('Manage Features', Icons.tune, const Color(0xFF64748B), () {}),
          _buildQuickActionItem('Plan Comparison', Icons.bar_chart, const Color(0xFF64748B), () {}),
          _buildQuickActionItem('Bulk Update Prices', Icons.sell_outlined, const Color(0xFF64748B), () {}),
          _buildQuickActionItem('Import/Export Plans', Icons.import_export, const Color(0xFF64748B), () {}),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: color == const Color(0xFF4F46E5) ? FontWeight.bold : FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // ================= 9. PLAN PERFORMANCE CARD =================
  Widget _buildPlanPerformanceCard() {
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
              Text('Plan Performance', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              Text('This Month ∨', style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 14),
          _buildPerformanceRow('Trial Pass', '251', '+8.2%', Icons.star_border_rounded, Colors.amber),
          _buildPerformanceRow('Starter', '1,842', '+11.3%', Icons.rocket_launch_outlined, const Color(0xFF10B981)),
          _buildPerformanceRow('Pro', '6,732', '+15.7%', Icons.workspace_premium_outlined, const Color(0xFF8B5CF6)),
          _buildPerformanceRow('Ultimate', '4,015', '+21.4%', Icons.diamond_outlined, const Color(0xFF3B82F6)),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {},
            child: const Text('View Detailed Report →', style: TextStyle(fontSize: 11, color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceRow(String name, String count, String growth, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
          Text(count, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Text(growth, style: const TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ================= 10. PLAN FEATURES MANAGEMENT TABLE =================
  Widget _buildPlanFeaturesTable() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Plan Features Management', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  SizedBox(height: 2),
                  Text('Enable or disable features for individual plans.', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ],
              ),
              Row(
                children: [
                  const Text('View Plan: ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Pro (8 Months) ∨', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),

          // Table Headers
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              children: [
                Expanded(flex: 4, child: Text('Feature Name', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                Expanded(flex: 2, child: Center(child: Text('⭐ Trial', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))))),
                Expanded(flex: 2, child: Center(child: Text('🚀 Starter', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))))),
                Expanded(flex: 2, child: Center(child: Text('👑 Pro', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))))),
                Expanded(flex: 2, child: Center(child: Text('💎 Ultimate', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))))),
                Expanded(flex: 2, child: Center(child: Text('Actions', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))))),
              ],
            ),
          ),
          const Divider(height: 1),

          // Table Row 1
          _buildFeatureRow(
            'Unlimited Question Practice',
            'Access unlimited questions across all subjects and topics',
            _f1Trial, (v) => setState(() => _f1Trial = v),
            _f1Starter, (v) => setState(() => _f1Starter = v),
            _f1Pro, (v) => setState(() => _f1Pro = v),
            _f1Ultimate, (v) => setState(() => _f1Ultimate = v),
          ),
          const Divider(height: 1),

          // Table Row 2
          _buildFeatureRow(
            'Custom Practice',
            'Create custom practice sessions',
            _f2Trial, (v) => setState(() => _f2Trial = v),
            _f2Starter, (v) => setState(() => _f2Starter = v),
            _f2Pro, (v) => setState(() => _f2Pro = v),
            _f2Ultimate, (v) => setState(() => _f2Ultimate = v),
          ),
          const Divider(height: 1),

          // Table Row 3
          _buildFeatureRow(
            'Unlimited Mock Tests',
            'Access unlimited mock tests',
            _f3Trial, (v) => setState(() => _f3Trial = v),
            _f3Starter, (v) => setState(() => _f3Starter = v),
            _f3Pro, (v) => setState(() => _f3Pro = v),
            _f3Ultimate, (v) => setState(() => _f3Ultimate = v),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(
    String title,
    String sub,
    bool tVal, ValueChanged<bool> tOn,
    bool sVal, ValueChanged<bool> sOn,
    bool pVal, ValueChanged<bool> pOn,
    bool uVal, ValueChanged<bool> uOn,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text(sub, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          Expanded(flex: 2, child: Center(child: Switch(value: tVal, activeColor: const Color(0xFF10B981), onChanged: tOn))),
          Expanded(flex: 2, child: Center(child: Switch(value: sVal, activeColor: const Color(0xFF10B981), onChanged: sOn))),
          Expanded(flex: 2, child: Center(child: Switch(value: pVal, activeColor: const Color(0xFF10B981), onChanged: pOn))),
          Expanded(flex: 2, child: Center(child: Switch(value: uVal, activeColor: const Color(0xFF10B981), onChanged: uOn))),
          Expanded(
            flex: 2,
            child: Center(
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text('Edit', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ORDERS & TRANSACTIONS TAB
  // ===========================================================================
  String _ordersStatusFilter = 'All';

  Widget _buildOrdersTabContent() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: SupabaseService.fetchAdminOrders(statusFilter: _ordersStatusFilter),
      builder: (context, snapshot) {
        final orders = snapshot.data ?? [];
        final filterOptions = ['All', 'Completed', 'Pending', 'Failed'];

        return Container(
          padding: const EdgeInsets.all(24),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Customer Orders & Payments', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                      const SizedBox(height: 4),
                      Text('Real-time ledger of student test series purchases and subscription activations.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                  Row(
                    children: filterOptions.map((opt) {
                      final isSel = _ordersStatusFilter == opt;
                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: ChoiceChip(
                          label: Text(opt),
                          selected: isSel,
                          onSelected: (_) => setState(() => _ordersStatusFilter = opt),
                          selectedColor: const Color(0xFF4F46E5),
                          labelStyle: TextStyle(color: isSel ? Colors.white : const Color(0xFF475569), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (orders.isEmpty)
                Container(
                  padding: const EdgeInsets.all(36),
                  alignment: Alignment.center,
                  child: const Text('No orders matching the selected filter.', style: TextStyle(color: Color(0xFF64748B))),
                )
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Table(
                    border: TableBorder.all(color: const Color(0xFFE2E8F0)),
                    columnWidths: const {
                      0: FlexColumnWidth(2.5),
                      1: FlexColumnWidth(3),
                      2: FlexColumnWidth(2),
                      3: FlexColumnWidth(1.8),
                      4: FlexColumnWidth(1.8),
                      5: FlexColumnWidth(2.2),
                    },
                    children: [
                      TableRow(
                        decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                        children: const [
                          Padding(padding: EdgeInsets.all(12), child: Text('Order ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Padding(padding: EdgeInsets.all(12), child: Text('Student / Email', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Padding(padding: EdgeInsets.all(12), child: Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Padding(padding: EdgeInsets.all(12), child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Padding(padding: EdgeInsets.all(12), child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Padding(padding: EdgeInsets.all(12), child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        ],
                      ),
                      ...orders.map((ord) {
                        final id = ord['id']?.toString() ?? '';
                        final shortId = id.length > 14 ? '${id.substring(0, 14)}...' : id;
                        final name = ord['user_name']?.toString() ?? 'Student';
                        final email = ord['user_email']?.toString() ?? '';
                        final method = ord['payment_method']?.toString() ?? 'UPI';
                        final total = (ord['total_amount'] as num?)?.toDouble() ?? 0.0;
                        final status = (ord['status']?.toString() ?? 'completed').toLowerCase();
                        final dateStr = ord['created_at']?.toString() ?? '';
                        final shortDate = dateStr.length >= 10 ? dateStr.substring(0, 10) : '';

                        return TableRow(
                          children: [
                            Padding(padding: const EdgeInsets.all(12), child: Text(shortId, style: const TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold))),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  Text(email, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                                ],
                              ),
                            ),
                            Padding(padding: const EdgeInsets.all(12), child: Text(method, style: const TextStyle(fontSize: 12))),
                            Padding(padding: const EdgeInsets.all(12), child: Text('₹${total.toInt()}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: status == 'completed' ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: status == 'completed' ? const Color(0xFF059669) : const Color(0xFFD97706),
                                  ),
                                ),
                              ),
                            ),
                            Padding(padding: const EdgeInsets.all(12), child: Text(shortDate, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)))),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // COUPONS & OFFERS TAB
  // ===========================================================================
  Widget _buildCouponsTabContent() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: SupabaseService.fetchAdminCoupons(),
      builder: (context, snapshot) {
        final coupons = snapshot.data ?? [];

        return Container(
          padding: const EdgeInsets.all(24),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Promotional Coupons & Discounts', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                      const SizedBox(height: 4),
                      const Text('Create and manage discount codes for NEET & JEE test series packages.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _openCreateCouponModal(),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('New Coupon', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: coupons.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, idx) {
                  final c = coupons[idx];
                  final code = c['code']?.toString() ?? '';
                  final isPerc = c['discount_type'] == 'percentage';
                  final val = (c['discount_value'] as num?)?.toDouble() ?? 0.0;
                  final minP = (c['min_purchase'] as num?)?.toDouble() ?? 0.0;
                  final maxD = (c['max_discount'] as num?)?.toDouble() ?? 0.0;
                  final isActive = c['is_active'] == true;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFC7D2FE)),
                          ),
                          child: Text(
                            code,
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w900, color: const Color(0xFF4F46E5), letterSpacing: 1),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isPerc ? '$val% OFF (Max ₹${maxD.toInt()})' : 'Flat ₹${val.toInt()} OFF',
                                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Min cart purchase: ₹${minP.toInt()} • Applicable to all test series',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Text(isActive ? 'ACTIVE' : 'INACTIVE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isActive ? const Color(0xFF10B981) : const Color(0xFF94A3B8))),
                            const SizedBox(width: 8),
                            Switch(
                              value: isActive,
                              activeColor: const Color(0xFF10B981),
                              onChanged: (val) async {
                                final updated = Map<String, dynamic>.from(c);
                                updated['is_active'] = val;
                                await SupabaseService.saveCoupon(updated);
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openCreateCouponModal() {
    final codeCtrl = TextEditingController();
    final valCtrl = TextEditingController();
    final minCtrl = TextEditingController();
    String discountType = 'percentage';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 440,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Create New Promo Coupon', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Coupon Code (e.g. JEE2026)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: discountType,
                        decoration: const InputDecoration(labelText: 'Discount Type', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'percentage', child: Text('Percentage (%)')),
                          DropdownMenuItem(value: 'fixed', child: Text('Fixed Amount (₹)')),
                        ],
                        onChanged: (val) => setDialogState(() => discountType = val ?? 'percentage'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: valCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: discountType == 'percentage' ? 'Value (%)' : 'Amount (₹)', border: const OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: minCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Minimum Cart Subtotal (₹)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
                      onPressed: () async {
                        final code = codeCtrl.text.trim().toUpperCase();
                        final val = double.tryParse(valCtrl.text.trim()) ?? 10.0;
                        final minP = double.tryParse(minCtrl.text.trim()) ?? 0.0;
                        if (code.isNotEmpty) {
                          await SupabaseService.saveCoupon({
                            'code': code,
                            'discount_type': discountType,
                            'discount_value': val,
                            'min_purchase': minP,
                            'max_discount': 500.0,
                            'is_active': true,
                            'usage_limit': 1000,
                          });
                          Navigator.pop(ctx);
                          setState(() {});
                        }
                      },
                      child: const Text('Save & Publish Coupon'),
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

  // ===========================================================================
  // SUBSCRIBERS TAB
  // ===========================================================================
  Widget _buildSubscribersTabContent() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: SupabaseService.fetchAdminSubscriptions(),
      builder: (context, snapshot) {
        final subs = snapshot.data ?? [];

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Subscribers Roster', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
              const SizedBox(height: 4),
              const Text('Active student subscriptions with expiry and auto-renew tracking.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 20),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: subs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, idx) {
                  final s = subs[idx];
                  final email = s['user_email']?.toString() ?? '';
                  final plan = s['plan_title']?.toString() ?? 'Plan';
                  final status = s['status']?.toString() ?? 'active';
                  final amount = (s['amount'] as num?)?.toDouble() ?? 299.0;
                  final cycle = s['billing_cycle']?.toString() ?? 'yearly';
                  final endDate = s['end_date']?.toString() ?? '';
                  final endStr = endDate.length >= 10 ? endDate.substring(0, 10) : '';

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFF4F46E5),
                          radius: 18,
                          child: Text(email.isNotEmpty ? email[0].toUpperCase() : 'S', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(plan, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                              const SizedBox(height: 2),
                              Text('$email • $cycle billing (₹${amount.toInt()})', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(4)),
                              child: Text(status.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                            ),
                            const SizedBox(height: 4),
                            Text('Expires: $endStr', style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
