import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/supabase_service.dart';

class RecommendedTestSeriesSection extends StatefulWidget {
  final VoidCallback? onViewAll;

  const RecommendedTestSeriesSection({
    Key? key,
    this.onViewAll,
  }) : super(key: key);

  @override
  State<RecommendedTestSeriesSection> createState() => _RecommendedTestSeriesSectionState();
}

class _RecommendedTestSeriesSectionState extends State<RecommendedTestSeriesSection> {
  List<Map<String, dynamic>> _recommendations = [];
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();
  int _activeDotIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    const cardWidthWithMargin = 270.0;
    final index = (_scrollController.offset / cardWidthWithMargin).round();
    if (index != _activeDotIndex && index >= 0 && index < _recommendations.length) {
      setState(() => _activeDotIndex = index);
    }
  }

  Future<void> _loadRecommendations() async {
    final list = await SupabaseService.fetchHomeRecommendations();
    if (mounted) {
      setState(() {
        _recommendations = list.where((e) => e['is_active'] != false).toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4F46E5)),
          ),
        ),
      );
    }

    if (_recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row: Recommended Test Series + View All >
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recommended Test Series',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              InkWell(
                onTap: () {
                  if (widget.onViewAll != null) {
                    widget.onViewAll!();
                  } else {
                    context.push('/test-series');
                  }
                },
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF2563EB)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Horizontal Scrollable Cards Carousel
        SizedBox(
          height: 310,
          child: ListView.builder(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: _recommendations.length,
            itemBuilder: (context, index) {
              final item = _recommendations[index];
              return _buildRecommendationCard(item);
            },
          ),
        ),

        const SizedBox(height: 12),

        // Dot Pagination Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _recommendations.length,
            (idx) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _activeDotIndex == idx ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _activeDotIndex == idx ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Go Premium Banner (from reference image)
        _buildGoPremiumBanner(context),
      ],
    );
  }

  // =========================================================================
  // PIXEL-PERFECT RECOMMENDATION CARD
  // =========================================================================
  Widget _buildRecommendationCard(Map<String, dynamic> item) {
    final title = (item['title'] ?? 'Test Series').toString();
    final subtitle = (item['subtitle'] ?? '').toString();
    final badge = (item['badge'] ?? 'BESTSELLER').toString();
    final int badgeColorValue = (item['badge_color'] is int)
        ? item['badge_color'] as int
        : (int.tryParse(item['badge_color']?.toString() ?? '') ?? 0xFF2563EB);
    final themeColor = Color(badgeColorValue);

    final testsCount = item['tests_count'] ?? 20;
    final questionsCount = item['questions_count'] ?? 3600;
    final validity = (item['validity'] ?? 'Till NEET 2026').toString();
    final price = (item['price'] is num) ? (item['price'] as num).toDouble() : 499.0;
    final origPrice = (item['original_price'] is num) ? (item['original_price'] as num).toDouble() : 999.0;
    final testSeriesId = (item['test_series_id'] ?? 'ts_neet_all_india_2026').toString();
    final iconType = (item['icon_type'] ?? 'cap').toString();

    IconData mainIcon = Icons.school_rounded;
    if (iconType == 'bolt') mainIcon = Icons.bolt_rounded;
    if (iconType == 'cube') mainIcon = Icons.inventory_2_rounded;
    if (iconType == 'target') mainIcon = Icons.track_changes_rounded;

    return Container(
      width: 255,
      margin: const EdgeInsets.only(right: 14, bottom: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Top Row: Badge Pill
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
              decoration: BoxDecoration(
                color: themeColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Thematic Icon with Soft Tint Circle
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(mainIcon, color: themeColor, size: 26),
          ),
          const SizedBox(height: 10),

          // Title
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),

          // Subtitle
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // Tests & Questions Count
          Text(
            '$testsCount Tests  •  $questionsCount Questions',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 2),

          // Validity
          Text(
            'Validity: $validity',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
          const Spacer(),

          // Price Row (₹499  ₹999)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '₹${price.toInt()}',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: themeColor,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '₹${origPrice.toInt()}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.lineThrough,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Action Button: View Details
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.zero,
              ),
              onPressed: () {
                context.push('/product/$testSeriesId');
              },
              child: Text(
                'View Details',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // GO PREMIUM BANNER (From reference image)
  // =========================================================================
  Widget _buildGoPremiumBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF16A34A).withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Crown Icon Container
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFF16A34A),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),

          // Texts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Go Premium',
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF14532D),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Unlock unlimited tests, detailed analytics, and All India Ranking.',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF166534),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Explore Plans Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => context.push('/test-series'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Explore Plans',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded, size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
