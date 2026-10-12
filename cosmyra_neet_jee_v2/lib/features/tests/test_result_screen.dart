import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../shared/widgets/latex_view.dart';
import '../../shared/widgets/smart_image.dart';
import '../../shared/widgets/solution_video_player.dart';
import '../../shared/utils/question_copy_helper.dart';
import '../../shared/utils/neet_subject_helper.dart';
import '../../core/services/supabase_service.dart';
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
  int _activeTab = 0; // 0: Result Summary, 1: Leaderboard
  String _selectedAttempt = 'Attempt 1';
  late String _selectedSubject;
  TestCohortStats? _cohortStats;
  bool _isLoadingCohort = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final subjects = _getAvailableSubjects();
    _selectedSubject = subjects.isNotEmpty ? subjects.first : 'Physics';
    _loadCohortStats();
  }

  Future<void> _loadCohortStats() async {
    final templateId = widget.attempt.testTemplateId;
    if (templateId.isEmpty) return;
    setState(() => _isLoadingCohort = true);
    try {
      final cohort = await SupabaseService.fetchTestCohortStats(testTemplateId: templateId);
      if (mounted) {
        setState(() {
          _cohortStats = cohort;
          _isLoadingCohort = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCohort = false);
    }
  }

  List<String> _getAvailableSubjects() {
    final isJee = widget.attempt.testTitle.toLowerCase().contains('jee');
    if (widget.questions.isNotEmpty) {
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
      if (subs.isNotEmpty) {
        final preferredOrder = isJee
            ? ['Physics', 'Chemistry', 'Mathematics']
            : ['Physics', 'Chemistry', 'Botany', 'Zoology', 'Biology'];
        final ordered = preferredOrder.where((s) => subs.contains(s)).toList();
        for (var s in subs) {
          if (!ordered.contains(s)) ordered.add(s);
        }
        return ordered;
      }
    }
    return isJee
        ? ['Physics', 'Chemistry', 'Mathematics']
        : ['Physics', 'Chemistry', 'Botany', 'Zoology'];
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

  Map<String, dynamic> _computeSubjectStats(String subject) {
    if (widget.questions.isEmpty) {
      return {
        'count': 0,
        'correct': 0,
        'incorrect': 0,
        'skipped': 0,
        'score': 0,
        'accuracy': 0.0,
        'percentile': 'Not available',
        'rank': 'Not available',
        'timeStr': '00:00:00',
        'isAvailable': false,
      };
    }

    int count = 0;
    int correct = 0;
    int incorrect = 0;
    int skipped = 0;
    double score = 0.0;
    final isJee = widget.attempt.testTitle.toLowerCase().contains('jee');

    for (int i = 0; i < widget.questions.length; i++) {
      final q = widget.questions[i];
      final qSub = NeetSubjectHelper.getSubjectForQuestionIndex(
        i,
        widget.questions.length,
        explicitSubject: q.subjectId,
        isNeet: !isJee,
        useBotanyZoology: true,
      );

      final matchesSubject = (qSub.toLowerCase() == subject.toLowerCase()) ||
          (subject.toLowerCase() == 'biology' &&
              (qSub.toLowerCase() == 'botany' || qSub.toLowerCase() == 'zoology'));

      if (matchesSubject) {
        count++;
        final ans = widget.userAnswers[i];
        final double qMarks = (q.marks > 0) ? q.marks.toDouble() : 4.0;
        final double qNeg = (q.negativeMarks > 0) ? q.negativeMarks.toDouble() : 1.0;

        if (ans != null && ans.trim().isNotEmpty) {
          bool isCorrect = false;
          if (q.qType == 'numerical') {
            final expected = (q.numericalAnswer ?? '').trim();
            if (expected.isNotEmpty) {
              final uNum = double.tryParse(ans.trim());
              final eNum = double.tryParse(expected);
              if (uNum != null && eNum != null) {
                isCorrect = (uNum - eNum).abs() < 0.01;
              } else {
                isCorrect = ans.trim().toLowerCase() == expected.toLowerCase();
              }
            }
          } else {
            for (int optIdx = 0; optIdx < q.options.length; optIdx++) {
              final opt = q.options[optIdx];
              final optKey = (opt.id.isNotEmpty) ? opt.id : 'opt_${q.id}_$optIdx';
              final optLetter = String.fromCharCode(65 + optIdx);
              if (_isOptSelected(ans, optKey, optLetter, opt.optionText, optIdx) && opt.isCorrect) {
                isCorrect = true;
                break;
              }
            }
          }
          if (isCorrect) {
            correct++;
            score += qMarks;
          } else {
            incorrect++;
            score -= qNeg;
          }
        } else {
          skipped++;
        }
      }
    }

    final attempted = correct + incorrect;
    final double accuracy = attempted > 0 ? (correct / attempted) * 100 : 0.0;
    final int subTimeSecs = widget.attempt.timeSpentSeconds > 0 && widget.questions.isNotEmpty && count > 0
        ? ((widget.attempt.timeSpentSeconds * (count / widget.questions.length))).round()
        : 0;

    final mins = subTimeSecs ~/ 60;
    final secs = subTimeSecs % 60;
    final timeStr = '00:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    return {
      'count': count,
      'correct': correct,
      'incorrect': incorrect,
      'skipped': skipped,
      'score': score.toInt(),
      'accuracy': accuracy,
      'percentile': (_cohortStats != null && _cohortStats!.totalAttempts >= 2)
          ? '${_cohortStats!.calculatePercentile(score).toStringAsFixed(2)}%'
          : 'Not available',
      'rank': (_cohortStats != null && _cohortStats!.totalAttempts >= 2)
          ? '${_cohortStats!.calculateRank(score)}'
          : 'Not available',
      'timeStr': timeStr,
      'isAvailable': count > 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final attempt = widget.attempt;
    final totalQ = widget.questions.isNotEmpty
        ? widget.questions.length
        : (attempt.totalQuestions > 0 ? attempt.totalQuestions : 0);
    final double maxScore = attempt.maxMarks != null && attempt.maxMarks! > 0
        ? attempt.maxMarks!
        : (totalQ > 0 ? (totalQ * 4.0) : 0.0);
    final double userScore = attempt.totalScore ?? 0.0;
    final int timeSpent = attempt.timeSpentSeconds > 0 ? attempt.timeSpentSeconds : 0;
    final int hours = timeSpent ~/ 3600;
    final int mins = (timeSpent % 3600) ~/ 60;
    final int secs = timeSpent % 60;
    final String timeStr = '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    final dateSubmitted = attempt.submittedAt ?? DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sept', 'Oct', 'Nov', 'Dec'];
    final String dateStr = '${dateSubmitted.day} ${months[dateSubmitted.month - 1]} ${dateSubmitted.year}';
    final int durationMins = attempt.expiresAt.difference(attempt.startedAt).inMinutes > 0
        ? attempt.expiresAt.difference(attempt.startedAt).inMinutes
        : (timeSpent > 0 ? (timeSpent ~/ 60) : 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF0F172A)),
          onPressed: widget.onBackToDashboard,
        ),
        title: Text(
          attempt.testTitle.isNotEmpty ? attempt.testTitle : 'Test Analysis',
          style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedAttempt,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF475569)),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedAttempt = val);
                },
                items: ['Attempt 1', 'Attempt 2', 'Attempt 3'].map((att) {
                  return DropdownMenuItem<String>(value: att, child: Text(att));
                }).toList(),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16.0),
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. TOP MAIN HEADER CARD (IMAGE 1 SPEC)
                  _buildMainHeaderCard(attempt, totalQ, maxScore, durationMins, dateStr),

                  const SizedBox(height: 16),

                  // 2. TAB SWITCHER ROW (Result Summary | Leaderboard)
                  _buildTabSwitcherRow(),

                  const SizedBox(height: 20),

                  // TAB CONTENT 1: RESULT SUMMARY
                  if (_activeTab == 0) ...[
                    // 3. YOUR PROGRESS SECTION
                    const Text('Your Progress', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(height: 12),

                    // SCORE & RANK CARDS ROW (IMAGE 1 SPEC)
                    Row(
                      children: [
                        Expanded(child: _buildScoreCard(userScore, maxScore)),
                        const SizedBox(width: 14),
                        Expanded(child: _buildRankCard()),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // PROGRESS BARS BREAKDOWN (CORRECT, INCORRECT, SKIPPED - IMAGE 1 & 2 SPEC)
                    _buildProgressBarsCard(attempt, totalQ),

                    const SizedBox(height: 16),

                    // 3 METRIC CARDS GRID (ACCURACY, COMPLETED, TIME TAKEN - IMAGE 2 SPEC)
                    _buildThreeMetricGrid(attempt, totalQ, timeStr),

                    const SizedBox(height: 24),

                    // 4. PERFORMANCE COMPARISON SECTION (IMAGE 2 SPEC)
                    const Text('Performance Comparison', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(height: 12),
                    _buildPerformanceComparisonCards(totalQ, maxScore),

                    const SizedBox(height: 24),

                    // 5. MARKS VS RANK GAUGE / SCALE CARD (IMAGE 3 SPEC)
                    _buildRankGaugeScaleCard(userScore, maxScore),

                    const SizedBox(height: 24),

                    // 6. SECTIONAL PERFORMANCE SECTION (IMAGE 3 SPEC)
                    const Text('Sectional Performance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(height: 12),
                    _buildSectionalPerformanceCard(),

                    const SizedBox(height: 28),

                    // 7. BOTTOM STICKY ACTION BUTTON (IMAGE 3 SPEC)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _scrollToSolutions,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text('View Detailed Analysis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            SizedBox(width: 6),
                            Icon(Icons.chevron_right_rounded, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    // TAB CONTENT 2: LEADERBOARD VIEW
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.emoji_events_rounded, color: Color(0xFFEAB308), size: 24),
                              SizedBox(width: 8),
                              Text('Test Leaderboard & Ranks', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 500,
                            child: LeaderboardScreen(
                              initialExam: widget.attempt.testTitle.toLowerCase().contains('jee') ? 'JEE Main' : 'NEET UG',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // 8. DETAILED QUESTION-BY-QUESTION SOLUTIONS REVIEW (IF TOGGLED)
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

  // 1. MAIN HEADER CARD (MATCHING IMAGE 1)
  Widget _buildMainHeaderCard(TestAttemptModel attempt, int totalQ, double maxScore, int durationMins, String dateStr) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                attempt.testTitle.isNotEmpty ? attempt.testTitle : 'AITS:2',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const Icon(Icons.more_vert_rounded, color: Color(0xFF64748B), size: 22),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.assignment_outlined, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(
                '$totalQ Questions • ${maxScore.toInt()} Marks',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.timer_outlined, size: 16, color: Color(0xFFEAB308)),
              const SizedBox(width: 4),
              Text(
                '$durationMins mins',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 15, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(
                'Attempted on: $dateStr',
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (widget.onRetryTest != null)
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onRetryTest,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF818CF8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Reattempt', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 13.5)),
                  ),
                ),
              if (widget.onRetryTest != null) const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _scrollToSolutions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: const Text('View Solutions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. TAB SWITCHER ROW (IMAGE 1 SPEC)
  Widget _buildTabSwitcherRow() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _activeTab == 0 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _activeTab == 0 ? [const BoxShadow(color: Color(0x0D000000), blurRadius: 4, offset: Offset(0, 2))] : null,
                ),
                child: Center(
                  child: Text(
                    'Result Summary',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: _activeTab == 0 ? FontWeight.bold : FontWeight.w500,
                      color: _activeTab == 0 ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _activeTab == 1 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _activeTab == 1 ? [const BoxShadow(color: Color(0x0D000000), blurRadius: 4, offset: Offset(0, 2))] : null,
                ),
                child: Center(
                  child: Text(
                    'Leaderboard',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: _activeTab == 1 ? FontWeight.bold : FontWeight.w500,
                      color: _activeTab == 1 ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 3. SCORE CARD (MATCHING IMAGE 1)
  Widget _buildScoreCard(double userScore, double maxScore) {
    final hasCohort = _cohortStats != null && _cohortStats!.totalAttempts >= 2;
    final String pctText = hasCohort
        ? 'Percentile: ${_cohortStats!.calculatePercentile(userScore).toStringAsFixed(2)}'
        : 'Percentile: Not available';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Icon(Icons.bar_chart_rounded, color: Color(0xFF2563EB), size: 22),
              SizedBox(),
            ],
          ),
          const SizedBox(height: 8),
          const Text('SCORE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5)),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: userScore < 0 ? '${userScore.toInt()}' : '${userScore.toInt()}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: userScore < 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                  ),
                ),
                TextSpan(
                  text: ' / ${maxScore.toInt()}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            pctText,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // 3. RANK CARD (MATCHING IMAGE 1)
  Widget _buildRankCard() {
    final hasCohort = _cohortStats != null && _cohortStats!.totalAttempts >= 2;
    final String rankText = hasCohort ? '${_cohortStats!.calculateRank(widget.attempt.totalScore ?? 0)}' : 'Not available';
    final String subtitleText = hasCohort ? 'Out of ${_cohortStats!.totalAttempts} students' : 'Awaiting cohort data';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Icon(Icons.emoji_events_rounded, color: Color(0xFFEAB308), size: 22),
              Icon(Icons.info_outline_rounded, color: Color(0xFF94A3B8), size: 16),
            ],
          ),
          const SizedBox(height: 8),
          const Text('RANK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(
            rankText,
            style: TextStyle(
              fontSize: hasCohort ? 24 : 18,
              fontWeight: FontWeight.w900,
              color: hasCohort ? const Color(0xFF0F172A) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitleText,
            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // PROGRESS BARS CARD (MATCHING IMAGE 1 & 2)
  Widget _buildProgressBarsCard(TestAttemptModel attempt, int totalQ) {
    final correctCount = attempt.correctCount;
    final incorrectCount = attempt.incorrectCount;
    final skippedCount = attempt.unattemptedCount;

    final double correctRatio = totalQ > 0 ? (correctCount / totalQ) : 0;
    final double incorrectRatio = totalQ > 0 ? (incorrectCount / totalQ) : 0;
    final double skippedRatio = totalQ > 0 ? (skippedCount / totalQ) : 0;

    double marksObtained = 0.0;
    double marksLost = 0.0;
    if (widget.questions.isNotEmpty) {
      for (int i = 0; i < widget.questions.length; i++) {
        final q = widget.questions[i];
        final ans = widget.userAnswers[i];
        final double qMarks = (q.marks > 0) ? q.marks : 4.0;
        final double qNeg = (q.negativeMarks > 0) ? q.negativeMarks : 1.0;
        if (ans != null && ans.trim().isNotEmpty) {
          bool isCorr = false;
          if (q.qType == 'numerical') {
            final expected = (q.numericalAnswer ?? '').trim();
            if (expected.isNotEmpty) {
              final uNum = double.tryParse(ans.trim());
              final eNum = double.tryParse(expected);
              if (uNum != null && eNum != null) {
                isCorr = (uNum - eNum).abs() < 0.01;
              } else {
                isCorr = ans.trim().toLowerCase() == expected.toLowerCase();
              }
            }
          } else {
            for (int optIdx = 0; optIdx < q.options.length; optIdx++) {
              final opt = q.options[optIdx];
              final optKey = (opt.id.isNotEmpty) ? opt.id : 'opt_${q.id}_$optIdx';
              final optLetter = String.fromCharCode(65 + optIdx);
              if (_isOptSelected(ans, optKey, optLetter, opt.optionText, optIdx) && opt.isCorrect) {
                isCorr = true;
                break;
              }
            }
          }
          if (isCorr) {
            marksObtained += qMarks;
          } else {
            marksLost += qNeg;
          }
        }
      }
    } else {
      marksObtained = correctCount * 4.0;
      marksLost = incorrectCount * 1.0;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Correct Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF22C55E), size: 18),
                  const SizedBox(width: 8),
                  const Text('Correct', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                ],
              ),
              Text('$correctCount/$totalQ', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(),
              Text('Marks Obtained: +${marksObtained.toInt()}', style: const TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: correctRatio,
              minHeight: 6,
              backgroundColor: const Color(0xFFF1F5F9),
              color: const Color(0xFF22C55E),
            ),
          ),

          const SizedBox(height: 14),

          // Incorrect Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.cancel_outlined, color: Color(0xFFEF4444), size: 18),
                  const SizedBox(width: 8),
                  const Text('Incorrect', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                ],
              ),
              Text('$incorrectCount/$totalQ', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(),
              Text('Marks Lost: -${marksLost.toInt()}', style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626), fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: incorrectRatio,
              minHeight: 6,
              backgroundColor: const Color(0xFFF1F5F9),
              color: const Color(0xFFEF4444),
            ),
          ),

          const SizedBox(height: 14),

          // Skipped Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.arrow_right_alt_rounded, color: Color(0xFF3B82F6), size: 18),
                  const SizedBox(width: 8),
                  const Text('Skipped', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                ],
              ),
              Text('$skippedCount/$totalQ', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(),
              Text('Unattempted Questions: $skippedCount', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: skippedRatio,
              minHeight: 6,
              backgroundColor: const Color(0xFFF1F5F9),
              color: const Color(0xFF3B82F6),
            ),
          ),
        ],
      ),
    );
  }

  // 3 METRIC CARDS GRID (ACCURACY, COMPLETED, TIME TAKEN - IMAGE 2 SPEC)
  Widget _buildThreeMetricGrid(TestAttemptModel attempt, int totalQ, String timeStr) {
    final double completedPct = totalQ > 0 ? (attempt.attemptedCount / totalQ * 100) : 0.0;
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.track_changes_rounded, size: 16, color: Color(0xFF0EA5E9)),
                    SizedBox(width: 6),
                    Text('Accuracy', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 6),
                Text('${attempt.accuracy.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.assignment_turned_in_outlined, size: 16, color: Color(0xFF8B5CF6)),
                    SizedBox(width: 6),
                    Text('Completed', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 6),
                Text('${completedPct.toStringAsFixed(2)}%', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.timer_outlined, size: 16, color: Color(0xFFEAB308)),
                    SizedBox(width: 6),
                    Text('Time Taken', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(timeStr, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 4. PERFORMANCE COMPARISON CARDS (MATCHING IMAGE 2)
  Widget _buildPerformanceComparisonCards(int totalQ, double maxScore) {
    if (_isLoadingCohort) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Column(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
              ),
              SizedBox(height: 10),
              Text(
                'Loading comparison data...',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    if (_cohortStats == null || _cohortStats!.totalAttempts < 2) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: const [
            Icon(Icons.analytics_outlined, size: 32, color: Color(0xFF94A3B8)),
            SizedBox(height: 8),
            Text(
              'Not enough comparison data yet',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            SizedBox(height: 4),
            Text(
              'Topper and cohort averages will be displayed once more students complete this test.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    final stats = _cohortStats!;
    return Row(
      children: [
        // TOPPER CARD (YELLOWISH)
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    CircleAvatar(backgroundColor: Color(0xFFFDE047), radius: 14, child: Icon(Icons.school, size: 16, color: Color(0xFF713F12))),
                    SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Topper', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF713F12))),
                        Text('(Live Test)', style: TextStyle(fontSize: 10, color: Color(0xFFA16207))),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildCompRow('Score', stats.topperScore.toStringAsFixed(1)),
                _buildCompRow('Correct', '${stats.topperCorrect}'),
                _buildCompRow('Incorrect', '${stats.topperIncorrect}'),
                _buildCompRow('Skipped', '${stats.topperSkipped}'),
                _buildCompRow('Accuracy', '${stats.topperAccuracy.toStringAsFixed(1)}%'),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // AVERAGE CARD (BLUISH)
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    CircleAvatar(backgroundColor: Color(0xFF93C5FD), radius: 14, child: Icon(Icons.groups, size: 16, color: Color(0xFF1E3A8A))),
                    SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Average', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                        Text('(Live Test)', style: TextStyle(fontSize: 10, color: Color(0xFF1E40AF))),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildCompRow('Score', stats.averageScore.toStringAsFixed(2)),
                _buildCompRow('Correct', '${stats.averageCorrect}'),
                _buildCompRow('Incorrect', '${stats.averageIncorrect}'),
                _buildCompRow('Skipped', '${stats.averageSkipped}'),
                _buildCompRow('Accuracy', '${stats.averageAccuracy.toStringAsFixed(1)}%'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569), fontWeight: FontWeight.w500)),
          Text(val, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }

  // 5. MARKS VS RANK GAUGE / SCALE CARD (MATCHING IMAGE 3)
  Widget _buildRankGaugeScaleCard(double userScore, double maxScore) {
    final hasCohort = _cohortStats != null && _cohortStats!.totalAttempts >= 2;
    final int? rank = hasCohort ? _cohortStats!.calculateRank(userScore) : null;
    final double norm = maxScore > 0 ? ((userScore + (maxScore * 0.25)) / (maxScore * 1.25)).clamp(0.05, 0.95) : 0.1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Floating Rank Badge
          Align(
            alignment: Alignment(norm * 2 - 1.0, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF818CF8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                rank != null ? 'Rank: $rank' : 'Rank: Pending cohort data',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Scale Line
          Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 6,
                width: double.infinity,
                decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(4)),
              ),
              FractionallySizedBox(
                widthFactor: norm,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(color: const Color(0xFF4F46E5), borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Marks: ${userScore.toInt()}/${maxScore.toInt()}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
        ],
      ),
    );
  }

  // 6. SECTIONAL PERFORMANCE CARD (MATCHING IMAGE 3)
  Widget _buildSectionalPerformanceCard() {
    final subjects = _getAvailableSubjects();
    final stats = _computeSubjectStats(_selectedSubject);

    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subject Breakdown', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedSubject,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF2563EB)),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedSubject = val);
                  },
                  items: subjects.map((s) {
                    return DropdownMenuItem<String>(value: s, child: Text(s));
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (widget.questions.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.pie_chart_outline_rounded, size: 36, color: Color(0xFF94A3B8)),
                  SizedBox(height: 10),
                  Text(
                    'Subject breakdown is unavailable',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Detailed question records for this attempt could not be loaded.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            )
          else if ((stats['count'] as int? ?? 0) == 0)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 28, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 8),
                  Text(
                    'No questions assigned to $_selectedSubject in this test paper.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )
          else ...[
            _buildSectionalItem(Icons.text_fields_rounded, const Color(0xFF6366F1), 'Score', '${stats['score']}'),
            _buildSectionalItem(Icons.percent_rounded, const Color(0xFF0EA5E9), 'Percentile', '${stats['percentile']}'),
            _buildSectionalItem(Icons.star_outline_rounded, const Color(0xFFEAB308), 'Rank', '${stats['rank']}'),
            _buildSectionalItem(Icons.check_circle_outline_rounded, const Color(0xFF22C55E), 'Correct', '${stats['correct']}'),
            _buildSectionalItem(Icons.cancel_outlined, const Color(0xFFEF4444), 'Incorrect', '${stats['incorrect']}'),
            _buildSectionalItem(Icons.arrow_right_alt_rounded, const Color(0xFF3B82F6), 'Skipped', '${stats['skipped']}'),
            _buildSectionalItem(Icons.track_changes_rounded, const Color(0xFF8B5CF6), 'Accuracy', '${(stats['accuracy'] as double).toStringAsFixed(1)}%'),
            _buildSectionalItem(Icons.timer_outlined, const Color(0xFFF59E0B), 'Time Taken', '${stats['timeStr']}'),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionalItem(IconData icon, Color color, String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(val, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }

  // 8. SOLUTIONS REVIEW SECTION
  Widget _buildSolutionsReviewSection(BuildContext context, TestAttemptModel attempt) {
    final filteredQuestions = widget.questions.where((q) {
      final idx = widget.questions.indexOf(q);
      final userAns = widget.userAnswers[idx];

      bool isCorrect = false;
      bool isAnswered = userAns != null && userAns.trim().isNotEmpty;

      if (isAnswered) {
        if (q.qType == 'numerical') {
          final expected = (q.numericalAnswer ?? '').trim();
          if (expected.isNotEmpty) {
            final uNum = double.tryParse(userAns.trim());
            final eNum = double.tryParse(expected);
            if (uNum != null && eNum != null) {
              isCorrect = (uNum - eNum).abs() < 0.01;
            } else {
              isCorrect = userAns.trim().toLowerCase() == expected.toLowerCase();
            }
          }
        } else {
          for (int i = 0; i < q.options.length; i++) {
            final opt = q.options[i];
            final optKey = opt.id.isNotEmpty ? opt.id : 'opt_${q.id}_$i';
            final optLetter = String.fromCharCode(65 + i);
            if (_isOptSelected(userAns, optKey, optLetter, opt.optionText) && opt.isCorrect) {
              isCorrect = true;
              break;
            }
          }
        }
      }

      if (_filter == 'CORRECT') return isCorrect;
      if (_filter == 'INCORRECT') return isAnswered && !isCorrect;
      if (_filter == 'UNATTEMPTED') return !isAnswered;
      return true; // ALL
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Detailed Question Solutions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            Text(
              '${filteredQuestions.length} Questions',
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // FILTER CHIPS
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterChip('ALL', 'All'),
            _buildFilterChip('CORRECT', 'Correct'),
            _buildFilterChip('INCORRECT', 'Incorrect'),
            _buildFilterChip('UNATTEMPTED', 'Unattempted'),
          ],
        ),

        const SizedBox(height: 20),

        // QUESTIONS LIST
        if (filteredQuestions.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: const Text('No questions match the selected filter.', style: TextStyle(color: Color(0xFF64748B))),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredQuestions.length,
            itemBuilder: (ctx, idx) {
              final q = filteredQuestions[idx];
              final originalIdx = widget.questions.indexOf(q);
              final userAns = widget.userAnswers[originalIdx];

              bool isCorrect = false;
              bool isAnswered = userAns != null && userAns.trim().isNotEmpty;

              if (isAnswered) {
                if (q.qType == 'numerical') {
                  final expected = (q.numericalAnswer ?? '').trim();
                  if (expected.isNotEmpty) {
                    final uNum = double.tryParse(userAns.trim());
                    final eNum = double.tryParse(expected);
                    if (uNum != null && eNum != null) {
                      isCorrect = (uNum - eNum).abs() < 0.01;
                    } else {
                      isCorrect = userAns.trim().toLowerCase() == expected.toLowerCase();
                    }
                  }
                } else {
                  for (int i = 0; i < q.options.length; i++) {
                    final opt = q.options[i];
                    final optKey = opt.id.isNotEmpty ? opt.id : 'opt_${q.id}_$i';
                    final optLetter = String.fromCharCode(65 + i);
                    if (_isOptSelected(userAns, optKey, optLetter, opt.optionText) && opt.isCorrect) {
                      isCorrect = true;
                      break;
                    }
                  }
                }
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 18),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isAnswered ? (isCorrect ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2)) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Question ${originalIdx + 1} (${isAnswered ? (isCorrect ? 'Correct' : 'Incorrect') : 'Skipped'})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isAnswered ? (isCorrect ? const Color(0xFF15803D) : const Color(0xFFB91C1C)) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF64748B)),
                          tooltip: 'Copy Question',
                          onPressed: () => QuestionCopyHelper.copyModelToClipboard(context, q, questionIndex: originalIdx + 1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LaTeXView(text: q.questionText, style: const TextStyle(fontSize: 15, height: 1.5, color: Color(0xFF0F172A))),
                    if (q.questionImage != null && q.questionImage!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SmartImage(url: q.questionImage, height: 180, fit: BoxFit.contain),
                    ],
                    const SizedBox(height: 16),

                    // Options
                    ...q.options.asMap().entries.map((entry) {
                      final optIdx = entry.key;
                      final opt = entry.value;
                      final optKey = opt.id.isNotEmpty ? opt.id : 'opt_${q.id}_$optIdx';
                      final optLetter = String.fromCharCode(65 + optIdx);
                      final isSelected = _isOptSelected(userAns, optKey, optLetter, opt.optionText);

                      Color bg = const Color(0xFFF8FAFC);
                      Color border = const Color(0xFFE2E8F0);
                      Color txtColor = const Color(0xFF334155);

                      if (opt.isCorrect) {
                        bg = const Color(0xFFF0FDF4);
                        border = const Color(0xFF22C55E);
                        txtColor = const Color(0xFF15803D);
                      } else if (isSelected && !opt.isCorrect) {
                        bg = const Color(0xFFFEF2F2);
                        border = const Color(0xFFEF4444);
                        txtColor = const Color(0xFFB91C1C);
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: border),
                        ),
                        child: Row(
                          children: [
                            Text('${optIdx + 1}. ', style: TextStyle(fontWeight: FontWeight.bold, color: txtColor)),
                            Expanded(child: LaTeXView(text: opt.optionText, style: TextStyle(fontSize: 14, color: txtColor))),
                            if (opt.isCorrect) const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 20),
                            if (isSelected && !opt.isCorrect) const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 20),
                          ],
                        ),
                      );
                    }).toList(),

                    // Solution Box
                    if ((q.explanation != null && q.explanation!.isNotEmpty) || (q.solution != null && q.solution!.isNotEmpty)) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Solution:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                            const SizedBox(height: 4),
                            LaTeXView(
                              text: (q.explanation != null && q.explanation!.isNotEmpty) ? q.explanation! : q.solution!,
                              style: const TextStyle(fontSize: 13.5, height: 1.4, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (q.solutionVideoUrl != null && q.solutionVideoUrl!.trim().isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.play_circle_fill, color: Color(0xFF4F46E5), size: 18),
                                SizedBox(width: 6),
                                Text('Video Solution', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SolutionVideoPlayerWidget(
                              videoUrl: q.solutionVideoUrl!,
                              height: 220,
                            ),
                          ],
                        ),
                      ),
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
    final bool isSelected = _filter == key;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? Colors.white : const Color(0xFF475569))),
      selected: isSelected,
      selectedColor: const Color(0xFF2563EB),
      backgroundColor: const Color(0xFFF1F5F9),
      onSelected: (sel) {
        if (sel) setState(() => _filter = key);
      },
    );
  }
}

/// Robust loader for direct navigation or page refresh on result routes
class TestResultLoaderScreen extends StatefulWidget {
  final String testId;
  final String? attemptId;
  final VoidCallback onBackToDashboard;

  const TestResultLoaderScreen({
    Key? key,
    required this.testId,
    this.attemptId,
    required this.onBackToDashboard,
  }) : super(key: key);

  @override
  State<TestResultLoaderScreen> createState() => _TestResultLoaderScreenState();
}

class _TestResultLoaderScreenState extends State<TestResultLoaderScreen> {
  bool _isLoading = true;
  String? _error;
  TestAttemptModel? _attempt;
  List<QuestionModel> _questions = [];
  Map<int, String> _userAnswers = {};

  @override
  void initState() {
    super.initState();
    _loadAttemptData();
  }

  Future<void> _loadAttemptData() async {
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

      setState(() {
        _attempt = attempt;
        _questions = questions;
        _userAnswers = answers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Unable to load test results. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF2563EB)),
              SizedBox(height: 16),
              Text(
                'Loading test results...',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null || _attempt == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Test Result'),
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
                  _error ?? 'Result Unavailable',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please take this test or check your test history to view completed results.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: widget.onBackToDashboard,
                  icon: const Icon(Icons.dashboard_rounded, size: 18),
                  label: const Text('Back to Dashboard'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
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

    return TestResultScreen(
      attempt: _attempt!,
      questions: _questions,
      userAnswers: _userAnswers,
      onBackToDashboard: widget.onBackToDashboard,
    );
  }
}
