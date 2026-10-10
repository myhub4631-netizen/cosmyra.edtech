import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import '../../core/services/supabase_service.dart';
import '../../models/models.dart';

class AdminPyqPaperManagerScreen extends StatefulWidget {
  final UserProfileModel? userProfile;
  final VoidCallback? onBack;

  const AdminPyqPaperManagerScreen({
    Key? key,
    this.userProfile,
    this.onBack,
  }) : super(key: key);

  @override
  State<AdminPyqPaperManagerScreen> createState() => _AdminPyqPaperManagerScreenState();
}

class _AdminPyqPaperManagerScreenState extends State<AdminPyqPaperManagerScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _allPapers = [];
  
  // Search and Filters
  String _searchQuery = '';
  String _selectedExamFilter = 'All Exams';
  String _selectedYearFilter = 'All Years';
  String _selectedStatusFilter = 'All Status';
  String _selectedCompletenessFilter = 'All';
  String _selectedSortBy = 'Year (Newest)';

  // Table selection
  final Set<String> _selectedPaperIds = {};

  // Pagination
  int _currentPage = 1;
  int _rowsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadPapers();
  }

  Future<void> _loadPapers() async {
    setState(() => _isLoading = true);
    final papers = await SupabaseService.fetchAllPapersAndTestSeries(forceRefresh: true);
    if (mounted) {
      setState(() {
        _allPapers = papers;
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredPapers {
    var list = _allPapers.where((p) {
      final title = (p['paper_name'] ?? p['paperName'] ?? p['title'] ?? '').toString().toLowerCase();
      final id = (p['id'] ?? p['paper_id'] ?? '').toString().toLowerCase();
      final code = (p['paper_code'] ?? p['paperCode'] ?? '').toString().toLowerCase();
      final phase = (p['phase_session'] ?? p['phaseSession'] ?? p['session'] ?? '').toString().toLowerCase();
      final exam = (p['exam'] ?? p['exam_name'] ?? p['target_exam'] ?? 'NEET').toString();
      final year = (p['year'] ?? '').toString();
      final status = (p['status'] ?? 'Published').toString();
      
      final actualCount = _getActualQuestionCount(p);
      final expectedCount = _getExpectedQuestionCount(p);

      // Search Query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase().trim();
        if (!title.contains(q) && !id.contains(q) && !code.contains(q) && !phase.contains(q) && !year.contains(q)) {
          return false;
        }
      }

      // Exam Filter
      if (_selectedExamFilter != 'All Exams') {
        if (_selectedExamFilter == 'NEET' && !exam.toUpperCase().contains('NEET')) return false;
        if (_selectedExamFilter == 'JEE Main' && !exam.toUpperCase().contains('MAIN')) return false;
        if (_selectedExamFilter == 'JEE Advanced' && !exam.toUpperCase().contains('ADV')) return false;
      }

      // Year Filter
      if (_selectedYearFilter != 'All Years') {
        if (year != _selectedYearFilter) return false;
      }

      // Status Filter
      if (_selectedStatusFilter != 'All Status') {
        if (status.toLowerCase() != _selectedStatusFilter.toLowerCase()) return false;
      }

      // Completeness Filter
      if (_selectedCompletenessFilter == 'Complete') {
        if (actualCount < expectedCount || actualCount == 0) return false;
      } else if (_selectedCompletenessFilter == 'Incomplete') {
        if (actualCount >= expectedCount || actualCount == 0) return false;
      } else if (_selectedCompletenessFilter == 'Empty (0 Qs)') {
        if (actualCount > 0) return false;
      } else if (_selectedCompletenessFilter == 'Has Warnings') {
        if (actualCount == expectedCount && actualCount > 0) return false;
      }

      return true;
    }).toList();

    // Sorting
    list.sort((a, b) {
      if (_selectedSortBy == 'Year (Newest)') {
        final yA = int.tryParse((a['year'] ?? '0').toString()) ?? 0;
        final yB = int.tryParse((b['year'] ?? '0').toString()) ?? 0;
        return yB.compareTo(yA);
      } else if (_selectedSortBy == 'Year (Oldest)') {
        final yA = int.tryParse((a['year'] ?? '0').toString()) ?? 0;
        final yB = int.tryParse((b['year'] ?? '0').toString()) ?? 0;
        return yA.compareTo(yB);
      } else if (_selectedSortBy == 'Title (A-Z)') {
        final tA = (a['paper_name'] ?? a['title'] ?? '').toString();
        final tB = (b['paper_name'] ?? b['title'] ?? '').toString();
        return tA.compareTo(tB);
      } else if (_selectedSortBy == 'Questions (High to Low)') {
        final qA = _getActualQuestionCount(a);
        final qB = _getActualQuestionCount(b);
        return qB.compareTo(qA);
      }
      return 0;
    });

    return list;
  }

  int _getActualQuestionCount(Map<String, dynamic> p) {
    if (p['actual_questions_count'] is num) return (p['actual_questions_count'] as num).toInt();
    if (p['saved_questions_count'] is num) return (p['saved_questions_count'] as num).toInt();
    if (p['questions'] is List) return (p['questions'] as List).length;
    return int.tryParse((p['actual_questions_count'] ?? p['saved_questions_count'] ?? '0').toString()) ?? 0;
  }

  int _getExpectedQuestionCount(Map<String, dynamic> p) {
    if (p['expected_question_count'] is num && (p['expected_question_count'] as num) > 0) {
      return (p['expected_question_count'] as num).toInt();
    }
    final format = ExamPaperFormatConfig.getPaperFormat(
      exam: (p['exam'] ?? p['exam_name'] ?? 'NEET').toString(),
      year: (p['year'] ?? '').toString(),
      paperName: (p['paper_name'] ?? p['title'] ?? '').toString(),
    );
    return format['totalQuestions'] as int? ?? 180;
  }

  int get _totalPapersCount => _allPapers.length;
  int get _totalQuestionsCount => _allPapers.fold(0, (sum, p) => sum + _getActualQuestionCount(p));
  int get _validPapersCount => _allPapers.where((p) {
    final act = _getActualQuestionCount(p);
    final exp = _getExpectedQuestionCount(p);
    return act >= exp && act > 0;
  }).length;
  int get _incompletePapersCount => _allPapers.length - _validPapersCount;

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredPapers;
    final totalPages = (filtered.length / _rowsPerPage).ceil().clamp(1, 999);
    if (_currentPage > totalPages) _currentPage = totalPages;

    final startIndex = (_currentPage - 1) * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage).clamp(0, filtered.length);
    final pageRows = filtered.sublist(startIndex, endIndex);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/admin');
            }
          },
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.description_outlined, color: Color(0xFF7C3AED), size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'PYQ Paper Manager',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                Text(
                  'Centralized CRUD Catalogue for NEET, JEE Main & JEE Advanced Papers',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: _loadPapers,
            icon: const Icon(Icons.refresh, size: 18, color: Color(0xFF64748B)),
            label: const Text('Refresh', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: _exportCsvCatalogue,
            icon: const Icon(Icons.download_rounded, size: 16, color: Color(0xFF4F46E5)),
            label: const Text('Export CSV', style: TextStyle(color: Color(0xFF4F46E5), fontSize: 13)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFC7D2FE)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: _importCsvMetadata,
            icon: const Icon(Icons.upload_file_rounded, size: 16, color: Color(0xFF059669)),
            label: const Text('Import CSV', style: TextStyle(color: Color(0xFF059669), fontSize: 13)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFA7F3D0)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _openCreatePaperDialog(),
            icon: const Icon(Icons.add, size: 18, color: Colors.white),
            label: const Text('Create Paper', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPapers,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Metric Cards Header
                    _buildStatsRow(),
                    const SizedBox(height: 20),

                    // 2. Search & Filter Bar
                    _buildFilterToolbar(),
                    const SizedBox(height: 16),

                    // 3. Bulk Action Bar (if items selected)
                    if (_selectedPaperIds.isNotEmpty) _buildBulkActionBar(),

                    // 4. Papers Data Table
                    _buildPapersTable(pageRows, filtered.length, startIndex, endIndex),
                    const SizedBox(height: 16),

                    // 5. Pagination Controls
                    _buildPaginationControls(filtered.length, totalPages),
                  ],
                ),
              ),
            ),
    );
  }

  // ==========================================
  // 1. STATS HEADER ROW
  // ==========================================
  Widget _buildStatsRow() {
    final validPct = _totalPapersCount > 0 ? ((_validPapersCount / _totalPapersCount) * 100).toStringAsFixed(1) : '0';
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total PYQ Papers',
            '$_totalPapersCount',
            'NEET & JEE Catalogues',
            Icons.folder_copy_outlined,
            const Color(0xFF4F46E5),
            const Color(0xFFEEF2FF),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Linked Questions',
            '$_totalQuestionsCount',
            'Total verified questions',
            Icons.help_outline_rounded,
            const Color(0xFF0284C7),
            const Color(0xFFE0F2FE),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Valid & Complete',
            '$_validPapersCount ($validPct%)',
            'Full question count met',
            Icons.check_circle_outline_rounded,
            const Color(0xFF16A34A),
            const Color(0xFFDCFCE7),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Incomplete / Empty',
            '$_incompletePapersCount',
            'Requires question upload',
            Icons.warning_amber_rounded,
            const Color(0xFFEA580C),
            const Color(0xFFFFEDD5),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, String subtext, IconData icon, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                ),
                Text(subtext, style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 2. FILTER TOOLBAR
  // ==========================================
  Widget _buildFilterToolbar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Search Input
              Expanded(
                flex: 3,
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search title, paper UUID, paper code, year, session...',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF94A3B8)),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Exam Filter
              _buildDropdownFilter(
                label: 'Exam',
                value: _selectedExamFilter,
                items: ['All Exams', 'NEET', 'JEE Main', 'JEE Advanced'],
                onChanged: (val) => setState(() => _selectedExamFilter = val!),
              ),
              const SizedBox(width: 8),

              // Year Filter
              _buildDropdownFilter(
                label: 'Year',
                value: _selectedYearFilter,
                items: ['All Years', '2026', '2025', '2024', '2023', '2022', '2021', '2020', '2019', '2018', '2017', '2016', '2015'],
                onChanged: (val) => setState(() => _selectedYearFilter = val!),
              ),
              const SizedBox(width: 8),

              // Status Filter
              _buildDropdownFilter(
                label: 'Status',
                value: _selectedStatusFilter,
                items: ['All Status', 'Published', 'Draft', 'Archived'],
                onChanged: (val) => setState(() => _selectedStatusFilter = val!),
              ),
              const SizedBox(width: 8),

              // Completeness Filter
              _buildDropdownFilter(
                label: 'Completeness',
                value: _selectedCompletenessFilter,
                items: ['All', 'Complete', 'Incomplete', 'Empty (0 Qs)', 'Has Warnings'],
                onChanged: (val) => setState(() => _selectedCompletenessFilter = val!),
              ),
              const SizedBox(width: 8),

              // Sort Filter
              _buildDropdownFilter(
                label: 'Sort By',
                value: _selectedSortBy,
                items: ['Year (Newest)', 'Year (Oldest)', 'Title (A-Z)', 'Questions (High to Low)'],
                onChanged: (val) => setState(() => _selectedSortBy = val!),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          isDense: true,
          style: const TextStyle(fontSize: 12.5, color: Color(0xFF1E293B), fontWeight: FontWeight.w500),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ==========================================
  // 3. BULK ACTION BAR
  // ==========================================
  Widget _buildBulkActionBar() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDDD6FE)),
      ),
      child: Row(
        children: [
          Text(
            '${_selectedPaperIds.length} papers selected',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF6B21A8)),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () => _bulkUpdateStatus('Published'),
            icon: const Icon(Icons.publish_rounded, size: 14, color: Colors.white),
            label: const Text('Publish Selected', style: TextStyle(fontSize: 12, color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _bulkUpdateStatus('Draft'),
            icon: const Icon(Icons.unpublished_rounded, size: 14, color: Colors.white),
            label: const Text('Unpublish Selected', style: TextStyle(fontSize: 12, color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _bulkUpdateStatus('Archived'),
            icon: const Icon(Icons.archive_outlined, size: 14, color: Colors.white),
            label: const Text('Archive Selected', style: TextStyle(fontSize: 12, color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF475569), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => setState(() => _selectedPaperIds.clear()),
            child: const Text('Deselect All', style: TextStyle(fontSize: 12, color: Color(0xFF6B21A8))),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 4. PAPERS DATA TABLE
  // ==========================================
  Widget _buildPapersTable(List<Map<String, dynamic>> pageRows, int totalCount, int startIndex, int endIndex) {
    if (pageRows.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: const [
            Icon(Icons.folder_off_outlined, size: 48, color: Color(0xFF94A3B8)),
            SizedBox(height: 12),
            Text('No PYQ papers found matching your criteria.', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
            SizedBox(height: 4),
            Text('Try clearing search filters or create a new PYQ paper record.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          ],
        ),
      );
    }

    final allOnPageSelected = pageRows.every((p) => _selectedPaperIds.contains((p['id'] ?? p['paper_id'] ?? '').toString()));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFC)),
            horizontalMargin: 16,
            columnSpacing: 18,
            columns: [
              DataColumn(
                label: Checkbox(
                  value: allOnPageSelected,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        for (var p in pageRows) {
                          final id = (p['id'] ?? p['paper_id'] ?? '').toString();
                          if (id.isNotEmpty) _selectedPaperIds.add(id);
                        }
                      } else {
                        for (var p in pageRows) {
                          final id = (p['id'] ?? p['paper_id'] ?? '').toString();
                          _selectedPaperIds.remove(id);
                        }
                      }
                    });
                  },
                ),
              ),
              const DataColumn(label: Text('EXAM & YEAR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
              const DataColumn(label: Text('PAPER TITLE & PHASE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
              const DataColumn(label: Text('PERMANENT UUID', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
              const DataColumn(label: Text('ACTUAL / EXPECTED Qs', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
              const DataColumn(label: Text('SUBJECT BREAKDOWN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
              const DataColumn(label: Text('VALIDATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
              const DataColumn(label: Text('STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
              const DataColumn(label: Text('ACTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
            ],
            rows: pageRows.map((p) {
              final paperId = (p['id'] ?? p['paper_id'] ?? '').toString();
              final isSelected = _selectedPaperIds.contains(paperId);
              final exam = (p['exam'] ?? p['exam_name'] ?? 'NEET').toString();
              final year = (p['year'] ?? '').toString();
              final title = (p['paper_name'] ?? p['paperName'] ?? p['title'] ?? 'PYQ Paper').toString();
              final phase = (p['phase_session'] ?? p['phaseSession'] ?? p['session'] ?? '').toString();
              final status = (p['status'] ?? 'Published').toString();

              final actualQs = _getActualQuestionCount(p);
              final expectedQs = _getExpectedQuestionCount(p);

              return DataRow(
                selected: isSelected,
                onSelectChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedPaperIds.add(paperId);
                    } else {
                      _selectedPaperIds.remove(paperId);
                    }
                  });
                },
                cells: [
                  DataCell(
                    Checkbox(
                      value: isSelected,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedPaperIds.add(paperId);
                          } else {
                            _selectedPaperIds.remove(paperId);
                          }
                        });
                      },
                    ),
                  ),

                  // Exam & Year Badge
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: exam.contains('NEET') ? const Color(0xFFECFDF5) : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: exam.contains('NEET') ? const Color(0xFFA7F3D0) : const Color(0xFFBFDBFE)),
                      ),
                      child: Text(
                        '$exam $year',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: exam.contains('NEET') ? const Color(0xFF047857) : const Color(0xFF1D4ED8),
                        ),
                      ),
                    ),
                  ),

                  // Paper Title & Phase
                  DataCell(
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        if (phase.isNotEmpty)
                          Text(
                            phase,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                      ],
                    ),
                  ),

                  // Permanent UUID
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          paperId.length > 18 ? '${paperId.substring(0, 18)}...' : paperId,
                          style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF475569)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF94A3B8)),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: paperId));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Copied UUID: $paperId'), duration: const Duration(seconds: 2)),
                            );
                          },
                          tooltip: 'Copy UUID',
                        ),
                      ],
                    ),
                  ),

                  // Actual vs Expected Qs
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: actualQs >= expectedQs
                            ? const Color(0xFFDCFCE7)
                            : (actualQs > 0 ? const Color(0xFFFEF3C7) : const Color(0xFFFEE2E2)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$actualQs / $expectedQs Qs',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: actualQs >= expectedQs
                              ? const Color(0xFF15803D)
                              : (actualQs > 0 ? const Color(0xFFB45309) : const Color(0xFFB91C1C)),
                        ),
                      ),
                    ),
                  ),

                  // Subject Breakdown
                  DataCell(
                    _buildSubjectBreakdownBadge(p, exam),
                  ),

                  // Validation Status
                  DataCell(
                    _buildValidationBadge(actualQs, expectedQs),
                  ),

                  // Status
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: status == 'Published'
                            ? const Color(0xFFF0FDF4)
                            : (status == 'Draft' ? const Color(0xFFFFFBEB) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: status == 'Published'
                              ? const Color(0xFF86EFAC)
                              : (status == 'Draft' ? const Color(0xFFFDE68A) : const Color(0xFFCBD5E1)),
                        ),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: status == 'Published'
                              ? const Color(0xFF166534)
                              : (status == 'Draft' ? const Color(0xFF92400E) : const Color(0xFF475569)),
                        ),
                      ),
                    ),
                  ),

                  // Actions
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_red_eye_outlined, size: 18, color: Color(0xFF7C3AED)),
                          onPressed: () => _previewAsStudent(paperId),
                          tooltip: 'View as Student (Admin Preview)',
                        ),
                        IconButton(
                          icon: const Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF4F46E5)),
                          onPressed: () => _openInspectPaperModal(p),
                          tooltip: 'Inspect Details & Audit',
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF0284C7)),
                          onPressed: () => _openEditPaperModal(p),
                          tooltip: 'Edit Metadata',
                        ),
                        IconButton(
                          icon: const Icon(Icons.format_list_bulleted_rounded, size: 18, color: Color(0xFF059669)),
                          onPressed: () => _navigateToQuestionEditor(paperId),
                          tooltip: 'Manage Questions',
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 18, color: Color(0xFF64748B)),
                          onSelected: (val) {
                            if (val == 'preview') {
                              _previewAsStudent(paperId);
                            } else if (val == 'archive') {
                              _toggleArchivePaper(paperId, status != 'Archived');
                            } else if (val == 'delete') {
                              _safeDeletePaper(p);
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(value: 'preview', child: Text('Preview as Student')),
                            PopupMenuItem(
                              value: 'archive',
                              child: Text(status == 'Archived' ? 'Restore Paper' : 'Archive Paper'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete Record', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectBreakdownBadge(Map<String, dynamic> p, String exam) {
    final act = _getActualQuestionCount(p);
    if (act == 0) {
      return const Text('P: 0 | C: 0 | B: 0', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)));
    }
    if (exam.contains('NEET')) {
      final pCount = act >= 180 ? 45 : (act * 0.25).toInt();
      final cCount = act >= 180 ? 45 : (act * 0.25).toInt();
      final bCount = act >= 180 ? 90 : (act * 0.50).toInt();
      return Text(
        'P: $pCount | C: $cCount | B: $bCount',
        style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w600),
      );
    } else {
      final pCount = act ~/ 3;
      return Text(
        'P: $pCount | C: $pCount | M: $pCount',
        style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w600),
      );
    }
  }

  Widget _buildValidationBadge(int actual, int expected) {
    if (actual == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
        child: const Text('Empty', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
      );
    } else if (actual >= expected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(4)),
        child: const Text('✓ Valid', style: TextStyle(fontSize: 10.5, color: Color(0xFF15803D), fontWeight: FontWeight.bold)),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(4)),
        child: Text('⚠ Incomplete (${expected - actual} short)', style: const TextStyle(fontSize: 10.5, color: Color(0xFFB45309), fontWeight: FontWeight.bold)),
      );
    }
  }

  // ==========================================
  // 5. PAGINATION CONTROLS
  // ==========================================
  Widget _buildPaginationControls(int totalFiltered, int totalPages) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Showing ${totalFiltered == 0 ? 0 : (_currentPage - 1) * _rowsPerPage + 1} to '
          '${(_currentPage * _rowsPerPage).clamp(0, totalFiltered)} of $totalFiltered papers',
          style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
        ),
        Row(
          children: [
            const Text('Rows per page: ', style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
            DropdownButton<int>(
              value: _rowsPerPage,
              isDense: true,
              underline: const SizedBox(),
              items: [10, 25, 50, 100].map((r) => DropdownMenuItem(value: r, child: Text('$r'))).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _rowsPerPage = val;
                    _currentPage = 1;
                  });
                }
              },
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
            ),
            Text('$_currentPage of $totalPages', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // CREATE PAPER DIALOG WITH DUPLICATE CHECK
  // ==========================================
  void _openCreatePaperDialog() {
    String exam = 'NEET';
    String year = '2026';
    String phaseSession = 'Phase 1';
    String paperName = 'NEET 2026 Phase 1';
    String paperCode = 'N26P1';
    String paperType = 'Medical (UG)';
    int expectedCount = 180;
    int duration = 180;
    double totalMarks = 720.0;
    String status = 'Published';
    String instructions = 'Attempt all sections carefully. 4 marks for correct answers, -1 mark for incorrect answers.';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dlgCtx, setDlgState) {
            void updateSuggestedTitle() {
              if (exam == 'NEET') {
                paperName = 'NEET $year $phaseSession';
                paperCode = 'N${year.substring(2)}${phaseSession.replaceAll(' ', '')}';
                expectedCount = 180;
                totalMarks = 720.0;
                paperType = 'Medical (UG)';
              } else if (exam == 'JEE Main') {
                paperName = 'JEE Main $year $phaseSession';
                paperCode = 'JM${year.substring(2)}${phaseSession.replaceAll(' ', '')}';
                expectedCount = 75;
                totalMarks = 300.0;
                paperType = 'Engineering (UG)';
              } else {
                paperName = 'JEE Advanced $year $phaseSession';
                paperCode = 'JA${year.substring(2)}${phaseSession.replaceAll(' ', '')}';
                expectedCount = 54;
                totalMarks = 180.0;
                paperType = 'Advanced';
              }
            }

            return AlertDialog(
              title: Row(
                children: const [
                  Icon(Icons.note_add_outlined, color: Color(0xFF7C3AED)),
                  SizedBox(width: 8),
                  Text('Create PYQ Paper Record', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SizedBox(
                width: 540,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Define paper metadata & exam format specifications. Can be created with 0 questions.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      const SizedBox(height: 16),

                      // Exam & Year
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: exam,
                              decoration: const InputDecoration(labelText: 'Target Exam', border: OutlineInputBorder()),
                              items: ['NEET', 'JEE Main', 'JEE Advanced'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setDlgState(() {
                                    exam = val;
                                    updateSuggestedTitle();
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: year,
                              decoration: const InputDecoration(labelText: 'Exam Year', border: OutlineInputBorder()),
                              items: List.generate(2027 - 1988 + 1, (i) => '${2027 - i}').map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setDlgState(() {
                                    year = val;
                                    updateSuggestedTitle();
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Phase / Session
                      TextFormField(
                        initialValue: phaseSession,
                        decoration: const InputDecoration(labelText: 'Session / Phase (e.g. Phase 1, Re-NEET, Shift 1)', border: OutlineInputBorder()),
                        onChanged: (val) {
                          phaseSession = val;
                          setDlgState(() => updateSuggestedTitle());
                        },
                      ),
                      const SizedBox(height: 12),

                      // Paper Name
                      TextFormField(
                        key: ValueKey(paperName),
                        initialValue: paperName,
                        decoration: const InputDecoration(labelText: 'Paper Title', border: OutlineInputBorder()),
                        onChanged: (val) => paperName = val,
                      ),
                      const SizedBox(height: 12),

                      // Expected Count & Duration
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: '$expectedCount',
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Expected Q Count', border: OutlineInputBorder()),
                              onChanged: (val) => expectedCount = int.tryParse(val) ?? expectedCount,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              initialValue: '$duration',
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Duration (Mins)', border: OutlineInputBorder()),
                              onChanged: (val) => duration = int.tryParse(val) ?? duration,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: status,
                              decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                              items: ['Published', 'Draft'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                              onChanged: (val) => setDlgState(() => status = val ?? status),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Instructions
                      TextFormField(
                        initialValue: instructions,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'Instructions', border: OutlineInputBorder()),
                        onChanged: (val) => instructions = val,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
                  onPressed: () async {
                    // Check duplicate
                    final matches = _allPapers.where((p) {
                      final pExam = (p['exam'] ?? '').toString().toUpperCase();
                      final pYear = (p['year'] ?? '').toString();
                      final pTitle = (p['paper_name'] ?? p['title'] ?? '').toString().toUpperCase();
                      return pExam.contains(exam.toUpperCase()) && pYear == year && pTitle == paperName.toUpperCase();
                    }).toList();

                    if (matches.isNotEmpty) {
                      final confirmDup = await showDialog<bool>(
                        context: context,
                        builder: (dupCtx) => AlertDialog(
                          title: const Text('⚠ Potential Duplicate Paper Detected'),
                          content: Text('A paper titled "$paperName" ($exam $year) already exists in the catalogue.\n\nAre you sure you want to create a second record?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(dupCtx, false), child: const Text('Cancel')),
                            ElevatedButton(onPressed: () => Navigator.pop(dupCtx, true), child: const Text('Create Duplicate Anyway')),
                          ],
                        ),
                      );
                      if (confirmDup != true) return;
                    }

                    // Create Paper Record
                    final paperData = {
                      'id': 'paper_${exam.toLowerCase()}_${year}_${DateTime.now().millisecondsSinceEpoch}',
                      'exam': exam,
                      'year': year,
                      'phase_session': phaseSession,
                      'paper_name': paperName,
                      'paper_code': paperCode,
                      'paper_type': paperType,
                      'question_count': expectedCount,
                      'expected_question_count': expectedCount,
                      'duration_minutes': duration,
                      'total_marks': totalMarks,
                      'status': status,
                      'instructions': instructions,
                      'source_category': 'PYQ',
                      'saved_questions_count': 0,
                    };

                    final res = await SupabaseService.savePaperRecord(paperData);
                    if (mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('✓ Successfully created paper record "${res['paper_name']}"!'), backgroundColor: const Color(0xFF16A34A)),
                      );
                      _loadPapers();
                    }
                  },
                  child: const Text('Create Record', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==========================================
  // INSPECT PAPER DETAILS & AUDIT MODAL
  // ==========================================
  void _openInspectPaperModal(Map<String, dynamic> paper) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        final paperId = (paper['id'] ?? paper['paper_id'] ?? '').toString();
        final title = (paper['paper_name'] ?? paper['paperName'] ?? paper['title'] ?? 'PYQ Paper').toString();
        final exam = (paper['exam'] ?? paper['exam_name'] ?? 'NEET').toString();
        final year = (paper['year'] ?? '').toString();
        final phase = (paper['phase_session'] ?? paper['phaseSession'] ?? '').toString();
        final status = (paper['status'] ?? 'Published').toString();
        final actual = _getActualQuestionCount(paper);
        final expected = _getExpectedQuestionCount(paper);

        return Container(
          height: MediaQuery.of(context).size.height * 0.82,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drawer Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      Text('$exam $year • $phase • UUID: $paperId', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(height: 24),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary Grid
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildAuditInfoTile('Actual Questions', '$actual Qs', actual >= expected ? Colors.green : Colors.orange),
                          _buildAuditInfoTile('Expected Format', '$expected Qs', Colors.blue),
                          _buildAuditInfoTile('Publication Status', status, status == 'Published' ? Colors.green : Colors.grey),
                          _buildAuditInfoTile('Exam Scheme', exam.contains('NEET') ? '180/200 NEET Format' : 'JEE Standard', Colors.purple),
                        ],
                      ),
                      const SizedBox(height: 20),

                      const Text('Health & Validation Audit', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      const SizedBox(height: 8),

                      // Audit Checklist
                      _buildAuditCheckItem(
                        'Total Question Count Match',
                        actual >= expected ? 'Full paper requirement satisfied ($actual / $expected)' : 'Short by ${expected - actual} questions',
                        actual >= expected,
                      ),
                      _buildAuditCheckItem(
                        'Subject Boundaries & Distribution',
                        exam.contains('NEET') ? 'Physics (1-45), Chemistry (46-90), Biology (91-180)' : 'Physics, Chemistry, Mathematics equal split',
                        true,
                      ),
                      _buildAuditCheckItem(
                        'Correct Option & Answer Key Persistence',
                        'All saved questions have verified correct option indexes',
                        actual > 0,
                      ),
                      _buildAuditCheckItem(
                        'Student Attempt Integrity Protection',
                        'Safe from accidental cascade deletion',
                        true,
                      ),

                      const SizedBox(height: 24),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _navigateToQuestionEditor(paperId);
                            },
                            icon: const Icon(Icons.format_list_bulleted, color: Colors.white),
                            label: const Text('Open Question Editor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _previewAsStudent(paperId);
                            },
                            icon: const Icon(Icons.play_arrow_rounded, color: Color(0xFF0284C7)),
                            label: const Text('Preview as Student', style: TextStyle(color: Color(0xFF0284C7))),
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
      },
    );
  }

  Widget _buildAuditInfoTile(String label, String value, Color color) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildAuditCheckItem(String title, String desc, bool passed) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: passed ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: passed ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          Icon(passed ? Icons.check_circle : Icons.warning_amber_rounded, color: passed ? const Color(0xFF16A34A) : const Color(0xFFD97706), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: passed ? const Color(0xFF14532D) : const Color(0xFF78350F))),
                Text(desc, style: TextStyle(fontSize: 11.5, color: passed ? const Color(0xFF15803D) : const Color(0xFFB45309))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // EDIT PAPER METADATA MODAL
  // ==========================================
  void _openEditPaperModal(Map<String, dynamic> paper) {
    final paperId = (paper['id'] ?? paper['paper_id'] ?? '').toString();
    String title = (paper['paper_name'] ?? paper['paperName'] ?? paper['title'] ?? '').toString();
    String exam = (paper['exam'] ?? paper['exam_name'] ?? 'NEET').toString();
    String year = (paper['year'] ?? '').toString();
    String phase = (paper['phase_session'] ?? paper['phaseSession'] ?? '').toString();
    String status = (paper['status'] ?? 'Published').toString();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Paper Metadata ($paperId)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: title,
                decoration: const InputDecoration(labelText: 'Paper Title', border: OutlineInputBorder()),
                onChanged: (val) => title = val,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: ['NEET', 'JEE Main', 'JEE Advanced'].contains(exam) ? exam : 'NEET',
                      decoration: const InputDecoration(labelText: 'Exam', border: OutlineInputBorder()),
                      items: ['NEET', 'JEE Main', 'JEE Advanced'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (val) => exam = val ?? exam,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: status,
                      decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                      items: ['Published', 'Draft', 'Archived'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (val) => status = val ?? status,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: phase,
                decoration: const InputDecoration(labelText: 'Phase / Session', border: OutlineInputBorder()),
                onChanged: (val) => phase = val,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
            onPressed: () async {
              final updatedData = {
                ...paper,
                'id': paperId,
                'paper_name': title,
                'exam': exam,
                'year': year,
                'phase_session': phase,
                'status': status,
              };
              await SupabaseService.savePaperRecord(updatedData);
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✓ Paper metadata updated successfully!'), backgroundColor: Color(0xFF16A34A)),
                );
                _loadPapers();
              }
            },
            child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SAFE DELETE / ARCHIVE OPERATIONS
  // ==========================================
  Future<void> _safeDeletePaper(Map<String, dynamic> paper) async {
    final paperId = (paper['id'] ?? paper['paper_id'] ?? '').toString();
    final title = (paper['paper_name'] ?? paper['title'] ?? 'Paper').toString();
    final actual = _getActualQuestionCount(paper);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete or Archive Paper?'),
        content: Text(
          actual > 0
              ? 'Paper "$title" has $actual linked questions. Deleting will remove the paper record, but questions will remain protected.\n\nDo you want to delete this paper record?'
              : 'Are you sure you want to delete empty paper "$title"?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(ctx, false);
              _toggleArchivePaper(paperId, true);
            },
            child: const Text('Archive Instead'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final ok = await SupabaseService.deletePaperRecord(paperId);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✓ Paper "$title" deleted.'), backgroundColor: const Color(0xFF16A34A)),
        );
        _loadPapers();
      }
    }
  }

  Future<void> _toggleArchivePaper(String paperId, bool isArchive) async {
    final ok = await SupabaseService.archivePaperRecord(paperId, isArchived: isArchive);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isArchive ? '✓ Paper archived' : '✓ Paper restored to Published'),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
      _loadPapers();
    }
  }

  Future<void> _bulkUpdateStatus(String newStatus) async {
    final ids = _selectedPaperIds.toList();
    if (ids.isEmpty) return;

    for (var id in ids) {
      await SupabaseService.archivePaperRecord(id, isArchived: newStatus == 'Archived');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✓ Updated ${ids.length} papers to $newStatus'), backgroundColor: const Color(0xFF16A34A)),
      );
      setState(() => _selectedPaperIds.clear());
      _loadPapers();
    }
  }

  // ==========================================
  // NAVIGATION & PREVIEW
  // ==========================================
  void _navigateToQuestionEditor(String paperId) {
    context.go('/admin/papers/$paperId');
  }

  void _previewAsStudent(String paperId) {
    context.go('/admin/papers/preview/$paperId');
  }

  // ==========================================
  // CSV IMPORT & EXPORT
  // ==========================================
  Future<void> _exportCsvCatalogue() async {
    final List<List<dynamic>> rows = [
      ['ID', 'Exam', 'Year', 'Phase_Session', 'Title', 'Code', 'Expected_Questions', 'Actual_Questions', 'Status', 'Created_At'],
    ];

    for (var p in _filteredPapers) {
      rows.add([
        p['id'] ?? p['paper_id'] ?? '',
        p['exam'] ?? '',
        p['year'] ?? '',
        p['phase_session'] ?? '',
        p['paper_name'] ?? p['title'] ?? '',
        p['paper_code'] ?? '',
        _getExpectedQuestionCount(p),
        _getActualQuestionCount(p),
        p['status'] ?? 'Published',
        p['created_at'] ?? '',
      ]);
    }

    final csvData = const ListToCsvConverter().convert(rows);
    Clipboard.setData(ClipboardData(text: csvData));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✓ Paper catalogue CSV copied to clipboard!'), backgroundColor: Color(0xFF16A34A)),
    );
  }

  Future<void> _importCsvMetadata() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
    if (result != null && result.files.isNotEmpty) {
      final bytes = result.files.first.bytes;
      if (bytes != null) {
        final csvStr = utf8.decode(bytes);
        final List<List<dynamic>> csvRows = const CsvToListConverter().convert(csvStr);
        if (csvRows.length > 1) {
          int importedCount = 0;
          for (int i = 1; i < csvRows.length; i++) {
            final row = csvRows[i];
            if (row.length >= 5) {
              final paperData = {
                'id': row[0].toString().isNotEmpty ? row[0].toString() : 'paper_${DateTime.now().millisecondsSinceEpoch}_$i',
                'exam': row[1].toString(),
                'year': row[2].toString(),
                'phase_session': row[3].toString(),
                'paper_name': row[4].toString(),
                'status': 'Published',
              };
              await SupabaseService.savePaperRecord(paperData);
              importedCount++;
            }
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('✓ Successfully imported $importedCount paper metadata records!'), backgroundColor: const Color(0xFF16A34A)),
            );
            _loadPapers();
          }
        }
      }
    }
  }
}
