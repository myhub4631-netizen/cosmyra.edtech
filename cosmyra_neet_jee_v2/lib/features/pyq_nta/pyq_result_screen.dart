import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../models/pyq_models.dart';
import '../../shared/widgets/latex_view.dart';

class PYQResultScreen extends StatefulWidget {
  final PYQSessionResultModel result;
  final List<QuestionModel> questions;
  final Map<int, String> userAnswers;
  final VoidCallback onDone;

  const PYQResultScreen({
    Key? key,
    required this.result,
    required this.questions,
    required this.userAnswers,
    required this.onDone,
  }) : super(key: key);

  @override
  State<PYQResultScreen> createState() => _PYQResultScreenState();
}

class _PYQResultScreenState extends State<PYQResultScreen> {
  String _selectedFilter = 'all'; // all, correct, incorrect, unattempted

  @override
  Widget build(BuildContext context) {
    final res = widget.result;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'PYQ Practice Results',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF64748B)),
            onPressed: widget.onDone,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Score Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Color(0x337C3AED), blurRadius: 16, offset: Offset(0, 6)),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    '${res.accuracy.toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  const Text(
                    'Overall Accuracy',
                    style: TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildHeaderStat('Total', '${res.totalQuestions}'),
                      _buildHeaderStat('Correct', '${res.correctCount}'),
                      _buildHeaderStat('Incorrect', '${res.incorrectCount}'),
                      _buildHeaderStat('Skipped', '${res.skippedCount}'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Subject-wise Breakdown Card
            if (res.subjectBreakdowns.isNotEmpty) ...[
              const Text(
                'Subject-wise Performance',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 12),
              ...res.subjectBreakdowns.map((sb) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFFEEF2FF),
                        child: Icon(
                          sb.subjectName == 'Physics'
                              ? Icons.science_outlined
                              : (sb.subjectName == 'Chemistry' ? Icons.science_rounded : Icons.calculate_outlined),
                          color: const Color(0xFF7C3AED),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sb.subjectName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Correct: ${sb.correctCount} • Incorrect: ${sb.incorrectCount}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${sb.accuracy.toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF7C3AED)),
                      ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 24),
            ],

            // Year-wise Breakdown Card
            if (res.yearBreakdowns.isNotEmpty) ...[
              const Text(
                'Year-wise Accuracy',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: res.yearBreakdowns.map((yb) {
                    return Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${yb.year}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${yb.accuracy.toStringAsFixed(0)}%',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF16A34A)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 28),
            ],

            // Question Review Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Detailed Question Review',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedFilter,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Questions')),
                      DropdownMenuItem(value: 'correct', child: Text('Correct')),
                      DropdownMenuItem(value: 'incorrect', child: Text('Incorrect')),
                      DropdownMenuItem(value: 'unattempted', child: Text('Unattempted')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedFilter = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Review List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.questions.length,
              itemBuilder: (context, idx) {
                final q = widget.questions[idx];
                final userAns = widget.userAnswers[idx];
                bool isCorrect = false;
                if (userAns != null) {
                  if (q.qType == 'numerical') {
                    isCorrect = userAns.trim() == (q.numericalAnswer ?? '').trim();
                  } else {
                    isCorrect = q.options.any((o) => o.isCorrect && o.optionText == userAns);
                  }
                }

                if (_selectedFilter == 'correct' && !isCorrect) return const SizedBox.shrink();
                if (_selectedFilter == 'incorrect' && (userAns == null || isCorrect)) return const SizedBox.shrink();
                if (_selectedFilter == 'unattempted' && userAns != null) return const SizedBox.shrink();

                final correctOption = q.options.firstWhere((o) => o.isCorrect, orElse: () => q.options.first);

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Question ${idx + 1}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: userAns == null
                                    ? const Color(0xFFF1F5F9)
                                    : (isCorrect ? const Color(0xFFDCFCE7) : const Color(0xFFFFE4E6)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                userAns == null ? 'Skipped' : (isCorrect ? 'Correct (+4)' : 'Incorrect (-1)'),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: userAns == null
                                      ? const Color(0xFF64748B)
                                      : (isCorrect ? const Color(0xFF16A34A) : const Color(0xFFE11D48)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LaTeXView(
                          text: q.questionText,
                          style: const TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Your Answer: ${userAns ?? "Not Attempted"}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: userAns == null ? Colors.grey : (isCorrect ? Colors.green : Colors.red),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Correct Answer: ${correctOption.optionText}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                        if (q.explanation != null && q.explanation!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Explanation / Solution:',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                ),
                                const SizedBox(height: 4),
                                LaTeXView(
                                  text: q.explanation!,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Return to Dashboard Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: widget.onDone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'Done & Return to PYQ Practice',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStat(String title, String val) {
    return Column(
      children: [
        Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 2),
        Text(title, style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ],
    );
  }
}
