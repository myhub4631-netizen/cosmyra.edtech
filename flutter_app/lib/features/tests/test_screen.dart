import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../shared/widgets/latex_view.dart';
import '../../core/services/supabase_service.dart';

class CustomTestScreen extends StatefulWidget {
  final List<QuestionModel> questions;
  final int durationMinutes;
  final Function(TestAttemptModel attempt, Map<int, String> answers) onTestSubmitted;

  const CustomTestScreen({
    super.key,
    required this.questions,
    this.durationMinutes = 60,
    required this.onTestSubmitted,
  });

  @override
  State<CustomTestScreen> createState() => _CustomTestScreenState();
}

class _CustomTestScreenState extends State<CustomTestScreen> {
  int _currentIndex = 0;
  final Map<int, String> _userAnswers = {};
  final Set<int> _markedForReview = {};

  late DateTime _startedAt;
  late DateTime _expiresAt;
  Timer? _timer;
  int _secondsRemaining = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _secondsRemaining = widget.durationMinutes > 0 ? widget.durationMinutes * 60 : 3600;
    _expiresAt = _startedAt.add(Duration(seconds: _secondsRemaining));
    _restoreActiveSession();
    _startTimer();
  }

  Future<void> _restoreActiveSession() async {
    final savedSession = await SupabaseService.loadActiveTestSession();
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
    SupabaseService.saveActiveTestSession(
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

  void _selectOption(String optionText) {
    setState(() {
      _userAnswers[_currentIndex] = optionText;
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
            (opt) => opt.optionText == userAns,
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

    // Save to Supabase and storage
    await SupabaseService.submitTestAttempt(
      userId: 'usr-current',
      attempt: attempt,
      questions: widget.questions,
      userAnswers: _userAnswers,
    );

    if (mounted) {
      widget.onTestSubmitted(attempt, _userAnswers);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return const Center(child: Text('No test questions loaded.'));
    }

    final question = widget.questions[_currentIndex];
    final selectedAns = _userAnswers[_currentIndex];
    final isMarked = _markedForReview.contains(_currentIndex);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${_currentIndex + 1} of ${widget.questions.length}'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 1,
        actions: [
          // Countdown Timer Chip
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _secondsRemaining < 300 ? Colors.red : const Color(0xFF4F46E5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  '${(_secondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _confirmSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('SUBMIT TEST', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // Question Content Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Test Header Bar (Marking Scheme + Controls)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Chip(
                        label: Text('Marking: +${question.marks.toInt()} / -${question.negativeMarks.toInt()}'),
                        backgroundColor: const Color(0xFFF1F5F9),
                        side: BorderSide.none,
                      ),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: _toggleMarkForReview,
                            icon: Icon(
                              isMarked ? Icons.bookmark : Icons.bookmark_border,
                              color: isMarked ? Colors.amber : const Color(0xFF64748B),
                            ),
                            label: Text(isMarked ? 'Marked for Review' : 'Mark for Review'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: selectedAns != null ? _clearResponse : null,
                            child: const Text('Clear Answer'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Question Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LaTeXView(
                            text: question.questionText,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 17, height: 1.4),
                          ),
                          if (question.questionImage != null) ...[
                            const SizedBox(height: 12),
                            Image.network(question.questionImage!, height: 180, fit: BoxFit.contain),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Options List (STRICT NO ANSWER REVEAL / NO CORRECTNESS HIGHLIGHT DURING TEST)
                  if (question.qType == 'numerical')
                    _buildNumericalField(selectedAns)
                  else
                    ...question.options.map((opt) {
                      final isSelected = selectedAns == opt.optionText;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: InkWell(
                          onTap: () => _selectOption(opt.optionText),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFF1F5F9),
                                  child: Text(
                                    String.fromCharCode(65 + opt.optionIndex),
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : const Color(0xFF475569),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                 Expanded(
                                   child: Column(
                                     crossAxisAlignment: CrossAxisAlignment.start,
                                     children: [
                                       if (opt.optionText.isNotEmpty) LaTeXView(text: opt.optionText),
                                       if (opt.optionImage != null && opt.optionImage!.isNotEmpty) ...[
                                         if (opt.optionText.isNotEmpty) const SizedBox(height: 6),
                                         Image.network(
                                           opt.optionImage!,
                                           height: 120,
                                           fit: BoxFit.contain,
                                           errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                         ),
                                       ],
                                     ],
                                   ),
                                 ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                  const SizedBox(height: 32),

                  // Bottom Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _currentIndex > 0 ? () => setState(() => _currentIndex--) : null,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Previous'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          if (_currentIndex < widget.questions.length - 1) {
                            setState(() => _currentIndex++);
                          } else {
                            _confirmSubmit();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: Icon(_currentIndex == widget.questions.length - 1 ? Icons.check_circle_outline : Icons.arrow_forward, color: Colors.white),
                        label: Text(
                          _currentIndex == widget.questions.length - 1 ? 'Review & Submit' : 'Next Question',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Question Palette Sidebar on Desktop
          if (isDesktop)
            Container(
              width: 240,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(left: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Question Palette', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                  const SizedBox(height: 12),
                  const Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _PaletteLegend(color: Color(0xFF4F46E5), label: 'Answered'),
                      _PaletteLegend(color: Colors.amber, label: 'Review'),
                      _PaletteLegend(color: Color(0xFFCBD5E1), label: 'Unanswered'),
                    ],
                  ),
                  const SizedBox(height: 16),
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
                        final isAns = _userAnswers.containsKey(idx);
                        final isRev = _markedForReview.contains(idx);

                        Color bg = const Color(0xFFF1F5F9);
                        if (isAns) bg = const Color(0xFF4F46E5);
                        if (isRev) bg = Colors.amber;

                        return InkWell(
                          onTap: () => setState(() => _currentIndex = idx),
                          child: Container(
                            decoration: BoxDecoration(
                              color: bg,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isCur ? const Color(0xFF0F172A) : Colors.transparent,
                                width: isCur ? 3.0 : 0,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${idx + 1}',
                                style: TextStyle(
                                  color: isAns || isRev ? Colors.white : const Color(0xFF475569),
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

class _PaletteLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _PaletteLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
      ],
    );
  }
}
