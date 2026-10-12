import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/supabase_service.dart';

class AdminRecommendationsScreen extends StatefulWidget {
  const AdminRecommendationsScreen({Key? key}) : super(key: key);

  @override
  State<AdminRecommendationsScreen> createState() => _AdminRecommendationsScreenState();
}

class _AdminRecommendationsScreenState extends State<AdminRecommendationsScreen> {
  List<Map<String, dynamic>> _recommendations = [];
  List<Map<String, dynamic>> _allTestSeries = [];
  bool _isLoading = true;

  // Pre-configured subscription plan presets for instant addition
  final List<Map<String, dynamic>> _subscriptionPlans = [
    {
      'id': 'plan_trial',
      'title': 'Trial Pass (1 Month)',
      'subtitle': '30 Days Access with Daily Limits',
      'badge': 'TRIAL',
      'badge_color': 0xFFF59E0B, // Amber
      'icon_type': 'star',
      'tests_count': 10,
      'questions_count': 1500,
      'validity': '1 Month',
      'price': 99.0,
      'original_price': 199.0,
      'target_route': '/pricing',
      'button_text': 'Get Trial Pass',
    },
    {
      'id': 'plan_starter',
      'title': 'Starter Plan (4 Months)',
      'subtitle': 'Targeted Prep for Revision',
      'badge': 'STARTER',
      'badge_color': 0xFF10B981, // Emerald
      'icon_type': 'bolt',
      'tests_count': 25,
      'questions_count': 3500,
      'validity': '4 Months',
      'price': 249.0,
      'original_price': 499.0,
      'target_route': '/pricing',
      'button_text': 'Choose Starter',
    },
    {
      'id': 'plan_pro',
      'title': 'Pro Subscription (8 Months)',
      'subtitle': 'Unlimited Mock Tests + AI Diagnostics',
      'badge': 'MOST POPULAR',
      'badge_color': 0xFF8B5CF6, // Purple
      'icon_type': 'trophy',
      'tests_count': 50,
      'questions_count': 8000,
      'validity': '8 Months',
      'price': 449.0,
      'original_price': 999.0,
      'target_route': '/pricing',
      'button_text': 'Unlock Pro',
    },
    {
      'id': 'plan_ultimate',
      'title': 'Ultimate 1-Year Pass',
      'subtitle': 'Complete Preparation + All Question Banks',
      'badge': 'BEST VALUE',
      'badge_color': 0xFF2563EB, // Royal Blue
      'icon_type': 'diamond',
      'tests_count': 100,
      'questions_count': 15000,
      'validity': '1 Year',
      'price': 689.0,
      'original_price': 1499.0,
      'target_route': '/pricing',
      'button_text': 'Get Ultimate Pass',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final recs = await SupabaseService.fetchHomeRecommendations();
    final series = await SupabaseService.fetchAllTestSeries();

    if (mounted) {
      setState(() {
        _recommendations = recs;
        _allTestSeries = series;
        _isLoading = false;
      });
    }
  }

  void _openEditDialog([Map<String, dynamic>? existing, String defaultType = 'test_series']) {
    final bool isEdit = existing != null;
    String productType = existing?['product_type']?.toString() ?? defaultType;

    final Map<String, dynamic> item = existing != null
        ? Map<String, dynamic>.from(existing)
        : {
            'id': 'rec_${DateTime.now().millisecondsSinceEpoch}',
            'product_type': productType,
            'test_series_id': _allTestSeries.isNotEmpty ? _allTestSeries.first['id'] : '',
            'product_id': '',
            'badge': 'RECOMMENDED',
            'badge_color': 0xFF2563EB,
            'icon_type': 'cap',
            'title': '',
            'subtitle': '',
            'tests_count': 20,
            'questions_count': 3000,
            'validity': 'Till Exam 2026',
            'price': 499.0,
            'original_price': 999.0,
            'target_route': productType == 'subscription' ? '/pricing' : '/test-series',
            'button_text': productType == 'subscription' ? 'Choose Plan' : 'Enroll Now',
            'is_active': true,
            'order_index': _recommendations.length,
          };

    // If adding a new test series and series exist, prefill with first series
    if (!isEdit && productType == 'test_series' && _allTestSeries.isNotEmpty) {
      final firstSeries = _allTestSeries.first;
      item['title'] = (firstSeries['title'] ?? firstSeries['name'] ?? 'NEET Test Series').toString();
      item['subtitle'] = (firstSeries['category'] ?? firstSeries['description'] ?? 'Full Syllabus Mock Tests').toString();
      item['price'] = (firstSeries['price'] as num?)?.toDouble() ?? 499.0;
      item['original_price'] = (firstSeries['original_price'] as num?)?.toDouble() ?? 999.0;
      item['tests_count'] = (firstSeries['test_count'] as num?)?.toInt() ?? 20;
      item['questions_count'] = (firstSeries['question_count'] as num?)?.toInt() ?? 3000;
      item['test_series_id'] = firstSeries['id']?.toString() ?? '';
      item['target_route'] = '/product/${firstSeries['id']}';
    } else if (!isEdit && productType == 'subscription') {
      final defaultPlan = _subscriptionPlans[2]; // Pro
      item['title'] = defaultPlan['title'];
      item['subtitle'] = defaultPlan['subtitle'];
      item['badge'] = defaultPlan['badge'];
      item['badge_color'] = defaultPlan['badge_color'];
      item['icon_type'] = defaultPlan['icon_type'];
      item['price'] = defaultPlan['price'];
      item['original_price'] = defaultPlan['original_price'];
      item['validity'] = defaultPlan['validity'];
      item['tests_count'] = defaultPlan['tests_count'];
      item['questions_count'] = defaultPlan['questions_count'];
      item['target_route'] = defaultPlan['target_route'];
      item['button_text'] = defaultPlan['button_text'];
    }

    final titleController = TextEditingController(text: item['title']?.toString() ?? '');
    final subtitleController = TextEditingController(text: item['subtitle']?.toString() ?? '');
    final badgeController = TextEditingController(text: item['badge']?.toString() ?? 'RECOMMENDED');
    final testsController = TextEditingController(text: (item['tests_count'] ?? 20).toString());
    final questionsController = TextEditingController(text: (item['questions_count'] ?? 3000).toString());
    final validityController = TextEditingController(text: item['validity']?.toString() ?? 'Till Exam 2026');
    final priceController = TextEditingController(text: (item['price'] ?? 499).toString());
    final origPriceController = TextEditingController(text: (item['original_price'] ?? 999).toString());
    final targetRouteController = TextEditingController(text: item['target_route']?.toString() ?? '');
    final buttonTextController = TextEditingController(text: item['button_text']?.toString() ?? 'Enroll Now');

    int selectedColor = (item['badge_color'] is int)
        ? item['badge_color']
        : (int.tryParse(item['badge_color']?.toString() ?? '') ?? 0xFF2563EB);
    String selectedIcon = (item['icon_type'] ?? 'cap').toString();
    String selectedSeriesId = (item['test_series_id'] ?? '').toString();
    String? selectedPlanId = productType == 'subscription' ? item['product_id']?.toString() : null;

    final colorOptions = [
      {'label': 'Royal Blue', 'color': 0xFF2563EB},
      {'label': 'Vibrant Orange', 'color': 0xFFEA580C},
      {'label': 'Purple', 'color': 0xFF8B5CF6},
      {'label': 'Emerald Green', 'color': 0xFF10B981},
      {'label': 'Crimson Red', 'color': 0xFFDC2626},
      {'label': 'Amber Gold', 'color': 0xFFF59E0B},
      {'label': 'Deep Indigo', 'color': 0xFF4F46E5},
    ];

    final iconOptions = [
      {'label': 'Graduation Cap', 'type': 'cap', 'icon': Icons.school_rounded},
      {'label': 'Lightning Bolt', 'type': 'bolt', 'icon': Icons.bolt_rounded},
      {'label': '3D Cube / PYQ', 'type': 'cube', 'icon': Icons.inventory_2_rounded},
      {'label': 'Target / Bullseye', 'type': 'target', 'icon': Icons.track_changes_rounded},
      {'label': 'Trophy Cup', 'type': 'trophy', 'icon': Icons.emoji_events_rounded},
      {'label': 'Diamond Premium', 'type': 'diamond', 'icon': Icons.diamond_rounded},
      {'label': 'Star Featured', 'type': 'star', 'icon': Icons.star_rounded},
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 620,
            constraints: const BoxConstraints(maxHeight: 700),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEdit ? 'Edit Recommendation' : 'Add Recommendation Card',
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 1. Product Type Selector (Test Series vs Subscription vs Custom)
                  Text('Product Type', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Test Series')),
                          selected: productType == 'test_series',
                          selectedColor: const Color(0xFF2563EB),
                          labelStyle: TextStyle(
                            color: productType == 'test_series' ? Colors.white : const Color(0xFF0F172A),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          onSelected: (val) {
                            if (val) {
                              setDialogState(() {
                                productType = 'test_series';
                                buttonTextController.text = 'Enroll Now';
                                if (targetRouteController.text.isEmpty || targetRouteController.text == '/pricing') {
                                  targetRouteController.text = selectedSeriesId.isNotEmpty ? '/product/$selectedSeriesId' : '/test-series';
                                }
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Subscription Plan')),
                          selected: productType == 'subscription',
                          selectedColor: const Color(0xFF8B5CF6),
                          labelStyle: TextStyle(
                            color: productType == 'subscription' ? Colors.white : const Color(0xFF0F172A),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          onSelected: (val) {
                            if (val) {
                              setDialogState(() {
                                productType = 'subscription';
                                buttonTextController.text = 'Choose Plan';
                                targetRouteController.text = '/pricing';
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Custom / Course')),
                          selected: productType == 'custom',
                          selectedColor: const Color(0xFF10B981),
                          labelStyle: TextStyle(
                            color: productType == 'custom' ? Colors.white : const Color(0xFF0F172A),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          onSelected: (val) {
                            if (val) {
                              setDialogState(() {
                                productType = 'custom';
                                buttonTextController.text = 'View Details';
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 2A. If Test Series: Dropdown from published test series
                  if (productType == 'test_series') ...[
                    Text('Select Published Test Series', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _allTestSeries.any((e) => e['id']?.toString() == selectedSeriesId) ? selectedSeriesId : null,
                          hint: const Text('Select from published Test Series', style: TextStyle(fontSize: 13)),
                          isExpanded: true,
                          items: _allTestSeries.map((ts) {
                            final id = ts['id']?.toString() ?? '';
                            final title = (ts['title'] ?? ts['name'] ?? id).toString();
                            final exam = (ts['exam'] ?? '').toString();
                            return DropdownMenuItem<String>(
                              value: id,
                              child: Text(
                                exam.isNotEmpty ? '[$exam] $title' : title,
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() {
                                selectedSeriesId = val;
                                final match = _allTestSeries.firstWhere((e) => e['id']?.toString() == val, orElse: () => {});
                                if (match.isNotEmpty) {
                                  titleController.text = (match['title'] ?? match['name'] ?? '').toString();
                                  subtitleController.text = (match['category'] ?? match['test_type'] ?? 'Comprehensive Test Series').toString();
                                  testsController.text = (match['test_count'] ?? 20).toString();
                                  questionsController.text = (match['question_count'] ?? 3000).toString();
                                  priceController.text = (match['price'] ?? 499).toString();
                                  origPriceController.text = (match['original_price'] ?? 999).toString();
                                  validityController.text = (match['validity'] ?? 'Till Exam 2026').toString();
                                  targetRouteController.text = '/product/$val';
                                }
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // 2B. If Subscription: Quick Preset Selector
                  if (productType == 'subscription') ...[
                    Text('Select Subscription Plan Preset', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedPlanId,
                          hint: const Text('Choose a subscription tier (or customize below)', style: TextStyle(fontSize: 13)),
                          isExpanded: true,
                          items: _subscriptionPlans.map((plan) {
                            return DropdownMenuItem<String>(
                              value: plan['id'] as String,
                              child: Text(
                                '${plan['title']} — ₹${(plan['price'] as num).toInt()}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() {
                                selectedPlanId = val;
                                final plan = _subscriptionPlans.firstWhere((p) => p['id'] == val);
                                titleController.text = plan['title'];
                                subtitleController.text = plan['subtitle'];
                                badgeController.text = plan['badge'];
                                selectedColor = plan['badge_color'] as int;
                                selectedIcon = plan['icon_type'] as String;
                                priceController.text = plan['price'].toString();
                                origPriceController.text = plan['original_price'].toString();
                                validityController.text = plan['validity'];
                                testsController.text = plan['tests_count'].toString();
                                questionsController.text = plan['questions_count'].toString();
                                targetRouteController.text = plan['target_route'];
                                buttonTextController.text = plan['button_text'];
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // 3. Title & Subtitle Fields
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Display Title', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                            const SizedBox(height: 6),
                            TextField(
                              controller: titleController,
                              decoration: InputDecoration(
                                hintText: productType == 'subscription' ? 'e.g. Pro Subscription' : 'e.g. NEET MASTER',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Subtitle', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                            const SizedBox(height: 6),
                            TextField(
                              controller: subtitleController,
                              decoration: InputDecoration(
                                hintText: productType == 'subscription' ? 'e.g. Unlimited Tests + AI' : 'e.g. Full Syllabus Mock Tests',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 4. Badge & Color Theme
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Badge Label', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                            const SizedBox(height: 6),
                            TextField(
                              controller: badgeController,
                              decoration: InputDecoration(
                                hintText: 'e.g. BESTSELLER, POPULAR, RECOMMENDED',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Color Theme', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: selectedColor,
                                  isExpanded: true,
                                  items: colorOptions.map((opt) {
                                    final col = Color(opt['color'] as int);
                                    return DropdownMenuItem<int>(
                                      value: opt['color'] as int,
                                      child: Row(
                                        children: [
                                          Container(width: 14, height: 14, decoration: BoxDecoration(color: col, shape: BoxShape.circle)),
                                          const SizedBox(width: 8),
                                          Text(opt['label'] as String, style: const TextStyle(fontSize: 12.5)),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setDialogState(() => selectedColor = val);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 5. Icon Selector
                  Text('Card Icon', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: iconOptions.map((opt) {
                      final isSelected = selectedIcon == opt['type'];
                      return ChoiceChip(
                        selected: isSelected,
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(opt['icon'] as IconData, size: 16, color: isSelected ? Colors.white : const Color(0xFF475569)),
                            const SizedBox(width: 6),
                            Text(opt['label'] as String, style: TextStyle(fontSize: 11.5, color: isSelected ? Colors.white : const Color(0xFF475569))),
                          ],
                        ),
                        selectedColor: Color(selectedColor),
                        onSelected: (val) {
                          if (val) setDialogState(() => selectedIcon = opt['type'] as String);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // 6. Tests Count, Questions Count, Validity
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tests Count', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                            const SizedBox(height: 6),
                            TextField(
                              controller: testsController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: '20',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Questions Count', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                            const SizedBox(height: 6),
                            TextField(
                              controller: questionsController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: '3000',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Validity', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                            const SizedBox(height: 6),
                            TextField(
                              controller: validityController,
                              decoration: InputDecoration(
                                hintText: 'Till NEET 2026',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 7. Pricing Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Sale Price (₹)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                            const SizedBox(height: 6),
                            TextField(
                              controller: priceController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: '499',
                                prefixText: '₹ ',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Original Price (₹)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                            const SizedBox(height: 6),
                            TextField(
                              controller: origPriceController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: '999',
                                prefixText: '₹ ',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 8. Target Route & Button Text
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Action Route / URL', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                            const SizedBox(height: 6),
                            TextField(
                              controller: targetRouteController,
                              decoration: InputDecoration(
                                hintText: productType == 'subscription' ? '/pricing' : '/product/ts_id',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Button Label', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                            const SizedBox(height: 6),
                            TextField(
                              controller: buttonTextController,
                              decoration: InputDecoration(
                                hintText: 'e.g. Enroll Now, Choose Plan',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () async {
                          final updated = {
                            'id': item['id'],
                            'product_type': productType,
                            'test_series_id': selectedSeriesId,
                            'product_id': selectedPlanId ?? '',
                            'title': titleController.text.trim().isNotEmpty
                                ? titleController.text.trim()
                                : (productType == 'subscription' ? 'Pro Plan' : 'NEET Test Series'),
                            'subtitle': subtitleController.text.trim(),
                            'badge': badgeController.text.trim().isNotEmpty
                                ? badgeController.text.trim().toUpperCase()
                                : 'RECOMMENDED',
                            'badge_color': selectedColor,
                            'icon_type': selectedIcon,
                            'tests_count': int.tryParse(testsController.text.trim()) ?? 20,
                            'questions_count': int.tryParse(questionsController.text.trim()) ?? 3000,
                            'validity': validityController.text.trim().isNotEmpty
                                ? validityController.text.trim()
                                : 'Till Exam 2026',
                            'price': double.tryParse(priceController.text.trim()) ?? 499.0,
                            'original_price': double.tryParse(origPriceController.text.trim()) ?? 999.0,
                            'target_route': targetRouteController.text.trim().isNotEmpty
                                ? targetRouteController.text.trim()
                                : (productType == 'subscription' ? '/pricing' : '/test-series'),
                            'button_text': buttonTextController.text.trim().isNotEmpty
                                ? buttonTextController.text.trim()
                                : 'Enroll Now',
                            'is_active': item['is_active'] ?? true,
                            'order_index': item['order_index'] ?? _recommendations.length,
                          };

                          await SupabaseService.saveHomeRecommendation(updated);
                          if (ctx.mounted) Navigator.pop(ctx);
                          _loadData();

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('✓ Recommendation "${updated['title']}" saved successfully!'),
                                backgroundColor: const Color(0xFF10B981),
                              ),
                            );
                          }
                        },
                        child: Text(isEdit ? 'Save Changes' : 'Add Recommendation'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(String id, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Recommendation'),
        content: Text('Are you sure you want to permanently remove "$title" from the Home Screen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await SupabaseService.deleteHomeRecommendation(id);
              _loadData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Removed "$title"'), backgroundColor: const Color(0xFFEF4444)),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmPurgeDemoData() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Purge Demo Data'),
        content: const Text('This will clear any old demo recommendation cards so you have a completely fresh slate for your real products. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA580C), foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await SupabaseService.purgeDemoRecommendations();
              _loadData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Demo recommendations purged successfully!'), backgroundColor: Color(0xFF10B981)),
                );
              }
            },
            child: const Text('Clear Demo Data'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => context.canPop() ? context.pop() : context.go('/admin'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Home Screen Recommendation Manager',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
            ),
            Text(
              'Curate, reorder, and style featured test series and subscription plans for students',
              style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          // Refresh Button
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF475569)),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
          // Clear Demo Data (if demo items or user wants clean slate)
          TextButton.icon(
            icon: const Icon(Icons.cleaning_services_rounded, size: 16, color: Color(0xFFEF4444)),
            label: const Text('Clear Demo Data', style: TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
            onPressed: _confirmPurgeDemoData,
          ),
          const SizedBox(width: 8),
          // + Add Recommendation Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => _openEditDialog(),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Recommendation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
          ),
          const SizedBox(width: 14),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1050),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Overview Banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB), size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'These recommendations are displayed prominently as the "Recommended Test Series" section on the Student Home Screen. Changes made here reflect instantly across all web and mobile apps.',
                                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1E40AF)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Quick Add Bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Quick Add:',
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF334155)),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF2563EB),
                                side: const BorderSide(color: Color(0xFFBFDBFE)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.school_outlined, size: 16),
                              label: const Text('+ Test Series', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              onPressed: () => _openEditDialog(null, 'test_series'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF8B5CF6),
                                side: const BorderSide(color: Color(0xFFDDD6FE)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.workspace_premium_outlined, size: 16),
                              label: const Text('+ Subscription Plan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              onPressed: () => _openEditDialog(null, 'subscription'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF10B981),
                                side: const BorderSide(color: Color(0xFFA7F3D0)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.auto_awesome_outlined, size: 16),
                              label: const Text('+ Custom Product', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              onPressed: () => _openEditDialog(null, 'custom'),
                            ),
                            const Spacer(),
                            Text(
                              'Total: ${_recommendations.length} Active / Configured',
                              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Recommendations List or Empty State
                      if (_recommendations.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.recommend_rounded, color: Color(0xFF2563EB), size: 36),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No Recommendations Curated Yet',
                                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Add your test series and subscription plans to showcase them prominently on the student dashboard.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2563EB),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: const Icon(Icons.add_rounded, size: 18),
                                    label: const Text('Add Test Series'),
                                    onPressed: () => _openEditDialog(null, 'test_series'),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF8B5CF6),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: const Icon(Icons.add_rounded, size: 18),
                                    label: const Text('Add Subscription Plan'),
                                    onPressed: () => _openEditDialog(null, 'subscription'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      else
                        ..._recommendations.asMap().entries.map((entry) {
                          final int index = entry.key;
                          final item = entry.value;

                          final id = item['id']?.toString() ?? '';
                          final title = (item['title'] ?? 'Card').toString();
                          final subtitle = (item['subtitle'] ?? '').toString();
                          final badge = (item['badge'] ?? 'RECOMMENDED').toString();
                          final productType = (item['product_type'] ?? 'test_series').toString();
                          final int badgeColorValue = (item['badge_color'] is int)
                              ? item['badge_color'] as int
                              : (int.tryParse(item['badge_color']?.toString() ?? '') ?? 0xFF2563EB);
                          final themeColor = Color(badgeColorValue);
                          final testsCount = item['tests_count'] ?? 20;
                          final questionsCount = item['questions_count'] ?? 3000;
                          final price = item['price'] ?? 499;
                          final origPrice = item['original_price'] ?? 999;
                          final bool isActive = item['is_active'] != false;
                          final iconType = (item['icon_type'] ?? 'cap').toString();
                          final targetRoute = (item['target_route'] ?? '').toString();

                          IconData mainIcon = Icons.school_rounded;
                          if (iconType == 'bolt') mainIcon = Icons.bolt_rounded;
                          if (iconType == 'cube') mainIcon = Icons.inventory_2_rounded;
                          if (iconType == 'target') mainIcon = Icons.track_changes_rounded;
                          if (iconType == 'trophy') mainIcon = Icons.emoji_events_rounded;
                          if (iconType == 'diamond') mainIcon = Icons.diamond_rounded;
                          if (iconType == 'star') mainIcon = Icons.star_rounded;

                          String typeLabel = 'TEST SERIES';
                          Color typeColor = const Color(0xFF2563EB);
                          if (productType == 'subscription') {
                            typeLabel = 'SUBSCRIPTION';
                            typeColor = const Color(0xFF8B5CF6);
                          } else if (productType == 'custom') {
                            typeLabel = 'CUSTOM';
                            typeColor = const Color(0xFF10B981);
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Reorder buttons (Up/Down)
                                Column(
                                  children: [
                                    InkWell(
                                      onTap: index > 0
                                          ? () async {
                                              await SupabaseService.reorderHomeRecommendations(index, index - 1);
                                              _loadData();
                                            }
                                          : null,
                                      child: Icon(
                                        Icons.keyboard_arrow_up_rounded,
                                        size: 20,
                                        color: index > 0 ? const Color(0xFF64748B) : const Color(0xFFCBD5E1),
                                      ),
                                    ),
                                    Text(
                                      '${index + 1}',
                                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF94A3B8)),
                                    ),
                                    InkWell(
                                      onTap: index < _recommendations.length - 1
                                          ? () async {
                                              await SupabaseService.reorderHomeRecommendations(index, index + 1);
                                              _loadData();
                                            }
                                          : null,
                                      child: Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        size: 20,
                                        color: index < _recommendations.length - 1
                                            ? const Color(0xFF64748B)
                                            : const Color(0xFFCBD5E1),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 10),

                                // Color & Icon Preview Box
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: themeColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(mainIcon, color: themeColor, size: 28),
                                ),
                                const SizedBox(width: 16),

                                // Content Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          // Product Type Pill
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: typeColor.withOpacity(0.1),
                                              border: Border.all(color: typeColor.withOpacity(0.3)),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              typeLabel,
                                              style: TextStyle(color: typeColor, fontSize: 9, fontWeight: FontWeight.w800),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          // Badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                            decoration: BoxDecoration(color: themeColor, borderRadius: BorderRadius.circular(4)),
                                            child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              title,
                                              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (subtitle.isNotEmpty) ...[
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                subtitle,
                                                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Wrap(
                                        spacing: 8,
                                        children: [
                                          Text(
                                            '$testsCount Tests • $questionsCount Questions • Sale: ₹$price (Was: ₹$origPrice)',
                                            style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
                                          ),
                                          if (targetRoute.isNotEmpty)
                                            Text(
                                              '• Link: $targetRoute',
                                              style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF2563EB)),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Active Switch
                                Row(
                                  children: [
                                    Text(
                                      isActive ? 'Active' : 'Hidden',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isActive ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Switch(
                                      value: isActive,
                                      activeColor: const Color(0xFF10B981),
                                      onChanged: (val) async {
                                        await SupabaseService.toggleRecommendationStatus(id, val);
                                        _loadData();
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),

                                // Action Buttons (Edit & Delete)
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: Color(0xFF2563EB), size: 20),
                                  tooltip: 'Edit Card',
                                  onPressed: () => _openEditDialog(item, productType),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                                  tooltip: 'Delete Card',
                                  onPressed: () => _confirmDelete(id, title),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
