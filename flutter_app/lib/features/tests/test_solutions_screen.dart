import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/models.dart';
import '../../shared/widgets/latex_view.dart';
import '../../shared/widgets/smart_image.dart';
import '../../shared/widgets/solution_video_player.dart';
import '../../shared/utils/question_copy_helper.dart';
import '../../shared/utils/neet_subject_helper.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/analytics_service.dart';

enum SolutionFilterType { all, correct, incorrect, skipped, review }

class TestSolutionsScreen extends StatefulWidget {
  final TestAttemptModel attempt;
  final List<QuestionModel> questions;
  final Map<int, String> userAnswers;
  final VoidCallback onBack;
  final List<TestAttemptModel>? allAttempts;
  final int initialQuestionIndex;

  const TestSolutionsScreen({
    super.key,
    required this.attempt,
    required this.questions,
    required this.userAnswers,
    required this.onBack,
    this.allAttempts,
    this.initialQuestionIndex = 0,
  });

  @override
  State<TestSolutionsScreen> createState() => _TestSolutionsScreenState();
}

class _TestSolutionsScreenState extends State<TestSolutionsScreen> {
  late TestAttemptModel _currentAttempt;
  late Map<int, String> _currentUserAnswers;
  List<TestAttemptModel> _availableAttempts = [];
  int _selectedAttemptIndex = 0;

  SolutionFilterType _activeFilter = SolutionFilterType.all;
  String _selectedSection = 'All Sections';
  late List<String> _availableSections;

  int _selectedQuestionOriginalIndex = 0;
  final Set<String> _bookmarkedQuestionIds = {};
  final Set<int> _reviewIndices = {};

  final List<Map<int, String>> _peerAnswers = [];

  final ScrollController _paletteScrollController = ScrollController();
  final ScrollController _contentScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logSolutionView(
      testId: widget.attempt.testTemplateId.isNotEmpty ? widget.attempt.testTemplateId : widget.attempt.id,
      paperName: widget.attempt.testTitle.isNotEmpty ? widget.attempt.testTitle : 'Practice Test',
    );
    _currentAttempt = widget.attempt;
    _currentUserAnswers = Map<int, String>.from(widget.userAnswers);
    _selectedQuestionOriginalIndex = widget.initialQuestionIndex.clamp(0, (widget.questions.length - 1).clamp(0, 9999));

    if (widget.allAttempts != null && widget.allAttempts!.isNotEmpty) {
      _availableAttempts = List<TestAttemptModel>.from(widget.allAttempts!);
      final idx = _availableAttempts.indexWhere((a) => a.id == _currentAttempt.id);
      _selectedAttemptIndex = idx != -1 ? idx : 0;
    } else {
      _availableAttempts = [_currentAttempt];
      _loadAllAttempts();
    }

    _initSections();
    _loadBookmarks();
    _loadPeerAnswers();
    _findFirstValidQuestionIndex();
  }

  @override
  void dispose() {
    _paletteScrollController.dispose();
    _contentScrollController.dispose();
    super.dispose();
  }

  void _initSections() {
    final isJee = _currentAttempt.testTitle.toLowerCase().contains('jee');
    final subs = <String>{};
    for (int i = 0; i < widget.questions.length; i++) {
      final q = widget.questions[i];
      final sub = NeetSubjectHelper.getSubjectForQuestionIndex(
        i,
        widget.questions.length,
        explicitSubject: q.subjectId,
        isNeet: !isJee,
        useBotanyZoology: true,
      );
      subs.add(sub);
    }
    final preferredOrder = isJee
        ? ['Physics', 'Chemistry', 'Mathematics']
        : ['Physics', 'Chemistry', 'Botany', 'Zoology', 'Biology'];
    final ordered = <String>['All Sections'];
    for (final s in preferredOrder) {
      if (subs.contains(s)) ordered.add(s);
    }
    for (final s in subs) {
      if (!ordered.contains(s)) ordered.add(s);
    }
    _availableSections = ordered;
  }

  Future<void> _loadBookmarks() async {
    try {
      final ids = await SupabaseService.getBookmarkedQuestionIds();
      if (mounted) {
        setState(() {
          _bookmarkedQuestionIds.addAll(ids);
        });
      }
    } catch (_) {}
  }

  Future<void> _loadPeerAnswers() async {
    try {
      final List<Map<int, String>> peerList = [];
      peerList.add(Map<int, String>.from(_currentUserAnswers));

      final prefs = await SharedPreferences.getInstance();
      final historyStr = prefs.getString('cosmyra_test_attempts_history');
      if (historyStr != null && historyStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(historyStr);
        for (final item in list) {
          if (item is Map && item['user_answers'] is Map) {
            final uAns = item['user_answers'] as Map;
            final map = <int, String>{};
            uAns.forEach((k, v) {
              final idx = int.tryParse(k.toString());
              if (idx != null) map[idx] = v.toString();
            });
            if (map.isNotEmpty) peerList.add(map);
          }
        }
      }

      final testId = _currentAttempt.testTemplateId.isNotEmpty
          ? _currentAttempt.testTemplateId
          : _currentAttempt.id;
      if (testId.isNotEmpty) {
        final rawAttempts = await SupabaseService.fetchAllAttemptsForTest(testId: testId);
        for (final item in rawAttempts) {
          if (item['user_answers'] is Map) {
            final uAns = item['user_answers'] as Map;
            final map = <int, String>{};
            uAns.forEach((k, v) {
              final idx = int.tryParse(k.toString());
              if (idx != null) map[idx] = v.toString();
            });
            if (map.isNotEmpty) peerList.add(map);
          }
        }
      }

      if (mounted) {
        setState(() {
          _peerAnswers.clear();
          _peerAnswers.addAll(peerList);
        });
      }
    } catch (_) {}
  }

  String? _getOptionMarkedPercentage(int qIdx, QuestionOptionModel opt, int optNumber) {
    if (_peerAnswers.isEmpty) return null;
    final optKey = opt.id.isNotEmpty ? opt.id : 'opt_${widget.questions[qIdx].id}_${opt.optionIndex}';
    final optLetter = String.fromCharCode(65 + opt.optionIndex);
    int marked = 0;
    int totalWithAnswers = 0;
    for (final ansMap in _peerAnswers) {
      final ans = ansMap[qIdx];
      if (ans != null && ans.trim().isNotEmpty) {
        totalWithAnswers++;
        if (_isOptSelected(ans, optKey, optLetter, opt.optionText, optNumber)) {
          marked++;
        }
      }
    }
    if (totalWithAnswers == 0 || marked == 0) return null;
    final pct = (marked / totalWithAnswers) * 100.0;
    return '${pct.toStringAsFixed(2)}%';
  }

  Future<void> _loadAllAttempts() async {
    final testId = _currentAttempt.testTemplateId.isNotEmpty
        ? _currentAttempt.testTemplateId
        : _currentAttempt.id;
    if (testId.isEmpty) return;

    try {
      final rawAttempts = await SupabaseService.fetchAllAttemptsForTest(testId: testId);
      if (mounted && rawAttempts.isNotEmpty) {
        final List<TestAttemptModel> parsed = [];
        for (final raw in rawAttempts) {
          try {
            parsed.add(TestAttemptModel.fromJson(raw));
          } catch (_) {}
        }
        if (parsed.isNotEmpty) {
          setState(() {
            _availableAttempts = parsed;
            final idx = _availableAttempts.indexWhere((a) => a.id == _currentAttempt.id);
            _selectedAttemptIndex = idx != -1 ? idx : 0;
          });
          return;
        }
      }
    } catch (_) {}
  }

  void _switchAttempt(int index) {
    if (index < 0 || index >= _availableAttempts.length) return;
    final newAttempt = _availableAttempts[index];
    setState(() {
      _selectedAttemptIndex = index;
      _currentAttempt = newAttempt;
    });

    _loadAttemptAnswers(newAttempt);
  }

  Future<void> _loadAttemptAnswers(TestAttemptModel attempt) async {
    try {
      final attemptMap = await SupabaseService.fetchLatestTestAttempt(testId: attempt.id);
      if (attemptMap != null && attemptMap['user_answers'] is Map) {
        final uAnsMap = attemptMap['user_answers'] as Map;
        final newAnswers = <int, String>{};
        uAnsMap.forEach((k, v) {
          final idx = int.tryParse(k.toString());
          if (idx != null) {
            newAnswers[idx] = v.toString();
          }
        });
        if (mounted) {
          setState(() {
            _currentUserAnswers = newAnswers;
            _findFirstValidQuestionIndex();
          });
        }
      }
    } catch (_) {}
  }

  bool _isOptSelected(String? userAns, String optKey, String optLetter, String optText, [int? optIndex]) {
    if (userAns == null || userAns.isEmpty) return false;
    final parts = userAns.split(',');
    for (var p in parts) {
      final trimmed = p.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed == optKey) return true;
      if (trimmed.toLowerCase() == optLetter.toLowerCase()) return true;
      if (trimmed.toLowerCase() == 'option ${optLetter.toLowerCase()}') return true;
      if (trimmed.toLowerCase() == 'opt ${optLetter.toLowerCase()}') return true;
      if (optIndex != null && trimmed == optIndex.toString()) return true;
      if (optText.isNotEmpty && trimmed.toLowerCase() == optText.trim().toLowerCase()) return true;
    }
    return false;
  }

  bool _isQuestionCorrect(int originalIdx) {
    if (originalIdx < 0 || originalIdx >= widget.questions.length) return false;
    final q = widget.questions[originalIdx];
    final userAns = _currentUserAnswers[originalIdx];
    if (userAns == null || userAns.trim().isEmpty) return false;

    if (q.qType == 'numerical') {
      final expected = (q.numericalAnswer ?? '').trim();
      if (expected.isEmpty) return false;
      final uNum = double.tryParse(userAns.trim());
      final eNum = double.tryParse(expected);
      if (uNum != null && eNum != null) {
        final tol = q.numericalTolerance ?? 0.01;
        return (uNum - eNum).abs() <= tol;
      }
      return userAns.trim().toLowerCase() == expected.toLowerCase();
    }

    for (int i = 0; i < q.options.length; i++) {
      final opt = q.options[i];
      final optKey = opt.id.isNotEmpty ? opt.id : 'opt_${q.id}_$i';
      final optLetter = String.fromCharCode(65 + i);
      if (_isOptSelected(userAns, optKey, optLetter, opt.optionText, i + 1) && opt.isCorrect) {
        return true;
      }
    }
    return false;
  }

  bool _isQuestionAnswered(int originalIdx) {
    final userAns = _currentUserAnswers[originalIdx];
    return userAns != null && userAns.trim().isNotEmpty;
  }

  bool _isQuestionReview(int originalIdx) {
    if (originalIdx < 0 || originalIdx >= widget.questions.length) return false;
    final q = widget.questions[originalIdx];
    return _bookmarkedQuestionIds.contains(q.id) || _reviewIndices.contains(originalIdx);
  }

  String _getQuestionSection(int originalIdx) {
    if (originalIdx < 0 || originalIdx >= widget.questions.length) return 'General';
    final q = widget.questions[originalIdx];
    final isJee = _currentAttempt.testTitle.toLowerCase().contains('jee');
    return NeetSubjectHelper.getSubjectForQuestionIndex(
      originalIdx,
      widget.questions.length,
      explicitSubject: q.subjectId,
      isNeet: !isJee,
      useBotanyZoology: true,
    );
  }

  List<int> _getFilteredOriginalIndices() {
    final List<int> list = [];
    for (int i = 0; i < widget.questions.length; i++) {
      if (_selectedSection != 'All Sections') {
        final sec = _getQuestionSection(i);
        if (sec.toLowerCase() != _selectedSection.toLowerCase()) continue;
      }

      final answered = _isQuestionAnswered(i);
      final correct = _isQuestionCorrect(i);
      final review = _isQuestionReview(i);

      switch (_activeFilter) {
        case SolutionFilterType.all:
          list.add(i);
          break;
        case SolutionFilterType.correct:
          if (answered && correct) list.add(i);
          break;
        case SolutionFilterType.incorrect:
          if (answered && !correct) list.add(i);
          break;
        case SolutionFilterType.skipped:
          if (!answered) list.add(i);
          break;
        case SolutionFilterType.review:
          if (review) list.add(i);
          break;
      }
    }
    return list;
  }

  Map<SolutionFilterType, int> _computeFilterCounts() {
    int total = 0;
    int correct = 0;
    int incorrect = 0;
    int skipped = 0;
    int review = 0;

    for (int i = 0; i < widget.questions.length; i++) {
      if (_selectedSection != 'All Sections') {
        final sec = _getQuestionSection(i);
        if (sec.toLowerCase() != _selectedSection.toLowerCase()) continue;
      }
      total++;
      final ans = _isQuestionAnswered(i);
      final corr = _isQuestionCorrect(i);
      final rev = _isQuestionReview(i);

      if (ans) {
        if (corr) {
          correct++;
        } else {
          incorrect++;
        }
      } else {
        skipped++;
      }

      if (rev) {
        review++;
      }
    }

    return {
      SolutionFilterType.all: total,
      SolutionFilterType.correct: correct,
      SolutionFilterType.incorrect: incorrect,
      SolutionFilterType.skipped: skipped,
      SolutionFilterType.review: review,
    };
  }

  void _findFirstValidQuestionIndex() {
    final filtered = _getFilteredOriginalIndices();
    if (filtered.isNotEmpty) {
      if (!filtered.contains(_selectedQuestionOriginalIndex)) {
        _selectedQuestionOriginalIndex = filtered.first;
      }
    }
    _scrollToPaletteItem();
  }

  void _onSelectFilter(SolutionFilterType filter) {
    setState(() {
      _activeFilter = filter;
      final filtered = _getFilteredOriginalIndices();
      if (filtered.isNotEmpty && !filtered.contains(_selectedQuestionOriginalIndex)) {
        _selectedQuestionOriginalIndex = filtered.first;
      }
    });
    _scrollToPaletteItem();
  }

  void _onSelectQuestion(int originalIdx) {
    setState(() {
      _selectedQuestionOriginalIndex = originalIdx;
    });
    _contentScrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
    _scrollToPaletteItem();
  }

  void _scrollToPaletteItem() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_paletteScrollController.hasClients) return;
      final filtered = _getFilteredOriginalIndices();
      final currentPosInFiltered = filtered.indexOf(_selectedQuestionOriginalIndex);
      if (currentPosInFiltered != -1) {
        final targetOffset = (currentPosInFiltered * 50.0) - 100.0;
        _paletteScrollController.animateTo(
          targetOffset.clamp(0.0, _paletteScrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _toggleBookmark(String questionId, int originalIdx) {
    final isCurrentlyBookmarked = _bookmarkedQuestionIds.contains(questionId) || _reviewIndices.contains(originalIdx);
    setState(() {
      if (isCurrentlyBookmarked) {
        _bookmarkedQuestionIds.remove(questionId);
        _reviewIndices.remove(originalIdx);
      } else {
        _bookmarkedQuestionIds.add(questionId);
        _reviewIndices.add(originalIdx);
      }
    });
    SupabaseService.toggleBookmarkQuestion(
      questionId: questionId,
      isBookmarked: !isCurrentlyBookmarked,
    );
  }

  void _showVideoSolutionModal(String videoUrl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Video Solution',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SolutionVideoPlayerWidget(
                  videoUrl: videoUrl,
                  height: 240,
                  autoPlay: true,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showSectionSelectorModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Section',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 12),
              ..._availableSections.map((sec) {
                final isSelected = _selectedSection.toLowerCase() == sec.toLowerCase();
                return ListTile(
                  title: Text(
                    sec,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF1E293B),
                    ),
                  ),
                  trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Color(0xFF4F46E5), size: 20) : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  tileColor: isSelected ? const Color(0xFFEEF2FF) : Colors.transparent,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    setState(() {
                      _selectedSection = sec;
                      _findFirstValidQuestionIndex();
                    });
                  },
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showAttemptSelectorModal() {
    if (_availableAttempts.length <= 1) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Switch Attempt',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 12),
              ...List.generate(_availableAttempts.length, (i) {
                final att = _availableAttempts[i];
                final isSelected = i == _selectedAttemptIndex;
                final scoreStr = att.totalScore != null ? '${att.totalScore!.toInt()}/${att.maxMarks?.toInt() ?? 720}' : '';
                return ListTile(
                  title: Text(
                    'Attempt ${i + 1}',
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF1E293B),
                    ),
                  ),
                  subtitle: scoreStr.isNotEmpty ? Text('Score: $scoreStr', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))) : null,
                  trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Color(0xFF4F46E5), size: 20) : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  tileColor: isSelected ? const Color(0xFFEEF2FF) : Colors.transparent,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _switchAttempt(i);
                  },
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _goToNextQuestion(List<int> filtered) {
    final currPos = filtered.indexOf(_selectedQuestionOriginalIndex);
    if (currPos != -1 && currPos < filtered.length - 1) {
      _onSelectQuestion(filtered[currPos + 1]);
    } else {
      widget.onBack();
    }
  }

  void _goToPreviousQuestion(List<int> filtered) {
    final currPos = filtered.indexOf(_selectedQuestionOriginalIndex);
    if (currPos > 0) {
      _onSelectQuestion(filtered[currPos - 1]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredIndices = _getFilteredOriginalIndices();
    final counts = _computeFilterCounts();

    final hasQuestion = widget.questions.isNotEmpty &&
        _selectedQuestionOriginalIndex >= 0 &&
        _selectedQuestionOriginalIndex < widget.questions.length;
    final currentQ = hasQuestion ? widget.questions[_selectedQuestionOriginalIndex] : null;

    final currFilteredPos = filteredIndices.indexOf(_selectedQuestionOriginalIndex);
    final isFirst = currFilteredPos <= 0;
    final isLast = currFilteredPos == filteredIndices.length - 1 || filteredIndices.isEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: _buildTopAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Solution Filter Tabs (Matching Reference Screenshots 1, 2, 3)
            _buildSolutionFilterTabs(counts),

            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

            // 2. Horizontal Question Palette (Matching Reference Screenshots 1, 2, 3)
            _buildHorizontalPalette(filteredIndices),

            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

            // 3. Single-Question Content Area (Scrollable single question only)
            Expanded(
              child: hasQuestion && currentQ != null
                  ? _buildSingleQuestionContent(currentQ, _selectedQuestionOriginalIndex)
                  : _buildEmptyState(),
            ),

            // 4. Fixed Bottom Navigation Bar (Matching Reference Screenshots)
            _buildBottomBar(filteredIndices, isFirst, isLast),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // A. COMPACT TOP APP BAR (Reference 1, 2, 3)
  // ---------------------------------------------------------------------------
  PreferredSizeWidget _buildTopAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 52,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF1E293B)),
        onPressed: widget.onBack,
      ),
      titleSpacing: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Solutions',
            style: TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
          InkWell(
            onTap: _showSectionSelectorModal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selectedSection,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF818CF8)),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.arrow_drop_down_rounded, size: 16, color: Color(0xFF818CF8)),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (_availableAttempts.length > 1)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: InkWell(
              onTap: _showAttemptSelectorModal,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFC7D2FE)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Attempt ${_selectedAttemptIndex + 1}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                    ),
                    const Icon(Icons.arrow_drop_down_rounded, size: 16, color: Color(0xFF4F46E5)),
                  ],
                ),
              ),
            ),
          ),

        // Language icon [A ⟲]
        IconButton(
          icon: const Icon(Icons.translate_rounded, size: 19, color: Color(0xFF475569)),
          tooltip: 'Language',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Solutions are currently displayed in English.'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),

        // Filter icon [∇]
        IconButton(
          icon: const Icon(Icons.filter_alt_outlined, size: 20, color: Color(0xFF475569)),
          tooltip: 'Sections',
          onPressed: _showSectionSelectorModal,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // B. QUESTION STATUS FILTERS (Reference 1, 2, 3)
  // ---------------------------------------------------------------------------
  Widget _buildSolutionFilterTabs(Map<SolutionFilterType, int> counts) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterTabItem(
              type: SolutionFilterType.all,
              title: 'All',
              count: counts[SolutionFilterType.all] ?? 0,
              badgeColor: const Color(0xFF1E293B),
            ),
          ),
          Expanded(
            child: _buildFilterTabItem(
              type: SolutionFilterType.correct,
              title: 'Correct',
              count: counts[SolutionFilterType.correct] ?? 0,
              badgeColor: const Color(0xFF22C55E),
            ),
          ),
          Expanded(
            child: _buildFilterTabItem(
              type: SolutionFilterType.incorrect,
              title: 'Incorrect',
              count: counts[SolutionFilterType.incorrect] ?? 0,
              badgeColor: const Color(0xFFEF4444),
            ),
          ),
          Expanded(
            child: _buildFilterTabItem(
              type: SolutionFilterType.skipped,
              title: 'Skipped',
              count: counts[SolutionFilterType.skipped] ?? 0,
              badgeColor: const Color(0xFF475569),
            ),
          ),
          Expanded(
            child: _buildFilterTabItem(
              type: SolutionFilterType.review,
              title: 'Review',
              count: counts[SolutionFilterType.review] ?? 0,
              badgeColor: const Color(0xFF2563EB),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabItem({
    required SolutionFilterType type,
    required String title,
    required int count,
    required Color badgeColor,
  }) {
    final isSelected = _activeFilter == type;

    return InkWell(
      onTap: () => _onSelectFilter(type),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 3.0,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF4F46E5) : Colors.transparent,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // C. HORIZONTAL NUMBERED QUESTION PALETTE (Reference 1, 2, 3)
  // ---------------------------------------------------------------------------
  Widget _buildHorizontalPalette(List<int> filteredIndices) {
    if (filteredIndices.isEmpty) {
      return Container(
        height: 58,
        alignment: Alignment.center,
        child: const Text(
          'No questions in this filter',
          style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
        ),
      );
    }

    return Container(
      height: 58,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView.builder(
        controller: _paletteScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: filteredIndices.length,
        itemBuilder: (ctx, i) {
          final originalIdx = filteredIndices[i];
          final isSelected = originalIdx == _selectedQuestionOriginalIndex;
          final answered = _isQuestionAnswered(originalIdx);
          final correct = _isQuestionCorrect(originalIdx);
          final review = _isQuestionReview(originalIdx);

          Color bgColor = const Color(0xFFF8FAFC);
          Color dotColor = const Color(0xFF94A3B8);
          Color borderColor = const Color(0xFFE2E8F0);

          if (answered) {
            if (correct) {
              bgColor = const Color(0xFFECFDF5);
              dotColor = const Color(0xFF10B981);
              borderColor = const Color(0xFFA7F3D0);
            } else {
              bgColor = const Color(0xFFFEF2F2);
              dotColor = const Color(0xFFEF4444);
              borderColor = const Color(0xFFFECACA);
            }
          } else if (review) {
            bgColor = const Color(0xFFF5F3FF);
            dotColor = const Color(0xFF8B5CF6);
            borderColor = const Color(0xFFDDD6FE);
          }

          if (isSelected) {
            borderColor = correct
                ? const Color(0xFF10B981)
                : (answered ? const Color(0xFFEF4444) : const Color(0xFF4F46E5));
          }

          return GestureDetector(
            onTap: () => _onSelectQuestion(originalIdx),
            child: Container(
              width: 42,
              margin: const EdgeInsets.symmetric(horizontal: 3.5),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? borderColor : borderColor,
                  width: isSelected ? 1.8 : 1.0,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${originalIdx + 1}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2.5),
                  Container(
                    width: 4.5,
                    height: 4.5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dotColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // D. SINGLE-QUESTION CONTENT AREA (Exact Reference 1, 2, 3 Layout)
  // ---------------------------------------------------------------------------
  Widget _buildSingleQuestionContent(QuestionModel q, int originalIdx) {
    final userAns = _currentUserAnswers[originalIdx];
    final isAnswered = _isQuestionAnswered(originalIdx);
    final isCorrect = _isQuestionCorrect(originalIdx);
    final isReview = _isQuestionReview(originalIdx);

    // Calculate marks display matching screenshot: Marks : -1 if wrong, Marks : +4 if correct
    String marksStr;
    if (isAnswered) {
      if (isCorrect) {
        marksStr = '+${q.marks.toInt()}';
      } else {
        marksStr = '-${q.negativeMarks.toInt()}';
      }
    } else {
      marksStr = '0';
    }

    final qTypeStr = q.qType == 'numerical'
        ? 'Numerical'
        : (q.qType == 'multiple_correct' ? 'Multiple' : 'Single');

    return SingleChildScrollView(
      controller: _contentScrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Meta Row: Number Circle, Marks, Type, Bookmark, Overflow (Screenshot 3)
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF1E293B),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${originalIdx + 1}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),

              // Marks Badge (e.g. Marks : -1 or Marks : +4)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Marks : $marksStr',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                ),
              ),
              const SizedBox(width: 8),

              // Type Badge (e.g. Type : Single)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Type : $qTypeStr',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                ),
              ),

              const Spacer(),

              // Bookmark icon
              IconButton(
                icon: Icon(
                  isReview ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: isReview ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                  size: 21,
                ),
                tooltip: isReview ? 'Marked for Review' : 'Mark for Review',
                onPressed: () => _toggleBookmark(q.id, originalIdx),
              ),

              // Overflow menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 20, color: Color(0xFF64748B)),
                onSelected: (val) {
                  if (val == 'copy') {
                    QuestionCopyHelper.copyModelToClipboard(context, q, questionIndex: originalIdx + 1);
                  } else if (val == 'report') {
                    _showReportDialog(q);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'copy',
                    child: Row(
                      children: [
                        Icon(Icons.copy_rounded, size: 16, color: Color(0xFF475569)),
                        SizedBox(width: 8),
                        Text('Copy Question', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'report',
                    child: Row(
                      children: [
                        Icon(Icons.flag_outlined, size: 16, color: Color(0xFFEF4444)),
                        SizedBox(width: 8),
                        Text('Report Issue', style: TextStyle(fontSize: 13, color: Color(0xFFEF4444))),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 2. Question Statement Card (Screenshot 3)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LaTeXView(
                  text: q.questionText,
                  style: const TextStyle(fontSize: 14.5, height: 1.5, color: Color(0xFF0F172A)),
                ),
                if (q.questionImage != null && q.questionImage!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: SmartImage(url: q.questionImage, height: 180, fit: BoxFit.contain),
                  ),
                ],
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.bottomRight,
                  child: InkWell(
                    onTap: () => _showZoomImageDialog(q.questionImage ?? ''),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFF94A3B8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.fullscreen_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 3. Student Status & Timing Card (Screenshot 3)
          _buildStatusAndTimingCard(isAnswered, isCorrect),

          const SizedBox(height: 16),

          // 4. Correct Answer Line (Screenshot 2 & 3)
          _buildCorrectAnswerBanner(q),

          const SizedBox(height: 16),

          // 5. Answer Option Cards (Screenshot 2)
          if (q.qType == 'numerical')
            _buildNumericalOptionsCard(q, userAns, isAnswered, isCorrect)
          else
            _buildOptionCardsList(q, userAns),

          const SizedBox(height: 20),

          // 6. Solution Explanation & Video Sol. Button (Screenshot 1)
          _buildSolutionHeaderAndBody(q),

          const SizedBox(height: 70), // Safe bottom padding for floating Next button
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STUDENT STATUS AND TIMING CARD (Screenshot 3)
  // ---------------------------------------------------------------------------
  Widget _buildStatusAndTimingCard(bool isAnswered, bool isCorrect) {
    final statusText = isAnswered ? (isCorrect ? 'Correct' : 'Incorrect') : 'Skipped';
    final statusColor = isAnswered
        ? (isCorrect ? const Color(0xFF15803D) : const Color(0xFFEF4444))
        : const Color(0xFF64748B);

    final totalQ = widget.questions.isNotEmpty ? widget.questions.length : 1;
    final avgTimeSec = _currentAttempt.timeSpentSeconds > 0
        ? (_currentAttempt.timeSpentSeconds ~/ totalQ).clamp(1, 999)
        : 2;
    final timeStr = '${avgTimeSec}s';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // Left: Status
          Expanded(
            child: Row(
              children: [
                const Text('Status', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(width: 14),
                Text(
                  statusText,
                  style: TextStyle(color: statusColor, fontSize: 13.5, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Divider
          Container(width: 1, height: 20, color: const Color(0xFFCBD5E1)),
          const SizedBox(width: 20),

          // Right: Time
          Expanded(
            child: Row(
              children: [
                const Text('Time', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(width: 14),
                Text(
                  timeStr,
                  style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13.5, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CORRECT ANSWER BANNER (Screenshot 2 & 3)
  // ---------------------------------------------------------------------------
  Widget _buildCorrectAnswerBanner(QuestionModel q) {
    String correctLabel = '';
    if (q.qType == 'numerical') {
      correctLabel = q.numericalAnswer ?? 'N/A';
    } else {
      final corrIdx = q.options.indexWhere((o) => o.isCorrect);
      if (corrIdx != -1) {
        correctLabel = '${corrIdx + 1}';
      } else {
        correctLabel = '1';
      }
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Text(
          'Correct Answer : $correctLabel',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ANSWER OPTION CARDS (Screenshot 2)
  // ---------------------------------------------------------------------------
  Widget _buildOptionCardsList(QuestionModel q, String? userAns) {
    return Column(
      children: q.options.asMap().entries.map((entry) {
        final optIdx = entry.key;
        final opt = entry.value;
        final optKey = opt.id.isNotEmpty ? opt.id : 'opt_${q.id}_$optIdx';
        final optLetter = String.fromCharCode(65 + optIdx);
        final isSelected = _isOptSelected(userAns, optKey, optLetter, opt.optionText, optIdx + 1);

        Color bg = const Color(0xFFFFFFFF);
        Color border = const Color(0xFFE2E8F0);
        Color txtColor = const Color(0xFF1E293B);
        Color dividerColor = const Color(0xFFCBD5E1);

        if (opt.isCorrect) {
          bg = const Color(0xFFDCFCE7); // Light green background (Screenshot 2)
          border = const Color(0xFF86EFAC);
          txtColor = const Color(0xFF14532D);
          dividerColor = const Color(0xFF86EFAC);
        } else if (isSelected && !opt.isCorrect) {
          bg = const Color(0xFFFEE2E2); // Light red background (Screenshot 2)
          border = const Color(0xFFFCA5A5);
          txtColor = const Color(0xFF7F1D1D);
          dividerColor = const Color(0xFFFCA5A5);
        }

        // Real dynamic marked percentage
        final dynamicPct = _getOptionMarkedPercentage(entry.key, opt, optIdx + 1);
        final bool showPct = dynamicPct != null && (isSelected || opt.isCorrect);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: 1.2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Index number
              SizedBox(
                width: 20,
                child: Text(
                  '${optIdx + 1}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: txtColor),
                ),
              ),

              // Vertical divider line
              Container(
                width: 1,
                height: 32,
                color: dividerColor,
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),

              // Option content + percentage
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LaTeXView(
                      text: opt.optionText,
                      style: TextStyle(fontSize: 14.5, height: 1.4, color: txtColor),
                    ),
                    if (opt.optionImage != null && opt.optionImage!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      SmartImage(url: opt.optionImage, height: 70, fit: BoxFit.contain),
                    ],
                    if (showPct) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.info_outline, size: 13, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Text(
                            '$dynamicPct Marked this option',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Selected Red Radio Indicator (Screenshot 2)
              if (isSelected && !opt.isCorrect) ...[
                const SizedBox(width: 8),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFEF4444), width: 2),
                  ),
                  child: Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ),
              ] else if (isSelected && opt.isCorrect) ...[
                const SizedBox(width: 8),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF16A34A), width: 2),
                  ),
                  child: Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNumericalOptionsCard(QuestionModel q, String? userAns, bool isAnswered, bool isCorrect) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Your Answer: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF475569))),
              Text(
                isAnswered ? userAns! : 'Skipped',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                  color: isAnswered ? (isCorrect ? const Color(0xFF15803D) : const Color(0xFFB91C1C)) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 8),
              if (isAnswered)
                Icon(
                  isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: isCorrect ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                  size: 18,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('Correct Value: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF475569))),
              Text(
                q.numericalAnswer ?? 'N/A',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF15803D)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SOLUTION & VIDEO SOLUTION (Screenshot 1)
  // ---------------------------------------------------------------------------
  Widget _buildSolutionHeaderAndBody(QuestionModel q) {
    final hasVideo = q.solutionVideoUrl != null && q.solutionVideoUrl!.trim().isNotEmpty;
    final rawExplanation = (q.explanation != null && q.explanation!.trim().isNotEmpty)
        ? q.explanation!
        : (q.solution != null && q.solution!.trim().isNotEmpty ? q.solution! : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Solution',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            if (hasVideo)
              ElevatedButton.icon(
                onPressed: () => _showVideoSolutionModal(q.solutionVideoUrl!),
                icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
                label: const Text(
                  'View Video Sol.',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),

        if (rawExplanation != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: LaTeXView(
              text: rawExplanation,
              style: const TextStyle(fontSize: 14.5, height: 1.6, color: Color(0xFF1E293B)),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Solution not available for this question yet.',
              style: TextStyle(fontSize: 13.5, fontStyle: FontStyle.italic, color: Color(0xFF64748B)),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // FIXED BOTTOM BAR (Screenshot 1, 2, 3)
  // ---------------------------------------------------------------------------
  Widget _buildBottomBar(List<int> filteredIndices, bool isFirst, bool isLast) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (!isFirst) ...[
            OutlinedButton.icon(
              onPressed: () => _goToPreviousQuestion(filteredIndices),
              icon: const Icon(Icons.chevron_left_rounded, size: 20),
              label: const Text('Prev', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF4F46E5),
                side: const BorderSide(color: Color(0xFFC7D2FE)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(width: 12),
          ],

          ElevatedButton(
            onPressed: () => _goToNextQuestion(filteredIndices),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              isLast ? 'Back to Result' : 'Next',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_outlined, size: 48, color: Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          const Text(
            'No questions found in this filter.',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _onSelectFilter(SolutionFilterType.all),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
            child: const Text('Show All Questions', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showZoomImageDialog(String imageUrl) {
    if (imageUrl.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.all(12),
              child: InteractiveViewer(
                child: SmartImage(url: imageUrl, fit: BoxFit.contain),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.black87),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDialog(QuestionModel q) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report Question', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Please describe the issue with this question (e.g. wrong answer key, typo, formatting issue):',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Describe issue here...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thank you. Your report has been submitted.')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
            child: const Text('Submit Report', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

/// Standalone loader screen for direct navigation or web page reload
class TestSolutionsLoaderScreen extends StatefulWidget {
  final String testId;
  final String? attemptId;
  final VoidCallback onBackToDashboard;

  const TestSolutionsLoaderScreen({
    super.key,
    required this.testId,
    this.attemptId,
    required this.onBackToDashboard,
  });

  @override
  State<TestSolutionsLoaderScreen> createState() => _TestSolutionsLoaderScreenState();
}

class _TestSolutionsLoaderScreenState extends State<TestSolutionsLoaderScreen> {
  bool _isLoading = true;
  String? _error;
  TestAttemptModel? _attempt;
  List<QuestionModel> _questions = [];
  Map<int, String> _userAnswers = {};
  List<TestAttemptModel> _allAttempts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final attemptMap = await SupabaseService.fetchLatestTestAttempt(testId: widget.testId);
      if (attemptMap == null) {
        setState(() {
          _error = 'No recorded attempt found for this test paper.';
          _isLoading = false;
        });
        return;
      }

      final attempt = TestAttemptModel.fromJson(attemptMap);
      final questions = await SupabaseService.fetchAttemptQuestions(
        attemptId: attempt.id,
        testId: widget.testId,
      );

      final answers = <int, String>{};
      if (attemptMap['user_answers'] is Map) {
        final uAnsMap = attemptMap['user_answers'] as Map;
        uAnsMap.forEach((k, v) {
          final idx = int.tryParse(k.toString());
          if (idx != null) {
            answers[idx] = v.toString();
          }
        });
      }

      final rawAttempts = await SupabaseService.fetchAllAttemptsForTest(
        testId: attempt.testTemplateId.isNotEmpty ? attempt.testTemplateId : attempt.id,
      );
      final List<TestAttemptModel> parsedAttempts = [];
      for (final r in rawAttempts) {
        try {
          parsedAttempts.add(TestAttemptModel.fromJson(r));
        } catch (_) {}
      }

      setState(() {
        _attempt = attempt;
        _questions = questions;
        _userAnswers = answers;
        _allAttempts = parsedAttempts.isNotEmpty ? parsedAttempts : [attempt];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Unable to load test solutions. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF4F46E5)),
              SizedBox(height: 16),
              Text(
                'Loading test solutions...',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null || _attempt == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Solutions'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: widget.onBackToDashboard,
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.assignment_late_outlined, size: 54, color: Color(0xFF94A3B8)),
                const SizedBox(height: 16),
                Text(
                  _error ?? 'Solutions Unavailable',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please take this test or check your test history to review solutions.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: widget.onBackToDashboard,
                  icon: const Icon(Icons.dashboard_rounded, size: 18),
                  label: const Text('Back to Dashboard'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return TestSolutionsScreen(
      attempt: _attempt!,
      questions: _questions,
      userAnswers: _userAnswers,
      allAttempts: _allAttempts,
      onBack: widget.onBackToDashboard,
    );
  }
}
