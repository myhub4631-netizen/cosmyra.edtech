import 'package:flutter/material.dart';

class LandingPageScreen extends StatelessWidget {
  final VoidCallback onStartPracticing;
  final VoidCallback onExploreTests;
  final VoidCallback onSignUp;
  final VoidCallback onLogIn;

  const LandingPageScreen({
    Key? key,
    required this.onStartPracticing,
    required this.onExploreTests,
    required this.onSignUp,
    required this.onLogIn,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. TOP HEADER NAVIGATION BAR
            _buildHeaderNav(context),

            // 2. HERO SECTION CANVAS
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF8FAFC), Color(0xFFEEF2FF), Color(0xFFF8FAFC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: MaxWidthContainer(
                child: Column(
                  children: [
                    // Main Hero Row: (Left Headline + Center Student Image & Badges + Right Floating Progress Cards)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left Headline & Call-To-Action Column
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Star Trust Badge Pill
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFFBEB),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFFFDE68A)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
                                    SizedBox(width: 6),
                                    Text(
                                      "India's Most Trusted Exam Preparation Platform",
                                      style: TextStyle(color: Color(0xFF4F46E5), fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Main Headline
                              RichText(
                                text: const TextSpan(
                                  style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), height: 1.15),
                                  children: [
                                    TextSpan(text: 'Practice '),
                                    TextSpan(text: 'Smarter.\n', style: TextStyle(color: Color(0xFF4F46E5))),
                                    TextSpan(text: 'Perform '),
                                    TextSpan(text: 'Better.\n', style: TextStyle(color: Color(0xFF4F46E5))),
                                    TextSpan(text: 'Crack Your Dream Exam.'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),

                              // Paragraph Subtitle
                              const Text(
                                'Ace NEET, JEE and other competitive exams with thousands of practice questions, full-length tests, PYQs, detailed solutions and advanced performance analytics.',
                                style: TextStyle(fontSize: 15, color: Color(0xFF64748B), height: 1.5),
                              ),
                              const SizedBox(height: 28),

                              // CTA Buttons Row
                              Row(
                                children: [
                                  ElevatedButton(
                                    onPressed: onStartPracticing,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4F46E5),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      elevation: 0,
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('Start Practicing Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        SizedBox(width: 8),
                                        Icon(Icons.arrow_forward_rounded, size: 16),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  OutlinedButton(
                                    onPressed: onExploreTests,
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Color(0xFFC7D2FE), width: 1.5),
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text('Explore Tests', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 14)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Social Proof Footnote
                              Row(
                                children: [
                                  SizedBox(
                                    width: 80,
                                    height: 32,
                                    child: Stack(
                                      children: const [
                                        Positioned(left: 0, child: CircleAvatar(radius: 14, backgroundImage: NetworkImage('https://i.pravatar.cc/100?img=11'))),
                                        Positioned(left: 18, child: CircleAvatar(radius: 14, backgroundImage: NetworkImage('https://i.pravatar.cc/100?img=12'))),
                                        Positioned(left: 36, child: CircleAvatar(radius: 14, backgroundImage: NetworkImage('https://i.pravatar.cc/100?img=13'))),
                                      ],
                                    ),
                                  ),
                                  RichText(
                                    text: const TextSpan(
                                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                      children: [
                                        TextSpan(text: 'Join '),
                                        TextSpan(text: '2M+ ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                        TextSpan(text: 'students who are preparing smarter every day!'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 24),

                        // Center Hero Column: Student Portrait & Left Floating Badges
                        Expanded(
                          flex: 4,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Hero Student Portrait Image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: Image.asset(
                                  'assets/images/hero_student_portrait.jpg',
                                  height: 480,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, stack) => Container(
                                    height: 440,
                                    width: 320,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFC7D2FE),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: const Icon(Icons.person_rounded, size: 120, color: Color(0xFF4F46E5)),
                                  ),
                                ),
                              ),

                              // Floating Badges to left of Student
                              Positioned(
                                left: 0,
                                top: 40,
                                child: _buildHeroBadge(Icons.book_outlined, '10,000+', 'Practice Questions', const Color(0xFF8B5CF6)),
                              ),
                              Positioned(
                                left: -10,
                                top: 200,
                                child: _buildHeroBadge(Icons.assignment_outlined, '500+', 'Full Length Tests', const Color(0xFF10B981)),
                              ),
                              Positioned(
                                left: 10,
                                bottom: 40,
                                child: _buildHeroBadge(Icons.emoji_events_outlined, 'NEET · JEE', '& Many More Exams', const Color(0xFFF59E0B)),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 24),

                        // Right Column: Floating Progress & Streak Dashboard Cards
                        if (isDesktop)
                          Expanded(
                            flex: 3,
                            child: Column(
                              children: [
                                _buildYourProgressCard(),
                                const SizedBox(height: 20),
                                _buildStreakCard(),
                              ],
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // 3. KEY STATS METRICS BAR (Full Width White Card)
                    _buildStatsMetricsBar(),
                    const SizedBox(height: 48),

                    // 4. POWERFUL FEATURES FOR EVERY ASPIRANT
                    _buildFeaturesSection(context),
                    const SizedBox(height: 40),

                    // 5. BOTTOM NEW HERE CTA BANNER
                    _buildNewHereBanner(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= 1. HEADER NAV =================
  Widget _buildHeaderNav(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: MaxWidthContainer(
        child: Row(
          children: [
            // Logo
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ExamPrep', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    Text('Practice | Analyze | Succeed', style: TextStyle(fontSize: 9, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 40),

            // Navigation Links
            Expanded(
              child: Row(
                children: [
                  _buildNavLink('Home', isActive: true),
                  _buildNavLink('Practice ∨'),
                  _buildNavLink('Tests ∨'),
                  _buildNavLink('PYQ ∨'),
                  _buildNavLink('Study Material'),
                  _buildNavLink('Leaderboard'),
                  _buildNavLink('Pricing'),
                  _buildNavLink('About Us'),
                ],
              ),
            ),

            // Right Action Buttons
            Row(
              children: [
                IconButton(icon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 22), onPressed: () {}),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onLogIn,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Log In', style: TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: onSignUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: const Text('Sign Up', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavLink(String title, {bool isActive = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? const Color(0xFF4F46E5) : const Color(0xFF475569),
            ),
          ),
          if (isActive) ...[
            const SizedBox(height: 4),
            Container(height: 2, width: 16, color: const Color(0xFF4F46E5)),
          ],
        ],
      ),
    );
  }

  // ================= 2. HERO FLOATING BADGES =================
  Widget _buildHeroBadge(IconData icon, String title, String sub, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4))],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              Text(sub, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
            ],
          ),
        ],
      ),
    );
  }

  // ================= 3. YOUR PROGRESS CARD =================
  Widget _buildYourProgressCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4))],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Your Progress', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              Text('This Week ∨', style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Score', style: TextStyle(fontSize: 10, color: Colors.grey)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('612 / 720', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              Text('85%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: const LinearProgressIndicator(
              value: 0.85,
              minHeight: 6,
              backgroundColor: Color(0xFFEEF2FF),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ProgressStat('Accuracy', '78.4%'),
              _ProgressStat('Questions Solved', '245'),
              _ProgressStat('Tests Completed', '16'),
            ],
          ),
        ],
      ),
    );
  }

  // ================= 4. STREAK CARD =================
  Widget _buildStreakCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4))],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🔥 12 Day Streak', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 2),
          const Text('Keep it up!', style: TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StreakDay('M', true),
              _StreakDay('T', true),
              _StreakDay('W', true),
              _StreakDay('T', true),
              _StreakDay('F', true),
              _StreakDay('S', true),
              _StreakDay('S', false),
            ],
          ),
        ],
      ),
    );
  }

  // ================= 5. STATS METRICS BAR =================
  Widget _buildStatsMetricsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricItem(Icons.people_outline, '2M+', 'Students', const Color(0xFF8B5CF6)),
          _buildMetricItem(Icons.school_outlined, '50+', 'Exams', const Color(0xFF3B82F6)),
          _buildMetricItem(Icons.description_outlined, '1.5M+', 'Questions', const Color(0xFF10B981)),
          _buildMetricItem(Icons.assignment_outlined, '25K+', 'Tests', const Color(0xFFF59E0B)),
          _buildMetricItem(Icons.trending_up_rounded, '95%', 'Student Satisfaction', const Color(0xFFEC4899)),
        ],
      ),
    );
  }

  Widget _buildMetricItem(IconData icon, String val, String label, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ],
        ),
      ],
    );
  }

  // ================= 6. FEATURES SECTION GRID =================
  Widget _buildFeaturesSection(BuildContext context) {
    return Column(
      children: [
        const Text(
          'EVERYTHING YOU NEED TO SUCCEED',
          style: TextStyle(color: Color(0xFF4F46E5), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1),
        ),
        const SizedBox(height: 6),
        const Text(
          'Powerful Features for Every Aspirant',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 6),
        const Text(
          'All the tools you need to plan, practice, analyze and improve your performance.',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 32),

        // 6 Feature Cards Grid
        GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width >= 900 ? 6 : 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.95,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildFeatureCard('Custom Practice', 'Practice questions from specific subjects, chapters & topics of your choice.', Icons.track_changes_outlined, const Color(0xFF8B5CF6)),
            _buildFeatureCard('Custom Tests', 'Create your own test with time limit, marks & negative marking and evaluate yourself.', Icons.assignment_outlined, const Color(0xFF10B981)),
            _buildFeatureCard('PYQ & NTA Questions', 'Practice previous year questions and official NTA questions chapter-wise or full syllabus.', Icons.auto_stories_outlined, const Color(0xFFF59E0B)),
            _buildFeatureCard('Performance Analytics', 'Detailed analysis of your strengths, weaknesses and progress over time.', Icons.bar_chart_rounded, const Color(0xFF3B82F6)),
            _buildFeatureCard('Smart Bookmarks', 'Bookmark important questions and revise them anytime, anywhere.', Icons.bookmark_outline_rounded, const Color(0xFFEC4899)),
            _buildFeatureCard('Leaderboards', 'Compete with other aspirants and climb the daily, weekly & monthly leaderboards.', Icons.emoji_events_outlined, const Color(0xFF8B5CF6)),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureCard(String title, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 14),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(description, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.4), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ================= 7. NEW HERE BOTTOM BANNER =================
  Widget _buildNewHereBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.card_giftcard_rounded, color: Color(0xFF4F46E5), size: 22),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('New Here?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  SizedBox(height: 2),
                  Text('Create your free account and get access to free tests, quizzes and more.', style: TextStyle(fontSize: 12, color: Color(0xFF475569))),
                ],
              ),
            ],
          ),
          ElevatedButton(
            onPressed: onSignUp,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Create Free Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MaxWidthContainer extends StatelessWidget {
  final Widget child;

  const MaxWidthContainer({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1280),
        child: child,
      ),
    );
  }
}

class _ProgressStat extends StatelessWidget {
  final String label;
  final String val;

  const _ProgressStat(this.label, this.val);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
      ],
    );
  }
}

class _StreakDay extends StatelessWidget {
  final String day;
  final bool isDone;

  const _StreakDay(this.day, this.isDone);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(day, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 4),
        Icon(
          isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 16,
          color: isDone ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
        ),
      ],
    );
  }
}
