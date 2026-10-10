import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/models.dart';
import '../../shared/widgets/latex_view.dart';
import '../../shared/widgets/smart_image.dart';
import '../../shared/utils/question_copy_helper.dart';
import '../../core/services/supabase_service.dart';
import '../../shared/utils/neet_subject_helper.dart';
import 'test_result_screen.dart';

class CustomTestScreen extends StatefulWidget {
  final List<QuestionModel> questions;
  final int durationMinutes;
  final String? sessionId;
  final bool isNewSession;
  final bool isPreview;
  final Function(TestAttemptModel attempt, Map<int, String> answers) onTestSubmitted;

  const CustomTestScreen({
    super.key,
    required this.questions,
    this.durationMinutes = 60,
    this.sessionId,
    this.isNewSession = false,
    this.isPreview = false,
    required this.onTestSubmitted,
  });

  @override
  State<CustomTestScreen> createState() => _CustomTestScreenState();
}

class _CustomTestScreenState extends State<CustomTestScreen> {
  late final String _activeSessionId;
  int _currentIndex = 0;
  final Map<int, String> _userAnswers = {};
  final Set<int> _markedForReview = {};
  TestAttemptModel? _submittedAttempt;

  late DateTime _startedAt;
  late DateTime _expiresAt;
  Timer? _timer;
  int _secondsRemaining = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _activeSessionId = widget.sessionId ?? 'test_session_${DateTime.now().millisecondsSinceEpoch}';
    _startedAt = DateTime.now();
    _secondsRemaining = widget.durationMinutes > 0 ? widget.durationMinutes * 60 : 3600;
    _expiresAt = _startedAt.add(Duration(seconds: _secondsRemaining));
    if (!widget.isPreview) {
      if (widget.isNewSession) {
        SupabaseService.clearActiveTestSession();
      } else {
        _restoreActiveSession();
      }
    }
    _startTimer();
  }

  Future<void> _restoreActiveSession() async {
    final savedSession = await SupabaseService.loadActiveTestSession(targetSessionId: _activeSessionId);
    if (savedSession != null && mounted) {
      final savedAnswersRaw = savedSession['userAnswers'] as Map<String, dynamic>?;
      final savedReviewRaw = savedSession['markedForReview'] as List<dynamic>?;
      final savedSecs = savedSession['secondsRemaining'] as int?;

      setState(() {
        if (savedAnswersRaw != null) {
          savedAnswersRaw.forEach((k, v) {
            final idx = int.tryParse(k);
            if (idx != null) {
              _userAnswers[idx] = v.toString();
            }
          });
        }
        if (savedReviewRaw != null) {
          _markedForReview.addAll(savedReviewRaw.map((e) => e as int));
        }
        if (savedSecs != null && savedSecs > 0) {
          _secondsRemaining = savedSecs;
        }
      });
    }
  }

  void _persistCurrentSession() {
    if (widget.isPreview) return;
    SupabaseService.saveActiveTestSession(
      sessionId: _activeSessionId,
      questions: widget.questions,
      userAnswers: _userAnswers,
      markedForReview: _markedForReview,
      secondsRemaining: _secondsRemaining,
      startedAt: _startedAt,
      durationMinutes: widget.durationMinutes,
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsRemaining <= 1) {
        t.cancel();
        _submitTest(auto: true);
      } else {
        setState(() => _secondsRemaining--);
        if (_secondsRemaining % 10 == 0) {
          _persistCurrentSession();
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool _isOptSelected(String? userAns, String optKey, String optLetter, String optText) {
    if (userAns == null || userAns.isEmpty) return false;
    final parts = userAns.split(',');
    for (var p in parts) {
      final trimmed = p.trim();
      if (trimmed == optKey) return true;
      if (trimmed == optLetter || trimmed == 'Option $optLetter') return true;
      if (optText.isNotEmpty && trimmed == optText) return true;
    }
    return false;
  }

  void _selectOption(String optKey, {bool isMultiple = false}) {
    setState(() {
      if (isMultiple) {
        final current = _userAnswers[_currentIndex] ?? '';
        final parts = current.isEmpty ? <String>[] : current.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        if (parts.contains(optKey)) {
          parts.remove(optKey);
        } else {
          parts.add(optKey);
        }
        if (parts.isEmpty) {
          _userAnswers.remove(_currentIndex);
        } else {
          _userAnswers[_currentIndex] = parts.join(',');
        }
      } else {
        _userAnswers[_currentIndex] = optKey;
      }
    });
    _persistCurrentSession();
  }

  void _clearResponse() {
    setState(() {
      _userAnswers.remove(_currentIndex);
    });
    _persistCurrentSession();
  }

  void _toggleMarkForReview() {
    setState(() {
      if (_markedForReview.contains(_currentIndex)) {
        _markedForReview.remove(_currentIndex);
      } else {
        _markedForReview.add(_currentIndex);
      }
    });
    _persistCurrentSession();
  }



  void _confirmSubmit() {
    final attemptedCount = _userAnswers.length;
    final totalCount = widget.questions.length;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.assignment_turned_in_outlined, color: Color(0xFF4F46E5)),
            SizedBox(width: 8),
            Text('Submit Test?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You have answered $attemptedCount out of $totalCount questions.'),
            const SizedBox(height: 12),
            const Text(
              'Once submitted, you cannot change your answers.',
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _submitTest(auto: false);
            },
            child: const Text('SUBMIT TEST', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitTest({required bool auto}) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    _timer?.cancel();

    // Calculate Test Score (+4 for correct, -1 for incorrect)
    int correct = 0;
    int incorrect = 0;
    double score = 0.0;

    for (int i = 0; i < widget.questions.length; i++) {
      final q = widget.questions[i];
      final userAns = _userAnswers[i];

      if (userAns != null && userAns.isNotEmpty) {
        bool isCorrect = false;
        if (q.qType == 'numerical') {
          isCorrect = userAns.trim() == (q.numericalAnswer ?? '').trim();
        } else {
          final matchedOpt = q.options.firstWhere(
            (opt) {
              final optKey = (opt.id != null && opt.id.isNotEmpty) ? opt.id : 'opt_${q.id}_${opt.optionIndex}';
              final optLetter = String.fromCharCode(65 + opt.optionIndex);
              return _isOptSelected(userAns, optKey, optLetter, opt.optionText);
            },
            orElse: () => QuestionOptionModel(id: '', questionId: '', optionIndex: 0, optionText: '', isCorrect: false),
          );
          isCorrect = matchedOpt.isCorrect;
        }

        if (isCorrect) {
          correct++;
          score += q.marks;
        } else {
          incorrect++;
          score -= q.negativeMarks;
        }
      }
    }

    final attempted = _userAnswers.length;
    final unattempted = widget.questions.length - attempted;
    final accuracy = attempted > 0 ? (correct / attempted) * 100 : 0.0;
    final timeSpent = (widget.durationMinutes * 60) - _secondsRemaining;

    final attempt = TestAttemptModel(
      id: 'att-${DateTime.now().millisecondsSinceEpoch}',
      userId: 'usr-current',
      testTemplateId: 'tmpl-custom',
      testTitle: 'Custom Test Session',
      startedAt: _startedAt,
      expiresAt: _expiresAt,
      submittedAt: DateTime.now(),
      status: 'submitted',
      totalScore: score,
      maxMarks: widget.questions.length * 4.0,
      totalQuestions: widget.questions.length,
      attemptedCount: attempted,
      correctCount: correct,
      incorrectCount: incorrect,
      unattemptedCount: unattempted,
      accuracy: double.parse(accuracy.toStringAsFixed(1)),
      timeSpentSeconds: timeSpent > 0 ? timeSpent : 1,
    );

    // Save to Supabase and storage (only when NOT in preview mode)
    if (!widget.isPreview) {
      await SupabaseService.submitTestAttempt(
        userId: 'usr-current',
        attempt: attempt,
        questions: widget.questions,
        userAnswers: _userAnswers,
      );
    }

    if (mounted) {
      setState(() {
        _submittedAttempt = attempt;
        _isSubmitting = false;
      });
      widget.onTestSubmitted(attempt, _userAnswers);
    }
  }

  String get _formattedTime {
    final hours = _secondsRemaining ~/ 3600;
    final mins = (_secondsRemaining % 3600) ~/ 60;
    final secs = _secondsRemaining % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String get _currentSubjectName {
    if (widget.questions.isNotEmpty && _currentIndex < widget.questions.length) {
      final q = widget.questions[_currentIndex];
      final explicit = q.subjectId.isNotEmpty ? q.subjectId : null;
      return NeetSubjectHelper.getSubjectForQuestionIndex(
        _currentIndex,
        widget.questions.length,
        explicitSubject: explicit,
        isNeet: true,
      );
    }
    return 'Physics';
  }

  void _openGridViewModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildGridViewSheet(ctx),
    );
  }

  void _showInstructionsModal(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB)),
            SizedBox(width: 8),
            Text('Test Marking & Rules', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Correct Answer: +4 Marks'),
            SizedBox(height: 6),
            Text('• Incorrect Answer: -1 Mark (Negative Marking)'),
            SizedBox(height: 6),
            Text('• Unattempted Question: 0 Marks'),
            SizedBox(height: 12),
            Text('Color Codes:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text('🟩 Answered  |  🟥 Not Answered  |  🟦 Marked for Review  |  ⬜ Not Visited'),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }

  void _showQuestionDetailDialog(BuildContext context, QuestionModel question) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 700,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Question ${_currentIndex + 1} Detail', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 16),
              LaTeXView(
                text: question.questionText,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
              if (question.questionImage != null && question.questionImage!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Center(
                  child: SmartImage(
                    url: question.questionImage,
                    height: 300,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridViewSheet(BuildContext ctx) {
    int answeredCount = 0;
    int notAnsweredCount = 0;
    int markedReviewCount = 0;
    int notVisitedCount = 0;
    int answeredAndMarkedCount = 0;

    for (int i = 0; i < widget.questions.length; i++) {
      final ans = _userAnswers[i];
      final hasAns = ans != null && ans.trim().isNotEmpty;
      final isRev = _markedForReview.contains(i);

      if (hasAns && isRev) {
        answeredAndMarkedCount++;
      } else if (hasAns) {
        answeredCount++;
      } else if (isRev) {
        markedReviewCount++;
      } else if (i <= _currentIndex) {
        notAnsweredCount++;
      } else {
        notVisitedCount++;
      }
    }

    final List<String> subjectList = ['Physics', 'Chemistry', 'Botany', 'Zoology'];
    String activeModalSub = subjectList.contains(_currentSubjectName) ? _currentSubjectName : subjectList.first;

    return StatefulBuilder(
      builder: (modalCtx, setModalState) {
        final List<int> filteredIndices = NeetSubjectHelper.getQuestionIndicesForSubject(
          subject: activeModalSub,
          totalQuestions: widget.questions.length,
          questions: widget.questions,
          isNeet: true,
        );

        return Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: < Grid View     ⏱ 02:56:24
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF0F172A)),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                      const SizedBox(width: 4),
                      const Text('Grid View', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 18, color: Color(0xFF475569)),
                      const SizedBox(width: 6),
                      Text(
                        _formattedTime,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Subject Switcher Tabs
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: subjectList.map((sub) {
                    final isSelected = sub.toLowerCase() == activeModalSub.toLowerCase();
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() => activeModalSub = sub),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: isSelected ? [const BoxShadow(color: Color(0x0D000000), blurRadius: 4, offset: Offset(0, 2))] : null,
                          ),
                          child: Center(
                            child: Text(
                              sub,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              // Status Legend Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    _buildLegendCountItem(answeredCount.toString(), 'Answered', const Color(0xFF22C55E)),
                    _buildLegendCountItem(notAnsweredCount.toString(), 'Not Answered', const Color(0xFFEF4444)),
                    _buildLegendCountItem(markedReviewCount.toString(), 'Marked for Review', const Color(0xFF3B82F6)),
                    _buildLegendCountItem(notVisitedCount.toString(), 'Not Visited', const Color(0xFF94A3B8), isOutline: true),
                    _buildLegendCountItem(answeredAndMarkedCount.toString(), 'Answered and Marked for Review', const Color(0xFF8B5CF6)),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 5-Column Question Grid Matrix (Filtered for activeSubject)
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: filteredIndices.length,
                  itemBuilder: (gridCtx, fIdx) {
                    final qIdx = filteredIndices[fIdx];
                    final isCur = qIdx == _currentIndex;
                    final ans = _userAnswers[qIdx];
                    final hasAns = ans != null && ans.trim().isNotEmpty;
                    final isRev = _markedForReview.contains(qIdx);

                    Color borderColor = const Color(0xFFE2E8F0);
                    Color bgColor = const Color(0xFFF8FAFC);
                    Color textColor = const Color(0xFF334155);

                    if (hasAns && isRev) {
                      bgColor = const Color(0xFF8B5CF6);
                      borderColor = const Color(0xFF7C3AED);
                      textColor = Colors.white;
                    } else if (hasAns) {
                      bgColor = const Color(0xFF22C55E);
                      borderColor = const Color(0xFF16A34A);
                      textColor = Colors.white;
                    } else if (isRev) {
                      bgColor = const Color(0xFF3B82F6);
                      borderColor = const Color(0xFF2563EB);
                      textColor = Colors.white;
                    } else if (isCur) {
                      bgColor = const Color(0xFFFEF2F2);
                      borderColor = const Color(0xFFEF4444);
                      textColor = const Color(0xFFDC2626);
                    }

                    return InkWell(
                      onTap: () {
                        setState(() => _currentIndex = qIdx);
                        Navigator.pop(ctx);
                        _persistCurrentSession();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isCur ? const Color(0xFFEF4444) : borderColor,
                            width: isCur ? 2.0 : 1.0,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${qIdx + 1}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Bottom Instructions Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showInstructionsModal(ctx),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Instructions', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendCountItem(String count, String label, Color color, {bool isOutline = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isOutline ? Colors.white : color,
            borderRadius: BorderRadius.circular(6),
            border: isOutline ? Border.all(color: color, width: 1.5) : null,
          ),
          child: Text(
            count,
            style: TextStyle(
              color: isOutline ? color : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_submittedAttempt != null) {
      return TestResultScreen(
        attempt: _submittedAttempt!,
        questions: widget.questions,
        userAnswers: _userAnswers,
        onBackToDashboard: () {
          widget.onTestSubmitted(_submittedAttempt!, _userAnswers);
        },
        onRetryTest: () {
          setState(() {
            _submittedAttempt = null;
            _currentIndex = 0;
            _userAnswers.clear();
            _isSubmitting = false;
            _secondsRemaining = widget.durationMinutes * 60;
            _startTimer();
          });
        },
      );
    }

    if (widget.questions.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.quiz_outlined, color: Color(0xFFD97706), size: 40),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Questions Uploaded Yet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This test paper structure has been created in the test series, but the 180 questions have not been uploaded via Bulk Question Upload (Step 2) yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Go Back'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        try {
                          GoRouter.of(context).go('/admin/questions/upload');
                        } catch (_) {}
                      },
                      icon: const Icon(Icons.upload_file_rounded, size: 18),
                      label: const Text('Upload Questions', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    final question = widget.questions[_currentIndex];
    final selectedAns = _userAnswers[_currentIndex];
    final isMarked = _markedForReview.contains(_currentIndex);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            if (widget.isPreview)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFD97706), Color(0xFFB45309)],
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.visibility_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ADMIN PREVIEW MODE — Testing interface in preview mode. Scores, attempt data, or analytics will NOT be logged as user data.',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            // 1. TOP HEADER BAR (Timer + Subject Title + Submit Button)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined, size: 18, color: Color(0xFF475569)),
                          const SizedBox(width: 6),
                          Text(
                            _formattedTime,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _currentSubjectName,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _confirmSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: const Text('Submit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ],
              ),
            ),

            // 2. HORIZONTAL QUESTION SCROLLBAR RIBBON + GRID VIEW BUTTON :::
            Container(
              height: 52,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.questions.length,
                      itemBuilder: (ctx, idx) {
                        final isCur = idx == _currentIndex;
                        final ans = _userAnswers[idx];
                        final hasAns = ans != null && ans.trim().isNotEmpty;
                        final isRev = _markedForReview.contains(idx);

                        Color bg = const Color(0xFFF1F5F9);
                        Color border = const Color(0xFFE2E8F0);
                        Color txtColor = const Color(0xFF64748B);

                        if (isCur) {
                          bg = const Color(0xFFFEF2F2);
                          border = const Color(0xFFEF4444);
                          txtColor = const Color(0xFFDC2626);
                        } else if (hasAns && isRev) {
                          bg = const Color(0xFFF3E8FF);
                          border = const Color(0xFF8B5CF6);
                          txtColor = const Color(0xFF7C3AED);
                        } else if (hasAns) {
                          bg = const Color(0xFFF0FDF4);
                          border = const Color(0xFF22C55E);
                          txtColor = const Color(0xFF15803D);
                        } else if (isRev) {
                          bg = const Color(0xFFEFF6FF);
                          border = const Color(0xFF3B82F6);
                          txtColor = const Color(0xFF1D4ED8);
                        }

                        return GestureDetector(
                          onTap: () {
                            setState(() => _currentIndex = idx);
                            _persistCurrentSession();
                          },
                          child: Container(
                            width: 38,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: border, width: isCur ? 1.5 : 1.0),
                            ),
                            child: Center(
                              child: Text(
                                '${idx + 1}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: txtColor,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    height: 32,
                    width: 1,
                    color: const Color(0xFFCBD5E1),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  // ::: Grid View Icon Button
                  IconButton(
                    icon: const Icon(Icons.grid_view_rounded, color: Color(0xFF475569), size: 22),
                    tooltip: 'Grid View / Question Palette',
                    onPressed: _openGridViewModal,
                  ),
                ],
              ),
            ),

            // MAIN SCROLLABLE QUESTION BODY
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 20),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 3. QUESTION META ROW (Dark Number Circle + Marking Badges + Translate & Menu Icons)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              // Dark Circle Badge (1)
                              Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF334155),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${_currentIndex + 1}',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Marks Badge (+4 -1)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: Row(
                                  children: [
                                    const Text('Marks : ', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                                    Text('+${question.marks.toInt()}', style: const TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 4),
                                    Text('-${question.negativeMarks.toInt()}', style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Question Type Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: Text(
                                  'Type : ${question.qType == 'numerical' ? 'Numerical' : (question.qType == 'multiple_correct' ? 'Multiple' : 'Single')}',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),

                          // Right Action Icons (Translate & Menu)
                          Row(
                            children: [
                              IconButton(
                                icon: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                  ),
                                  child: const Icon(Icons.g_translate_rounded, size: 16, color: Color(0xFF475569)),
                                ),
                                tooltip: 'Language',
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Language: English (Default)'), duration: Duration(seconds: 1)),
                                  );
                                },
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF475569), size: 22),
                                onSelected: (val) {
                                  if (val == 'copy') {
                                    QuestionCopyHelper.copyModelToClipboard(context, question, questionIndex: _currentIndex + 1);
                                  } else if (val == 'clear') {
                                    _clearResponse();
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(value: 'copy', child: Row(children: [Icon(Icons.copy_rounded, size: 16), SizedBox(width: 8), Text('Copy Question')])),
                                  const PopupMenuItem(value: 'clear', child: Row(children: [Icon(Icons.clear_rounded, size: 16), SizedBox(width: 8), Text('Clear Response')])),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // 4. QUESTION TEXT & CONTENT CARD
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LaTeXView(
                            text: question.questionText,
                            style: const TextStyle(fontSize: 15.5, height: 1.5, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
                          ),
                          if (question.questionImage != null && question.questionImage!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            SmartImage(
                              key: ValueKey('q_img_${question.id}_${question.questionImage}'),
                              url: question.questionImage,
                              height: 180,
                              fit: BoxFit.contain,
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.open_in_full_rounded, size: 18, color: Color(0xFF64748B)),
                                tooltip: 'Expand Question',
                                onPressed: () => _showQuestionDetailDialog(context, question),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Mark for Review Checkbox below Question Card
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: InkWell(
                          onTap: _toggleMarkForReview,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: isMarked ? const Color(0xFF2563EB) : Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: isMarked ? const Color(0xFF2563EB) : const Color(0xFF94A3B8), width: 1.5),
                                  ),
                                  child: isMarked ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Mark for Review',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF334155)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // 5. OPTIONS SELECTOR CARDS (1 | 1 ◯ format)
                    if (question.qType == 'numerical')
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: _buildNumericalField(selectedAns),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          children: question.options.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final opt = entry.value;
                            final String optKey = (opt.id != null && opt.id.isNotEmpty) ? opt.id : 'opt_${question.id}_${opt.optionIndex}';
                            final String optLetter = String.fromCharCode(65 + opt.optionIndex);
                            final bool isMultiple = (question.qType == 'multiple_correct' || question.qType == 'multiple');
                            final bool isSelected = _isOptSelected(selectedAns, optKey, optLetter, opt.optionText);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: InkWell(
                                onTap: () => _selectOption(optKey, isMultiple: isMultiple),
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Index Column with Vertical Divider: "1  |  "
                                      Row(
                                        children: [
                                          Text(
                                            '${idx + 1}',
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                                          ),
                                          const SizedBox(width: 12),
                                          Container(height: 20, width: 1, color: const Color(0xFFCBD5E1)),
                                          const SizedBox(width: 12),
                                        ],
                                      ),

                                      // Option Text / Image
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (opt.optionText.isNotEmpty)
                                              LaTeXView(
                                                text: opt.optionText,
                                                style: TextStyle(
                                                  fontSize: 14.5,
                                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                                  color: const Color(0xFF0F172A),
                                                ),
                                              ),
                                            if (opt.optionImage != null && opt.optionImage!.isNotEmpty) ...[
                                              if (opt.optionText.isNotEmpty) const SizedBox(height: 6),
                                              SmartImage(
                                                url: opt.optionImage,
                                                height: 100,
                                                fit: BoxFit.contain,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),

                                      const SizedBox(width: 8),

                                      // Radio Circle Selector Button
                                      Icon(
                                        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                        color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                                        size: 22,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // 6. BOTTOM STICKY ACTION BAR (Save & Next Button)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: selectedAns != null ? _clearResponse : null,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Clear', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (_currentIndex < widget.questions.length - 1) {
                        setState(() {
                          _currentIndex++;
                        });
                        _persistCurrentSession();
                      } else {
                        _confirmSubmit();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: Text(
                      _currentIndex == widget.questions.length - 1 ? 'Submit Test' : 'Save & Next',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumericalField(String? selectedAns) {
    final controller = TextEditingController(text: selectedAns ?? '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Enter Numerical Answer (Integer / Decimal)',
            hintText: 'e.g. 15.5',
            border: OutlineInputBorder(),
          ),
          onChanged: (val) => _selectOption(val),
        ),
      ],
    );
  }
}

enum TestLoaderState { loading, ready, empty, notFound, accessDenied, error }

class TestRunnerLoaderScreen extends StatefulWidget {
  final String testId;
  final String testTitle;
  final int durationMins;
  final Function(TestAttemptModel attempt, Map<int, String> answers)? onSubmitted;

  const TestRunnerLoaderScreen({
    super.key,
    required this.testId,
    required this.testTitle,
    this.durationMins = 180,
    this.onSubmitted,
  });

  @override
  State<TestRunnerLoaderScreen> createState() => _TestRunnerLoaderScreenState();
}

class _TestRunnerLoaderScreenState extends State<TestRunnerLoaderScreen> {
  TestLoaderState _state = TestLoaderState.loading;
  List<QuestionModel> _questions = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    if (!mounted) return;
    setState(() {
      _state = TestLoaderState.loading;
      _errorMessage = '';
    });

    if (widget.testId.isEmpty) {
      if (mounted) {
        setState(() {
          _state = TestLoaderState.notFound;
          _errorMessage = 'Invalid test paper ID.';
        });
      }
      return;
    }

    try {
      final questions = await SupabaseService.fetchTestSeriesQuestions(paperId: widget.testId);

      if (!mounted) return;

      if (questions.isNotEmpty) {
        setState(() {
          _questions = questions;
          _state = TestLoaderState.ready;
        });
      } else {
        setState(() {
          _questions = [];
          _state = TestLoaderState.empty;
        });
      }
    } catch (e) {
      debugPrint('Notice loading paper questions: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _state = TestLoaderState.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_state == TestLoaderState.loading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(widget.testTitle, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go('/dashboard');
              }
            },
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFF2563EB)),
              const SizedBox(height: 16),
              Text(
                'Preparing "${widget.testTitle}"...',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Loading test paper questions...',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_state == TestLoaderState.error || _state == TestLoaderState.notFound || _state == TestLoaderState.accessDenied) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(
            widget.testTitle.isNotEmpty ? widget.testTitle : 'Test Paper',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
          ),
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go('/test-series');
              }
            },
          ),
        ),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Color(0x0F000000), blurRadius: 20, offset: Offset(0, 4)),
              ],
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.error_outline_rounded, size: 40, color: Color(0xFFDC2626)),
                ),
                const SizedBox(height: 20),
                Text(
                  'Failed to load test paper',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage.isNotEmpty ? _errorMessage : 'A temporary connection error occurred. Please check your network and try again.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        onPressed: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else {
                            context.go('/test-series');
                          }
                        },
                        icon: const Icon(Icons.arrow_back_rounded, size: 18, color: Color(0xFF475569)),
                        label: Text(
                          'Back',
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        onPressed: _loadQuestions,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: Text(
                          'Retry',
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_state == TestLoaderState.empty || _questions.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(
            widget.testTitle.isNotEmpty ? widget.testTitle : 'Test Paper',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
          ),
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go('/test-series');
              }
            },
          ),
        ),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Color(0x0F000000), blurRadius: 20, offset: Offset(0, 4)),
              ],
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF3C7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.hourglass_empty_rounded, size: 40, color: Color(0xFFD97706)),
                ),
                const SizedBox(height: 20),
                Text(
                  'Questions for this test paper will be uploaded soon.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'For More Detail Contact Admin',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
                if (widget.testTitle.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.assignment_outlined, size: 16, color: Color(0xFF475569)),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            widget.testTitle,
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        context.go('/test-series');
                      }
                    },
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: Text(
                      'Back to Test Series',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return CustomTestScreen(
      questions: _questions,
      durationMinutes: widget.durationMins > 0 ? widget.durationMins : 180,
      sessionId: widget.testId,
      onTestSubmitted: (attempt, answers) {
        if (widget.onSubmitted != null) {
          widget.onSubmitted!(attempt, answers);
        } else {
          context.go('/test/${widget.testId}/result');
        }
      },
    );
  }
}

