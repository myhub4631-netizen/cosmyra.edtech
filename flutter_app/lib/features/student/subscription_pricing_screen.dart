import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/cart_service.dart';
import '../../core/services/supabase_service.dart';
import 'widgets/ecommerce_checkout_dialog.dart';

class SubscriptionPricingScreen extends StatefulWidget {
  const SubscriptionPricingScreen({super.key});

  @override
  State<SubscriptionPricingScreen> createState() => _SubscriptionPricingScreenState();
}

class _SubscriptionPricingScreenState extends State<SubscriptionPricingScreen> {
  List<Map<String, dynamic>> _plans = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // 'all', 'short', 'pro', 'annual'
  String _selectedPlanId = 'plan_pro'; // Default to Pro (Most Popular)
  int _expandedFaqIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() => _isLoading = true);
    final plans = await SupabaseService.fetchSubscriptionPlans();
    if (mounted) {
      setState(() {
        _plans = plans.where((p) => p['is_active'] != false).toList();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredPlans {
    if (_selectedFilter == 'short') {
      return _plans.where((p) {
        final days = (p['duration_days'] as num?)?.toInt() ?? 30;
        return days <= 120;
      }).toList();
    } else if (_selectedFilter == 'pro') {
      return _plans.where((p) {
        final days = (p['duration_days'] as num?)?.toInt() ?? 240;
        return days >= 180 && days <= 270;
      }).toList();
    } else if (_selectedFilter == 'annual') {
      return _plans.where((p) {
        final days = (p['duration_days'] as num?)?.toInt() ?? 365;
        return days >= 300;
      }).toList();
    }
    return _plans;
  }

  void _onChoosePlan(Map<String, dynamic> plan) {
    setState(() => _selectedPlanId = plan['id']?.toString() ?? '');

    final double price = (plan['price'] as num?)?.toDouble() ?? 449.0;
    final double origPrice = (plan['original_price'] as num?)?.toDouble() ?? 999.0;
    final String title = plan['title']?.toString() ?? 'Subscription Plan';
    final String id = plan['id']?.toString() ?? 'plan_${DateTime.now().millisecondsSinceEpoch}';
    final String duration = plan['duration_title']?.toString() ?? 'Plan Access';

    final int tests = (plan['mock_tests'] is int)
        ? plan['mock_tests'] as int
        : (int.tryParse(plan['mock_tests']?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '') ?? 50);

    final cartItem = CartItem(
      id: id,
      title: 'Cosmyra $title ($duration)',
      description: plan['description']?.toString() ?? '',
      productType: 'subscription',
      price: price,
      originalPrice: origPrice,
      validity: duration,
      testCount: tests,
    );

    // If on web or mobile dialog is preferred, open checkout dialog
    EcommerceCheckoutDialog.show(
      context,
      singleItem: cartItem,
      onStartTest: (testId, testTitle, duration) {
        context.go('/dashboard');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 950;
    final isTablet = screenWidth >= 650 && screenWidth < 950;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(context, isDesktop),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // 1. HERO HEADER SECTION
                  _buildHeroHeader(isDesktop),

                  // 2. TIMELINE FILTER CHIPS
                  _buildFilterChips(),

                  const SizedBox(height: 24),

                  // 3. PRICING CARDS (DESKTOP GRID OR MOBILE STACK)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 48.0 : (isTablet ? 24.0 : 16.0),
                    ),
                    child: isDesktop
                        ? _buildDesktopPlanGrid()
                        : _buildMobilePlanCards(),
                  ),

                  const SizedBox(height: 48),

                  // 4. COMPARISON MATRIX (DESKTOP & EXPANDABLE ON MOBILE)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 48.0 : (isTablet ? 24.0 : 16.0),
                    ),
                    child: _buildComparisonSection(isDesktop),
                  ),

                  const SizedBox(height: 48),

                  // 5. TRUST BADGES & PAYMENT SECURITY
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 48.0 : (isTablet ? 24.0 : 16.0),
                    ),
                    child: _buildTrustAndPaymentBanner(isDesktop),
                  ),

                  const SizedBox(height: 48),

                  // 6. STUDENT SUCCESS & TESTIMONIALS
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 48.0 : (isTablet ? 24.0 : 16.0),
                    ),
                    child: _buildTestimonialsSection(isDesktop),
                  ),

                  const SizedBox(height: 48),

                  // 7. FREQUENTLY ASKED QUESTIONS (FAQ)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 48.0 : (isTablet ? 24.0 : 16.0),
                    ),
                    child: _buildFaqSection(isDesktop),
                  ),

                  const SizedBox(height: 64),

                  // 8. FOOTER CALLOUT
                  _buildBottomCallout(isDesktop),
                ],
              ),
            ),
      // Sticky bottom bar on mobile for instant checkout of the selected plan
      bottomNavigationBar: (!isDesktop && _plans.isNotEmpty)
          ? _buildMobileStickyBottomBar()
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDesktop) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/dashboard');
          }
        },
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            'Cosmyra Subscription Plans',
            style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
      actions: [
        if (isDesktop) ...[
          TextButton(
            onPressed: () => context.go('/dashboard'),
            child: const Text('Dashboard', style: TextStyle(color: Color(0xFF475569))),
          ),
          TextButton(
            onPressed: () => context.go('/test-series'),
            child: const Text('Test Series', style: TextStyle(color: Color(0xFF475569))),
          ),
          const SizedBox(width: 8),
        ],
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Color(0xFF475569)),
          tooltip: 'Refresh Plans',
          onPressed: _loadPlans,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ================= 1. HERO HEADER =================
  Widget _buildHeroHeader(bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48.0 : 20.0,
        vertical: isDesktop ? 40.0 : 28.0,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFF1F5F9),
          ],
        ),
      ),
      child: Column(
        children: [
          // Trust Badge Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFFC7D2FE)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF4F46E5)),
                const SizedBox(width: 6),
                Text(
                  'TRUSTED BY 12,800+ NEET & JEE ASPIRANTS',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF4338CA),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Main Headline
          Text(
            'Simple, Transparent Prep Plans',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: isDesktop ? 38 : 26,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          // Subtitle
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Text(
              'Unlock unlimited full-syllabus mock tests, AI weakness analytics, and 15-year chapter-wise NTA PYQ banks. Upgrade your rank today.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: isDesktop ? 15 : 13.5,
                color: const Color(0xFF475569),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= 2. FILTER CHIPS =================
  Widget _buildFilterChips() {
    final filters = [
      {'id': 'all', 'label': 'All Plans'},
      {'id': 'short', 'label': 'Short-Term (1-4 Mo)'},
      {'id': 'pro', 'label': 'Pro Target (8 Months)'},
      {'id': 'annual', 'label': 'Complete 1-Year Pass'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: filters.map((f) {
          final isSelected = _selectedFilter == f['id'];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              selected: isSelected,
              label: Text(f['label'] as String),
              selectedColor: const Color(0xFF2563EB),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF475569),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                ),
              ),
              onSelected: (val) {
                if (val) setState(() => _selectedFilter = f['id'] as String);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // ================= 3. DESKTOP 4-COLUMN PLAN GRID =================
  Widget _buildDesktopPlanGrid() {
    final plans = _filteredPlans;
    if (plans.isEmpty) {
      return const Center(child: Text('No plans match this filter.'));
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: plans.map((plan) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: _buildPlanCard(plan, isDesktop: true),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ================= 3. MOBILE STACKED PLAN CARDS =================
  Widget _buildMobilePlanCards() {
    final plans = _filteredPlans;
    return Column(
      children: plans.map((plan) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: _buildPlanCard(plan, isDesktop: false),
        );
      }).toList(),
    );
  }

  // ================= PLAN CARD WIDGET =================
  Widget _buildPlanCard(Map<String, dynamic> plan, {required bool isDesktop}) {
    final String id = plan['id']?.toString() ?? '';
    final String title = plan['title']?.toString() ?? 'Plan';
    final String durationTitle = plan['duration_title']?.toString() ?? 'Duration';
    final String badge = plan['badge']?.toString() ?? '';
    final String description = plan['description']?.toString() ?? '';
    final double price = (plan['price'] as num?)?.toDouble() ?? 499.0;
    final double originalPrice = (plan['original_price'] as num?)?.toDouble() ?? 999.0;
    final String billingPeriod = plan['billing_period']?.toString() ?? '/ duration';
    final bool isPopular = plan['is_popular'] == true;
    final bool isSelected = _selectedPlanId == id;
    final String maxQuestions = plan['max_questions_per_day']?.toString() ?? 'Unlimited';
    final String mockTests = plan['mock_tests']?.toString() ?? 'Unlimited';
    final int featuresCount = (plan['features_count'] as num?)?.toInt() ?? 25;
    final List<dynamic> featuresList = plan['features'] is List ? plan['features'] as List : [];

    final int discountPct = originalPrice > price
        ? (((originalPrice - price) / originalPrice) * 100).round()
        : 0;

    // Theme Color Mapping
    Color themeColor;
    if (plan['badge_color'] is int) {
      themeColor = Color(plan['badge_color'] as int);
    } else {
      final String iconType = plan['icon_type']?.toString() ?? '';
      switch (iconType) {
        case 'star':
          themeColor = const Color(0xFFF59E0B);
          break;
        case 'rocket':
          themeColor = const Color(0xFF10B981);
          break;
        case 'trophy':
          themeColor = const Color(0xFF8B5CF6);
          break;
        case 'diamond':
          themeColor = const Color(0xFF2563EB);
          break;
        default:
          themeColor = const Color(0xFF4F46E5);
      }
    }

    IconData cardIcon;
    switch (plan['icon_type']?.toString()) {
      case 'star':
        cardIcon = Icons.star_rounded;
        break;
      case 'rocket':
        cardIcon = Icons.rocket_launch_rounded;
        break;
      case 'trophy':
        cardIcon = Icons.emoji_events_rounded;
        break;
      case 'diamond':
        cardIcon = Icons.diamond_rounded;
        break;
      default:
        cardIcon = Icons.school_rounded;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(isDesktop ? 22 : 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isPopular
                  ? const Color(0xFF8B5CF6)
                  : (isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0)),
              width: (isPopular || isSelected) ? 2.2 : 1.0,
            ),
            boxShadow: [
              if (isPopular)
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                )
              else
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Icon + Badge + Duration
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(cardIcon, color: themeColor, size: 22),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          badge.isNotEmpty ? badge : durationTitle,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: themeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Plan Title
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),

                  // Duration text
                  Text(
                    durationTitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Price Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '₹${price.toStringAsFixed(0)}',
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        billingPeriod,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),

                  // Discount / Original Price Row
                  if (originalPrice > price) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '₹${originalPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$discountPct% OFF',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),

                  // Description
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF475569),
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 14),

                  // Core Highlights Pill Grid
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _buildHighlightRow(Icons.help_outline_rounded, 'Questions/Day', maxQuestions),
                        const SizedBox(height: 6),
                        _buildHighlightRow(Icons.assignment_outlined, 'Mock Tests', mockTests),
                        const SizedBox(height: 6),
                        _buildHighlightRow(Icons.verified_outlined, 'Features', '$featuresCount Included'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Key Checklist items
                  Text(
                    'What\'s Included:',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (featuresList.isNotEmpty)
                    ...featuresList.take(isDesktop ? 6 : 5).map((f) => Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 15, color: Color(0xFF10B981)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  f.toString(),
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    color: const Color(0xFF334155),
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ))
                  else ...[
                    _buildFeatureItem('Full Syllabus & Subject Mock Tests'),
                    _buildFeatureItem('Chapter Practice & Instant Solutions'),
                    _buildFeatureItem('Performance & Accuracy Diagnostics'),
                  ],
                ],
              ),

              const SizedBox(height: 20),

              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPopular
                        ? const Color(0xFF8B5CF6)
                        : (isSelected ? const Color(0xFF2563EB) : const Color(0xFF0F172A)),
                    foregroundColor: Colors.white,
                    elevation: isPopular ? 4 : 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => _onChoosePlan(plan),
                  child: Text(
                    isPopular ? 'Get Most Popular Pass' : 'Choose $title',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Most Popular floating tag on top
        if (isPopular)
          Positioned(
            top: -12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      'MOST POPULAR CHOICE',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHighlightRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF64748B)),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded, size: 15, color: Color(0xFF10B981)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: const Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= 4. COMPARISON MATRIX =================
  Widget _buildComparisonSection(bool isDesktop) {
    final comparisonRows = [
      {'feature': 'Access Duration', 'trial': '30 Days', 'starter': '4 Months', 'pro': '8 Months', 'ultimate': '1 Year'},
      {'feature': 'Questions Practice / Day', 'trial': '100 Qs', 'starter': 'Unlimited', 'pro': 'Unlimited', 'ultimate': 'Unlimited'},
      {'feature': 'Full Syllabus Mock Tests', 'trial': '5 / Month', 'starter': '10 / Month', 'pro': 'Unlimited', 'ultimate': 'Unlimited'},
      {'feature': 'NTA PYQ Question Banks', 'trial': '❌', 'starter': '5 Years', 'pro': '15 Years', 'ultimate': '15 Yrs + Video Sol.'},
      {'feature': 'AI Weakness & Error Radar', 'trial': 'Basic', 'starter': 'Subject Level', 'pro': 'Advanced AI', 'ultimate': 'Predictive AI'},
      {'feature': 'Custom Chapter Test Creator', 'trial': '❌', 'trial_bool': false, 'starter': '❌', 'starter_bool': false, 'pro': '✔', 'pro_bool': true, 'ultimate': '✔', 'ultimate_bool': true},
      {'feature': 'All-India Rank Percentile', 'trial': '❌', 'starter': '✔', 'pro': '✔', 'ultimate': '✔'},
      {'feature': 'Downloadable Offline PDFs', 'trial': '❌', 'starter': '❌', 'pro': '❌', 'ultimate': '✔'},
      {'feature': '1-on-1 Mentorship & Strategy', 'trial': '❌', 'starter': '❌', 'pro': '❌', 'ultimate': '✔'},
      {'feature': 'Price (INR)', 'trial': '₹99', 'starter': '₹249', 'pro': '₹449', 'ultimate': '₹689'},
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 28 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.table_chart_rounded, color: Color(0xFF2563EB), size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Feature Comparison Matrix',
                    style: GoogleFonts.outfit(
                      fontSize: isDesktop ? 20 : 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Side-by-side comparison across all 4 preparation plans',
                    style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Responsive Table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              columnSpacing: isDesktop ? 32 : 18,
              columns: const [
                DataColumn(label: Text('Feature', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
                DataColumn(label: Text('Trial Pass (₹99)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD97706)))),
                DataColumn(label: Text('Starter (₹249)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF059669)))),
                DataColumn(label: Text('Pro (₹449) ★', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)))),
                DataColumn(label: Text('Ultimate (₹689)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB)))),
              ],
              rows: comparisonRows.map((r) {
                return DataRow(
                  cells: [
                    DataCell(Text(r['feature'] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                    DataCell(_formatTableCell(r['trial'] as String)),
                    DataCell(_formatTableCell(r['starter'] as String)),
                    DataCell(_formatTableCell(r['pro'] as String, isPro: true)),
                    DataCell(_formatTableCell(r['ultimate'] as String, isUltimate: true)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formatTableCell(String val, {bool isPro = false, bool isUltimate = false}) {
    if (val == '✔') {
      return const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18);
    } else if (val == '❌') {
      return const Icon(Icons.cancel_rounded, color: Color(0xFFCBD5E1), size: 16);
    }
    return Text(
      val,
      style: TextStyle(
        fontSize: 12,
        fontWeight: (isPro || isUltimate) ? FontWeight.bold : FontWeight.normal,
        color: isPro
            ? const Color(0xFF7C3AED)
            : (isUltimate ? const Color(0xFF2563EB) : const Color(0xFF334155)),
      ),
    );
  }

  // ================= 5. TRUST & PAYMENT SECURITY =================
  Widget _buildTrustAndPaymentBanner(bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 24 : 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security_rounded, color: Color(0xFF10B981), size: 20),
              const SizedBox(width: 8),
              Text(
                '100% Secure Checkout & Instant Activation',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'We accept all major payment modes including UPI (Google Pay, PhonePe, Paytm), Debit/Credit Cards, and NetBanking.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildTrustPill(Icons.qr_code_2_rounded, 'Direct UPI & QR'),
              _buildTrustPill(Icons.bolt_rounded, 'Instant Test Access'),
              _buildTrustPill(Icons.lock_outline_rounded, '256-bit Bank Grade SSL'),
              _buildTrustPill(Icons.support_agent_rounded, '24/7 Student Support'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrustPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF2563EB)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
        ],
      ),
    );
  }

  // ================= 6. TESTIMONIALS SECTION =================
  Widget _buildTestimonialsSection(bool isDesktop) {
    final reviews = [
      {
        'name': 'Rahul Verma',
        'exam': 'NEET 2025 • AIR 642 (Score: 685)',
        'review': 'The Pro Plan was a game-changer for my physics and chemistry. The AI error detector showed exactly which chapter I was making silly mistakes in.',
        'rating': 5,
      },
      {
        'name': 'Pooja Sharma',
        'exam': 'NEET 2025 • AIR 1280 (Score: 668)',
        'review': 'Worth every rupee. The 15-year PYQ mock papers and line-by-line NCERT questions simulate the real NTA exam interface 100%.',
        'rating': 5,
      },
      {
        'name': 'Aditya Sen',
        'exam': 'JEE Main 2025 • 99.4 Percentile',
        'review': 'Clean interface, zero lag during 3-hour tests, and instant rank analytics. Customer support on WhatsApp activated my account in 1 minute.',
        'rating': 5,
      },
    ];

    return Column(
      children: [
        Text(
          'Ranker Stories & Aspirant Reviews',
          style: GoogleFonts.outfit(
            fontSize: isDesktop ? 22 : 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'See how students used Cosmyra subscription to boost their scores by 80+ marks',
          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
        ),
        const SizedBox(height: 20),
        isDesktop
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: reviews.map((r) => Expanded(child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: _buildReviewCard(r),
                ))).toList(),
              )
            : Column(
                children: reviews.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _buildReviewCard(r),
                )).toList(),
              ),
      ],
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> r) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(
              5,
              (i) => const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '"${r['review']}"',
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF334155), height: 1.4),
          ),
          const SizedBox(height: 12),
          Text(
            r['name'] as String,
            style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
          ),
          Text(
            r['exam'] as String,
            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF10B981), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ================= 7. FAQ ACCORDION =================
  Widget _buildFaqSection(bool isDesktop) {
    final faqs = [
      {
        'q': 'Which plan is recommended for NEET / JEE 2026 aspirants?',
        'a': 'For students targeting NEET or JEE 2026, the Pro Plan (8 Months, ₹449) is our most popular and comprehensive tier. It includes unlimited mock tests, complete 15-year PYQs, custom test creation, and our proprietary AI Error Pattern Radar.',
      },
      {
        'q': 'Can I upgrade my subscription plan later?',
        'a': 'Yes! You can upgrade from the Trial Pass or Starter Plan to Pro or Ultimate anytime. Your remaining days will be prorated automatically towards your new plan.',
      },
      {
        'q': 'Are tests available in both English and Hindi?',
        'a': 'Yes, questions and explanations can be toggled between English and Hindi directly inside the test window.',
      },
      {
        'q': 'Can I access Cosmyra on mobile and desktop web with the same login?',
        'a': 'Absolutely. Your subscription is tied to your account. You can log in seamlessly on our Android app, mobile browser, and desktop web platform (neet-jee.in).',
      },
      {
        'q': 'How quickly is my account activated after payment?',
        'a': 'Account activation is instant upon payment. If you pay via UPI QR code or Ref/UTR submission, access is verified and unlocked within minutes.',
      },
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 28 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF2F8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.help_outline_rounded, color: Color(0xFFDB2777), size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Frequently Asked Questions',
                    style: GoogleFonts.outfit(
                      fontSize: isDesktop ? 20 : 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Got questions about our subscription passes? Find answers below.',
                    style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...faqs.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final isExpanded = _expandedFaqIndex == idx;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isExpanded ? const Color(0xFFF8FAFC) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isExpanded ? const Color(0xFFCBD5E1) : const Color(0xFFF1F5F9),
                ),
              ),
              child: ExpansionTile(
                key: Key('faq_$idx'),
                initiallyExpanded: isExpanded,
                onExpansionChanged: (val) {
                  setState(() => _expandedFaqIndex = val ? idx : -1);
                },
                title: Text(
                  item['q']!,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Text(
                      item['a']!,
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569), height: 1.5),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ================= 8. BOTTOM CALLOUT =================
  Widget _buildBottomCallout(bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 20, vertical: 36),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
      ),
      child: Column(
        children: [
          Text(
            'Ready to Crack NEET & JEE with Confidence?',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: isDesktop ? 26 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Get unlimited full syllabus mocks, question banks, and AI ranking today starting at just ₹99.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.rocket_launch_rounded, size: 18),
            label: const Text('Unlock Your Pass Now', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              final defaultPlan = _plans.firstWhere(
                (p) => p['id'] == 'plan_pro',
                orElse: () => _plans.isNotEmpty ? _plans.first : {},
              );
              if (defaultPlan.isNotEmpty) {
                _onChoosePlan(defaultPlan);
              }
            },
          ),
        ],
      ),
    );
  }

  // ================= MOBILE STICKY BOTTOM BAR =================
  Widget _buildMobileStickyBottomBar() {
    final selectedPlan = _plans.firstWhere(
      (p) => p['id'] == _selectedPlanId,
      orElse: () => _plans.first,
    );
    final String title = selectedPlan['title']?.toString() ?? 'Pro Plan';
    final double price = (selectedPlan['price'] as num?)?.toDouble() ?? 449.0;
    final String duration = selectedPlan['duration_title']?.toString() ?? '8 Months';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '₹${price.toStringAsFixed(0)}',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        duration,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                      ),
                    ),
                  ],
                ),
                Text(
                  title,
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                ),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _onChoosePlan(selectedPlan),
              child: const Text('Upgrade Now', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
