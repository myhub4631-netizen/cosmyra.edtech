import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../models/pyq_models.dart';
import '../../core/services/supabase_service.dart';

class PYQPracticeScreen extends StatefulWidget {
  final String activeExam; // 'NEET' or 'JEE Main' or 'JEE Advanced'
  final Function(List<QuestionModel> questions, int timerMinutes) onStartPractice;
  final VoidCallback? onBack;

  const PYQPracticeScreen({
    Key? key,
    required this.activeExam,
    required this.onStartPractice,
    this.onBack,
  }) : super(key: key);

  @override
  State<PYQPracticeScreen> createState() => _PYQPracticeScreenState();
}

class _PYQPracticeScreenState extends State<PYQPracticeScreen> {
  late String _selectedExam;
  late Set<String> _selectedSubjects;
  PYQPracticeMode _selectedMode = PYQPracticeMode.chapterWise;
  
  bool _allYears = true;
  Set<int> _selectedYears = {2025};
  
  int _questionCount = 20;
  String _difficulty = 'Medium';

  bool _isLoadingStats = true;
  bool _isStarting = false;

  int _availableQuestionsCount = 1248;
  int _availablePapersCount = 98;
  double _userAccuracy = 72.4;
  int _timeSpentSeconds = 101700; // 28h 15m default
  Map<String, int> _subjectPYQCounts = {};

  final List<int> _availableYearsList = [2025, 2024, 2023, 2022, 2021, 2020, 2019, 2018];

  @override
  void initState() {
    super.initState();
    _selectedExam = widget.activeExam.contains('JEE') ? 'JEE Main 2026' : 'NEET 2026';
    _selectedSubjects = _selectedExam.contains('NEET')
        ? {'Physics', 'Chemistry', 'Biology'}
        : {'Physics', 'Chemistry', 'Mathematics'};
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoadingStats = true);
    final stats = await SupabaseService.fetchPYQStats(_selectedExam);
    final counts = await SupabaseService.fetchSubjectPYQCounts(_selectedExam);
    if (mounted) {
      setState(() {
        _availableQuestionsCount = stats['availableQuestions'] ?? 1248;
        _availablePapersCount = stats['availablePapers'] ?? 98;
        _userAccuracy = stats['avgAccuracy'] ?? 72.4;
        _timeSpentSeconds = stats['timeSpentSeconds'] ?? 101700;
        _subjectPYQCounts = counts;
        _isLoadingStats = false;
      });
    }
  }

  void _onExamChanged(String newExam) {
    setState(() {
      _selectedExam = newExam;
      if (newExam.contains('NEET')) {
        _selectedSubjects = {'Physics', 'Chemistry', 'Biology'};
      } else {
        _selectedSubjects = {'Physics', 'Chemistry', 'Mathematics'};
      }
    });
    _loadStats();
  }

  void _toggleSelectAllSubjects() {
    setState(() {
      final all = _selectedExam.contains('NEET')
          ? {'Physics', 'Chemistry', 'Biology'}
          : {'Physics', 'Chemistry', 'Mathematics'};
      if (_selectedSubjects.length == all.length) {
        _selectedSubjects = {all.first};
      } else {
        _selectedSubjects = Set.from(all);
      }
    });
  }

  String _formatTimeSpent(int seconds) {
    final hours = seconds ~/ 3600;
    final mins = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }

  Future<void> _handleStartPractice() async {
    if (_selectedSubjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one subject to start practice.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isStarting = true);

    final questions = await SupabaseService.fetchPYQQuestions(
      exam: _selectedExam,
      subjects: _selectedSubjects.toList(),
      mode: _selectedMode,
      years: _allYears ? null : _selectedYears.toList(),
      difficulty: _difficulty,
      limit: _questionCount,
    );

    setState(() => _isStarting = false);

    if (!mounted) return;

    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No PYQ questions match your selected filters. Please adjust filters.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (questions.length < _questionCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Only ${questions.length} questions are available for your selected filters.'),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    // Launch Practice Screen with loaded real PYQs (0 timer for practice mode)
    widget.onStartPractice(questions, 0);
  }

  @override
  Widget build(BuildContext context) {
    final isNeet = _selectedExam.contains('NEET');
    final availableSubjects = isNeet ? ['Physics', 'Chemistry', 'Biology'] : ['Physics', 'Chemistry', 'Mathematics'];
    final allSelected = _selectedSubjects.length == availableSubjects.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: widget.onBack ?? () => Navigator.maybePop(context),
        ),
        title: const Text(
          'PYQ Practice',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border_rounded, color: Color(0xFF7C3AED)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Saved PYQs and Bookmarks accessible in My Mistakes & Bookmarks.')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subtitle
            const Center(
              child: Text(
                'Practice previous year questions chapter-wise and year-wise to ace your exam',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.3),
              ),
            ),
            const SizedBox(height: 14),

            // Top Exam Selector Dropdown Pill
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedExam,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF7C3AED)),
                    isDense: true,
                    items: ['NEET 2026', 'JEE Main 2026', 'JEE Advanced 2026'].map((e) {
                      return DropdownMenuItem<String>(
                        value: e,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.shield, size: 16, color: Color(0xFF7C3AED)),
                            const SizedBox(width: 6),
                            Text(
                              e,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) _onExamChanged(val);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 4 Real-time Stat Cards
            _isLoadingStats
                ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final cardWidth = (constraints.maxWidth - 12) / 2;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildStatCard(
                            width: cardWidth,
                            icon: Icons.track_changes_rounded,
                            iconBg: const Color(0xFFDCFCE7),
                            iconColor: const Color(0xFF16A34A),
                            value: '$_availableQuestionsCount',
                            label: 'Questions\nAvailable',
                          ),
                          _buildStatCard(
                            width: cardWidth,
                            icon: Icons.assignment_outlined,
                            iconBg: const Color(0xFFDBEAFE),
                            iconColor: const Color(0xFF2563EB),
                            value: '$_availablePapersCount',
                            label: 'PYQ Papers\nAvailable',
                          ),
                          _buildStatCard(
                            width: cardWidth,
                            icon: Icons.trending_up_rounded,
                            iconBg: const Color(0xFFF3E8FF),
                            iconColor: const Color(0xFF9333EA),
                            value: '$_userAccuracy%',
                            label: 'Avg. Accuracy\n(Your)',
                          ),
                          _buildStatCard(
                            width: cardWidth,
                            icon: Icons.access_time_rounded,
                            iconBg: const Color(0xFFFFEDD5),
                            iconColor: const Color(0xFFEA580C),
                            value: _formatTimeSpent(_timeSpentSeconds),
                            label: 'Time Spent\nPracticing',
                          ),
                        ],
                      );
                    },
                  ),
            const SizedBox(height: 24),

            // Section 1: Select Subjects
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '1. Select Subjects',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                GestureDetector(
                  onTap: _toggleSelectAllSubjects,
                  child: Text(
                    allSelected ? 'Deselect All' : 'Select All',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF7C3AED)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: availableSubjects.map((subName) {
                final isSelected = _selectedSubjects.contains(subName);
                final count = _subjectPYQCounts[subName] ?? (subName == 'Physics' ? 520 : (subName == 'Chemistry' ? 436 : (isNeet ? 292 : 480)));

                IconData iconData = Icons.science_outlined;
                Color themeColor = const Color(0xFF7C3AED);
                Color iconBg = const Color(0xFFF3E8FF);

                if (subName == 'Chemistry') {
                  iconData = Icons.science_rounded;
                  themeColor = const Color(0xFF16A34A);
                  iconBg = const Color(0xFFDCFCE7);
                } else if (subName == 'Biology') {
                  iconData = Icons.coronavirus_outlined;
                  themeColor = const Color(0xFFE11D48);
                  iconBg = const Color(0xFFFFE4E6);
                } else if (subName == 'Mathematics') {
                  iconData = Icons.calculate_outlined;
                  themeColor = const Color(0xFF2563EB);
                  iconBg = const Color(0xFFDBEAFE);
                }

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            if (_selectedSubjects.length > 1) {
                              _selectedSubjects.remove(subName);
                            }
                          } else {
                            _selectedSubjects.add(subName);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? themeColor.withOpacity(0.04) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? themeColor : const Color(0xFFE2E8F0),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                                  child: Icon(iconData, color: themeColor, size: 24),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  subName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$count PYQs',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                            if (isSelected)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(color: themeColor, shape: BoxShape.circle),
                                  child: const Icon(Icons.check, color: Colors.white, size: 12),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Section 2: Choose Practice Mode
            const Text(
              '2. Choose Practice Mode',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildModeCard(
                    mode: PYQPracticeMode.chapterWise,
                    icon: Icons.calendar_today_outlined,
                    title: 'Chapter-wise',
                    subtitle: 'Practice PYQs by specific chapters and topics',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildModeCard(
                    mode: PYQPracticeMode.yearWise,
                    icon: Icons.edit_calendar_outlined,
                    title: 'Year-wise',
                    subtitle: 'Practice PYQs from specific years',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Section 3: Select Year Range (or Chapter selection)
            if (_selectedMode == PYQPracticeMode.yearWise) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '3. Select Year Range (Optional)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  Row(
                    children: [
                      const Text('All Years', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      const SizedBox(width: 4),
                      Switch(
                        value: _allYears,
                        activeColor: const Color(0xFF7C3AED),
                        onChanged: (val) {
                          setState(() {
                            _allYears = val;
                            if (val) _selectedYears = Set.from(_availableYearsList);
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _availableYearsList.map((y) {
                    final isSel = _allYears || _selectedYears.contains(y);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        selected: isSel,
                        label: Text('$y${y == 2025 ? ' (Latest)' : ''}'),
                        selectedColor: const Color(0xFFEEF2FF),
                        checkmarkColor: const Color(0xFF7C3AED),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          color: isSel ? const Color(0xFF7C3AED) : const Color(0xFF475569),
                        ),
                        onSelected: (selected) {
                          setState(() {
                            _allYears = false;
                            if (selected) {
                              _selectedYears.add(y);
                            } else {
                              if (_selectedYears.length > 1) {
                                _selectedYears.remove(y);
                              }
                            }
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Section 4: Number of Questions & Difficulty
            const Text(
              '4. Number of Questions & Difficulty',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Number of Questions', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _questionCount,
                            isExpanded: true,
                            items: [10, 20, 30, 50, 100].map((c) {
                              return DropdownMenuItem<int>(
                                value: c,
                                child: Text('$c Questions', style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B))),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _questionCount = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Difficulty Level', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _difficulty,
                            isExpanded: true,
                            items: ['Mixed', 'Easy', 'Medium', 'Hard'].map((d) {
                              return DropdownMenuItem<String>(
                                value: d,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: d == 'Easy'
                                            ? Colors.green
                                            : (d == 'Medium' ? Colors.orange : (d == 'Hard' ? Colors.red : Colors.purple)),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(d, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B))),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _difficulty = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Start Action Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isStarting ? null : _handleStartPractice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isStarting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.track_changes_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Start PYQ Practice',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required double width,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(color: Color(0x05000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), height: 1.1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard({
    required PYQPracticeMode mode,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _selectedMode = mode),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFDDD6FE) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFF64748B), size: 18),
                ),
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFCBD5E1),
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), height: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}
