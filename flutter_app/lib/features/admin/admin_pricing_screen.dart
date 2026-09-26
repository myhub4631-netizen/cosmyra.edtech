import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/models.dart';
import '../../core/services/supabase_service.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/utils/smooth_page_route.dart';
import 'admin_dashboard_screen.dart';
import 'admin_user_management_screen.dart';

class AdminPricingScreen extends StatefulWidget {
  final UserProfileModel userProfile;
  final bool autoOpenPaymentModal;

  const AdminPricingScreen({
    Key? key,
    required this.userProfile,
    this.autoOpenPaymentModal = false,
  }) : super(key: key);

  @override
  State<AdminPricingScreen> createState() => _AdminPricingScreenState();
}

class _AdminPricingScreenState extends State<AdminPricingScreen> {
  String _activeTab = 'Plans'; // Plans, Features, Plan Comparisons, Subscribers, Settings
  bool _showInactivePlans = false;
  String _selectedDefaultPlan = 'Pro (8 Months)';
  bool _allowDowngrade = true;
  bool _allowUpgrade = true;

  @override
  void initState() {
    super.initState();
    if (widget.autoOpenPaymentModal) {
      _activeTab = 'Payment Gateways';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPaymentGatewayModal(context);
      });
    }
  }
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

                        // Sub-navigation Tabs (Plans, Payment Gateways, Orders & Transactions, Coupons & Offers, Subscribers, Settings)
                        _buildSubNavTabs(),
                        const SizedBox(height: 24),

                        // Prominent Payment Gateways Banner Card (when on Plans tab)
                        if (_activeTab == 'Plans') ...[
                          _buildPaymentGatewayBannerCard(),
                          const SizedBox(height: 24),
                        ],

                        // Top 5 Metrics Cards Row
                        _buildTopMetricsRow(),
                        const SizedBox(height: 24),

                        // Main Content: Dynamic Tabs
                        if (_activeTab == 'Payment Gateways')
                          const _PaymentGatewaysConfigCard()
                        else if (_activeTab == 'Orders & Transactions')
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
                _buildSidebarTile('Pricing & Plans', Icons.monetization_on_outlined, _activeTab == 'Plans', onTap: () => setState(() => _activeTab = 'Plans')),
                _buildSidebarTile('💳 Payment Gateways', Icons.payment_rounded, _activeTab == 'Payment Gateways', onTap: () => setState(() => _activeTab = 'Payment Gateways')),
                _buildSidebarTile('Coupons & Offers', Icons.local_offer_outlined, _activeTab == 'Coupons & Offers', onTap: () => setState(() => _activeTab = 'Coupons & Offers')),
                _buildSidebarTile('Transactions', Icons.receipt_long_outlined, _activeTab == 'Orders & Transactions', onTap: () => setState(() => _activeTab = 'Orders & Transactions')),
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
              AppAvatar.fromProfile(
                widget.userProfile,
                size: 32,
                backgroundColor: const Color(0xFF6366F1),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userProfile.fullName.isNotEmpty ? widget.userProfile.fullName : 'Admin User',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    widget.userProfile.isSuperAdmin ? 'Super Administrator' : 'Administrator',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _activeTab == 'Payment Gateways' ? 'Payment Gateways & Settings' : 'Pricing & Plans',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 2),
            Text(
              _activeTab == 'Payment Gateways'
                  ? 'Configure UPI merchant VPA, Payee Name, Cashfree App ID & Secret credentials.'
                  : 'Manage subscription plans, pricing, features, payment gateways and user access.',
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => setState(() => _activeTab = 'Payment Gateways'),
              icon: const Icon(Icons.payment_rounded, size: 18, color: Color(0xFF10B981)),
              label: const Text('💳 Payment Settings', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(width: 12),
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
        ),
      ],
    );
  }

  // ================= PAYMENT GATEWAYS BANNER CARD =================
  Widget _buildPaymentGatewayBannerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x1A000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.payment_rounded, color: Color(0xFF10B981), size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '💳 Payment Gateways Configuration',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: const BoxDecoration(color: Color(0xFF10B981), borderRadius: BorderRadius.all(Radius.circular(10))),
                      child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage UPI Merchant ID, Payee Name, QR Code verification, and Cashfree PG App ID & Secret Key.',
                  style: TextStyle(fontSize: 12.5, color: Colors.grey[300]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () => setState(() => _activeTab = 'Payment Gateways'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            icon: const Icon(Icons.settings_rounded, size: 18),
            label: const Text('Configure Gateways', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // ================= 4. SUB-NAVIGATION TABS =================
  Widget _buildSubNavTabs() {
    final tabs = ['Plans', 'Payment Gateways', 'Orders & Transactions', 'Coupons & Offers', 'Subscribers', 'Settings'];
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
          _buildQuickActionItem('💳 Configure Payment Gateways (UPI & Cashfree)', Icons.payment_rounded, const Color(0xFF10B981), () => _showPaymentGatewayModal(context)),
          _buildQuickActionItem('+ Add New Plan', Icons.add, const Color(0xFF4F46E5), _openCreatePlanModal),
          _buildQuickActionItem('Manage Features', Icons.tune, const Color(0xFF64748B), () {}),
          _buildQuickActionItem('Plan Comparison', Icons.bar_chart, const Color(0xFF64748B), () {}),
          _buildQuickActionItem('Bulk Update Prices', Icons.sell_outlined, const Color(0xFF64748B), () {}),
          _buildQuickActionItem('Import/Export Plans', Icons.import_export, const Color(0xFF64748B), () {}),
        ],
      ),
    );
  }

  void _showPaymentGatewayModal(BuildContext context) async {
    final settings = await SupabaseService.fetchPaymentSettings();
    bool upiActive = SupabaseService.parseBool(settings['upi_active'], defaultValue: true);
    final upiIdCtrl = TextEditingController(text: (settings['upi_id'] ?? '1mdollar2027@okicici').toString());
    final upiPayeeCtrl = TextEditingController(text: (settings['upi_payee_name'] ?? 'Cosmyra Edu Platform').toString());

    bool cashfreeActive = SupabaseService.parseBool(settings['cashfree_active'], defaultValue: true);
    final cashfreeAppIdCtrl = TextEditingController(text: (settings['cashfree_app_id'] ?? '').toString());
    final cashfreeSecretCtrl = TextEditingController(text: (settings['cashfree_secret_key'] ?? '').toString());
    String cashfreeEnv = (settings['cashfree_environment'] ?? 'TEST').toString();

    bool isSaving = false;

    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setModalState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              width: 580,
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.payment_rounded, color: Color(0xFF4F46E5), size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Payment Gateways & Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                              Text('Control active payment options at checkout (UPI Pay, Cashfree PG)', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const Divider(height: 28),

                    // SECTION 1: UPI PAY SETTINGS
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: upiActive ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: upiActive ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF2563EB), size: 20),
                                  SizedBox(width: 8),
                                  Text('1} UPI Pay (GPay, PhonePe, Paytm, BHIM)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
                                ],
                              ),
                              Switch(
                                value: upiActive,
                                activeColor: const Color(0xFF2563EB),
                                onChanged: (val) => setModalState(() => upiActive = val),
                              ),
                            ],
                          ),
                          if (upiActive) ...[
                            const SizedBox(height: 12),
                            TextField(
                              controller: upiIdCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Merchant UPI ID (VPA)',
                                hintText: 'e.g. cosmyra@ybl or 1mdollar2027@okicici',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: upiPayeeCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Merchant / Payee Display Name',
                                hintText: 'e.g. Cosmyra Edu Platform',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text('• Mobile Users: Opens native installed UPI app automatically.\n• Web Users: Displays QR Code + Copy UPI ID + UTR entry box.', style: TextStyle(fontSize: 11, color: Color(0xFF475569))),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // SECTION 2: CASHFREE PG SETTINGS
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cashfreeActive ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: cashfreeActive ? const Color(0xFF6EE7B7) : const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.shield_rounded, color: Color(0xFF059669), size: 20),
                                  SizedBox(width: 8),
                                  Text('2} Cashfree Payment Gateway', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
                                ],
                              ),
                              Switch(
                                value: cashfreeActive,
                                activeColor: const Color(0xFF059669),
                                onChanged: (val) => setModalState(() => cashfreeActive = val),
                              ),
                            ],
                          ),
                          if (cashfreeActive) ...[
                            const SizedBox(height: 12),
                            TextField(
                              controller: cashfreeAppIdCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Cashfree App ID (Client ID)',
                                hintText: 'e.g. TEST103444...',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: cashfreeSecretCtrl,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Cashfree Secret Key',
                                hintText: 'e.g. TEST418c39...',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Text('Environment: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ChoiceChip(
                                  label: const Text('TEST (Sandbox)'),
                                  selected: cashfreeEnv == 'TEST',
                                  onSelected: (sel) {
                                    if (sel) setModalState(() => cashfreeEnv = 'TEST');
                                  },
                                ),
                                const SizedBox(width: 8),
                                ChoiceChip(
                                  label: const Text('PROD (Live)'),
                                  selected: cashfreeEnv == 'PROD',
                                  onSelected: (sel) {
                                    if (sel) setModalState(() => cashfreeEnv = 'PROD');
                                  },
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: isSaving
                              ? null
                              : () async {
                                  setModalState(() => isSaving = true);
                                  await SupabaseService.savePaymentSettings({
                                    'upi_active': upiActive,
                                    'upi_id': upiIdCtrl.text.trim(),
                                    'upi_payee_name': upiPayeeCtrl.text.trim(),
                                    'cashfree_active': cashfreeActive,
                                    'cashfree_app_id': cashfreeAppIdCtrl.text.trim(),
                                    'cashfree_secret_key': cashfreeSecretCtrl.text.trim(),
                                    'cashfree_environment': cashfreeEnv,
                                  });
                                  if (context.mounted) {
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('✓ Payment Gateway settings saved and active on website & app!'),
                                        backgroundColor: Color(0xFF10B981),
                                      ),
                                    );
                                  }
                                },
                          icon: isSaving
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Save & Update Checkout'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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
  String _ordersSearchQuery = '';

  Future<void> _approveOrderPricing(Map<String, dynamic> ord) async {
    final rawId = (ord['order_number'] ?? ord['order_id'] ?? ord['id'] ?? '').toString();
    final uid = (ord['user_id'] ?? ord['student_id'] ?? '').toString();
    final user = UserProfileModel(
      id: uid.isNotEmpty ? uid : 'usr_${DateTime.now().millisecondsSinceEpoch}',
      email: (ord['user_email'] ?? ord['student_email'] ?? 'student@cosmyra.in').toString(),
      fullName: (ord['user_name'] ?? ord['student_name'] ?? 'Student Aspirant').toString(),
    );

    final items = [
      {
        'id': ord['product_id'] ?? 'ts_all_access',
        'title': ord['product_name'] ?? 'NEET/JEE Test Series',
      }
    ];

    await SupabaseService.verifyPaymentAndGrantAccess(
      orderId: rawId,
      paymentId: (ord['payment_id'] ?? ord['payment_reference'] ?? 'UPI_VERIFIED').toString(),
      paymentMethod: (ord['payment_method'] ?? 'UPI').toString(),
      user: user,
      items: items,
    );

    await SupabaseService.updateAdminOrderStatus(
      orderId: rawId,
      newStatus: 'completed',
      adminNote: 'UPI Payment UTR verified and access granted by Admin',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Order #$rawId Approved & Access Granted!'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {});
    }
  }

  Future<void> _deleteOrderPricing(String orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Order?'),
        content: Text('Are you sure you want to permanently delete order #$orderId from database?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await SupabaseService.deleteAdminOrder(orderId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Order #$orderId deleted.'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {});
      }
    }
  }

  void _showCreateManualOrderDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final productCtrl = TextEditingController(text: 'NEET 2026 Full Test Series');
    final amountCtrl = TextEditingController(text: '499');
    final utrCtrl = TextEditingController();
    String method = 'UPI';
    String status = 'completed';
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 520,
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Create Manual Order / Grant Access', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                      IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                    ],
                  ),
                  const Divider(height: 20),
                  const Text('Student Name *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  TextField(controller: nameCtrl, decoration: InputDecoration(hintText: 'e.g. Rahul Sharma', isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
                  const SizedBox(height: 12),
                  const Text('Student Email *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  TextField(controller: emailCtrl, decoration: InputDecoration(hintText: 'e.g. rahul@gmail.com', isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
                  const SizedBox(height: 12),
                  const Text('Student Phone', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  TextField(controller: phoneCtrl, decoration: InputDecoration(hintText: 'e.g. 9876543210', isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Product Title', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            TextField(controller: productCtrl, decoration: InputDecoration(isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 120,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Amount (₹)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Payment Method', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            DropdownButtonFormField<String>(
                              value: method,
                              decoration: InputDecoration(isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                              items: const [
                                DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                                DropdownMenuItem(value: 'Cashfree PG', child: Text('Cashfree PG')),
                                DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
                                DropdownMenuItem(value: 'Cash / Offline', child: Text('Cash / Offline')),
                              ],
                              onChanged: (v) => setDialogState(() => method = v!),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            DropdownButtonFormField<String>(
                              value: status,
                              decoration: InputDecoration(isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                              items: const [
                                DropdownMenuItem(value: 'completed', child: Text('Completed (Grant Access)')),
                                DropdownMenuItem(value: 'pending_verification', child: Text('Pending Verification')),
                                DropdownMenuItem(value: 'pending', child: Text('Pending Payment')),
                              ],
                              onChanged: (v) => setDialogState(() => status = v!),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('UTR / Reference / Notes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  TextField(controller: utrCtrl, decoration: InputDecoration(hintText: 'e.g. 12-digit UTR 429182736410 or Admin grant note', isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      onPressed: isSaving
                          ? null
                          : () async {
                              final name = nameCtrl.text.trim();
                              final email = emailCtrl.text.trim();
                              if (name.isEmpty || email.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter Student Name and Email.'), backgroundColor: Color(0xFFEF4444)));
                                return;
                              }
                              setDialogState(() => isSaving = true);
                              final amt = double.tryParse(amountCtrl.text.trim()) ?? 499.0;
                              await SupabaseService.createManualAdminOrder(
                                studentName: name,
                                studentEmail: email,
                                studentPhone: phoneCtrl.text.trim(),
                                productName: productCtrl.text.trim(),
                                amount: amt,
                                paymentMethod: method,
                                status: status,
                                utrOrNotes: utrCtrl.text.trim(),
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ Manual Order Created successfully!'), backgroundColor: Color(0xFF10B981)));
                                setState(() {});
                              }
                            },
                      icon: isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.add_task_rounded, size: 18),
                      label: Text(isSaving ? 'Creating Order...' : 'Create Order & Save'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showPricingOrderDetailsDialog(Map<String, dynamic> ord) {
    final id = (ord['order_number'] ?? ord['order_id'] ?? ord['id'] ?? '').toString();
    final name = (ord['user_name'] ?? ord['student_name'] ?? 'Student').toString();
    final email = (ord['user_email'] ?? ord['student_email'] ?? '-').toString();
    final phone = (ord['user_phone'] ?? ord['student_phone'] ?? '-').toString();
    final product = (ord['product_name'] ?? 'NEET/JEE Test Series').toString();
    final amount = (ord['total_amount'] ?? ord['subtotal_amount'] ?? 0).toString();
    final method = (ord['payment_method'] ?? 'UPI').toString();
    final ref = (ord['payment_reference'] ?? ord['payment_id'] ?? '-').toString();
    final status = (ord['status'] ?? ord['payment_status'] ?? 'completed').toString();
    final date = (ord['created_at'] ?? '').toString();
    final notes = (ord['notes'] ?? 'Order placed via portal').toString();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 520,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Order #$id', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: status == 'completed' ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(status.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: status == 'completed' ? const Color(0xFF059669) : const Color(0xFFD97706))),
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildDetailItem('Student Name', name),
              _buildDetailItem('Student Email', email),
              _buildDetailItem('Mobile Phone', phone),
              _buildDetailItem('Product Purchased', product),
              _buildDetailItem('Total Amount', '₹$amount'),
              _buildDetailItem('Payment Gateway', method),
              _buildDetailItem('UTR / Reference ID', ref),
              _buildDetailItem('Order Date', date),
              _buildDetailItem('Audit / System Notes', notes),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (status == 'pending_verification' || status == 'pending')
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _approveOrderPricing(ord);
                      },
                      icon: const Icon(Icons.check_circle_rounded, size: 16),
                      label: const Text('Approve & Grant Access'),
                    )
                  else
                    const SizedBox.shrink(),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444)),
                        tooltip: 'Delete Order',
                        onPressed: () {
                          Navigator.pop(ctx);
                          _deleteOrderPricing(id);
                        },
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
          Expanded(child: SelectableText(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
        ],
      ),
    );
  }

  Widget _buildOrdersTabContent() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: SupabaseService.fetchAdminOrders(statusFilter: _ordersStatusFilter),
      builder: (context, snapshot) {
        final allOrders = snapshot.data ?? [];

        // Apply client search query
        final orders = allOrders.where((ord) {
          if (_ordersSearchQuery.trim().isEmpty) return true;
          final q = _ordersSearchQuery.trim().toLowerCase();
          final id = (ord['id'] ?? ord['order_number'] ?? '').toString().toLowerCase();
          final name = (ord['user_name'] ?? ord['student_name'] ?? '').toString().toLowerCase();
          final email = (ord['user_email'] ?? ord['student_email'] ?? '').toString().toLowerCase();
          final phone = (ord['user_phone'] ?? ord['student_phone'] ?? '').toString().toLowerCase();
          final ref = (ord['payment_reference'] ?? ord['payment_id'] ?? '').toString().toLowerCase();
          final product = (ord['product_name'] ?? '').toString().toLowerCase();
          return id.contains(q) || name.contains(q) || email.contains(q) || phone.contains(q) || ref.contains(q) || product.contains(q);
        }).toList();

        final filterOptions = ['All', 'Completed', 'Pending Verification', 'Pending', 'Failed'];

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
                      Text('Real-time ledger of student test series purchases and subscription activations.', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _showCreateManualOrderDialog,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Create Manual Order', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, color: Color(0xFF4F46E5)),
                        tooltip: 'Refresh Orders',
                        onPressed: () => setState(() {}),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search & Filter Row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => _ordersSearchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Search by Order ID, Student Name, Email, UTR number...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF64748B)),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: filterOptions.map((opt) {
                        final isSel = _ordersStatusFilter == opt;
                        return Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: ChoiceChip(
                            label: Text(opt),
                            selected: isSel,
                            onSelected: (_) => setState(() => _ordersStatusFilter = opt),
                            selectedColor: const Color(0xFF4F46E5),
                            labelStyle: TextStyle(color: isSel ? Colors.white : const Color(0xFF475569), fontSize: 11.5, fontWeight: FontWeight.bold),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (orders.isEmpty)
                Container(
                  padding: const EdgeInsets.all(40),
                  alignment: Alignment.center,
                  child: const Column(
                    children: [
                      Icon(Icons.inbox_outlined, size: 48, color: Color(0xFF94A3B8)),
                      SizedBox(height: 12),
                      Text('No orders matching the selected query or filter.', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                    ],
                  ),
                )
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Table(
                    border: TableBorder.all(color: const Color(0xFFE2E8F0)),
                    columnWidths: const {
                      0: FlexColumnWidth(2.2),
                      1: FlexColumnWidth(2.8),
                      2: FlexColumnWidth(2.2),
                      3: FlexColumnWidth(2.2),
                      4: FlexColumnWidth(1.4),
                      5: FlexColumnWidth(2.2),
                      6: FlexColumnWidth(1.6),
                      7: FlexColumnWidth(1.8),
                    },
                    children: [
                      TableRow(
                        decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                        children: const [
                          Padding(padding: EdgeInsets.all(10), child: Text('Order ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                          Padding(padding: EdgeInsets.all(10), child: Text('Student / Email', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                          Padding(padding: EdgeInsets.all(10), child: Text('Product', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                          Padding(padding: EdgeInsets.all(10), child: Text('Payment / UTR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                          Padding(padding: EdgeInsets.all(10), child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                          Padding(padding: EdgeInsets.all(10), child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                          Padding(padding: EdgeInsets.all(10), child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                          Padding(padding: EdgeInsets.all(10), child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                        ],
                      ),
                      ...orders.map((ord) {
                        final rawId = (ord['order_number'] ?? ord['order_id'] ?? ord['id'] ?? '').toString();
                        final shortId = rawId.length > 14 ? '${rawId.substring(0, 14)}...' : rawId;
                        final name = ord['user_name']?.toString() ?? ord['student_name']?.toString() ?? 'Student';
                        final email = ord['user_email']?.toString() ?? ord['student_email']?.toString() ?? '';
                        final product = ord['product_name']?.toString() ?? 'NEET Test Series';
                        final method = ord['payment_method']?.toString() ?? 'UPI';
                        final ref = (ord['payment_reference'] ?? ord['payment_id'] ?? '').toString();
                        final total = (ord['total_amount'] as num?)?.toDouble() ?? (ord['amount'] as num?)?.toDouble() ?? 0.0;
                        final status = (ord['status']?.toString() ?? ord['payment_status']?.toString() ?? 'completed').toLowerCase();
                        final dateStr = ord['created_at']?.toString() ?? '';
                        final shortDate = dateStr.length >= 10 ? dateStr.substring(0, 10) : '';

                        return TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: InkWell(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: rawId));
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied Order ID to clipboard!'), duration: Duration(seconds: 1)));
                                },
                                child: Text(shortId, style: const TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                  Text(email, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                ],
                              ),
                            ),
                            Padding(padding: const EdgeInsets.all(10), child: Text(product, style: const TextStyle(fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis)),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(method, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                  if (ref.isNotEmpty) SelectableText(ref, style: const TextStyle(fontSize: 9.5, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            Padding(padding: const EdgeInsets.all(10), child: Text('₹${total.toInt()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                decoration: BoxDecoration(
                                  color: status == 'completed' ? const Color(0xFFECFDF5) : (status == 'pending_verification' ? const Color(0xFFFEF3C7) : const Color(0xFFFEE2E2)),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  status == 'pending_verification' ? 'PENDING UTR' : status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: status == 'completed' ? const Color(0xFF059669) : (status == 'pending_verification' ? const Color(0xFFD97706) : const Color(0xFFDC2626)),
                                  ),
                                ),
                              ),
                            ),
                            Padding(padding: const EdgeInsets.all(10), child: Text(shortDate, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)))),
                            Padding(
                              padding: const EdgeInsets.all(6),
                              child: Row(
                                children: [
                                  if (status == 'pending_verification' || status == 'pending')
                                    IconButton(
                                      icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                                      tooltip: 'Approve & Grant Access',
                                      onPressed: () => _approveOrderPricing(ord),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.visibility_rounded, color: Color(0xFF4F46E5), size: 18),
                                    tooltip: 'View Order Details',
                                    onPressed: () => _showPricingOrderDetailsDialog(ord),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
                                    tooltip: 'Delete Order',
                                    onPressed: () => _deleteOrderPricing(rawId),
                                  ),
                                ],
                              ),
                            ),
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

class _PaymentGatewaysConfigCard extends StatefulWidget {
  const _PaymentGatewaysConfigCard({Key? key}) : super(key: key);

  @override
  State<_PaymentGatewaysConfigCard> createState() => _PaymentGatewaysConfigCardState();
}

class _PaymentGatewaysConfigCardState extends State<_PaymentGatewaysConfigCard> {
  bool _isLoading = true;
  bool _isSaving = false;

  bool _upiActive = true;
  late TextEditingController _upiIdCtrl;
  late TextEditingController _upiPayeeCtrl;

  bool _cashfreeActive = true;
  late TextEditingController _cashfreeAppIdCtrl;
  late TextEditingController _cashfreeSecretCtrl;
  String _cashfreeEnv = 'TEST';

  @override
  void initState() {
    super.initState();
    _upiIdCtrl = TextEditingController(text: '1mdollar2027@okicici');
    _upiPayeeCtrl = TextEditingController(text: 'Cosmyra Edu Platform');
    _cashfreeAppIdCtrl = TextEditingController();
    _cashfreeSecretCtrl = TextEditingController();
    _loadSettings();
  }

  @override
  void dispose() {
    _upiIdCtrl.dispose();
    _upiPayeeCtrl.dispose();
    _cashfreeAppIdCtrl.dispose();
    _cashfreeSecretCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final settings = await SupabaseService.fetchPaymentSettings();
    if (mounted) {
      setState(() {
        _upiActive = SupabaseService.parseBool(settings['upi_active'], defaultValue: true);
        _upiIdCtrl.text = (settings['upi_id'] ?? '1mdollar2027@okicici').toString();
        _upiPayeeCtrl.text = (settings['upi_payee_name'] ?? 'Cosmyra Edu Platform').toString();

        _cashfreeActive = SupabaseService.parseBool(settings['cashfree_active'], defaultValue: true);
        _cashfreeAppIdCtrl.text = (settings['cashfree_app_id'] ?? '').toString();
        _cashfreeSecretCtrl.text = (settings['cashfree_secret_key'] ?? '').toString();
        _cashfreeEnv = (settings['cashfree_environment'] ?? 'TEST').toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    final success = await SupabaseService.savePaymentSettings({
      'upi_active': _upiActive,
      'upi_id': _upiIdCtrl.text.trim(),
      'upi_payee_name': _upiPayeeCtrl.text.trim(),
      'cashfree_active': _cashfreeActive,
      'cashfree_app_id': _cashfreeAppIdCtrl.text.trim(),
      'cashfree_secret_key': _cashfreeSecretCtrl.text.trim(),
      'cashfree_environment': _cashfreeEnv,
    });
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '✅ Payment Gateway Settings Saved Successfully!' : '❌ Failed to save payment gateway settings'),
          backgroundColor: success ? const Color(0xFF10B981) : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.payment_rounded, color: Color(0xFF4F46E5), size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Payment Gateways & Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    SizedBox(height: 2),
                    Text('Manage active payment methods, UPI merchant details, and Cashfree API credentials for user checkout.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // SECTION 1: UPI PAY
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _upiActive ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _upiActive ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF2563EB), size: 22),
                        SizedBox(width: 10),
                        Text('1} UPI Pay (GPay, PhonePe, Paytm, BHIM)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
                      ],
                    ),
                    Switch(
                      value: _upiActive,
                      activeColor: const Color(0xFF2563EB),
                      onChanged: (val) => setState(() => _upiActive = val),
                    ),
                  ],
                ),
                if (_upiActive) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _upiIdCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Merchant UPI ID (VPA)',
                            hintText: 'e.g. 1mdollar2027@okicici',
                            isDense: true,
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.qr_code_2_rounded, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _upiPayeeCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Merchant / Payee Display Name',
                            hintText: 'e.g. Cosmyra Edu Platform',
                            isDense: true,
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.store_rounded, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFBFDBFE))),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF2563EB)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '• Mobile App: Automatically triggers native installed UPI apps (GPay/PhonePe/Paytm/BHIM).\n'
                            '• Web: Renders payment QR code + copy UPI ID + 12-digit UTR transaction submission modal. Admin verifies in Orders.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF), height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // SECTION 2: CASHFREE PG
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _cashfreeActive ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _cashfreeActive ? const Color(0xFF6EE7B7) : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.shield_rounded, color: Color(0xFF059669), size: 22),
                        SizedBox(width: 10),
                        Text('2} Cashfree Payment Gateway', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
                      ],
                    ),
                    Switch(
                      value: _cashfreeActive,
                      activeColor: const Color(0xFF059669),
                      onChanged: (val) => setState(() => _cashfreeActive = val),
                    ),
                  ],
                ),
                if (_cashfreeActive) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _cashfreeAppIdCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Cashfree App ID (Client ID)',
                            hintText: 'e.g. TEST10098273...',
                            isDense: true,
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.key_rounded, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _cashfreeSecretCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Cashfree Secret Key',
                            hintText: 'Enter Secret Key',
                            isDense: true,
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lock_outline_rounded, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Environment: ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        label: const Text('TEST (Sandbox)'),
                        selected: _cashfreeEnv == 'TEST',
                        selectedColor: const Color(0xFFFEF3C7),
                        labelStyle: TextStyle(color: _cashfreeEnv == 'TEST' ? const Color(0xFFD97706) : Colors.black87, fontWeight: FontWeight.bold),
                        onSelected: (sel) {
                          if (sel) setState(() => _cashfreeEnv = 'TEST');
                        },
                      ),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: const Text('PRODUCTION (Live)'),
                        selected: _cashfreeEnv == 'PROD',
                        selectedColor: const Color(0xFFD1FAE5),
                        labelStyle: TextStyle(color: _cashfreeEnv == 'PROD' ? const Color(0xFF059669) : Colors.black87, fontWeight: FontWeight.bold),
                        onSelected: (sel) {
                          if (sel) setState(() => _cashfreeEnv = 'PROD');
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // SAVE BUTTON
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save_rounded),
              label: Text(_isSaving ? 'Saving Settings...' : 'Save Payment Settings', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
