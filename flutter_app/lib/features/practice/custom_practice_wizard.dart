import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../core/services/supabase_service.dart';

class CustomPracticeWizardModal extends StatefulWidget {
  final String initialExam;
  final VoidCallback? onClose;
  final Function(List<QuestionModel> questions, int timerMinutes) onStartPractice;

  const CustomPracticeWizardModal({
    super.key,
    required this.initialExam,
    this.onClose,
    required this.onStartPractice,
  });

  @override
  State<CustomPracticeWizardModal> createState() => _CustomPracticeWizardModalState();
}

class _CustomPracticeWizardModalState extends State<CustomPracticeWizardModal> {
  int _currentStep = 0; // 0: Exam & Subjects, 1: Chapters & Topics, 2: Practice Settings, 3: Overview
  late String _selectedExam;

  List<SubjectModel> _availableSubjects = [];
  final Set<String> _selectedSubjectIds = {};

  final Set<String> _selectedChapterIds = {};

  // Screen 2 specific selection states matching exact screenshot
  final Set<String> _selectedChapterNames = {'Mechanics', 'Thermodynamics', 'Optics'};
  bool _showMoreChapters = false;

  final Set<String> _selectedTopicNames = {'Laws of Motion', 'Work, Energy & Power', 'Gravitation'};
  bool _showMoreTopics = false;

  String _selectedSource = 'Mixed';
  String _selectedDifficulty = 'Mixed';
  int _questionCount = 15;
  int _timerMinutes = 15;
  bool _isLoading = false;

  final TextEditingController _presetNameController = TextEditingController();
  final List<Map<String, dynamic>> _savedPresets = [
    {
      'name': 'Quick NEET Physics & Chem',
      'exam': 'NEET',
      'subjects': ['Physics', 'Chemistry'],
      'questions': 15,
      'timer': 15,
      'difficulty': 'Medium',
    },
    {
      'name': 'Hard PYQ Challenge',
      'exam': 'NEET',
      'subjects': ['Biology'],
      'questions': 30,
      'timer': 30,
      'difficulty': 'Hard',
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedExam = widget.initialExam.contains('JEE') ? 'JEE' : 'NEET';
    _loadSubjects();
  }

  @override
  void dispose() {
    _presetNameController.dispose();
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    setState(() => _isLoading = true);
    final subjects = await SupabaseService.getSubjects(
      examId: _selectedExam == 'JEE'
          ? '22222222-2222-2222-2222-222222222222'
          : '11111111-1111-1111-1111-111111111111',
    );
    setState(() {
      _availableSubjects = subjects;
      _selectedSubjectIds.clear();
      // Select all subjects by default to match screenshot state
      for (final sub in subjects) {
        _selectedSubjectIds.add(sub.id);
      }
      _isLoading = false;
    });
    _loadChapters();
  }

  Future<void> _loadChapters() async {
    if (_selectedSubjectIds.isEmpty) {
      return;
    }
    List<ChapterModel> allChs = [];
    for (final subId in _selectedSubjectIds) {
      final chs = await SupabaseService.getChapters(subId);
      allChs.addAll(chs);
    }
    setState(() {
      _selectedChapterIds.clear();
      for (final ch in allChs) {
        _selectedChapterIds.add(ch.id);
      }
    });
  }

  void _selectAllSubjects() {
    setState(() {
      if (_selectedSubjectIds.length == _availableSubjects.length) {
        _selectedSubjectIds.clear();
      } else {
        _selectedSubjectIds.clear();
        for (final sub in _availableSubjects) {
          _selectedSubjectIds.add(sub.id);
        }
      }
    });
    _loadChapters();
  }

  void _handleStartSession() async {
    setState(() => _isLoading = true);
    final questions = await SupabaseService.fetchQuestions(
      examId: _selectedExam,
      subjectId: _selectedSubjectIds.isNotEmpty ? _selectedSubjectIds.first : null,
      source: _selectedSource.toLowerCase(),
      difficulty: _selectedDifficulty.toLowerCase(),
      limit: _questionCount,
    );
    setState(() => _isLoading = false);
    if (mounted) {
      Navigator.of(context).pop();
      widget.onStartPractice(questions, _timerMinutes);
    }
  }

  void _showPresetsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.bookmark_rounded, color: Color(0xFF4F46E5)),
            SizedBox(width: 8),
            Text('Saved Presets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_savedPresets.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No saved presets yet.'),
                )
              else
                ..._savedPresets.map((p) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: ListTile(
                        title: Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${p['exam']} • ${p['questions']} Qs • ${p['difficulty']}'),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            setState(() {
                              _selectedExam = p['exam'];
                              _questionCount = p['questions'];
                              _timerMinutes = p['timer'];
                              _selectedDifficulty = p['difficulty'];
                            });
                            _loadSubjects();
                          },
                          child: const Text('Load', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Header Bar
            _buildTopHeader(),

            // 2. Step Progress Indicator (1: Exam & Subjects, 2: Chapters & Topics, 3: Practice Settings, 4: Overview)
            _buildStepIndicator(),

            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // 3. Scrollable Main Content Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 32.0),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: _isLoading
                        ? const SizedBox(
                            height: 300,
                            child: Center(
                              child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
                            ),
                          )
                        : _buildCurrentStepBody(),
                  ),
                ),
              ),
            ),

            // 4. Bottom Sticky Action Navigation Bar
            Container(
              color: Colors.white,
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: _buildBottomActionBar(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Header Bar matching exact layout and My Presets button
  Widget _buildTopHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A), size: 22),
                onPressed: () {
                  if (_currentStep > 0) {
                    setState(() => _currentStep--);
                  } else {
                    if (widget.onClose != null) {
                      widget.onClose!();
                    } else if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  }
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'Custom Practice',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 1),
                    Text(
                      'Build your personalized practice',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _showPresetsDialog,
                icon: const Icon(Icons.bookmark_border_rounded, size: 15, color: Color(0xFF4F46E5)),
                label: const Text(
                  'My Presets',
                  style: TextStyle(
                    color: Color(0xFF4F46E5),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  side: const BorderSide(color: Color(0xFFC7D2FE), width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  backgroundColor: const Color(0xFFF5F3FF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 4-Step Stepper Header matching exact screenshot design & proportions
  Widget _buildStepIndicator() {
    final steps = [
      {'number': 1, 'title': 'Exam &\nSubjects'},
      {'number': 2, 'title': 'Chapters &\nTopics'},
      {'number': 3, 'title': 'Practice\nSettings'},
      {'number': 4, 'title': 'Overview'},
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Row(
            children: List.generate(steps.length, (index) {
          final isCurrent = _currentStep == index;
          final isCompleted = _currentStep > index;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Line before circle
                          if (index > 0)
                            Expanded(
                              child: Container(
                                height: 2,
                                color: isCompleted || isCurrent
                                    ? (index == 1 ? const Color(0xFF22C55E) : const Color(0xFF4F46E5))
                                    : const Color(0xFFE2E8F0),
                              ),
                            )
                          else
                            const Spacer(),

                          // Circle node
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCompleted
                                  ? const Color(0xFF22C55E)
                                  : (isCurrent
                                      ? const Color(0xFF4F46E5)
                                      : const Color(0xFFF1F5F9)),
                              border: Border.all(
                                color: isCompleted
                                    ? const Color(0xFF22C55E)
                                    : (isCurrent
                                        ? const Color(0xFF4F46E5)
                                        : const Color(0xFFE2E8F0)),
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: isCompleted
                                  ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                                  : Text(
                                      '${steps[index]['number']}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isCurrent ? Colors.white : const Color(0xFF64748B),
                                      ),
                                    ),
                            ),
                          ),

                          // Line after circle
                          if (index < steps.length - 1)
                            Expanded(
                              child: Container(
                                height: 2,
                                color: isCompleted
                                    ? const Color(0xFF4F46E5)
                                    : (isCurrent && index == 0 ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0)),
                              ),
                            )
                          else
                            const Spacer(),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        steps[index]['title'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.2,
                          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                          color: isCurrent ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    ),
  ),
);
  }

  // Switch between 4 Screens
  Widget _buildCurrentStepBody() {
    switch (_currentStep) {
      case 0:
        return _buildScreen1ExamAndSubjects();
      case 1:
        return _buildScreen2ChaptersAndTopics();
      case 2:
        return _buildScreen3PracticeSettings();
      case 3:
        return _buildScreen4Overview();
      default:
        return const SizedBox.shrink();
    }
  }

  // ==========================================
  // SCREEN 1: EXAM & SUBJECTS (Exact Replica)
  // ==========================================
  Widget _buildScreen1ExamAndSubjects() {
    final allSelected = _availableSubjects.isNotEmpty && _selectedSubjectIds.length == _availableSubjects.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Subheader step text
        const Text(
          'Step 1 of 4',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Select Exam & Subjects',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Choose the exam you\'re preparing for and select the subjects you want to practice.',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),

        // Section 1: Select Exam
        const Text(
          'Select Exam',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 14),

        // 2 Exam Cards Side by Side
        Row(
          children: [
            // NEET Card
            Expanded(
              child: _buildExamCard(
                title: 'NEET',
                isSelected: _selectedExam == 'NEET',
                iconBgColor: const Color(0xFFEEF2FF),
                iconWidget: CustomPaint(
                  size: const Size(26, 26),
                  painter: StethoscopeIconPainter(color: const Color(0xFF4F46E5)),
                ),
                onTap: () {
                  setState(() => _selectedExam = 'NEET');
                  _loadSubjects();
                },
              ),
            ),
            const SizedBox(width: 14),
            // JEE Card
            Expanded(
              child: _buildExamCard(
                title: 'JEE',
                isSelected: _selectedExam == 'JEE',
                iconBgColor: const Color(0xFFE6F4EA),
                iconWidget: CustomPaint(
                  size: const Size(26, 26),
                  painter: DraftingCompassPainter(color: const Color(0xFF16A34A)),
                ),
                onTap: () {
                  setState(() => _selectedExam = 'JEE');
                  _loadSubjects();
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 28),

        // Section 2: Select Subjects
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Select Subjects',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            GestureDetector(
              onTap: _selectAllSubjects,
              child: Text(
                allSelected ? 'Deselect All' : 'Select All',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4F46E5),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Choose one or more subjects',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 14),

        // Subject Cards List
        if (_availableSubjects.isEmpty)
          // Fallback static list matching screenshot if database is initializing
          Column(
            children: [
              _buildSubjectCard(
                id: 'phy',
                name: 'Physics',
                desc: 'Explore concepts of matter, energy and motion',
                iconBgColor: const Color(0xFFEEF2FF),
                iconWidget: CustomPaint(
                  size: const Size(24, 24),
                  painter: AtomIconPainter(color: const Color(0xFF6366F1)),
                ),
                isSelected: true,
                onChanged: (v) {},
              ),
              const SizedBox(height: 12),
              _buildSubjectCard(
                id: 'chem',
                name: 'Chemistry',
                desc: 'Structure of matter and chemical reactions',
                iconBgColor: const Color(0xFFE0F2FE),
                iconWidget: CustomPaint(
                  size: const Size(24, 24),
                  painter: FlaskIconPainter(color: const Color(0xFF0284C7)),
                ),
                isSelected: true,
                onChanged: (v) {},
              ),
              const SizedBox(height: 12),
              _buildSubjectCard(
                id: 'bio',
                name: 'Biology',
                desc: 'Living organisms and life processes',
                iconBgColor: const Color(0xFFDCFCE7),
                iconWidget: CustomPaint(
                  size: const Size(24, 24),
                  painter: LeafIconPainter(color: const Color(0xFF16A34A)),
                ),
                isSelected: true,
                onChanged: (v) {},
              ),
            ],
          )
        else
          Column(
            children: _availableSubjects.map((sub) {
              final isSelected = _selectedSubjectIds.contains(sub.id);

              Color iconBg = const Color(0xFFEEF2FF);
              Widget painterWidget = CustomPaint(
                size: const Size(24, 24),
                painter: AtomIconPainter(color: const Color(0xFF6366F1)),
              );
              String desc = 'Explore subject concepts and topics';

              if (sub.name.toLowerCase().contains('physics')) {
                iconBg = const Color(0xFFEEF2FF);
                painterWidget = CustomPaint(
                  size: const Size(24, 24),
                  painter: AtomIconPainter(color: const Color(0xFF6366F1)),
                );
                desc = 'Explore concepts of matter, energy and motion';
              } else if (sub.name.toLowerCase().contains('chem')) {
                iconBg = const Color(0xFFE0F2FE);
                painterWidget = CustomPaint(
                  size: const Size(24, 24),
                  painter: FlaskIconPainter(color: const Color(0xFF0284C7)),
                );
                desc = 'Structure of matter and chemical reactions';
              } else if (sub.name.toLowerCase().contains('bio')) {
                iconBg = const Color(0xFFDCFCE7);
                painterWidget = CustomPaint(
                  size: const Size(24, 24),
                  painter: LeafIconPainter(color: const Color(0xFF16A34A)),
                );
                desc = 'Living organisms and life processes';
              } else if (sub.name.toLowerCase().contains('math')) {
                iconBg = const Color(0xFFFEF3C7);
                painterWidget = const Icon(Icons.functions_rounded, color: Color(0xFFD97706), size: 24);
                desc = 'Algebra, calculus, geometry and vectors';
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _buildSubjectCard(
                  id: sub.id,
                  name: sub.name,
                  desc: desc,
                  iconBgColor: iconBg,
                  iconWidget: painterWidget,
                  isSelected: isSelected,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedSubjectIds.add(sub.id);
                      } else {
                        _selectedSubjectIds.remove(sub.id);
                      }
                    });
                    _loadChapters();
                  },
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  // Exam Selection Card matching exact layout & proportions
  Widget _buildExamCard({
    required String title,
    required bool isSelected,
    required Color iconBgColor,
    required Widget iconWidget,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF5F3FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.02),
              blurRadius: 8,
              offset: Offset(0, 2),
            )
          ],
        ),
        child: Stack(
          children: [
            // Top Right Check Badge if selected
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4F46E5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 14, color: Colors.white),
                ),
              ),

            // Card Content Center
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: iconWidget),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Subject Item Card Widget
  Widget _buildSubjectCard({
    required String id,
    required String name,
    required String desc,
    required Color iconBgColor,
    required Widget iconWidget,
    required bool isSelected,
    required ValueChanged<bool?> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!isSelected),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.02),
              blurRadius: 8,
              offset: Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            // Circular Left Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Center(child: iconWidget),
            ),
            const SizedBox(width: 14),

            // Title & Description Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Purple Rounded Square Checkbox
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF4F46E5) : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // SCREEN 2: CHAPTERS & TOPICS SELECTION (Exact Replica)
  // ==========================================
  Widget _buildScreen2ChaptersAndTopics() {
    final chaptersList = ['Mechanics', 'Thermodynamics', 'Electromagnetism', 'Optics'];
    final extraChaptersList = ['Waves & Oscillations', 'Modern Physics', 'Fluid Mechanics', 'Electrostatics'];

    final topicsList = ['Laws of Motion', 'Work, Energy & Power', 'Rotational Motion', 'Gravitation'];
    final extraTopicsList = ['Friction & Circular Motion', 'Center of Mass & Collisions', 'Kepler\'s Laws', 'Simple Harmonic Motion'];

    final allChapters = [...chaptersList, if (_showMoreChapters) ...extraChaptersList];
    final allTopics = [...topicsList, if (_showMoreTopics) ...extraTopicsList];

    final allChaptersSelected = allChapters.every((ch) => _selectedChapterNames.contains(ch));
    final allTopicsSelected = allTopics.every((tp) => _selectedTopicNames.contains(tp));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 2 of 4',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Select Chapters & Topics',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Choose the chapters and topics you want to include in your practice.',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),

        // Section 1: Select Chapters Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Select Chapters',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  if (allChaptersSelected) {
                    _selectedChapterNames.clear();
                  } else {
                    _selectedChapterNames.addAll(allChapters);
                  }
                });
              },
              child: const Text(
                'Select All',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4F46E5),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Main Chapter Cards
        ...chaptersList.map((chName) => _buildChapterCard(
              name: chName,
              isSelected: _selectedChapterNames.contains(chName),
              onTap: (selected) {
                setState(() {
                  if (selected) {
                    _selectedChapterNames.add(chName);
                  } else {
                    _selectedChapterNames.remove(chName);
                  }
                });
              },
            )),

        // Extra Chapters if expanded
        if (_showMoreChapters)
          ...extraChaptersList.map((chName) => _buildChapterCard(
                name: chName,
                isSelected: _selectedChapterNames.contains(chName),
                onTap: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedChapterNames.add(chName);
                    } else {
                      _selectedChapterNames.remove(chName);
                    }
                  });
                },
              )),

        // Expandable "+ Add more chapters" Card
        _buildExpandableAddCard(
          title: 'Add more chapters',
          isExpanded: _showMoreChapters,
          onTap: () => setState(() => _showMoreChapters = !_showMoreChapters),
        ),

        const SizedBox(height: 28),

        // Section 2: Select Topics Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Select Topics',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  if (allTopicsSelected) {
                    _selectedTopicNames.clear();
                  } else {
                    _selectedTopicNames.addAll(allTopics);
                  }
                });
              },
              child: const Text(
                'Select All',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4F46E5),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Main Topic Cards
        ...topicsList.map((tpName) => _buildTopicCard(
              name: tpName,
              isSelected: _selectedTopicNames.contains(tpName),
              onTap: (selected) {
                setState(() {
                  if (selected) {
                    _selectedTopicNames.add(tpName);
                  } else {
                    _selectedTopicNames.remove(tpName);
                  }
                });
              },
            )),

        // Extra Topics if expanded
        if (_showMoreTopics)
          ...extraTopicsList.map((tpName) => _buildTopicCard(
                name: tpName,
                isSelected: _selectedTopicNames.contains(tpName),
                onTap: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTopicNames.add(tpName);
                    } else {
                      _selectedTopicNames.remove(tpName);
                    }
                  });
                },
              )),

        // Expandable "+ Add more topics" Card
        _buildExpandableAddCard(
          title: 'Add more topics',
          isExpanded: _showMoreTopics,
          onTap: () => setState(() => _showMoreTopics = !_showMoreTopics),
        ),
      ],
    );
  }

  // Chapter Card Widget with vertical purple accent line on left
  Widget _buildChapterCard({
    required String name,
    required bool isSelected,
    required ValueChanged<bool> onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.02),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => onTap(!isSelected),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Left Vertical Accent Bar
              Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 14),

              // Chapter Title
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
              ),

              // Right Purple Checkbox
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF4F46E5) : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1),
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Topic Card Widget with right chevron icon on left
  Widget _buildTopicCard({
    required String name,
    required bool isSelected,
    required ValueChanged<bool> onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.02),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => onTap(!isSelected),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Left Chevron Right Icon
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF4F46E5),
                size: 22,
              ),
              const SizedBox(width: 10),

              // Topic Title
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
              ),

              // Right Purple Checkbox
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF4F46E5) : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1),
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Expandable Add More Card Widget
  Widget _buildExpandableAddCard({
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.02),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Icon(
                Icons.add_rounded,
                size: 18,
                color: Color(0xFF475569),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              Icon(
                isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                size: 22,
                color: const Color(0xFF64748B),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SCREEN 3: PRACTICE SETTINGS
  // ==========================================
  Widget _buildScreen3PracticeSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Step 3 of 4', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF64748B))),
        const SizedBox(height: 4),
        const Text('Practice Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
        const SizedBox(height: 6),
        const Text('Customize question sources, difficulty level, question quantity and timer.', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
        const SizedBox(height: 24),

        // 1. Question Source
        const Text('Question Source', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['Mixed', 'PYQ (Previous Years)', 'NTA Question Bank', 'NCERT Exemplar']
              .map((src) => ChoiceChip(
                    label: Text(src),
                    selected: _selectedSource == src,
                    selectedColor: const Color(0xFFEEF2FF),
                    labelStyle: TextStyle(
                      color: _selectedSource == src ? const Color(0xFF4F46E5) : const Color(0xFF0F172A),
                      fontWeight: _selectedSource == src ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (v) => setState(() => _selectedSource = src),
                  ))
              .toList(),
        ),

        const SizedBox(height: 24),

        // 2. Difficulty Level
        const Text('Difficulty Level', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: ['Mixed', 'Easy', 'Medium', 'Hard']
              .map((diff) => ChoiceChip(
                    label: Text(diff),
                    selected: _selectedDifficulty == diff,
                    selectedColor: const Color(0xFFEEF2FF),
                    labelStyle: TextStyle(
                      color: _selectedDifficulty == diff ? const Color(0xFF4F46E5) : const Color(0xFF0F172A),
                      fontWeight: _selectedDifficulty == diff ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (v) => setState(() => _selectedDifficulty = diff),
                  ))
              .toList(),
        ),

        const SizedBox(height: 24),

        // 3. Question Quantity
        const Text('Number of Questions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: [5, 10, 15, 20, 25, 30]
              .map((cnt) => ChoiceChip(
                    label: Text('$cnt Questions'),
                    selected: _questionCount == cnt,
                    selectedColor: const Color(0xFFEEF2FF),
                    labelStyle: TextStyle(
                      color: _questionCount == cnt ? const Color(0xFF4F46E5) : const Color(0xFF0F172A),
                      fontWeight: _questionCount == cnt ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (v) => setState(() => _questionCount = cnt),
                  ))
              .toList(),
        ),

        const SizedBox(height: 24),

        // 4. Timer Limit
        const Text('Time Limit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: [0, 10, 15, 30, 45, 60]
              .map((mins) => ChoiceChip(
                    label: Text(mins == 0 ? 'No Timer' : '$mins Mins'),
                    selected: _timerMinutes == mins,
                    selectedColor: const Color(0xFFEEF2FF),
                    labelStyle: TextStyle(
                      color: _timerMinutes == mins ? const Color(0xFF4F46E5) : const Color(0xFF0F172A),
                      fontWeight: _timerMinutes == mins ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (v) => setState(() => _timerMinutes = mins),
                  ))
              .toList(),
        ),
      ],
    );
  }

  // ==========================================
  // SCREEN 4: OVERVIEW & START SESSION
  // ==========================================
  Widget _buildScreen4Overview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Step 4 of 4', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF64748B))),
        const SizedBox(height: 4),
        const Text('Overview & Summary', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
        const SizedBox(height: 6),
        const Text('Review your practice configurations before generating questions.', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
        const SizedBox(height: 20),

        // Summary Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.03), blurRadius: 10, offset: Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Practice Session Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Chip(
                    label: Text(_selectedExam, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    backgroundColor: const Color(0xFF4F46E5),
                  ),
                ],
              ),
              const Divider(height: 24),

              _buildSummaryRow('Target Exam:', _selectedExam),
              _buildSummaryRow(
                'Subjects:',
                _selectedSubjectIds.isEmpty
                    ? 'All Subjects'
                    : _availableSubjects
                        .where((s) => _selectedSubjectIds.contains(s.id))
                        .map((s) => s.name)
                        .join(', '),
              ),
              _buildSummaryRow('Chapters:', '${_selectedChapterIds.length} Chapters Selected'),
              _buildSummaryRow('Source:', _selectedSource),
              _buildSummaryRow('Difficulty:', _selectedDifficulty),
              _buildSummaryRow('Question Count:', '$_questionCount Questions'),
              _buildSummaryRow('Duration:', _timerMinutes == 0 ? 'Unlimited (No Timer)' : '$_timerMinutes Minutes'),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Preset Save Container
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.save_outlined, color: Color(0xFF4F46E5)),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Save this practice setup as a preset for quick access later.', style: TextStyle(fontSize: 13)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEEF2FF),
                  foregroundColor: const Color(0xFF4F46E5),
                  elevation: 0,
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Configuration saved to My Presets! 🎉')),
                  );
                },
                child: const Text('Save Preset'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 14)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF0F172A))),
          ),
        ],
      ),
    );
  }

  // Bottom Navigation Bar with primary purple button & proportions matching screenshot
  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              flex: 3,
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep--),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFFC7D2FE), width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  backgroundColor: Colors.white,
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],

          Expanded(
            flex: _currentStep > 0 ? 7 : 10,
            child: ElevatedButton(
              onPressed: () {
                if (_currentStep < 3) {
                  setState(() => _currentStep++);
                } else {
                  _handleStartSession();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _currentStep == 3 ? 'Start Practice 🚀' : 'Continue',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  if (_currentStep < 3) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// CUSTOM PAINTERS FOR ICON REPLICATION
// ==========================================

// 1. Stethoscope Icon Painter for NEET Exam Card
class StethoscopeIconPainter extends CustomPainter {
  final Color color;
  StethoscopeIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // U-shaped main stethoscope tube
    final path = Path();
    path.moveTo(w * 0.28, h * 0.22);
    path.lineTo(w * 0.28, h * 0.38);
    path.cubicTo(w * 0.28, h * 0.62, w * 0.72, h * 0.62, w * 0.72, h * 0.38);
    path.lineTo(w * 0.72, h * 0.22);

    // Cable down to diaphragm
    path.moveTo(w * 0.5, h * 0.56);
    path.cubicTo(w * 0.5, h * 0.76, w * 0.35, h * 0.82, w * 0.35, h * 0.72);

    canvas.drawPath(path, paint);

    // Earpiece tips
    canvas.drawCircle(Offset(w * 0.28, h * 0.22), 2.5, Paint()..color = color..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(w * 0.72, h * 0.22), 2.5, Paint()..color = color..style = PaintingStyle.fill);

    // Chestpiece diaphragm
    final center = Offset(w * 0.35, h * 0.72);
    canvas.drawCircle(center, w * 0.12, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2.4);
    canvas.drawCircle(center, w * 0.05, Paint()..color = color..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 2. Drafting Compass Painter for JEE Exam Card
class DraftingCompassPainter extends CustomPainter {
  final Color color;
  DraftingCompassPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Top hinge knob
    canvas.drawCircle(Offset(w * 0.5, h * 0.2), 3.0, Paint()..color = color..style = PaintingStyle.fill);

    final path = Path();
    // Left leg
    path.moveTo(w * 0.5, h * 0.2);
    path.lineTo(w * 0.28, h * 0.82);

    // Right leg
    path.moveTo(w * 0.5, h * 0.2);
    path.lineTo(w * 0.72, h * 0.82);

    // Horizontal bar
    path.moveTo(w * 0.36, h * 0.55);
    path.lineTo(w * 0.64, h * 0.55);

    canvas.drawPath(path, paint);

    // Adjusting wheel center
    canvas.drawCircle(Offset(w * 0.5, h * 0.55), 2.2, Paint()..color = color..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 3. Atom Structure Painter for Physics Subject
class AtomIconPainter extends CustomPainter {
  final Color color;
  AtomIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final center = Offset(size.width / 2, size.height / 2);
    final rx = size.width * 0.42;
    final ry = size.height * 0.16;

    // Nucleus
    canvas.drawCircle(center, 3.5, Paint()..color = color..style = PaintingStyle.fill);

    // 3 Rotated Orbits
    for (int i = 0; i < 3; i++) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(i * (3.14159265359 / 3));
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 4. Flask Beaker Painter for Chemistry Subject
class FlaskIconPainter extends CustomPainter {
  final Color color;
  FlaskIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    final path = Path();
    path.moveTo(w * 0.38, h * 0.18);
    path.lineTo(w * 0.62, h * 0.18); // top lip
    path.moveTo(w * 0.42, h * 0.18);
    path.lineTo(w * 0.42, h * 0.42); // left neck
    path.lineTo(w * 0.2, h * 0.82);  // left body
    path.lineTo(w * 0.8, h * 0.82);  // bottom
    path.lineTo(w * 0.58, h * 0.42); // right body
    path.lineTo(w * 0.58, h * 0.18); // right neck

    canvas.drawPath(path, paint);

    // Liquid line inside
    final liquidPath = Path();
    liquidPath.moveTo(w * 0.27, h * 0.68);
    liquidPath.quadraticBezierTo(w * 0.5, h * 0.64, w * 0.73, h * 0.68);
    canvas.drawPath(liquidPath, paint..strokeWidth = 1.8);

    // Bubbles
    canvas.drawCircle(Offset(w * 0.46, h * 0.55), 1.8, Paint()..color = color..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(w * 0.54, h * 0.48), 1.4, Paint()..color = color..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 5. Leaf Sprout Painter for Biology Subject
class LeafIconPainter extends CustomPainter {
  final Color color;
  LeafIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Stem
    final stemPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(w * 0.5, h * 0.85), Offset(w * 0.5, h * 0.25), stemPaint);

    // Top Leaf
    final topLeaf = Path();
    topLeaf.moveTo(w * 0.5, h * 0.15);
    topLeaf.quadraticBezierTo(w * 0.32, h * 0.28, w * 0.5, h * 0.48);
    topLeaf.quadraticBezierTo(w * 0.68, h * 0.28, w * 0.5, h * 0.15);
    canvas.drawPath(topLeaf, paint);

    // Left Leaf
    final leftLeaf = Path();
    leftLeaf.moveTo(w * 0.5, h * 0.55);
    leftLeaf.quadraticBezierTo(w * 0.2, h * 0.45, w * 0.22, h * 0.65);
    leftLeaf.quadraticBezierTo(w * 0.4, h * 0.72, w * 0.5, h * 0.55);
    canvas.drawPath(leftLeaf, paint);

    // Right Leaf
    final rightLeaf = Path();
    rightLeaf.moveTo(w * 0.5, h * 0.42);
    rightLeaf.quadraticBezierTo(w * 0.8, h * 0.32, w * 0.78, h * 0.52);
    rightLeaf.quadraticBezierTo(w * 0.6, h * 0.59, w * 0.5, h * 0.42);
    canvas.drawPath(rightLeaf, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
