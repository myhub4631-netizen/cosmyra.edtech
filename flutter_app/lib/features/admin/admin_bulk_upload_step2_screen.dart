import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/services/supabase_service.dart';
import '../../shared/widgets/smart_image.dart';
import '../../shared/widgets/solution_video_player.dart';
import '../../shared/widgets/latex_view.dart';
import 'admin_bulk_upload_step1_screen.dart';

class AdminBulkUploadStep2Screen extends StatefulWidget {
  final dynamic userProfile;
  final String paperName;
  final int totalQuestionsCount;
  final Map<String, dynamic>? paperRecord;

  const AdminBulkUploadStep2Screen({
    Key? key,
    this.userProfile,
    this.paperName = 'NEET 2026 Phase 1',
    this.totalQuestionsCount = 200,
    this.paperRecord,
  }) : super(key: key);

  @override
  State<AdminBulkUploadStep2Screen> createState() => _AdminBulkUploadStep2ScreenState();
}

class QuestionItemData {
  String id;
  int number;
  String text;
  String? questionImage;
  List<String> options;
  List<String?> optionImages;
  int correctOptionIndex;
  String explanation;
  String difficulty;
  String positiveMarks;
  String negativeMarks;
  String questionType;
  String chapterTopic;
  String subject;
  String chapter;
  String topic;
  String chapterId;
  String topicId;
  String subjectId;
  String examId;
  bool isMarkedForReview;
  bool isCollapsed;
  bool isSaved;
  bool showLivePreview;
  bool isUploadingQuestionImage;
  List<bool> isUploadingOptionImage;
  String? solutionVideoUrl;
  bool isUploadingSolutionVideo;
  List<String> availableIn;

  String get uniqueId => id.isNotEmpty ? id : 'temp_q_$number';

  QuestionItemData({
    this.id = '',
    required this.number,
    this.text = '',
    this.questionImage,
    List<String>? options,
    List<String?>? optionImages,
    this.correctOptionIndex = -1,
    this.explanation = '',
    this.difficulty = 'Medium',
    this.positiveMarks = '4',
    this.negativeMarks = '-1',
    this.questionType = 'MCQ (Single Correct)',
    this.chapterTopic = '',
    this.subject = 'Physics',
    this.chapter = '',
    this.topic = '',
    this.chapterId = '',
    this.topicId = '',
    this.subjectId = '',
    this.examId = '',
    this.isMarkedForReview = false,
    this.isCollapsed = false,
    this.isSaved = false,
    this.showLivePreview = false,
    this.isUploadingQuestionImage = false,
    List<bool>? isUploadingOptionImage,
    this.solutionVideoUrl,
    this.isUploadingSolutionVideo = false,
    List<String>? availableIn,
  })  : options = options != null ? List<String>.from(options) : ['', '', '', ''],
        optionImages = optionImages != null ? List<String?>.from(optionImages) : [null, null, null, null],
        isUploadingOptionImage = isUploadingOptionImage != null ? List<bool>.from(isUploadingOptionImage) : [false, false, false, false],
        availableIn = availableIn != null ? List<String>.from(availableIn) : [];
}

class _AdminBulkUploadStep2ScreenState extends State<AdminBulkUploadStep2Screen> {
  int _currentPageIndex = 1;
  int _itemsPerPage = 10;
  int _jumpToQuestionNumber = 1;
  int _addedCount = 0;
  Timer? _autoSaveTimer;

  late List<QuestionItemData> _questionsList;
  Map<String, dynamic>? _paperData;
  String _paperId = '';
  bool _isLoading = true;
  bool _isSavingBatch = false;
  List<String> _paperDefaultAvailableIn = ['custom_practice', 'custom_test', 'pyq_practice', 'nta_questions', 'test_series'];

  // =========================================================================
  // TEST SERIES PAPER BUILDER - EXISTING CONTENT REUSE STATE
  // =========================================================================
  String _activeStep2Tab = 'existing'; // 'existing', 'manual', 'upload'
  String _existingContentSubTab = 'pyq'; // 'pyq', 'nta', 'qbank', 'summary'

  // PYQ Filters & Data
  String _pyqExamFilter = 'All';
  String _pyqYearFilter = 'All';
  String _pyqSubjectFilter = 'All';
  final TextEditingController _pyqSearchCtrl = TextEditingController();
  List<Map<String, dynamic>> _pyqPapersList = [];
  bool _isLoadingPyqPapers = false;

  // NTA Filters & Data
  String _ntaExamFilter = 'All';
  String _ntaYearFilter = 'All';
  String _ntaSessionFilter = 'All';
  final TextEditingController _ntaSearchCtrl = TextEditingController();
  List<Map<String, dynamic>> _ntaPapersList = [];
  bool _isLoadingNtaPapers = false;

  // Question Bank Filters & Data
  String _qbExamFilter = 'All';
  String _qbSubjectFilter = 'Physics';
  String _qbChapterFilter = 'All';
  String _qbTopicFilter = 'All';
  String _qbDifficultyFilter = 'All';
  String _qbSourceFilter = 'All';
  String _qbYearFilter = 'All';
  final TextEditingController _qbSearchCtrl = TextEditingController();
  int _qbPage = 1;
  int _qbTotalCount = 0;
  List<Map<String, dynamic>> _qbResultsList = [];
  final Set<String> _selectedQbQuestionIds = {};
  final List<Map<String, dynamic>> _selectedQbQuestionsList = [];
  bool _isLoadingQb = false;

  // Selection Mode inside Question Bank
  String _qbSelectionMode = 'manual'; // 'manual', 'random'
  String _randomSubject = 'Physics';
  String _randomChapter = 'All';
  String _randomDifficulty = 'All';
  int _randomCount = 30;
  bool _isGeneratingRandom = false;

  // Multi-Source Selected Questions Pool (PYQ + NTA + Question Bank)
  final List<Map<String, dynamic>> _testSeriesSelectedQuestions = [];
  int _duplicatesRemovedCount = 0;

  // Target Subject Distribution State
  int _targetPhysicsCount = 45;
  int _targetChemistryCount = 45;
  int _targetBotanyCount = 45;
  int _targetZoologyCount = 45;
  bool _allowIncompletePaper = false;

  // Paper Preview State
  int _previewQuestionIndex = 0;

  bool _hasEssentialDetails(QuestionItemData q) {
    // 1. Question text or image must be provided
    final bool hasTextOrImage = q.text.trim().isNotEmpty || (q.questionImage != null && q.questionImage!.isNotEmpty);
    if (!hasTextOrImage) return false;

    // 2. Options: At least 2 non-empty options (or option images)
    final int filledOpts = q.options.where((opt) => opt.trim().isNotEmpty).length;
    final int filledImgs = q.optionImages.where((img) => img != null && img.isNotEmpty).length;
    if ((filledOpts + filledImgs) < 2) return false;

    // 3. Correct Option Index: MUST be selected by admin (>= 0 and < options.length)
    if (q.correctOptionIndex < 0 || q.correctOptionIndex >= q.options.length) {
      return false;
    }

    // 4. Chapter & Topic: MUST be selected by admin from dropdown
    if (q.chapterId.trim().isEmpty && q.chapter.trim().isEmpty && q.chapterTopic.trim().isEmpty) {
      return false;
    }

    // Auto-fix visibility if empty (use the test series' default visibility configured in Step 1)
    if (q.availableIn.isEmpty) {
      q.availableIn = List<String>.from(_paperDefaultAvailableIn);
    }

    return true;
  }

  void _scheduleAutoSave(QuestionItemData q) {
    if (_isLoading) return;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!_isLoading && mounted) {
        if (_hasEssentialDetails(q)) {
          _saveSingleQuestion(q, showToast: false);
        } else {
          debugPrint('Auto-save skipped for Question ${q.number}: Missing essential details marked with *.');
        }
      }
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _questionsList = List.generate(
      widget.totalQuestionsCount,
      (index) => QuestionItemData(
        id: 'q_temp_${index + 1}',
        number: index + 1,
      ),
    );
    _loadPaperAndSavedQuestions();
  }

  List<Map<String, dynamic>> _loadedDbChapters = [];

  Map<String, dynamic> _parseOptionsFromQuestionText(String rawText, List<String> existingOpts) {
    if (existingOpts.any((o) => o.trim().isNotEmpty)) {
      return {'text': rawText, 'options': existingOpts};
    }

    final RegExp optionReg = RegExp(r'^\s*[\(\[]?(?:[1-4]|[A-Da-d])[\)\.\:]\s*(.*)', multiLine: true);
    final matches = optionReg.allMatches(rawText).toList();

    if (matches.length >= 2) {
      final List<String> parsedOpts = [];
      for (var m in matches) {
        final val = m.group(1)?.trim() ?? '';
        if (val.isNotEmpty) parsedOpts.add(val);
      }
      while (parsedOpts.length < 4) parsedOpts.add('');

      final firstMatchIndex = rawText.indexOf(matches.first.group(0)!);
      final cleanText = (firstMatchIndex != -1 ? rawText.substring(0, firstMatchIndex) : rawText).trim();

      return {
        'text': cleanText.isNotEmpty ? cleanText : rawText,
        'options': parsedOpts.sublist(0, 4),
      };
    }

    return {'text': rawText, 'options': existingOpts};
  }

  Future<void> _loadPaperAndSavedQuestions() async {
    setState(() => _isLoading = true);

    _paperData = widget.paperRecord ?? await SupabaseService.loadActiveUploadPaperSession();
    _paperId = _paperData?['id'] ?? 'paper_${DateTime.now().millisecondsSinceEpoch}';

    final String buildMethod = (_paperData?['buildPaperMethod'] ?? _paperData?['build_paper_method'] ?? '').toString();
    final String sourceCat = (_paperData?['source_category'] ?? _paperData?['sourceCategory'] ?? '').toString();

    if (buildMethod == 'existing_pyq' || buildMethod == 'existing_nta' || buildMethod == 'question_bank' || sourceCat == 'Test Series') {
      _activeStep2Tab = 'existing';
      if (buildMethod == 'existing_pyq') _existingContentSubTab = 'pyq';
      else if (buildMethod == 'existing_nta') _existingContentSubTab = 'nta';
      else if (buildMethod == 'question_bank') _existingContentSubTab = 'qbank';
      _loadPyqPapers();
      _loadNtaPapers();
      _loadQuestionBank();
    }

    final String exam = _paperData?['exam'] ?? _paperData?['exam_name'] ?? 'NEET';
    final String subject = _paperData?['subject'] ?? 'Physics';

    try {
      _loadedDbChapters = await SupabaseService.fetchAllChaptersForDropdown(exam: exam, subject: subject);
    } catch (e) {
      debugPrint('Notice loading db chapters for step2: $e');
    }

    final int qCount = (int.tryParse(_paperData?['question_count']?.toString() ?? '') ?? widget.totalQuestionsCount).clamp(1, 1000);

    final dynamic paperAvailRaw = widget.paperRecord?['available_in'] ?? widget.paperRecord?['availableIn'] ?? _paperData?['available_in'] ?? _paperData?['availableIn'];
    final List<String> defaultAvailableIn = (paperAvailRaw is List && paperAvailRaw.isNotEmpty)
        ? List<String>.from(paperAvailRaw)
        : <String>['custom_practice', 'custom_test', 'pyq_practice', 'nta_questions', 'test_series'];
    _paperDefaultAvailableIn = List<String>.from(defaultAvailableIn);

    final String optionPresetKey = widget.paperRecord?['defaultOptionPreset'] ?? widget.paperRecord?['default_option_preset'] ?? _paperData?['defaultOptionPreset'] ?? _paperData?['default_option_preset'] ?? '1_2_3_4';
    final List<String> defaultPresetOpts = _getPresetOptions(optionPresetKey);

    if (_questionsList.length != qCount) {
      _questionsList = List.generate(
        qCount,
        (index) => QuestionItemData(
          id: 'q_${_paperId}_${index + 1}',
          number: index + 1,
          options: List<String>.from(defaultPresetOpts),
          availableIn: List<String>.from(defaultAvailableIn),
          positiveMarks: '4',
          negativeMarks: '-1',
        ),
      );
    }

    final dynamic preselectedRaw = _paperData?['preselectedQuestions'] ?? _paperData?['preselected_questions'];
    if (preselectedRaw is List && preselectedRaw.isNotEmpty) {
      final List<QuestionItemData> preselectedItems = [];
      for (int idx = 0; idx < preselectedRaw.length; idx++) {
        final qMap = Map<String, dynamic>.from(preselectedRaw[idx] as Map);
        final opts = SupabaseService.parseOptionsFromQuestionMap(qMap);
        final List<String?> optImgs = [
          qMap['option_image_1'] ?? qMap['option_1_image'] ?? qMap['optionImage1'],
          qMap['option_image_2'] ?? qMap['option_2_image'] ?? qMap['optionImage2'],
          qMap['option_image_3'] ?? qMap['option_3_image'] ?? qMap['optionImage3'],
          qMap['option_image_4'] ?? qMap['option_4_image'] ?? qMap['optionImage4'],
        ];

        int correctIdx = -1;
        if (qMap['correct_option_index'] != null) {
          correctIdx = (qMap['correct_option_index'] as num).toInt();
        } else if (qMap['correctOptionIndex'] != null) {
          correctIdx = (qMap['correctOptionIndex'] as num).toInt();
        }

        preselectedItems.add(QuestionItemData(
          id: qMap['id']?.toString() ?? 'q_${_paperId}_${idx + 1}',
          number: idx + 1,
          text: qMap['question_text'] ?? qMap['questionText'] ?? '',
          questionImage: qMap['question_image'] ?? qMap['questionImage'],
          options: opts,
          optionImages: optImgs,
          correctOptionIndex: correctIdx,
          explanation: qMap['explanation'] ?? qMap['solution'] ?? '',
          solutionVideoUrl: qMap['solution_video_url'] ?? qMap['solutionVideoUrl'],
          difficulty: qMap['difficulty'] ?? 'Medium',
          positiveMarks: qMap['marks']?.toString() ?? qMap['positiveMarks']?.toString() ?? '4',
          negativeMarks: qMap['negative_marks']?.toString() ?? qMap['negativeMarks']?.toString() ?? '-1',
          questionType: qMap['q_type'] ?? qMap['question_type'] ?? 'MCQ (Single Correct)',
          subject: qMap['subject'] ?? 'Physics',
          chapter: qMap['chapter'] ?? '',
          topic: qMap['topic'] ?? '',
          chapterTopic: qMap['chapter'] ?? '',
          chapterId: qMap['chapter_id']?.toString() ?? '',
          isSaved: true,
          availableIn: defaultAvailableIn,
        ));
      }
      if (preselectedItems.isNotEmpty) {
        _questionsList = preselectedItems;
        _activeStep2Tab = 'existing';
        _existingContentSubTab = 'summary';
      }
    }

    final savedQList = await SupabaseService.fetchQuestionsForPaper(_paperId);

    int savedCounter = 0;
    int firstUnsavedIndex = -1;

    for (int i = 0; i < _questionsList.length; i++) {
      final qNum = i + 1;
      final String expectedUuid = SupabaseService.toValidUuid('q_${_paperId}_$qNum');
      final savedMatch = savedQList.firstWhere(
        (sq) {
          final rawNum = sq['question_number'] ?? sq['questionNumber'];
          final int? parsedNum = rawNum is num ? rawNum.toInt() : int.tryParse(rawNum?.toString() ?? '');
          final String sqId = sq['id']?.toString() ?? '';
          return (parsedNum != null && parsedNum == qNum) || sqId == 'q_${_paperId}_$qNum' || sqId == expectedUuid;
        },
        orElse: () => {},
      );

      if (savedMatch.isNotEmpty) {
        savedCounter++;
        String rawQText = savedMatch['question_text'] ?? savedMatch['questionText'] ?? '';
        List<String> opts = SupabaseService.parseOptionsFromQuestionMap(savedMatch);

        final parsed = _parseOptionsFromQuestionText(rawQText, opts);
        rawQText = parsed['text'] as String;
        opts = List<String>.from(parsed['options'] as List);
        while (opts.length < 4) opts.add('');

        int correctIdx = -1;
        if (savedMatch['correct_option_index'] != null) {
          correctIdx = (savedMatch['correct_option_index'] as num).toInt();
        } else if (savedMatch['correctOptionIndex'] != null) {
          correctIdx = (savedMatch['correctOptionIndex'] as num).toInt();
        } else {
          String correctOptText = (savedMatch['correct_answer'] ?? savedMatch['correctAnswer'] ?? '').toString().trim();
          if (correctOptText.startsWith('Option ')) {
            int optNum = int.tryParse(correctOptText.replaceAll('Option ', '')) ?? -1;
            if (optNum > 0) {
              correctIdx = (optNum - 1).clamp(0, opts.length > 0 ? opts.length - 1 : 0);
            }
          } else if (correctOptText.isNotEmpty) {
            int foundIdx = opts.indexOf(correctOptText);
            if (foundIdx != -1) {
              correctIdx = foundIdx;
            } else if (correctOptText.toLowerCase() == 'option a' || correctOptText.toLowerCase() == 'a') {
              correctIdx = 0;
            } else if (correctOptText.toLowerCase() == 'option b' || correctOptText.toLowerCase() == 'b') {
              correctIdx = 1;
            } else if (correctOptText.toLowerCase() == 'option c' || correctOptText.toLowerCase() == 'c') {
              correctIdx = 2;
            } else if (correctOptText.toLowerCase() == 'option d' || correctOptText.toLowerCase() == 'd') {
              correctIdx = 3;
            }
          }
        }

        String normDiff = (savedMatch['difficulty'] ?? 'Medium').toString().toLowerCase();
        if (normDiff == 'easy') normDiff = 'Easy';
        else if (normDiff == 'hard') normDiff = 'Hard';
        else normDiff = 'Medium';

        final optImgsRaw = savedMatch['option_images'] ?? savedMatch['optionImages'];
        final List<String?> optImgs = optImgsRaw is List
            ? List<String?>.from(optImgsRaw)
            : <String?>[null, null, null, null];
        while (optImgs.length < opts.length) optImgs.add(null);

        final String chapIdFromMatch = savedMatch['chapter_id']?.toString() ?? '';
        final String chapNameFromMatch = savedMatch['chapter']?.toString() ?? savedMatch['chapterTopic']?.toString() ?? '';
        final String qSubject = savedMatch['subject']?.toString() ?? subject;

        String finalChapId = chapIdFromMatch;
        String finalChapName = chapNameFromMatch;

        if (chapIdFromMatch.isNotEmpty && _loadedDbChapters.any((c) => c['id'].toString() == chapIdFromMatch)) {
          final matchedC = _loadedDbChapters.firstWhere((c) => c['id'].toString() == chapIdFromMatch);
          finalChapId = matchedC['id'].toString();
          finalChapName = matchedC['name'].toString();
        } else if (chapNameFromMatch.isNotEmpty && _loadedDbChapters.any((c) => c['name'].toString().trim().toLowerCase() == chapNameFromMatch.trim().toLowerCase())) {
          final matchedC = _loadedDbChapters.firstWhere((c) => c['name'].toString().trim().toLowerCase() == chapNameFromMatch.trim().toLowerCase());
          finalChapId = matchedC['id'].toString();
          finalChapName = matchedC['name'].toString();
        } else if (chapNameFromMatch.isNotEmpty || chapIdFromMatch.isNotEmpty) {
          finalChapId = chapIdFromMatch;
          finalChapName = chapNameFromMatch.isNotEmpty ? chapNameFromMatch : chapIdFromMatch;
        }

        final dynamic availInRaw = savedMatch['available_in'] ?? savedMatch['availableIn'];
        final List<String> availInList = (availInRaw is List && availInRaw.isNotEmpty)
            ? List<String>.from(availInRaw)
            : List<String>.from(defaultAvailableIn);

        _questionsList[i] = QuestionItemData(
          id: savedMatch['id'] ?? 'q_${_paperId}_$qNum',
          number: qNum,
          text: rawQText,
          questionImage: savedMatch['question_image'] ?? savedMatch['questionImage'],
          options: opts,
          optionImages: optImgs,
          correctOptionIndex: correctIdx,
          explanation: savedMatch['explanation'] ?? savedMatch['solution'] ?? '',
          solutionVideoUrl: savedMatch['solution_video_url'] ?? savedMatch['solutionVideoUrl'] ?? savedMatch['video_url'],
          difficulty: normDiff,
          positiveMarks: savedMatch['marks']?.toString() ?? savedMatch['positiveMarks']?.toString() ?? '4',
          negativeMarks: savedMatch['negative_marks']?.toString() ?? savedMatch['negativeMarks']?.toString() ?? '-1',
          questionType: savedMatch['q_type'] ?? savedMatch['question_type'] ?? savedMatch['qType'] ?? 'MCQ (Single Correct)',
          subject: qSubject,
          chapter: finalChapName,
          topic: savedMatch['topic'] ?? finalChapName,
          chapterTopic: finalChapName,
          chapterId: finalChapId,
          availableIn: availInList,
          isSaved: savedMatch.isNotEmpty && correctIdx >= 0 && finalChapName.isNotEmpty,
        );
      } else {
        if (firstUnsavedIndex == -1) {
          firstUnsavedIndex = i;
        }
        _questionsList[i] = QuestionItemData(
          id: 'q_${_paperId}_$qNum',
          number: qNum,
          options: List<String>.from(defaultPresetOpts),
          availableIn: List<String>.from(defaultAvailableIn),
          positiveMarks: '4',
          negativeMarks: '-1',
        );
      }
    }

    _addedCount = savedCounter;

    if (firstUnsavedIndex != -1) {
      _currentPageIndex = (firstUnsavedIndex ~/ _itemsPerPage) + 1;
    }

    setState(() => _isLoading = false);
  }

  // =========================================================================
  // TEST SERIES PAPER BUILDER - EXISTING CONTENT REUSE METHODS
  // =========================================================================

  Future<void> _loadPyqPapers() async {
    setState(() => _isLoadingPyqPapers = true);
    try {
      final papers = await SupabaseService.fetchExistingPYQPapers(
        exam: _pyqExamFilter,
        year: _pyqYearFilter,
        subject: _pyqSubjectFilter,
        search: _pyqSearchCtrl.text,
      );
      if (mounted) {
        setState(() {
          _pyqPapersList = papers;
          _isLoadingPyqPapers = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingPyqPapers = false);
    }
  }

  Future<void> _loadNtaPapers() async {
    setState(() => _isLoadingNtaPapers = true);
    try {
      final papers = await SupabaseService.fetchExistingNTAPapers(
        exam: _ntaExamFilter,
        year: _ntaYearFilter,
        session: _ntaSessionFilter,
        search: _ntaSearchCtrl.text,
      );
      if (mounted) {
        setState(() {
          _ntaPapersList = papers;
          _isLoadingNtaPapers = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingNtaPapers = false);
    }
  }

  Future<void> _loadQuestionBank() async {
    setState(() => _isLoadingQb = true);
    try {
      final res = await SupabaseService.queryQuestionBank(
        exam: _qbExamFilter,
        subject: _qbSubjectFilter,
        chapter: _qbChapterFilter,
        topic: _qbTopicFilter,
        difficulty: _qbDifficultyFilter,
        source: _qbSourceFilter,
        year: _qbYearFilter,
        search: _qbSearchCtrl.text,
        limit: 20,
        page: _qbPage,
      );
      if (mounted) {
        setState(() {
          _qbResultsList = List<Map<String, dynamic>>.from(res['items'] ?? []);
          _qbTotalCount = res['totalCount'] as int? ?? 0;
          _isLoadingQb = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingQb = false);
    }
  }

  Future<void> _attachPaperQuestionsToTestSeries(Map<String, dynamic> paper, String sourceTag) async {
    final String pId = (paper['id'] ?? paper['paper_id'] ?? '').toString();
    final String pName = (paper['paper_name'] ?? paper['paperName'] ?? paper['title'] ?? 'Paper').toString();
    if (pId.isEmpty) return;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Loading questions from "$pName"...'),
          backgroundColor: const Color(0xFF4F46E5),
          duration: const Duration(seconds: 1),
        ),
      );
    }

    final questions = await SupabaseService.fetchQuestionsForPaper(pId, paperName: pName);
    if (questions.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No questions found in "$pName".'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    int dupCount = 0;
    int addedCount = 0;
    final Set<String> existingIds = _testSeriesSelectedQuestions
        .map((q) => (q['id'] ?? q['question_id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet();

    for (var q in questions) {
      final qMap = Map<String, dynamic>.from(q);
      final qId = (qMap['id'] ?? qMap['question_id'] ?? '').toString();

      qMap['source_badge'] = sourceTag;
      qMap['original_paper'] = pName;

      if (qId.isNotEmpty && existingIds.contains(qId)) {
        dupCount++;
      } else {
        if (qId.isNotEmpty) existingIds.add(qId);
        _testSeriesSelectedQuestions.add(qMap);
        addedCount++;
      }
    }

    setState(() {
      _duplicatesRemovedCount += dupCount;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Attached $addedCount questions from "$pName".' + (dupCount > 0 ? ' ($dupCount duplicate questions removed.)' : '')),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _generateRandomSelection() async {
    setState(() => _isGeneratingRandom = true);
    try {
      final List<String> excludeIds = _testSeriesSelectedQuestions
          .map((q) => (q['id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toList();

      final randomQuestions = await SupabaseService.getRandomQuestionsFromBank(
        subject: _randomSubject,
        chapter: _randomChapter,
        difficulty: _randomDifficulty,
        count: _randomCount,
        excludeIds: excludeIds,
      );

      int added = 0;
      for (var q in randomQuestions) {
        final qMap = Map<String, dynamic>.from(q);
        qMap['source_badge'] = '[QUESTION BANK] ${_randomSubject} → ${_randomChapter != 'All' ? _randomChapter : 'Mixed'}';
        _testSeriesSelectedQuestions.add(qMap);
        added++;
      }

      setState(() {
        _isGeneratingRandom = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Successfully generated $added questions for $_randomSubject!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isGeneratingRandom = false);
    }
  }

  void _autoArrangeQuestionsBySubject() {
    final Map<String, int> subjectOrder = {
      'physics': 1,
      'chemistry': 2,
      'botany': 3,
      'biology': 3,
      'zoology': 4,
      'mathematics': 5,
    };

    setState(() {
      _testSeriesSelectedQuestions.sort((a, b) {
        final subA = (a['subject'] ?? a['subject_id'] ?? '').toString().toLowerCase();
        final subB = (b['subject'] ?? b['subject_id'] ?? '').toString().toLowerCase();
        final orderA = subjectOrder[subA] ?? 99;
        final orderB = subjectOrder[subB] ?? 99;
        if (orderA != orderB) return orderA.compareTo(orderB);
        return 0;
      });
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Questions auto-arranged by Subject (Physics → Chemistry → Botany → Zoology).'),
          backgroundColor: Color(0xFF4F46E5),
        ),
      );
    }
  }

  void _randomizeSelectedQuestionsOrder() {
    setState(() {
      _testSeriesSelectedQuestions.shuffle();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Question order randomized.'),
          backgroundColor: Color(0xFF4F46E5),
        ),
      );
    }
  }

  Future<void> _finalizeAndCreateTestSeriesPaper() async {
    if (_testSeriesSelectedQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one question from PYQs, NTA papers, or Question Bank.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final int physicsCount = _testSeriesSelectedQuestions.where((q) => (q['subject'] ?? '').toString().toLowerCase() == 'physics').length;
    final int chemistryCount = _testSeriesSelectedQuestions.where((q) => (q['subject'] ?? '').toString().toLowerCase() == 'chemistry').length;
    final int botanyCount = _testSeriesSelectedQuestions.where((q) => ['botany', 'biology'].contains((q['subject'] ?? '').toString().toLowerCase())).length;
    final int zoologyCount = _testSeriesSelectedQuestions.where((q) => (q['subject'] ?? '').toString().toLowerCase() == 'zoology').length;
    final int totalSelected = _testSeriesSelectedQuestions.length;

    if (!_allowIncompletePaper && totalSelected < 180 && (_paperData?['exam'] ?? '').toString().contains('NEET')) {
      final bool? proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Incomplete Paper Warning'),
          content: Text(
            'Target NEET paper question count is 180, but you currently have $totalSelected questions selected.\n\n'
            'Distribution:\n'
            '• Physics: $physicsCount / 45\n'
            '• Chemistry: $chemistryCount / 45\n'
            '• Botany: $botanyCount / 45\n'
            '• Zoology: $zoologyCount / 45\n\n'
            'Do you want to allow incomplete paper creation?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                setState(() => _allowIncompletePaper = true);
                Navigator.pop(ctx, true);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
              child: const Text('Allow Incomplete & Create', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    setState(() => _isSavingBatch = true);

    final res = await SupabaseService.createTestSeriesPaperFromExistingQuestions(
      paperDetails: _paperData ?? {
        'paper_name': widget.paperName,
        'exam': 'NEET',
        'year': 2026,
        'questionCount': _testSeriesSelectedQuestions.length,
      },
      selectedQuestionItems: _testSeriesSelectedQuestions,
      testSeriesDetails: {
        'title': _paperData?['test_series_title'] ?? widget.paperName,
        'description': _paperData?['test_series_desc'] ?? 'Full length test series paper',
      },
    );

    setState(() => _isSavingBatch = false);

    if (res['success'] == true && mounted) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 28),
              const SizedBox(width: 10),
              const Text('Test Series Paper Created!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Paper Name: ${res['paperName']}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Total Unique Questions Attached: ${res['totalQuestions']}'),
              const SizedBox(height: 4),
              Text('Duplicate Questions Removed: ${res['duplicatesRemoved']}', style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text('The Test Series paper has been published and is immediately available across Web, Mobile, and Web App!', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
              child: const Text('Done & Return to Admin', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  void _showExistingPaperPreviewDialog(Map<String, dynamic> paper, String sourceTag) async {
    final String pId = (paper['id'] ?? paper['paper_id'] ?? '').toString();
    final String pName = (paper['paper_name'] ?? paper['paperName'] ?? paper['title'] ?? 'Paper Preview').toString();
    if (pId.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    final questions = await SupabaseService.fetchQuestionsForPaper(pId, paperName: pName);
    if (mounted) Navigator.pop(context);

    if (questions.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No questions found in "$pName".'), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    int previewIdx = 0;

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final currentQ = questions[previewIdx];
          final opts = SupabaseService.parseOptionsFromQuestionMap(currentQ);
          final String qText = currentQ['question_text'] ?? currentQ['questionText'] ?? '';
          final String qImg = currentQ['question_image'] ?? currentQ['questionImage'] ?? '';
          final String explanation = currentQ['explanation'] ?? currentQ['solution'] ?? '';
          final String subject = currentQ['subject'] ?? 'Physics';

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: 800,
              constraints: const BoxConstraints(maxHeight: 700),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(6)),
                                  child: Text(sourceTag, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF4F46E5))),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    pName,
                                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('Question ${previewIdx + 1} of ${questions.length} • Subject: $subject', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                    ],
                  ),
                  const Divider(height: 24),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (qImg.isNotEmpty) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(qImg, height: 180, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                            ),
                            const SizedBox(height: 12),
                          ],
                          LaTeXView(text: qText, style: GoogleFonts.inter(fontSize: 14.5, color: const Color(0xFF1E293B))),
                          const SizedBox(height: 16),

                          ...opts.asMap().entries.map((e) {
                            final idx = e.key;
                            final txt = e.value;
                            final letter = String.fromCharCode(65 + idx);
                            final bool isCorr = (currentQ['correct_option_index'] == idx || currentQ['correctOptionIndex'] == idx);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isCorr ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: isCorr ? const Color(0xFF10B981) : const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: isCorr ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                                    child: Text(letter, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(child: LaTeXView(text: txt.isNotEmpty ? txt : 'Option $letter')),
                                  if (isCorr) const Icon(Icons.check_circle, size: 18, color: Color(0xFF10B981)),
                                ],
                              ),
                            );
                          }).toList(),

                          if (explanation.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Explanation:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF92400E))),
                                  const SizedBox(height: 4),
                                  LaTeXView(text: explanation, style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF78350F))),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: previewIdx > 0 ? () => setDialogState(() => previewIdx--) : null,
                            icon: const Icon(Icons.arrow_back, size: 16),
                            label: const Text('Previous'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: previewIdx < questions.length - 1 ? () => setDialogState(() => previewIdx++) : null,
                            icon: const Icon(Icons.arrow_forward, size: 16),
                            label: const Text('Next'),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _attachPaperQuestionsToTestSeries(paper, sourceTag);
                        },
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Select / Attach Entire Paper'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _saveAllQuestions({bool showToast = true}) async {
    if (_isLoading || _isSavingBatch) return;
    setState(() => _isSavingBatch = true);

    int savedCount = 0;

    for (int i = 0; i < _questionsList.length; i++) {
      final q = _questionsList[i];
      if (_hasEssentialDetails(q)) {
        int correctIdx = (q.correctOptionIndex >= 0 && q.correctOptionIndex < q.options.length) ? q.correctOptionIndex : 0;
        String correctLetter = String.fromCharCode(65 + correctIdx);
        String correctAnsText = q.options[correctIdx].isNotEmpty
            ? q.options[correctIdx]
            : 'Option $correctLetter';

        final String qId = q.id.isNotEmpty ? q.id : 'q_${_paperId}_${q.number}';

        final qMap = {
          'id': qId,
          'paper_id': _paperId,
          'question_number': q.number,
          'questionText': q.text,
          'question_text': q.text,
          'questionImage': q.questionImage ?? '',
          'question_image': q.questionImage ?? '',
          'options': q.options,
          'optionImages': q.optionImages,
          'option_images': q.optionImages,
          'correctAnswer': 'Option $correctLetter',
          'correct_answer': 'Option $correctLetter',
          'correctOptionIndex': correctIdx,
          'correct_option_index': correctIdx,
          'correctText': correctAnsText,
          'explanation': q.explanation,
          'solution_video_url': q.solutionVideoUrl ?? '',
          'solutionVideoUrl': q.solutionVideoUrl ?? '',
          'difficulty': q.difficulty,
          'marks': double.tryParse(q.positiveMarks) ?? 4.0,
          'negativeMarks': double.tryParse(q.negativeMarks) ?? 1.0,
          'qType': q.questionType,
          'subject': q.subject,
          'chapter': q.chapter,
          'topic': q.topic,
          'sourceType': _paperData?['source_category'] ?? _paperData?['sourceCategory'] ?? 'PYQ',
          'available_in': q.availableIn,
          'availableIn': q.availableIn,
          'exam': _paperData?['exam'] ?? _paperData?['exam_name'] ?? 'NEET',
          'year': _paperData?['year']?.toString() ?? '2026',
          'paperName': _paperData?['paper_name'] ?? _paperData?['paperName'] ?? widget.paperName,
          'test_series_id': _paperId,
          'test_series_title': _paperData?['test_series_title'] ?? _paperData?['testSeriesTitle'] ?? '',
        };

        final ok = await SupabaseService.saveQuestionMap(qMap);
        if (ok) {
          q.isSaved = true;
          q.id = qId;
          savedCount++;
        }
      }
    }

    if (savedCount > 0) {
      setState(() {
        _addedCount = _questionsList.where((q) => q.isSaved).length;
      });

      // Update paper record with saved questions count and mark Published
      try {
        final updatedPaper = Map<String, dynamic>.from(_paperData ?? {});
        updatedPaper['saved_questions_count'] = _addedCount;
        updatedPaper['status'] = 'Published';
        await SupabaseService.savePaperRecord(updatedPaper);

        final tsTitle = (updatedPaper['test_series_title'] ?? updatedPaper['new_test_series_name'] ?? updatedPaper['existing_test_series'] ?? '').toString().trim();
        if (tsTitle.isNotEmpty || updatedPaper['source_category'] == 'Test Series') {
          await SupabaseService.saveTestSeries({
            'id': SupabaseService.toValidUuid('ts_${updatedPaper['exam']}_${updatedPaper['year']}_$tsTitle'),
            'title': tsTitle.isNotEmpty ? tsTitle : (updatedPaper['paper_name'] ?? 'NEET Test Series'),
            'exam': updatedPaper['exam'] ?? 'NEET',
            'year': updatedPaper['year']?.toString() ?? '2026',
            'category': 'Full Syllabus',
            'paper_id': _paperId,
            'paper_name': widget.paperName,
            'question_count': _addedCount,
            'duration_minutes': int.tryParse(updatedPaper['duration_minutes']?.toString() ?? '180') ?? 180,
            'difficulty': 'High',
            'status': 'Published',
          });
        }
      } catch (paperErr) {
        debugPrint('Notice updating paper/test series record status: $paperErr');
      }

      if (showToast && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Persisted $savedCount question(s) to Supabase Question Bank! (Total Saved: $_addedCount / ${_questionsList.length})'),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      if (showToast && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No questions with content found to save. Please enter question text or attach an image.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }

    if (mounted) setState(() => _isSavingBatch = false);
  }

  Future<void> _saveSingleQuestion(QuestionItemData q, {bool showToast = true}) async {
    if (_isLoading) return;
    if (!_hasEssentialDetails(q)) {
      if (mounted && showToast) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please complete all essential details marked with * for Question ${q.number} (Text, Options, Correct Answer, Chapter, Visibility).'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
      return;
    }

    int correctIdx = (q.correctOptionIndex >= 0 && q.correctOptionIndex < q.options.length) ? q.correctOptionIndex : 0;
    String correctLetter = String.fromCharCode(65 + correctIdx);
    String correctAnsText = q.options[correctIdx].isNotEmpty
        ? q.options[correctIdx]
        : 'Option $correctLetter';

    final String qId = q.id.isNotEmpty ? q.id : 'q_${_paperId}_${q.number}';

    final qMap = {
      'id': qId,
      'paper_id': _paperId,
      'question_number': q.number,
      'questionText': q.text,
      'question_text': q.text,
      'questionImage': q.questionImage ?? '',
      'question_image': q.questionImage ?? '',
      'options': q.options,
      'optionImages': q.optionImages,
      'option_images': q.optionImages,
      'correctAnswer': 'Option $correctLetter',
      'correct_answer': 'Option $correctLetter',
      'correctOptionIndex': correctIdx,
      'correct_option_index': correctIdx,
      'correctText': correctAnsText,
      'explanation': q.explanation,
      'solution_video_url': q.solutionVideoUrl ?? '',
      'solutionVideoUrl': q.solutionVideoUrl ?? '',
      'difficulty': q.difficulty,
      'marks': double.tryParse(q.positiveMarks) ?? 4.0,
      'negativeMarks': double.tryParse(q.negativeMarks) ?? 1.0,
      'qType': q.questionType,
      'chapter_id': (q.chapterId.isNotEmpty && SupabaseService.isValidUuid(q.chapterId)) ? q.chapterId : null,
      'subject': q.subject,
      'chapter': q.chapter,
      'topic': q.topic,
      'sourceType': _paperData?['source_category'] ?? _paperData?['sourceCategory'] ?? 'PYQ',
      'available_in': q.availableIn,
      'availableIn': q.availableIn,
      'exam': _paperData?['exam'] ?? _paperData?['exam_name'] ?? 'NEET',
      'year': _paperData?['year']?.toString() ?? '2026',
      'paperName': _paperData?['paper_name'] ?? _paperData?['paperName'] ?? widget.paperName,
      'test_series_id': _paperId,
      'test_series_title': _paperData?['test_series_title'] ?? _paperData?['testSeriesTitle'] ?? '',
    };

    final res = await SupabaseService.saveQuestionMapWithStatus(qMap);

    if (res['success'] == true) {
      setState(() {
        q.isSaved = true;
        q.id = qId;
        _addedCount = _questionsList.where((item) => item.isSaved).length;
      });

      if (mounted && showToast) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Question ${q.number} saved successfully to Supabase Question Bank!'),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      if (mounted && showToast) {
        final err = res['error'] ?? 'Unknown database error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save Question ${q.number}: $err'),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _saveCurrentBatch({bool showToast = true}) async {
    return _saveAllQuestions(showToast: showToast);
  }

  Future<void> _pickAndUploadQuestionImage(QuestionItemData q) async {
    try {
      setState(() => q.isUploadingQuestionImage = true);
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'svg'],
        withData: true,
      );
      if (result != null && result.files.single.bytes != null) {
        final bytes = result.files.single.bytes!;
        final filename = result.files.single.name;
        final url = await SupabaseService.uploadImageToSupabase(bytes, filename);
        if (url != null && url.isNotEmpty) {
          setState(() {
            q.questionImage = url;
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking/uploading question image: $e');
    } finally {
      if (mounted) setState(() => q.isUploadingQuestionImage = false);
    }
  }

  Future<void> _pickAndUploadOptionImage(QuestionItemData q, int optIdx) async {
    try {
      while (q.optionImages.length <= optIdx) q.optionImages.add(null);
      while (q.isUploadingOptionImage.length <= optIdx) q.isUploadingOptionImage.add(false);

      setState(() => q.isUploadingOptionImage[optIdx] = true);
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'svg'],
        withData: true,
      );
      if (result != null && result.files.single.bytes != null) {
        final bytes = result.files.single.bytes!;
        final filename = result.files.single.name;
        final url = await SupabaseService.uploadImageToSupabase(bytes, filename);
        if (url != null && url.isNotEmpty) {
          setState(() {
            q.optionImages[optIdx] = url;
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking/uploading option image: $e');
    } finally {
      if (mounted) setState(() => q.isUploadingOptionImage[optIdx] = false);
    }
  }

  Future<void> _pickAndUploadSolutionVideo(QuestionItemData q) async {
    try {
      setState(() => q.isUploadingSolutionVideo = true);
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp4', 'webm', 'mov', 'm4v', 'avi', 'mkv'],
        withData: true,
      );
      if (result != null && result.files.single.bytes != null) {
        final bytes = result.files.single.bytes!;
        final filename = result.files.single.name;
        final ext = result.files.single.extension?.toLowerCase() ?? 'mp4';
        final mimeType = ext == 'webm' ? 'video/webm' : (ext == 'mov' ? 'video/quicktime' : 'video/mp4');
        final url = await SupabaseService.uploadMediaFile(
          fileBytes: bytes,
          fileName: 'solution_vid_${DateTime.now().millisecondsSinceEpoch}_$filename',
          mimeType: mimeType,
        );
        if (url != null && url.isNotEmpty) {
          setState(() {
            q.solutionVideoUrl = url;
            _scheduleAutoSave(q);
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Solution video uploaded successfully!')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error uploading solution video: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading video: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => q.isUploadingSolutionVideo = false);
    }
  }

  void _addOptionToQuestion(QuestionItemData q) {
    if (q.options.length < 6) {
      setState(() {
        q.options.add('');
      });
    }
  }

  void _duplicateQuestion(int index) {
    setState(() {
      final source = _questionsList[index];
      final newQ = QuestionItemData(
        number: _questionsList.length + 1,
        text: source.text,
        options: List.from(source.options),
        correctOptionIndex: source.correctOptionIndex,
        explanation: source.explanation,
        solutionVideoUrl: source.solutionVideoUrl,
        difficulty: source.difficulty,
        positiveMarks: source.positiveMarks,
        negativeMarks: source.negativeMarks,
        questionType: source.questionType,
        chapterTopic: source.chapterTopic,
      );
      _questionsList.insert(index + 1, newQ);
      _reindexQuestions();
    });
  }

  void _deleteQuestion(int index) {
    if (_questionsList.length > 1) {
      setState(() {
        _questionsList.removeAt(index);
        _reindexQuestions();
      });
    }
  }

  void _reindexQuestions() {
    for (int i = 0; i < _questionsList.length; i++) {
      _questionsList[i].number = i + 1;
    }
  }

  List<String> _getPresetOptions(String presetKey) {
    switch (presetKey) {
      case '1_2_3_4':
        return ['1', '2', '3', '4'];
      case 'A_B_C_D':
        return ['A', 'B', 'C', 'D'];
      case '(1)_(2)_(3)_(4)':
        return ['(1)', '(2)', '(3)', '(4)'];
      case '(A)_(B)_(C)_(D)':
        return ['(A)', '(B)', '(C)', '(D)'];
      case 'blank':
        return ['', '', '', ''];
      default:
        return ['1', '2', '3', '4'];
    }
  }

  void _applyOptionPresetToAllQuestions(String presetKey) {
    if (presetKey == 'sync_visibility') {
      setState(() {
        for (var q in _questionsList) {
          q.availableIn = List<String>.from(_paperDefaultAvailableIn);
        }
      });
      _saveAllQuestions(showToast: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚡ Synced visibility to paper default across all ${_questionsList.length} questions!'),
          backgroundColor: const Color(0xFF4F46E5),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final newOpts = _getPresetOptions(presetKey);
    setState(() {
      for (var q in _questionsList) {
        for (int i = 0; i < newOpts.length; i++) {
          if (i < q.options.length) {
            q.options[i] = newOpts[i];
          }
        }
      }
    });
    _saveAllQuestions(showToast: false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          presetKey == 'blank'
              ? 'Cleared options text across all ${_questionsList.length} questions.'
              : '⚡ Applied option preset [${newOpts.join(', ')}] across all ${_questionsList.length} questions!',
        ),
        backgroundColor: const Color(0xFF4F46E5),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildQuickOptionPresetPill(QuestionItemData q, List<String> presetOpts, String label) {
    return InkWell(
      onTap: () {
        setState(() {
          for (int i = 0; i < presetOpts.length; i++) {
            if (i < q.options.length) {
              q.options[i] = presetOpts[i];
            }
          }
        });
        _scheduleAutoSave(q);
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFC7D2FE)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF4F46E5)),
        ),
      ),
    );
  }

  void _showQuestionLivePreviewDialog(QuestionItemData q) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 820, maxHeight: 750),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                          child: const Icon(Icons.remove_red_eye_rounded, color: Color(0xFF4F46E5), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Student View Live Preview — Question ${q.number}',
                              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                            ),
                            Text(
                              'Authentic student renderer for LaTeX, KaTeX equations, images, and options.',
                              style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(height: 24, thickness: 1, color: Color(0xFFE2E8F0)),
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildStudentLivePreviewContent(q),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStudentLivePreviewContent(QuestionItemData q) {
    final optionLetters = ['A', 'B', 'C', 'D', 'E', 'F'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Meta Badges Bar
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Text(
                'Q${q.number} • ${q.subject}',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF1D4ED8)),
              ),
            ),
            if (q.chapter.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  q.chapter,
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: q.difficulty == 'Hard'
                    ? const Color(0xFFFEF2F2)
                    : q.difficulty == 'Easy'
                        ? const Color(0xFFECFDF5)
                        : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: q.difficulty == 'Hard'
                      ? const Color(0xFFFCA5A5)
                      : q.difficulty == 'Easy'
                          ? const Color(0xFFA7F3D0)
                          : const Color(0xFFFDE68A),
                ),
              ),
              child: Text(
                '${q.difficulty} Difficulty',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: q.difficulty == 'Hard'
                      ? const Color(0xFF991B1B)
                      : q.difficulty == 'Easy'
                          ? const Color(0xFF065F46)
                          : const Color(0xFF92400E),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Marks: +${q.positiveMarks} / ${q.negativeMarks}',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Question Statement Card with LaTeXView
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (q.text.trim().isNotEmpty)
                LaTeXView(
                  text: q.text,
                  style: GoogleFonts.inter(fontSize: 14.5, height: 1.5, color: const Color(0xFF0F172A), fontWeight: FontWeight.w500),
                )
              else
                Text(
                  '*(No text provided for this question)*',
                  style: GoogleFonts.inter(fontSize: 13, fontStyle: FontStyle.italic, color: const Color(0xFF94A3B8)),
                ),

              if (q.questionImage != null && q.questionImage!.isNotEmpty) ...[
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SmartImage(
                    url: q.questionImage,
                    height: 260,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Options List (Rendered with LaTeXView)
        Text('Options:', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF334155))),
        const SizedBox(height: 8),

        ...List.generate(q.options.length, (optIdx) {
          final letter = optionLetters[optIdx];
          final isCorrect = (q.correctOptionIndex == optIdx);
          final optText = q.options[optIdx];
          final optImg = (optIdx < q.optionImages.length) ? q.optionImages[optIdx] : null;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isCorrect ? const Color(0xFFECFDF5) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isCorrect ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                width: isCorrect ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Radio Letter Badge
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isCorrect ? const Color(0xFF10B981) : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      letter,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isCorrect ? Colors.white : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Option Text with LaTeXView
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (optText.trim().isNotEmpty)
                        LaTeXView(
                          text: optText,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            color: isCorrect ? const Color(0xFF065F46) : const Color(0xFF1E293B),
                            fontWeight: isCorrect ? FontWeight.bold : FontWeight.w500,
                          ),
                        )
                      else if (optImg == null || optImg.isEmpty)
                        Text('(Option $letter)', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8))),

                      if (optImg != null && optImg.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        SmartImage(
                          url: optImg,
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ],
                  ),
                ),

                if (isCorrect) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Correct Answer',
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),

        // Solution & Explanation Preview Section (If Provided)
        if (q.explanation.trim().isNotEmpty || (q.solutionVideoUrl != null && q.solutionVideoUrl!.trim().isNotEmpty)) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb_rounded, size: 18, color: Color(0xFF4F46E5)),
                    const SizedBox(width: 6),
                    Text(
                      'Explanation & Solution',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1E1B4B)),
                    ),
                  ],
                ),
                if (q.explanation.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  LaTeXView(
                    text: q.explanation,
                    style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: const Color(0xFF334155)),
                  ),
                ],
                if (q.solutionVideoUrl != null && q.solutionVideoUrl!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SolutionVideoPlayerWidget(
                    videoUrl: q.solutionVideoUrl!,
                    height: 200,
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth >= 900;

    final int remainingCount = _questionsList.length - _addedCount;
    final double progressPercent = _questionsList.isEmpty ? 0 : (_addedCount / _questionsList.length);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Sidebar (Desktop Only)
          if (isDesktop) _buildAdminSidebar(),

          // Main Scrollable Body
          Expanded(
            child: Column(
              children: [
                // Top Admin Navigation Header
                _buildTopAdminHeader(),

                // Scrollable Workspace Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Breadcrumbs
                            _buildBreadcrumb(),
                            const SizedBox(height: 12),

                            // 2. Title & Action Header Row
                            _buildTitleHeaderRow(),
                            const SizedBox(height: 24),

                            // 3. Stepper Indicator Bar
                            _buildStepperBar(),
                            const SizedBox(height: 20),

                            // 3.5 Main Step 2 Mode Tabs (Existing Content / Manual / Upload)
                            _buildStep2MainTabBar(),
                            const SizedBox(height: 24),

                            if (_activeStep2Tab == 'existing')
                              _buildExistingContentTabContent(isDesktop)
                            else if (_activeStep2Tab == 'manual') ...[
                              // 4. KPI Summary Metric Card
                              _buildKPISummaryCard(remainingCount, progressPercent),
                              const SizedBox(height: 20),

                              // 5. Filter / Jump Toolbar Bar
                              _buildFilterToolbarBar(),
                              const SizedBox(height: 20),

                              // 6. Question Cards List (Visible for current page)
                              ..._buildVisibleQuestionCards(isDesktop),
                              const SizedBox(height: 28),

                              // 7. Pagination Footer
                              _buildPaginationFooter(),
                            ] else ...[
                              _buildUploadQuestionsTabContent(),
                            ],
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
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

  // ===========================================================================
  // TEST SERIES PAPER BUILDER - STEP 2 TAB UI BUILDERS
  // ===========================================================================

  Widget _buildStep2MainTabBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMainTabButton('existing', Icons.auto_awesome_rounded, 'Create From Existing Content'),
            _buildMainTabButton('manual', Icons.edit_note_rounded, 'Manual Question Editor'),
            _buildMainTabButton('upload', Icons.upload_file_rounded, 'Bulk File / PDF Upload'),
          ],
        ),
      ),
    );
  }

  Widget _buildMainTabButton(String tabKey, IconData icon, String label) {
    final bool isSelected = _activeStep2Tab == tabKey;
    return InkWell(
      onTap: () {
        setState(() {
          _activeStep2Tab = tabKey;
          if (tabKey == 'existing') {
            _loadPyqPapers();
            _loadNtaPapers();
            _loadQuestionBank();
          }
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF64748B)),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubTabButton(String key, IconData icon, String label) {
    final bool isSelected = _existingContentSubTab == key;
    return InkWell(
      onTap: () {
        setState(() => _existingContentSubTab = key);
        if (key == 'pyq') _loadPyqPapers();
        if (key == 'nta') _loadNtaPapers();
        if (key == 'qbank') _loadQuestionBank();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        margin: const EdgeInsets.only(right: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F46E5) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: isSelected ? Colors.white : const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 12.5, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? Colors.white : const Color(0xFF4F46E5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExistingContentTabContent(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sub-Navigation Tabs
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSubTabButton('pyq', Icons.history_edu_rounded, 'Existing PYQ Papers'),
                _buildSubTabButton('nta', Icons.menu_book_rounded, 'Existing NTA Papers'),
                _buildSubTabButton('qbank', Icons.quiz_rounded, 'Question Bank / Sets'),
                _buildSubTabButton('summary', Icons.assignment_rounded, 'Paper Summary & Order (${_testSeriesSelectedQuestions.length})'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        if (_existingContentSubTab == 'pyq') _buildPyqSelectorView(),
        if (_existingContentSubTab == 'nta') _buildNtaSelectorView(),
        if (_existingContentSubTab == 'qbank') _buildQuestionBankSelectorView(),
        if (_existingContentSubTab == 'summary') _buildPaperSummaryAndOrderView(),
      ],
    );
  }

  Widget _buildPyqSelectorView() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Search & Filter Existing PYQ Papers', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 250,
                child: TextField(
                  controller: _pyqSearchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search paper name, year...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onSubmitted: (_) => _loadPyqPapers(),
                ),
              ),
              DropdownButton<String>(
                value: _pyqExamFilter,
                items: ['All', 'NEET', 'JEE Main', 'JEE Advanced', 'AIIMS'].map((e) => DropdownMenuItem(value: e, child: Text('Exam: $e'))).toList(),
                onChanged: (v) { setState(() => _pyqExamFilter = v!); _loadPyqPapers(); },
              ),
              DropdownButton<String>(
                value: _pyqYearFilter,
                items: ['All', '2026', '2025', '2024', '2023', '2022', '2021', '2020'].map((y) => DropdownMenuItem(value: y, child: Text('Year: $y'))).toList(),
                onChanged: (v) { setState(() => _pyqYearFilter = v!); _loadPyqPapers(); },
              ),
              ElevatedButton.icon(
                onPressed: _loadPyqPapers,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh PYQs'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_isLoadingPyqPapers)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
          else if (_pyqPapersList.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10)),
              child: Column(
                children: [
                  const Icon(Icons.description_outlined, size: 40, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 10),
                  Text('No matching PYQ papers found', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF64748B))),
                  const SizedBox(height: 4),
                  Text('Try clearing filters or search query.', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _pyqPapersList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final paper = _pyqPapersList[index];
                final pName = paper['paper_name'] ?? paper['paperName'] ?? paper['title'] ?? 'PYQ Paper';
                final year = paper['year']?.toString() ?? '2025';
                final qCount = paper['question_count'] ?? paper['saved_questions_count'] ?? 180;
                final exam = paper['exam'] ?? 'NEET';

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(4)),
                                  child: Text('PYQ • $year', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF15803D))),
                                ),
                                const SizedBox(width: 8),
                                Text(pName, style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('$exam • $qCount Questions • Physics • Chemistry • Biology', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _showExistingPaperPreviewDialog(paper, '[PYQ]'),
                            icon: const Icon(Icons.remove_red_eye, size: 15),
                            label: const Text('Preview'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _attachPaperQuestionsToTestSeries(paper, '[PYQ] $year $pName'),
                            icon: const Icon(Icons.add, size: 15),
                            label: const Text('Select / Use Entire Paper'),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
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
  }

  Widget _buildNtaSelectorView() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Search & Filter Existing NTA Question Papers', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 250,
                child: TextField(
                  controller: _ntaSearchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search NTA paper name...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onSubmitted: (_) => _loadNtaPapers(),
                ),
              ),
              DropdownButton<String>(
                value: _ntaExamFilter,
                items: ['All', 'NEET', 'JEE Main'].map((e) => DropdownMenuItem(value: e, child: Text('Exam: $e'))).toList(),
                onChanged: (v) { setState(() => _ntaExamFilter = v!); _loadNtaPapers(); },
              ),
              DropdownButton<String>(
                value: _ntaYearFilter,
                items: ['All', '2026', '2025', '2024'].map((y) => DropdownMenuItem(value: y, child: Text('Year: $y'))).toList(),
                onChanged: (v) { setState(() => _ntaYearFilter = v!); _loadNtaPapers(); },
              ),
              ElevatedButton.icon(
                onPressed: _loadNtaPapers,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh NTA Papers'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_isLoadingNtaPapers)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
          else if (_ntaPapersList.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10)),
              child: Column(
                children: [
                  const Icon(Icons.description_outlined, size: 40, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 10),
                  Text('No matching NTA papers found', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF64748B))),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _ntaPapersList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final paper = _ntaPapersList[index];
                final pName = paper['paper_name'] ?? paper['paperName'] ?? paper['title'] ?? 'NTA Paper';
                final year = paper['year']?.toString() ?? '2026';
                final qCount = paper['question_count'] ?? paper['saved_questions_count'] ?? 180;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: const Color(0xFFE0E7FF), borderRadius: BorderRadius.circular(4)),
                                  child: Text('NTA • $year', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF4F46E5))),
                                ),
                                const SizedBox(width: 8),
                                Text(pName, style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('Phase 1 • $qCount Questions', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _showExistingPaperPreviewDialog(paper, '[NTA]'),
                            icon: const Icon(Icons.remove_red_eye, size: 15),
                            label: const Text('Preview'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _attachPaperQuestionsToTestSeries(paper, '[NTA] $year $pName'),
                            icon: const Icon(Icons.add, size: 15),
                            label: const Text('Select / Use Entire Paper'),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
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
  }

  Widget _buildQuestionBankSelectorView() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Select Questions from Central Question Bank', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Manual Selection'),
                    selected: _qbSelectionMode == 'manual',
                    onSelected: (s) => setState(() => _qbSelectionMode = 'manual'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Random Selection Generator'),
                    selected: _qbSelectionMode == 'random',
                    onSelected: (s) => setState(() => _qbSelectionMode = 'random'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_qbSelectionMode == 'random') ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFBBF7D0))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('⚡ Random Selection Criteria', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF15803D))),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      DropdownButton<String>(
                        value: _randomSubject,
                        items: ['Physics', 'Chemistry', 'Botany', 'Zoology', 'Mathematics'].map((s) => DropdownMenuItem(value: s, child: Text('Subject: $s'))).toList(),
                        onChanged: (v) => setState(() => _randomSubject = v!),
                      ),
                      DropdownButton<String>(
                        value: _randomDifficulty,
                        items: ['All', 'easy', 'medium', 'hard'].map((d) => DropdownMenuItem(value: d, child: Text('Difficulty: $d'))).toList(),
                        onChanged: (v) => setState(() => _randomDifficulty = v!),
                      ),
                      SizedBox(
                        width: 140,
                        child: TextField(
                          decoration: const InputDecoration(labelText: 'Question Count', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          controller: TextEditingController(text: _randomCount.toString()),
                          onChanged: (v) => _randomCount = int.tryParse(v) ?? 30,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isGeneratingRandom ? null : _generateRandomSelection,
                        icon: _isGeneratingRandom ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.bolt, size: 16),
                        label: const Text('[ Generate Selection ]'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A), foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 250,
                child: TextField(
                  controller: _qbSearchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search question text...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onSubmitted: (_) => _loadQuestionBank(),
                ),
              ),
              DropdownButton<String>(
                value: _qbSubjectFilter,
                items: ['All Subjects', 'Physics', 'Chemistry', 'Botany', 'Zoology', 'Mathematics'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) { setState(() => _qbSubjectFilter = v!); _loadQuestionBank(); },
              ),
              DropdownButton<String>(
                value: _qbDifficultyFilter,
                items: ['All', 'easy', 'medium', 'hard'].map((d) => DropdownMenuItem(value: d, child: Text('Diff: $d'))).toList(),
                onChanged: (v) { setState(() => _qbDifficultyFilter = v!); _loadQuestionBank(); },
              ),
              ElevatedButton.icon(
                onPressed: _loadQuestionBank,
                icon: const Icon(Icons.filter_alt, size: 16),
                label: const Text('Filter'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        for (var item in _qbResultsList) {
                          final id = (item['id'] ?? '').toString();
                          if (id.isNotEmpty) {
                            _selectedQbQuestionIds.add(id);
                            if (!_selectedQbQuestionsList.any((q) => q['id'] == id)) {
                              _selectedQbQuestionsList.add(item);
                            }
                          }
                        }
                      });
                    },
                    child: const Text('[ Select All Page ]'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedQbQuestionIds.clear();
                        _selectedQbQuestionsList.clear();
                      });
                    },
                    child: const Text('[ Clear ]'),
                  ),
                ],
              ),
              Row(
                children: [
                  Text('Selected: ${_selectedQbQuestionsList.length} / 180 Questions', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF4F46E5))),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _selectedQbQuestionsList.isEmpty
                        ? null
                        : () {
                            int added = 0;
                            int dups = 0;
                            final Set<String> existingIds = _testSeriesSelectedQuestions.map((q) => q['id'].toString()).toSet();
                            for (var item in _selectedQbQuestionsList) {
                              final id = item['id'].toString();
                              final Map<String, dynamic> qMap = Map<String, dynamic>.from(item);
                              qMap['source_badge'] = '[QUESTION BANK]';
                              if (existingIds.contains(id)) {
                                dups++;
                              } else {
                                existingIds.add(id);
                                _testSeriesSelectedQuestions.add(qMap);
                                added++;
                              }
                            }
                            setState(() => _duplicatesRemovedCount += dups);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('✓ Added $added questions to Test Series!' + (dups > 0 ? ' ($dups duplicate questions removed.)' : '')),
                                backgroundColor: const Color(0xFF10B981),
                              ),
                            );
                          },
                    icon: const Icon(Icons.add_task, size: 16),
                    label: const Text('[ Add Selected Questions ]'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_isLoadingQb)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
          else if (_qbResultsList.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text('No questions found in Question Bank.', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)))),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _qbResultsList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = _qbResultsList[index];
                final qId = (item['id'] ?? '').toString();
                final text = item['question_text'] ?? item['questionText'] ?? '';
                final subject = item['subject'] ?? 'Physics';
                final isSelected = _selectedQbQuestionIds.contains(qId);

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isSelected ? const Color(0xFF10B981) : const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: isSelected,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedQbQuestionIds.add(qId);
                              if (!_selectedQbQuestionsList.any((q) => q['id'] == qId)) _selectedQbQuestionsList.add(item);
                            } else {
                              _selectedQbQuestionIds.remove(qId);
                              _selectedQbQuestionsList.removeWhere((q) => q['id'] == qId);
                            }
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(4)),
                                  child: Text(subject, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF4F46E5))),
                                ),
                                const SizedBox(width: 8),
                                Text('ID: ${qId.length > 8 ? qId.substring(0, 8) : qId}', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
                              ],
                            ),
                            const SizedBox(height: 4),
                            LaTeXView(text: text, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1E293B))),
                          ],
                        ),
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

  Widget _buildPaperSummaryAndOrderView() {
    final int pyqCount = _testSeriesSelectedQuestions.where((q) => (q['source_badge'] ?? '').toString().contains('[PYQ]')).length;
    final int ntaCount = _testSeriesSelectedQuestions.where((q) => (q['source_badge'] ?? '').toString().contains('[NTA]')).length;
    final int qbCount = _testSeriesSelectedQuestions.length - pyqCount - ntaCount;
    final int totalCount = _testSeriesSelectedQuestions.length;

    final int phyCount = _testSeriesSelectedQuestions.where((q) => (q['subject'] ?? '').toString().toLowerCase() == 'physics').length;
    final int chemCount = _testSeriesSelectedQuestions.where((q) => (q['subject'] ?? '').toString().toLowerCase() == 'chemistry').length;
    final int botCount = _testSeriesSelectedQuestions.where((q) => ['botany', 'biology'].contains((q['subject'] ?? '').toString().toLowerCase())).length;
    final int zooCount = _testSeriesSelectedQuestions.where((q) => (q['subject'] ?? '').toString().toLowerCase() == 'zoology').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('PAPER CONTENT SUMMARY', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                  if (_duplicatesRemovedCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(12)),
                      child: Text('$_duplicatesRemovedCount duplicate questions removed', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFDC2626))),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildSummaryBadge('PYQ Questions', pyqCount, const Color(0xFFDCFCE7), const Color(0xFF15803D)),
                  const SizedBox(width: 12),
                  _buildSummaryBadge('NTA Questions', ntaCount, const Color(0xFFE0E7FF), const Color(0xFF4F46E5)),
                  const SizedBox(width: 12),
                  _buildSummaryBadge('Question Bank', qbCount, const Color(0xFFFEF3C7), const Color(0xFFD97706)),
                  const SizedBox(width: 12),
                  _buildSummaryBadge('Total Selected', totalCount, const Color(0xFF0F172A), Colors.white),
                ],
              ),
              const SizedBox(height: 20),

              Text('Subject Distribution Target (NEET 180 Questions)', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildSubjectTargetChip('Physics', phyCount, 45),
                  _buildSubjectTargetChip('Chemistry', chemCount, 45),
                  _buildSubjectTargetChip('Botany', botCount, 45),
                  _buildSubjectTargetChip('Zoology', zooCount, 45),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: _allowIncompletePaper,
                    onChanged: (val) => setState(() => _allowIncompletePaper = val ?? false),
                  ),
                  const Text('Allow incomplete paper (create even if total questions < target 180)'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Question Order (${_testSeriesSelectedQuestions.length} Questions)', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _autoArrangeQuestionsBySubject,
                        icon: const Icon(Icons.sort_by_alpha, size: 16),
                        label: const Text('Auto Arrange (Subject-wise)'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _randomizeSelectedQuestionsOrder,
                        icon: const Icon(Icons.shuffle, size: 16),
                        label: const Text('Randomize Order'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _finalizeAndCreateTestSeriesPaper,
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: const Text('[ Create Test Paper ]'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_testSeriesSelectedQuestions.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
                  child: Center(child: Text('No questions added yet. Use PYQ, NTA, or Question Bank tabs to add questions.', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)))),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _testSeriesSelectedQuestions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = _testSeriesSelectedQuestions[index];
                    final badge = (item['source_badge'] ?? '[QUESTION BANK]').toString();
                    final text = item['question_text'] ?? item['questionText'] ?? '';

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: const Color(0xFF4F46E5),
                            child: Text('${index + 1}', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(4)),
                            child: Text(badge, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF4F46E5))),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: LaTeXView(text: text, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1E293B)))),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_upward, size: 16),
                                onPressed: index > 0
                                    ? () {
                                        setState(() {
                                          final item = _testSeriesSelectedQuestions.removeAt(index);
                                          _testSeriesSelectedQuestions.insert(index - 1, item);
                                        });
                                      }
                                    : null,
                              ),
                              IconButton(
                                icon: const Icon(Icons.arrow_downward, size: 16),
                                onPressed: index < _testSeriesSelectedQuestions.length - 1
                                    ? () {
                                        setState(() {
                                          final item = _testSeriesSelectedQuestions.removeAt(index);
                                          _testSeriesSelectedQuestions.insert(index + 1, item);
                                        });
                                      }
                                    : null,
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _testSeriesSelectedQuestions.removeAt(index);
                                  });
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
        ),
      ],
    );
  }

  Widget _buildSummaryBadge(String label, int count, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: textColor)),
          Text('$count', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildSubjectTargetChip(String subject, int current, int target) {
    final bool isSatisfied = current >= target;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isSatisfied ? const Color(0xFFDCFCE7) : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isSatisfied ? const Color(0xFF16A34A) : const Color(0xFFF97316)),
      ),
      child: Text('$subject: $current / $target', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: isSatisfied ? const Color(0xFF15803D) : const Color(0xFFC2410C))),
    );
  }

  Widget _buildUploadQuestionsTabContent() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_upload_outlined, size: 50, color: Color(0xFF4F46E5)),
          const SizedBox(height: 12),
          Text('Upload Question Paper PDF / Excel / JSON', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
          const SizedBox(height: 6),
          Text('Import new external questions file directly into this paper.', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PDF / Excel Bulk Import is active in Admin PDF Import menu.')),
              );
            },
            icon: const Icon(Icons.file_present),
            label: const Text('Select File to Import'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 1. TOP ADMIN HEADER BAR
  // ===========================================================================
  Widget _buildTopAdminHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Brand Logo
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'Cosmyra Edu Admin',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
              ),
            ],
          ),

          // User Profile & Notification Actions
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Icon(Icons.notifications_none_rounded, color: Color(0xFF64748B), size: 20),
                  ),
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text('12', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 14,
                      backgroundColor: Color(0xFF4F46E5),
                      child: Icon(Icons.person, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Admin User', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                        Text('Super Admin', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500, color: const Color(0xFF64748B))),
                      ],
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B), size: 18),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. BREADCRUMBS
  // ===========================================================================
  Widget _buildBreadcrumb() {
    return Row(
      children: [
        Text('Question & Paper Bank', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF64748B))),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFF94A3B8)),
        ),
        Text('Upload Questions', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
      ],
    );
  }

  // ===========================================================================
  // 3. TITLE & ACTION HEADER ROW
  // ===========================================================================
  Widget _buildTitleHeaderRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload Questions in Bulk - Step 2 of 2',
              style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A), letterSpacing: -0.4),
            ),
            const SizedBox(height: 4),
            Text(
              'Add all questions for ${widget.paperName}. Total ${widget.totalQuestionsCount} questions.',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, color: const Color(0xFF64748B)),
            ),
          ],
        ),
        Row(
          children: [
            // Back to Step 1 Button
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => AdminBulkUploadStep1Screen(userProfile: widget.userProfile)),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF334155),
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.arrow_back_rounded, size: 16, color: Color(0xFF334155)),
              label: Text('Back to Step 1', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 12),            // Save All Questions Primary Button
            ElevatedButton.icon(
              onPressed: () => _saveCurrentBatch(showToast: true),
              icon: _isSavingBatch
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.cloud_upload_rounded, size: 16, color: Colors.white),
              label: Text(
                _isSavingBatch ? 'Saving...' : 'Save All Questions',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // 4. STEPPER INDICATOR BAR
  // ===========================================================================
  Widget _buildStepperBar() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Row(
          children: [
            // Step 1: Paper Details (Completed Checkmark)
            Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF4F46E5), width: 2),
                  ),
                  child: const Icon(Icons.check_rounded, color: Color(0xFF4F46E5), size: 20),
                ),
                const SizedBox(height: 6),
                Text('Paper Details', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF4F46E5))),
              ],
            ),

            // Dashed Line Connector
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: CustomPaint(
                  painter: DashedLinePainter(color: const Color(0xFF4F46E5)),
                  child: const SizedBox(height: 2),
                ),
              ),
            ),

            // Step 2: Add Questions (Active Solid Circle 2)
            Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4F46E5),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('2', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 6),
                Text('Add Questions', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF4F46E5))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<int> get _pendingQuestionNumbers {
    return _questionsList.where((q) => !q.isSaved).map((q) => q.number).toList();
  }

  void _jumpToQuestion(int qNum) {
    if (qNum < 1 || qNum > _questionsList.length) return;
    final targetPage = ((qNum - 1) ~/ _itemsPerPage) + 1;
    setState(() {
      _jumpToQuestionNumber = qNum;
      _currentPageIndex = targetPage;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Jumped to Question $qNum (Page $targetPage)'),
        backgroundColor: const Color(0xFF4F46E5),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // ===========================================================================
  // 5. KPI SUMMARY METRIC CARD
  // ===========================================================================
  Widget _buildKPISummaryCard(int remainingCount, double progressPercent) {
    final pendingNums = _pendingQuestionNumbers;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Total Questions
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Questions', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                    const SizedBox(height: 4),
                    Text('${widget.totalQuestionsCount}', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: const Color(0xFFF1F5F9)),

              // Added
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Added', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                      const SizedBox(height: 4),
                      Text('$_addedCount', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                    ],
                  ),
                ),
              ),
              Container(width: 1, height: 40, color: const Color(0xFFF1F5F9)),

              // Remaining
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Remaining', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                      const SizedBox(height: 4),
                      Text('$remainingCount', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: remainingCount > 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A))),
                    ],
                  ),
                ),
              ),
              Container(width: 1, height: 40, color: const Color(0xFFF1F5F9)),

              // Progress
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Progress', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                      const SizedBox(height: 4),
                      Text('${(progressPercent * 100).toInt()}%', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progressPercent,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFF1F5F9),
                          valueColor: AlwaysStoppedAnimation<Color>(remainingCount == 0 ? const Color(0xFF10B981) : const Color(0xFF4F46E5)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Pending Question Numbers Section
          if (pendingNums.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Questions Still Pending Upload (${pendingNums.length}):',
                        style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF991B1B)),
                      ),
                      const Spacer(),
                      Text(
                        'Click any question number to jump directly to it ➔',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFB91C1C)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ...pendingNums.take(30).map((qNum) {
                        return InkWell(
                          onTap: () => _jumpToQuestion(qNum),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFEF4444)),
                              boxShadow: const [
                                BoxShadow(color: Color(0x1AEF4444), blurRadius: 4, offset: Offset(0, 1)),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Q$qNum',
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFDC2626)),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFFDC2626)),
                              ],
                            ),
                          ),
                        );
                      }),
                      if (pendingNums.length > 30)
                        Padding(
                          padding: const EdgeInsets.only(left: 6, top: 4),
                          child: Text(
                            '+${pendingNums.length - 30} more pending...',
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF991B1B)),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '✓ Great job! All ${widget.totalQuestionsCount} questions have been successfully filled and saved!',
                    style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF065F46)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // 6. FILTER / JUMP TOOLBAR BAR
  // ===========================================================================
  Widget _buildFilterToolbarBar() {
    final pendingNums = _pendingQuestionNumbers;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Jump to Question & Go To
          Row(
            children: [
              Text('Jump to Question', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
              const SizedBox(width: 12),
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _jumpToQuestionNumber,
                    items: List.generate(
                      _questionsList.length,
                      (index) => DropdownMenuItem<int>(
                        value: index + 1,
                        child: Text('${index + 1}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
                      ),
                    ),
                    onChanged: (val) {
                      if (val != null) setState(() => _jumpToQuestionNumber = val);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _jumpToQuestion(_jumpToQuestionNumber),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEEF2FF),
                  foregroundColor: const Color(0xFF4F46E5),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Go to', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              if (pendingNums.isNotEmpty) ...[
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => _jumpToQuestion(pendingNums.first),
                  icon: const Icon(Icons.bolt_rounded, size: 14, color: Colors.white),
                  label: Text(
                    '⚡ Next Pending: Q${pendingNums.first}',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ],
          ),

          // Show X per page, Bulk Actions & Auto Save ON
          Row(
            children: [
              Text('Show', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
              const SizedBox(width: 8),
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _itemsPerPage,
                    items: const [
                      DropdownMenuItem(value: 5, child: Text('5 per page')),
                      DropdownMenuItem(value: 10, child: Text('10 per page')),
                      DropdownMenuItem(value: 20, child: Text('20 per page')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _itemsPerPage = val);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),

              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: 'Bulk Actions',
                    items: const [
                      DropdownMenuItem(value: 'Bulk Actions', child: Text('Bulk Actions')),
                      DropdownMenuItem(value: 'Clear All', child: Text('Clear All')),
                      DropdownMenuItem(value: 'Delete Selected', child: Text('Delete Selected')),
                    ],
                    onChanged: (val) {},
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // ⚡ 1-Click Bulk Option Set Popup Menu Button
              PopupMenuButton<String>(
                tooltip: 'Bulk set options for all questions in 1-click',
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFC7D2FE)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFF4F46E5)),
                      const SizedBox(width: 6),
                      Text(
                        '⚡ 1-Click Options (All)',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF4F46E5)),
                      ),
                      const Icon(Icons.arrow_drop_down_rounded, size: 18, color: Color(0xFF4F46E5)),
                    ],
                  ),
                ),
                onSelected: (val) => _applyOptionPresetToAllQuestions(val),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: '1_2_3_4',
                    child: Text('⚡ Set All Questions: A=1, B=2, C=3, D=4'),
                  ),
                  const PopupMenuItem(
                    value: 'A_B_C_D',
                    child: Text('⚡ Set All Questions: A=A, B=B, C=C, D=D'),
                  ),
                  const PopupMenuItem(
                    value: '(1)_(2)_(3)_(4)',
                    child: Text('⚡ Set All Questions: A=(1), B=(2), C=(3), D=(4)'),
                  ),
                  const PopupMenuItem(
                    value: '(A)_(B)_(C)_(D)',
                    child: Text('⚡ Set All Questions: A=(A), B=(B), C=(C), D=(D)'),
                  ),
                  const PopupMenuItem(
                    value: 'sync_visibility',
                    child: Text('⚡ Sync All Questions Visibility to Test Series Default'),
                  ),
                  const PopupMenuItem(
                    value: 'blank',
                    child: Text('Clear All Option Text'),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Auto Save ON Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('Auto Save ', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF065F46))),
                    Text('ON', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF047857))),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 7. QUESTION CARDS GENERATOR
  // ===========================================================================
  List<Widget> _buildVisibleQuestionCards(bool isDesktop) {
    final int startIndex = (_currentPageIndex - 1) * _itemsPerPage;
    final int endIndex = (startIndex + _itemsPerPage < _questionsList.length)
        ? startIndex + _itemsPerPage
        : _questionsList.length;

    final List<Widget> cards = [];

    for (int i = startIndex; i < endIndex; i++) {
      cards.add(_buildQuestionCard(_questionsList[i], i, isDesktop));
      cards.add(const SizedBox(height: 20));
    }

    return cards;
  }

  Widget _buildQuestionCard(QuestionItemData q, int index, bool isDesktop) {
    return Container(
      key: ValueKey('q_card_${q.number}_${q.uniqueId}'),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar of Question Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14)),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Question ${q.number}',
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF4F46E5)),
                    ),
                    if (q.isSaved) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF10B981)),
                            const SizedBox(width: 4),
                            Text(
                              'Saved to Question Bank',
                              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF065F46)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                Row(
                  children: [
                    // 👁️ Live Student View Button
                    InkWell(
                      onTap: () {
                        setState(() {
                          q.showLivePreview = !q.showLivePreview;
                        });
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: q.showLivePreview ? const Color(0xFF4F46E5) : const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: q.showLivePreview ? const Color(0xFF4F46E5) : const Color(0xFFC7D2FE)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              q.showLivePreview ? Icons.edit_note_rounded : Icons.remove_red_eye_rounded,
                              size: 14,
                              color: q.showLivePreview ? Colors.white : const Color(0xFF4F46E5),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              q.showLivePreview ? 'Edit Question' : '👁️ Student View',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: q.showLivePreview ? Colors.white : const Color(0xFF4F46E5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.open_in_new_rounded, color: Color(0xFF4F46E5), size: 18),
                      onPressed: () => _showQuestionLivePreviewDialog(q),
                      tooltip: 'Open Full Student Preview Modal',
                    ),
                    IconButton(
                      icon: Icon(
                        q.isCollapsed ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded,
                        color: const Color(0xFF64748B),
                        size: 20,
                      ),
                      onPressed: () => setState(() => q.isCollapsed = !q.isCollapsed),
                      tooltip: 'Collapse',
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, color: Color(0xFF64748B), size: 18),
                      onPressed: () => _duplicateQuestion(index),
                      tooltip: 'Duplicate Question',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
                      onPressed: () => _deleteQuestion(index),
                      tooltip: 'Delete Question',
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (!q.isCollapsed)
            Padding(
              padding: const EdgeInsets.all(20),
              child: q.showLivePreview
                  ? _buildStudentLivePreviewContent(q)
                  : isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Column (~65%)
                            Expanded(
                              flex: 65,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildQuestionRichTextInput(q),
                                  const SizedBox(height: 24),
                                  _buildOptionsListSection(q),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            Container(width: 1, height: 520, color: const Color(0xFFF1F5F9)),
                            const SizedBox(width: 24),

                            // Right Column (~35%)
                            Expanded(
                              flex: 35,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildRightColumnDetails(q),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildQuestionRichTextInput(q),
                            const SizedBox(height: 24),
                            _buildOptionsListSection(q),
                            const Divider(height: 32),
                            _buildRightColumnDetails(q),
                          ],
                        ),
            ),

          // Footer Bar of Question Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14)),
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Mark for Review Checkbox
                InkWell(
                  onTap: () => setState(() => q.isMarkedForReview = !q.isMarkedForReview),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: q.isMarkedForReview,
                          onChanged: (val) => setState(() => q.isMarkedForReview = val ?? false),
                          activeColor: const Color(0xFF4F46E5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Mark for Review', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
                    ],
                  ),
                ),

                // Save Buttons
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () async {
                        await _saveSingleQuestion(q);
                        if (index < _questionsList.length - 1) {
                          final nextQNum = q.number + 1;
                          final nextPageIndex = ((nextQNum - 1) ~/ _itemsPerPage) + 1;
                          setState(() => _currentPageIndex = nextPageIndex);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF334155),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('Save & Next', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 10),

                    ElevatedButton(
                      onPressed: () async {
                        await _saveSingleQuestion(q);
                        if (index < _questionsList.length - 1) {
                          final nextQNum = q.number + 1;
                          final nextPageIndex = ((nextQNum - 1) ~/ _itemsPerPage) + 1;
                          setState(() => _currentPageIndex = nextPageIndex);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Row(
                        children: [
                          Text('Save & Next', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
                        ],
                      ),
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

  // ===========================================================================
  // 1. QUESTION RICH TEXT EDITOR INPUT (LEFT COLUMN)
  // ===========================================================================
  Widget _buildQuestionRichTextInput(QuestionItemData q) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('1. Question ', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
            Text('*', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red)),
          ],
        ),
        const SizedBox(height: 8),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Column(
            children: [
              // Rich Text Editor Toolbar Row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildEditorIcon('B', isBold: true),
                        _buildEditorIcon('I', isItalic: true),
                        _buildEditorIcon('U', isUnderline: true),
                        const SizedBox(width: 8),
                        _buildEditorIconIcon(Icons.format_list_bulleted_rounded),
                        _buildEditorIconIcon(Icons.format_list_numbered_rounded),
                        const SizedBox(width: 8),
                        _buildEditorIconText('x₂'),
                        _buildEditorIconText('x²'),
                        const SizedBox(width: 8),
                        _buildEditorIconIcon(Icons.image_outlined),
                      ],
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _pickAndUploadQuestionImage(q),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF334155),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      icon: q.isUploadingQuestionImage
                          ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5))
                          : const Icon(Icons.add_photo_alternate_outlined, size: 14, color: Color(0xFF475569)),
                      label: Text(
                        q.isUploadingQuestionImage ? 'Uploading...' : (q.questionImage != null && q.questionImage!.isNotEmpty ? 'Change Image' : 'Add Image'),
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

              // Question Image Preview
              if (q.questionImage != null && q.questionImage!.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SmartImage(
                            url: q.questionImage,
                            height: 70,
                            width: 100,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Question Image attached',
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () => _pickAndUploadQuestionImage(q),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: Size.zero),
                          child: const Text('Replace', style: TextStyle(fontSize: 10)),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                          onPressed: () => setState(() => q.questionImage = null),
                          tooltip: 'Remove Image',
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Textarea
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextFormField(
                  key: ValueKey('q_text_${q.number}_${q.uniqueId}'),
                  initialValue: q.text,
                  maxLines: 4,
                  onChanged: (val) {
                    q.text = val;
                    _scheduleAutoSave(q);
                  },
                  decoration: const InputDecoration(
                    hintText: 'Type or paste your question here...',
                    hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF0F172A)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditorIcon(String text, {bool isBold = false, bool isItalic = false, bool isUnderline = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
          decoration: isUnderline ? TextDecoration.underline : TextDecoration.none,
          color: const Color(0xFF475569),
        ),
      ),
    );
  }

  Widget _buildEditorIconIcon(IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Icon(icon, size: 16, color: const Color(0xFF475569)),
    );
  }

  Widget _buildEditorIconText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(text, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
    );
  }

  // ===========================================================================
  // 2. OPTIONS LIST SECTION (LEFT COLUMN)
  // ===========================================================================
  Widget _buildOptionsListSection(QuestionItemData q) {
    final optionLetters = ['A', 'B', 'C', 'D', 'E', 'F'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: [
                Text('2. Options ', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                Text('*', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red)),
                const SizedBox(width: 4),
                _buildQuickOptionPresetPill(q, ['1', '2', '3', '4'], '1,2,3,4'),
                _buildQuickOptionPresetPill(q, ['A', 'B', 'C', 'D'], 'A,B,C,D'),
                _buildQuickOptionPresetPill(q, ['(1)', '(2)', '(3)', '(4)'], '(1),(2),(3),(4)'),
                _buildQuickOptionPresetPill(q, ['(A)', '(B)', '(C)', '(D)'], '(A),(B),(C),(D)'),
              ],
            ),
            Text('Is Correct?', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
          ],
        ),
        const SizedBox(height: 10),

        ...List.generate(q.options.length, (optIdx) {
          while (q.optionImages.length < q.options.length) q.optionImages.add(null);
          while (q.isUploadingOptionImage.length < q.options.length) q.isUploadingOptionImage.add(false);

          final letter = optionLetters[optIdx];
          final isSelected = (q.correctOptionIndex == optIdx);
          final optImg = q.optionImages[optIdx];
          final isUploadingOpt = q.isUploadingOptionImage[optIdx];

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Option Letter Badge (A, B, C, D)
                    Container(
                      width: 34,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8)),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Center(
                        child: Text(letter, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF334155))),
                      ),
                    ),

                    // Option Input Field
                    Expanded(
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: TextFormField(
                          key: ValueKey('q_opt_${q.number}_${q.uniqueId}_$optIdx'),
                          initialValue: q.options[optIdx],
                          onChanged: (val) {
                            q.options[optIdx] = val;
                            _scheduleAutoSave(q);
                          },
                          decoration: InputDecoration(
                            hintText: 'Enter option $letter (or add image)',
                            hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF0F172A)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Add Image Control for Option
                    IconButton(
                      icon: isUploadingOpt
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 1.5))
                          : Icon(
                              optImg != null && optImg.isNotEmpty ? Icons.image_rounded : Icons.add_photo_alternate_outlined,
                              color: optImg != null && optImg.isNotEmpty ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                              size: 20,
                            ),
                      onPressed: () => _pickAndUploadOptionImage(q, optIdx),
                      tooltip: 'Add / Replace Image for Option $letter',
                    ),
                    const SizedBox(width: 8),

                    // Is Correct Radio Button
                    Radio<int>(
                      value: optIdx,
                      groupValue: q.correctOptionIndex,
                      activeColor: const Color(0xFF4F46E5),
                      onChanged: (val) {
                        setState(() => q.correctOptionIndex = val ?? -1);
                        _scheduleAutoSave(q);
                      },
                    ),
                  ],
                ),

                // Option Image Preview Thumbnail
                if (optImg != null && optImg.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 36, bottom: 6),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: SmartImage(
                              url: optImg,
                              height: 45,
                              width: 60,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('Option $letter Image', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => _pickAndUploadOptionImage(q, optIdx),
                            child: Text('Replace', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB))),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => setState(() => q.optionImages[optIdx] = null),
                            child: const Icon(Icons.close_rounded, size: 14, color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),

        const SizedBox(height: 6),

        // Add Option Button
        OutlinedButton.icon(
          onPressed: () => _addOptionToQuestion(q),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF4F46E5),
            backgroundColor: const Color(0xFFEEF2FF),
            side: BorderSide.none,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: const Icon(Icons.add_rounded, size: 16, color: Color(0xFF4F46E5)),
          label: Text('Add Option', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  // ===========================================================================
  // RIGHT COLUMN DETAILS (CORRECT ANSWER, EXPLANATION, DIFFICULTY, MARKS, TYPE, TOPIC)
  // ===========================================================================
  Widget _buildRightColumnDetails(QuestionItemData q) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 3. Correct Answer
        Row(
          children: [
            Text('3. Correct Answer ', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
            Text('*', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red)),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: q.correctOptionIndex == -1 ? null : q.correctOptionIndex,
              hint: Text('Select Correct Option', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
              isExpanded: true,
              items: List.generate(
                q.options.length,
                (idx) => DropdownMenuItem<int>(
                  value: idx,
                  child: Text('Option ${['A', 'B', 'C', 'D', 'E', 'F'][idx]}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
              onChanged: (val) {
                setState(() => q.correctOptionIndex = val ?? -1);
                _scheduleAutoSave(q);
              },
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 4. Explanation (Optional) & Solution Video
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text('4. Explanation & Video Solution ', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                Text('(Optional)', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF64748B))),
              ],
            ),
            OutlinedButton.icon(
              onPressed: () => _pickAndUploadSolutionVideo(q),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF4F46E5),
                backgroundColor: const Color(0xFFEEF2FF),
                side: const BorderSide(color: Color(0xFFC7D2FE)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              icon: q.isUploadingSolutionVideo
                  ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF4F46E5)))
                  : const Icon(Icons.video_call_rounded, size: 15, color: Color(0xFF4F46E5)),
              label: Text(
                q.isUploadingSolutionVideo
                    ? 'Uploading...'
                    : (q.solutionVideoUrl != null && q.solutionVideoUrl!.isNotEmpty ? 'Change Video File' : 'Upload Video File'),
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF4F46E5)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: TextFormField(
              key: ValueKey('q_exp_${q.number}_${q.uniqueId}'),
              initialValue: q.explanation,
              maxLines: 3,
              onChanged: (val) {
                q.explanation = val;
                _scheduleAutoSave(q);
              },
              decoration: const InputDecoration(
                hintText: 'Explain why this is the correct answer...',
                hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                isDense: true,
              ),
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF0F172A)),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Video URL Input Field
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.link_rounded, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    key: ValueKey('q_vidurl_${q.number}_${q.uniqueId}'),
                    initialValue: q.solutionVideoUrl ?? '',
                    onChanged: (val) {
                      setState(() {
                        q.solutionVideoUrl = val.trim();
                      });
                      _scheduleAutoSave(q);
                    },
                    decoration: const InputDecoration(
                      hintText: 'Or enter Solution Video URL (MP4, YouTube, Vimeo, Supabase)...',
                      hintStyle: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF0F172A)),
                  ),
                ),
                if (q.solutionVideoUrl != null && q.solutionVideoUrl!.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFFEF4444)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Remove video',
                    onPressed: () {
                      setState(() {
                        q.solutionVideoUrl = null;
                      });
                      _scheduleAutoSave(q);
                    },
                  ),
              ],
            ),
          ),
        ),

        // Live Video Player Preview
        if (q.solutionVideoUrl != null && q.solutionVideoUrl!.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.play_circle_fill, color: Color(0xFF4F46E5), size: 16),
                        SizedBox(width: 6),
                        Text('Video Solution Preview', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                      ],
                    ),
                    InkWell(
                      onTap: () {
                        setState(() {
                          q.solutionVideoUrl = null;
                        });
                        _scheduleAutoSave(q);
                      },
                      child: const Text('Delete Video', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFEF4444))),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SolutionVideoPlayerWidget(
                  videoUrl: q.solutionVideoUrl!,
                  height: 200,
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),

        // 5. Difficulty / Toughness
        Text('5. Difficulty / Toughness', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: q.difficulty,
              isExpanded: true,
              items: ['Select Difficulty', 'Easy', 'Medium', 'Hard']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500))))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => q.difficulty = val);
                  _scheduleAutoSave(q);
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 6. Marks
        Text('6. Marks', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Positive Marks', style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                  const SizedBox(height: 4),
                  Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: TextFormField(
                      key: ValueKey('q_pos_${q.number}_${q.uniqueId}'),
                      initialValue: q.positiveMarks,
                      onChanged: (val) {
                        q.positiveMarks = val;
                        _scheduleAutoSave(q);
                      },
                      decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 10)),
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
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
                  Text('Negative Marks', style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                  const SizedBox(height: 4),
                  Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: TextFormField(
                      key: ValueKey('q_neg_${q.number}_${q.uniqueId}'),
                      initialValue: q.negativeMarks,
                      onChanged: (val) {
                        q.negativeMarks = val;
                        _scheduleAutoSave(q);
                      },
                      decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 10)),
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 7. Question Type
        Text('7. Question Type', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: q.questionType,
              isExpanded: true,
              items: ['MCQ (Single Correct)', 'Multiple Correct', 'Numerical', 'Match the Following']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500))))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => q.questionType = val);
                  _scheduleAutoSave(q);
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 8. Topic / Chapter
        Row(
          children: [
            Text('8. Topic / Chapter ', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
            Text('*', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red)),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: () {
                if (_loadedDbChapters.any((c) => c['id'].toString() == q.chapterId)) {
                  return q.chapterId;
                }
                if (_loadedDbChapters.any((c) => c['name'] == q.chapterTopic || c['name'] == q.chapter)) {
                  final m = _loadedDbChapters.firstWhere((c) => c['name'] == q.chapterTopic || c['name'] == q.chapter);
                  return m['id'].toString();
                }
                return null;
              }(),
              hint: Text(_loadedDbChapters.isNotEmpty ? (q.chapter.isNotEmpty ? q.chapter : 'Select Chapter') : 'Loading chapters...', style: GoogleFonts.inter(fontSize: 12)),
              isExpanded: true,
              items: _loadedDbChapters.map((c) {
                final String cId = c['id'].toString();
                final String cName = c['name']?.toString() ?? 'Chapter';
                return DropdownMenuItem<String>(
                  value: cId,
                  child: Text(cName, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  final matched = _loadedDbChapters.firstWhere(
                    (c) => c['id'].toString() == val,
                    orElse: () => {},
                  );
                  if (matched.isNotEmpty) {
                    setState(() {
                      q.chapterId = val;
                      q.chapterTopic = matched['name']?.toString() ?? '';
                      q.chapter = matched['name']?.toString() ?? '';
                    });
                    _scheduleAutoSave(q);
                  }
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 9. Visibility / Available In *
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('9. Visibility / Available In *', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
            InkWell(
              onTap: () {
                setState(() {
                  q.availableIn = List<String>.from(_paperDefaultAvailableIn);
                });
                _scheduleAutoSave(q);
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFC7D2FE)),
                ),
                child: Text('⚡ Use Test Series Default', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF4F46E5))),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: q.availableIn.isEmpty ? Colors.red : const Color(0xFFCBD5E1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildVisibilityChip(q, 'custom_practice', 'Custom Practice'),
                  _buildVisibilityChip(q, 'custom_test', 'Custom Test'),
                  _buildVisibilityChip(q, 'pyq_practice', 'PYQ Practice'),
                  _buildVisibilityChip(q, 'nta_questions', 'NTA Questions'),
                  _buildVisibilityChip(q, 'test_series', 'Test Series'),
                ],
              ),
              if (q.availableIn.isEmpty) ...[
                const SizedBox(height: 6),
                Text('⚠️ Select at least 1 module', style: GoogleFonts.inter(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVisibilityChip(QuestionItemData q, String key, String label) {
    final isSel = q.availableIn.contains(key);
    return FilterChip(
      label: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500)),
      selected: isSel,
      onSelected: (val) {
        setState(() {
          if (val) {
            if (!q.availableIn.contains(key)) q.availableIn.add(key);
          } else {
            q.availableIn.remove(key);
          }
        });
        _scheduleAutoSave(q);
      },
      selectedColor: const Color(0xFFE0E7FF),
      checkmarkColor: const Color(0xFF4F46E5),
      visualDensity: VisualDensity.compact,
    );
  }

  // ===========================================================================
  // 8. PAGINATION FOOTER
  // ===========================================================================
  Widget _buildPaginationFooter() {
    final int totalPages = (_questionsList.length / _itemsPerPage).ceil();

    void goToPage(int pageNum) {
      _saveCurrentBatch(showToast: false);
      setState(() => _currentPageIndex = pageNum);
    }

    final List<int> pagesToShow = [];
    int startPage = (_currentPageIndex - 2).clamp(1, totalPages);
    int endPage = (startPage + 4).clamp(1, totalPages);
    if (endPage - startPage < 4) {
      startPage = (endPage - 4).clamp(1, totalPages);
    }
    for (int p = startPage; p <= endPage; p++) {
      pagesToShow.add(p);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF64748B)),
          onPressed: _currentPageIndex > 1 ? () => goToPage(_currentPageIndex - 1) : null,
        ),
        const SizedBox(width: 8),

        ...pagesToShow.map((pageNum) {
          final isSelected = (_currentPageIndex == pageNum);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => goToPage(pageNum),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF4F46E5) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1)),
                ),
                child: Center(
                  child: Text(
                    '$pageNum',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? Colors.white : const Color(0xFF334155),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),

        if (pagesToShow.isNotEmpty && pagesToShow.last < totalPages) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('...', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
          ),

          InkWell(
            onTap: () => goToPage(totalPages),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Center(
                child: Text(
                  '$totalPages',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(width: 8),

        IconButton(
          icon: const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B)),
          onPressed: _currentPageIndex < totalPages ? () => goToPage(_currentPageIndex + 1) : null,
        ),
      ],
    );
  }

  // ===========================================================================
  // LEFT SIDEBAR (DESKTOP)
  // ===========================================================================
  Widget _buildAdminSidebar() {
    return Container(
      width: 250,
      color: const Color(0xFF0F172A),
      child: Column(
        children: [
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFF818CF8), size: 20),
                const SizedBox(width: 10),
                Text('ExamPrep Admin', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              children: [
                _buildSidebarTile('Dashboard', Icons.dashboard_outlined, false, onTap: () => Navigator.pushReplacementNamed(context, '/admin')),
                const SizedBox(height: 14),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Text('CONTENT MANAGEMENT', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                ),
                _buildSidebarTile('Exams', Icons.assignment_outlined, false),
                _buildSidebarTile('Subjects', Icons.science_outlined, false),
                _buildSidebarTile('Chapters', Icons.menu_book_outlined, false),
                _buildSidebarTile('Topics', Icons.grid_view_rounded, false),
                _buildSidebarTile('Question & Paper Bank', Icons.help_outline_rounded, true),
                _buildSidebarTile('NTA Mock Papers', Icons.description_outlined, false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarTile(String title, IconData icon, bool isActive, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF4F46E5).withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isActive ? const Color(0xFFA5B4FC) : const Color(0xFF94A3B8)),
            const SizedBox(width: 12),
            Text(title, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: isActive ? FontWeight.bold : FontWeight.w500, color: isActive ? Colors.white : const Color(0xFF94A3B8))),
          ],
        ),
      ),
    );
  }
}
