import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../shared/widgets/latex_view.dart';

class CustomTestScreen extends StatefulWidget {
  final List<QuestionModel> questions;
  final int durationMinutes;
  final Function(TestAttemptModel attempt, Map<int, String> answers) onTestSubmitted;

  const CustomTestScreen({
    Key? key,
    required this.questions,
    this.durationMinutes = 60,
    required this.onTestSubmitted,
  }) : super(key: key);

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
    _expiresAt = _startedAt.add(Duration(minutes: widget.durationMinutes));
    _secondsRemaining = widget.durationMinutes * 60;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsRemaining <= 1) {
        t.cancel();
        _submitTest(auto: true);
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

  void _selectOption(String optionText) {
    setState(() {
      _userAnswers[_currentIndex] = optionText;
    });
  }

  void _clearResponse() {
    setState(() {
      _userAnswers.remove(_currentIndex);
    });
  }

  void _toggleMarkForReview() {
    setState(() {
      if (_markedForReview.contains(_currentIndex)) {
        _markedForReview.remove(_currentIndex);
      } else {
        _markedForReview.add(_currentIndex);
      }
    });
  }

  void _confirmSubmit() {
    final attemptedCount = _userAnswers.length;
    final totalCount = widget.questions.length;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Examination?'),
        content: Text(
          'You have attempted $attemptedCount out of $totalCount questions.\n\nAre you sure you want to submit your test?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel & Resume')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _submitTest(auto: false);
            },
            child: const Text('Confirm Submission'),
          ),
        ],
      ),
    );
  }

  void _submitTest({required bool auto}) {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    _timer?.cancel();

    // Calculate Test Score Server-Style (+4 for correct, -1 for incorrect)
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

    final attempt = TestAttemptModel(
      id: 'att-${DateTime.now().millisecondsSinceEpoch}',
      userId: 'usr-demo-123',
      testTemplateId: 'tmpl-custom',
      testTitle: 'Custom NEET/JEE Full Mock Test',
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
      timeSpentSeconds: (widget.durationMinutes * 60) - _secondsRemaining,
    );

    widget.onTestSubmitted(attempt, _userAnswers);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return const Center(child: Text('No test questions loaded.'));
    }

    final question = widget.questions[_currentIndex];
    final selectedAns = _userAnswers[_currentIndex];
    final isMarked = _markedForReview.contains(_currentIndex);

    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${_currentIndex + 1} of ${widget.questions.length}'),
        actions: [
          // Countdown Timer Chip
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _secondsRemaining < 300 ? Colors.red : Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  '${(_secondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _confirmSubmit,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Submit Test'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          // Question Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Test Header & Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Marking: +${question.marks.toInt()} / -${question.negativeMarks.toInt()}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: _toggleMarkForReview,
                            icon: Icon(isMarked ? Icons.bookmark : Icons.bookmark_border, color: Colors.amber),
                            label: Text(isMarked ? 'Marked for Review' : 'Mark for Review'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: _clearResponse,
                            child: const Text('Clear Answer'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Question Card (HIDDEN SOLUTIONS & ANSWERS DURING TEST)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: LaTeXView(
                        text: question.questionText,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 17, height: 1.4),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Options (Only highlight user selected option, correct answer is HIDDEN)
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
                              color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.12) : Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).dividerColor.withOpacity(0.2),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: isSelected ? Theme.of(context).primaryColor : Colors.grey.withOpacity(0.2),
                                  child: Text(
                                    String.fromCharCode(65 + opt.optionIndex),
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.black87,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(child: LaTeXView(text: opt.optionText)),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                  const SizedBox(height: 32),

                  // Navigation Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton(
                        onPressed: _currentIndex > 0 ? () => setState(() => _currentIndex--) : null,
                        child: const Text('Previous'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (_currentIndex < widget.questions.length - 1) {
                            setState(() => _currentIndex++);
                          } else {
                            _confirmSubmit();
                          }
                        },
                        child: Text(_currentIndex == widget.questions.length - 1 ? 'Review & Submit' : 'Next Question'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Question Palette Side Navigation
          Container(
            width: 240,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(left: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Question Palette', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                const Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _PaletteLegend(color: Colors.green, label: 'Attempted'),
                    _PaletteLegend(color: Colors.amber, label: 'Review'),
                    _PaletteLegend(color: Colors.grey, label: 'Unattempted'),
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

                      Color bg = Colors.grey.withOpacity(0.15);
                      if (isAns) bg = Colors.green;
                      if (isRev) bg = Colors.amber;

                      return InkWell(
                        onTap: () => setState(() => _currentIndex = idx),
                        child: Container(
                          decoration: BoxDecoration(
                            color: bg,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isCur ? Theme.of(context).primaryColor : Colors.transparent,
                              width: isCur ? 3.0 : 0,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${idx + 1}',
                              style: TextStyle(
                                color: isAns || isRev ? Colors.white : Colors.black87,
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
          decoration: const InputDecoration(labelText: 'Numerical Answer'),
          onChanged: (val) => _selectOption(val),
        ),
      ],
    );
  }
}

class _PaletteLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _PaletteLegend({Key? key, required this.color, required this.label}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
