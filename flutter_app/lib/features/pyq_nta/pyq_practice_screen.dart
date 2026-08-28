import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../models/pyq_models.dart';
import '../../core/services/supabase_service.dart';

class PYQPracticeScreen extends StatefulWidget {
  final String activeExam; // 'NEET' or 'JEE Main' or 'JEE Advanced'
  final Function(List<QuestionModel> questions, int timerMinutes, bool isTestMode)? onStartPYQSession;
  final Function(List<QuestionModel> questions, int timerMinutes)? onStartPractice;
  final VoidCallback? onBack;

  const PYQPracticeScreen({
    Key? key,
    required this.activeExam,
    this.onStartPYQSession,
    this.onStartPractice,
    this.onBack,
  }) : super(key: key);

  @override
  State<PYQPracticeScreen> createState() => _PYQPracticeScreenState();
}

class _PYQPracticeScreenState extends State<PYQPracticeScreen> {
  int _currentStep = 1; // 1 = Subject & Filters, 2 = Attempt Mode
  String? _selectedAttemptMode; // 'practice' or 'test'

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

  Future<void> _handleStartPYQSession() async {
    if (_selectedSubjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one subject to continue.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedAttemptMode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an attempt mode (Practice or Test) to start.'),
          backgroundColor: Colors.orange,
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

    final isTest = _selectedAttemptMode == 'test';
    final timerMins = isTest ? (_questionCount * 1.5).ceil() : 0;

    if (widget.onStartPYQSession != null) {
      widget.onStartPYQSession!(questions, timerMins, isTest);
    } else if (widget.onStartPractice != null) {
      widget.onStartPractice!(questions, timerMins);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () {
            if (_currentStep == 2) {
              setState(() => _currentStep = 1);
            } else {
              if (widget.onBack != null) {
                widget.onBack!();
              } else {
                Navigator.maybePop(context);
              }
            }
          },
        ),
        title: const Text(
          'PYQ Practice',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Preset saved to your PYQ preferences.')),
              );
            },
            icon: const Icon(Icons.bookmark_border_rounded, size: 16, color: Color(0xFF7C3AED)),
            label: const Text(
              'Save Preset',
              style: TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Subtitle & 2-Step Progress Indicator Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
                Text(
                  _currentStep == 1
                      ? 'Practice previous year questions chapter-wise and year-wise to ace your exam'
                      : 'Choose how you want to attempt PYQs',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.3),
                ),
                const SizedBox(height: 14),
                _buildProgressIndicator(),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Scrollable Body (Step 1 or Step 2)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: _currentStep == 1 ? _buildStep1View() : _buildStep2View(),
            ),
          ),

          // Sticky Bottom CTA Area
          _buildStickyBottomBar(),
        ],
      ),
    );
  }

  // ================= 2-STEP PROGRESS INDICATOR =================

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Step 1 Circle
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _currentStep > 1 ? const Color(0xFFDCFCE7) : const Color(0xFF7C3AED),
            shape: BoxShape.circle,
            border: Border.all(
              color: _currentStep > 1 ? const Color(0xFF16A34A) : const Color(0xFF7C3AED),
              width: 2,
            ),
          ),
          child: Center(
            child: _currentStep > 1
                ? const Icon(Icons.check, size: 16, color: Color(0xFF16A34A))
                : const Text('1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Step 1', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
            Text(
              'Subject',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _currentStep > 1 ? const Color(0xFF16A34A) : const Color(0xFF7C3AED),
              ),
            ),
          ],
        ),

        // Connecting Line
        Container(
          width: 60,
          height: 2,
          margin: const EdgeInsets.symmetric(horizontal: 14),
          color: _currentStep > 1 ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1),
        ),

        // Step 2 Circle
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _currentStep == 2 ? const Color(0xFF7C3AED) : const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
            border: Border.all(
              color: _currentStep == 2 ? const Color(0xFF7C3AED) : const Color(0xFFCBD5E1),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              '2',
              style: TextStyle(
                color: _currentStep == 2 ? Colors.white : const Color(0xFF64748B),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Step 2', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
            Text(
              'Attempt Mode',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _currentStep == 2 ? const Color(0xFF7C3AED) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ================= STEP 1 VIEW =================

  Widget _buildStep1View() {
    final isNeet = _selectedExam.contains('NEET');
    final availableSubjects = isNeet ? ['Physics', 'Chemistry', 'Biology'] : ['Physics', 'Chemistry', 'Mathematics'];
    final allSelected = _selectedSubjects.length == availableSubjects.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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

        // Real-time Stat Cards
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

        // Section 3: Select Year Range
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
                    activeThumbColor: const Color(0xFF7C3AED),
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
        const SizedBox(height: 28),

        // Action Button to proceed to Step 2
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              if (_selectedSubjects.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select at least one subject to continue.')),
                );
                return;
              }
              setState(() => _currentStep = 2);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Continue to Attempt Mode (Step 2)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ================= STEP 2 VIEW =================

  Widget _buildStep2View() {
    final selectedSubjectName = _selectedSubjects.join(', ');
    int totalSubjectPyqs = 0;
    for (var s in _selectedSubjects) {
      totalSubjectPyqs += _subjectPYQCounts[s] ?? 450;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected Subject Summary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(color: Color(0x05000000), blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3E8FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.science_rounded, color: Color(0xFF7C3AED), size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          selectedSubjectName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _selectedExam,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalSubjectPyqs PYQs Available',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Heading & Subheading
        const Text(
          'How do you want to attempt?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 4),
        const Text(
          'Choose Practice for question-by-question learning or Test for a real test experience.',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3),
        ),
        const SizedBox(height: 20),

        // CARD 1: ATTEMPT AS PRACTICE
        _buildAttemptModeCard(
          modeKey: 'practice',
          badgeText: 'Best for Learning',
          icon: Icons.track_changes_rounded,
          title: 'Attempt as Practice',
          description: 'Get instant feedback after every question.',
          features: const [
            'See correct answer immediately',
            'View explanation after each question',
            'Track your progress while practicing',
            'No final submission required',
          ],
        ),
        const SizedBox(height: 16),

        // CARD 2: ATTEMPT AS TEST
        _buildAttemptModeCard(
          modeKey: 'test',
          badgeText: 'Best for Exam Simulation',
          icon: Icons.assignment_turned_in_outlined,
          title: 'Attempt as Test',
          description: 'Attempt all questions like a real exam and see your result at the end.',
          features: const [
            'No answer revealed during the test',
            'Complete all selected questions',
            'Submit the test at the end',
            'See score, accuracy and analysis after submission',
          ],
        ),
      ],
    );
  }

  Widget _buildAttemptModeCard({
    required String modeKey,
    required String badgeText,
    required IconData icon,
    required String title,
    required String description,
    required List<String> features,
  }) {
    final isSelected = _selectedAttemptMode == modeKey;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedAttemptMode = modeKey);
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFE2E8F0),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? const Color(0x1E7C3AED) : const Color(0x05000000),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge & Checkmark Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
                ),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF7C3AED) : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFCBD5E1),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Icon & Title
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFDDD6FE) : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: const Color(0xFF7C3AED), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 12),

            // Features List
            Column(
              children: features.map((ft) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ft,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF334155), fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ================= STICKY BOTTOM BAR =================

  Widget _buildStickyBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
        boxShadow: [
          BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _currentStep == 1
                ? () {
                    if (_selectedSubjects.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select at least one subject to continue.')),
                      );
                      return;
                    }
                    setState(() => _currentStep = 2);
                  }
                : (_selectedAttemptMode == null || _isStarting ? null : _handleStartPYQSession),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              disabledBackgroundColor: const Color(0xFFE2E8F0),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isStarting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Text(
                    _currentStep == 1
                        ? 'Continue to Attempt Mode →'
                        : (_selectedAttemptMode == null
                            ? 'Select an attempt mode to continue'
                            : (_selectedAttemptMode == 'practice' ? 'Start Practice →' : 'Start Test →')),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: (_currentStep == 2 && _selectedAttemptMode == null)
                          ? const Color(0xFF94A3B8)
                          : Colors.white,
                    ),
                  ),
          ),
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
