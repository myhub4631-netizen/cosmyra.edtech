import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/supabase_service.dart';
import '../../models/models.dart';
import 'admin_bulk_upload_step2_screen.dart';

class AdminBulkUploadStep1Screen extends StatefulWidget {
  final UserProfileModel userProfile;
  final VoidCallback? onBack;
  final Function(Map<String, dynamic> paperDetails)? onProceedToStep2;

  const AdminBulkUploadStep1Screen({
    Key? key,
    required this.userProfile,
    this.onBack,
    this.onProceedToStep2,
  }) : super(key: key);

  @override
  State<AdminBulkUploadStep1Screen> createState() => _AdminBulkUploadStep1ScreenState();
}

class _AdminBulkUploadStep1ScreenState extends State<AdminBulkUploadStep1Screen> {
  // Years range from 2029 down to 1988
  static final List<String> availableYears = List<String>.generate(
    2029 - 1988 + 1,
    (index) => (2029 - index).toString(),
  );

  // Form Controllers
  late TextEditingController _paperNameCtrl;
  late TextEditingController _paperCodeCtrl;
  late TextEditingController _questionCountCtrl;
  late TextEditingController _totalMarksCtrl;
  late TextEditingController _durationCtrl;
  late TextEditingController _negativeMarksCtrl;
  late TextEditingController _positiveMarksCtrl;
  late TextEditingController _instructionsCtrl;

  // Dropdown Values
  String _sourceCategory = 'PYQ';
  String _examName = 'NEET';
  String _year = '2026';
  String _phaseSession = 'Phase 1';
  String _paperType = 'Medical (UG)';
  String _language = 'English';
  String _conductingBody = 'NTA';
  String _negativeMarking = 'Yes';
  String? _paperShift;
  String? _difficultyDistribution;
  String _questionOrdering = 'Subject-wise';

  late TextEditingController _testDateTimeCtrl;
  DateTime? _selectedTestDateTime;

  // Test Series Selection State
  String _testSeriesOption = 'existing'; // 'existing' or 'new'
  String _existingTestSeries = '';
  // Test Series Commercial & Metadata Controllers
  late TextEditingController _newTestSeriesCtrl;
  late TextEditingController _testSeriesDescCtrl;
  late TextEditingController _testSeriesBannerCtrl;
  late TextEditingController _testSeriesPriceCtrl;
  late TextEditingController _testSeriesOrigPriceCtrl;
  late TextEditingController _testSeriesPurchaseLinkCtrl;
  late TextEditingController _testSeriesButtonTextCtrl;
  bool _testSeriesIsFree = false;
  bool _testSeriesShowButton = true;
  List<Map<String, dynamic>> _loadedSeriesObjects = [];
  List<String> _availableTestSeriesList = [];

  // Paper Selection State within Test Series
  String _paperOption = 'new'; // 'existing' or 'new'
  String _existingPaper = '';
  List<String> _availablePapersForSelectedSeries = [];
  List<Map<String, dynamic>> _loadedPapersList = [];

  // Checkboxes for subjects
  bool _subjectPhysics = true;
  bool _subjectChemistry = true;
  bool _subjectBotany = true;
  bool _subjectZoology = true;
  bool _subjectMathematics = false;

  // Visibility / Available In Multi-Select Checkboxes
  bool _visCustomPractice = true;
  bool _visCustomTest = true;
  bool _visPyqPractice = true;
  bool _visNtaQuestions = true;
  bool _visTestSeries = true;

  // Build Paper Method (for Test Series existing content reuse)
  String _buildPaperMethod = 'existing_pyq'; // 'existing_pyq', 'existing_nta', 'question_bank', 'manual'

  // Upload Method Radio
  String _uploadMethod = 'manual'; // 'manual', 'excel', 'paste'

  // Toggle Switch
  bool _showSectionBreaks = true;

  // Option Bulk Preset State
  String _defaultOptionPreset = '1_2_3_4'; // '1_2_3_4', 'A_B_C_D', '(1)_(2)_(3)_(4)', '(A)_(B)_(C)_(D)', 'blank'

  // Active Sidebar Item tracking
  String _activeSidebarItem = 'Question & Paper Bank';

  // Step 1 Question Source Section State (Existing Content Selection)
  String _questionSourceMode = 'new'; // 'new' or 'existing'
  String _selectedSourceType = 'pyq'; // 'pyq', 'nta', 'qbank', 'qset'
  final List<Map<String, dynamic>> _addedSources = [];
  bool _isLoadingStep1Content = false;

  // Search Controllers for Step 1 Existing Content
  final TextEditingController _step1PyqSearchCtrl = TextEditingController();
  final TextEditingController _step1NtaSearchCtrl = TextEditingController();
  final TextEditingController _step1QBankSearchCtrl = TextEditingController();
  final TextEditingController _step1QSetSearchCtrl = TextEditingController();

  String _step1PyqExamFilter = 'NEET';
  String _step1PyqYearFilter = 'All';
  String _step1PyqSubjectFilter = 'All';
  String _step1PyqPaperTypeFilter = 'All';

  String _step1NtaExamFilter = 'NEET';
  String _step1NtaYearFilter = 'All';
  String _step1NtaSessionFilter = 'All';

  String _step1QBankSubjectFilter = 'Physics';
  String _step1QBankChapterFilter = 'All';
  String _step1QBankDifficultyFilter = 'All';
  final Set<String> _selectedQBankIdsInStep1 = {};

  List<Map<String, dynamic>> _step1PyqPapersList = [];
  List<Map<String, dynamic>> _step1NtaPapersList = [];
  List<Map<String, dynamic>> _step1QBankResults = [];
  List<Map<String, dynamic>> _step1QuestionSetsList = [];

  List<Map<String, dynamic>> get _allDeduplicatedQuestions {
    final Map<String, Map<String, dynamic>> uniqueMap = {};
    for (var src in _addedSources) {
      final qList = src['questions'];
      if (qList is List) {
        for (var q in qList) {
          if (q is Map) {
            final qMap = Map<String, dynamic>.from(q as Map);
            final String canonicalId = qMap['id']?.toString() ??
                qMap['question_id']?.toString() ??
                qMap['questionId']?.toString() ??
                'q_${qMap['question_text']?.toString().hashCode}';
            if (!uniqueMap.containsKey(canonicalId)) {
              uniqueMap[canonicalId] = qMap;
            }
          }
        }
      }
    }
    return uniqueMap.values.toList();
  }

  int get _rawTotalSelectedCount {
    int total = 0;
    for (var src in _addedSources) {
      final qList = src['questions'];
      if (qList is List) {
        total += qList.length;
      }
    }
    return total;
  }

  Future<void> _loadStep1PyqPapers() async {
    setState(() => _isLoadingStep1Content = true);
    try {
      final res = await SupabaseService.fetchExistingPYQPapers(
        exam: _step1PyqExamFilter == 'All' ? null : _step1PyqExamFilter,
        year: _step1PyqYearFilter == 'All' ? null : _step1PyqYearFilter,
        subject: _step1PyqSubjectFilter == 'All' ? null : _step1PyqSubjectFilter,
        search: _step1PyqSearchCtrl.text.trim(),
      );
      if (mounted) {
        setState(() {
          _step1PyqPapersList = res;
          _isLoadingStep1Content = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingStep1Content = false);
    }
  }

  Future<void> _loadStep1NtaPapers() async {
    setState(() => _isLoadingStep1Content = true);
    try {
      final res = await SupabaseService.fetchExistingNTAPapers(
        exam: _step1NtaExamFilter == 'All' ? null : _step1NtaExamFilter,
        year: _step1NtaYearFilter == 'All' ? null : _step1NtaYearFilter,
        session: _step1NtaSessionFilter == 'All' ? null : _step1NtaSessionFilter,
        search: _step1NtaSearchCtrl.text.trim(),
      );
      if (mounted) {
        setState(() {
          _step1NtaPapersList = res;
          _isLoadingStep1Content = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingStep1Content = false);
    }
  }

  Future<void> _loadStep1QBankQuestions() async {
    setState(() => _isLoadingStep1Content = true);
    try {
      final res = await SupabaseService.queryQuestionBank(
        exam: _examName,
        subject: _step1QBankSubjectFilter == 'All' ? null : _step1QBankSubjectFilter,
        chapter: _step1QBankChapterFilter == 'All' ? null : _step1QBankChapterFilter,
        difficulty: _step1QBankDifficultyFilter == 'All' ? null : _step1QBankDifficultyFilter,
        search: _step1QBankSearchCtrl.text.trim(),
        limit: 50,
      );
      if (mounted) {
        setState(() {
          _step1QBankResults = (res['items'] as List? ?? []).cast<Map<String, dynamic>>();
          _isLoadingStep1Content = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingStep1Content = false);
    }
  }

  Future<void> _loadStep1QuestionSets() async {
    setState(() => _isLoadingStep1Content = true);
    try {
      final res = await SupabaseService.fetchAllPapersAndTestSeries(exam: _examName);
      if (mounted) {
        setState(() {
          _step1QuestionSetsList = res;
          _isLoadingStep1Content = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingStep1Content = false);
    }
  }

  Future<void> _addPaperSourceToStep1(Map<String, dynamic> paperMap, String sourceType) async {
    final String paperId = paperMap['id']?.toString() ?? '';
    final String pName = paperMap['paper_name'] ?? paperMap['paperName'] ?? 'Selected Paper';

    // Auto-fill Step 1 Paper Details from selected paper metadata!
    setState(() {
      _paperNameCtrl.text = pName;
      if (paperMap['paper_code'] != null || paperMap['code'] != null) {
        _paperCodeCtrl.text = (paperMap['paper_code'] ?? paperMap['code']).toString();
      }
      if (paperMap['exam'] != null) _examName = paperMap['exam'].toString();
      if (paperMap['year'] != null) _year = paperMap['year'].toString();
      if (paperMap['phase_session'] != null) _phaseSession = paperMap['phase_session'].toString();
      if (paperMap['paper_type'] != null) _paperType = paperMap['paper_type'].toString();
      if (paperMap['conducting_body'] != null) _conductingBody = paperMap['conducting_body'].toString();
      if (paperMap['total_marks'] != null) _totalMarksCtrl.text = paperMap['total_marks'].toString();
      if (paperMap['question_count'] != null) _questionCountCtrl.text = paperMap['question_count'].toString();
      if (paperMap['duration_minutes'] != null) _durationCtrl.text = paperMap['duration_minutes'].toString();
      if (paperMap['instructions'] != null) _instructionsCtrl.text = paperMap['instructions'].toString();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fetching questions for "$pName"...'),
        duration: const Duration(seconds: 1),
      ),
    );

    final questions = await SupabaseService.fetchQuestionsForPaper(paperId, paperName: pName);

    setState(() {
      _addedSources.add({
        'type': sourceType,
        'id': paperId,
        'name': pName,
        'count': questions.length,
        'paperMap': paperMap,
        'questions': questions,
      });
      _questionCountCtrl.text = _allDeduplicatedQuestions.length.toString();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ Added "$pName" (${questions.length} questions) to paper content!'),
        backgroundColor: const Color(0xFF16A34A),
      ),
    );
  }

  void _addSelectedQBankQuestionsToStep1() {
    final selectedQuestions = _step1QBankResults.where((q) {
      final qId = q['id']?.toString() ?? '';
      return _selectedQBankIdsInStep1.contains(qId);
    }).toList();

    if (selectedQuestions.isEmpty) return;

    setState(() {
      _addedSources.add({
        'type': 'Question Bank',
        'id': 'qbank_${DateTime.now().millisecondsSinceEpoch}',
        'name': 'Question Bank (${_step1QBankSubjectFilter} - ${selectedQuestions.length} Qs)',
        'count': selectedQuestions.length,
        'questions': selectedQuestions,
      });
      _selectedQBankIdsInStep1.clear();
      _questionCountCtrl.text = _allDeduplicatedQuestions.length.toString();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ Added ${selectedQuestions.length} Question Bank items to paper content!'),
        backgroundColor: const Color(0xFF16A34A),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _paperNameCtrl = TextEditingController(text: 'NEET 2026 Phase 1');
    _paperCodeCtrl = TextEditingController(text: 'N26P1');
    _questionCountCtrl = TextEditingController(text: '180');
    _totalMarksCtrl = TextEditingController(text: '720');
    _durationCtrl = TextEditingController(text: '180');
    _negativeMarksCtrl = TextEditingController(text: '-1');
    _positiveMarksCtrl = TextEditingController(text: '+4');
    _instructionsCtrl = TextEditingController();
    _newTestSeriesCtrl = TextEditingController();
    _testSeriesDescCtrl = TextEditingController(text: 'Comprehensive mock tests covering full syllabus with step-by-step solutions.');
    _testSeriesBannerCtrl = TextEditingController(text: 'https://images.unsplash.com/photo-1532094349884-543bc11b234d?w=800&auto=format&fit=crop&q=60');
    _testSeriesPriceCtrl = TextEditingController(text: '299');
    _testSeriesOrigPriceCtrl = TextEditingController(text: '999');
    _testSeriesPurchaseLinkCtrl = TextEditingController(text: 'https://neet-jee.in/test-series');
    _testSeriesButtonTextCtrl = TextEditingController(text: 'Enroll Now - ₹299');
    _selectedTestDateTime = DateTime.now();
    _testDateTimeCtrl = TextEditingController(text: DateFormat('yyyy-MM-dd HH:mm').format(_selectedTestDateTime!));
    _loadCustomTestSeries();
  }

  Future<void> _pickTestDateTime() async {
    final now = DateTime.now();
    final defaultDateTime = DateTime(now.year, now.month, now.day, 14, 0);
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedTestDateTime ?? defaultDateTime,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedTestDateTime ?? defaultDateTime),
      );
      final selectedTime = time ?? const TimeOfDay(hour: 14, minute: 0);
      final dt = DateTime(date.year, date.month, date.day, selectedTime.hour, selectedTime.minute);
      setState(() {
        _selectedTestDateTime = dt;
        _testDateTimeCtrl.text = DateFormat('yyyy-MM-dd HH:mm').format(dt);
      });
    }
  }

  Future<void> _loadCustomTestSeries() async {
    try {
      final list = await SupabaseService.fetchAllTestSeries(exam: _examName);
      final papers = await SupabaseService.fetchAllPapersAndTestSeries(exam: _examName);
      if (mounted) {
        setState(() {
          _loadedSeriesObjects = list;
          _loadedPapersList = papers;
          _availableTestSeriesList = list
              .map((e) => (e['title'] ?? e['name'] ?? '').toString().trim())
              .where((t) => t.isNotEmpty)
              .toSet()
              .toList();

          if (_availableTestSeriesList.isNotEmpty) {
            _testSeriesOption = 'existing';
            _existingTestSeries = _availableTestSeriesList.first;
            _onExistingTestSeriesSelected(_existingTestSeries);
          } else {
            _testSeriesOption = 'new';
            _onNewTestSeriesOptionSelected();
          }
        });
      }
    } catch (e) {
      debugPrint('Notice loading test series: $e');
    }
  }

  void _onExamChanged(String newExam) {
    setState(() {
      _examName = newExam;
      _applyExamDefaults(newExam);

      // 1. Reset Test Series selection & clear state
      _testSeriesOption = 'new';
      _existingTestSeries = '';
      _existingPaper = '';
      _availableTestSeriesList.clear();
      _availablePapersForSelectedSeries.clear();
      _loadedSeriesObjects.clear();
      _loadedPapersList.clear();

      // 2. Reset filters for PYQ, NTA, and Question Bank
      _step1PyqExamFilter = newExam;
      _step1NtaExamFilter = newExam;
      _step1QBankSubjectFilter = newExam.contains('JEE') ? 'Physics' : 'Physics';
      _step1QBankChapterFilter = 'All';
      _step1QBankDifficultyFilter = 'All';

      _step1PyqPapersList.clear();
      _step1NtaPapersList.clear();
      _step1QBankResults.clear();
      _step1QuestionSetsList.clear();
      _addedSources.clear();
      _selectedQBankIdsInStep1.clear();

      // 3. Reload Exam-scoped data
      _loadCustomTestSeries();
      if (_uploadMethod == 'pyq') _loadStep1PyqPapers();
      if (_uploadMethod == 'nta') _loadStep1NtaPapers();
      if (_uploadMethod == 'qbank') _loadStep1QBankQuestions();
    });
  }

  void _applyExamDefaults(String exam, {bool preserveMarks = false}) {
    if (exam.contains('JEE')) {
      _conductingBody = 'NTA';
      _paperType = 'Engineering';
      if (!preserveMarks) {
        _questionCountCtrl.text = '90';
        _totalMarksCtrl.text = '300';
        _durationCtrl.text = '180';
        _positiveMarksCtrl.text = '+4';
        _negativeMarksCtrl.text = '-1';
      }
      _subjectPhysics = true;
      _subjectChemistry = true;
      _subjectBotany = false;
      _subjectZoology = false;
    } else {
      _conductingBody = 'NTA';
      _paperType = 'Medical (UG)';
      if (!preserveMarks) {
        _questionCountCtrl.text = '180';
        _totalMarksCtrl.text = '720';
        _durationCtrl.text = '180';
        _positiveMarksCtrl.text = '+4';
        _negativeMarksCtrl.text = '-1';
      }
      _subjectPhysics = true;
      _subjectChemistry = true;
      _subjectBotany = true;
      _subjectZoology = true;
    }
  }

  void _onExistingTestSeriesSelected(String title) {
    setState(() {
      _existingTestSeries = title;
      final found = _loadedSeriesObjects.firstWhere(
        (e) => (e['title'] ?? e['name'] ?? '').toString().trim().toLowerCase() == title.trim().toLowerCase(),
        orElse: () => {},
      );
      if (found.isNotEmpty) {
        if (found['exam'] != null && found['exam'].toString().isNotEmpty) {
          _examName = found['exam'].toString();
        }
        if (found['year'] != null && found['year'].toString().isNotEmpty) {
          _year = found['year'].toString();
        }
        if (found['description'] != null) _testSeriesDescCtrl.text = found['description'].toString();
        if (found['banner_image_url'] != null) _testSeriesBannerCtrl.text = found['banner_image_url'].toString();
        if (found['price'] != null) _testSeriesPriceCtrl.text = found['price'].toString();
        if (found['original_price'] != null) _testSeriesOrigPriceCtrl.text = found['original_price'].toString();
        if (found['purchase_link'] != null) _testSeriesPurchaseLinkCtrl.text = found['purchase_link'].toString();
        if (found['purchase_button_text'] != null) _testSeriesButtonTextCtrl.text = found['purchase_button_text'].toString();
        if (found['is_free'] != null) _testSeriesIsFree = found['is_free'] == true;
        if (found['show_purchase_button'] != null) _testSeriesShowButton = found['show_purchase_button'] != false;

        if (found['question_count'] != null) {
          _questionCountCtrl.text = found['question_count'].toString();
        }
        if (found['duration_minutes'] != null) {
          _durationCtrl.text = found['duration_minutes'].toString();
        }
        if (found['total_marks'] != null) {
          _totalMarksCtrl.text = found['total_marks'].toString();
        } else {
          _totalMarksCtrl.text = _examName.contains('JEE') ? '300' : '720';
        }
        if (found['conducting_body'] != null) {
          _conductingBody = found['conducting_body'].toString();
        } else {
          _conductingBody = 'NTA';
        }

        _applyExamDefaults(_examName, preserveMarks: found['total_marks'] != null);
      }
      _updateAvailablePapersForTestSeries(title);
    });
  }

  void _onNewTestSeriesOptionSelected() {
    setState(() {
      _testSeriesOption = 'new';
      _applyExamDefaults(_examName);
      _paperOption = 'new';
      final pTitle = _newTestSeriesCtrl.text.isNotEmpty
          ? '${_newTestSeriesCtrl.text.trim()} - Paper 1'
          : 'NEET 2026 Phase 1';
      _paperNameCtrl.text = pTitle;
      _paperCodeCtrl.text = 'N26P1';
      _availablePapersForSelectedSeries = [];
    });
  }

  void _updateAvailablePapersForTestSeries(String seriesTitle) {
    final titleLower = seriesTitle.trim().toLowerCase();
    final seriesObj = _loadedSeriesObjects.firstWhere(
      (s) => (s['title'] ?? s['name'] ?? '').toString().trim().toLowerCase() == titleLower,
      orElse: () => {},
    );
    final String seriesId = seriesObj['id']?.toString() ?? '';
    final String seriesPaperId = seriesObj['paper_id']?.toString() ?? '';

    // 1. Extract embedded tests created inside Test Series Manager dialog
    final List<Map<String, dynamic>> embeddedTests = [];
    if (seriesObj['tests'] is List) {
      int testCounter = 1;
      for (var t in (seriesObj['tests'] as List)) {
        if (t is Map) {
          final tMap = Map<String, dynamic>.from(t);
          final tTitle = (tMap['title'] ?? tMap['name'] ?? '').toString().trim();
          if (tTitle.isNotEmpty) {
            embeddedTests.add({
              'id': tMap['id'] ?? tMap['paper_id'] ?? 'test_${DateTime.now().millisecondsSinceEpoch}',
              'paper_name': tTitle,
              'paperName': tTitle,
              'paper_code': tMap['code'] ?? 'P$testCounter',
              'question_count': tMap['questions'] ?? tMap['question_count'] ?? 180,
              'total_marks': tMap['marks'] ?? tMap['total_marks'] ?? 720,
              'duration_minutes': tMap['duration'] ?? tMap['duration_minutes'] ?? 180,
              'exam': seriesObj['exam'] ?? _examName,
              'year': seriesObj['year'] ?? _year,
              'test_series_title': seriesTitle,
              'test_series_id': seriesId,
              'is_embedded': true,
            });
            testCounter++;
          }
        }
      }
    }

    // 2. Extract matched papers from papers database table
    final matched = _loadedPapersList.where((p) {
      final pTsTitle = (p['test_series_title'] ?? p['existing_test_series'] ?? p['new_test_series_name'] ?? '').toString().trim().toLowerCase();
      final pTsId = (p['test_series_id'] ?? '').toString().trim();
      final pId = (p['id'] ?? '').toString().trim();

      if (pTsTitle.isNotEmpty && pTsTitle == titleLower) return true;
      if (seriesId.isNotEmpty && pTsId == seriesId) return true;
      if (seriesPaperId.isNotEmpty && pId == seriesPaperId) return true;
      return false;
    }).toList();

    // 3. Combine both sources safely
    final Map<String, Map<String, dynamic>> combinedMap = {};
    for (var et in embeddedTests) {
      final key = (et['paper_name'] ?? '').toString().trim().toLowerCase();
      if (key.isNotEmpty) combinedMap[key] = et;
    }
    for (var mp in matched) {
      final key = (mp['paper_name'] ?? mp['paperName'] ?? '').toString().trim().toLowerCase();
      if (key.isNotEmpty) {
        if (combinedMap.containsKey(key)) {
          combinedMap[key] = {...combinedMap[key]!, ...mp};
        } else {
          combinedMap[key] = mp;
        }
      }
    }

    final allCombined = combinedMap.values.toList();
    final titles = allCombined
        .map((p) => (p['paper_name'] ?? p['paperName'] ?? '').toString().trim())
        .where((t) => t.isNotEmpty)
        .toList();

    setState(() {
      _availablePapersForSelectedSeries = titles;
      if (_paperOption == 'existing' && titles.isNotEmpty) {
        if (_existingPaper.isEmpty || !titles.contains(_existingPaper)) {
          _existingPaper = titles.first;
        }
        _onExistingPaperSelected(_existingPaper, customPaperMapList: allCombined);
      } else {
        _paperOption = 'new';
        _existingPaper = '';
        final int nextPaperNum = titles.length + 1;
        _paperNameCtrl.text = seriesTitle.isNotEmpty ? '$seriesTitle - Test #$nextPaperNum' : 'NEET 2026 Phase 1';
        _paperCodeCtrl.text = 'P$nextPaperNum';
      }
    });
  }

  List<int> _selectedPaperPendingQNumbers = [];
  int _selectedPaperSavedCount = 0;
  bool _isLoadingPaperPendingStatus = false;

  Future<void> _checkPaperPendingQuestions(String paperId, int totalQCount, {String? paperName}) async {
    if (paperId.isEmpty && (paperName == null || paperName.isEmpty)) return;
    setState(() => _isLoadingPaperPendingStatus = true);
    try {
      final savedQuestions = await SupabaseService.fetchQuestionsForPaper(
        paperId,
        paperName: paperName ?? _existingPaper,
      );
      final Set<int> savedNumSet = {};
      for (var sq in savedQuestions) {
        final rawNum = sq['question_number'] ?? sq['questionNumber'];
        final int? parsedNum = rawNum is num ? rawNum.toInt() : int.tryParse(rawNum?.toString() ?? '');
        if (parsedNum != null && parsedNum > 0) {
          savedNumSet.add(parsedNum);
        }
      }

      final List<int> pending = [];
      for (int i = 1; i <= totalQCount; i++) {
        if (!savedNumSet.contains(i)) {
          pending.add(i);
        }
      }

      if (mounted) {
        setState(() {
          _selectedPaperSavedCount = savedNumSet.length;
          _selectedPaperPendingQNumbers = pending;
          _isLoadingPaperPendingStatus = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingPaperPendingStatus = false);
    }
  }

  void _onExistingPaperSelected(String paperTitle, {List<Map<String, dynamic>>? customPaperMapList}) {
    setState(() {
      _existingPaper = paperTitle;
      final targetTitleLower = paperTitle.trim().toLowerCase();

      Map<String, dynamic> foundPaper = {};
      if (customPaperMapList != null && customPaperMapList.isNotEmpty) {
        foundPaper = customPaperMapList.firstWhere(
          (p) => (p['paper_name'] ?? p['paperName'] ?? '').toString().trim().toLowerCase() == targetTitleLower,
          orElse: () => {},
        );
      }

      if (foundPaper.isEmpty) {
        foundPaper = _loadedPapersList.firstWhere(
          (p) => (p['paper_name'] ?? p['paperName'] ?? '').toString().trim().toLowerCase() == targetTitleLower,
          orElse: () => {},
        );
      }

      if (foundPaper.isEmpty && _existingTestSeries.isNotEmpty) {
        final seriesObj = _loadedSeriesObjects.firstWhere(
          (s) => (s['title'] ?? s['name'] ?? '').toString().trim().toLowerCase() == _existingTestSeries.trim().toLowerCase(),
          orElse: () => {},
        );
        if (seriesObj['tests'] is List) {
          for (var t in (seriesObj['tests'] as List)) {
            if (t is Map) {
              final tMap = Map<String, dynamic>.from(t);
              final tTitle = (tMap['title'] ?? tMap['name'] ?? '').toString().trim();
              if (tTitle.toLowerCase() == targetTitleLower) {
                foundPaper = {
                  'id': tMap['id'] ?? tMap['paper_id'] ?? 'test_${DateTime.now().millisecondsSinceEpoch}',
                  'paper_name': tTitle,
                  'paperName': tTitle,
                  'question_count': tMap['questions'] ?? tMap['question_count'] ?? 180,
                  'total_marks': tMap['marks'] ?? tMap['total_marks'] ?? 720,
                  'duration_minutes': tMap['duration'] ?? tMap['duration_minutes'] ?? 180,
                  'exam': seriesObj['exam'] ?? _examName,
                  'year': seriesObj['year'] ?? _year,
                };
                break;
              }
            }
          }
        }
      }

      if (foundPaper.isNotEmpty) {
        _paperNameCtrl.text = foundPaper['paper_name'] ?? foundPaper['paperName'] ?? paperTitle;
        _paperCodeCtrl.text = foundPaper['paper_code'] ?? foundPaper['paperCode'] ?? 'P1';

        if (foundPaper['exam'] != null && foundPaper['exam'].toString().isNotEmpty) {
          _examName = foundPaper['exam'].toString();
        }
        if (foundPaper['year'] != null && foundPaper['year'].toString().isNotEmpty) {
          _year = foundPaper['year'].toString();
        }
        if (foundPaper['phase_session'] != null || foundPaper['phaseSession'] != null) {
          _phaseSession = (foundPaper['phase_session'] ?? foundPaper['phaseSession']).toString();
        }
        if (foundPaper['paper_type'] != null || foundPaper['paperType'] != null) {
          _paperType = (foundPaper['paper_type'] ?? foundPaper['paperType']).toString();
        }
        if (foundPaper['language'] != null) {
          _language = foundPaper['language'].toString();
        }
        if (foundPaper['conducting_body'] != null || foundPaper['conductingBody'] != null) {
          _conductingBody = (foundPaper['conducting_body'] ?? foundPaper['conductingBody']).toString();
        }

        if (foundPaper['total_marks'] != null || foundPaper['totalMarks'] != null || foundPaper['marks'] != null) {
          _totalMarksCtrl.text = (foundPaper['total_marks'] ?? foundPaper['totalMarks'] ?? foundPaper['marks']).toString();
        }
        if (foundPaper['question_count'] != null || foundPaper['questionCount'] != null || foundPaper['questions'] != null) {
          _questionCountCtrl.text = (foundPaper['question_count'] ?? foundPaper['questionCount'] ?? foundPaper['questions']).toString();
        }
        if (foundPaper['duration_minutes'] != null || foundPaper['duration'] != null) {
          _durationCtrl.text = (foundPaper['duration_minutes'] ?? foundPaper['duration']).toString();
        }
        if (foundPaper['negative_marking'] != null || foundPaper['negativeMarking'] != null) {
          _negativeMarking = (foundPaper['negative_marking'] ?? foundPaper['negativeMarking']).toString();
        }
        if (foundPaper['negative_marks'] != null || foundPaper['negativeMarks'] != null) {
          _negativeMarksCtrl.text = (foundPaper['negative_marks'] ?? foundPaper['negativeMarks']).toString();
        }
        if (foundPaper['positive_marks'] != null || foundPaper['positiveMarks'] != null) {
          _positiveMarksCtrl.text = (foundPaper['positive_marks'] ?? foundPaper['positiveMarks']).toString();
        }
        if (foundPaper['instructions'] != null) {
          _instructionsCtrl.text = foundPaper['instructions'].toString();
        }
        if (foundPaper['shift'] != null) {
          _paperShift = foundPaper['shift'].toString();
        }

        final dynamic rawSubjects = foundPaper['subjects'] ?? foundPaper['subjectList'];
        if (rawSubjects is List) {
          final subList = rawSubjects.map((s) => s.toString().toLowerCase()).toList();
          _subjectPhysics = subList.contains('physics');
          _subjectChemistry = subList.contains('chemistry');
          _subjectMathematics = subList.contains('mathematics') || subList.contains('maths') || subList.contains('math');
          _subjectBotany = subList.contains('botany') || subList.contains('biology');
          _subjectZoology = subList.contains('zoology') || subList.contains('biology');
        }

        final String paperId = foundPaper['id']?.toString() ?? '';
        final int totalQ = int.tryParse(foundPaper['question_count']?.toString() ?? foundPaper['questions']?.toString() ?? '') ?? 180;
        _checkPaperPendingQuestions(paperId, totalQ, paperName: paperTitle);
      }
    });
  }

  void _onNewPaperOptionSelected() {
    setState(() {
      _paperOption = 'new';
      final int nextNum = _availablePapersForSelectedSeries.length + 1;
      final prefix = _testSeriesOption == 'new'
          ? (_newTestSeriesCtrl.text.isNotEmpty ? _newTestSeriesCtrl.text.trim() : 'Test Series')
          : _existingTestSeries;
      _paperNameCtrl.text = '$prefix - Paper $nextNum';
      _paperCodeCtrl.text = 'P$nextNum';
      _applyExamDefaults(_examName);
    });
  }

  @override
  void dispose() {
    _paperNameCtrl.dispose();
    _paperCodeCtrl.dispose();
    _questionCountCtrl.dispose();
    _totalMarksCtrl.dispose();
    _durationCtrl.dispose();
    _negativeMarksCtrl.dispose();
    _positiveMarksCtrl.dispose();
    _instructionsCtrl.dispose();
    _newTestSeriesCtrl.dispose();
    _testSeriesDescCtrl.dispose();
    _testSeriesBannerCtrl.dispose();
    _priceCtrlDispose();
    super.dispose();
  }

  void _priceCtrlDispose() {
    _testSeriesPriceCtrl.dispose();
    _testSeriesOrigPriceCtrl.dispose();
    _testSeriesPurchaseLinkCtrl.dispose();
    _testSeriesButtonTextCtrl.dispose();
  }

  Future<void> _handleProceed() async {
    final List<String> availableInModules = [
      if (_visCustomPractice) 'custom_practice',
      if (_visCustomTest) 'custom_test',
      if (_visPyqPractice) 'pyq_practice',
      if (_visNtaQuestions) 'nta_questions',
      if (_visTestSeries) 'test_series',
    ];

    if (availableInModules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one "Visibility / Available In" module for the questions.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final String pName = _paperNameCtrl.text.trim().isNotEmpty ? _paperNameCtrl.text.trim() : 'NEET 2026 Phase 1';
    
    // If existing paper was selected, reuse its exact ID so Step 2 loads its existing questions
    String paperId = SupabaseService.toValidUuid('paper_${_examName}_${_year}_${_phaseSession}_$pName');
    if (_sourceCategory == 'Test Series' && _paperOption == 'existing' && _existingPaper.isNotEmpty) {
      Map<String, dynamic> foundExisting = _loadedPapersList.firstWhere(
        (p) => (p['paper_name'] ?? p['paperName'] ?? '').toString().trim().toLowerCase() == _existingPaper.trim().toLowerCase(),
        orElse: () => {},
      );
      if (foundExisting.isEmpty && _existingTestSeries.isNotEmpty) {
        final seriesObj = _loadedSeriesObjects.firstWhere(
          (s) => (s['title'] ?? s['name'] ?? '').toString().trim().toLowerCase() == _existingTestSeries.trim().toLowerCase(),
          orElse: () => {},
        );
        if (seriesObj['tests'] is List) {
          for (var t in (seriesObj['tests'] as List)) {
            if (t is Map) {
              final tMap = Map<String, dynamic>.from(t);
              final tTitle = (tMap['title'] ?? tMap['name'] ?? '').toString().trim();
              if (tTitle.toLowerCase() == _existingPaper.trim().toLowerCase()) {
                foundExisting = tMap;
                break;
              }
            }
          }
        }
      }
      if (foundExisting.isNotEmpty && foundExisting['id'] != null && foundExisting['id'].toString().isNotEmpty) {
        paperId = SupabaseService.toValidUuid(foundExisting['id'].toString());
      }
    }

    final String effectiveTestSeriesTitle = _sourceCategory == 'Test Series'
        ? (_testSeriesOption == 'new' && _newTestSeriesCtrl.text.trim().isNotEmpty
            ? _newTestSeriesCtrl.text.trim()
            : _existingTestSeries)
        : '';

    final now = DateTime.now();
    final defaultDateTime = DateTime(now.year, now.month, now.day, 14, 0);
    final String formattedIsoDateTime = _selectedTestDateTime != null
        ? _selectedTestDateTime!.toIso8601String()
        : defaultDateTime.toIso8601String();

    final Map<String, dynamic> paperDetails = {
      'id': paperId,
      'sourceCategory': _sourceCategory,
      'source_category': _sourceCategory,
      'available_in': availableInModules,
      'availableIn': availableInModules,
      'examName': _examName,
      'exam': _examName,
      'year': _year,
      'phaseSession': _phaseSession,
      'phase_session': _phaseSession,
      'paperType': _paperType,
      'paper_type': _paperType,
      'paperName': pName,
      'paper_name': pName,
      'paperCode': _paperCodeCtrl.text.trim(),
      'paper_code': _paperCodeCtrl.text.trim(),
      'language': _language,
      'conductingBody': _conductingBody,
      'conducting_body': _conductingBody,
      'questionCount': int.tryParse(_questionCountCtrl.text) ?? 180,
      'totalMarks': int.tryParse(_totalMarksCtrl.text) ?? 720,
      'total_marks': double.tryParse(_totalMarksCtrl.text) ?? 720.0,
      'durationMinutes': int.tryParse(_durationCtrl.text) ?? 180,
      'duration': int.tryParse(_durationCtrl.text) ?? 180,
      'test_date_time': formattedIsoDateTime,
      'test_date': formattedIsoDateTime,
      'scheduled_at': formattedIsoDateTime,
      'negativeMarking': _negativeMarking == 'Yes',
      'negativeMarks': double.tryParse(_negativeMarksCtrl.text) ?? -1.0,
      'positiveMarks': double.tryParse(_positiveMarksCtrl.text) ?? 4.0,
      'subjects': [
        if (_subjectPhysics) 'Physics',
        if (_subjectChemistry) 'Chemistry',
        if (_examName.contains('JEE') && _subjectMathematics) 'Mathematics',
        if (!_examName.contains('JEE') && _subjectBotany) 'Botany',
        if (!_examName.contains('JEE') && _subjectZoology) 'Zoology',
      ],
      'paperShift': _paperShift,
      'instructions': _instructionsCtrl.text,
      'uploadMethod': _uploadMethod,
      'difficultyDistribution': _difficultyDistribution,
      'questionOrdering': _questionOrdering,
      'showSectionBreaks': _showSectionBreaks,
      'testSeriesOption': _testSeriesOption,
      'test_series_option': _testSeriesOption,
      'existingTestSeries': _existingTestSeries,
      'existing_test_series': _existingTestSeries,
      'newTestSeriesName': _newTestSeriesCtrl.text.trim(),
      'new_test_series_name': _newTestSeriesCtrl.text.trim(),
      'testSeriesTitle': effectiveTestSeriesTitle,
      'test_series_title': effectiveTestSeriesTitle,
      'paperOption': _paperOption,
      'paper_option': _paperOption,
      'existingPaper': _existingPaper,
      'existing_paper': _existingPaper,
      'is_test_series': _sourceCategory == 'Test Series' || availableInModules.contains('test_series'),
      'defaultOptionPreset': _defaultOptionPreset,
      'default_option_preset': _defaultOptionPreset,
      'buildPaperMethod': _buildPaperMethod,
      'build_paper_method': _buildPaperMethod,
      'questionSourceMode': _questionSourceMode,
      'question_source_mode': _questionSourceMode,
      'preselectedQuestions': _allDeduplicatedQuestions,
      'preselected_questions': _allDeduplicatedQuestions,
      'addedSources': _addedSources,
      'added_sources': _addedSources,
    };

    if (_allDeduplicatedQuestions.isNotEmpty) {
      paperDetails['questionCount'] = _allDeduplicatedQuestions.length;
    }

    // Immediately persist created Test Series so it shows up in Test Series section
    if (_sourceCategory == 'Test Series' && effectiveTestSeriesTitle.isNotEmpty) {
      try {
        await SupabaseService.saveTestSeries({
          'id': SupabaseService.toValidUuid('ts_${_examName}_${_year}_$effectiveTestSeriesTitle'),
          'title': effectiveTestSeriesTitle,
          'name': effectiveTestSeriesTitle,
          'description': _testSeriesDescCtrl.text.trim(),
          'banner_image_url': _testSeriesBannerCtrl.text.trim(),
          'exam': _examName,
          'year': _year,
          'category': 'Full Syllabus',
          'paper_id': paperId,
          'paper_name': pName,
          'is_free': _testSeriesIsFree,
          'price': double.tryParse(_testSeriesPriceCtrl.text) ?? 299.0,
          'original_price': double.tryParse(_testSeriesOrigPriceCtrl.text) ?? 999.0,
          'purchase_link': _testSeriesPurchaseLinkCtrl.text.trim(),
          'purchase_button_text': _testSeriesButtonTextCtrl.text.trim(),
          'show_purchase_button': _testSeriesShowButton,
          'question_count': int.tryParse(_questionCountCtrl.text) ?? 180,
          'total_marks': double.tryParse(_totalMarksCtrl.text) ?? (_examName.contains('JEE') ? 300.0 : 720.0),
          'conducting_body': _conductingBody,
          'duration_minutes': int.tryParse(_durationCtrl.text) ?? 180,
          'difficulty': 'High',
          'status': 'Published',
          'test_date_time': formattedIsoDateTime,
          'scheduled_at': formattedIsoDateTime,
          'tests': [
            {
              'id': paperId,
              'paper_id': paperId,
              'title': pName,
              'questions': int.tryParse(_questionCountCtrl.text) ?? 180,
              'marks': double.tryParse(_totalMarksCtrl.text) ?? (_examName.contains('JEE') ? 300.0 : 720.0),
              'duration': int.tryParse(_durationCtrl.text) ?? 180,
              'type': 'Full',
              'status': 'Published',
              'test_date_time': formattedIsoDateTime,
              'scheduled_at': formattedIsoDateTime,
            }
          ],
          'test_count': 1,
        });
      } catch (e) {
        debugPrint('Notice persisting test series in step 1: $e');
      }
    }

    try {
      await SupabaseService.savePaperRecord(paperDetails);
    } catch (e) {
      debugPrint('Notice saving paper record: $e');
    }

    final bool isExistingContent = _uploadMethod == 'pyq' ||
        _uploadMethod == 'nta' ||
        _uploadMethod == 'qbank' ||
        _uploadMethod == 'combine';

    if (isExistingContent) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Paper "$pName" successfully created and built from existing content!'),
          backgroundColor: const Color(0xFF16A34A),
          duration: const Duration(seconds: 4),
        ),
      );
      if (widget.onBack != null) {
        widget.onBack!();
      } else {
        Navigator.of(context).maybePop();
      }
      return;
    }

    if (widget.onProceedToStep2 != null) {
      widget.onProceedToStep2!(paperDetails);
    } else {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AdminBulkUploadStep2Screen(
            userProfile: widget.userProfile,
            paperRecord: paperDetails,
            paperName: pName,
            totalQuestionsCount: paperDetails['questionCount'] as int? ?? 180,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // 1. Top Navbar Header
          _buildTopHeader(),

          // 2. Main Content Split (Sidebar + Scrollable Form Area)
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Sidebar
                SizedBox(
                  width: 240,
                  child: _buildLeftSidebar(),
                ),

                // Vertical Divider
                Container(width: 1, color: const Color(0xFFE2E8F0)),

                // Right Scrollable Page Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Breadcrumbs
                        _buildBreadcrumbs(),

                        const SizedBox(height: 12),

                        // Title & Subtitle
                        Text(
                          'Upload Questions in Bulk - Step 1 of 2',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Enter paper details and settings. You will add questions in the next step.',
                          style: TextStyle(
                            fontSize: 14,
                            color: const Color(0xFF64748B),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Stepper Bar
                        _buildStepperBar(),

                        const SizedBox(height: 32),

                        // Card 1: Paper / Exam Details
                        _buildPaperExamDetailsCard(),

                        const SizedBox(height: 24),

                        // Card 2: Upload Options
                        _buildUploadOptionsCard(),

                        const SizedBox(height: 24),

                        // Card 3: Other Settings
                        _buildOtherSettingsCard(),

                        const SizedBox(height: 24),

                        // Tip Card
                        _buildTipCard(),

                        const SizedBox(height: 40),
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
  // TOP NAVBAR HEADER WIDGET
  // ==========================================
  Widget _buildTopHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: App Brand Logo & Name
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Cosmyra Edu Admin',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),

          // Right: Notification Bell & Admin Profile
          Row(
            children: [
              // Notification Bell with red badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      color: Color(0xFF475569),
                      size: 22,
                    ),
                  ),
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: const Text(
                        '12',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 20),

              // Admin Avatar & User Info Dropdown
              InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&auto=format&fit=crop&q=80',
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Container(
                            width: 36,
                            height: 36,
                            color: const Color(0xFF6366F1),
                            child: const Icon(Icons.person, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Admin User',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Super Admin',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF64748B),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // LEFT SIDEBAR NAVIGATION WIDGET
  // ==========================================
  Widget _buildLeftSidebar() {
    return Container(
      color: Colors.white,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // Single top item
          _buildSidebarItem('Dashboard', Icons.space_dashboard_outlined),

          const SizedBox(height: 16),
          _buildSidebarSectionHeader('CONTENT MANAGEMENT'),
          _buildSidebarItem('Exams', Icons.assignment_outlined),
          _buildSidebarItem('Subjects', Icons.tune_outlined),
          _buildSidebarItem('Chapters', Icons.menu_book_outlined),
          _buildSidebarItem('Topics', Icons.topic_outlined),
          _buildSidebarItem('Question & Paper Bank', Icons.quiz_outlined, isActive: true),
          _buildSidebarItem('NTA Mock Papers', Icons.collections_bookmark_outlined),

          const SizedBox(height: 16),
          _buildSidebarSectionHeader('PRACTICE & TEST'),
          _buildSidebarItem('Custom Practice', Icons.edit_note_outlined),
          _buildSidebarItem('Custom Tests', Icons.timer_outlined),
          _buildSidebarItem('PYQ Practice', Icons.history_edu_outlined),
          _buildSidebarItem('Test Series', Icons.track_changes_outlined),
          _buildSidebarItem('Mock Tests', Icons.fact_check_outlined),

          const SizedBox(height: 16),
          _buildSidebarSectionHeader('TEST MANAGEMENT'),
          _buildSidebarItem('Test Attempts', Icons.assignment_turned_in_outlined),
          _buildSidebarItem('Analytics', Icons.bar_chart_outlined),

          const SizedBox(height: 16),
          _buildSidebarSectionHeader('USER MANAGEMENT'),
          _buildSidebarItem('Users', Icons.people_outline_rounded),
          _buildSidebarItem('Roles & Permissions', Icons.key_outlined),

          const SizedBox(height: 16),
          _buildSidebarSectionHeader('OTHER'),
          _buildSidebarItem('Settings', Icons.settings_outlined),
          _buildSidebarItem('Logs', Icons.grid_view_outlined),
          _buildSidebarItem('Help & Support', Icons.help_outline_rounded),
        ],
      ),
    );
  }

  Widget _buildSidebarSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF94A3B8),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildSidebarItem(String title, IconData icon, {bool isActive = false}) {
    final bool selected = isActive || (_activeSidebarItem == title);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFEEF2FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        minLeadingWidth: 24,
        leading: Icon(
          icon,
          size: 18,
          color: selected ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            color: selected ? const Color(0xFF4F46E5) : const Color(0xFF334155),
          ),
        ),
        onTap: () {
          setState(() {
            _activeSidebarItem = title;
          });
          if (title == 'Dashboard') {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              context.go('/admin');
            }
          } else if (title == 'Question & Paper Bank') {
            context.go('/admin/questions');
          } else if (title == 'Exams') {
            context.go('/admin/exams');
          } else if (title == 'Subjects') {
            context.go('/admin/subjects');
          } else if (title == 'Chapters') {
            context.go('/admin/chapters');
          } else if (title == 'Topics') {
            context.go('/admin/topics');
          } else if (title == 'NTA Mock Papers') {
            context.go('/admin/mock-papers');
          } else if (title == 'Custom Practice') {
            context.go('/practice');
          } else if (title == 'Custom Tests') {
            context.go('/mock-tests');
          } else if (title == 'PYQ Practice') {
            context.go('/pyq');
          } else if (title == 'Test Series') {
            context.go('/test-series');
          } else if (title == 'Mock Tests') {
            context.go('/mock-tests');
          }
        },
      ),
    );
  }

  // ==========================================
  // BREADCRUMBS WIDGET
  // ==========================================
  Widget _buildBreadcrumbs() {
    return Row(
      children: const [
        Text(
          'Question & Paper Bank',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: 8),
        Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
        SizedBox(width: 8),
        Text(
          'Upload Questions',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF475569),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // STEPPER BAR WIDGET
  // ==========================================
  Widget _buildStepperBar() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Step 1 Circle + Label
            Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4F46E5),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '1',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Paper Details',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4F46E5),
                  ),
                ),
              ],
            ),

            // Dotted Connecting Line
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24, left: 12, right: 12),
                child: CustomPaint(
                  size: const Size(double.infinity, 2),
                  painter: DashedLinePainter(color: const Color(0xFFCBD5E1)),
                ),
              ),
            ),

            // Step 2 Circle + Label
            Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                  ),
                  child: const Center(
                    child: Text(
                      '2',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add Questions',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // CARD 1: PAPER / EXAM DETAILS
  // ==========================================
  Widget _buildPaperExamDetailsCard() {
    return _buildCardContainer(
      title: 'Paper / Exam Details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1 (5 Dropdowns)
          LayoutBuilder(
            builder: (context, constraints) {
              return _buildResponsiveGrid(
                constraints: constraints,
                columns: 5,
                children: [
                  _buildDropdownField(
                    label: 'Source Category *',
                    value: _sourceCategory,
                    items: ['PYQ', 'NTA', 'Questions', 'Test Series'],
                    onChanged: (val) {
                      setState(() {
                        _sourceCategory = val!;
                        if (_sourceCategory == 'Test Series') {
                          if (_availableTestSeriesList.isNotEmpty) {
                            _testSeriesOption = 'existing';
                            _existingTestSeries = _availableTestSeriesList.first;
                            _onExistingTestSeriesSelected(_existingTestSeries);
                          } else {
                            _testSeriesOption = 'new';
                            _onNewTestSeriesOptionSelected();
                          }
                        } else if (_sourceCategory == 'PYQ' && !['NEET', 'JEE Main', 'JEE Advanced', 'AIIMS'].contains(_examName)) {
                          _examName = 'NEET';
                          _applyExamDefaults('NEET');
                        }
                      });
                    },
                  ),
                  _buildDropdownField(
                    label: 'Exam Name *',
                    value: ['NEET', 'JEE Main', 'JEE Advanced', 'AIIMS', 'CUET', 'CBSE 12'].contains(_examName) ? _examName : 'NEET',
                    items: _sourceCategory == 'PYQ'
                        ? ['NEET', 'JEE Main', 'JEE Advanced', 'AIIMS']
                        : ['NEET', 'JEE Main', 'JEE Advanced', 'AIIMS', 'CUET', 'CBSE 12'],
                    onChanged: (val) {
                      if (val != null && val != _examName) {
                        _onExamChanged(val);
                      }
                    },
                  ),
                  _buildDropdownField(
                    label: 'Year *',
                    value: _year,
                    items: availableYears,
                    onChanged: (val) => setState(() => _year = val!),
                  ),
                  _buildDropdownField(
                    label: 'Phase / Session *',
                    value: _phaseSession,
                    items: ['Phase 1', 'Phase 2', 'Session 1', 'Session 2', 'Full Paper'],
                    onChanged: (val) => setState(() => _phaseSession = val!),
                  ),
                  _buildDropdownField(
                    label: 'Paper Type *',
                    value: _paperType,
                    items: ['Medical (UG)', 'Engineering', 'Foundation', 'Board'],
                    onChanged: (val) => setState(() => _paperType = val!),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF4F46E5)),
                    SizedBox(width: 8),
                    Text(
                      'Visibility / Available In * (Select all modules where these questions should appear)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Custom Practice'),
                      selected: _visCustomPractice,
                      onSelected: (val) => setState(() => _visCustomPractice = val),
                      selectedColor: const Color(0xFFE0E7FF),
                      checkmarkColor: const Color(0xFF4F46E5),
                    ),
                    FilterChip(
                      label: const Text('Custom Test'),
                      selected: _visCustomTest,
                      onSelected: (val) => setState(() => _visCustomTest = val),
                      selectedColor: const Color(0xFFE0E7FF),
                      checkmarkColor: const Color(0xFF4F46E5),
                    ),
                    FilterChip(
                      label: const Text('PYQ Practice'),
                      selected: _visPyqPractice,
                      onSelected: (val) => setState(() => _visPyqPractice = val),
                      selectedColor: const Color(0xFFE0E7FF),
                      checkmarkColor: const Color(0xFF4F46E5),
                    ),
                    FilterChip(
                      label: const Text('NTA Questions'),
                      selected: _visNtaQuestions,
                      onSelected: (val) => setState(() => _visNtaQuestions = val),
                      selectedColor: const Color(0xFFE0E7FF),
                      checkmarkColor: const Color(0xFF4F46E5),
                    ),
                    FilterChip(
                      label: const Text('Test Series'),
                      selected: _visTestSeries,
                      onSelected: (val) => setState(() => _visTestSeries = val),
                      selectedColor: const Color(0xFFE0E7FF),
                      checkmarkColor: const Color(0xFF4F46E5),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Conditional Test Series Card Block (When Source Category == 'Test Series')
          if (_sourceCategory == 'Test Series') ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFC7D2FE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Test Series Option *',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF3730A3)),
                      ),
                      if (_availableTestSeriesList.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: const Color(0xFFE0E7FF), borderRadius: BorderRadius.circular(12)),
                          child: Text(
                            '${_availableTestSeriesList.length} Available in DB',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF3730A3)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Row(
                        children: [
                          Radio<String>(
                            value: 'existing',
                            groupValue: _testSeriesOption,
                            activeColor: const Color(0xFF4F46E5),
                            onChanged: (val) {
                              if (_availableTestSeriesList.isNotEmpty) {
                                setState(() {
                                  _testSeriesOption = val!;
                                  if (_existingTestSeries.isEmpty || !_availableTestSeriesList.contains(_existingTestSeries)) {
                                    _existingTestSeries = _availableTestSeriesList.first;
                                  }
                                  _onExistingTestSeriesSelected(_existingTestSeries);
                                });
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('No test series created yet. Please select "Create New Test Series".'),
                                    backgroundColor: Color(0xFF4F46E5),
                                  ),
                                );
                              }
                            },
                          ),
                          Text(
                            'Select Existing Test Series (${_availableTestSeriesList.length})',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E1B4B)),
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      Row(
                        children: [
                          Radio<String>(
                            value: 'new',
                            groupValue: _testSeriesOption,
                            activeColor: const Color(0xFF4F46E5),
                            onChanged: (val) => _onNewTestSeriesOptionSelected(),
                          ),
                          const Text('Create New Test Series', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E1B4B))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_testSeriesOption == 'existing') ...[
                    if (_availableTestSeriesList.isNotEmpty)
                      _buildDropdownField(
                        label: 'Select Test Series *',
                        value: _availableTestSeriesList.contains(_existingTestSeries)
                            ? _existingTestSeries
                            : _availableTestSeriesList.first,
                        items: _availableTestSeriesList,
                        onChanged: (val) => _onExistingTestSeriesSelected(val!),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8)),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No test series found in database. Please click "Create New Test Series" above to create your first series.',
                                style: TextStyle(fontSize: 12, color: Color(0xFF92400E), fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ] else ...[
                    _buildTextField(
                      label: 'New Test Series Title *',
                      controller: _newTestSeriesCtrl,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '✓ Standard specifications (Total Marks: ${_totalMarksCtrl.text}, Total Questions: ${_questionCountCtrl.text}, Conducting Body: $_conductingBody) are automatically filled for $_examName.',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF4F46E5), fontWeight: FontWeight.w600),
                    ),
                  ],

                  const SizedBox(height: 12),
                  // Test Series Description
                  _buildTextField(
                    label: 'Test Series Description / Features',
                    controller: _testSeriesDescCtrl,
                  ),

                  const SizedBox(height: 12),
                  // Banner URL & Free toggle
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildTextField(
                          label: 'Banner Image URL',
                          controller: _testSeriesBannerCtrl,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Checkbox(
                              value: _testSeriesIsFree,
                              activeColor: const Color(0xFF4F46E5),
                              onChanged: (v) => setState(() => _testSeriesIsFree = v ?? false),
                            ),
                            const Text('100% Free Series', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B))),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (!_testSeriesIsFree) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            label: 'Discounted Price (₹)',
                            controller: _testSeriesPriceCtrl,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            label: 'Original Price / MRP (₹)',
                            controller: _testSeriesOrigPriceCtrl,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            label: 'Purchase Link / URL',
                            controller: _testSeriesPurchaseLinkCtrl,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            label: 'Button Text',
                            controller: _testSeriesButtonTextCtrl,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Card 2: Paper in this Test Series (Select Existing or Create New)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Paper in this Test Series *',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                      ),
                      if (_availablePapersForSelectedSeries.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(12)),
                          child: Text(
                            '${_availablePapersForSelectedSeries.length} Existing Papers',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Row(
                        children: [
                          Radio<String>(
                            value: 'existing',
                            groupValue: _paperOption,
                            activeColor: const Color(0xFF16A34A),
                            onChanged: (val) {
                              if (_availablePapersForSelectedSeries.isNotEmpty) {
                                setState(() {
                                  _paperOption = val!;
                                  if (_existingPaper.isEmpty || !_availablePapersForSelectedSeries.contains(_existingPaper)) {
                                    _existingPaper = _availablePapersForSelectedSeries.first;
                                  }
                                  _onExistingPaperSelected(_existingPaper);
                                });
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('No existing papers in this test series yet. Please select "Create New Paper".'),
                                    backgroundColor: Color(0xFF16A34A),
                                  ),
                                );
                              }
                            },
                          ),
                          Text(
                            'Select Existing Paper (${_availablePapersForSelectedSeries.length})',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF14532D)),
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      Row(
                        children: [
                          Radio<String>(
                            value: 'new',
                            groupValue: _paperOption,
                            activeColor: const Color(0xFF16A34A),
                            onChanged: (val) => _onNewPaperOptionSelected(),
                          ),
                          const Text('Create New Paper', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF14532D))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_paperOption == 'existing') ...[
                    if (_availablePapersForSelectedSeries.isNotEmpty) ...[
                      _buildDropdownField(
                        label: 'Select Existing Paper *',
                        value: _availablePapersForSelectedSeries.contains(_existingPaper)
                            ? _existingPaper
                            : _availablePapersForSelectedSeries.first,
                        items: _availablePapersForSelectedSeries,
                        onChanged: (val) => _onExistingPaperSelected(val!),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedPaperPendingQNumbers.isEmpty ? const Color(0xFFDCFCE7) : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _selectedPaperPendingQNumbers.isEmpty ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _selectedPaperPendingQNumbers.isEmpty ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                                  color: _selectedPaperPendingQNumbers.isEmpty ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '✓ Auto-fetched parameters for "$_existingPaper": Total Marks: ${_totalMarksCtrl.text} | Questions: ${_questionCountCtrl.text} | Duration: ${_durationCtrl.text}m | Marking: ${_positiveMarksCtrl.text}/${_negativeMarksCtrl.text}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _selectedPaperPendingQNumbers.isEmpty ? const Color(0xFF15803D) : const Color(0xFF991B1B),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  _isLoadingPaperPendingStatus
                                      ? 'Checking pending question status...'
                                      : (_selectedPaperPendingQNumbers.isEmpty
                                          ? '✓ Upload Status: All ${_questionCountCtrl.text} questions saved!'
                                          : '⚠️ Upload Status: $_selectedPaperSavedCount / ${_questionCountCtrl.text} Saved | Pending (${_selectedPaperPendingQNumbers.length}):'),
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: _selectedPaperPendingQNumbers.isEmpty ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                                  ),
                                ),
                              ],
                            ),
                            if (!_isLoadingPaperPendingStatus && _selectedPaperPendingQNumbers.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: [
                                  ..._selectedPaperPendingQNumbers.take(25).map((qNum) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: const Color(0xFFEF4444)),
                                      ),
                                      child: Text(
                                        'Q$qNum',
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                                      ),
                                    );
                                  }),
                                  if (_selectedPaperPendingQNumbers.length > 25)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 4, top: 2),
                                      child: Text(
                                        '+${_selectedPaperPendingQNumbers.length - 25} more pending...',
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFBFDBFE)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.info_outline_rounded, color: Color(0xFF1D4ED8), size: 16),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Paper structure created. Click "Proceed to Step 2 (Question Upload)" below to bulk upload or paste the questions.',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E40AF)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ] else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No papers recorded under "$_existingTestSeries" yet. Click "Create New Paper" above to add the first paper.',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF92400E), fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ] else ...[
                    _buildTextField(
                      label: 'New Paper Name *',
                      controller: _paperNameCtrl,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome_rounded, color: Color(0xFF2563EB), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '✓ Pre-filled standard defaults for $_examName: Total Marks (${_totalMarksCtrl.text}), Total Questions (${_questionCountCtrl.text}), Conducting Body ($_conductingBody). You can customize them in the grid below.',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Row 2 (5 Fields)
          LayoutBuilder(
            builder: (context, constraints) {
              return _buildResponsiveGrid(
                constraints: constraints,
                columns: 5,
                children: [
                  if (_sourceCategory == 'Test Series')
                    _buildTextField(
                      label: 'Paper Code (Optional)',
                      controller: _paperCodeCtrl,
                    )
                  else
                    _buildTextField(
                      label: 'Paper Name *',
                      controller: _paperNameCtrl,
                    ),
                  if (_sourceCategory != 'Test Series')
                    _buildTextField(
                      label: 'Paper Code (Optional)',
                      controller: _paperCodeCtrl,
                    ),
                  _buildDropdownField(
                    label: 'Language *',
                    value: _language,
                    items: ['English', 'Hindi', 'Bilingual'],
                    onChanged: (val) => setState(() => _language = val!),
                  ),
                  _buildDropdownField(
                    label: 'Conducting Body *',
                    value: _conductingBody,
                    items: ['NTA', 'CBSE', 'IIT', 'AIIMS', 'State Board', 'Cosmyra'],
                    onChanged: (val) => setState(() => _conductingBody = val!),
                  ),
                  _buildTextField(
                    label: 'Question Count *',
                    controller: _questionCountCtrl,
                    keyboardType: TextInputType.number,
                  ),
                  if (_sourceCategory == 'Test Series')
                    _buildDropdownField(
                      label: 'Paper Type *',
                      value: _paperType,
                      items: ['Medical (UG)', 'Engineering', 'Foundation', 'Board'],
                      onChanged: (val) => setState(() => _paperType = val!),
                    ),
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          // Row 3 (6 Fields including Test Date & Time)
          LayoutBuilder(
            builder: (context, constraints) {
              return _buildResponsiveGrid(
                constraints: constraints,
                columns: 6,
                children: [
                  _buildTextField(
                    label: 'Total Marks *',
                    controller: _totalMarksCtrl,
                    keyboardType: TextInputType.number,
                  ),
                  _buildTextField(
                    label: 'Duration (Minutes) *',
                    controller: _durationCtrl,
                    keyboardType: TextInputType.number,
                  ),
                  GestureDetector(
                    onTap: _pickTestDateTime,
                    child: AbsorbPointer(
                      child: _buildTextField(
                        label: 'Test Date & Time *',
                        controller: _testDateTimeCtrl,
                      ),
                    ),
                  ),
                  _buildDropdownField(
                    label: 'Negative Marking *',
                    value: _negativeMarking,
                    items: ['Yes', 'No'],
                    onChanged: (val) => setState(() => _negativeMarking = val!),
                  ),
                  _buildTextField(
                    label: 'Negative Marks',
                    controller: _negativeMarksCtrl,
                  ),
                  _buildTextField(
                    label: 'Positive Marks',
                    controller: _positiveMarksCtrl,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // Row 4: Split Subjects Checkboxes + Paper Shift Dropdown
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Subjects Checkboxes
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Subjects In This Paper (Select all that apply) *'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        _buildCheckboxItem('Physics', _subjectPhysics, (v) => setState(() => _subjectPhysics = v!)),
                        _buildCheckboxItem('Chemistry', _subjectChemistry, (v) => setState(() => _subjectChemistry = v!)),
                        if (_examName.contains('JEE'))
                          _buildCheckboxItem('Mathematics', _subjectMathematics, (v) => setState(() => _subjectMathematics = v!))
                        else ...[
                          _buildCheckboxItem('Botany', _subjectBotany, (v) => setState(() => _subjectBotany = v!)),
                          _buildCheckboxItem('Zoology', _subjectZoology, (v) => setState(() => _subjectZoology = v!)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 24),

              // Right: Paper Shift Dropdown
              Expanded(
                flex: 4,
                child: _buildDropdownField(
                  label: 'Paper Shift (If Applicable)',
                  value: _paperShift,
                  hintText: 'Select Shift',
                  items: ['Select Shift', 'Shift 1 (Morning)', 'Shift 2 (Afternoon)', 'N/A'],
                  onChanged: (val) => setState(() => _paperShift = val == 'Select Shift' ? null : val),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Row 5: Instructions
          _buildFieldLabel('Instructions (Optional)'),
          const SizedBox(height: 8),
          TextField(
            controller: _instructionsCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Enter paper instructions or notes...',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: 24),
          _buildQuickOptionsPresetCard(),
        ],
      ),
    );
  }

  Widget _buildQuickOptionsPresetCard() {
    final List<Map<String, String>> presets = [
      {'key': '1_2_3_4', 'badge': '1, 2, 3, 4', 'label': 'Option A=1, B=2, C=3, D=4'},
      {'key': 'A_B_C_D', 'badge': 'A, B, C, D', 'label': 'Option A=A, B=B, C=C, D=D'},
      {'key': '(1)_(2)_(3)_(4)', 'badge': '(1), (2), (3), (4)', 'label': 'Option A=(1), B=(2), C=(3), D=(4)'},
      {'key': '(A)_(B)_(C)_(D)', 'badge': '(A), (B), (C), (D)', 'label': 'Option A=(A), B=(B), C=(C), D=(D)'},
      {'key': 'blank', 'badge': 'Blank', 'label': 'Manual Custom Text'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.bolt_rounded, size: 20, color: Color(0xFF2563EB)),
              SizedBox(width: 8),
              Text(
                '⚡ 1-Click Bulk Option Set (Fast Question Upload)',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Select a default option preset for all questions in this paper so option text is pre-filled automatically.',
            style: TextStyle(fontSize: 11.5, color: Color(0xFF1E40AF)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: presets.map((p) {
              final isSel = (_defaultOptionPreset == p['key']);
              return ChoiceChip(
                label: Text(
                  '${p['badge']}  (${p['label']})',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                    color: isSel ? const Color(0xFF1E40AF) : const Color(0xFF334155),
                  ),
                ),
                selected: isSel,
                onSelected: (val) {
                  if (val) setState(() => _defaultOptionPreset = p['key']!);
                },
                selectedColor: const Color(0xFFDBEAFE),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isSel ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
                    width: isSel ? 1.5 : 1.0,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // CARD 2: UPLOAD OPTIONS
  // ==========================================
  Widget _buildUploadOptionsCard() {
    final bool isExistingMode = _questionSourceMode == 'existing' ||
        _uploadMethod == 'pyq' ||
        _uploadMethod == 'nta' ||
        _uploadMethod == 'qbank' ||
        _uploadMethod == 'combine';

    return _buildCardContainer(
      title: 'Upload Options',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Upload Method Radio Buttons
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Upload Method / Question Source',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildRadioButton(
                      title: 'Enter Questions Manually',
                      value: 'manual',
                      groupValue: _uploadMethod,
                      onChanged: (val) => setState(() {
                        _uploadMethod = val!;
                        _questionSourceMode = 'new';
                      }),
                    ),
                    const SizedBox(height: 8),
                    _buildRadioButton(
                      title: 'Upload from Excel / CSV',
                      value: 'excel',
                      groupValue: _uploadMethod,
                      onChanged: (val) => setState(() {
                        _uploadMethod = val!;
                        _questionSourceMode = 'new';
                      }),
                    ),
                    const SizedBox(height: 8),
                    _buildRadioButton(
                      title: 'Copy & Paste',
                      value: 'paste',
                      groupValue: _uploadMethod,
                      onChanged: (val) => setState(() {
                        _uploadMethod = val!;
                        _questionSourceMode = 'new';
                      }),
                    ),
                    const SizedBox(height: 8),
                    _buildRadioButton(
                      title: 'Existing PYQ Paper',
                      value: 'pyq',
                      groupValue: _uploadMethod,
                      onChanged: (val) {
                        setState(() {
                          _uploadMethod = val!;
                          _selectedSourceType = 'pyq';
                          _questionSourceMode = 'existing';
                          if (_step1PyqPapersList.isEmpty) _loadStep1PyqPapers();
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildRadioButton(
                      title: 'Existing NTA Question Paper',
                      value: 'nta',
                      groupValue: _uploadMethod,
                      onChanged: (val) {
                        setState(() {
                          _uploadMethod = val!;
                          _selectedSourceType = 'nta';
                          _questionSourceMode = 'existing';
                          if (_step1NtaPapersList.isEmpty) _loadStep1NtaPapers();
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildRadioButton(
                      title: 'Question Bank / Question Set',
                      value: 'qbank',
                      groupValue: _uploadMethod,
                      onChanged: (val) {
                        setState(() {
                          _uploadMethod = val!;
                          _selectedSourceType = 'qbank';
                          _questionSourceMode = 'existing';
                          if (_step1QBankResults.isEmpty) _loadStep1QBankQuestions();
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildRadioButton(
                      title: 'Combine Multiple Sources',
                      value: 'combine',
                      groupValue: _uploadMethod,
                      onChanged: (val) {
                        setState(() {
                          _uploadMethod = val!;
                          _selectedSourceType = 'combine';
                          _questionSourceMode = 'existing';
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 24),

              // Right Column: Recommended Excel Banner Box or Existing Content Info Badge
              Expanded(
                flex: 5,
                child: isExistingMode
                    ? Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFF86EFAC)),
                              ),
                              child: const Icon(
                                Icons.storage_rounded,
                                color: Color(0xFF16A34A),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Reuse Existing Content',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF15803D),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  const Text(
                                    'Reuse existing PYQ, NTA, and Question Bank content without duplicating question records.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE0E7FF), width: 1),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFC7D2FE)),
                              ),
                              child: const Icon(
                                Icons.article_outlined,
                                color: Color(0xFF4F46E5),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Recommended Excel Format',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF4F46E5),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  const Text(
                                    'Download our sample Excel file and fill your questions.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Downloading sample Excel file...'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.download_rounded, size: 16, color: Color(0xFF4F46E5)),
                                    label: const Text(
                                      'Download Sample File',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF4F46E5),
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      side: const BorderSide(color: Color(0xFF4F46E5), width: 1.2),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),

          // If Existing Content Mode is active, render picker & selected sources summary
          if (isExistingMode) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SELECT EXISTING CONTENT',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Select one or multiple existing sources to build this paper.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),

                  // Source Type Chips
                  Row(
                    children: [
                      _buildSourceTypeChip('pyq', 'Existing PYQ Paper', Icons.history_edu_rounded),
                      const SizedBox(width: 8),
                      _buildSourceTypeChip('nta', 'Existing NTA Question Paper', Icons.collections_bookmark_rounded),
                      const SizedBox(width: 8),
                      _buildSourceTypeChip('qbank', 'Question Bank', Icons.storage_rounded),
                      const SizedBox(width: 8),
                      _buildSourceTypeChip('qset', 'Question Set', Icons.auto_stories_rounded),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Active Tab Content View
                  if (_selectedSourceType == 'pyq') _buildStep1PyqPicker(),
                  if (_selectedSourceType == 'nta') _buildStep1NtaPicker(),
                  if (_selectedSourceType == 'qbank') _buildStep1QBankPicker(),
                  if (_selectedSourceType == 'qset') _buildStep1QSetPicker(),

                  const SizedBox(height: 24),

                  // Added Sources Summary List
                  if (_addedSources.isNotEmpty) ...[
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'SELECTED SOURCES & CONTENT SUMMARY',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() => _selectedSourceType = 'pyq');
                          },
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('+ Add Another Source'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF4F46E5),
                            side: const BorderSide(color: Color(0xFF4F46E5)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: List.generate(_addedSources.length, (idx) {
                        final src = _addedSources[idx];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  src['type'].toString().toUpperCase(),
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  src['name'].toString(),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                ),
                              ),
                              Text(
                                '${src['count']} questions',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
                                onPressed: () {
                                  setState(() {
                                    _addedSources.removeAt(idx);
                                    _questionCountCtrl.text = _allDeduplicatedQuestions.length.toString();
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),

                    // Deduplication & Live Summary Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.cleaning_services_rounded, color: Color(0xFF2563EB), size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Question Source Summary',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                              ),
                              const Spacer(),
                              ElevatedButton.icon(
                                onPressed: _showStep1DeduplicatedPreviewDialog,
                                icon: const Icon(Icons.preview_rounded, size: 16),
                                label: const Text('View Selected Questions'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildSummaryStatCard('Total Selected', '$_rawTotalSelectedCount Qs', const Color(0xFF3B82F6)),
                              const SizedBox(width: 12),
                              _buildSummaryStatCard('Duplicates Removed', '${_rawTotalSelectedCount - _allDeduplicatedQuestions.length}', const Color(0xFFEF4444)),
                              const SizedBox(width: 12),
                              _buildSummaryStatCard('Final Unique Questions', '${_allDeduplicatedQuestions.length}', const Color(0xFF16A34A)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // CARD 3: OTHER SETTINGS & ACTIONS
  // ==========================================
  Widget _buildOtherSettingsCard() {
    return _buildCardContainer(
      title: 'Other Settings',
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Col 1: Difficulty Distribution
              Expanded(
                child: _buildDropdownField(
                  label: 'Difficulty Distribution (Optional)',
                  value: _difficultyDistribution,
                  hintText: 'Select Difficulty Distribution',
                  items: [
                    'Select Difficulty Distribution',
                    'Standard (30% Easy, 50% Medium, 20% Hard)',
                    'Balanced (33% Each)',
                    'Custom'
                  ],
                  onChanged: (val) => setState(() => _difficultyDistribution = val == 'Select Difficulty Distribution' ? null : val),
                ),
              ),

              const SizedBox(width: 20),

              // Col 2: Question Ordering
              Expanded(
                child: _buildDropdownField(
                  label: 'Question Ordering',
                  value: _questionOrdering,
                  items: ['Subject-wise', 'Randomized', 'Sequential'],
                  onChanged: (val) => setState(() => _questionOrdering = val!),
                ),
              ),

              const SizedBox(width: 20),

              // Col 3: Show Section / Subject Breaks
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Show Section / Subject Breaks'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Transform.scale(
                          scale: 0.85,
                          child: Switch(
                            value: _showSectionBreaks,
                            activeColor: Colors.white,
                            activeTrackColor: const Color(0xFF4F46E5),
                            inactiveTrackColor: const Color(0xFFCBD5E1),
                            onChanged: (val) => setState(() => _showSectionBreaks = val),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _showSectionBreaks ? 'Yes' : 'No',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Bottom Action Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Cancel Button
              OutlinedButton(
                onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
              ),

              // Right: Action Button
              Builder(
                builder: (context) {
                  final bool isExisting = _uploadMethod == 'pyq' ||
                      _uploadMethod == 'nta' ||
                      _uploadMethod == 'qbank' ||
                      _uploadMethod == 'combine';

                  return ElevatedButton.icon(
                    onPressed: _handleProceed,
                    icon: Text(
                      isExisting ? 'Create & Build Paper From Existing Content' : 'Proceed to Add Questions',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    label: Icon(
                      isExisting ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isExisting ? const Color(0xFF16A34A) : const Color(0xFF4F46E5),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TIP CARD WIDGET
  // ==========================================
  Widget _buildTipCard() {
    final bool isExisting = _uploadMethod == 'pyq' ||
        _uploadMethod == 'nta' ||
        _uploadMethod == 'qbank' ||
        _uploadMethod == 'combine';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isExisting ? const Color(0xFFF0FDF4) : const Color(0xFFF8F7FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isExisting ? const Color(0xFFBBF7D0) : const Color(0xFFE0E7FF)),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isExisting ? const Color(0xFFDCFCE7) : const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: isExisting ? const Color(0xFF86EFAC) : const Color(0xFFC7D2FE)),
            ),
            child: Icon(
              isExisting ? Icons.auto_awesome_rounded : Icons.error_outline_rounded,
              color: isExisting ? const Color(0xFF16A34A) : const Color(0xFF4F46E5),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isExisting
                  ? 'Tip: Existing Content Selected — Clicking "Create & Build Paper From Existing Content" will create your paper directly from existing questions. No Step 2 manual entry required.'
                  : 'Tip: Manual Upload Selected — After clicking "Proceed to Add Questions", you will enter and edit questions in Step 2.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isExisting ? const Color(0xFF15803D) : const Color(0xFF4338CA),
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildSourceTypeChip(String typeKey, String label, IconData icon) {
    final bool selected = _selectedSourceType == typeKey;
    return ChoiceChip(
      avatar: Icon(icon, size: 16, color: selected ? Colors.white : const Color(0xFF4F46E5)),
      label: Text(label),
      selected: selected,
      selectedColor: const Color(0xFF4F46E5),
      labelStyle: TextStyle(
        color: selected ? Colors.white : const Color(0xFF1E293B),
        fontWeight: selected ? FontWeight.bold : FontWeight.w500,
        fontSize: 12,
      ),
      onSelected: (val) {
        if (val) {
          setState(() {
            _selectedSourceType = typeKey;
            if (typeKey == 'pyq' && _step1PyqPapersList.isEmpty) _loadStep1PyqPapers();
            if (typeKey == 'nta' && _step1NtaPapersList.isEmpty) _loadStep1NtaPapers();
            if (typeKey == 'qbank' && _step1QBankResults.isEmpty) _loadStep1QBankQuestions();
            if (typeKey == 'qset' && _step1QuestionSetsList.isEmpty) _loadStep1QuestionSets();
          });
        }
      },
    );
  }

  Widget _buildSummaryStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1PyqPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _step1PyqSearchCtrl,
                onChanged: (_) => _loadStep1PyqPapers(),
                decoration: InputDecoration(
                  hintText: 'Search PYQ papers by name, year, exam...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 140,
              child: _buildDropdownField(
                label: '',
                value: _step1PyqExamFilter,
                items: ['All', 'NEET', 'JEE Main', 'JEE Advanced'],
                onChanged: (val) {
                  _step1PyqExamFilter = val!;
                  _loadStep1PyqPapers();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoadingStep1Content)
          const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
        else if (_step1PyqPapersList.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF64748B)),
                SizedBox(width: 8),
                Text('No PYQ papers found matching filters.', style: TextStyle(color: Color(0xFF64748B))),
              ],
            ),
          )
        else
          SizedBox(
            height: 220,
            child: ListView.builder(
              itemCount: _step1PyqPapersList.length,
              itemBuilder: (ctx, idx) {
                final p = _step1PyqPapersList[idx];
                final pName = p['paper_name'] ?? p['paperName'] ?? 'PYQ Paper';
                final qCount = p['question_count'] ?? p['questions'] ?? 180;
                final yr = p['year'] ?? '';
                final ex = p['exam'] ?? 'NEET';

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.history_edu, color: Color(0xFF4F46E5)),
                    title: Text(pName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text('$ex $yr • $qCount Questions', style: const TextStyle(fontSize: 11)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton(
                          onPressed: () => _showStep1PaperPreviewDialog(p),
                          child: const Text('Preview', style: TextStyle(fontSize: 11)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _addPaperSourceToStep1(p, 'Existing PYQ Paper'),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
                          child: const Text('Select Paper', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildStep1NtaPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _step1NtaSearchCtrl,
                onChanged: (_) => _loadStep1NtaPapers(),
                decoration: InputDecoration(
                  hintText: 'Search NTA question papers...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 140,
              child: _buildDropdownField(
                label: '',
                value: _step1NtaExamFilter,
                items: ['All', 'NEET', 'JEE Main'],
                onChanged: (val) {
                  _step1NtaExamFilter = val!;
                  _loadStep1NtaPapers();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoadingStep1Content)
          const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
        else if (_step1NtaPapersList.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF64748B)),
                SizedBox(width: 8),
                Text('No NTA papers found matching filters.', style: TextStyle(color: Color(0xFF64748B))),
              ],
            ),
          )
        else
          SizedBox(
            height: 220,
            child: ListView.builder(
              itemCount: _step1NtaPapersList.length,
              itemBuilder: (ctx, idx) {
                final p = _step1NtaPapersList[idx];
                final pName = p['paper_name'] ?? p['paperName'] ?? 'NTA Paper';
                final qCount = p['question_count'] ?? p['questions'] ?? 180;
                final yr = p['year'] ?? '';

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.collections_bookmark, color: Color(0xFF059669)),
                    title: Text(pName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text('NTA $yr • $qCount Questions', style: const TextStyle(fontSize: 11)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton(
                          onPressed: () => _showStep1PaperPreviewDialog(p),
                          child: const Text('Preview', style: TextStyle(fontSize: 11)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _addPaperSourceToStep1(p, 'Existing NTA Paper'),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
                          child: const Text('Select Paper', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildStep1QBankPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _step1QBankSearchCtrl,
                onChanged: (_) => _loadStep1QBankQuestions(),
                decoration: InputDecoration(
                  hintText: 'Search questions in Question Bank...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 130,
              child: _buildDropdownField(
                label: '',
                value: _step1QBankSubjectFilter,
                items: ['Physics', 'Chemistry', 'Botany', 'Zoology'],
                onChanged: (val) {
                  _step1QBankSubjectFilter = val!;
                  _loadStep1QBankQuestions();
                },
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 110,
              child: _buildDropdownField(
                label: '',
                value: _step1QBankDifficultyFilter,
                items: ['All', 'easy', 'medium', 'hard'],
                onChanged: (val) {
                  _step1QBankDifficultyFilter = val!;
                  _loadStep1QBankQuestions();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Selected: ${_selectedQBankIdsInStep1.length} / ${_step1QBankResults.length} Results',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF4F46E5)),
            ),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      for (var q in _step1QBankResults) {
                        final id = q['id']?.toString() ?? '';
                        if (id.isNotEmpty) _selectedQBankIdsInStep1.add(id);
                      }
                    });
                  },
                  child: const Text('Select All Results', style: TextStyle(fontSize: 11)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _selectedQBankIdsInStep1.isEmpty ? null : _addSelectedQBankQuestionsToStep1,
                  icon: const Icon(Icons.add, size: 16),
                  label: Text('Add Selected (${_selectedQBankIdsInStep1.length})'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isLoadingStep1Content)
          const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
        else if (_step1QBankResults.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF64748B)),
                SizedBox(width: 8),
                Text('No questions found in Question Bank.', style: TextStyle(color: Color(0xFF64748B))),
              ],
            ),
          )
        else
          SizedBox(
            height: 220,
            child: ListView.builder(
              itemCount: _step1QBankResults.length,
              itemBuilder: (ctx, idx) {
                final q = _step1QBankResults[idx];
                final qId = q['id']?.toString() ?? '';
                final text = q['question_text'] ?? q['questionText'] ?? 'Question Text';
                final isSel = _selectedQBankIdsInStep1.contains(qId);

                return CheckboxListTile(
                  value: isSel,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedQBankIdsInStep1.add(qId);
                      } else {
                        _selectedQBankIdsInStep1.remove(qId);
                      }
                    });
                  },
                  dense: true,
                  title: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  subtitle: Text('${q['subject'] ?? 'Physics'} • ${q['chapter'] ?? 'General'} • Difficulty: ${q['difficulty'] ?? 'Medium'}', style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildStep1QSetPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _step1QSetSearchCtrl,
          onChanged: (_) => _loadStep1QuestionSets(),
          decoration: InputDecoration(
            hintText: 'Search question sets...',
            prefixIcon: const Icon(Icons.search, size: 18),
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 12),
        if (_isLoadingStep1Content)
          const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
        else if (_step1QuestionSetsList.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF64748B)),
                SizedBox(width: 8),
                Text('No Question Sets found.', style: TextStyle(color: Color(0xFF64748B))),
              ],
            ),
          )
        else
          SizedBox(
            height: 220,
            child: ListView.builder(
              itemCount: _step1QuestionSetsList.length,
              itemBuilder: (ctx, idx) {
                final s = _step1QuestionSetsList[idx];
                final sName = s['paper_name'] ?? s['name'] ?? s['title'] ?? 'Question Set';
                final qCount = s['question_count'] ?? s['questions'] ?? 50;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.auto_stories, color: Color(0xFFD97706)),
                    title: Text(sName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text('$qCount Questions', style: const TextStyle(fontSize: 11)),
                    trailing: ElevatedButton(
                      onPressed: () => _addPaperSourceToStep1(s, 'Question Set'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706), foregroundColor: Colors.white),
                      child: const Text('Select Set', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Future<void> _showStep1PaperPreviewDialog(Map<String, dynamic> paperMap) async {
    final String paperId = paperMap['id']?.toString() ?? '';
    final String pName = paperMap['paper_name'] ?? paperMap['paperName'] ?? 'Paper Preview';
    final qList = await SupabaseService.fetchQuestionsForPaper(paperId, paperName: pName);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.preview, color: Color(0xFF4F46E5)),
              const SizedBox(width: 8),
              Expanded(child: Text('Preview: $pName', style: const TextStyle(fontSize: 16))),
            ],
          ),
          content: SizedBox(
            width: 600,
            height: 400,
            child: qList.isEmpty
                ? const Center(child: Text('No question text preview stored for this paper.'))
                : ListView.builder(
                    itemCount: qList.length,
                    itemBuilder: (c, i) {
                      final q = qList[i];
                      return ListTile(
                        leading: CircleAvatar(radius: 12, child: Text('${i + 1}', style: const TextStyle(fontSize: 10))),
                        title: Text(q['question_text'] ?? q['questionText'] ?? 'Q${i + 1}', style: const TextStyle(fontSize: 12)),
                        subtitle: Text('${q['subject'] ?? 'Physics'} • Difficulty: ${q['difficulty'] ?? 'Medium'}', style: const TextStyle(fontSize: 10)),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _addPaperSourceToStep1(paperMap, 'Selected Paper');
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
              child: const Text('Use Entire Paper'),
            ),
          ],
        );
      },
    );
  }

  void _showStep1DeduplicatedPreviewDialog() {
    final deduplicated = _allDeduplicatedQuestions;
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.cleaning_services, color: Color(0xFF16A34A)),
              const SizedBox(width: 8),
              Text('Deduplicated Questions (${deduplicated.length} Unique)', style: const TextStyle(fontSize: 16)),
            ],
          ),
          content: SizedBox(
            width: 700,
            height: 450,
            child: deduplicated.isEmpty
                ? const Center(child: Text('No sources added yet.'))
                : ListView.builder(
                    itemCount: deduplicated.length,
                    itemBuilder: (c, i) {
                      final q = deduplicated[i];
                      return ListTile(
                        leading: CircleAvatar(radius: 12, backgroundColor: const Color(0xFFDCFCE7), child: Text('${i + 1}', style: const TextStyle(fontSize: 10, color: Color(0xFF15803D)))),
                        title: Text(q['question_text'] ?? q['questionText'] ?? 'Q${i + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        subtitle: Text('${q['subject'] ?? 'Physics'} • ${q['chapter'] ?? 'General'} • Canonical ID: ${q['id'] ?? q['question_id'] ?? 'N/A'}', style: const TextStyle(fontSize: 10)),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ],
        );
      },
    );
  }

  // ==========================================
  // HELPER REUSABLE WIDGETS
  // ==========================================
  Widget _buildCardContainer({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.02),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    final bool isRequired = label.contains('*');
    if (!isRequired) {
      return Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF334155),
        ),
      );
    }

    final String textWithoutAsterisk = label.replaceAll('*', '').trim();
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: textWithoutAsterisk,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          const TextSpan(
            text: ' *',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFFEF4444),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label),
        const SizedBox(height: 6),
        SizedBox(
          height: 42,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? hintText,
  }) {
    final String displayValue = value ?? hintText ?? items.first;
    final bool isHintSelected = (value == null && hintText != null) || displayValue == hintText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label),
        const SizedBox(height: 6),
        SizedBox(
          height: 42,
          child: DropdownButtonFormField<String>(
            value: items.contains(displayValue) ? displayValue : items.first,
            menuMaxHeight: 320,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B), size: 20),
            style: TextStyle(
              fontSize: 13,
              color: isHintSelected ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
              fontWeight: isHintSelected ? FontWeight.normal : FontWeight.w500,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
              ),
            ),
            items: items.map((item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: TextStyle(
                    color: (item == hintText) ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxItem(String title, bool value, ValueChanged<bool?> onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: value,
            activeColor: const Color(0xFF4F46E5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildRadioButton({
    required String title,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    final bool selected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Radio<String>(
              value: value,
              groupValue: groupValue,
              activeColor: const Color(0xFF4F46E5),
              onChanged: onChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected ? const Color(0xFF0F172A) : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveGrid({
    required BoxConstraints constraints,
    required int columns,
    required List<Widget> children,
  }) {
    if (constraints.maxWidth > 900) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children.map((w) => Expanded(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: w,
        ))).toList(),
      );
    } else {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: children.map((w) => SizedBox(width: (constraints.maxWidth - 24) / 2, child: w)).toList(),
      );
    }
  }
}

// Custom Painter for Stepper Dashed Line
class DashedLinePainter extends CustomPainter {
  final Color color;
  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    double dashWidth = 4, dashSpace = 4, startX = 0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
