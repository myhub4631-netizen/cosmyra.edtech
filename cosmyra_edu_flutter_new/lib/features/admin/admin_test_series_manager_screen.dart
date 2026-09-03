import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/supabase_service.dart';
import '../../models/models.dart';

class AdminTestSeriesManagerScreen extends StatefulWidget {
  final UserProfileModel? userProfile;
  final VoidCallback? onBack;

  const AdminTestSeriesManagerScreen({
    Key? key,
    this.userProfile,
    this.onBack,
  }) : super(key: key);

  @override
  State<AdminTestSeriesManagerScreen> createState() => _AdminTestSeriesManagerScreenState();
}

class _AdminTestSeriesManagerScreenState extends State<AdminTestSeriesManagerScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _testSeriesList = [];
  String _searchQuery = '';
  String _selectedExamFilter = 'All';
  String _selectedCategoryFilter = 'All';
  String _selectedStatusFilter = 'All';

  // 42 Years from 2029 down to 1988
  static final List<String> availableYears = List<String>.generate(
    2029 - 1988 + 1,
    (index) => (2029 - index).toString(),
  );

  static const List<String> availableCategories = [
    'Full Syllabus',
    'Part + Unit + Full Syllabus',
    'Chapter + Part + Unit + Full Syllabus',
    'Chapter Wise',
    'Topic Wise',
    'Mock Tests',
  ];

  List<Map<String, dynamic>> _availablePapers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final list = await SupabaseService.fetchAllTestSeries();
    final papers = await SupabaseService.fetchAllPapersAndTestSeries();
    if (mounted) {
      setState(() {
        _testSeriesList = list;
        _availablePapers = papers;
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredSeries {
    return _testSeriesList.where((item) {
      final title = (item['title'] ?? item['name'] ?? '').toString().toLowerCase();
      final desc = (item['description'] ?? '').toString().toLowerCase();
      final exam = (item['exam'] ?? 'NEET').toString();
      final category = (item['category'] ?? 'Full Syllabus').toString();
      final status = (item['status'] ?? 'Published').toString();

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!title.contains(q) && !desc.contains(q)) return false;
      }
      if (_selectedExamFilter != 'All' && exam != _selectedExamFilter) return false;
      if (_selectedCategoryFilter != 'All' && category != _selectedCategoryFilter) return false;
      if (_selectedStatusFilter != 'All' && status != _selectedStatusFilter) return false;

      return true;
    }).toList();
  }

  Future<void> _handleDelete(String id, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Test Series?'),
        content: Text('Are you sure you want to delete "$title"? This action will remove the series and its configuration.'),
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

    if (confirm == true) {
      final ok = await SupabaseService.deleteTestSeries(id);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Test Series "$title" deleted successfully'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        _loadData();
      }
    }
  }

  Future<void> _handleDuplicate(String id, String title) async {
    setState(() => _isLoading = true);
    final res = await SupabaseService.duplicateTestSeries(id);
    if (res != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Successfully duplicated "$title"!'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      _loadData();
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openEditorModal([Map<String, dynamic>? initial]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _TestSeriesEditorDialog(
        initialData: initial,
        availablePapers: _availablePapers,
        onSaved: () {
          _loadData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopHeader(),
                    const SizedBox(height: 20),
                    _buildKpiMetricsRow(),
                    const SizedBox(height: 20),
                    _buildSearchBarAndFilters(),
                    const SizedBox(height: 20),
                    _buildTestSeriesGrid(),
                  ],
                ),
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B)),
        onPressed: () {
          if (widget.onBack != null) {
            widget.onBack!();
          } else {
            context.go('/admin');
          }
        },
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.track_changes_rounded, color: Color(0xFF4F46E5), size: 20),
          ),
          const SizedBox(width: 10),
          Text(
            'Test Series Manager',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: () => context.go('/admin/questions/upload'),
          icon: const Icon(Icons.cloud_upload_outlined, size: 16, color: Color(0xFF4F46E5)),
          label: const Text('Question Upload Step 1', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => _openEditorModal(),
            icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
            label: const Text('Add Test Series', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildTopHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: const Color(0xFF312E81).withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Centralized Test Series & Pricing Management',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  'Manage test series titles, descriptions, banner graphics, pricing, purchase links, and link directly with bulk question upload.',
                  style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85), height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white70),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => context.go('/test-series'),
            icon: const Icon(Icons.visibility_outlined, size: 18),
            label: const Text('View Student Test Series Page', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiMetricsRow() {
    final total = _testSeriesList.length;
    final published = _testSeriesList.where((e) => e['status'] == 'Published').length;
    final paid = _testSeriesList.where((e) => e['is_free'] != true).length;
    final free = total - paid;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 650;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _buildKpiCard('Total Test Series', '$total', Icons.layers_outlined, const Color(0xFF4F46E5), const Color(0xFFEEF2FF), isNarrow),
            _buildKpiCard('Published & Active', '$published', Icons.check_circle_outline_rounded, const Color(0xFF10B981), const Color(0xFFECFDF5), isNarrow),
            _buildKpiCard('Paid Series', '$paid', Icons.monetization_on_outlined, const Color(0xFFF59E0B), const Color(0xFFFFFBEB), isNarrow),
            _buildKpiCard('Free Tests', '$free', Icons.card_giftcard_rounded, const Color(0xFF8B5CF6), const Color(0xFFF5F3FF), isNarrow),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color, Color bg, bool isNarrow) {
    return Container(
      width: isNarrow ? double.infinity : 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
              Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF64748B))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBarAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Search Field
          SizedBox(
            width: 280,
            height: 40,
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search test series...',
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              ),
            ),
          ),

          // Exam Filter
          _buildFilterDropdown(
            label: 'Exam: ',
            value: _selectedExamFilter,
            items: ['All', 'NEET', 'JEE Main', 'JEE Advanced', 'AIIMS', 'CUET'],
            onChanged: (v) => setState(() => _selectedExamFilter = v!),
          ),

          // Category Filter
          _buildFilterDropdown(
            label: 'Category: ',
            value: _selectedCategoryFilter,
            items: ['All', ...availableCategories],
            onChanged: (v) => setState(() => _selectedCategoryFilter = v!),
          ),

          // Status Filter
          _buildFilterDropdown(
            label: 'Status: ',
            value: _selectedStatusFilter,
            items: ['All', 'Published', 'Draft'],
            onChanged: (v) => setState(() => _selectedStatusFilter = v!),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          DropdownButton<String>(
            value: items.contains(value) ? value : items.first,
            underline: const SizedBox(),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
            style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
            onChanged: onChanged,
            items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTestSeriesGrid() {
    final filtered = _filteredSeries;
    if (filtered.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            const Icon(Icons.folder_off_outlined, size: 48, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            const Text('No test series found matching your filters.', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
              onPressed: () => _openEditorModal(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Create First Test Series'),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1100 ? 3 : (constraints.maxWidth > 700 ? 2 : 1);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filtered.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 470,
          ),
          itemBuilder: (ctx, i) => _buildTestSeriesCard(filtered[i]),
        );
      },
    );
  }

  Widget _buildTestSeriesCard(Map<String, dynamic> item) {
    final String sId = item['id']?.toString() ?? '';
    final String title = item['title'] ?? item['name'] ?? 'Test Series';
    final String desc = item['description'] ?? 'Curated test series for comprehensive exam readiness.';
    final String exam = item['exam'] ?? 'NEET';
    final String year = item['year']?.toString() ?? '2027';
    final String category = item['category'] ?? 'Full Syllabus';
    final String bannerUrl = item['banner_image_url'] ?? '';
    final bool isFree = item['is_free'] == true;
    final double price = (item['price'] is num) ? (item['price'] as num).toDouble() : 299.0;
    final double origPrice = (item['original_price'] is num) ? (item['original_price'] as num).toDouble() : 999.0;
    final String purchaseLink = item['purchase_link'] ?? '';
    final String buttonText = item['purchase_button_text'] ?? 'Join';
    final String status = item['status'] ?? 'Published';
    final int testCount = (item['test_count'] is num) ? (item['test_count'] as num).toInt() : 10;
    final int questionCount = (item['question_count'] is num) ? (item['question_count'] as num).toInt() : 200;
    final int durationMins = (item['duration_minutes'] is num) ? (item['duration_minutes'] as num).toInt() : 180;
    final String testType = item['test_type'] ?? item['testType'] ?? 'Full';
    final String difficulty = item['difficulty'] ?? 'Moderate';
    final String validity = item['validity'] ?? 'Valid until exam';
    final String attemptStatus = item['attempt_status'] ?? 'Not Attempted';
    final String syllabusUrl = item['syllabus_url'] ?? '';

    final String durationFormatted = (durationMins >= 60 && durationMins % 60 == 0)
        ? '${durationMins ~/ 60} Hours'
        : '$durationMins min';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Banner Image Header
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: AspectRatio(
                  aspectRatio: 16 / 6,
                  child: bannerUrl.isNotEmpty
                      ? Image.network(
                          bannerUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, st) => Container(
                            color: const Color(0xFF312E81),
                            child: const Center(child: Icon(Icons.track_changes_rounded, color: Colors.white, size: 36)),
                          ),
                        )
                      : Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Center(child: Icon(Icons.track_changes_rounded, color: Colors.white, size: 36)),
                        ),
                ),
              ),
              // Exam & Year Tag
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withOpacity(0.85),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$exam $year',
                    style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              // Status Badge
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: status == 'Published'
                        ? const Color(0xFF10B981)
                        : (status == 'Archived' ? const Color(0xFF94A3B8) : const Color(0xFFF59E0B)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),

          // 2. Card Body Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 4),
                  // Description
                  Text(
                    desc,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 10),

                  // Pill tags
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _buildMiniPill(Icons.category_outlined, category),
                      _buildMiniPill(Icons.description_outlined, '$testCount Estimated Tests'),
                      _buildMiniPill(Icons.layers_outlined, 'Type: $testType'),
                      _buildMiniPill(Icons.quiz_outlined, '$questionCount Qs'),
                      _buildMiniPill(Icons.access_time_rounded, durationFormatted),
                      _buildMiniPill(Icons.bar_chart_rounded, difficulty),
                      _buildMiniPill(Icons.event_available_rounded, validity),
                      _buildMiniPill(Icons.pending_actions_rounded, attemptStatus),
                      if (syllabusUrl.isNotEmpty)
                        _buildMiniPill(Icons.download_rounded, 'Syllabus Attached'),
                    ],
                  ),
                  const Spacer(),

                  // Pricing Row
                  Row(
                    children: [
                      if (isFree)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                          child: const Text('FREE', style: TextStyle(color: Color(0xFF16A34A), fontSize: 13, fontWeight: FontWeight.w800)),
                        )
                      else ...[
                        Text('₹${price.toInt()}', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                        const SizedBox(width: 6),
                        Text(
                          '₹${origPrice.toInt()}',
                          style: GoogleFonts.inter(fontSize: 12, decoration: TextDecoration.lineThrough, color: const Color(0xFF94A3B8)),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(4)),
                          child: Text(
                            '${(((origPrice - price) / origPrice) * 100).toInt()}% OFF',
                            style: const TextStyle(color: Color(0xFFDC2626), fontSize: 9.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // 3. Action Buttons Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Upload / Edit Questions (Direct step 1 shortcut)
                TextButton.icon(
                  onPressed: () {
                    context.go('/admin/questions/upload');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Selected "$title" in Bulk Upload Step 1!'),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  },
                  icon: const Icon(Icons.cloud_upload_outlined, size: 14, color: Color(0xFF4F46E5)),
                  label: const Text('Upload/Edit Qs', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
                ),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Edit
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                      tooltip: 'Edit Series',
                      onPressed: () => _openEditorModal(item),
                    ),
                    // Duplicate
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 17, color: Color(0xFF64748B)),
                      tooltip: 'Duplicate Series',
                      onPressed: () => _handleDuplicate(sId, title),
                    ),
                    // Purchase Link
                    if (purchaseLink.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.shopping_cart_outlined, size: 17, color: Color(0xFF10B981)),
                        tooltip: 'Test Purchase Link ($buttonText)',
                        onPressed: () async {
                          final uri = Uri.tryParse(purchaseLink);
                          if (uri != null) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                      ),
                    // Delete
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                      tooltip: 'Delete Series',
                      onPressed: () => _handleDelete(sId, title),
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

  Widget _buildMiniPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: const Color(0xFF64748B)),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
        ],
      ),
    );
  }
}

// ==============================================================================
// TEST SERIES EDITOR DIALOG
// ==============================================================================
class _TestSeriesEditorDialog extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final List<Map<String, dynamic>> availablePapers;
  final VoidCallback onSaved;

  const _TestSeriesEditorDialog({
    Key? key,
    this.initialData,
    this.availablePapers = const [],
    required this.onSaved,
  }) : super(key: key);

  @override
  State<_TestSeriesEditorDialog> createState() => _TestSeriesEditorDialogState();
}

class _TestSeriesEditorDialogState extends State<_TestSeriesEditorDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Basic & Pricing Controllers
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _bannerCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _origPriceCtrl;
  late TextEditingController _linkCtrl;
  late TextEditingController _buttonTextCtrl;
  late TextEditingController _testCountCtrl;
  late TextEditingController _questionCountCtrl;
  late TextEditingController _durationCtrl;
  late TextEditingController _validityCtrl;
  late TextEditingController _syllabusCtrl;

  late String _exam;
  late String _year;
  late String _category;
  late String _testType;
  late String _difficulty;
  late String _attemptStatus;
  late String _status;
  late bool _isFree;
  late bool _showPurchaseButton;

  // Tab 2: Overview & Key Features Controllers
  late TextEditingController _longDescCtrl;
  late TextEditingController _f1TitleCtrl;
  late TextEditingController _f1DescCtrl;
  late TextEditingController _f2TitleCtrl;
  late TextEditingController _f2DescCtrl;
  late TextEditingController _f3TitleCtrl;
  late TextEditingController _f3DescCtrl;
  late TextEditingController _f4TitleCtrl;
  late TextEditingController _f4DescCtrl;

  // Tab 3: Tests List
  List<Map<String, dynamic>> _tests = [];

  // Tab 4: Reviews & Ratings
  List<Map<String, dynamic>> _reviews = [];
  late TextEditingController _ratingScoreCtrl;
  late TextEditingController _ratingsCountCtrl;

  // Tab 5: Top Scores & Leaderboard Rankers
  late TextEditingController _highestScoreCtrl;
  late TextEditingController _avgScoreCtrl;
  late TextEditingController _activeAspirantsCtrl;
  List<Map<String, dynamic>> _rankers = [];

  final List<String> _sampleBanners = [
    'https://images.unsplash.com/photo-1532094349884-543bc11b234d?w=800&auto=format&fit=crop&q=60',
    'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=800&auto=format&fit=crop&q=60',
    'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=800&auto=format&fit=crop&q=60',
    'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=800&auto=format&fit=crop&q=60',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    final d = widget.initialData ?? {};
    _titleCtrl = TextEditingController(text: d['title'] ?? d['name'] ?? '');
    _descCtrl = TextEditingController(text: d['description'] ?? 'Curated test series for comprehensive exam readiness.');
    _bannerCtrl = TextEditingController(text: d['banner_image_url'] ?? _sampleBanners[0]);
    _priceCtrl = TextEditingController(text: (d['price'] ?? 299).toString());
    _origPriceCtrl = TextEditingController(text: (d['original_price'] ?? 999).toString());
    _linkCtrl = TextEditingController(text: d['purchase_link'] ?? 'https://neet-jee.in/test-series');
    _buttonTextCtrl = TextEditingController(text: d['purchase_button_text'] ?? 'Join');
    _testCountCtrl = TextEditingController(text: (d['test_count'] ?? 10).toString());
    _questionCountCtrl = TextEditingController(text: (d['question_count'] ?? 200).toString());
    _durationCtrl = TextEditingController(text: (d['duration_minutes'] ?? 180).toString());
    _validityCtrl = TextEditingController(text: d['validity'] ?? 'Valid until exam');
    _syllabusCtrl = TextEditingController(text: d['syllabus_url'] ?? d['syllabusUrl'] ?? '');

    _exam = d['exam'] ?? 'NEET';
    _year = d['year']?.toString() ?? '2027';
    _category = d['category'] ?? 'Full Syllabus';
    _testType = (d['test_type'] ?? d['testType'] ?? 'Full').toString();
    if (!['Full', 'Part + Unit + Full', 'Chapter + Part + Unit + Full', 'Part', 'Chapter'].contains(_testType)) {
      _testType = 'Full';
    }
    _difficulty = d['difficulty'] ?? 'Moderate';
    if (!['Easy', 'Moderate', 'Advanced', 'Mixed', 'Medium', 'High'].contains(_difficulty)) {
      _difficulty = 'Moderate';
    }
    _attemptStatus = d['attempt_status'] ?? d['attemptStatus'] ?? 'Not Attempted';
    if (!['Not Attempted', 'In Progress', 'Completed'].contains(_attemptStatus)) {
      _attemptStatus = 'Not Attempted';
    }
    _status = d['status'] ?? 'Published';
    _isFree = d['is_free'] == true;
    _showPurchaseButton = d['show_purchase_button'] != false;

    // Overview & Key Features init
    _longDescCtrl = TextEditingController(
      text: (d['long_description'] ?? d['longDescription'] ?? '').toString().isNotEmpty
          ? (d['long_description'] ?? d['longDescription']).toString()
          : 'This comprehensive test series has been strictly curated by top NEET/JEE subject experts following the latest NTA exam pattern. Designed to emulate the exact pressure, time constraints, and multi-concept question levels of the real computer-based examination. It empowers aspirants with predictive All India Rankings, deep topic-level analytics, and error diagnosis to optimize their scores.',
    );

    final rawFeatures = (d['features'] is List) ? (d['features'] as List) : [];
    Map<String, String> getFeature(int index, String defTitle, String defDesc) {
      if (index < rawFeatures.length && rawFeatures[index] is Map) {
        final f = rawFeatures[index] as Map;
        return {
          'title': (f['title'] ?? defTitle).toString(),
          'description': (f['description'] ?? defDesc).toString(),
        };
      }
      return {'title': defTitle, 'description': defDesc};
    }

    final f1 = getFeature(0, '100% NTA Exam Pattern', 'Matches exact weightage, question difficulty, and sectional division (Section A & Section B).');
    final f2 = getFeature(1, 'All India Rank Prediction', 'Real-time percentile benchmarking and national rank estimation against 14,000+ active aspirants.');
    final f3 = getFeature(2, 'Step-by-Step Solutions', 'Detailed conceptual explanations and shortcut techniques for every single problem.');
    final f4 = getFeature(3, 'Deep Performance Analytics', 'Identify weak chapters, wasted time on unattempted questions, and negative mark traps.');

    _f1TitleCtrl = TextEditingController(text: f1['title']);
    _f1DescCtrl = TextEditingController(text: f1['description']);
    _f2TitleCtrl = TextEditingController(text: f2['title']);
    _f2DescCtrl = TextEditingController(text: f2['description']);
    _f3TitleCtrl = TextEditingController(text: f3['title']);
    _f3DescCtrl = TextEditingController(text: f3['description']);
    _f4TitleCtrl = TextEditingController(text: f4['title']);
    _f4DescCtrl = TextEditingController(text: f4['description']);

    // Tests List init
    if (d['tests'] is List && (d['tests'] as List).isNotEmpty) {
      _tests = (d['tests'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      _tests = [];
    }

    // Reviews List init
    if (d['reviews'] is List && (d['reviews'] as List).isNotEmpty) {
      _reviews = (d['reviews'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      _reviews = [];
    }

    // Top Scores & Rankers init
    final ts = (d['top_scores'] is Map)
        ? Map<String, dynamic>.from(d['top_scores'])
        : ((d['topScores'] is Map) ? Map<String, dynamic>.from(d['topScores']) : {});

    _highestScoreCtrl = TextEditingController(text: (ts['highest_score'] ?? (_exam.contains('JEE') ? 296 : 712)).toString());
    _avgScoreCtrl = TextEditingController(text: (ts['average_score'] ?? (_exam.contains('JEE') ? 210 : 584)).toString());
    _activeAspirantsCtrl = TextEditingController(text: (ts['active_aspirants'] ?? '14,850+').toString());
    _ratingScoreCtrl = TextEditingController(text: (ts['rating_score'] ?? 4.9).toString());
    _ratingsCountCtrl = TextEditingController(text: (ts['ratings_count'] ?? 1480).toString());

    if (ts['rankers'] is List && (ts['rankers'] as List).isNotEmpty) {
      _rankers = (ts['rankers'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      _rankers = [];
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _longDescCtrl.dispose();
    _bannerCtrl.dispose();
    _priceCtrl.dispose();
    _origPriceCtrl.dispose();
    _linkCtrl.dispose();
    _buttonTextCtrl.dispose();
    _testCountCtrl.dispose();
    _questionCountCtrl.dispose();
    _durationCtrl.dispose();
    _validityCtrl.dispose();
    _syllabusCtrl.dispose();

    _f1TitleCtrl.dispose();
    _f1DescCtrl.dispose();
    _f2TitleCtrl.dispose();
    _f2DescCtrl.dispose();
    _f3TitleCtrl.dispose();
    _f3DescCtrl.dispose();
    _f4TitleCtrl.dispose();
    _f4DescCtrl.dispose();

    _highestScoreCtrl.dispose();
    _avgScoreCtrl.dispose();
    _activeAspirantsCtrl.dispose();
    _ratingScoreCtrl.dispose();
    _ratingsCountCtrl.dispose();

    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      _tabController.animateTo(0);
      return;
    }
    setState(() => _isSaving = true);

    final isEdit = widget.initialData != null && widget.initialData!['id'] != null;
    final seriesId = isEdit
        ? widget.initialData!['id'].toString()
        : SupabaseService.toValidUuid('ts_${_exam}_${_year}_${_titleCtrl.text.trim()}');

    final data = {
      'id': seriesId,
      'title': _titleCtrl.text.trim(),
      'name': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'long_description': _longDescCtrl.text.trim(),
      'exam': _exam,
      'year': _year,
      'category': _category,
      'banner_image_url': _bannerCtrl.text.trim(),
      'is_free': _isFree,
      'price': double.tryParse(_priceCtrl.text) ?? 299.0,
      'original_price': double.tryParse(_origPriceCtrl.text) ?? 999.0,
      'purchase_link': _linkCtrl.text.trim(),
      'purchase_button_text': _buttonTextCtrl.text.trim().isNotEmpty ? _buttonTextCtrl.text.trim() : 'Join',
      'show_purchase_button': _showPurchaseButton,
      'test_count': _tests.isNotEmpty ? _tests.length : (int.tryParse(_testCountCtrl.text) ?? 1),
      'question_count': int.tryParse(_questionCountCtrl.text) ?? 200,
      'duration_minutes': int.tryParse(_durationCtrl.text) ?? 180,
      'difficulty': _difficulty,
      'test_type': _testType,
      'validity': _validityCtrl.text.trim().isNotEmpty ? _validityCtrl.text.trim() : 'Valid until exam',
      'syllabus_url': _syllabusCtrl.text.trim(),
      'attempt_status': _attemptStatus,
      'status': _status,
      'features': [
        {'title': _f1TitleCtrl.text.trim(), 'description': _f1DescCtrl.text.trim()},
        {'title': _f2TitleCtrl.text.trim(), 'description': _f2DescCtrl.text.trim()},
        {'title': _f3TitleCtrl.text.trim(), 'description': _f3DescCtrl.text.trim()},
        {'title': _f4TitleCtrl.text.trim(), 'description': _f4DescCtrl.text.trim()},
      ],
      'tests': _tests,
      'reviews': _reviews,
      'top_scores': {
        'highest_score': int.tryParse(_highestScoreCtrl.text.trim()) ?? (_exam.contains('JEE') ? 296 : 712),
        'average_score': int.tryParse(_avgScoreCtrl.text.trim()) ?? (_exam.contains('JEE') ? 210 : 584),
        'active_aspirants': _activeAspirantsCtrl.text.trim().isNotEmpty ? _activeAspirantsCtrl.text.trim() : '14,850+',
        'rating_score': double.tryParse(_ratingScoreCtrl.text.trim()) ?? 4.9,
        'ratings_count': int.tryParse(_ratingsCountCtrl.text.trim()) ?? 1480,
        'rankers': _rankers,
      },
      'updated_at': DateTime.now().toIso8601String(),
    };

    await SupabaseService.saveTestSeries(data);
    setState(() => _isSaving = false);

    if (mounted) {
      Navigator.of(context).pop();
      widget.onSaved();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Test Series "${data['title']}" saved with all product contents!'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  // --- SUB DIALOG: ADD CUSTOM TEST ---
  void _showAddTestDialog() {
    final titleCtrl = TextEditingController(text: 'Mock Test ${_tests.length + 1}');
    final qCtrl = TextEditingController(text: _exam.contains('JEE') ? '90' : '200');
    final marksCtrl = TextEditingController(text: _exam.contains('JEE') ? '300' : '720');
    final durCtrl = TextEditingController(text: '180');
    String type = _testType;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Row(
            children: [
              Icon(Icons.add_task_rounded, color: Color(0xFF4F46E5), size: 20),
              SizedBox(width: 8),
              Text('Add Test to Series', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Test Name / Title *', hintText: 'e.g. Full Syllabus Mock 01'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: qCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Questions Count *'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: marksCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Total Marks *'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: durCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Duration (Minutes) *'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: ['Full', 'Part + Unit + Full', 'Chapter + Part + Unit + Full', 'Part', 'Chapter'].contains(type) ? type : 'Full',
                          decoration: const InputDecoration(labelText: 'Test Type *'),
                          items: const [
                            DropdownMenuItem(value: 'Full', child: Text('Full Syllabus')),
                            DropdownMenuItem(value: 'Part + Unit + Full', child: Text('Part + Unit + Full')),
                            DropdownMenuItem(value: 'Chapter + Part + Unit + Full', child: Text('Chapter + Part + Unit + Full')),
                            DropdownMenuItem(value: 'Part', child: Text('Part Syllabus')),
                            DropdownMenuItem(value: 'Chapter', child: Text('Chapter Wise')),
                          ],
                          onChanged: (v) => setDlgState(() => type = v!),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) return;
                setState(() {
                  _tests.add({
                    'id': 'test_${DateTime.now().millisecondsSinceEpoch}',
                    'title': titleCtrl.text.trim(),
                    'questions': int.tryParse(qCtrl.text.trim()) ?? 200,
                    'marks': int.tryParse(marksCtrl.text.trim()) ?? 720,
                    'duration': int.tryParse(durCtrl.text.trim()) ?? 180,
                    'type': type,
                    'status': 'Not Attempted',
                  });
                  _testCountCtrl.text = _tests.length.toString();
                });
                Navigator.pop(ctx);
              },
              child: const Text('Add Test'),
            ),
          ],
        ),
      ),
    );
  }

  // --- SUB DIALOG: LINK PUBLISHED PAPER ---
  void _showLinkPaperDialog() {
    if (widget.availablePapers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No published papers found in the database.')),
      );
      return;
    }

    Map<String, dynamic> selectedPaper = widget.availablePapers.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Row(
            children: [
              Icon(Icons.link_rounded, color: Color(0xFF10B981), size: 20),
              SizedBox(width: 8),
              Text('Link Published Paper', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select an existing published test paper from question uploads to link directly into this test series:',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<Map<String, dynamic>>(
                  value: selectedPaper,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Choose Paper *'),
                  items: widget.availablePapers.map((p) {
                    final name = (p['paper_name'] ?? p['paperName'] ?? p['title'] ?? 'Untitled Paper').toString();
                    final qCount = p['question_count'] ?? p['saved_questions_count'] ?? 200;
                    return DropdownMenuItem(
                      value: p,
                      child: Text('$name ($qCount Qs)', overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (v) => setDlgState(() => selectedPaper = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
              onPressed: () {
                final name = (selectedPaper['paper_name'] ?? selectedPaper['paperName'] ?? selectedPaper['title'] ?? 'Test Paper').toString();
                final pId = selectedPaper['id']?.toString() ?? 'p_${DateTime.now().millisecondsSinceEpoch}';
                final qCount = selectedPaper['question_count'] ?? selectedPaper['saved_questions_count'] ?? (_exam.contains('JEE') ? 90 : 200);
                final marks = selectedPaper['total_marks'] ?? (_exam.contains('JEE') ? 300 : 720);
                final duration = selectedPaper['duration_minutes'] ?? 180;

                setState(() {
                  _tests.add({
                    'id': pId,
                    'paper_id': pId,
                    'title': name,
                    'questions': qCount,
                    'marks': marks,
                    'duration': duration,
                    'type': _testType,
                    'status': 'Not Attempted',
                  });
                  _testCountCtrl.text = _tests.length.toString();
                });
                Navigator.pop(ctx);
              },
              child: const Text('Link Paper'),
            ),
          ],
        ),
      ),
    );
  }

  // --- SUB DIALOG: ADD REVIEW ---
  void _showAddReviewDialog() {
    final nameCtrl = TextEditingController();
    final credCtrl = TextEditingController(text: 'AIR 142 • NEET Qualified');
    final dateCtrl = TextEditingController(text: 'August 2026');
    final commentCtrl = TextEditingController();
    int rating = 5;
    bool isVerified = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Row(
            children: [
              Icon(Icons.rate_review_rounded, color: Color(0xFFF59E0B), size: 20),
              SizedBox(width: 8),
              Text('Add Student Review', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(labelText: 'Student Name *', hintText: 'e.g. Aarav Sharma'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<int>(
                          value: rating,
                          decoration: const InputDecoration(labelText: 'Rating *'),
                          items: [5, 4, 3, 2, 1]
                              .map((r) => DropdownMenuItem(value: r, child: Text('$r ★')))
                              .toList(),
                          onChanged: (v) => setDlgState(() => rating = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: credCtrl,
                          decoration: const InputDecoration(labelText: 'Credential / AIR *', hintText: 'e.g. AIR 142 • NEET Qualified'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: dateCtrl,
                          decoration: const InputDecoration(labelText: 'Review Date *', hintText: 'e.g. August 2026'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: commentCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Review Comment / Feedback *', hintText: 'Share how this test series helped improve score and speed.'),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: const Text('Mark as Verified Student Review', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                    value: isVerified,
                    onChanged: (v) => setDlgState(() => isVerified = v ?? true),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.white),
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty || commentCtrl.text.trim().isEmpty) return;
                setState(() {
                  _reviews.add({
                    'name': nameCtrl.text.trim(),
                    'credential': credCtrl.text.trim(),
                    'rating': rating,
                    'date': dateCtrl.text.trim(),
                    'comment': commentCtrl.text.trim(),
                    'is_verified': isVerified,
                  });
                });
                Navigator.pop(ctx);
              },
              child: const Text('Add Review'),
            ),
          ],
        ),
      ),
    );
  }

  // --- SUB DIALOG: ADD TOP RANKER ---
  void _showAddRankerDialog() {
    final rankCtrl = TextEditingController(text: (_rankers.length + 1).toString());
    final nameCtrl = TextEditingController();
    final scoreCtrl = TextEditingController(text: _highestScoreCtrl.text);
    final accCtrl = TextEditingController(text: '98.2%');
    final pctlCtrl = TextEditingController(text: '99.99%ile');
    final badgeCtrl = TextEditingController(text: 'AIR ${_rankers.length + 1}');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: Color(0xFF10B981), size: 20),
              SizedBox(width: 8),
              Text('Add Top Ranker to Leaderboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          controller: rankCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Rank # *'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(labelText: 'Student Name *', hintText: 'e.g. Aayush Kulkarni'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: scoreCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Score *', hintText: '712'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: accCtrl,
                          decoration: const InputDecoration(labelText: 'Accuracy *', hintText: '98.2%'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: pctlCtrl,
                          decoration: const InputDecoration(labelText: 'Percentile *', hintText: '99.99%ile'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: badgeCtrl,
                          decoration: const InputDecoration(labelText: 'Badge Tag *', hintText: 'AIR 1'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                setState(() {
                  _rankers.add({
                    'rank': int.tryParse(rankCtrl.text.trim()) ?? (_rankers.length + 1),
                    'name': nameCtrl.text.trim(),
                    'score': int.tryParse(scoreCtrl.text.trim()) ?? 700,
                    'accuracy': accCtrl.text.trim(),
                    'percentile': pctlCtrl.text.trim(),
                    'badge': badgeCtrl.text.trim(),
                  });
                });
                Navigator.pop(ctx);
              },
              child: const Text('Add Ranker'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialData != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 860,
        constraints: const BoxConstraints(maxHeight: 820),
        child: Column(
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF4F46E5), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEdit ? 'Edit Test Series & Full Product Suite' : 'Create New Test Series Suite',
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Manage overview, curriculum, all tests, reviews, and top rankers leaderboard directly.',
                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),

            // Tab Bar Navigation
            Container(
              color: const Color(0xFFF8FAFC),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: const Color(0xFF4F46E5),
                unselectedLabelColor: const Color(0xFF64748B),
                indicatorColor: const Color(0xFF4F46E5),
                indicatorWeight: 3,
                tabs: [
                  const Tab(icon: Icon(Icons.tune_rounded, size: 16), text: '1. Basic & Pricing'),
                  const Tab(icon: Icon(Icons.article_outlined, size: 16), text: '2. Product Overview'),
                  Tab(icon: const Icon(Icons.format_list_bulleted_rounded, size: 16), text: '3. All Tests (${_tests.length})'),
                  Tab(icon: const Icon(Icons.star_rate_rounded, size: 16), text: '4. Reviews (${_reviews.length})'),
                  Tab(icon: const Icon(Icons.emoji_events_outlined, size: 16), text: '5. Top Scores (${_rankers.length})'),
                ],
              ),
            ),

            // Modal Body: TabBarView
            Expanded(
              child: Form(
                key: _formKey,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // TAB 1: BASIC & PRICING
                    _buildTab1BasicAndPricing(),

                    // TAB 2: PRODUCT OVERVIEW & KEY FEATURES
                    _buildTab2OverviewAndFeatures(),

                    // TAB 3: ALL TESTS IN SERIES
                    _buildTab3AllTests(),

                    // TAB 4: REVIEWS & RATINGS
                    _buildTab4Reviews(),

                    // TAB 5: TOP SCORES & RANKERS
                    _buildTab5TopScores(),
                  ],
                ),
              ),
            ),

            // Modal Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'All data is saved real-time to Supabase & synced with student cards and detail view.',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _isSaving ? null : _handleSave,
                        icon: _isSaving
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.check_rounded, size: 18, color: Colors.white),
                        label: Text(
                          _isSaving ? 'Saving...' : 'Save All Changes',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 1: BASIC & PRICING
  // ===========================================================================
  Widget _buildTab1BasicAndPricing() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Basic Info
          _buildSectionHeading('1. Basic Details & Categorization'),
          const SizedBox(height: 12),
          TextFormField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Test Series Name / Title *',
              hintText: 'e.g. NEET 2026 Full Syllabus Master Test Series',
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a title' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _descCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Short Description / Card Teaser',
              hintText: 'Curated by top NEET/JEE faculties with complete solutions and all India rankings.',
            ),
          ),
          const SizedBox(height: 16),

          // Dropdown Row: Exam, Year, Category, Status
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _exam,
                  decoration: const InputDecoration(labelText: 'Exam *'),
                  items: ['NEET', 'JEE Main', 'JEE Advanced', 'AIIMS', 'CUET']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _exam = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _year,
                  menuMaxHeight: 320,
                  decoration: const InputDecoration(labelText: 'Year *'),
                  items: _AdminTestSeriesManagerScreenState.availableYears
                      .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                      .toList(),
                  onChanged: (v) => setState(() => _year = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _AdminTestSeriesManagerScreenState.availableCategories.contains(_category)
                      ? _category
                      : 'Full Syllabus',
                  decoration: const InputDecoration(labelText: 'Category *'),
                  items: _AdminTestSeriesManagerScreenState.availableCategories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _status,
                  decoration: const InputDecoration(labelText: 'Status *'),
                  items: ['Published', 'Draft', 'Archived']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => _status = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Section 2: Banner Image
          _buildSectionHeading('2. Banner Graphic & Thumbnail'),
          const SizedBox(height: 12),
          TextFormField(
            controller: _bannerCtrl,
            decoration: const InputDecoration(
              labelText: 'Banner Image URL',
              hintText: 'https://example.com/banner.jpg',
            ),
            onChanged: (v) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              const Text('Presets: ', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
              ...List.generate(_sampleBanners.length, (i) {
                return InkWell(
                  onTap: () => setState(() => _bannerCtrl.text = _sampleBanners[i]),
                  child: Chip(
                    label: Text('Theme ${i + 1}', style: const TextStyle(fontSize: 10)),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 10),
          if (_bannerCtrl.text.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 100,
                width: double.infinity,
                child: Image.network(
                  _bannerCtrl.text,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, st) => Container(
                    color: const Color(0xFFF1F5F9),
                    child: const Center(child: Text('Invalid Image URL', style: TextStyle(color: Colors.red, fontSize: 11))),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),

          // Section 3: Pricing & Purchase Links
          _buildSectionHeading('3. Pricing, Purchase Links & Buttons'),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Is this Test Series 100% Free?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
            subtitle: const Text('Toggle on if students can access this test series without purchasing', style: TextStyle(fontSize: 11)),
            value: _isFree,
            onChanged: (v) => setState(() => _isFree = v),
            contentPadding: EdgeInsets.zero,
          ),
          if (!_isFree) ...[
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Sale / Discounted Price (₹) *',
                      hintText: '299',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _origPriceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Original Price / MRP (₹) *',
                      hintText: '999',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _linkCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Purchase Link / Checkout URL',
                    hintText: 'https://razorpay.me/@cosmyra or /checkout',
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 1,
                child: TextFormField(
                  controller: _buttonTextCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Button Text',
                    hintText: 'Enroll Now',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            title: const Text('Show Purchase Button on Student Page', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
            subtitle: const Text('Displays the configured CTA button directly on the test series card', style: TextStyle(fontSize: 11)),
            value: _showPurchaseButton,
            onChanged: (v) => setState(() => _showPurchaseButton = v),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 24),

          // Section 4: Specifications
          _buildSectionHeading('4. Test Structure Specifications'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _testCountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Total Estimated Tests *',
                    hintText: 'e.g. 25',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: ['Full', 'Part + Unit + Full', 'Chapter + Part + Unit + Full', 'Part', 'Chapter'].contains(_testType) ? _testType : 'Full',
                  decoration: const InputDecoration(labelText: 'Test Type (Full / Part / Chapter) *'),
                  items: const [
                    DropdownMenuItem(value: 'Full', child: Text('Full Syllabus')),
                    DropdownMenuItem(value: 'Part + Unit + Full', child: Text('Part + Unit + Full Syllabus')),
                    DropdownMenuItem(value: 'Chapter + Part + Unit + Full', child: Text('Chapter + Part + Unit + Full Syllabus')),
                    DropdownMenuItem(value: 'Part', child: Text('Part Syllabus')),
                    DropdownMenuItem(value: 'Chapter', child: Text('Chapter Wise')),
                  ],
                  onChanged: (v) => setState(() => _testType = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _durationCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Duration (Minutes)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: ['Easy', 'Moderate', 'Advanced', 'Mixed'].contains(_difficulty) ? _difficulty : 'Moderate',
                  decoration: const InputDecoration(labelText: 'Difficulty *'),
                  items: ['Easy', 'Moderate', 'Advanced', 'Mixed']
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (v) => setState(() => _difficulty = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _validityCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Validity *',
                    hintText: 'e.g. Valid until exam, 1 Year Access',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _syllabusCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Download Syllabus URL (PDF / Web link)',
                    hintText: 'https://neet-jee.in/syllabus.pdf',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _attemptStatus,
                  decoration: const InputDecoration(labelText: 'Attempt Status *'),
                  items: ['Not Attempted', 'In Progress', 'Completed']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => _attemptStatus = v!),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2: PRODUCT OVERVIEW & KEY FEATURES
  // ===========================================================================
  Widget _buildTab2OverviewAndFeatures() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeading('Detailed Product Overview & Syllabus Description'),
          const SizedBox(height: 6),
          const Text(
            'This full description will appear when a student clicks the test card under "Overview & Details". You can write multi-paragraph text explaining test coverage, syllabus strategy, and benefits.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _longDescCtrl,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'In-Depth Product Description *',
              hintText: 'Enter full description of the test series, curriculum breakdown, and exam strategy...',
            ),
          ),
          const SizedBox(height: 28),

          _buildSectionHeading('Key Features & Inclusions (4 Featured Inclusions)'),
          const SizedBox(height: 6),
          const Text(
            'These 4 highlights appear as prominent feature cards in the Overview tab for students.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),

          // Feature 1
          _buildFeatureInputCard(1, _f1TitleCtrl, _f1DescCtrl, const Color(0xFF2563EB)),
          const SizedBox(height: 12),
          // Feature 2
          _buildFeatureInputCard(2, _f2TitleCtrl, _f2DescCtrl, const Color(0xFF059669)),
          const SizedBox(height: 12),
          // Feature 3
          _buildFeatureInputCard(3, _f3TitleCtrl, _f3DescCtrl, const Color(0xFFD97706)),
          const SizedBox(height: 12),
          // Feature 4
          _buildFeatureInputCard(4, _f4TitleCtrl, _f4DescCtrl, const Color(0xFF7C3AED)),
        ],
      ),
    );
  }

  Widget _buildFeatureInputCard(int num, TextEditingController titleCtrl, TextEditingController descCtrl, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: color.withOpacity(0.12),
            child: Text('$num', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                TextFormField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Feature $num Title',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: descCtrl,
                  decoration: InputDecoration(
                    labelText: 'Feature $num Description',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 3: ALL TESTS IN SERIES
  // ===========================================================================
  Widget _buildTab3AllTests() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeading('All Tests in this Series (${_tests.length})'),
                  const SizedBox(height: 4),
                  const Text(
                    'Real individual tests that students can view and launch from the "All Tests" tab.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _showLinkPaperDialog,
                    icon: const Icon(Icons.link_rounded, size: 16),
                    label: const Text('Link Published Paper'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF10B981),
                      side: const BorderSide(color: Color(0xFF10B981)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _showAddTestDialog,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Add Custom Test'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_tests.isEmpty)
            Container(
              padding: const EdgeInsets.all(36),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.quiz_outlined, size: 48, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 12),
                  const Text(
                    'No individual tests added yet to this series',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Add custom test papers or link published test papers directly using the buttons above.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _showAddTestDialog,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Add First Test'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _tests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, idx) {
                final t = _tests[idx];
                final title = (t['title'] ?? 'Test ${idx + 1}').toString();
                final qCount = t['questions'] ?? 200;
                final marks = t['marks'] ?? 720;
                final duration = t['duration'] ?? 180;
                final type = (t['type'] ?? 'Full').toString();
                final status = (t['status'] ?? 'Not Attempted').toString();

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '#${idx + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5), fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A))),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              children: [
                                _buildMiniBadge('$qCount Qs'),
                                _buildMiniBadge('$marks Marks'),
                                _buildMiniBadge('$duration Mins'),
                                _buildMiniBadge('$type Syllabus'),
                                _buildMiniBadge(status, color: const Color(0xFF10B981)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
                        tooltip: 'Remove Test',
                        onPressed: () {
                          setState(() {
                            _tests.removeAt(idx);
                            _testCountCtrl.text = _tests.length.toString();
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 4: REVIEWS & RATINGS
  // ===========================================================================
  Widget _buildTab4Reviews() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeading('Student Reviews & Ratings (${_reviews.length})'),
                  const SizedBox(height: 4),
                  const Text(
                    'Real verified testimonials and ratings displayed in the "Reviews" tab.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showAddReviewDialog,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Student Review'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Rating Score and Count Row
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _ratingScoreCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Overall Rating Score (e.g. 4.9) *',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _ratingsCountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Total Ratings Count (e.g. 1480) *',
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (_reviews.isEmpty)
            Container(
              padding: const EdgeInsets.all(36),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_border_rounded, size: 48, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 12),
                  const Text(
                    'No student reviews added yet',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Add verified student feedback, AIR ranks, and star ratings using the button above.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _showAddReviewDialog,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Add First Review'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.white),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _reviews.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, idx) {
                final r = _reviews[idx];
                final name = (r['name'] ?? 'Aspirant').toString();
                final cred = (r['credential'] ?? 'Verified Aspirant').toString();
                final rating = (r['rating'] is num) ? (r['rating'] as num).toInt() : (int.tryParse(r['rating']?.toString() ?? '5') ?? 5);
                final date = (r['date'] ?? 'Recent').toString();
                final comment = (r['comment'] ?? '').toString();

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFF4F46E5),
                        child: Text(name.isNotEmpty ? name[0] : 'S', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A))),
                                const SizedBox(width: 6),
                                const Icon(Icons.verified, size: 13, color: Color(0xFF16A34A)),
                                const Spacer(),
                                Row(
                                  children: List.generate(
                                    rating,
                                    (_) => const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(date, style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(cred, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            const SizedBox(height: 6),
                            Text(comment, style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
                        tooltip: 'Remove Review',
                        onPressed: () => setState(() => _reviews.removeAt(idx)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 5: TOP SCORES & RANKERS
  // ===========================================================================
  Widget _buildTab5TopScores() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeading('Top Scores & Leaderboard (${_rankers.length})'),
                  const SizedBox(height: 4),
                  const Text(
                    'Metrics and Hall of Fame rankers displayed in the "Top Scores & Users" tab.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showAddRankerDialog,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Top Ranker'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3 Metric inputs
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _highestScoreCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Highest Score Achieved *', hintText: '712', isDense: true),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextFormField(
                    controller: _avgScoreCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Platform Average Score *', hintText: '584', isDense: true),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextFormField(
                    controller: _activeAspirantsCtrl,
                    decoration: const InputDecoration(labelText: 'Active Aspirants *', hintText: '14,850+', isDense: true),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (_rankers.isEmpty)
            Container(
              padding: const EdgeInsets.all(36),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emoji_events_outlined, size: 48, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 12),
                  const Text(
                    'No top rankers added yet to the leaderboard',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Add your top test series scorers, accuracy rates, and All India Ranks using the button above.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _showAddRankerDialog,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Add First Ranker'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _rankers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, idx) {
                final r = _rankers[idx];
                final rank = r['rank'] ?? (idx + 1);
                final name = (r['name'] ?? 'Ranker ${idx + 1}').toString();
                final score = r['score'] ?? 700;
                final acc = (r['accuracy'] ?? '98.0%').toString();
                final pctl = (r['percentile'] ?? '99.9%ile').toString();
                final badge = (r['badge'] ?? 'AIR $rank').toString();

                Color medalColor = const Color(0xFF2563EB);
                if (rank == 1) medalColor = const Color(0xFFF59E0B);
                else if (rank == 2) medalColor = const Color(0xFF94A3B8);
                else if (rank == 3) medalColor = const Color(0xFFB45309);

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: medalColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Rank #$rank',
                          style: TextStyle(fontWeight: FontWeight.bold, color: medalColor, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A))),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(color: medalColor.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                                  child: Text(badge, style: TextStyle(color: medalColor, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              children: [
                                _buildMiniBadge('Score: $score'),
                                _buildMiniBadge('Accuracy: $acc'),
                                _buildMiniBadge('Percentile: $pctl'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
                        tooltip: 'Remove Ranker',
                        onPressed: () => setState(() => _rankers.removeAt(idx)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMiniBadge(String text, {Color color = const Color(0xFF475569)}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildSectionHeading(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 13.5,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF4F46E5),
      ),
    );
  }
}
