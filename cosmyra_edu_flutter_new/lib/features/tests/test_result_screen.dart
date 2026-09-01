import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../shared/widgets/latex_view.dart';
import 'exam_config_engine.dart';
import '../leaderboard/leaderboard_screen.dart';

class TestResultScreen extends StatefulWidget {
  final TestAttemptModel attempt;
  final List<QuestionModel> questions;
  final Map<int, String> userAnswers;
  final VoidCallback onBackToDashboard;
  final VoidCallback? onRetryTest;
  final VoidCallback? onPracticeSimilar;

  const TestResultScreen({
    Key? key,
    required this.attempt,
    required this.questions,
    required this.userAnswers,
    required this.onBackToDashboard,
    this.onRetryTest,
    this.onPracticeSimilar,
  }) : super(key: key);

  @override
  State<TestResultScreen> createState() => _TestResultScreenState();
}

class _TestResultScreenState extends State<TestResultScreen> {
  String _filter = 'ALL'; // ALL, CORRECT, INCORRECT, UNATTEMPTED
  bool _showSolutions = false;
  final ScrollController _scrollController = ScrollController();

  late ExamPredictionModel _prediction;

  @override
  void initState() {
    super.initState();
    _prediction = ExamConfigEngine.calculatePredictions(
      testTitle: widget.attempt.testTitle,
      score: widget.attempt.totalScore ?? 0,
      maxScore: widget.attempt.maxMarks ?? (widget.questions.length * 4.0),
      accuracy: widget.attempt.accuracy,
      totalQuestions: widget.questions.length,
      attemptedCount: widget.attempt.attemptedCount,
    );
  }

  void _scrollToSolutions() {
    setState(() => _showSolutions = true);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final attempt = widget.attempt;
    final double maxScore = attempt.maxMarks ?? (widget.questions.length * 4.0);
    final double userScore = attempt.totalScore ?? 0.0;
    final int minutesSpent = attempt.timeSpentSeconds ~/ 60;
    final int secondsSpent = attempt.timeSpentSeconds % 60;
    final String timeStr = '${minutesSpent.toString().padLeft(2, '0')}:${secondsSpent.toString().padLeft(2, '0')}';
    final int avgSecsPerQ = attempt.attemptedCount > 0 ? (attempt.timeSpentSeconds ~/ attempt.attemptedCount) : 0;
    final String avgTimeStr = '${(avgSecsPerQ ~/ 60).toString().padLeft(2, '0')}:${(avgSecsPerQ % 60).toString().padLeft(2, '0')}';

    final dateSubmitted = attempt.submittedAt ?? DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final String dateStr = '${dateSubmitted.day.toString().padLeft(2, '0')} ${months[dateSubmitted.month - 1]} ${dateSubmitted.year}, ${dateSubmitted.hour.toString().padLeft(2, '0')}:${dateSubmitted.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. HEADER BAR
                  _buildHeader(context),

                  const SizedBox(height: 20),

                  // 2. TEST SUMMARY CARD
                  _buildTestSummaryCard(attempt, dateStr),

                  const SizedBox(height: 20),

                  // 3. PERFORMANCE CARD
                  _buildPerformanceCard(attempt, userScore, maxScore, timeStr, avgTimeStr),

                  const SizedBox(height: 20),

                  // 4. LEADERBOARD BENCHMARK CARD
                  _buildLeaderboardCard(),

                  const SizedBox(height: 20),

                  // 5 & 6. AIR TRACKER + COLLEGE PREDICTOR ROW
                  LayoutBuilder(
                    builder: (ctx, constraints) {
                      if (constraints.maxWidth > 720) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildAirTrackerCard()),
                            const SizedBox(width: 20),
                            Expanded(child: _buildCollegePredictorCard()),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          _buildAirTrackerCard(),
                          const SizedBox(height: 20),
                          _buildCollegePredictorCard(),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // 7. CUTOFF PREDICTOR TABLE + AIM HIGHER TARGET CARD
                  LayoutBuilder(
                    builder: (ctx, constraints) {
                      if (constraints.maxWidth > 760) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: _buildCutoffTableCard()),
                            const SizedBox(width: 20),
                            Expanded(flex: 2, child: _buildTargetCard()),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          _buildCutoffTableCard(),
                          const SizedBox(height: 20),
                          _buildTargetCard(),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // 8. QUICK ACTIONS GRID
                  _buildQuickActionsGrid(attempt),

                  const SizedBox(height: 24),

                  // 9. WHAT'S NEXT CARD
                  _buildWhatsNextCard(context),

                  const SizedBox(height: 24),

                  // 10. FINAL STICKY CTA FOOTER
                  _buildFinalFooterCTA(context),

                  // SOLUTIONS REVIEW SECTION (TOGGLEABLE)
                  if (_showSolutions) ...[
                    const SizedBox(height: 32),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 24),
                    _buildSolutionsReviewSection(context, attempt),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 1. HEADER
  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: widget.onBackToDashboard,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                child: Row(
                  children: const [
                    Icon(Icons.arrow_back, size: 20, color: Color(0xFF475569)),
                    SizedBox(width: 6),
                    Text('Back', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569), fontSize: 14)),
                  ],
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Test performance link copied to clipboard!'), duration: Duration(seconds: 2)),
                );
              },
              icon: const Icon(Icons.share_outlined, size: 16, color: Color(0xFF4F46E5)),
              label: const Text('Share', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w600, fontSize: 13)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFC7D2FE)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: Color(0xFF10B981),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Color(0x3310B981), blurRadius: 12, offset: Offset(0, 4)),
            ],
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
        ),
        const SizedBox(height: 10),
        const Text(
          'Test Completed!',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.5),
        ),
        const SizedBox(height: 4),
        const Text(
          'Outstanding effort! Keep practicing and improve your rank.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // 2. TEST SUMMARY CARD
  Widget _buildTestSummaryCard(TestAttemptModel attempt, String dateStr) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.assignment_outlined, color: Color(0xFF4F46E5), size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attempt.testTitle,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    _buildMetaChip('${widget.questions.length} Questions'),
                    _buildMetaChip('${(attempt.maxMarks ?? (widget.questions.length * 4)).toInt()} Marks'),
                    _buildMetaChip(dateStr),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: _scrollToSolutions,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFC7D2FE)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('View Details', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w600, fontSize: 13)),
                SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 16, color: Color(0xFF4F46E5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChip(String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFF94A3B8), shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
      ],
    );
  }

  // 3. PERFORMANCE CARD
  Widget _buildPerformanceCard(TestAttemptModel attempt, double userScore, double maxScore, String timeStr, String avgTimeStr) {
    final int correctPct = attempt.totalQuestions > 0 ? ((attempt.correctCount / attempt.totalQuestions) * 100).round() : 0;
    final int wrongPct = attempt.totalQuestions > 0 ? ((attempt.incorrectCount / attempt.totalQuestions) * 100).round() : 0;
    final int skippedPct = attempt.totalQuestions > 0 ? ((attempt.unattemptedCount / attempt.totalQuestions) * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your Performance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          Row(
            children: [
              // Circular Accuracy Gauge
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 90,
                      height: 90,
                      child: CircularProgressIndicator(
                        value: (attempt.accuracy / 100.0).clamp(0.0, 1.0),
                        strokeWidth: 9,
                        backgroundColor: const Color(0xFFF1F5F9),
                        color: const Color(0xFF10B981),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${attempt.accuracy.round()}%',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                        const Text('Accuracy', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),

              // Breakdown List
              Expanded(
                child: Column(
                  children: [
                    _buildStatRow(Icons.check_circle_outline, const Color(0xFF10B981), 'Correct', '${attempt.correctCount}', '($correctPct%)'),
                    const SizedBox(height: 8),
                    _buildStatRow(Icons.cancel_outlined, const Color(0xFFEF4444), 'Wrong', '${attempt.incorrectCount}', '($wrongPct%)'),
                    const SizedBox(height: 8),
                    _buildStatRow(Icons.remove_circle_outline, const Color(0xFFF59E0B), 'Skipped', '${attempt.unattemptedCount}', '($skippedPct%)'),
                  ],
                ),
              ),

              const SizedBox(width: 16),
              Container(width: 1, height: 90, color: const Color(0xFFE2E8F0)),
              const SizedBox(width: 16),

              // Total Score Box
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Total Score', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${userScore.toInt()} ',
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
                        ),
                        TextSpan(
                          text: '/ ${maxScore.toInt()}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      userScore >= (maxScore * 0.6) ? 'Good Job! 👏' : 'Keep Pushing! 🚀',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF15803D)),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          // Lower Metric Strip
          Row(
            children: [
              Expanded(child: _buildSubMetric(Icons.access_time, const Color(0xFF6366F1), 'Time Taken', timeStr)),
              Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
              Expanded(child: _buildSubMetric(Icons.bar_chart_outlined, const Color(0xFF3B82F6), 'Avg. Time / Q', avgTimeStr)),
              Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
              Expanded(child: _buildSubMetric(Icons.track_changes_outlined, const Color(0xFFEF4444), 'Positive / Negative', '+4 / -1')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, Color color, String label, String val, String pctStr) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(val, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
        const SizedBox(width: 4),
        Text(pctStr, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
      ],
    );
  }

  Widget _buildSubMetric(IconData icon, Color iconColor, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
          ],
        ),
      ],
    );
  }

  // 4. LEADERBOARD BENCHMARK CARD
  Widget _buildLeaderboardCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You beat ${_prediction.beatStudentsCount} students on the leaderboard! 🏆',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF14532D)),
                ),
                const SizedBox(height: 2),
                Text(
                  'Great job! You scored higher than ${_prediction.beatPercentage.round()}% of students who attempted this test.',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF166534), fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => LeaderboardScreen(
                    initialExam: _prediction.examName,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF15803D),
              elevation: 0,
              side: const BorderSide(color: Color(0xFF86EFAC)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: Row(
              children: const [
                Text('View Leaderboard', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 5. AIR TRACKER CARD
  Widget _buildAirTrackerCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Color(0xFFEEF2FF), shape: BoxShape.circle),
                    child: const Icon(Icons.trending_up_rounded, color: Color(0xFF4F46E5), size: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Your ${_prediction.rankTerm} Tracker (Based on Recent Data)',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              InkWell(
                onTap: () {},
                child: const Text('View Trends >', style: TextStyle(fontSize: 12, color: Color(0xFF4F46E5), fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Estimated ${_prediction.rankTerm}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    const SizedBox(height: 2),
                    Text(
                      '${_prediction.estimatedRank}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF4F46E5)),
                    ),
                    Text('Top ${(100 - _prediction.percentile).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 11, color: Color(0xFF4F46E5), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_prediction.rankTerm} Range', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    const SizedBox(height: 2),
                    Text(
                      '${_prediction.rankRangeMin} - ${_prediction.rankRangeMax}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    ),
                    Row(
                      children: const [
                        Icon(Icons.circle, color: Color(0xFF10B981), size: 8),
                        SizedBox(width: 4),
                        Text('Confidence: High', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Previous ${_prediction.rankTerm}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    const SizedBox(height: 2),
                    Text(
                      '${_prediction.previousRank}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    ),
                    Text('↑ ${_prediction.rankImprovement} You improved!', style: const TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          // Micro Trend Sparkline
          SizedBox(
            height: 48,
            child: CustomPaint(
              size: const Size(double.infinity, 48),
              painter: _SparklinePainter(),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Test 1', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
              Text('Test 2', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
              Text('Test 3', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
              Text('Test 4', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
              Text('Latest', style: TextStyle(fontSize: 10, color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text('Keep practicing to improve your AIR!', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  // 6. COLLEGE PREDICTOR CARD
  Widget _buildCollegePredictorCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: Color(0xFFEEF2FF), shape: BoxShape.circle),
                child: const Icon(Icons.verified_user_outlined, color: Color(0xFF4F46E5), size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _prediction.mainCollegeQuestion,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
              ),
              const Icon(Icons.info_outline, size: 16, color: Color(0xFF94A3B8)),
            ],
          ),
          const SizedBox(height: 14),

          // Banner Status
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _prediction.chanceBannerTitle,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF15803D)),
                      ),
                      Text(
                        _prediction.chanceBannerSubtitle,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF166534)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 3 Stat Boxes
          Row(
            children: [
              Expanded(
                child: _buildMiniStatBox(
                  'Your Score (Est.)',
                  '${_prediction.estimatedScore} / ${_prediction.maxMarks}',
                  '${_prediction.percentile.toStringAsFixed(1)} Percentile',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMiniStatBox(
                  'Expected Rank',
                  '${_prediction.rankRangeMin} - ${_prediction.rankRangeMax}',
                  'Top ${(100 - _prediction.percentile).toStringAsFixed(1)}% Students',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMiniStatBox(
                  'College Chance',
                  _prediction.chanceLevel,
                  '${_prediction.chancePercentage}% Probability',
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.track_changes, color: Color(0xFF10B981), size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Keep improving! You can target top ${_prediction.examName} institutes.',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF15803D), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatBox(String title, String val, String sub) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF4F46E5))),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  // 7. CUTOFF TABLE CARD
  Widget _buildCutoffTableCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: Color(0xFF4F46E5), size: 18),
              const SizedBox(width: 8),
              Text(
                '${_prediction.examName} College Cutoff Predictor',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: const [
                Expanded(flex: 3, child: Text('College (Branch/State)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)))),
                Expanded(flex: 2, child: Text('Closing Rank', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)))),
                Expanded(flex: 2, child: Text('Marks', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)))),
                Expanded(flex: 2, child: Text('Your Chance', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)))),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Table Rows
          ..._prediction.collegeCutoffs.map((item) {
            Color pillBg = const Color(0xFFF1F5F9);
            Color pillTxt = const Color(0xFF475569);

            if (item.chanceLevel == 'High') {
              pillBg = const Color(0xFFDCFCE7);
              pillTxt = const Color(0xFF15803D);
            } else if (item.chanceLevel == 'Good') {
              pillBg = const Color(0xFFE0E7FF);
              pillTxt = const Color(0xFF4338CA);
            } else if (item.chanceLevel == 'Moderate') {
              pillBg = const Color(0xFFFEF3C7);
              pillTxt = const Color(0xFFB45309);
            } else {
              pillBg = const Color(0xFFFEE2E2);
              pillTxt = const Color(0xFFB91C1C);
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.collegeName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                        Text(item.locationOrBranch, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  Expanded(flex: 2, child: Text('${item.closingRank}', style: const TextStyle(fontSize: 12, color: Color(0xFF334155)))),
                  Expanded(flex: 2, child: Text('${item.requiredMarks}+', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF10B981)))),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: pillBg, borderRadius: BorderRadius.circular(10)),
                      child: Text(item.chanceLevel, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: pillTxt)),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 8),
          Center(
            child: InkWell(
              onTap: () {},
              child: Text(
                'View All ${_prediction.examName} Colleges & Cutoffs >',
                style: const TextStyle(fontSize: 12, color: Color(0xFF4F46E5), fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 7. TARGET CARD ("Aim Higher!")
  Widget _buildTargetCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.track_changes, color: Color(0xFF4F46E5), size: 20),
              SizedBox(width: 8),
              Text('Aim Higher!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF4F46E5))),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _prediction.targetAdvice,
            style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.4),
          ),
          const SizedBox(height: 16),

          // Target Progress Ring Gauge
          Center(
            child: SizedBox(
              width: 110,
              height: 110,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      value: 0.85,
                      strokeWidth: 10,
                      backgroundColor: const Color(0xFFC7D2FE),
                      color: const Color(0xFF4F46E5),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${_prediction.targetScore}+',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF4F46E5)),
                      ),
                      const Text('Target Score', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Target practice roadmap recommendations loaded!'), duration: Duration(seconds: 2)),
                );
              },
              icon: const Icon(Icons.flash_on, size: 16, color: Colors.white),
              label: const Text('How to Improve? →', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 8. QUICK ACTIONS GRID
  Widget _buildQuickActionsGrid(TestAttemptModel attempt) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionTile(
                icon: Icons.menu_book_outlined,
                iconColor: const Color(0xFF10B981),
                title: 'View Solutions',
                subtitle: 'Step-by-step explanations',
                onTap: _scrollToSolutions,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildActionTile(
                icon: Icons.cancel_outlined,
                iconColor: const Color(0xFFEF4444),
                title: 'Review Wrong Questions',
                subtitle: '${attempt.incorrectCount} questions to review',
                onTap: () {
                  setState(() => _filter = 'INCORRECT');
                  _scrollToSolutions();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionTile(
                icon: Icons.remove_circle_outline,
                iconColor: const Color(0xFFF59E0B),
                title: 'Review Skipped Questions',
                subtitle: '${attempt.unattemptedCount} questions to try',
                onTap: () {
                  setState(() => _filter = 'UNATTEMPTED');
                  _scrollToSolutions();
                },
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildActionTile(
                icon: Icons.replay_rounded,
                iconColor: const Color(0xFF3B82F6),
                title: 'Retry Test',
                subtitle: 'Improve your score',
                onTap: () {
                  if (widget.onRetryTest != null) {
                    widget.onRetryTest!();
                  } else {
                    widget.onBackToDashboard();
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildActionTile(
          icon: Icons.track_changes,
          iconColor: const Color(0xFF10B981),
          title: 'Practice Similar Questions',
          subtitle: 'Get better with more practice',
          onTap: () {
            if (widget.onPracticeSimilar != null) {
              widget.onPracticeSimilar!();
            } else {
              widget.onBackToDashboard();
            }
          },
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }

  // 9. WHAT'S NEXT CARD
  Widget _buildWhatsNextCard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("What's Next?", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildNextCard(
                icon: Icons.layers_outlined,
                color: const Color(0xFF8B5CF6),
                title: 'Practice Weak Topics',
                sub: 'Focus on weak areas',
                onTap: widget.onBackToDashboard,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildNextCard(
                icon: Icons.edit_note_outlined,
                color: const Color(0xFF3B82F6),
                title: 'Take Another Test',
                sub: 'Challenge yourself again',
                onTap: widget.onBackToDashboard,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildNextCard(
                icon: Icons.home_outlined,
                color: const Color(0xFFF59E0B),
                title: 'Go to Dashboard',
                sub: 'Back to home',
                onTap: widget.onBackToDashboard,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNextCard({
    required IconData icon,
    required Color color,
    required String title,
    required String sub,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
              Text(sub, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
            ],
          ),
        ),
      ),
    );
  }

  // 10. FINAL COMPACT FOOTER CTA
  Widget _buildFinalFooterCTA(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
            child: const Icon(Icons.star_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Consistency is the key to success!', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF14532D))),
                Text('The more you practice, the better you become. Don\'t stop now!', style: TextStyle(fontSize: 10, color: Color(0xFF166534))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: widget.onBackToDashboard,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF15803D),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: const Text('Keep Practicing 🚀', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // SOLUTIONS REVIEW SECTION
  Widget _buildSolutionsReviewSection(BuildContext context, TestAttemptModel attempt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Question Solutions & Explanations Review',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            IconButton(
              onPressed: () => setState(() => _showSolutions = false),
              icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Filter Segmented Chips
        Wrap(
          spacing: 8,
          children: [
            _buildFilterChip('ALL', 'All (${widget.questions.length})'),
            _buildFilterChip('CORRECT', 'Correct (${attempt.correctCount})'),
            _buildFilterChip('INCORRECT', 'Incorrect (${attempt.incorrectCount})'),
            _buildFilterChip('UNATTEMPTED', 'Unattempted (${attempt.unattemptedCount})'),
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

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 13,
                        backgroundColor: !isAttempted
                            ? const Color(0xFF94A3B8)
                            : (isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                        child: Text(
                          '${idx + 1}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        !isAttempted ? 'UNATTEMPTED' : (isCorrect ? 'CORRECT (+4)' : 'INCORRECT (-1)'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: !isAttempted
                              ? const Color(0xFF64748B)
                              : (isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
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
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('Your Answer: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Expanded(child: LaTeXView(text: userAns ?? 'Not Attempted')),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Text('Correct Answer: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF10B981))),
                            Expanded(child: LaTeXView(text: correctText)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (q.explanation != null || q.solution != null) ...[
                    const SizedBox(height: 12),
                    const Text('Solution & Explanation:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    LaTeXView(text: q.solution ?? q.explanation!),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final bool isSel = _filter == key;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSel ? Colors.white : const Color(0xFF475569), fontSize: 12, fontWeight: FontWeight.w600)),
      selected: isSel,
      selectedColor: const Color(0xFF4F46E5),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSel ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1))),
      onSelected: (val) => setState(() => _filter = key),
    );
  }
}

// Micro Sparkline Painter for AIR Trend Chart
class _SparklinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6366F1)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFF6366F1).withOpacity(0.25), const Color(0xFF6366F1).withOpacity(0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final points = [
      Offset(0, size.height * 0.75),
      Offset(size.width * 0.25, size.height * 0.5),
      Offset(size.width * 0.5, size.height * 0.65),
      Offset(size.width * 0.75, size.height * 0.4),
      Offset(size.width, size.height * 0.2),
    ];

    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    final dotPaint = Paint()..color = const Color(0xFF4F46E5);
    final dotBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var pt in points) {
      canvas.drawCircle(pt, 4, dotPaint);
      canvas.drawCircle(pt, 4, dotBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
