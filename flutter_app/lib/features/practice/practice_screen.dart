import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/models.dart';
import '../../shared/widgets/latex_view.dart';
import '../../shared/widgets/smart_image.dart';
import '../../shared/services/audio_feedback_service.dart';
import '../../shared/utils/question_copy_helper.dart';
import '../../core/services/supabase_service.dart';
import '../tests/test_result_screen.dart';

class PracticeScreen extends StatefulWidget {
  final List<QuestionModel> questions;
  final int timerMinutes;
  final String? sessionId;
  final bool isNewSession;
  final VoidCallback onFinish;

  const PracticeScreen({
    Key? key,
    required this.questions,
    this.timerMinutes = 0,
    this.sessionId,
    this.isNewSession = false,
    required this.onFinish,
  }) : super(key: key);

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  late final String _activeSessionId;
  int _currentIndex = 0;
  final Map<int, String> _selectedAnswers = {};
  final Map<int, bool> _hasAnswered = {};
  final Set<int> _markedForReview = {};
  final Map<int, bool> _isCorrectMap = {};
  final Map<int, bool> _isPartialMap = {};

  int _currentStreak = 0;
  bool _isAudioMuted = !AudioFeedbackService.isAudioEnabled;

  Timer? _timer;
  int _secondsRemaining = 0;
  TestAttemptModel? _submittedAttempt;

  @override
  void initState() {
    super.initState();
    _activeSessionId = widget.sessionId ?? 'session_${DateTime.now().millisecondsSinceEpoch}_${widget.questions.map((q) => q.id).join('_').hashCode}';
    if (widget.timerMinutes > 0) {
      _secondsRemaining = widget.timerMinutes * 60;
      _startTimer();
    }
    if (widget.isNewSession) {
      _clearPracticeSession();
    } else {
      _loadPracticeSession();
    }
  }

  Future<void> _clearPracticeSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionKey = 'cosmyra_practice_session_$_activeSessionId';
      await prefs.remove(sessionKey);
      if (mounted) {
        setState(() {
          _currentIndex = 0;
          _selectedAnswers.clear();
          _hasAnswered.clear();
          _markedForReview.clear();
          _isCorrectMap.clear();
          _isPartialMap.clear();
          if (widget.timerMinutes > 0) {
            _secondsRemaining = widget.timerMinutes * 60;
          }
        });
      }
    } catch (e) {
      debugPrint('Notice clearing practice session: $e');
    }
  }

  Future<void> _savePracticeSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionKey = 'cosmyra_practice_session_$_activeSessionId';
      final Map<String, dynamic> data = {
        'sessionId': _activeSessionId,
        'currentIndex': _currentIndex,
        'selectedAnswers': _selectedAnswers.map((k, v) => MapEntry(k.toString(), v)),
        'hasAnswered': _hasAnswered.map((k, v) => MapEntry(k.toString(), v)),
        'isCorrectMap': _isCorrectMap.map((k, v) => MapEntry(k.toString(), v)),
        'isPartialMap': _isPartialMap.map((k, v) => MapEntry(k.toString(), v)),
        'markedForReview': _markedForReview.toList(),
        'secondsRemaining': _secondsRemaining,
      };
      await prefs.setString(sessionKey, jsonEncode(data));
    } catch (e) {
      debugPrint('Notice saving practice session: $e');
    }
  }

  Future<void> _loadPracticeSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionKey = 'cosmyra_practice_session_$_activeSessionId';
      final str = prefs.getString(sessionKey);
      if (str != null && str.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(str);
        if (mounted) {
          setState(() {
            _currentIndex = data['currentIndex'] as int? ?? 0;
            if (data['selectedAnswers'] is Map) {
              (data['selectedAnswers'] as Map).forEach((k, v) {
                final idx = int.tryParse(k.toString());
                if (idx != null) _selectedAnswers[idx] = v.toString();
              });
            }
            if (data['hasAnswered'] is Map) {
              (data['hasAnswered'] as Map).forEach((k, v) {
                final idx = int.tryParse(k.toString());
                if (idx != null) _hasAnswered[idx] = v == true;
              });
            }
            if (data['isCorrectMap'] is Map) {
              (data['isCorrectMap'] as Map).forEach((k, v) {
                final idx = int.tryParse(k.toString());
                if (idx != null) _isCorrectMap[idx] = v == true;
              });
            }
            if (data['isPartialMap'] is Map) {
              (data['isPartialMap'] as Map).forEach((k, v) {
                final idx = int.tryParse(k.toString());
                if (idx != null) _isPartialMap[idx] = v == true;
              });
            }
            if (data['markedForReview'] is List) {
              _markedForReview.addAll((data['markedForReview'] as List).map((e) => int.tryParse(e.toString()) ?? 0));
            }
            if (data['secondsRemaining'] is int && (data['secondsRemaining'] as int) > 0) {
              _secondsRemaining = data['secondsRemaining'] as int;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Notice loading practice session: $e');
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsRemaining <= 1) {
        t.cancel();
        _finishPracticeSession();
      } else {
        setState(() => _secondsRemaining--);
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

  void _selectOption(int optionIndex, String optKey, [String? optionText]) {
    if (_hasAnswered[_currentIndex] == true) return; // Immediate feedback given once

    final question = widget.questions[_currentIndex];
    bool isCorrect = false;
    bool isPartial = false;

    final textVal = optionText ?? optKey;
    if (question.qType == 'numerical') {
      final expected = (question.numericalAnswer ?? '').trim();
      if (expected.isNotEmpty) {
        final double? uNum = double.tryParse(textVal.trim());
        final double? eNum = double.tryParse(expected);
        if (uNum != null && eNum != null) {
          isCorrect = (uNum - eNum).abs() < 0.01;
        } else {
          isCorrect = textVal.trim().toLowerCase() == expected.toLowerCase();
        }
      } else {
        isCorrect = true;
      }
    } else if (question.qType == 'multiple_correct' || question.qType == 'multiple' || question.qType == 'multi_correct') {
      final correctIndices = <int>{};
      for (int i = 0; i < question.options.length; i++) {
        if (question.options[i].isCorrect) correctIndices.add(i);
      }
      if (correctIndices.contains(optionIndex) && correctIndices.length > 1) {
        isPartial = true;
      } else if (question.options[optionIndex].isCorrect) {
        isCorrect = true;
      }
    } else {
      isCorrect = question.options[optionIndex].isCorrect;
    }

    setState(() {
      _selectedAnswers[_currentIndex] = optKey;
      _hasAnswered[_currentIndex] = true;
      _isCorrectMap[_currentIndex] = isCorrect;
      _isPartialMap[_currentIndex] = isPartial;
      if (isCorrect) {
        _currentStreak++;
        if (!_isAudioMuted) AudioFeedbackService.playCorrectSound();
      } else {
        _currentStreak = 0;
        if (!_isAudioMuted) AudioFeedbackService.playIncorrectSound();
      }
    });

    _savePracticeSession();
  }

  void _clearResponse() {
    setState(() {
      _selectedAnswers.remove(_currentIndex);
      _hasAnswered.remove(_currentIndex);
      _isCorrectMap.remove(_currentIndex);
      _isPartialMap.remove(_currentIndex);
    });
    _savePracticeSession();
  }

  void _toggleMarkForReview() {
    setState(() {
      if (_markedForReview.contains(_currentIndex)) {
        _markedForReview.remove(_currentIndex);
      } else {
        _markedForReview.add(_currentIndex);
      }
    });
    _savePracticeSession();
  }

  void _finishPracticeSession() {
    _timer?.cancel();

    int correct = 0;
    int incorrect = 0;
    _isCorrectMap.forEach((idx, isCorr) {
      if (isCorr) {
        correct++;
      } else {
        incorrect++;
      }
    });

    final attempted = _selectedAnswers.length;
    final unattempted = widget.questions.length - attempted;
    final double score = (correct * 4.0) - (incorrect * 1.0);
    final double maxScore = widget.questions.length * 4.0;
    final double accuracy = attempted > 0 ? (correct / attempted * 100) : 0.0;
    final int timeSpent = widget.timerMinutes > 0 ? ((widget.timerMinutes * 60) - _secondsRemaining) : 180;

    final attempt = TestAttemptModel(
      id: 'att-${DateTime.now().millisecondsSinceEpoch}',
      userId: 'usr-current',
      testTemplateId: 'tmpl-practice',
      testTitle: 'Custom Practice Session',
      startedAt: DateTime.now().subtract(Duration(seconds: timeSpent > 0 ? timeSpent : 1)),
      expiresAt: DateTime.now(),
      submittedAt: DateTime.now(),
      status: 'submitted',
      totalScore: score,
      maxMarks: maxScore,
      totalQuestions: widget.questions.length,
      attemptedCount: attempted,
      correctCount: correct,
      incorrectCount: incorrect,
      unattemptedCount: unattempted,
      accuracy: double.parse(accuracy.toStringAsFixed(1)),
      timeSpentSeconds: timeSpent > 0 ? timeSpent : 1,
    );

    // Save attempt to Supabase
    SupabaseService.submitTestAttempt(
      userId: 'usr-current',
      attempt: attempt,
      questions: widget.questions,
      userAnswers: _selectedAnswers,
    );

    if (mounted) {
      setState(() {
        _submittedAttempt = attempt;
      });
    }
  }

  void _confirmFinish() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Submit Practice Session?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('You have attempted ${_selectedAnswers.length} out of ${widget.questions.length} questions. Are you sure you want to finish?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _finishPracticeSession();
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
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
      if (q.subjectId.isNotEmpty) {
        final s = q.subjectId.trim();
        if (!s.toLowerCase().contains('uuid') && !s.contains('-') && s.length < 25) {
          return s;
        }
      }
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
            Text('Practice Marking & Rules', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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

  void _showReportDialog(String questionId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report Question'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Describe issue (e.g. Typo, Wrong Answer, Broken LaTeX)...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report submitted to Admin for quality review.')),
              );
            },
            child: const Text('Submit Report'),
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
      final ans = _selectedAnswers[i];
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

    final Set<String> subjects = {};
    for (var q in widget.questions) {
      if (q.subjectId.isNotEmpty && !q.subjectId.contains('-') && q.subjectId.length < 25) {
        subjects.add(q.subjectId);
      }
    }
    if (subjects.isEmpty) {
      subjects.addAll(['Physics', 'Chemistry', 'Botany']);
    }
    final subjectList = subjects.toList();
    String activeModalSub = subjectList.contains(_currentSubjectName) ? _currentSubjectName : subjectList.first;

    return StatefulBuilder(
      builder: (modalCtx, setModalState) {
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

              // 5-Column Question Grid Matrix
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: widget.questions.length,
                  itemBuilder: (gridCtx, qIdx) {
                    final isCur = qIdx == _currentIndex;
                    final ans = _selectedAnswers[qIdx];
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
                        _savePracticeSession();
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
        userAnswers: _selectedAnswers,
        onBackToDashboard: widget.onFinish,
        onRetryTest: () {
          setState(() {
            _submittedAttempt = null;
            _clearPracticeSession();
          });
        },
      );
    }

    if (widget.questions.isEmpty) {
      return const Center(child: Text('No practice questions available.'));
    }

    final question = widget.questions[_currentIndex];
    final selectedAns = _selectedAnswers[_currentIndex];
    final isAnswered = _hasAnswered[_currentIndex] == true;
    final isCorrect = _isCorrectMap[_currentIndex] ?? false;
    final isMarked = _markedForReview.contains(_currentIndex);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
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
                            widget.timerMinutes > 0 ? _formattedTime : 'Practice Mode',
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
                    onPressed: _confirmFinish,
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
                        final ans = _selectedAnswers[idx];
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
                            _savePracticeSession();
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
                                  } else if (val == 'report') {
                                    _showReportDialog(question.id);
                                  } else if (val == 'clear') {
                                    _clearResponse();
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(value: 'copy', child: Row(children: [Icon(Icons.copy_rounded, size: 16), SizedBox(width: 8), Text('Copy Question')])),
                                  const PopupMenuItem(value: 'report', child: Row(children: [Icon(Icons.flag_outlined, size: 16), SizedBox(width: 8), Text('Report Question')])),
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
                        child: _buildNumericalField(question, selectedAns),
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
                            final bool isSelected = _isOptSelected(selectedAns, optKey, optLetter, opt.optionText);

                            Color cardBg = Colors.white;
                            Color borderColor = const Color(0xFFE2E8F0);
                            Color textColor = const Color(0xFF0F172A);

                            if (isAnswered) {
                              if (opt.isCorrect) {
                                cardBg = const Color(0xFFF0FDF4);
                                borderColor = const Color(0xFF22C55E);
                                textColor = const Color(0xFF15803D);
                              } else if (isSelected) {
                                cardBg = const Color(0xFFFEF2F2);
                                borderColor = const Color(0xFFEF4444);
                                textColor = const Color(0xFFB91C1C);
                              }
                            } else if (isSelected) {
                              cardBg = const Color(0xFFEEF2FF);
                              borderColor = const Color(0xFF2563EB);
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: InkWell(
                                onTap: () => _selectOption(idx, optKey, opt.optionText),
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: borderColor,
                                      width: isSelected || (isAnswered && opt.isCorrect) ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Index Column with Vertical Divider: "1  |  "
                                      Row(
                                        children: [
                                          Text(
                                            '${idx + 1}',
                                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
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
                                                  fontWeight: isSelected || (isAnswered && opt.isCorrect) ? FontWeight.bold : FontWeight.w500,
                                                  color: textColor,
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

                                      // Radio Circle Selector Button / Feedback Icon
                                      if (isAnswered && opt.isCorrect)
                                        const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 22)
                                      else if (isAnswered && isSelected && !opt.isCorrect)
                                        const Icon(Icons.cancel, color: Color(0xFFEF4444), size: 22)
                                      else
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

                    // PRACTICE FEEDBACK & SOLUTION CARD (WHEN ANSWERED)
                    if (isAnswered)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isCorrect ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isCorrect ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                      color: isCorrect ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isCorrect ? 'Correct Answer!' : 'Incorrect Answer',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isCorrect ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: Icon(
                                    _isAudioMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                                    color: const Color(0xFF64748B),
                                    size: 20,
                                  ),
                                  tooltip: _isAudioMuted ? 'Unmute Sound' : 'Mute Sound',
                                  onPressed: () {
                                    AudioFeedbackService.toggleAudio();
                                    setState(() {
                                      _isAudioMuted = !AudioFeedbackService.isAudioEnabled;
                                    });
                                  },
                                ),
                              ],
                            ),
                            if ((question.explanation != null && question.explanation!.isNotEmpty) || (question.solution != null && question.solution!.isNotEmpty)) ...[
                              const Divider(height: 20, color: Color(0xFFCBD5E1)),
                              const Text(
                                'Solution Explanation:',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF334155)),
                              ),
                              const SizedBox(height: 6),
                              LaTeXView(
                                text: (question.explanation != null && question.explanation!.isNotEmpty) ? question.explanation! : question.solution!,
                                style: const TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ],
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
                        _savePracticeSession();
                      } else {
                        _confirmFinish();
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
                      _currentIndex == widget.questions.length - 1 ? 'Finish Practice' : 'Save & Next',
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

  Widget _buildNumericalField(QuestionModel question, String? selectedAns) {
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
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () => _selectOption(0, controller.text),
          child: const Text('Submit Numerical Answer'),
        ),
      ],
    );
  }
}
