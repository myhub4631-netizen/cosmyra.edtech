import 'package:flutter/material.dart';
import '../../models/models.dart';

class HomeScreen extends StatelessWidget {
  final UserProfileModel userProfile;
  final String activeExam;
  final Function(int) onNavigate;
  final VoidCallback onStartCustomPractice;
  final VoidCallback onStartCustomTest;

  const HomeScreen({
    Key? key,
    required this.userProfile,
    required this.activeExam,
    required this.onNavigate,
    required this.onStartCustomPractice,
    required this.onStartCustomTest,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Header with Target Exam & Greeting
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: activeExam.contains('JEE')
                    ? [const Color(0xFF4F46E5), const Color(0xFF7C3AED)]
                    : [const Color(0xFF2563EB), const Color(0xFF0D9488)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'TARGET $activeExam ${userProfile.targetYear}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Welcome back, ${userProfile.fullName}!',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Consistent question practice is the key to cracking competitive entrance exams.',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '🔥 12',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.amber),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Daily Progress & Streak Stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  title: 'Today Attempted',
                  value: '45 Questions',
                  subtitle: 'Target: 50/day',
                  icon: Icons.check_circle_outline_rounded,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  title: 'Overall Accuracy',
                  value: '${userProfile.accuracy}%',
                  subtitle: '395 Correct',
                  icon: Icons.pie_chart_outline_rounded,
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  title: 'Leaderboard Rank',
                  value: '#${userProfile.rank}',
                  subtitle: 'Top 5%',
                  icon: Icons.emoji_events_outlined,
                  color: Colors.amber,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Primary Practice & Test Actions Header
          Text(
            'Practice & Exam Engine',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onStartCustomPractice,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.tune_rounded, color: Theme.of(context).primaryColor),
                        ),
                        const SizedBox(height: 14),
                        const Text('Custom Practice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                        const SizedBox(height: 4),
                        const Text('Filter by subjects, chapters, sources & immediate solutions.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: onStartCustomTest,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.purple.withOpacity(0.3), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.timer_rounded, color: Colors.purple),
                        ),
                        const SizedBox(height: 14),
                        const Text('Custom Mock Test', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                        const SizedBox(height: 4),
                        const Text('Exam simulator: Timed test with hidden answers until submit.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Specialized Question Banks Grid
          Text(
            'Specialized Question Banks',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width >= 900 ? 4 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildFeatureTile(
                context,
                title: 'PYQ Explorer',
                subtitle: 'Year-wise 2018-2025',
                icon: Icons.history_edu_rounded,
                color: Colors.indigo,
                onTap: () => onNavigate(3),
              ),
              _buildFeatureTile(
                context,
                title: 'NTA Questions',
                subtitle: 'Official Pattern Sets',
                icon: Icons.verified_rounded,
                color: Colors.teal,
                onTap: () => onNavigate(3),
              ),
              _buildFeatureTile(
                context,
                title: 'Mistake Book',
                subtitle: 'Review & Re-attempt',
                icon: Icons.warning_amber_rounded,
                color: Colors.orange,
                onTap: () => onNavigate(4),
              ),
              _buildFeatureTile(
                context,
                title: 'Bookmarks',
                subtitle: 'Saved Important MCQs',
                icon: Icons.bookmark_outline_rounded,
                color: Colors.pink,
                onTap: () => onNavigate(4),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Recommended Weak Topics Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.analytics_rounded, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text('Recommended Focus Topics', style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTopicRow('Physics: Friction & Newton Laws', 0.54, '54% Mastery'),
                  const SizedBox(height: 10),
                  _buildTopicRow('Chemistry: Hydrocarbons & Alkanes', 0.68, '68% Mastery'),
                  const SizedBox(height: 10),
                  _buildTopicRow('Biology: Human Digestive Anatomy', 0.78, '78% Mastery'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 2),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicRow(String topicName, double progress, String percentText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(topicName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Text(percentText, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
          minHeight: 6,
        ),
      ],
    );
  }
}
