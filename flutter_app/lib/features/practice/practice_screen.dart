import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../shared/widgets/latex_view.dart';
import '../../core/services/supabase_service.dart';

class PracticeScreen extends StatefulWidget {
  final List<QuestionModel> questions;
  final int timerMinutes;
  final VoidCallback onFinish;

  const PracticeScreen({
    Key? key,
    required this.questions,
    this.timerMinutes = 0,
    required this.onFinish,
  }) : super(key: key);

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  int _currentIndex = 0;
  final Map<int, String> _selectedAnswers = {};
  final Map<int, bool> _hasAnswered = {};
  final Set<int> _markedForReview = {};
  final Map<int, bool> _isCorrectMap = {};

  Timer? _timer;
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    if (widget.timerMinutes > 0) {
      _secondsRemaining = widget.timerMinutes * 60;
      _startTimer();
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

    final textVal = optionText ?? optKey;
    if (question.qType == 'numerical') {
      isCorrect = textVal.trim() == (question.numericalAnswer ?? '').trim();
    } else {
      isCorrect = question.options[optionIndex].isCorrect;
    }

    setState(() {
      _selectedAnswers[_currentIndex] = optKey;
      _hasAnswered[_currentIndex] = true;
      _isCorrectMap[_currentIndex] = isCorrect;
    });
  }

  void _finishPracticeSession() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Practice Session Complete 🎉'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Questions: ${widget.questions.length}'),
            Text('Attempted: ${_selectedAnswers.length}'),
            Text('Correct: ${_isCorrectMap.values.where((v) => v).length}'),
            Text('Incorrect: ${_isCorrectMap.values.where((v) => !v).length}'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onFinish();
            },
            child: const Text('Return to Dashboard'),
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

  @override
  Widget build(BuildContext context) {
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
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Metadata Tags Header
                  Row(
                    children: [
                      Chip(
                        label: Text(question.difficulty.toUpperCase()),
                        backgroundColor: question.difficulty == 'easy'
                            ? Colors.green.withOpacity(0.15)
                            : (question.difficulty == 'hard' ? Colors.red.withOpacity(0.15) : Colors.orange.withOpacity(0.15)),
                        side: BorderSide.none,
                      ),
                      const SizedBox(width: 8),
                      Chip(label: Text(question.source.toUpperCase())),
                      if (question.year != null) ...[
                        const SizedBox(width: 8),
                        Chip(label: Text('${question.year}')),
                      ],
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          _markedForReview.contains(_currentIndex) ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          color: _markedForReview.contains(_currentIndex) ? Colors.amber : null,
                        ),
                        onPressed: () {
                          setState(() {
                            if (_markedForReview.contains(_currentIndex)) {
                              _markedForReview.remove(_currentIndex);
                            } else {
                              _markedForReview.add(_currentIndex);
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Question Text Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
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

                  const SizedBox(height: 20),

                  // Options List
                  if (question.qType == 'numerical')
                    _buildNumericalInput(question)
                  else
                    ...question.options.map((opt) {
                      final String optKey = (opt.id != null && opt.id.isNotEmpty) ? opt.id : 'opt_${question.id}_${opt.optionIndex}';
                      final String optLetter = String.fromCharCode(65 + opt.optionIndex);
                      final optionText = opt.optionText;
                      final isSelected = _isOptSelected(_selectedAnswers[_currentIndex], optKey, optLetter, optionText);
                      final isThisCorrect = opt.isCorrect;

                      Color optionBorderColor = Theme.of(context).dividerColor.withOpacity(0.2);
                      Color optionBgColor = Theme.of(context).cardColor;

                      if (isAnswered) {
                        if (isThisCorrect) {
                          optionBorderColor = Colors.green;
                          optionBgColor = Colors.green.withOpacity(0.08);
                        } else if (isSelected && !isThisCorrect) {
                          optionBorderColor = Colors.red;
                          optionBgColor = Colors.red.withOpacity(0.08);
                        }
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: InkWell(
                          key: ValueKey('opt_practice_${question.id}_${opt.optionIndex}'),
                          onTap: () => _selectOption(opt.optionIndex, optKey, optionText),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: optionBgColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: optionBorderColor, width: isAnswered && (isThisCorrect || isSelected) ? 2 : 1),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: isAnswered && isThisCorrect
                                      ? Colors.green
                                      : (isAnswered && isSelected && !isThisCorrect
                                          ? Colors.red
                                          : Theme.of(context).primaryColor.withOpacity(0.1)),
                                  child: Text(
                                    optLetter,
                                    style: TextStyle(
                                      color: isAnswered && (isThisCorrect || (isSelected && !isThisCorrect))
                                          ? Colors.white
                                          : Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (optionText.isNotEmpty) LaTeXView(text: optionText),
                                      if (opt.optionImage != null && opt.optionImage!.isNotEmpty) ...[
                                        if (optionText.isNotEmpty) const SizedBox(height: 6),
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
                                if (isAnswered && isThisCorrect)
                                  const Icon(Icons.check_circle_rounded, color: Colors.green)
                                else if (isAnswered && isSelected && !isThisCorrect)
                                  const Icon(Icons.cancel_rounded, color: Colors.red),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                  // Immediate Feedback Box
                  if (isAnswered) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isCorrect ? Colors.green.withOpacity(0.08) : Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isCorrect ? Colors.green : Colors.red),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(isCorrect ? Icons.check_circle : Icons.error, color: isCorrect ? Colors.green : Colors.red),
                              const SizedBox(width: 8),
                              Text(
                                isCorrect ? '✅ Correct Answer!' : '❌ Incorrect Answer',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isCorrect ? Colors.green.shade800 : Colors.red.shade800,
                                ),
                              ),
                            ],
                          ),
                          if (question.explanation != null) ...[
                            const SizedBox(height: 12),
                            const Text('Explanation:', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            LaTeXView(text: question.explanation!),
                          ],
                          if (question.solution != null) ...[
                            const SizedBox(height: 10),
                            const Text('Step-by-Step Solution:', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            LaTeXView(text: question.solution!),
                          ],
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Bottom Controls (Previous, Clear, Next, Finish)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _currentIndex > 0 ? () => setState(() => _currentIndex--) : null,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Previous'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (_currentIndex < widget.questions.length - 1) {
                            setState(() => _currentIndex++);
                          } else {
                            _finishPracticeSession();
                          }
                        },
                        child: Text(_currentIndex == widget.questions.length - 1 ? 'Finish Practice' : 'Next Question'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Question Palette Sidebar on Desktop
          if (MediaQuery.of(context).size.width >= 900)
            Container(
              width: 220,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(left: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Question Palette', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                        final isAns = _hasAnswered[idx] == true;
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
                              border: Border.all(color: isCur ? Theme.of(context).primaryColor : Colors.transparent, width: 2),
                            ),
                            child: Center(
                              child: Text(
                                '${idx + 1}',
                                style: TextStyle(
                                  color: isAns ? Colors.white : Colors.black87,
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
