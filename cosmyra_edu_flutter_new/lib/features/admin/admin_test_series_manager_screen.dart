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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final list = await SupabaseService.fetchAllTestSeries();
    if (mounted) {
      setState(() {
        _testSeriesList = list;
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
            items: ['All', 'Full Syllabus', 'Chapter Wise', 'Topic Wise', 'Mock Tests'],
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: SizedBox(
                  height: 120,
                  width: double.infinity,
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
              // Status Badge
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: status == 'Published' ? const Color(0xFF10B981) : const Color(0xFF64748B),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              // Exam & Year Badge
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$exam $year',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),

          // 2. Content Details
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
                      _buildMiniPill(Icons.description_outlined, '$testCount Tests'),
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
  final VoidCallback onSaved;

  const _TestSeriesEditorDialog({
    Key? key,
    this.initialData,
    required this.onSaved,
  }) : super(key: key);

  @override
  State<_TestSeriesEditorDialog> createState() => _TestSeriesEditorDialogState();
}

class _TestSeriesEditorDialogState extends State<_TestSeriesEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

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
  late String _difficulty;
  late String _attemptStatus;
  late String _status;
  late bool _isFree;
  late bool _showPurchaseButton;

  final List<String> _sampleBanners = [
    'https://images.unsplash.com/photo-1532094349884-543bc11b234d?w=800&auto=format&fit=crop&q=60',
    'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=800&auto=format&fit=crop&q=60',
    'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=800&auto=format&fit=crop&q=60',
    'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=800&auto=format&fit=crop&q=60',
  ];

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
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
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
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
      'test_count': int.tryParse(_testCountCtrl.text) ?? 1,
      'question_count': int.tryParse(_questionCountCtrl.text) ?? 200,
      'duration_minutes': int.tryParse(_durationCtrl.text) ?? 180,
      'difficulty': _difficulty,
      'validity': _validityCtrl.text.trim().isNotEmpty ? _validityCtrl.text.trim() : 'Valid until exam',
      'syllabus_url': _syllabusCtrl.text.trim(),
      'attempt_status': _attemptStatus,
      'status': _status,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await SupabaseService.saveTestSeries(data);
    setState(() => _isSaving = false);

    if (mounted) {
      Navigator.of(context).pop();
      widget.onSaved();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Test Series "${data['title']}" saved successfully!'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialData != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Container(
        width: 720,
        constraints: const BoxConstraints(maxHeight: 780),
        child: Column(
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                        child: const Icon(Icons.tune_rounded, color: Color(0xFF4F46E5), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isEdit ? 'Edit Test Series' : 'Create New Test Series',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
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

            // Modal Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
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
                          labelText: 'Description / Highlights',
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
                              value: _category,
                              decoration: const InputDecoration(labelText: 'Category *'),
                              items: ['Full Syllabus', 'Chapter Wise', 'Topic Wise', 'Mock Tests']
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
                      // Preset image chips
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
                      // Banner live preview
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

                      // Section 4: Test Specifications
                      _buildSectionHeading('4. Test Structure Specifications'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _testCountCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Total Tests Count'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _questionCountCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Questions per Test'),
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
                          const SizedBox(width: 12),
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
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
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
                    'Tip: Questions can be uploaded or updated under Question Upload Step 1.',
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
                          _isSaving ? 'Saving...' : 'Save Test Series',
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
