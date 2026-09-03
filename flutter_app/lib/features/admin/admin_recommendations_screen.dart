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

  void _openEditDialog([Map<String, dynamic>? existing]) {
    final bool isEdit = existing != null;
    final Map<String, dynamic> item = existing != null
        ? Map<String, dynamic>.from(existing)
        : {
            'id': 'rec_${DateTime.now().millisecondsSinceEpoch}',
            'test_series_id': _allTestSeries.isNotEmpty ? _allTestSeries.first['id'] : 'ts_neet_all_india_2026',
            'badge': 'BESTSELLER',
            'badge_color': 0xFF2563EB,
            'icon_type': 'cap',
            'title': 'NEET MASTER',
            'subtitle': 'Full Syllabus Test Series',
            'tests_count': 20,
            'questions_count': 3600,
            'validity': 'Till NEET 2026',
            'price': 499.0,
            'original_price': 999.0,
            'is_active': true,
            'order_index': _recommendations.length,
          };

    final titleController = TextEditingController(text: item['title']?.toString() ?? '');
    final subtitleController = TextEditingController(text: item['subtitle']?.toString() ?? '');
    final badgeController = TextEditingController(text: item['badge']?.toString() ?? 'BESTSELLER');
    final testsController = TextEditingController(text: (item['tests_count'] ?? 20).toString());
    final questionsController = TextEditingController(text: (item['questions_count'] ?? 3600).toString());
    final validityController = TextEditingController(text: item['validity']?.toString() ?? 'Till NEET 2026');
    final priceController = TextEditingController(text: (item['price'] ?? 499).toString());
    final origPriceController = TextEditingController(text: (item['original_price'] ?? 999).toString());

    int selectedColor = (item['badge_color'] is int) ? item['badge_color'] : 0xFF2563EB;
    String selectedIcon = (item['icon_type'] ?? 'cap').toString();
    String selectedSeriesId = (item['test_series_id'] ?? '').toString();

    final colorOptions = [
      {'label': 'Royal Blue', 'color': 0xFF2563EB},
      {'label': 'Vibrant Orange', 'color': 0xFFEA580C},
      {'label': 'Purple', 'color': 0xFF9333EA},
      {'label': 'Emerald Green', 'color': 0xFF10B981},
      {'label': 'Crimson Red', 'color': 0xFFDC2626},
    ];

    final iconOptions = [
      {'label': 'Graduation Cap', 'type': 'cap', 'icon': Icons.school_rounded},
      {'label': 'Lightning Bolt', 'type': 'bolt', 'icon': Icons.bolt_rounded},
      {'label': '3D Cube / PYQ', 'type': 'cube', 'icon': Icons.inventory_2_rounded},
      {'label': 'Target / Shield', 'type': 'target', 'icon': Icons.track_changes_rounded},
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 580,
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
                        isEdit ? 'Edit Recommendation' : 'Add Recommendation',
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Linked Test Series Selector
                  Text('Linked Test Series / Course', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
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
                        hint: const Text('Select a published Test Series', style: TextStyle(fontSize: 13)),
                        isExpanded: true,
                        items: _allTestSeries.map((ts) {
                          final id = ts['id']?.toString() ?? '';
                          final title = (ts['title'] ?? ts['name'] ?? id).toString();
                          return DropdownMenuItem<String>(
                            value: id,
                            child: Text(title, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedSeriesId = val;
                              final match = _allTestSeries.firstWhere((e) => e['id']?.toString() == val, orElse: () => {});
                              if (match.isNotEmpty) {
                                titleController.text = (match['title'] ?? match['name'] ?? '').toString();
                                subtitleController.text = (match['category'] ?? match['test_type'] ?? 'Test Series').toString();
                                testsController.text = (match['test_count'] ?? 10).toString();
                                priceController.text = (match['price'] ?? 499).toString();
                                origPriceController.text = (match['original_price'] ?? 999).toString();
                                validityController.text = (match['validity'] ?? 'Till NEET 2026').toString();
                              }
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Title & Subtitle
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
                                hintText: 'e.g. NEET MASTER',
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
                                hintText: 'e.g. Full Syllabus Test Series',
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

                  // Badge & Color Theme
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
                                hintText: 'e.g. BESTSELLER, POPULAR',
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

                  // Icon Selector
                  Text('Card Icon', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
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

                  // Tests Count & Questions Count
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
                                hintText: '3600',
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

                  // Pricing Row
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
                            'test_series_id': selectedSeriesId.isNotEmpty ? selectedSeriesId : 'ts_neet_all_india_2026',
                            'title': titleController.text.trim().isNotEmpty ? titleController.text.trim() : 'NEET MASTER',
                            'subtitle': subtitleController.text.trim(),
                            'badge': badgeController.text.trim().isNotEmpty ? badgeController.text.trim().toUpperCase() : 'RECOMMENDED',
                            'badge_color': selectedColor,
                            'icon_type': selectedIcon,
                            'tests_count': int.tryParse(testsController.text.trim()) ?? 20,
                            'questions_count': int.tryParse(questionsController.text.trim()) ?? 3600,
                            'validity': validityController.text.trim().isNotEmpty ? validityController.text.trim() : 'Till NEET 2026',
                            'price': double.tryParse(priceController.text.trim()) ?? 499.0,
                            'original_price': double.tryParse(origPriceController.text.trim()) ?? 999.0,
                            'is_active': item['is_active'] ?? true,
                            'order_index': item['order_index'] ?? 0,
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
                        child: Text(isEdit ? 'Save Changes' : 'Add Card'),
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
        content: Text('Are you sure you want to remove "$title" from the Home Screen?'),
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
              'Curate, reorder, and style featured test series cards for the student dashboard',
              style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
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
                  constraints: const BoxConstraints(maxWidth: 1000),
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

                      // Recommendations List
                      ..._recommendations.map((item) {
                        final id = item['id']?.toString() ?? '';
                        final title = (item['title'] ?? 'Series').toString();
                        final subtitle = (item['subtitle'] ?? '').toString();
                        final badge = (item['badge'] ?? 'BESTSELLER').toString();
                        final int badgeColorValue = (item['badge_color'] is int)
                            ? item['badge_color'] as int
                            : (int.tryParse(item['badge_color']?.toString() ?? '') ?? 0xFF2563EB);
                        final themeColor = Color(badgeColorValue);
                        final testsCount = item['tests_count'] ?? 20;
                        final questionsCount = item['questions_count'] ?? 3600;
                        final price = item['price'] ?? 499;
                        final origPrice = item['original_price'] ?? 999;
                        final bool isActive = item['is_active'] != false;
                        final iconType = (item['icon_type'] ?? 'cap').toString();

                        IconData mainIcon = Icons.school_rounded;
                        if (iconType == 'bolt') mainIcon = Icons.bolt_rounded;
                        if (iconType == 'cube') mainIcon = Icons.inventory_2_rounded;
                        if (iconType == 'target') mainIcon = Icons.track_changes_rounded;

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
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(color: themeColor, borderRadius: BorderRadius.circular(4)),
                                          child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                                        const SizedBox(width: 8),
                                        Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$testsCount Tests • $questionsCount Questions • Sale: ₹$price (Was: ₹$origPrice) • Linked: ${item['test_series_id']}',
                                      style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ),

                              // Active Switch
                              Row(
                                children: [
                                  Text(isActive ? 'Active' : 'Hidden', style: TextStyle(fontSize: 12, color: isActive ? const Color(0xFF10B981) : const Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
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

                              // Action Buttons
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Color(0xFF2563EB), size: 20),
                                tooltip: 'Edit',
                                onPressed: () => _openEditDialog(item),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                                tooltip: 'Delete',
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
