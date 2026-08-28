import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../core/services/supabase_service.dart';

class NtaPaperWiseScreen extends StatefulWidget {
  final String activeExam;
  final VoidCallback? onBack;
  final Function(List<QuestionModel> questions, int timerMinutes, bool isTestMode)? onStartSession;

  const NtaPaperWiseScreen({
    Key? key,
    this.activeExam = 'NEET 2026',
    this.onBack,
    this.onStartSession,
  }) : super(key: key);

  @override
  State<NtaPaperWiseScreen> createState() => _NtaPaperWiseScreenState();
}

class _NtaPaperWiseScreenState extends State<NtaPaperWiseScreen> {
  int _selectedFilterTab = 0; // 0 = Full Papers, 1 = Subject-wise Papers, 2 = Previous Year Papers
  int _selectedPaperIndex = 0; // 0 = NTA Mock Paper 2 (Recommended)
  int _activeNavIndex = 1; // Practice Tab active

  final List<Map<String, dynamic>> _mockPapers = [
    {
      'id': 'mock_2',
      'title': 'NTA Mock Paper 2',
      'isRecommended': true,
      'subtitle': 'Full Syllabus  •  180 Questions',
      'duration': '180 Min',
      'marks': '720 Marks',
      'questionsCount': 180,
      'durationMins': 180,
      'features': [
        'Based on latest NTA pattern and syllabus',
        'Includes Physics, Chemistry, Botany & Zoology',
        'Accurate marking and detailed solutions',
      ],
    },
    {
      'id': 'mock_1',
      'title': 'NTA Mock Paper 1',
      'isRecommended': false,
      'subtitle': 'Full Syllabus  •  180 Questions',
      'duration': '180 Min',
      'marks': '720 Marks',
      'questionsCount': 180,
      'durationMins': 180,
      'features': [
        'Based on previous NTA pattern and syllabus',
        'Includes Physics, Chemistry & Biology',
        'Complete answer key and solutions',
      ],
    },
    {
      'id': 'mock_3',
      'title': 'NTA Mock Paper 3',
      'isRecommended': false,
      'subtitle': 'Full Syllabus  •  180 Questions',
      'duration': '180 Min',
      'marks': '720 Marks',
      'questionsCount': 180,
      'durationMins': 180,
      'features': [
        'Advanced level NTA mock test',
        'Includes High-Yield Physics & Chemistry questions',
        'Instant rank analysis & accuracy reports',
      ],
    },
    {
      'id': 'mock_4',
      'title': 'NTA Mock Paper 4',
      'isRecommended': false,
      'subtitle': 'Full Syllabus  •  180 Questions',
      'duration': '180 Min',
      'marks': '720 Marks',
      'questionsCount': 180,
      'durationMins': 180,
      'features': [
        'Standard NTA NEET Speed Test',
        'Detailed subject-wise breakdown',
        'Negative marking evaluation (+4 / -1)',
      ],
    },
    {
      'id': 'mock_5',
      'title': 'NTA Mock Paper 5',
      'isRecommended': false,
      'subtitle': 'Full Syllabus  •  180 Questions',
      'duration': '180 Min',
      'marks': '720 Marks',
      'questionsCount': 180,
      'durationMins': 180,
      'features': [
        'Comprehensive full syllabus test',
        'Curated by top NEET educators',
        'Real exam environment timer',
      ],
    },
  ];

  void _startSelectedTest() async {
    final selectedPaper = _mockPapers[_selectedPaperIndex];
    final cleanExam = widget.activeExam.contains('JEE') ? 'JEE Main' : 'NEET';

    // Show loading modal or fetch questions
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Preparing ${selectedPaper['title']}...'),
        duration: const Duration(seconds: 1),
      ),
    );

    final questions = await SupabaseService.fetchPYQQuestions(
      exam: cleanExam,
      subjects: ['Physics', 'Chemistry', 'Biology'],
      limit: selectedPaper['questionsCount'] ?? 180,
    );

    if (widget.onStartSession != null) {
      widget.onStartSession!(questions, selectedPaper['durationMins'] ?? 180, true);
    }
  }

  void _showPaperDetailsModal() {
    final selectedPaper = _mockPapers[_selectedPaperIndex];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedPaper['title'],
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Pattern: NEET / NTA Standard\n'
                'Total Duration: ${selectedPaper['duration']}\n'
                'Total Marks: ${selectedPaper['marks']}\n'
                'Marking Scheme: +4 for correct, -1 for incorrect',
                style: const TextStyle(fontSize: 13.5, color: Color(0xFF475569), height: 1.5),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _startSelectedTest();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Start Test Now', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activePaper = _mockPapers[_selectedPaperIndex];
    final featuresList = (activePaper['features'] as List?)?.cast<String>() ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFD),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            _buildHeaderBar(),

            // Scrollable Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                physics: const BouncingScrollPhysics(),
                children: [
                  // Filter Chips Bar
                  _buildFilterChipsBar(),

                  const SizedBox(height: 16),

                  // Mock Papers Selection List (Radio Cards)
                  ..._mockPapers.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final paper = entry.value;
                    final isSelected = _selectedPaperIndex == idx;

                    return _buildPaperRadioCard(
                      title: paper['title'],
                      isRecommended: paper['isRecommended'] ?? false,
                      subtitle: paper['subtitle'],
                      duration: paper['duration'],
                      marks: paper['marks'],
                      isSelected: isSelected,
                      onTap: () {
                        setState(() => _selectedPaperIndex = idx);
                      },
                    );
                  }).toList(),

                  const SizedBox(height: 20),

                  // "About Selected Paper" Container
                  _buildAboutPaperContainer(
                    paperTitle: activePaper['title'],
                    features: featuresList,
                  ),

                  const SizedBox(height: 20),

                  // Action Buttons Row (View Paper Details & Start Test)
                  _buildActionButtonsRow(),

                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Bottom Navigation Bar
            _buildBottomNavigationBar(),
          ],
        ),
      ),
    );
  }

  // Header Bar
  Widget _buildHeaderBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A), size: 22),
            onPressed: () {
              if (widget.onBack != null) {
                widget.onBack!();
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          const Text(
            'Paper-wise (NTA Mock Papers)',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Color(0xFF0F172A), size: 22),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Select an NTA Mock Paper and tap Start Test.')),
              );
            },
          ),
        ],
      ),
    );
  }

  // Horizontal Filter Chips Bar
  Widget _buildFilterChipsBar() {
    final filters = ['Full Papers', 'Subject-wise Papers', 'Previous Year Papers'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.asMap().entries.map((entry) {
          final idx = entry.key;
          final title = entry.value;
          final isSel = _selectedFilterTab == idx;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              onTap: () => setState(() => _selectedFilterTab = idx),
              borderRadius: BorderRadius.circular(24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                decoration: BoxDecoration(
                  color: isSel ? const Color(0xFF4F46E5) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSel ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
                    width: 1.0,
                  ),
                  boxShadow: isSel
                      ? [
                          const BoxShadow(
                            color: Color(0x334F46E5),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                    color: isSel ? Colors.white : const Color(0xFF334155),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Paper Radio Selection Card Widget
  Widget _buildPaperRadioCard({
    required String title,
    required bool isRecommended,
    required String subtitle,
    required String duration,
    required String marks,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF5F3FF) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
          width: isSelected ? 1.6 : 1.0,
        ),
        boxShadow: isSelected
            ? [
                const BoxShadow(
                  color: Color(0x106366F1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                // Radio Button Icon
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF94A3B8),
                      width: isSelected ? 6.5 : 1.8,
                    ),
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),

                // Middle Details Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          if (isRecommended) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Recommended',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6366F1),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),

                // Right Duration & Marks Column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      duration,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      marks,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // About Paper Info Container with Graphic
  Widget _buildAboutPaperContainer({
    required String paperTitle,
    required List<String> features,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEF2FF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Feature Bullets Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About $paperTitle',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 12),
                ...features.map((feat) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEEF2FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Color(0xFF6366F1),
                            size: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feat,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF475569),
                              height: 1.3,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Right Graphic Illustration
          Container(
            width: 80,
            height: 96,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x124F46E5),
                  blurRadius: 10,
                  offset: Offset(2, 4),
                ),
              ],
              border: Border.all(color: const Color(0xFFEEF2FF)),
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 4, width: 40, color: const Color(0xFFF59E0B)),
                const SizedBox(height: 6),
                Container(height: 3, width: 60, color: const Color(0xFFCBD5E1)),
                const SizedBox(height: 4),
                Container(height: 3, width: 55, color: const Color(0xFFCBD5E1)),
                const SizedBox(height: 4),
                Container(height: 3, width: 60, color: const Color(0xFFCBD5E1)),
                const SizedBox(height: 4),
                Container(height: 3, width: 48, color: const Color(0xFFCBD5E1)),
                const Spacer(),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF472B6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Action Buttons Row
  Widget _buildActionButtonsRow() {
    return Row(
      children: [
        // View Paper Details Button
        Expanded(
          flex: 1,
          child: SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _showPaperDetailsModal,
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.description_outlined, color: Color(0xFF4F46E5), size: 20),
              label: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'View Paper Details',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4F46E5),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Start Test Button
        Expanded(
          flex: 1,
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _startSelectedTest,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                elevation: 3,
                shadowColor: const Color(0x404F46E5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Start Test',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Bottom Navigation Bar
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1.0)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home_outlined, 'Home'),
          _buildNavItem(1, Icons.grid_view_rounded, 'Practice'),
          _buildNavItem(2, Icons.assignment_outlined, 'Test'),
          _buildNavItem(3, Icons.menu_book_outlined, 'PYQ'),
          _buildNavItem(4, Icons.person_outline_rounded, 'Profile'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSel = _activeNavIndex == index;
    return InkWell(
      onTap: () => setState(() => _activeNavIndex = index),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFFF3E8FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSel ? const Color(0xFF6366F1) : const Color(0xFF64748B),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                color: isSel ? const Color(0xFF6366F1) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
