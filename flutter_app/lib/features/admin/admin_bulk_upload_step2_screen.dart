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
  bool isMarkedForReview;
  bool isCollapsed;
  bool isSaved;
  bool isUploadingQuestionImage;
  List<bool> isUploadingOptionImage;

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
    this.chapterTopic = 'Select Chapter / Topic',
    this.subject = 'Physics',
    this.chapter = 'General',
    this.topic = 'General',
    this.isMarkedForReview = false,
    this.isCollapsed = false,
    this.isSaved = false,
    this.isUploadingQuestionImage = false,
    List<bool>? isUploadingOptionImage,
  })  : options = options ?? ['', '', '', ''],
        optionImages = optionImages ?? [null, null, null, null],
        isUploadingOptionImage = isUploadingOptionImage ?? [false, false, false, false];
}

class _AdminBulkUploadStep2ScreenState extends State<AdminBulkUploadStep2Screen> {
  int _currentPageIndex = 1;
  int _itemsPerPage = 10;
  int _jumpToQuestionNumber = 1;
  int _addedCount = 0;

  late List<QuestionItemData> _questionsList;
  Map<String, dynamic>? _paperData;
  String _paperId = '';
  bool _isLoading = true;
  bool _isSavingBatch = false;

  @override
  void initState() {
    super.initState();
    _questionsList = List.generate(
      widget.totalQuestionsCount,
      (index) => QuestionItemData(number: index + 1),
    );
    _loadPaperAndSavedQuestions();
  }

  Future<void> _loadPaperAndSavedQuestions() async {
    setState(() => _isLoading = true);

    _paperData = widget.paperRecord ?? await SupabaseService.loadActiveUploadPaperSession();
    _paperId = _paperData?['id'] ?? 'paper_${DateTime.now().millisecondsSinceEpoch}';

    final int qCount = (int.tryParse(_paperData?['question_count']?.toString() ?? '') ?? widget.totalQuestionsCount).clamp(1, 1000);
    if (_questionsList.length != qCount) {
      _questionsList = List.generate(qCount, (index) => QuestionItemData(number: index + 1));
    }

    final savedQList = await SupabaseService.fetchQuestionsForPaper(_paperId);

    int savedCounter = 0;
    int firstUnsavedIndex = -1;

    for (int i = 0; i < _questionsList.length; i++) {
      final qNum = i + 1;
      final savedMatch = savedQList.firstWhere(
        (sq) => sq['question_number'] == qNum || sq['id'] == 'q_${_paperId}_$qNum',
        orElse: () => {},
      );

      if (savedMatch.isNotEmpty) {
        savedCounter++;
        final opts = savedMatch['options'] is List ? List<String>.from(savedMatch['options']) : <String>['', '', '', ''];
        while (opts.length < 4) opts.add('');

        String correctOptText = savedMatch['correct_answer'] ?? savedMatch['correctAnswer'] ?? '';
        int correctIdx = opts.indexOf(correctOptText);
        if (correctIdx == -1 && correctOptText.startsWith('Option ')) {
          int optNum = int.tryParse(correctOptText.replaceAll('Option ', '')) ?? 1;
          correctIdx = optNum - 1;
        }

        final optImgsRaw = savedMatch['option_images'] ?? savedMatch['optionImages'];
        final List<String?> optImgs = optImgsRaw is List
            ? List<String?>.from(optImgsRaw)
            : <String?>[null, null, null, null];
        while (optImgs.length < opts.length) optImgs.add(null);

        _questionsList[i] = QuestionItemData(
          id: savedMatch['id'] ?? 'q_${_paperId}_$qNum',
          number: qNum,
          text: savedMatch['question_text'] ?? savedMatch['questionText'] ?? '',
          questionImage: savedMatch['question_image'] ?? savedMatch['questionImage'],
          options: opts,
          optionImages: optImgs,
          correctOptionIndex: correctIdx >= 0 ? correctIdx : 0,
          explanation: savedMatch['explanation'] ?? '',
          difficulty: savedMatch['difficulty'] ?? 'Medium',
          positiveMarks: savedMatch['marks']?.toString() ?? '4',
          negativeMarks: savedMatch['negative_marks']?.toString() ?? '-1',
          questionType: savedMatch['q_type'] ?? savedMatch['question_type'] ?? 'MCQ (Single Correct)',
          subject: savedMatch['subject'] ?? 'Physics',
          chapter: savedMatch['chapter'] ?? 'General',
          topic: savedMatch['topic'] ?? 'General',
          chapterTopic: '${savedMatch['subject'] ?? 'Physics'} > ${savedMatch['chapter'] ?? 'General'}',
          isSaved: true,
        );
      } else {
        if (firstUnsavedIndex == -1) {
          firstUnsavedIndex = i;
        }
      }
    }

    _addedCount = savedCounter;

    if (firstUnsavedIndex != -1) {
      _currentPageIndex = (firstUnsavedIndex ~/ _itemsPerPage) + 1;
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveCurrentBatch({bool showToast = true}) async {
    if (_isSavingBatch) return;
    setState(() => _isSavingBatch = true);

    final int startIndex = (_currentPageIndex - 1) * _itemsPerPage;
    final int endIndex = (startIndex + _itemsPerPage).clamp(0, _questionsList.length);

    final List<Map<String, dynamic>> batchToSave = [];

    for (int i = startIndex; i < endIndex; i++) {
      final q = _questionsList[i];
      final bool hasContent = q.text.trim().isNotEmpty ||
          (q.questionImage != null && q.questionImage!.isNotEmpty) ||
          q.optionImages.any((img) => img != null && img.isNotEmpty);

      if (hasContent) {
        String correctAnsText = 'Option A';
        if (q.correctOptionIndex >= 0 && q.correctOptionIndex < q.options.length) {
          correctAnsText = q.options[q.correctOptionIndex].isNotEmpty
              ? q.options[q.correctOptionIndex]
              : 'Option ${String.fromCharCode(65 + q.correctOptionIndex)}';
        }

        batchToSave.add({
          'id': q.id.isNotEmpty ? q.id : 'q_${_paperId}_${q.number}',
          'questionNumber': q.number,
          'questionText': q.text,
          'questionImage': q.questionImage ?? '',
          'options': q.options,
          'optionImages': q.optionImages,
          'correctAnswer': correctAnsText,
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
          'year': int.tryParse(_paperData?['year']?.toString() ?? '2026') ?? 2026,
          'paperName': _paperData?['paper_name'] ?? _paperData?['paperName'] ?? widget.paperName,
        });
      }
    }

    if (batchToSave.isNotEmpty) {
      final success = await SupabaseService.upsertIncrementalQuestions(
        paperId: _paperId,
        questionsData: batchToSave,
      );

      if (success) {
        for (int i = startIndex; i < endIndex; i++) {
          final q = _questionsList[i];
          final bool hasContent = q.text.trim().isNotEmpty ||
              (q.questionImage != null && q.questionImage!.isNotEmpty) ||
              q.optionImages.any((img) => img != null && img.isNotEmpty);
          if (hasContent) {
            q.isSaved = true;
            q.id = 'q_${_paperId}_${q.number}';
          }
        }
        _addedCount = _questionsList.where((q) => q.isSaved).length;

        if (showToast && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ Persisted ${batchToSave.length} question(s) to Supabase Question Bank! (Saved: $_addedCount / ${_questionsList.length})'),
              backgroundColor: const Color(0xFF10B981),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }

    if (mounted) setState(() => _isSavingBatch = false);
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
                      onPressed: () {
                        setState(() => _addedCount++);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Question ${q.number} saved!'), duration: const Duration(seconds: 1)),
                        );
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
                      onPressed: () {
                        setState(() => _addedCount++);
                        if (index < _questionsList.length - 1) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Question ${q.number} saved. Moving to Question ${q.number + 1}...'), duration: const Duration(seconds: 1)),
                          );
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
        Text('1. Question', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
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
                  initialValue: q.text,
                  maxLines: 4,
                  onChanged: (val) => q.text = val,
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
            Text('2. Options', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
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
                          initialValue: q.options[optIdx],
                          onChanged: (val) => q.options[optIdx] = val,
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
                      onChanged: (val) => setState(() => q.correctOptionIndex = val ?? -1),
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
        Text('3. Correct Answer', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
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
              onChanged: (val) => setState(() => q.correctOptionIndex = val ?? -1),
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
              initialValue: q.explanation,
              maxLines: 3,
              onChanged: (val) => q.explanation = val,
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
                if (val != null) setState(() => q.difficulty = val);
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
                      initialValue: q.positiveMarks,
                      onChanged: (val) => q.positiveMarks = val,
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
                      initialValue: q.negativeMarks,
                      onChanged: (val) => q.negativeMarks = val,
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
                if (val != null) setState(() => q.questionType = val);
              },
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 8. Topic / Chapter
        Text('8. Topic / Chapter', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
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
              value: q.chapterTopic,
              isExpanded: true,
              items: ['Select Chapter / Topic', 'Physics - Kinematics', 'Physics - Laws of Motion', 'Chemistry - Organic', 'Biology - Cell Structure']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500))))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => q.chapterTopic = val);
              },
            ),
          ),
        ),
      ],
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
