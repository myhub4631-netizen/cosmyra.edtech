import 'package:flutter/material.dart';
import '../../models/models.dart';

class UserDashboardScreen extends StatefulWidget {
  final UserProfileModel userProfile;
  final String activeExam;
  final VoidCallback onOpenPractice;
  final VoidCallback onOpenMockTests;
  final VoidCallback onOpenPyqs;
  final VoidCallback onOpenMistakes;

  const UserDashboardScreen({
    Key? key,
    required this.userProfile,
    required this.activeExam,
    required this.onOpenPractice,
    required this.onOpenMockTests,
    required this.onOpenPyqs,
    required this.onOpenMistakes,
  }) : super(key: key);

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  String _performanceFilter = 'Overall Performance';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hero Banner Greeting
            _buildHeroBanner(),
            const SizedBox(height: 24),

            // 2. Metrics Cards Row
            _buildMetricsRow(),
            const SizedBox(height: 28),

            // 3. Middle Section: Practice Modes + AI Recommendations & Streak
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 1000) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Practice Modes
                      Expanded(
                        flex: 6,
                        child: _buildPracticeModesGrid(),
                      ),
                      const SizedBox(width: 24),
                      // Right Column: AI Recommendations & Activity
                      Expanded(
                        flex: 4,
                        child: Column(
                          children: [
                            _buildAIRecommendationsCard(),
                            const SizedBox(height: 20),
                            _buildStudyStreakCard(),
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildPracticeModesGrid(),
                      const SizedBox(height: 24),
                      _buildAIRecommendationsCard(),
                      const SizedBox(height: 20),
                      _buildStudyStreakCard(),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 28),

            // 4. Bottom Section: Subject Wise Performance + Recent Tests
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 1000) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: _buildSubjectPerformanceTable(),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 4,
                        child: _buildRecentTestsList(),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildSubjectPerformanceTable(),
                      const SizedBox(height: 24),
                      _buildRecentTestsList(),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cosmyra AI Tutor Assistant opened!')),
          );
        },
        backgroundColor: const Color(0xFF6366F1),
        child: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white),
      ),
    );
  }

  // ================= 1. HERO BANNER =================
  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF312E81)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E1B4B).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 700;
          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Good morning, ${widget.userProfile.fullName.split(" ").first}! 👋',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFFCBD5E1),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "You're building your future, one question at a time.",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Keep going! Your consistency today is your success tomorrow.",
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.15)),
                          ),
                          child: Text(
                            'Target: ${widget.activeExam} 2026',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF38BDF8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.amber.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.local_fire_department_rounded, size: 14, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.userProfile.studyStreak} Day Streak',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.amber,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isWide) ...[
                const SizedBox(width: 24),
                // Gauge & Progress Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Today's Goal",
                        style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 10),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: CircularProgressIndicator(
                              value: widget.userProfile.questionsAttempted > 0
                                  ? ((widget.userProfile.questionsAttempted % 50) / 50.0).clamp(0.1, 1.0)
                                  : 0.0,
                              strokeWidth: 8,
                              backgroundColor: Colors.white.withOpacity(0.1),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                            ),
                          ),
                          Column(
                            children: [
                              Text(
                                '${widget.userProfile.questionsAttempted % 50} / 50',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const Text(
                                'Questions',
                                style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: 100,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: widget.userProfile.questionsAttempted > 0
                                ? ((widget.userProfile.questionsAttempted % 50) / 50.0).clamp(0.0, 1.0)
                                : 0.0,
                            minHeight: 6,
                            backgroundColor: const Color(0xFF334155),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(((widget.userProfile.questionsAttempted % 50) / 50.0) * 100).toInt()}%',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  // ================= 2. METRICS CARDS ROW =================
  Widget _buildMetricsRow() {
    final metrics = [
      {
        'title': 'Questions Attempted',
        'value': '${widget.userProfile.questionsAttempted}',
        'sub': widget.userProfile.questionsAttempted > 0 ? '+${widget.userProfile.questionsAttempted} solved' : '0 today',
        'icon': Icons.bolt_rounded,
        'iconBg': const Color(0xFFEEF2FF),
        'iconColor': const Color(0xFF6366F1),
        'subColor': const Color(0xFF16A34A),
      },
      {
        'title': 'Accuracy Rate',
        'value': '${widget.userProfile.accuracy.toStringAsFixed(1)}%',
        'sub': widget.userProfile.accuracy > 0 ? '${widget.userProfile.accuracy.toStringAsFixed(1)}%' : '0.0%',
        'icon': Icons.track_changes_rounded,
        'iconBg': const Color(0xFFECFDF5),
        'iconColor': const Color(0xFF10B981),
        'subColor': const Color(0xFF16A34A),
      },
      {
        'title': 'Tests Completed',
        'value': '${(widget.userProfile.questionsAttempted / 20).floor()}',
        'sub': '${(widget.userProfile.questionsAttempted / 20).floor()} tests',
        'icon': Icons.description_outlined,
        'iconBg': const Color(0xFFEFF6FF),
        'iconColor': const Color(0xFF3B82F6),
        'subColor': const Color(0xFF16A34A),
      },
      {
        'title': 'Average Test Score',
        'value': '${widget.userProfile.totalCorrect * 4} / 720',
        'sub': '${widget.userProfile.totalCorrect} correct',
        'icon': Icons.workspace_premium_rounded,
        'iconBg': const Color(0xFFF3E8FF),
        'iconColor': const Color(0xFFA855F7),
        'subColor': const Color(0xFF16A34A),
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        double cardWidth = (constraints.maxWidth - (16 * 3)) / 4;
        if (constraints.maxWidth < 900) {
          cardWidth = (constraints.maxWidth - 16) / 2;
        }
        if (constraints.maxWidth < 500) {
          cardWidth = constraints.maxWidth;
        }

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: metrics.map((m) {
            return SizedBox(
              width: cardWidth,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          m['title'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: m['iconBg'] as Color,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            m['icon'] as IconData,
                            size: 18,
                            color: m['iconColor'] as Color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          m['value'] as String,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            m['sub'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: m['subColor'] as Color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Mini Sparkline Graph representation
                    SizedBox(
                      height: 24,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: _SparklinePainter(color: m['iconColor'] as Color),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ================= 3. PRACTICE MODES GRID =================
  Widget _buildPracticeModesGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.grid_view_rounded, size: 20, color: Color(0xFF6366F1)),
                SizedBox(width: 8),
                Text(
                  'Practice Modes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: widget.onOpenPractice,
              child: const Row(
                children: [
                  Text(
                    'View All Modes',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF6366F1)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.45,
          children: [
            _buildPracticeModeCard(
              title: 'Custom Practice',
              desc: 'Select multiple subjects, chapters, topics, difficulty, and instant answer feedback.',
              actionText: 'Configure Practice ->',
              icon: Icons.bolt_rounded,
              iconBg: const Color(0xFFEEF2FF),
              iconColor: const Color(0xFF6366F1),
              onTap: widget.onOpenPractice,
            ),
            _buildPracticeModeCard(
              title: 'Full Mock Test',
              desc: 'Simulate real exam environment with timer, question palette, and detailed analysis.',
              actionText: 'Start Mock Test ->',
              icon: Icons.track_changes_rounded,
              iconBg: const Color(0xFFFFE4E6),
              iconColor: const Color(0xFFE11D48),
              onTap: widget.onOpenMockTests,
            ),
            _buildPracticeModeCard(
              title: 'PYQ Bank (2025 - 2018)',
              desc: 'Year-wise, shift-wise, and subject-wise official previous year NEET/JEE papers.',
              actionText: 'Explore PYQs ->',
              icon: Icons.menu_book_rounded,
              iconBg: const Color(0xFFDCFCE7),
              iconColor: const Color(0xFF16A34A),
              onTap: widget.onOpenPyqs,
            ),
            _buildPracticeModeCard(
              title: 'My Mistake Book',
              desc: 'Automatically tracks questions answered incorrectly. Review solutions & retry.',
              actionText: 'Review Mistakes ->',
              icon: Icons.warning_amber_rounded,
              iconBg: const Color(0xFFFFEDD5),
              iconColor: const Color(0xFFEA580C),
              onTap: widget.onOpenMistakes,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPracticeModeCard({
    required String title,
    required String desc,
    required String actionText,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    height: 1.3,
                  ),
                ),
              ],
            ),
            Text(
              actionText,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= 4. AI RECOMMENDATIONS CARD =================
  Widget _buildAIRecommendationsCard() {
    final weakAreas = [
      {
        'topic': 'Current Electricity (Physics)',
        'accuracy': '54% Accuracy',
        'btn': 'Practice 25 Questions ->',
        'icon': Icons.bolt_rounded,
        'iconColor': const Color(0xFFEAB308),
      },
      {
        'topic': 'Genetics & Inheritance (Botany)',
        'accuracy': '61% Accuracy',
        'btn': 'Practice 20 Questions ->',
        'icon': Icons.nature_rounded,
        'iconColor': const Color(0xFF10B981),
      },
      {
        'topic': 'Chemical Bonding (Chemistry)',
        'accuracy': '62% Accuracy',
        'btn': 'Practice 18 Questions ->',
        'icon': Icons.science_rounded,
        'iconColor': const Color(0xFFA855F7),
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFF6366F1)),
                  SizedBox(width: 6),
                  Text(
                    'Recommended Weak Areas',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'AI',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'AI analysis identified 3 topics with accuracy below 65%',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),

          ...weakAreas.map((wa) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Row(
                children: [
                  Icon(wa['icon'] as IconData, size: 18, color: wa['iconColor'] as Color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          wa['topic'] as String,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          wa['accuracy'] as String,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onOpenPractice,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      wa['btn'] as String,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // ================= 5. STUDY STREAK & ACTIVITY =================
  Widget _buildStudyStreakCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.schedule_rounded, size: 18, color: Color(0xFF6366F1)),
              SizedBox(width: 6),
              Text(
                'Study Streak & Activity',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // GitHub-style Activity Grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('M', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
              Text('T', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
              Text('W', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
              Text('T', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
              Text('F', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
              Text('S', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
              Text('S', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
            ],
          ),
          const SizedBox(height: 8),
          _buildActivityHeatmap(),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Current Streak', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '12 Days',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                      SizedBox(width: 4),
                      Text('🔥', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Longest Streak', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  SizedBox(height: 2),
                  Text(
                    '23 Days',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'View Calendar ->',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6366F1)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityHeatmap() {
    final activityLevels = [
      [0, 1, 2, 3, 2, 4, 3],
      [1, 2, 4, 3, 4, 2, 4],
      [2, 3, 3, 4, 4, 4, 4],
    ];

    final colors = [
      const Color(0xFFF1F5F9),
      const Color(0xFFC7D2FE),
      const Color(0xFF818CF8),
      const Color(0xFF6366F1),
      const Color(0xFF4F46E5),
    ];

    return Column(
      children: activityLevels.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: row.map((level) {
              return Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: colors[level],
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  // ================= 6. SUBJECT WISE PERFORMANCE TABLE =================
  Widget _buildSubjectPerformanceTable() {
    final subjectsData = [
      {
        'subject': 'Physics',
        'icon': Icons.water_drop_outlined,
        'iconColor': const Color(0xFF3B82F6),
        'accuracy': '82.3%',
        'attempts': '452',
        'score': '335 / 450',
        'progress': 0.74,
      },
      {
        'subject': 'Chemistry',
        'icon': Icons.science_outlined,
        'iconColor': const Color(0xFF10B981),
        'accuracy': '85.7%',
        'attempts': '398',
        'score': '298 / 360',
        'progress': 0.83,
      },
      {
        'subject': 'Biology (Botany & Zoology)',
        'icon': Icons.nature_outlined,
        'iconColor': const Color(0xFFEC4899),
        'accuracy': '88.1%',
        'attempts': '570',
        'score': '317 / 360',
        'progress': 0.88,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.bar_chart_rounded, size: 20, color: Color(0xFF6366F1)),
                  SizedBox(width: 8),
                  Text(
                    'Subject Wise Performance',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _performanceFilter,
                    isDense: true,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                    items: const [
                      DropdownMenuItem(value: 'Overall Performance', child: Text('Overall Performance')),
                      DropdownMenuItem(value: 'Last 7 Days', child: Text('Last 7 Days')),
                      DropdownMenuItem(value: 'Mock Tests Only', child: Text('Mock Tests Only')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _performanceFilter = val);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Table Header Row
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('Subject', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600))),
                Expanded(flex: 2, child: Text('Accuracy', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600))),
                Expanded(flex: 2, child: Text('Attempts', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600))),
                Expanded(flex: 2, child: Text('Score', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600))),
                Expanded(flex: 3, child: Text('Progress', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600))),
              ],
            ),
          ),
          const Divider(color: Color(0xFFF1F5F9)),

          ...subjectsData.map((sd) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF8FAFC))),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        Icon(sd['icon'] as IconData, size: 16, color: sd['iconColor'] as Color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            sd['subject'] as String,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      sd['accuracy'] as String,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      sd['attempts'] as String,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      sd['score'] as String,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: sd['progress'] as double,
                              minHeight: 6,
                              backgroundColor: const Color(0xFFE2E8F0),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${((sd['progress'] as double) * 100).toInt()}%',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // ================= 7. RECENT TESTS LIST =================
  Widget _buildRecentTestsList() {
    final recentTests = [
      {
        'title': 'NEET Full Syllabus Mock Test 24',
        'date': 'Attempted on May 23, 2026',
        'score': '612 / 720',
        'percentage': '85.0%',
      },
      {
        'title': 'JEE Main Chapter Test - Physics',
        'date': 'Attempted on May 22, 2026',
        'score': '84 / 100',
        'percentage': '84.0%',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.assignment_turned_in_rounded, size: 20, color: Color(0xFF6366F1)),
                  SizedBox(width: 8),
                  Text(
                    'Recent Tests',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: widget.onOpenMockTests,
                child: const Text(
                  'View All ->',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6366F1)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ...recentTests.map((rt) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.assignment_rounded, size: 18, color: Color(0xFFA855F7)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rt['title'] as String,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          rt['date'] as String,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        rt['score'] as String,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          rt['percentage'] as String,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF16A34A)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

// Sparkline Painter for mini metric charts
class _SparklinePainter extends CustomPainter {
  final Color color;

  _SparklinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(size.width * 0.2, size.height * 0.3, size.width * 0.4, size.height * 0.6);
    path.quadraticBezierTo(size.width * 0.6, size.height * 0.9, size.width * 0.8, size.height * 0.2);
    path.lineTo(size.width, size.height * 0.4);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
