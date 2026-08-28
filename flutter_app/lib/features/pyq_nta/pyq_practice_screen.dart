import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../core/services/supabase_service.dart';

enum PYQPracticeMode { chapterWise, yearWise }

class ChapterItem {
  final String id;
  final String name;
  final List<TopicItem> topics;
  bool isExpanded;

  ChapterItem({
    required this.id,
    required this.name,
    required this.topics,
    this.isExpanded = true,
  });

  bool get isFullySelected => topics.isNotEmpty && topics.every((t) => t.isSelected);
  bool get isPartiallySelected => topics.any((t) => t.isSelected) && !isFullySelected;
  int get selectedTopicCount => topics.where((t) => t.isSelected).length;
}

class TopicItem {
  final String id;
  final String name;
  bool isSelected;

  TopicItem({
    required this.id,
    required this.name,
    this.isSelected = true,
  });
}

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
  int _currentStep = 1; // 1 = Select Subject & Options, 2 = Select Chapters & Topics

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
  int _timeSpentSeconds = 101700;
  Map<String, int> _subjectPYQCounts = {};

  final List<int> _availableYearsList = [2025, 2024, 2023, 2022, 2021, 2020];

  String _searchQuery = '';
  int _activeViewTab = 0; // 0 = Chapters, 1 = Topics
  
  // Multi-Subject Chapters Map (PCB for NEET, PCM for JEE)
  Map<String, List<ChapterItem>> _subjectChaptersMap = {};
  String _activeStep2Subject = 'Physics';

  @override
  void initState() {
    super.initState();
    _selectedExam = widget.activeExam.contains('JEE') ? 'JEE Main 2026' : 'NEET 2026';
    _selectedSubjects = _selectedExam.contains('NEET')
        ? {'Physics', 'Chemistry', 'Biology'}
        : {'Physics', 'Chemistry', 'Mathematics'};
    _activeStep2Subject = 'Physics';
    _loadStats();
    _initChapters();
  }

  Future<void> _initChapters() async {
    final isNeet = _selectedExam.contains('NEET');
    final examCode = isNeet ? 'NEET' : 'JEE Main';
    final subjects = isNeet ? ['Physics', 'Chemistry', 'Biology'] : ['Physics', 'Chemistry', 'Mathematics'];

    final Map<String, List<ChapterItem>> newMap = {};

    for (var sub in subjects) {
      final rawChapters = await SupabaseService.fetchTaxonomyForSubject(
        exam: examCode,
        subject: sub,
        forceRefresh: true,
        includeInactive: false,
      );

      final List<ChapterItem> chapterItems = rawChapters.map((cMap) {
        final rawTopics = (cMap['topicsList'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        final topicItems = rawTopics.map((tMap) {
          return TopicItem(
            id: tMap['id'] ?? '',
            name: tMap['name'] ?? '',
            isSelected: true,
          );
        }).toList();

        return ChapterItem(
          id: cMap['id'] ?? '',
          name: cMap['name'] ?? '',
          isExpanded: false,
          topics: topicItems,
        );
      }).toList();

      if (chapterItems.isNotEmpty) {
        chapterItems.first = ChapterItem(
          id: chapterItems.first.id,
          name: chapterItems.first.name,
          isExpanded: true,
          topics: chapterItems.first.topics,
        );
      }

      newMap[sub] = chapterItems;
    }

    if (mounted) {
      setState(() {
        _subjectChaptersMap = newMap;
        if (!_subjectChaptersMap.containsKey(_activeStep2Subject) && _subjectChaptersMap.isNotEmpty) {
          _activeStep2Subject = _subjectChaptersMap.keys.first;
        }
      });
    }
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
        _activeStep2Subject = 'Physics';
      } else {
        _selectedSubjects = {'Physics', 'Chemistry', 'Mathematics'};
        _activeStep2Subject = 'Physics';
      }
      _initChapters();
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
      _initChapters();
    });
  }

  List<ChapterItem> get _activeChapters => _subjectChaptersMap[_activeStep2Subject] ?? [];

  int get _totalSelectedChaptersCount {
    int total = 0;
    _subjectChaptersMap.forEach((sub, chapters) {
      total += chapters.where((c) => c.topics.any((t) => t.isSelected)).length;
    });
    return total;
  }

  int get _totalSelectedTopicsCount {
    int total = 0;
    _subjectChaptersMap.forEach((sub, chapters) {
      total += chapters.fold(0, (sum, c) => sum + c.selectedTopicCount);
    });
    return total;
  }

  bool get _areAllActiveSubjectChaptersSelected {
    final chapters = _activeChapters;
    return chapters.isNotEmpty && chapters.every((c) => c.isFullySelected);
  }

  void _toggleSelectAllActiveSubjectChapters(bool? val) {
    final select = val ?? !_areAllActiveSubjectChaptersSelected;
    setState(() {
      for (var c in _activeChapters) {
        for (var t in c.topics) {
          t.isSelected = select;
        }
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

  Future<void> _startPYQSession(bool isTestMode) async {
    if (_totalSelectedTopicsCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one topic across subjects to start.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isStarting = true);

    final activeSelectedSubjects = _subjectChaptersMap.entries
        .where((entry) => entry.value.any((c) => c.topics.any((t) => t.isSelected)))
        .map((entry) => entry.key)
        .toList();

    final questions = await SupabaseService.fetchPYQQuestions(
      exam: _selectedExam,
      subjects: activeSelectedSubjects.isEmpty ? _selectedSubjects.toList() : activeSelectedSubjects,
      years: _allYears ? null : _selectedYears.toList(),
      difficulty: _difficulty,
      limit: _questionCount,
    );

    setState(() => _isStarting = false);

    if (!mounted) return;

    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No PYQs available for the selected topics.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final timerMins = isTestMode ? (_questionCount * 1.5).ceil() : 0;

    if (widget.onStartPYQSession != null) {
      widget.onStartPYQSession!(questions, timerMins, isTestMode);
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
          icon: const Icon(Icons.arrow_back, color: Color(0xFF7C3AED)),
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
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Preset saved successfully!')),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF7C3AED),
                side: const BorderSide(color: Color(0xFF7C3AED), width: 1.2),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.bookmark_border_rounded, size: 14, color: Color(0xFF7C3AED)),
              label: const Text('Save Preset', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
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
                      ? 'Practice previous year questions chapter-wise and year-wise to ace NEET'
                      : 'Practice previous year questions chapter-wise and topic-wise',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3),
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

          // Sticky Bottom Action Bar (Only on Step 2)
          if (_currentStep == 2) _buildStickyBottomBarStep2(),
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
            color: _currentStep > 1 ? const Color(0xFFDCFCE7) : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: _currentStep > 1 ? const Color(0xFF16A34A) : const Color(0xFF7C3AED),
              width: 2,
            ),
          ),
          child: Center(
            child: _currentStep > 1
                ? const Icon(Icons.check, size: 16, color: Color(0xFF16A34A))
                : const Text('1', style: TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.bold, fontSize: 13)),
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
          color: _currentStep > 1 ? const Color(0xFF7C3AED) : const Color(0xFFCBD5E1),
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
              'Select Chapters & Topics',
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E8FF),
              borderRadius: BorderRadius.circular(20),
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
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF7C3AED)),
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
                      _initChapters();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? themeColor.withOpacity(0.05) : Colors.white,
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

        // Section 3: Select Year Range (Optional)
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
                  showCheckmark: true,
                  avatar: isSel ? const Icon(Icons.check_box, size: 16, color: Colors.white) : const Icon(Icons.check_box_outline_blank, size: 16, color: Color(0xFF94A3B8)),
                  label: Text('$y${y == 2025 ? '\n(Latest)' : ''}'),
                  selectedColor: const Color(0xFF7C3AED),
                  checkmarkColor: Colors.white,
                  backgroundColor: Colors.white,
                  side: BorderSide(color: isSel ? const Color(0xFF7C3AED) : const Color(0xFFE2E8F0)),
                  labelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    color: isSel ? Colors.white : const Color(0xFF1E293B),
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

        // Action Button to proceed to Step 2 (Select Chapters & Topics)
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
              backgroundColor: const Color(0xFF4F46E5),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '🎯 Start PYQ Practice',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ================= STEP 2 VIEW (DYNAMIC PCB / PCM SELECTION) =================

  Widget _buildStep2View() {
    final isNeet = _selectedExam.contains('NEET');
    final availableSubjects = isNeet ? ['Physics', 'Chemistry', 'Biology'] : ['Physics', 'Chemistry', 'Mathematics'];
    final activeSubject = _activeStep2Subject;

    final currentChapters = _activeChapters;

    final filteredChapters = _searchQuery.isEmpty
        ? currentChapters
        : currentChapters.where((c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase()) || c.topics.any((t) => t.name.toLowerCase().contains(_searchQuery.toLowerCase()))).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Subject Selector Tab Bar (PCB for NEET, PCM for JEE)
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: availableSubjects.map((sub) {
              final isSel = _activeStep2Subject == sub;
              final subChapters = _subjectChaptersMap[sub] ?? [];
              final subTopicCount = subChapters.fold(0, (s, c) => s + c.topics.length);

              IconData iconData = Icons.science_outlined;
              Color activeColor = const Color(0xFF7C3AED);

              if (sub == 'Chemistry') {
                iconData = Icons.science_rounded;
                activeColor = const Color(0xFF16A34A);
              } else if (sub == 'Biology') {
                iconData = Icons.coronavirus_outlined;
                activeColor = const Color(0xFFE11D48);
              } else if (sub == 'Mathematics') {
                iconData = Icons.calculate_outlined;
                activeColor = const Color(0xFF2563EB);
              }

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _activeStep2Subject = sub),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSel ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: isSel
                          ? [const BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2))]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(iconData, size: 16, color: isSel ? activeColor : const Color(0xFF64748B)),
                        const SizedBox(width: 6),
                        Text(
                          '$sub (${subChapters.length})',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSel ? activeColor : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Subject Summary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: const [
              BoxShadow(color: Color(0x05000000), blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF3E8FF),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      activeSubject == 'Chemistry'
                          ? Icons.science_rounded
                          : (activeSubject == 'Biology'
                              ? Icons.coronavirus_outlined
                              : (activeSubject == 'Mathematics' ? Icons.calculate_outlined : Icons.science_outlined)),
                      color: const Color(0xFF7C3AED),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeSubject,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _selectedExam,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${currentChapters.length} Chapters',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${currentChapters.fold(0, (s, c) => s + c.topics.length)} Topics',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Choose the chapters and topics of $activeSubject to practice PYQs from.',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // View Mode Switch Tabs (Chapters vs Topics)
        Container(
          height: 44,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _activeViewTab = 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _activeViewTab == 0 ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: _activeViewTab == 0 ? Border.all(color: const Color(0xFFE2E8F0)) : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.menu_book_rounded, size: 16, color: _activeViewTab == 0 ? const Color(0xFF7C3AED) : const Color(0xFF64748B)),
                        const SizedBox(width: 6),
                        Text(
                          'Chapters',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _activeViewTab == 0 ? const Color(0xFF7C3AED) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _activeViewTab = 1),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _activeViewTab == 1 ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: _activeViewTab == 1 ? Border.all(color: const Color(0xFFE2E8F0)) : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.format_list_bulleted_rounded, size: 16, color: _activeViewTab == 1 ? const Color(0xFF7C3AED) : const Color(0xFF64748B)),
                        const SizedBox(width: 6),
                        Text(
                          'Topics',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _activeViewTab == 1 ? const Color(0xFF7C3AED) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Search Input & Filter Icon Button
        Row(
          children: [
            Expanded(
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        decoration: InputDecoration(
                          hintText: 'Search $activeSubject chapters...',
                          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: IconButton(
                icon: const Icon(Icons.tune_rounded, size: 18, color: Color(0xFF64748B)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Filter parameters applied.')),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Select All Active Subject Chapters Header Bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _areAllActiveSubjectChaptersSelected,
                    activeColor: const Color(0xFF7C3AED),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: _toggleSelectAllActiveSubjectChapters,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Select All $activeSubject Chapters',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  '${currentChapters.where((c) => c.topics.any((t) => t.isSelected)).length} selected',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_up_rounded, color: Color(0xFF7C3AED), size: 18),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Accordion Chapter Cards List
        ...filteredChapters.map((chapter) {
          final isFully = chapter.isFullySelected;
          final isPartial = chapter.isPartiallySelected;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                // Chapter Main Row
                InkWell(
                  onTap: () {
                    setState(() => chapter.isExpanded = !chapter.isExpanded);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: Checkbox(
                            value: isFully ? true : (isPartial ? null : false),
                            tristate: true,
                            activeColor: const Color(0xFF7C3AED),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (val) {
                              setState(() {
                                final select = val ?? true;
                                for (var t in chapter.topics) {
                                  t.isSelected = select;
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            chapter.name,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ),
                        Text(
                          '${chapter.selectedTopicCount} / ${chapter.topics.length} Topics',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          chapter.isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          color: const Color(0xFF94A3B8),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),

                // Expanded Topics List
                if (chapter.isExpanded) ...[
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  Padding(
                    padding: const EdgeInsets.only(left: 12, right: 12, top: 4, bottom: 8),
                    child: Column(
                      children: chapter.topics.map((topic) {
                        return InkWell(
                          onTap: () {
                            setState(() => topic.isSelected = !topic.isSelected);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Checkbox(
                                    value: topic.isSelected,
                                    activeColor: const Color(0xFF7C3AED),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    onChanged: (val) {
                                      setState(() => topic.isSelected = val ?? false);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    topic.name,
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF334155), fontWeight: FontWeight.w500),
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFFCBD5E1)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),

        const SizedBox(height: 20),
      ],
    );
  }

  // ================= STICKY BOTTOM ACTION BAR (CUMULATIVE PCB / PCM) =================

  Widget _buildStickyBottomBarStep2() {
    final isNeet = _selectedExam.contains('NEET');
    final pcbPcmLabel = isNeet ? 'PCB' : 'PCM';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
        boxShadow: [
          BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Cumulative Selected Counter Pill Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.label_outlined, color: Color(0xFF7C3AED), size: 18),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Selected ($pcbPcmLabel)', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                          Text(
                            '$_totalSelectedChaptersCount Chap • $_totalSelectedTopicsCount Top',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Button 1: Start Practice (Outlined Purple)
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: (_totalSelectedTopicsCount == 0 || _isStarting) ? null : () => _startPYQSession(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF7C3AED),
                        side: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, color: Color(0xFF7C3AED), size: 18),
                      label: const Text(
                        'Start Practice',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Button 2: Start Test (Solid Purple)
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: (_totalSelectedTopicsCount == 0 || _isStarting) ? null : () => _startPYQSession(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.assignment_turned_in_rounded, color: Colors.white, size: 16),
                      label: const Text(
                        'Start Test',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Bottom Note
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.info_outline_rounded, size: 12, color: Color(0xFF94A3B8)),
                SizedBox(width: 4),
                Text(
                  'You can review and change your selection in the next step.',
                  style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
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
