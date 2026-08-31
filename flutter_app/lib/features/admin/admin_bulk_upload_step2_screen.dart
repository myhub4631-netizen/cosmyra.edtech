import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/services/supabase_service.dart';
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
  bool isUploadingQuestionImage;
  List<bool> isUploadingOptionImage;
  List<String> availableIn;

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
    this.chapterTopic = 'Physics - Kinematics',
    this.subject = 'Physics',
    this.chapter = 'Kinematics',
    this.topic = 'Kinematics',
    this.chapterId = 'b2222222-2222-2222-2222-222222222222',
    this.topicId = 'c2222222-2222-2222-2222-222222222222',
    this.subjectId = 'a1111111-1111-1111-1111-111111111111',
    this.examId = '11111111-1111-1111-1111-111111111111',
    this.isMarkedForReview = false,
    this.isCollapsed = false,
    this.isSaved = false,
    this.isUploadingQuestionImage = false,
    List<bool>? isUploadingOptionImage,
    List<String>? availableIn,
  })  : options = options != null ? List<String>.from(options) : ['', '', '', ''],
        optionImages = optionImages != null ? List<String?>.from(optionImages) : [null, null, null, null],
        isUploadingOptionImage = isUploadingOptionImage != null ? List<bool>.from(isUploadingOptionImage) : [false, false, false, false],
        availableIn = availableIn != null
            ? List<String>.from(availableIn)
            : ['custom_practice', 'custom_test', 'pyq_practice', 'nta_questions', 'test_series'];
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

  bool _hasEssentialDetails(QuestionItemData q) {
    // 1. Question text or image must be provided
    final bool hasTextOrImage = q.text.trim().isNotEmpty || (q.questionImage != null && q.questionImage!.isNotEmpty);
    if (!hasTextOrImage) return false;

    // 2. Options: At least 2 non-empty options (or option images)
    final int filledOpts = q.options.where((opt) => opt.trim().isNotEmpty).length;
    final int filledImgs = q.optionImages.where((img) => img != null && img.isNotEmpty).length;
    if ((filledOpts + filledImgs) < 2) return false;

    // 3. Correct Answer: Must have selected a valid option index (0..options.length-1)
    if (q.correctOptionIndex < 0 || q.correctOptionIndex >= q.options.length) return false;

    // 4. Chapter / Topic: Must have a chapter assigned
    if (q.chapterId.isEmpty && q.chapter.isEmpty && q.chapterTopic.isEmpty) return false;

    // 5. Visibility / Available In *: Must have at least 1 visibility tag selected
    if (q.availableIn.isEmpty) return false;

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
      (index) => QuestionItemData(number: index + 1),
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

    final String exam = _paperData?['exam'] ?? _paperData?['exam_name'] ?? 'NEET';
    final String subject = _paperData?['subject'] ?? 'Physics';

    try {
      _loadedDbChapters = await SupabaseService.fetchAllChaptersForDropdown(exam: exam, subject: subject);
    } catch (e) {
      debugPrint('Notice loading db chapters for step2: $e');
    }

    final int qCount = (int.tryParse(_paperData?['question_count']?.toString() ?? '') ?? widget.totalQuestionsCount).clamp(1, 1000);
    if (_questionsList.length != qCount) {
      _questionsList = List.generate(qCount, (index) => QuestionItemData(number: index + 1));
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

        int correctIdx = 0;
        if (savedMatch['correct_option_index'] != null) {
          correctIdx = (savedMatch['correct_option_index'] as num).toInt();
        } else if (savedMatch['correctOptionIndex'] != null) {
          correctIdx = (savedMatch['correctOptionIndex'] as num).toInt();
        } else {
          String correctOptText = (savedMatch['correct_answer'] ?? savedMatch['correctAnswer'] ?? '').toString().trim();
          if (correctOptText.startsWith('Option ')) {
            int optNum = int.tryParse(correctOptText.replaceAll('Option ', '')) ?? 1;
            correctIdx = (optNum - 1).clamp(0, opts.length > 0 ? opts.length - 1 : 0);
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
        } else if (qSubject.isNotEmpty && _loadedDbChapters.any((c) => c['subject_name']?.toString().toLowerCase() == qSubject.toLowerCase() || c['subject']?.toString().toLowerCase() == qSubject.toLowerCase())) {
          final matchedC = _loadedDbChapters.firstWhere((c) => c['subject_name']?.toString().toLowerCase() == qSubject.toLowerCase() || c['subject']?.toString().toLowerCase() == qSubject.toLowerCase());
          finalChapId = matchedC['id'].toString();
          finalChapName = matchedC['name'].toString();
        } else if (_loadedDbChapters.isNotEmpty) {
          finalChapId = _loadedDbChapters.first['id'].toString();
          finalChapName = _loadedDbChapters.first['name'].toString();
        }

        final dynamic availInRaw = savedMatch['available_in'] ?? savedMatch['availableIn'];
        final List<String> availInList = availInRaw is List
            ? List<String>.from(availInRaw)
            : <String>['custom_practice', 'custom_test', 'pyq_practice', 'nta_questions', 'test_series'];

        _questionsList[i] = QuestionItemData(
          id: savedMatch['id'] ?? 'q_${_paperId}_$qNum',
          number: qNum,
          text: rawQText,
          questionImage: savedMatch['question_image'] ?? savedMatch['questionImage'],
          options: opts,
          optionImages: optImgs,
          correctOptionIndex: correctIdx >= 0 ? correctIdx : 0,
          explanation: savedMatch['explanation'] ?? savedMatch['solution'] ?? '',
          difficulty: normDiff,
          positiveMarks: savedMatch['marks']?.toString() ?? savedMatch['positiveMarks']?.toString() ?? '4',
          negativeMarks: savedMatch['negative_marks']?.toString() ?? savedMatch['negativeMarks']?.toString() ?? '-1',
          questionType: savedMatch['q_type'] ?? savedMatch['question_type'] ?? savedMatch['qType'] ?? 'MCQ (Single Correct)',
          subject: qSubject,
          chapter: finalChapName.isNotEmpty ? finalChapName : 'General',
          topic: savedMatch['topic'] ?? finalChapName,
          chapterTopic: finalChapName.isNotEmpty ? finalChapName : 'General',
          chapterId: finalChapId.isNotEmpty ? finalChapId : (_loadedDbChapters.isNotEmpty ? _loadedDbChapters.first['id'].toString() : 'b2222222-2222-2222-2222-222222222222'),
          availableIn: availInList,
          isSaved: true,
        );
      } else {
        if (firstUnsavedIndex == -1) {
          firstUnsavedIndex = i;
        }
        if (_loadedDbChapters.isNotEmpty) {
          _questionsList[i].chapterId = _loadedDbChapters.first['id'].toString();
          _questionsList[i].chapterTopic = _loadedDbChapters.first['name'].toString();
          _questionsList[i].chapter = _loadedDbChapters.first['name'].toString();
        }
      }
    }

    _addedCount = savedCounter;

    if (firstUnsavedIndex != -1) {
      _currentPageIndex = (firstUnsavedIndex ~/ _itemsPerPage) + 1;
    }

    setState(() => _isLoading = false);
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
          'difficulty': q.difficulty,
          'marks': double.tryParse(q.positiveMarks) ?? 4.0,
          'negativeMarks': double.tryParse(q.negativeMarks) ?? 1.0,
          'qType': q.questionType,
          'subject': q.subject,
          'chapter': q.chapter,
          'topic': q.topic,
          'sourceType': _paperData?['source_category'] ?? _paperData?['sourceCategory'] ?? 'PYQ',
          'exam': _paperData?['exam'] ?? _paperData?['exam_name'] ?? 'NEET',
          'year': _paperData?['year']?.toString() ?? '2026',
          'paperName': _paperData?['paper_name'] ?? _paperData?['paperName'] ?? widget.paperName,
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
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
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
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
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
                            const SizedBox(height: 24),

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

  // ===========================================================================
  // 5. KPI SUMMARY METRIC CARD
  // ===========================================================================
  Widget _buildKPISummaryCard(int remainingCount, double progressPercent) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
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
                  Text('$remainingCount', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
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
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 6. FILTER / JUMP TOOLBAR BAR
  // ===========================================================================
  Widget _buildFilterToolbarBar() {
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
                onPressed: () {
                  final targetPage = ((_jumpToQuestionNumber - 1) ~/ _itemsPerPage) + 1;
                  setState(() => _currentPageIndex = targetPage);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEEF2FF),
                  foregroundColor: const Color(0xFF4F46E5),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Go to', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
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
              child: isDesktop
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
                          child: Image.network(
                            q.questionImage!,
                            height: 70,
                            width: 100,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, color: Colors.grey),
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
                  key: ValueKey('q_text_${q.id}'),
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
            Row(
              children: [
                Text('2. Options ', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                Text('*', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red)),
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
                          key: ValueKey('q_opt_${q.id}_$optIdx'),
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
                            child: Image.network(
                              optImg,
                              height: 45,
                              width: 60,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, color: Colors.grey, size: 20),
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

        // 4. Explanation (Optional)
        Row(
          children: [
            Text('4. Explanation ', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
            Text('(Optional)', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF64748B))),
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
              key: ValueKey('q_exp_${q.id}'),
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
                      key: ValueKey('q_pos_${q.id}'),
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
                      key: ValueKey('q_neg_${q.id}'),
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
        Text('9. Visibility / Available In *', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
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

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF64748B)),
          onPressed: _currentPageIndex > 1 ? () => goToPage(_currentPageIndex - 1) : null,
        ),
        const SizedBox(width: 8),

        ...List.generate(5, (idx) {
          final pageNum = idx + 1;
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

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('...', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
        ),

        // Page 20 / Total Pages
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
