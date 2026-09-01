import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/models.dart';
import '../../shared/widgets/latex_view.dart';
import '../../shared/widgets/smart_image.dart';
import '../../shared/widgets/question_feedback_view.dart';
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
      } else {
        _currentStreak = 0;
      }
    });

    _savePracticeSession();
  }

  Widget _buildPaletteLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
      ],
    );
  }

  TestAttemptModel? _submittedAttempt;

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
    final isAnswered = _hasAnswered[_currentIndex] == true;
    final isCorrect = _isCorrectMap[_currentIndex] ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${_currentIndex + 1} of ${widget.questions.length}'),
        actions: [
          if (widget.timerMinutes > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Chip(
                avatar: const Icon(Icons.timer, size: 18, color: Colors.white),
                label: Text(
                  '${(_secondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                backgroundColor: _secondsRemaining < 120 ? Colors.red : Theme.of(context).primaryColor,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.flag_outlined),
            tooltip: 'Report Question',
            onPressed: () => _showReportDialog(question.id),
          ),
        ],
      ),
      body: Row(
        children: [
          // Main Question View
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: QuestionFeedbackView(
                    question: question,
                    questionIndex: _currentIndex,
                    totalQuestions: widget.questions.length,
                    selectedAnswer: _selectedAnswers[_currentIndex],
                    isAnswered: isAnswered,
                    isCorrect: isCorrect,
                    currentStreak: _currentStreak,
                    currentScore: (_isCorrectMap.values.where((v) => v).length * 4.0) - (_isCorrectMap.values.where((v) => !v).length * 1.0),
                    onOptionSelected: (idx) {
                      final opt = question.options[idx];
                      final String optKey = (opt.id != null && opt.id.isNotEmpty) ? opt.id : 'opt_${question.id}_${opt.optionIndex}';
                      _selectOption(idx, optKey, opt.optionText);
                    },
                    onNextQuestion: () {
                      if (_currentIndex < widget.questions.length - 1) {
                        setState(() => _currentIndex++);
                      } else {
                        _finishPracticeSession();
                      }
                    },
                    isLastQuestion: _currentIndex == widget.questions.length - 1,
                    isAudioMuted: _isAudioMuted,
                    onToggleAudio: () {
                      AudioFeedbackService.toggleAudio();
                      setState(() {
                        _isAudioMuted = !AudioFeedbackService.isAudioEnabled;
                      });
                    },
                    isBookmarked: _markedForReview.contains(_currentIndex),
                    onBookmarkToggle: () {
                      setState(() {
                        if (_markedForReview.contains(_currentIndex)) {
                          _markedForReview.remove(_currentIndex);
                        } else {
                          _markedForReview.add(_currentIndex);
                        }
                      });
                    },
                    onReportQuestion: () => _showReportDialog(question.id),
                  ),
                ),
              ),
            ),
          ),

          // Question Palette Sidebar on Desktop
          if (MediaQuery.of(context).size.width >= 900)
            Container(
              width: 230,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(left: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Question Palette', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildPaletteLegendDot(const Color(0xFF22C55E), 'Correct'),
                      _buildPaletteLegendDot(const Color(0xFFEF4444), 'Wrong'),
                      _buildPaletteLegendDot(const Color(0xFFEAB308), 'Partial/Review'),
                      _buildPaletteLegendDot(const Color(0xFF6366F1), 'Current'),
                      _buildPaletteLegendDot(const Color(0xFFCBD5E1), 'Skipped'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: widget.questions.length,
                      itemBuilder: (ctx, idx) {
                        final isCur = idx == _currentIndex;
                        final hasAns = _hasAnswered[idx] == true || _selectedAnswers.containsKey(idx);
                        final isCorr = _isCorrectMap[idx];
                        final isPart = _isPartialMap[idx] == true;
                        final isRev = _markedForReview.contains(idx);

                        Color bg = const Color(0xFFCBD5E1); // Grey default
                        Color textClr = const Color(0xFF334155);

                        if (hasAns) {
                          if (isCorr == true) {
                            bg = const Color(0xFF22C55E); // Green = Correct
                            textClr = Colors.white;
                          } else if (isPart) {
                            bg = const Color(0xFFEAB308); // Yellow = Partial
                            textClr = Colors.white;
                          } else {
                            bg = const Color(0xFFEF4444); // Red = Wrong
                            textClr = Colors.white;
                          }
                        } else if (isRev) {
                          bg = const Color(0xFFEAB308); // Yellow = Review
                          textClr = Colors.white;
                        } else if (isCur) {
                          bg = const Color(0xFF6366F1); // Purple/Blue = Current Unanswered
                          textClr = Colors.white;
                        }

                        return InkWell(
                          onTap: () {
                            setState(() => _currentIndex = idx);
                            _savePracticeSession();
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: bg,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isCur ? const Color(0xFF1E1B4B) : Colors.transparent,
                                width: isCur ? 3.0 : 0,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${idx + 1}',
                                style: TextStyle(
                                  color: textClr,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNumericalInput(QuestionModel question) {
    final controller = TextEditingController();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Enter Numerical Answer (Decimal / Integer)',
            hintText: 'e.g. 20.5',
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
