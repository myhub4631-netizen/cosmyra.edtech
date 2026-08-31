import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'dart:convert';
import '../../models/models.dart';
import '../../core/services/supabase_service.dart';
import '../../shared/widgets/latex_view.dart';
import 'admin_question_builder_screen.dart';
import 'admin_pdf_import_screen.dart';
import 'admin_bulk_upload_step1_screen.dart';

class AdminQuestionsBankDashboard extends StatefulWidget {
  final UserProfileModel userProfile;
  final VoidCallback? onBack;

  const AdminQuestionsBankDashboard({
    Key? key,
    required this.userProfile,
    this.onBack,
  }) : super(key: key);

  @override
  State<AdminQuestionsBankDashboard> createState() => _AdminQuestionsBankDashboardState();
}

class _AdminQuestionsBankDashboardState extends State<AdminQuestionsBankDashboard> {
  int _activeCategoryTab = 0; // 0 = All Questions, 1 = Custom Practice, 2 = Custom Test, 3 = PYQ Practice, 4 = NTA Questions, 5 = Mock Tests
  String _searchQuery = '';
  String _selectedExam = 'All Exams';
  String _selectedSubject = 'All Subjects';
  String _selectedChapter = 'All Chapters';
  String _selectedType = 'All Types';
  String _selectedStatus = 'All Status';

  bool _isSidebarCollapsed = false;
  bool _isLoading = true;
  int _currentPage = 1;
  int _itemsPerPage = 10;
  final Set<String> _selectedQuestionIds = {};

  List<Map<String, dynamic>> _allQuestionsData = [];

  // Cascading taxonomy mappings
  final Map<String, List<String>> _examSubjectsMap = {
    'NEET 2026': ['Physics', 'Chemistry', 'Biology'],
    'NEET 2025': ['Physics', 'Chemistry', 'Biology'],
    'JEE Main 2026': ['Physics', 'Chemistry', 'Mathematics'],
    'JEE Main 2025': ['Physics', 'Chemistry', 'Mathematics'],
  };

  final Map<String, List<String>> _subjectChaptersMap = {
    'Physics': ['1. Mechanics', '2. Thermodynamics', '3. Oscillations and Waves', '4. Electromagnetism', '5. Modern Physics'],
    'Chemistry': ['1. Some Basic Concepts', '2. Organic Chemistry (GOC)', '3. Inorganic Periodic Table', '4. Physical Equilibrium'],
    'Biology': ['1. Cell: The Unit of Life', '2. Genetics & Evolution', '3. Plant Physiology', '4. Human Physiology'],
    'Mathematics': ['1. Algebra', '2. Trigonometry', '3. Calculus', '4. Coordinate Geometry'],
  };

  @override
  void initState() {
    super.initState();
    _loadSupabaseQuestions();
  }

  Future<void> _loadSupabaseQuestions() async {
    setState(() => _isLoading = true);
    try {
      final dbQuestions = await SupabaseService.fetchAllQuestionsFromSupabase();
      if (mounted) {
        setState(() {
          _allQuestionsData = dbQuestions;
        });
      }
    } catch (e) {
      debugPrint('Error loading questions from Supabase: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Filter Logic
  List<Map<String, dynamic>> get _filteredQuestions {
    final catTabs = ['All', 'Custom Practice', 'Custom Test', 'PYQ Practice', 'NTA Question', 'Mock Test'];
    final activeTabName = catTabs[_activeCategoryTab];

    return _allQuestionsData.where((q) {
      // Category Tab Filter
      if (activeTabName != 'All') {
        final cat = (q['category'] ?? '').toString().toLowerCase();
        final canonCat = (q['canonical_category'] ?? '').toString().toLowerCase();
        final source = (q['sourceType'] ?? q['source_type'] ?? q['source'] ?? '').toString().toLowerCase();
        final searchTarget = activeTabName.toLowerCase();

        bool matches = false;
        if (searchTarget.contains('pyq')) {
          matches = cat.contains('pyq') || canonCat.contains('pyq') || source.contains('pyq');
        } else if (searchTarget.contains('nta')) {
          matches = cat.contains('nta') || canonCat.contains('nta') || source.contains('nta');
        } else if (searchTarget.contains('mock')) {
          matches = cat.contains('mock') || canonCat.contains('mock') || source.contains('mock') || source.contains('series');
        } else if (searchTarget.contains('custom test') || searchTarget.contains('test')) {
          matches = cat.contains('test') || canonCat.contains('test');
        } else {
          // Custom Practice
          matches = cat.contains('practice') || canonCat.contains('practice') || source.contains('practice');
        }

        if (!matches) return false;
      }

      // Subject Filter
      if (_selectedSubject != 'All Subjects' && q['subject'] != _selectedSubject) {
        return false;
      }

      // Chapter Filter
      if (_selectedChapter != 'All Chapters' && !(q['chapter'] ?? '').toString().contains(_selectedChapter)) {
        return false;
      }

      // Question Type Filter
      if (_selectedType != 'All Types' && !(q['type'] ?? '').toString().toLowerCase().contains(_selectedType.toLowerCase())) {
        return false;
      }

      // Status Filter
      if (_selectedStatus != 'All Status' && q['status'] != _selectedStatus) {
        return false;
      }

      // Search Query Filter
      if (_searchQuery.isNotEmpty) {
        final qText = (q['questionText'] ?? '').toString().toLowerCase();
        final qId = (q['id'] ?? '').toString().toLowerCase();
        final qChapter = (q['chapter'] ?? '').toString().toLowerCase();
        final qTopic = (q['topic'] ?? '').toString().toLowerCase();
        final sLower = _searchQuery.toLowerCase();
        if (!qText.contains(sLower) && !qId.contains(sLower) && !qChapter.contains(sLower) && !qTopic.contains(sLower)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // Statistics Computations
  int get _totalQuestionsCount => _allQuestionsData.length;
  int get _activeQuestionsCount => _allQuestionsData.where((q) {
    final s = q['status']?.toString().toLowerCase() ?? '';
    return s == 'active' || s == 'published' || s == 'approved';
  }).length;
  int get _usedInTestsCount => _allQuestionsData.where((q) => (q['usedIn'] as int? ?? 0) > 0).length;
  int get _inactiveQuestionsCount => _allQuestionsData.where((q) {
    final s = q['status']?.toString().toLowerCase() ?? '';
    return s == 'inactive' || s == 'draft';
  }).length;
  int get _totalMarksSum {
    int sum = 0;
    for (var q in _allQuestionsData) {
      final m = q['marks'];
      if (m is int) sum += m;
      else if (m is String) sum += int.tryParse(m) ?? 4;
    }
    return sum;
  }

  // CRUD Actions
  void _openAddQuestionDialog() {
    _showQuestionFormModal(isEdit: false);
  }

  void _openEditQuestionDialog(Map<String, dynamic> question) {
    _showQuestionFormModal(isEdit: true, initialData: question);
  }

  void _showQuestionPreviewModal(Map<String, dynamic> question) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                question['id'] ?? '',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${question['subject']} • ${question['chapter']}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 540,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Question Text:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                const SizedBox(height: 6),
                LaTeXView(
                  text: question['questionText'] ?? '',
                  style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),

                if (question['options'] != null && (question['options'] as List).isNotEmpty) ...[
                  const Text('Options:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  ...(question['options'] as List).map((opt) {
                    final isCorrect = opt.toString() == question['correctAnswer'];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isCorrect ? const Color(0xFFDCFCE7) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isCorrect ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isCorrect ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            size: 16,
                            color: isCorrect ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              opt.toString(),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                                color: isCorrect ? const Color(0xFF16A34A) : const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 14),
                ],

                const Text('Explanation / Solution:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                const SizedBox(height: 4),
                Text(
                  question['explanation'] ?? 'No explanation provided.',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    _buildPreviewChip('Category', question['category'] ?? 'Custom Practice'),
                    const SizedBox(width: 8),
                    _buildPreviewChip('Type', question['type'] ?? 'MCQ'),
                    const SizedBox(width: 8),
                    _buildPreviewChip('Marks', '+${question['marks']} / -${question['negativeMarks'] ?? 1.0}'),
                    const SizedBox(width: 8),
                    _buildPreviewChip('Used In', '${question['usedIn'] ?? 0} Tests'),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
      ),
    );
  }

  void _duplicateQuestion(Map<String, dynamic> question) async {
    final dupId = 'Q_${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
    final dupData = Map<String, dynamic>.from(question);
    dupData['id'] = dupId;
    dupData['questionText'] = '${question['questionText']} (Copy)';

    await SupabaseService.insertQuestionToSupabase(dupData);
    setState(() {
      _allQuestionsData.insert(0, dupData);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Question duplicated successfully as $dupId!')),
    );
  }

  void _deleteQuestion(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete question $id? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () async {
              Navigator.pop(ctx);
              await SupabaseService.deleteQuestionFromSupabase(id);
              setState(() {
                _allQuestionsData.removeWhere((q) => q['id'] == id);
                _selectedQuestionIds.remove(id);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Question $id deleted successfully.')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Bulk Actions
  void _executeBulkAction(String action) async {
    if (_selectedQuestionIds.isEmpty) return;

    final selectedList = _selectedQuestionIds.toList();

    if (action == 'delete') {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirm Bulk Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text('Delete ${selectedList.length} selected questions permanently?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
              onPressed: () async {
                Navigator.pop(ctx);
                await SupabaseService.deleteBulkQuestionsFromSupabase(selectedList);
                setState(() {
                  _allQuestionsData.removeWhere((q) => selectedList.contains(q['id']));
                  _selectedQuestionIds.clear();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${selectedList.length} questions deleted successfully.')),
                );
              },
              child: const Text('Bulk Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else if (action == 'activate' || action == 'deactivate') {
      final targetStatus = action == 'activate' ? 'Active' : 'Inactive';
      await SupabaseService.updateBulkQuestionStatusInSupabase(selectedList, targetStatus);
      setState(() {
        for (var q in _allQuestionsData) {
          if (selectedList.contains(q['id'])) {
            q['status'] = targetStatus;
          }
        }
        _selectedQuestionIds.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${selectedList.length} questions set to $targetStatus.')),
      );
    }
  }

  // Add/Edit Question Modal Form
  void _showQuestionFormModal({required bool isEdit, Map<String, dynamic>? initialData}) {
    final formKey = GlobalKey<FormState>();
    final qTextCtrl = TextEditingController(text: (isEdit && initialData != null) ? (initialData['questionText'] ?? '').toString() : '');
    final qImageCtrl = TextEditingController(text: (isEdit && initialData != null) ? (initialData['questionImage'] ?? '').toString() : '');
    final expCtrl = TextEditingController(text: (isEdit && initialData != null) ? (initialData['explanation'] ?? '').toString() : '');
    final solCtrl = TextEditingController(text: (isEdit && initialData != null) ? (initialData['solution'] ?? '').toString() : '');
    final marksCtrl = TextEditingController(text: (isEdit && initialData != null) ? (initialData['marks'] ?? 4).toString() : '4');
    final negCtrl = TextEditingController(text: (isEdit && initialData != null) ? (initialData['negativeMarks'] ?? 1.0).toString() : '1.0');

    String selSubject = (isEdit && initialData != null) ? (initialData['subject'] ?? 'Physics').toString() : 'Physics';
    String selChapter = (isEdit && initialData != null) ? (initialData['chapter'] ?? '1. Mechanics').toString() : '1. Mechanics';
    String selTopic = (isEdit && initialData != null) ? (initialData['topic'] ?? 'Kinematics').toString() : 'Kinematics';
    String selCategory = (isEdit && initialData != null) ? (initialData['category'] ?? 'Custom Practice').toString() : 'Custom Practice';
    String selType = (isEdit && initialData != null) ? (initialData['type'] ?? 'MCQ').toString() : 'MCQ';
    String selDifficulty = (isEdit && initialData != null) ? (initialData['difficulty'] ?? 'Medium').toString() : 'Medium';
    String selStatus = (isEdit && initialData != null) ? (initialData['status'] ?? 'Active').toString() : 'Active';

    final opts = (isEdit && initialData != null && initialData['options'] is List) ? (initialData['options'] as List) : [];
    final opt1Ctrl = TextEditingController(text: opts.isNotEmpty ? opts[0].toString() : 'Option A');
    final opt2Ctrl = TextEditingController(text: opts.length > 1 ? opts[1].toString() : 'Option B');
    final opt3Ctrl = TextEditingController(text: opts.length > 2 ? opts[2].toString() : 'Option C');
    final opt4Ctrl = TextEditingController(text: opts.length > 3 ? opts[3].toString() : 'Option D');

    int initCorrIdx = 0;
    if (isEdit && initialData != null) {
      if (initialData['correct_option_index'] != null) {
        initCorrIdx = (initialData['correct_option_index'] as num).toInt();
      } else if (initialData['correctOptionIndex'] != null) {
        initCorrIdx = (initialData['correctOptionIndex'] as num).toInt();
      } else {
        final String caStr = (initialData['correct_answer'] ?? initialData['correctAnswer'] ?? initialData['correctText'] ?? '').toString().trim();
        if (caStr.toUpperCase().startsWith('OPTION ')) {
          int n = int.tryParse(caStr.substring(7).trim()) ?? 1;
          initCorrIdx = (n - 1).clamp(0, 3);
        } else if (caStr.length == 1 && RegExp(r'[A-D]', caseSensitive: false).hasMatch(caStr)) {
          initCorrIdx = caStr.toUpperCase().codeUnitAt(0) - 65;
        } else if (caStr.isNotEmpty) {
          int fIdx = [opt1Ctrl.text, opt2Ctrl.text, opt3Ctrl.text, opt4Ctrl.text].indexOf(caStr);
          if (fIdx != -1) initCorrIdx = fIdx;
        }
      }
    }

    List<String> currentOptTexts = [opt1Ctrl.text, opt2Ctrl.text, opt3Ctrl.text, opt4Ctrl.text];
    String selCorrectOpt = (initCorrIdx >= 0 && initCorrIdx < currentOptTexts.length)
        ? currentOptTexts[initCorrIdx]
        : currentOptTexts.first;

    List<String> initAvail = [];
    if (isEdit && initialData != null) {
      if (initialData['available_in'] is List) {
        initAvail = (initialData['available_in'] as List).map((v) => v.toString()).toList();
      } else if (initialData['availableIn'] is List) {
        initAvail = (initialData['availableIn'] as List).map((v) => v.toString()).toList();
      }
    }
    if (initAvail.isEmpty) {
      initAvail = ['custom_practice', 'custom_test', 'pyq_practice', 'nta_questions', 'test_series'];
    }

    bool visCP = initAvail.contains('custom_practice');
    bool visCT = initAvail.contains('custom_test');
    bool visPYQ = initAvail.contains('pyq_practice');
    bool visNTA = initAvail.contains('nta_questions');
    bool visTS = initAvail.contains('test_series');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            isEdit ? 'Edit Question (${initialData?['id']})' : 'Add New Question',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
          ),
          content: SizedBox(
            width: 620,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Subject & Chapter
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selSubject,
                            decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder()),
                            items: ['Physics', 'Chemistry', 'Biology', 'Mathematics'].map((s) {
                              return DropdownMenuItem(value: s, child: Text(s));
                            }).toList(),
                            onChanged: (v) => setDlgState(() => selSubject = v!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _subjectChaptersMap[selSubject]?.contains(selChapter) == true ? selChapter : _subjectChaptersMap[selSubject]?.first,
                            decoration: const InputDecoration(labelText: 'Chapter', border: OutlineInputBorder()),
                            items: (_subjectChaptersMap[selSubject] ?? ['1. General']).map((c) {
                              return DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis));
                            }).toList(),
                            onChanged: (v) => setDlgState(() => selChapter = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Row 2: Category & Question Type
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selCategory,
                            decoration: const InputDecoration(labelText: 'Primary Category', border: OutlineInputBorder()),
                            items: ['Custom Practice', 'Custom Test', 'PYQ Practice', 'NTA Question', 'Mock Test'].map((c) {
                              return DropdownMenuItem(value: c, child: Text(c));
                            }).toList(),
                            onChanged: (v) => setDlgState(() => selCategory = v!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selType,
                            decoration: const InputDecoration(labelText: 'Question Type', border: OutlineInputBorder()),
                            items: ['MCQ', 'Multiple Correct', 'Match', 'Assertion', 'Numerical', 'True/False'].map((t) {
                              return DropdownMenuItem(value: t, child: Text(t));
                            }).toList(),
                            onChanged: (v) => setDlgState(() => selType = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Visibility / Available In Multi-Select Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: (!visCP && !visCT && !visPYQ && !visNTA && !visTS) ? Colors.red : const Color(0xFFCBD5E1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Visibility / Available In * (Select all modules where this question appears)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E293B))),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              FilterChip(
                                label: const Text('Custom Practice', style: TextStyle(fontSize: 11)),
                                selected: visCP,
                                onSelected: (val) => setDlgState(() => visCP = val),
                                selectedColor: const Color(0xFFE0E7FF),
                              ),
                              FilterChip(
                                label: const Text('Custom Test', style: TextStyle(fontSize: 11)),
                                selected: visCT,
                                onSelected: (val) => setDlgState(() => visCT = val),
                                selectedColor: const Color(0xFFE0E7FF),
                              ),
                              FilterChip(
                                label: const Text('PYQ Practice', style: TextStyle(fontSize: 11)),
                                selected: visPYQ,
                                onSelected: (val) => setDlgState(() => visPYQ = val),
                                selectedColor: const Color(0xFFE0E7FF),
                              ),
                              FilterChip(
                                label: const Text('NTA Questions', style: TextStyle(fontSize: 11)),
                                selected: visNTA,
                                onSelected: (val) => setDlgState(() => visNTA = val),
                                selectedColor: const Color(0xFFE0E7FF),
                              ),
                              FilterChip(
                                label: const Text('Test Series', style: TextStyle(fontSize: 11)),
                                selected: visTS,
                                onSelected: (val) => setDlgState(() => visTS = val),
                                selectedColor: const Color(0xFFE0E7FF),
                              ),
                            ],
                          ),
                          if (!visCP && !visCT && !visPYQ && !visNTA && !visTS) ...[
                            const SizedBox(height: 6),
                            const Text('⚠️ Select at least 1 module', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Question Text Input
                    TextFormField(
                      controller: qTextCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: r'Question Text (Supports LaTeX \$...\$)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Please enter question text' : null,
                    ),
                    const SizedBox(height: 14),

                    // Options Inputs
                    const Text('Answer Options:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(child: TextFormField(controller: opt1Ctrl, decoration: const InputDecoration(labelText: 'Option A', isDense: true, border: OutlineInputBorder()))),
                        const SizedBox(width: 8),
                        Expanded(child: TextFormField(controller: opt2Ctrl, decoration: const InputDecoration(labelText: 'Option B', isDense: true, border: OutlineInputBorder()))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: TextFormField(controller: opt3Ctrl, decoration: const InputDecoration(labelText: 'Option C', isDense: true, border: OutlineInputBorder()))),
                        const SizedBox(width: 8),
                        Expanded(child: TextFormField(controller: opt4Ctrl, decoration: const InputDecoration(labelText: 'Option D', isDense: true, border: OutlineInputBorder()))),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Correct Answer & Difficulty
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selCorrectOpt,
                            decoration: const InputDecoration(labelText: 'Correct Option', border: OutlineInputBorder()),
                            items: [opt1Ctrl.text, opt2Ctrl.text, opt3Ctrl.text, opt4Ctrl.text].map((o) {
                              return DropdownMenuItem(value: o, child: Text(o.isEmpty ? 'Option' : o));
                            }).toList(),
                            onChanged: (v) => setDlgState(() => selCorrectOpt = v!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selDifficulty,
                            decoration: const InputDecoration(labelText: 'Difficulty', border: OutlineInputBorder()),
                            items: ['Easy', 'Medium', 'Hard'].map((d) {
                              return DropdownMenuItem(value: d, child: Text(d));
                            }).toList(),
                            onChanged: (v) => setDlgState(() => selDifficulty = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Marks & Status Row
                    Row(
                      children: [
                        Expanded(child: TextFormField(controller: marksCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Marks (+)', border: OutlineInputBorder()))),
                        const SizedBox(width: 12),
                        Expanded(child: TextFormField(controller: negCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Negative Marks (-)', border: OutlineInputBorder()))),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selStatus,
                            decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                            items: ['Active', 'Inactive'].map((s) {
                              return DropdownMenuItem(value: s, child: Text(s));
                            }).toList(),
                            onChanged: (v) => setDlgState(() => selStatus = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Explanation / Solution Input
                    TextFormField(
                      controller: expCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Explanation / Solution Details',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
              onPressed: () async {
                final List<String> availableInSel = [
                  if (visCP) 'custom_practice',
                  if (visCT) 'custom_test',
                  if (visPYQ) 'pyq_practice',
                  if (visNTA) 'nta_questions',
                  if (visTS) 'test_series',
                ];

                if (availableInSel.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select at least 1 "Visibility / Available In" option.'), backgroundColor: Colors.red),
                  );
                  return;
                }

                if (formKey.currentState!.validate()) {
                  Navigator.pop(ctx);
                  final List<String> formOpts = [opt1Ctrl.text, opt2Ctrl.text, opt3Ctrl.text, opt4Ctrl.text];
                  int cIdx = formOpts.indexOf(selCorrectOpt);
                  if (cIdx == -1) {
                    if (selCorrectOpt == 'Option A' || selCorrectOpt == opt1Ctrl.text) cIdx = 0;
                    else if (selCorrectOpt == 'Option B' || selCorrectOpt == opt2Ctrl.text) cIdx = 1;
                    else if (selCorrectOpt == 'Option C' || selCorrectOpt == opt3Ctrl.text) cIdx = 2;
                    else if (selCorrectOpt == 'Option D' || selCorrectOpt == opt4Ctrl.text) cIdx = 3;
                    else cIdx = 0;
                  }
                  final String corrAnsStr = 'Option ${String.fromCharCode(65 + cIdx)}';

                  final qMap = {
                    'id': isEdit ? initialData!['id'] : 'Q_${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
                    'questionText': qTextCtrl.text,
                    'questionImage': qImageCtrl.text,
                    'subject': selSubject,
                    'chapter': selChapter,
                    'topic': selTopic,
                    'category': selCategory,
                    'available_in': availableInSel,
                    'availableIn': availableInSel,
                    'type': selType,
                    'difficulty': selDifficulty,
                    'status': selStatus,
                    'marks': int.tryParse(marksCtrl.text) ?? 4,
                    'negativeMarks': double.tryParse(negCtrl.text) ?? 1.0,
                    'options': formOpts,
                    'correct_option_index': cIdx,
                    'correctOptionIndex': cIdx,
                    'correct_answer': corrAnsStr,
                    'correctAnswer': corrAnsStr,
                    'correctText': formOpts[cIdx],
                    'explanation': expCtrl.text,
                    'usedIn': isEdit ? (initialData!['usedIn'] ?? 0) : 0,
                  };

                if (isEdit) {
                  await SupabaseService.updateQuestionInSupabase(qMap['id'].toString(), qMap);
                  setState(() {
                    final idx = _allQuestionsData.indexWhere((item) => item['id'] == qMap['id']);
                    if (idx != -1) _allQuestionsData[idx] = qMap;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Question updated successfully!')),
                  );
                } else {
                  await SupabaseService.insertQuestionToSupabase(qMap);
                  setState(() {
                    _allQuestionsData.insert(0, qMap);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Question created successfully!')),
                  );
                }
              }
            },
            child: Text(isEdit ? 'Save Changes' : 'Create Question', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. LEFT SIDEBAR NAVIGATION
          _buildSidebar(),

          // 2. MAIN CONTENT AREA
          Expanded(
            child: Column(
              children: [
                // Top App Bar
                _buildTopAppBar(),

                // Scrollable Content Body
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(24.0),
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Page Header Title & Buttons
                              _buildPageHeader(),

                              const SizedBox(height: 20),

                              // 5 Stat Metric Cards Row
                              _buildStatCardsRow(),

                              const SizedBox(height: 24),

                              // Category Sub-Navigation Tabs Bar
                              _buildCategoryTabsBar(),

                              const SizedBox(height: 18),

                              // Filter Toolbar
                              _buildFilterToolbar(),

                              const SizedBox(height: 16),

                              // Bulk Selection Action Bar (Shown when items selected)
                              if (_selectedQuestionIds.isNotEmpty) _buildBulkActionBar(),

                              // Questions Data Table
                              _buildQuestionsDataTable(),

                              const SizedBox(height: 16),

                              // Table Pagination Footer
                              _buildPaginationFooter(),

                              const SizedBox(height: 30),
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

  // ==========================================
  // 1. LEFT SIDEBAR NAVIGATION
  // ==========================================
  Widget _buildSidebar() {
    return Container(
      width: _isSidebarCollapsed ? 70 : 240,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Column(
        children: [
          // Logo Bar
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
                ),
                if (!_isSidebarCollapsed) ...[
                  const SizedBox(width: 12),
                  const Text(
                    'Cosmyra Edu Admin',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Sidebar Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              children: [
                _buildSidebarItem(Icons.dashboard_outlined, 'Dashboard', false, onTap: () => context.go('/admin')),

                const SizedBox(height: 14),
                if (!_isSidebarCollapsed)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: Text('CONTENT MANAGEMENT', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                  ),

                _buildSidebarItem(Icons.assignment_outlined, 'Exams', false, onTap: () => context.go('/admin/exams')),
                _buildSidebarItem(Icons.science_outlined, 'Subjects', false, onTap: () => context.go('/admin/subjects')),
                _buildSidebarItem(Icons.menu_book_outlined, 'Chapters', false, onTap: () => context.go('/admin/chapters')),
                _buildSidebarItem(Icons.grid_view_rounded, 'Topics', false, onTap: () => context.go('/admin/topics')),
                _buildSidebarItem(Icons.help_outline_rounded, 'Questions', true, onTap: () => context.go('/admin/questions')),
                _buildSidebarItem(Icons.description_outlined, 'NTA Mock Papers', false, onTap: () => context.go('/admin/mock-papers')),

                const SizedBox(height: 14),
                if (!_isSidebarCollapsed)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: Text('PRACTICE & TEST', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                  ),

                _buildSidebarItem(Icons.edit_note_rounded, 'Custom Practice', false, onTap: () => context.go('/practice')),
                _buildSidebarItem(Icons.assignment_turned_in_outlined, 'Custom Tests', false, onTap: () => context.go('/mock-tests')),
                _buildSidebarItem(Icons.history_edu_rounded, 'PYQ Practice', false, onTap: () => context.go('/pyq')),
                _buildSidebarItem(Icons.quiz_outlined, 'Mock Tests', false, onTap: () => context.go('/mock-tests')),

                const SizedBox(height: 14),
                if (!_isSidebarCollapsed)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: Text('TEST MANAGEMENT', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                  ),

                _buildSidebarItem(Icons.fact_check_outlined, 'Test Attempts', false, onTap: () => context.go('/admin/test-series')),
                _buildSidebarItem(Icons.analytics_outlined, 'Analytics', false, onTap: () => context.go('/admin/analytics')),
                _buildSidebarItem(Icons.insert_chart_outlined_rounded, 'Reports', false, onTap: () => context.go('/admin/analytics')),

                const SizedBox(height: 14),
                if (!_isSidebarCollapsed)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: Text('USER MANAGEMENT', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                  ),

                _buildSidebarItem(Icons.people_outline, 'Users', false, onTap: () => context.go('/admin/users')),
                _buildSidebarItem(Icons.admin_panel_settings_outlined, 'Roles & Permissions', false),

                const SizedBox(height: 14),
                if (!_isSidebarCollapsed)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: Text('OTHER', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                  ),

                _buildSidebarItem(Icons.settings_outlined, 'Settings', false),
                _buildSidebarItem(Icons.receipt_long_outlined, 'Logs', false),
                _buildSidebarItem(Icons.help_outline, 'Help & Support', false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, bool isSelected, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF3E8FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        leading: Icon(
          icon,
          size: 19,
          color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
        ),
        title: _isSidebarCollapsed
            ? null
            : Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF334155),
                ),
              ),
        onTap: onTap ?? () {},
      ),
    );
  }

  // ==========================================
  // TOP APP BAR
  // ==========================================
  Widget _buildTopAppBar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              _isSidebarCollapsed ? Icons.menu_open_rounded : Icons.menu_rounded,
              color: const Color(0xFF64748B),
              size: 22,
            ),
            onPressed: () {
              setState(() => _isSidebarCollapsed = !_isSidebarCollapsed);
            },
          ),
          Row(
            children: [
              // Notification Bell
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF64748B), size: 22),
                    onPressed: () {},
                  ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        '12',
                        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Admin User Profile Avatar
              Row(
                children: [
                  const CircleAvatar(
                    radius: 17,
                    backgroundColor: Color(0xFFEEF2FF),
                    child: Icon(Icons.person_rounded, color: Color(0xFF4F46E5), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Admin User',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        'Super Admin',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // PAGE HEADER (TITLE & BUTTONS)
  // ==========================================
  Widget _buildPageHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Questions',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Dashboard  >  Questions',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
        Row(
          children: [
            // + Add Question Button
            ElevatedButton.icon(
              onPressed: _openAddQuestionDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                elevation: 2,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
              label: Row(
                children: const [
                  Text('Add Question', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 18),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Import Questions Button
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => AdminPdfImportScreen(
                      userProfile: widget.userProfile,
                      onBack: () {
                        Navigator.pop(ctx);
                        _loadSupabaseQuestions();
                      },
                    ),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.upload_outlined, color: Color(0xFF334155), size: 18),
              label: const Text(
                'Import Questions',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
              ),
            ),
            const SizedBox(width: 12),

            // Bulk Upload (Step 1) Button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => AdminBulkUploadStep1Screen(
                      userProfile: widget.userProfile,
                      onBack: () => Navigator.pop(ctx),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                elevation: 2,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.cloud_upload_outlined, color: Colors.white, size: 18),
              label: const Text(
                'Bulk Upload (Step 1)',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // 5 STAT CARDS ROW
  // ==========================================
  Widget _buildStatCardsRow() {
    final activePct = _totalQuestionsCount > 0 ? ((_activeQuestionsCount / _totalQuestionsCount) * 100).toStringAsFixed(2) : '0.00';
    final usedPct = _totalQuestionsCount > 0 ? ((_usedInTestsCount / _totalQuestionsCount) * 100).toStringAsFixed(2) : '0.00';
    final inactivePct = _totalQuestionsCount > 0 ? ((_inactiveQuestionsCount / _totalQuestionsCount) * 100).toStringAsFixed(2) : '0.00';

    return Row(
      children: [
        Expanded(
          child: _buildMetricStatCard(
            title: 'Total Questions',
            value: _totalQuestionsCount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},'),
            footer: 'All Categories',
            footerColor: const Color(0xFF64748B),
            icon: Icons.help_outline_rounded,
            iconColor: const Color(0xFF7C3AED),
            iconBg: const Color(0xFFF3E8FF),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildMetricStatCard(
            title: 'Active Questions',
            value: _activeQuestionsCount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},'),
            footer: '$activePct% of Total',
            footerColor: const Color(0xFF16A34A),
            icon: Icons.description_outlined,
            iconColor: const Color(0xFF16A34A),
            iconBg: const Color(0xFFDCFCE7),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildMetricStatCard(
            title: 'Used in Tests',
            value: _usedInTestsCount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},'),
            footer: '$usedPct% of Total',
            footerColor: const Color(0xFFEA580C),
            icon: Icons.visibility_outlined,
            iconColor: const Color(0xFFEA580C),
            iconBg: const Color(0xFFFFEDD5),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildMetricStatCard(
            title: 'Inactive Questions',
            value: _inactiveQuestionsCount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},'),
            footer: '$inactivePct% of Total',
            footerColor: const Color(0xFFEF4444),
            icon: Icons.cancel_outlined,
            iconColor: const Color(0xFFEF4444),
            iconBg: const Color(0xFFFEE2E2),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildMetricStatCard(
            title: 'Total Marks',
            value: _totalMarksSum.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},'),
            footer: 'Across All Questions',
            footerColor: const Color(0xFF64748B),
            icon: Icons.local_offer_outlined,
            iconColor: const Color(0xFF2563EB),
            iconBg: const Color(0xFFDBEAFE),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricStatCard({
    required String title,
    required String value,
    required String footer,
    required Color footerColor,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(color: Color(0x04000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Text(
                  footer,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: footerColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // CATEGORY SUB-NAVIGATION TABS BAR
  // ==========================================
  Widget _buildCategoryTabsBar() {
    final tabs = [
      'All Questions',
      'Custom Practice',
      'Custom Test',
      'PYQ Practice',
      'NTA Questions',
      'Mock Tests',
    ];

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final idx = entry.key;
          final label = entry.value;
          final isSel = _activeCategoryTab == idx;

          return InkWell(
            onTap: () => setState(() => _activeCategoryTab = idx),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSel ? const Color(0xFF4F46E5) : Colors.transparent,
                    width: 2.5,
                  ),
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                  color: isSel ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==========================================
  // FILTER TOOLBAR (WITH CASCADING LOGIC)
  // ==========================================
  Widget _buildFilterToolbar() {
    final subjectsForExam = _selectedExam == 'All Exams'
        ? ['All Subjects', 'Physics', 'Chemistry', 'Biology', 'Mathematics']
        : ['All Subjects', ...(_examSubjectsMap[_selectedExam] ?? ['Physics', 'Chemistry', 'Biology'])];

    final chaptersForSubject = _selectedSubject == 'All Subjects'
        ? ['All Chapters', '1. Mechanics', '2. Thermodynamics', '3. Trigonometry']
        : ['All Chapters', ...(_subjectChaptersMap[_selectedSubject] ?? ['1. General'])];

    return Row(
      children: [
        // Search Input Box
        Expanded(
          flex: 3,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: const InputDecoration(
                      hintText: 'Search by question, topic or ID...',
                      hintStyle: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Exam Dropdown
        _buildDropdownFilter('Exam', _selectedExam, ['All Exams', 'NEET 2026', 'NEET 2025', 'JEE Main 2026', 'JEE Main 2025'], (v) {
          setState(() {
            _selectedExam = v!;
            _selectedSubject = 'All Subjects';
            _selectedChapter = 'All Chapters';
          });
        }),
        const SizedBox(width: 10),

        // Subject Dropdown
        _buildDropdownFilter('Subject', _selectedSubject, subjectsForExam, (v) {
          setState(() {
            _selectedSubject = v!;
            _selectedChapter = 'All Chapters';
          });
        }),
        const SizedBox(width: 10),

        // Chapter Dropdown
        _buildDropdownFilter('Chapter', _selectedChapter, chaptersForSubject, (v) {
          setState(() => _selectedChapter = v!);
        }),
        const SizedBox(width: 10),

        // Question Type Dropdown
        _buildDropdownFilter('Question Type', _selectedType, ['All Types', 'MCQ', 'Match', 'Assertion', 'Numerical', 'True/False'], (v) {
          setState(() => _selectedType = v!);
        }),
        const SizedBox(width: 10),

        // Status Dropdown
        _buildDropdownFilter('Status', _selectedStatus, ['All Status', 'Active', 'Inactive'], (v) {
          setState(() => _selectedStatus = v!);
        }),
        const SizedBox(width: 10),

        // Reset Button
        OutlinedButton(
          onPressed: () {
            setState(() {
              _searchQuery = '';
              _selectedExam = 'All Exams';
              _selectedSubject = 'All Subjects';
              _selectedChapter = 'All Chapters';
              _selectedType = 'All Types';
              _selectedStatus = 'All Status';
            });
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFE2E8F0)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Reset', style: TextStyle(fontSize: 12.5, color: Color(0xFF334155), fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 10),

        // Filters Button
        ElevatedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Advanced filters active.')),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEEF2FF),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.tune_rounded, color: Color(0xFF4F46E5), size: 16),
          label: const Text('Filters', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
        ),
      ],
    );
  }

  Widget _buildDropdownFilter(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B), size: 18),
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
          onChanged: onChanged,
          items: items.map((i) {
            return DropdownMenuItem<String>(
              value: i,
              child: Text(i),
            );
          }).toList(),
        ),
      ),
    );
  }

  // Bulk Action Bar
  Widget _buildBulkActionBar() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_selectedQuestionIds.length} questions selected',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF4338CA)),
          ),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _executeBulkAction('activate'),
                style: OutlinedButton.styleFrom(backgroundColor: Colors.white),
                icon: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF16A34A), size: 16),
                label: const Text('Bulk Activate', style: TextStyle(fontSize: 12, color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _executeBulkAction('deactivate'),
                style: OutlinedButton.styleFrom(backgroundColor: Colors.white),
                icon: const Icon(Icons.cancel_outlined, color: Color(0xFFEA580C), size: 16),
                label: const Text('Bulk Deactivate', style: TextStyle(fontSize: 12, color: Color(0xFFEA580C), fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _executeBulkAction('delete'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 16),
                label: const Text('Bulk Delete', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // QUESTIONS DATA TABLE
  // ==========================================
  Widget _buildQuestionsDataTable() {
    final questions = _filteredQuestions;
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final paginatedQuestions = questions.skip(startIndex).take(_itemsPerPage).toList();

    final allPaginatedSelected = paginatedQuestions.isNotEmpty && paginatedQuestions.every((q) => _selectedQuestionIds.contains(q['id']));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x04000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFC)),
          dataRowHeight: 64,
          headingRowHeight: 46,
          horizontalMargin: 16,
          columnSpacing: 18,
          columns: [
            DataColumn(
              label: SizedBox(
                width: 24,
                child: Checkbox(
                  value: allPaginatedSelected,
                  activeColor: const Color(0xFF4F46E5),
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        for (var q in paginatedQuestions) {
                          _selectedQuestionIds.add(q['id']);
                        }
                      } else {
                        for (var q in paginatedQuestions) {
                          _selectedQuestionIds.remove(q['id']);
                        }
                      }
                    });
                  },
                ),
              ),
            ),
            const DataColumn(label: Text('ID', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
            const DataColumn(label: Text('Question', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
            const DataColumn(label: Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
            const DataColumn(label: Text('Subject', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
            const DataColumn(label: Text('Chapter / Topic', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
            const DataColumn(label: Text('Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
            const DataColumn(label: Text('Marks', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
            const DataColumn(label: Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
            const DataColumn(label: Text('Used In', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
            const DataColumn(label: Text('Actions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
          ],
          rows: paginatedQuestions.map((q) {
            final qId = q['id'].toString();
            final isChecked = _selectedQuestionIds.contains(qId);

            final categoryBg = q['category'] == 'Custom Test'
                ? const Color(0xFFDBEAFE)
                : (q['category'] == 'PYQ Practice'
                    ? const Color(0xFFDCFCE7)
                    : (q['category'] == 'NTA Question'
                        ? const Color(0xFFFFEDD5)
                        : (q['category'] == 'Mock Test' ? const Color(0xFFFCE7F3) : const Color(0xFFEEF2FF))));

            final categoryText = q['category'] == 'Custom Test'
                ? const Color(0xFF2563EB)
                : (q['category'] == 'PYQ Practice'
                    ? const Color(0xFF16A34A)
                    : (q['category'] == 'NTA Question'
                        ? const Color(0xFFEA580C)
                        : (q['category'] == 'Mock Test' ? const Color(0xFFDB2777) : const Color(0xFF4F46E5))));

            return DataRow(
              cells: [
                DataCell(
                  Checkbox(
                    value: isChecked,
                    activeColor: const Color(0xFF4F46E5),
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedQuestionIds.add(qId);
                        } else {
                          _selectedQuestionIds.remove(qId);
                        }
                      });
                    },
                  ),
                ),
                DataCell(
                  Text(
                    qId,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 240,
                    child: LaTeXView(
                      text: q['questionText'] ?? '',
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155)),
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: categoryBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      q['category'] ?? 'Custom Practice',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: categoryText,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    q['subject'] ?? 'Physics',
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155)),
                  ),
                ),
                DataCell(
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        q['chapter'] ?? '',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        q['topic'] ?? '',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Text(
                    q['type'] ?? 'MCQ',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
                  ),
                ),
                DataCell(
                  Text(
                    '${q['marks'] ?? 4}',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ),
                DataCell(
                  InkWell(
                    onTap: () async {
                      final bool isCurrActive = q['status'] == 'Active' || q['status'] == 'published' || q['status'] == 'approved';
                      final newStatus = isCurrActive ? 'Inactive' : 'Active';
                      await SupabaseService.updateQuestionInSupabase(q['id'].toString(), {'status': newStatus});
                      setState(() {
                        q['status'] = newStatus;
                      });
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Question status permanently updated to $newStatus.')),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (q['status'] == 'Active' || q['status'] == 'published' || q['status'] == 'approved') ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        (q['status'] == 'Active' || q['status'] == 'published' || q['status'] == 'approved') ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: (q['status'] == 'Active' || q['status'] == 'published' || q['status'] == 'approved') ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    '${q['usedIn'] ?? 0}',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility_outlined, size: 16, color: Color(0xFF2563EB)),
                        onPressed: () => _showQuestionPreviewModal(q),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF7C3AED)),
                        onPressed: () => _openEditQuestionDialog(q),
                      ),
                      IconButton(
                        icon: const Icon(Icons.content_copy_outlined, size: 16, color: Color(0xFF475569)),
                        onPressed: () => _duplicateQuestion(q),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                        onPressed: () => _deleteQuestion(qId),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // ==========================================
  // TABLE PAGINATION FOOTER
  // ==========================================
  Widget _buildPaginationFooter() {
    final totalCount = _filteredQuestions.length;
    final start = totalCount == 0 ? 0 : (_currentPage - 1) * _itemsPerPage + 1;
    final end = (_currentPage * _itemsPerPage) > totalCount ? totalCount : (_currentPage * _itemsPerPage);
    final totalPages = (totalCount / _itemsPerPage).ceil();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Showing $start to $end of ${totalCount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} questions',
          style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
        ),
        Row(
          children: [
            Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _itemsPerPage,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _itemsPerPage = v;
                        _currentPage = 1;
                      });
                    }
                  },
                  items: [10, 25, 50, 100].map((count) {
                    return DropdownMenuItem<int>(
                      value: count,
                      child: Text('$count / page'),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Pagination Buttons
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded, size: 20, color: Color(0xFF94A3B8)),
              onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
            ),
            ...List.generate(totalPages > 3 ? 3 : totalPages, (index) {
              final pNum = index + 1;
              return _buildPageNumBtn(pNum, _currentPage == pNum);
            }),
            if (totalPages > 3) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text('...', style: TextStyle(color: Color(0xFF64748B))),
              ),
              _buildPageNumBtn(totalPages, _currentPage == totalPages),
            ],
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF0F172A)),
              onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPageNumBtn(int pageNum, bool isSelected) {
    return InkWell(
      onTap: () => setState(() => _currentPage = pageNum),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F46E5) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0)),
        ),
        child: Center(
          child: Text(
            '$pageNum',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : const Color(0xFF334155),
            ),
          ),
        ),
      ),
    );
  }
}
