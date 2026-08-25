import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../shared/widgets/latex_view.dart';

class TestResultScreen extends StatefulWidget {
  final TestAttemptModel attempt;
  final List<QuestionModel> questions;
  final Map<int, String> userAnswers;
  final VoidCallback onBackToDashboard;

  const TestResultScreen({
    Key? key,
    required this.attempt,
    required this.questions,
    required this.userAnswers,
    required this.onBackToDashboard,
  }) : super(key: key);

  @override
  State<TestResultScreen> createState() => _TestResultScreenState();
}

class _TestResultScreenState extends State<TestResultScreen> {
  String _filter = 'ALL'; // ALL, CORRECT, INCORRECT, UNATTEMPTED

  @override
  Widget build(BuildContext context) {
    final attempt = widget.attempt;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card with Score Overview
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  attempt.testTitle,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Submitted at ${attempt.submittedAt?.hour}:${attempt.submittedAt?.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 24),

                // Score Circle Display
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Text(
                          '${attempt.totalScore?.toInt()} / ${attempt.maxMarks?.toInt()}',
                          style: const TextStyle(color: Colors.amber, fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                        const Text('Total Score', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                    Container(height: 50, width: 1, color: Colors.white24),
                    Column(
                      children: [
                        Text(
                          '${attempt.accuracy}%',
                          style: const TextStyle(color: Color(0xFF10B981), fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                        const Text('Accuracy', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                    Container(height: 50, width: 1, color: Colors.white24),
                    Column(
                      children: [
                        Text(
                          '${attempt.timeSpentSeconds ~/ 60}m ${attempt.timeSpentSeconds % 60}s',
                          style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                        const Text('Time Spent', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Attempt Performance Breakdown Grid
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'Correct',
                  value: '${attempt.correctCount}',
                  color: Colors.green,
                  icon: Icons.check_circle_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  title: 'Incorrect',
                  value: '${attempt.incorrectCount}',
                  color: Colors.red,
                  icon: Icons.cancel_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  title: 'Unattempted',
                  value: '${attempt.unattemptedCount}',
                  color: Colors.grey,
                  icon: Icons.help_outline_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  title: 'Avg Time / Question',
                  value: '${attempt.attemptedCount > 0 ? (attempt.timeSpentSeconds ~/ attempt.attemptedCount) : 0} sec',
                  color: Colors.purple,
                  icon: Icons.timer_outlined,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Detailed Solutions Review Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question Solutions & Explanations Review',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: widget.onBackToDashboard,
                icon: const Icon(Icons.home),
                label: const Text('Back to Dashboard'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Filter Segmented Buttons
          Row(
            children: [
              ChoiceChip(
                label: Text('All (${widget.questions.length})'),
                selected: _filter == 'ALL',
                onSelected: (val) => setState(() => _filter = 'ALL'),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text('Correct (${attempt.correctCount})'),
                selected: _filter == 'CORRECT',
                onSelected: (val) => setState(() => _filter = 'CORRECT'),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text('Incorrect (${attempt.incorrectCount})'),
                selected: _filter == 'INCORRECT',
                onSelected: (val) => setState(() => _filter = 'INCORRECT'),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text('Unattempted (${attempt.unattemptedCount})'),
                selected: _filter == 'UNATTEMPTED',
                onSelected: (val) => setState(() => _filter = 'UNATTEMPTED'),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Question Review List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.questions.length,
            itemBuilder: (ctx, idx) {
              final q = widget.questions[idx];
              final userAns = widget.userAnswers[idx];
              bool isCorrect = false;
              String correctText = '';

              if (q.qType == 'numerical') {
                correctText = q.numericalAnswer ?? '';
                isCorrect = userAns?.trim() == correctText.trim();
              } else {
                final correctOpt = q.options.firstWhere(
                  (o) => o.isCorrect,
                  orElse: () => QuestionOptionModel(id: '', questionId: '', optionIndex: 0, optionText: 'N/A', isCorrect: true),
                );
                correctText = correctOpt.optionText;
                isCorrect = userAns == correctText;
              }

              final isAttempted = userAns != null && userAns.isNotEmpty;

              if (_filter == 'CORRECT' && (!isAttempted || !isCorrect)) return const SizedBox.shrink();
              if (_filter == 'INCORRECT' && (!isAttempted || isCorrect)) return const SizedBox.shrink();
              if (_filter == 'UNATTEMPTED' && isAttempted) return const SizedBox.shrink();

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: !isAttempted
                                ? Colors.grey
                                : (isCorrect ? Colors.green : Colors.red),
                            child: Text(
                              '${idx + 1}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            !isAttempted ? 'UNATTEMPTED' : (isCorrect ? 'CORRECT (+4)' : 'INCORRECT (-1)'),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: !isAttempted ? Colors.grey : (isCorrect ? Colors.green : Colors.red),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LaTeXView(text: q.questionText),
                      const SizedBox(height: 14),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('Your Answer: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                Expanded(child: LaTeXView(text: userAns ?? 'Not Attempted')),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Text('Correct Answer: ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                Expanded(child: LaTeXView(text: correctText)),
                              ],
                            ),
                          ],
                        ),
                      ),

                      if (q.explanation != null || q.solution != null) ...[
                        const SizedBox(height: 12),
                        const Text('Solution & Explanation:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        LaTeXView(text: q.solution ?? q.explanation!),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 2),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
