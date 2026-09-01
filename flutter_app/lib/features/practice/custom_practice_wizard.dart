import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../core/services/supabase_service.dart';

class CustomPracticeWizardModal extends StatefulWidget {
  final String initialExam;
  final VoidCallback? onClose;
  final Function(List<QuestionModel> questions, int timerMinutes) onStartPractice;
  final PracticeTestMode mode;

  const CustomPracticeWizardModal({
    super.key,
    required this.initialExam,
    this.onClose,
    required this.onStartPractice,
    this.mode = PracticeTestMode.practice,
  });

  @override
  State<CustomPracticeWizardModal> createState() => _CustomPracticeWizardModalState();
}

class _CustomPracticeWizardModalState extends State<CustomPracticeWizardModal> {
  int _currentStep = 1; // 0: Exam & Subjects, 1: Chapters & Topics, 2: Practice Settings, 3: Overview
  late String _selectedExam;

  List<SubjectModel> _availableSubjects = [];
  final Set<String> _selectedSubjectIds = {};

  final Set<String> _selectedChapterIds = {};

  // Screen 2 specific selection states matching exact screenshot
  final TextEditingController _chapterSearchController = TextEditingController();
  String _chapterSearchQuery = '';
  final Set<int> _expandedChapterIndices = {1}; // Chapter 1 expanded by default
  final Set<String> _selectedSubjectTabs = {'Physics', 'Chemistry', 'Biology'};
  String _activeSubjectTab = 'Physics';

  final Map<String, List<Map<String, dynamic>>> _subjectChaptersMap = {
    'Physics': [
      {
        'number': 1,
        'name': 'Physical World and Measurement',
        'topicsCountText': '6 Topics Selected',
        'isSelected': true,
        'subtopics': [
          {'id': '1.1', 'name': 'Units and Measurements', 'isSelected': true},
          {'id': '1.2', 'name': 'Dimensional Analysis', 'isSelected': true},
          {'id': '1.3', 'name': 'Error Analysis', 'isSelected': true},
          {'id': '1.4', 'name': 'Significant Figures', 'isSelected': false},
          {'id': '1.5', 'name': 'Vector and Scalars', 'isSelected': true},
          {'id': '1.6', 'name': 'Measurement of Physical Quantities', 'isSelected': false},
        ],
      },
      {
        'number': 2,
        'name': 'Kinematics',
        'topicsCountText': '8 Topics Selected',
        'isSelected': true,
        'subtopics': <Map<String, dynamic>>[
          {'id': '2.1', 'name': 'Motion in a Straight Line', 'isSelected': true},
          {'id': '2.2', 'name': 'Motion in a Plane', 'isSelected': true},
        ],
      },
      {
        'number': 3,
        'name': 'Laws of Motion',
        'topicsCountText': '7 Topics Selected',
        'isSelected': true,
        'subtopics': <Map<String, dynamic>>[
          {'id': '3.1', 'name': 'Newton\'s First Law', 'isSelected': true},
          {'id': '3.2', 'name': 'Momentum and Impulse', 'isSelected': true},
        ],
      },
      {
        'number': 4,
        'name': 'Work, Energy and Power',
        'topicsCountText': '3 Topics Selected',
        'isSelected': false,
        'subtopics': <Map<String, dynamic>>[
          {'id': '4.1', 'name': 'Work Done by Constant Force', 'isSelected': false},
          {'id': '4.2', 'name': 'Kinetic and Potential Energy', 'isSelected': false},
        ],
      },
      {
        'number': 5,
        'name': 'Motion of System of Particles',
        'topicsCountText': '0 Topic Selected',
        'isSelected': false,
        'subtopics': <Map<String, dynamic>>[
          {'id': '5.1', 'name': 'Center of Mass', 'isSelected': false},
          {'id': '5.2', 'name': 'Rigid Body Rotation', 'isSelected': false},
        ],
      },
    ],
    'Chemistry': [
      {
        'number': 1,
        'name': 'Some Basic Concepts of Chemistry',
        'topicsCountText': '5 Topics Selected',
        'isSelected': true,
        'subtopics': [
          {'id': '1.1', 'name': 'Mole Concept & Atomic Mass', 'isSelected': true},
          {'id': '1.2', 'name': 'Stoichiometry & Yield', 'isSelected': true},
          {'id': '1.3', 'name': 'Molarity & Molality', 'isSelected': true},
          {'id': '1.4', 'name': 'Empirical & Molecular Formula', 'isSelected': true},
          {'id': '1.5', 'name': 'Laws of Chemical Combination', 'isSelected': true},
        ],
      },
      {
        'number': 2,
        'name': 'Structure of Atom',
        'topicsCountText': '4 Topics Selected',
        'isSelected': true,
        'subtopics': [
          {'id': '2.1', 'name': 'Bohr\'s Model of Hydrogen Atom', 'isSelected': true},
          {'id': '2.2', 'name': 'Quantum Numbers & Orbital Filling', 'isSelected': true},
          {'id': '2.3', 'name': 'de Broglie Wavelength & Photoelectric', 'isSelected': true},
          {'id': '2.4', 'name': 'Heisenberg Uncertainty Principle', 'isSelected': true},
        ],
      },
      {
        'number': 3,
        'name': 'Chemical Bonding & Molecular Structure',
        'topicsCountText': '6 Topics Selected',
        'isSelected': true,
        'subtopics': [
          {'id': '3.1', 'name': 'Ionic and Covalent Bond', 'isSelected': true},
          {'id': '3.2', 'name': 'VSEPR Theory & Molecular Shapes', 'isSelected': true},
          {'id': '3.3', 'name': 'Hybridization (sp, sp2, sp3)', 'isSelected': true},
          {'id': '3.4', 'name': 'Molecular Orbital Theory (MOT)', 'isSelected': true},
        ],
      },
      {
        'number': 4,
        'name': 'Chemical Thermodynamics',
        'topicsCountText': '3 Topics Selected',
        'isSelected': false,
        'subtopics': [
          {'id': '4.1', 'name': 'First Law & Enthalpy of Reaction', 'isSelected': false},
          {'id': '4.2', 'name': 'Hess\'s Law & Bond Energies', 'isSelected': false},
          {'id': '4.3', 'name': 'Entropy & Gibbs Free Energy', 'isSelected': false},
        ],
      },
      {
        'number': 5,
        'name': 'Equilibrium',
        'topicsCountText': '0 Topic Selected',
        'isSelected': false,
        'subtopics': [
          {'id': '5.1', 'name': 'Chemical Equilibrium & Kc/Kp', 'isSelected': false},
          {'id': '5.2', 'name': 'Ionic Equilibrium & pH Scale', 'isSelected': false},
          {'id': '5.3', 'name': 'Solubility Product (Ksp)', 'isSelected': false},
        ],
      },
    ],
    'Biology': [
      {
        'number': 1,
        'name': 'The Living World',
        'topicsCountText': '4 Topics Selected',
        'isSelected': true,
        'subtopics': [
          {'id': '1.1', 'name': 'What is Living? Biodiversity', 'isSelected': true},
          {'id': '1.2', 'name': 'Taxonomic Categories & Hierarchy', 'isSelected': true},
          {'id': '1.3', 'name': 'Binomial Nomenclature Rules', 'isSelected': true},
          {'id': '1.4', 'name': 'Taxonomical Aids & Herbaria', 'isSelected': true},
        ],
      },
      {
        'number': 2,
        'name': 'Biological Classification',
        'topicsCountText': '5 Topics Selected',
        'isSelected': true,
        'subtopics': [
          {'id': '2.1', 'name': 'Five Kingdom System Overview', 'isSelected': true},
          {'id': '2.2', 'name': 'Kingdom Monera & Archaebacteria', 'isSelected': true},
          {'id': '2.3', 'name': 'Kingdom Protista & Fungi', 'isSelected': true},
          {'id': '2.4', 'name': 'Viruses, Viroids & Lichens', 'isSelected': true},
        ],
      },
      {
        'number': 3,
        'name': 'Plant Kingdom',
        'topicsCountText': '6 Topics Selected',
        'isSelected': true,
        'subtopics': [
          {'id': '3.1', 'name': 'Algae, Bryophytes & Pteridophytes', 'isSelected': true},
          {'id': '3.2', 'name': 'Gymnosperms & Angiosperms', 'isSelected': true},
          {'id': '3.3', 'name': 'Plant Life Cycles & Alternation', 'isSelected': true},
        ],
      },
      {
        'number': 4,
        'name': 'Animal Kingdom',
        'topicsCountText': '2 Topics Selected',
        'isSelected': false,
        'subtopics': [
          {'id': '4.1', 'name': 'Basis of Classification (Symmetry, Coelom)', 'isSelected': false},
          {'id': '4.2', 'name': 'Non-Chordates & Chordates Overview', 'isSelected': false},
        ],
      },
      {
        'number': 5,
        'name': 'Cell: The Unit of Life',
        'topicsCountText': '0 Topic Selected',
        'isSelected': false,
        'subtopics': [
          {'id': '5.1', 'name': 'Prokaryotic vs Eukaryotic Cell Structure', 'isSelected': false},
          {'id': '5.2', 'name': 'Organelles: Endomembrane & Plastids', 'isSelected': false},
        ],
      },
    ],
    'Mathematics': [
      {
        'number': 1,
        'name': 'Sets, Relations and Functions',
        'topicsCountText': '5 Topics Selected',
        'isSelected': true,
        'subtopics': [
          {'id': '1.1', 'name': 'Sets & Venn Diagrams', 'isSelected': true},
          {'id': '1.2', 'name': 'Types of Relations & Equivalence', 'isSelected': true},
          {'id': '1.3', 'name': 'Domain, Range & One-One/Onto', 'isSelected': true},
          {'id': '1.4', 'name': 'Composite & Inverse Functions', 'isSelected': true},
        ],
      },
      {
        'number': 2,
        'name': 'Complex Numbers & Quadratic Equations',
        'topicsCountText': '6 Topics Selected',
        'isSelected': true,
        'subtopics': [
          {'id': '2.1', 'name': 'Modulus, Argument & Polar Form', 'isSelected': true},
          {'id': '2.2', 'name': 'Roots of Quadratic Equations & Discriminant', 'isSelected': true},
          {'id': '2.3', 'name': 'De Moivre\'s Theorem & Cube Roots', 'isSelected': true},
        ],
      },
      {
        'number': 3,
        'name': 'Matrices and Determinants',
        'topicsCountText': '7 Topics Selected',
        'isSelected': true,
        'subtopics': [
          {'id': '3.1', 'name': 'Matrix Algebra & Types', 'isSelected': true},
          {'id': '3.2', 'name': 'Determinants & Properties', 'isSelected': true},
          {'id': '3.3', 'name': 'Inverse of Matrix & Cramer\'s Rule', 'isSelected': true},
        ],
      },
      {
        'number': 4,
        'name': 'Permutations and Combinations',
        'topicsCountText': '3 Topics Selected',
        'isSelected': false,
        'subtopics': [
          {'id': '4.1', 'name': 'Fundamental Principle of Counting', 'isSelected': false},
          {'id': '4.2', 'name': 'Permutations & Combinations Formulas', 'isSelected': false},
        ],
      },
      {
        'number': 5,
        'name': 'Differential Calculus',
        'topicsCountText': '0 Topic Selected',
        'isSelected': false,
        'subtopics': [
          {'id': '5.1', 'name': 'Limits, Continuity & Differentiability', 'isSelected': false},
          {'id': '5.2', 'name': 'Derivatives & Chain Rule', 'isSelected': false},
        ],
      },
    ],
  };

  final Set<String> _selectedChapterNames = {'Mechanics', 'Thermodynamics', 'Optics'};
  final Set<String> _selectedTopicNames = {'Laws of Motion', 'Work, Energy & Power', 'Gravitation'};

  final Set<String> _selectedSources = {'PYQ', 'NTA', 'Practice'};
  String _selectedSource = 'PYQ';
  String _selectedDifficulty = 'Medium';
  int _questionCount = 20;
  int _timerMinutes = 30;
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
    _syncSubjectTabsForExam(_selectedExam);
    _loadSubjects();
  }

  void _syncSubjectTabsForExam(String exam) {
    _selectedSubjectTabs.clear();
    if (exam.toUpperCase().contains('JEE')) {
      _selectedSubjectTabs.addAll(['Physics', 'Chemistry', 'Mathematics']);
    } else {
      _selectedSubjectTabs.addAll(['Physics', 'Chemistry', 'Biology']);
    }
    _activeSubjectTab = 'Physics';
  }

  void _selectExam(String exam) {
    setState(() {
      _selectedExam = exam;
      _syncSubjectTabsForExam(exam);
    });
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
    final examCode = _selectedExam.contains('JEE') ? 'JEE Main' : 'NEET';
    final subjects = _selectedExam.contains('JEE') ? ['Physics', 'Chemistry', 'Mathematics'] : ['Physics', 'Chemistry', 'Biology'];

    final Map<String, List<Map<String, dynamic>>> dynamicMap = {};

    for (var sub in subjects) {
      final rawChapters = await SupabaseService.fetchTaxonomyForSubject(
        exam: examCode,
        subject: sub,
        forceRefresh: true,
        includeInactive: false,
      );

      final formattedList = rawChapters.asMap().entries.map((entry) {
        final idx = entry.key;
        final c = entry.value;
        final rawTopics = (c['topicsList'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        final subtopics = rawTopics.map((t) {
          return {
            'id': t['id'] ?? '',
            'name': t['name'] ?? '',
            'isSelected': true,
          };
        }).toList();

        return {
          'id': c['id'] ?? '',
          'number': idx + 1,
          'name': c['name'] ?? '',
          'topicsCountText': '${subtopics.length} Topics Selected',
          'isSelected': true,
          'subtopics': subtopics,
        };
      }).toList();

      dynamicMap[sub] = formattedList;
    }

    if (mounted) {
      setState(() {
        _subjectChaptersMap.clear();
        _subjectChaptersMap.addAll(dynamicMap);
      });
    }
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
      if (questions.length < _questionCount) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notice: Only ${questions.length} questions are currently available for this selection. All ${questions.length} questions loaded.'),
            backgroundColor: const Color(0xFF4F46E5),
            duration: const Duration(seconds: 4),
          ),
        );
      }
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
                  children: [
                    Text(
                      widget.mode == PracticeTestMode.test ? 'Custom Test' : 'Custom Practice',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      widget.mode == PracticeTestMode.test
                          ? 'Configure your full-length evaluation test'
                          : 'Build your personalized practice',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
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
  // SCREEN 1: EXAMS & SUBJECTS SELECTION (Exact Replica)
  // ==========================================
  Widget _buildScreen1ExamAndSubjects() {
    final allSelected = _availableSubjects.isNotEmpty &&
        _selectedSubjectIds.length == _availableSubjects.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Subheader step text
        const Text(
          'Step 1 of 4',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'Select Exam & Subjects',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Choose the exam you\'re preparing for and select the subjects you want to practice.',
          style: TextStyle(
            fontSize: 13.5,
            color: Color(0xFF64748B),
            height: 1.35,
          ),
        ),
        const SizedBox(height: 18),

        // Section 1: Select Exam
        const Text(
          'Select Exam',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),

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
                  size: const Size(24, 24),
                  painter: StethoscopeIconPainter(color: const Color(0xFF4F46E5)),
                ),
                onTap: () => _selectExam('NEET'),
              ),
            ),
            const SizedBox(width: 12),
            // JEE Card
            Expanded(
              child: _buildExamCard(
                title: 'JEE',
                isSelected: _selectedExam == 'JEE',
                iconBgColor: const Color(0xFFE6F4EA),
                iconWidget: CustomPaint(
                  size: const Size(24, 24),
                  painter: DraftingCompassPainter(color: const Color(0xFF16A34A)),
                ),
                onTap: () => _selectExam('JEE'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 22),

        // Section 2: Select Subjects
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Select Subjects',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            GestureDetector(
              onTap: _selectAllSubjects,
              child: Text(
                allSelected ? 'Deselect All' : 'Select All',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4F46E5),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        const Text(
          'Choose one or more subjects',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 10),

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
                  size: const Size(22, 22),
                  painter: AtomIconPainter(color: const Color(0xFF6366F1)),
                ),
                isSelected: true,
                onChanged: (v) {},
              ),
              const SizedBox(height: 10),
              _buildSubjectCard(
                id: 'chem',
                name: 'Chemistry',
                desc: 'Structure of matter and chemical reactions',
                iconBgColor: const Color(0xFFE0F2FE),
                iconWidget: CustomPaint(
                  size: const Size(22, 22),
                  painter: FlaskIconPainter(color: const Color(0xFF0284C7)),
                ),
                isSelected: true,
                onChanged: (v) {},
              ),
              const SizedBox(height: 10),
              _buildSubjectCard(
                id: 'bio',
                name: 'Biology',
                desc: 'Living organisms and life processes',
                iconBgColor: const Color(0xFFDCFCE7),
                iconWidget: CustomPaint(
                  size: const Size(22, 22),
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
                size: const Size(22, 22),
                painter: AtomIconPainter(color: const Color(0xFF6366F1)),
              );
              String desc = 'Explore subject concepts and topics';

              if (sub.name.toLowerCase().contains('physics')) {
                iconBg = const Color(0xFFEEF2FF);
                painterWidget = CustomPaint(
                  size: const Size(22, 22),
                  painter: AtomIconPainter(color: const Color(0xFF6366F1)),
                );
                desc = 'Explore concepts of matter, energy and motion';
              } else if (sub.name.toLowerCase().contains('chem')) {
                iconBg = const Color(0xFFE0F2FE);
                painterWidget = CustomPaint(
                  size: const Size(22, 22),
                  painter: FlaskIconPainter(color: const Color(0xFF0284C7)),
                );
                desc = 'Structure of matter and chemical reactions';
              } else if (sub.name.toLowerCase().contains('bio')) {
                iconBg = const Color(0xFFDCFCE7);
                painterWidget = CustomPaint(
                  size: const Size(22, 22),
                  painter: LeafIconPainter(color: const Color(0xFF16A34A)),
                );
                desc = 'Living organisms and life processes';
              } else if (sub.name.toLowerCase().contains('math')) {
                iconBg = const Color(0xFFFEF3C7);
                painterWidget = const Icon(Icons.functions_rounded, color: Color(0xFFD97706), size: 22);
                desc = 'Algebra, calculus, geometry and vectors';
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
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
  // SCREEN 2: CHAPTERS & TOPICS SELECTION (Exact Replica & Dynamic PCM/PCB)
  // ==========================================
  Widget _buildScreen2ChaptersAndTopics() {
    final isJee = _selectedExam.toUpperCase().contains('JEE');
    final activeSubjects = isJee
        ? ['Physics', 'Chemistry', 'Mathematics']
        : ['Physics', 'Chemistry', 'Biology'];

    // Enforce correct subjects set for current exam (PCM for JEE, PCB for NEET)
    if (isJee && _selectedSubjectTabs.contains('Biology')) {
      _selectedSubjectTabs.remove('Biology');
      _selectedSubjectTabs.add('Mathematics');
    } else if (!isJee && _selectedSubjectTabs.contains('Mathematics')) {
      _selectedSubjectTabs.remove('Mathematics');
      _selectedSubjectTabs.add('Biology');
    }

    final allSubjectTabsSelected = activeSubjects.every((s) => _selectedSubjectTabs.contains(s));

    // Ensure active subject tab is valid and currently selected
    if (!_selectedSubjectTabs.contains(_activeSubjectTab)) {
      if (_selectedSubjectTabs.isNotEmpty) {
        _activeSubjectTab = _selectedSubjectTabs.first;
      } else {
        _activeSubjectTab = activeSubjects.first;
      }
    }

    final activeChaptersList = _subjectChaptersMap[_activeSubjectTab] ?? [];
    final allChaptersInActiveSubjectSelected = activeChaptersList.every((c) => c['isSelected'] == true);

    final filteredChapters = activeChaptersList.where((c) {
      if (_chapterSearchQuery.isEmpty) return true;
      final query = _chapterSearchQuery.toLowerCase();
      final nameMatches = (c['name'] as String).toLowerCase().contains(query);
      final subMatches = (c['subtopics'] as List).any((s) => (s['name'] as String).toLowerCase().contains(query));
      return nameMatches || subMatches;
    }).toList();

    String statsText = '68 Chapters • 182 Topics';
    if (_activeSubjectTab == 'Chemistry') statsText = '62 Chapters • 165 Topics';
    if (_activeSubjectTab == 'Biology') statsText = '89 Chapters • 240 Topics';
    if (_activeSubjectTab == 'Mathematics') statsText = '75 Chapters • 198 Topics';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Subheader step text
        const Text(
          'Step 2 of 4',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF635BFF),
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'Select Chapters & Topics',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E1B4B),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Choose the chapters and topics you want to include in your practice.',
          style: TextStyle(
            fontSize: 13.5,
            color: Color(0xFF64748B),
            height: 1.35,
          ),
        ),
        const SizedBox(height: 18),

        // Selected Exam Card Container
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.02),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selected Exam',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _selectedExam,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2A1B69),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentStep = 0; // Go back to exam selection screen
                  });
                },
                icon: const Icon(Icons.swap_horiz_rounded, size: 18, color: Color(0xFF5E46E4)),
                label: const Text(
                  'Change Exam',
                  style: TextStyle(
                    color: Color(0xFF5E46E4),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  side: const BorderSide(color: Color(0xFFD1D5DB), width: 1.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  backgroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Subjects Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Subjects',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E1B4B),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  if (allSubjectTabsSelected) {
                    _selectedSubjectTabs.clear();
                  } else {
                    _selectedSubjectTabs.addAll(activeSubjects);
                  }
                });
              },
              child: const Text(
                'Select All Subjects',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF5E46E4),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // 3 Subject Cards Side by Side (Physics, Chemistry, Biology/Mathematics)
        Row(
          children: [
            // Physics Card
            Expanded(
              child: _buildSubjectSelectCard(
                title: 'Physics',
                count: '68',
                bgColor: const Color(0xFFF5F3FF),
                borderColor: const Color(0xFFC7D2FE),
                iconAvatarColor: const Color(0xFFEEF2FF),
                iconWidget: CustomPaint(
                  size: const Size(20, 20),
                  painter: AtomIconPainter(color: const Color(0xFF6366F1)),
                ),
                isSelected: _selectedSubjectTabs.contains('Physics'),
                onTap: () {
                  setState(() {
                    if (_selectedSubjectTabs.contains('Physics')) {
                      _selectedSubjectTabs.remove('Physics');
                    } else {
                      _selectedSubjectTabs.add('Physics');
                      _activeSubjectTab = 'Physics';
                    }
                  });
                },
              ),
            ),
            const SizedBox(width: 10),

            // Chemistry Card
            Expanded(
              child: _buildSubjectSelectCard(
                title: 'Chemistry',
                count: '62',
                bgColor: const Color(0xFFF0F9FF),
                borderColor: const Color(0xFFBAE6FD),
                iconAvatarColor: const Color(0xFFE0F2FE),
                iconWidget: CustomPaint(
                  size: const Size(20, 20),
                  painter: FlaskIconPainter(color: const Color(0xFF0284C7)),
                ),
                isSelected: _selectedSubjectTabs.contains('Chemistry'),
                onTap: () {
                  setState(() {
                    if (_selectedSubjectTabs.contains('Chemistry')) {
                      _selectedSubjectTabs.remove('Chemistry');
                    } else {
                      _selectedSubjectTabs.add('Chemistry');
                      _activeSubjectTab = 'Chemistry';
                    }
                  });
                },
              ),
            ),
            const SizedBox(width: 10),

            // 3rd Subject Card: Biology (NEET) or Mathematics (JEE)
            if (isJee)
              Expanded(
                child: _buildSubjectSelectCard(
                  title: 'Mathematics',
                  count: '75',
                  bgColor: const Color(0xFFFEF3C7),
                  borderColor: const Color(0xFFFDE68A),
                  iconAvatarColor: const Color(0xFFFEF3C7),
                  iconWidget: const Icon(Icons.functions_rounded, color: Color(0xFFD97706), size: 20),
                  isSelected: _selectedSubjectTabs.contains('Mathematics'),
                  onTap: () {
                    setState(() {
                      if (_selectedSubjectTabs.contains('Mathematics')) {
                        _selectedSubjectTabs.remove('Mathematics');
                      } else {
                        _selectedSubjectTabs.add('Mathematics');
                        _activeSubjectTab = 'Mathematics';
                      }
                    });
                  },
                ),
              )
            else
              Expanded(
                child: _buildSubjectSelectCard(
                  title: 'Biology',
                  count: '89',
                  bgColor: const Color(0xFFF0FDF4),
                  borderColor: const Color(0xFFBBF7D0),
                  iconAvatarColor: const Color(0xFFDCFCE7),
                  iconWidget: CustomPaint(
                    size: const Size(20, 20),
                    painter: LeafIconPainter(color: const Color(0xFF16A34A)),
                  ),
                  isSelected: _selectedSubjectTabs.contains('Biology'),
                  onTap: () {
                    setState(() {
                      if (_selectedSubjectTabs.contains('Biology')) {
                        _selectedSubjectTabs.remove('Biology');
                      } else {
                        _selectedSubjectTabs.add('Biology');
                        _activeSubjectTab = 'Biology';
                      }
                    });
                  },
                ),
              ),
          ],
        ),

        const SizedBox(height: 20),

        // Outer Chapters & Topics White Container Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.02),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // If multiple subjects selected, show Subject Tab selector pills
              if (_selectedSubjectTabs.length > 1) ...[
                Row(
                  children: activeSubjects.where((s) => _selectedSubjectTabs.contains(s)).map((subName) {
                    final bool isCurrentActive = _activeSubjectTab == subName;
                    return GestureDetector(
                      onTap: () => setState(() => _activeSubjectTab = subName),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8, bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isCurrentActive ? const Color(0xFF4F46E5) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          subName,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: isCurrentActive ? Colors.white : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              // Header inside Chapters Box
              Row(
                children: [
                  Container(
                    width: 3.5,
                    height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _activeSubjectTab,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    statsText,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        final targetVal = !allChaptersInActiveSubjectSelected;
                        for (final c in activeChaptersList) {
                          c['isSelected'] = targetVal;
                          for (final sub in (c['subtopics'] as List)) {
                            sub['isSelected'] = targetVal;
                          }
                        }
                      });
                    },
                    child: const Text(
                      'Select All Chapters',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF5E46E4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildPurpleCheckbox(
                    isChecked: allChaptersInActiveSubjectSelected,
                    onTap: () {
                      setState(() {
                        final targetVal = !allChaptersInActiveSubjectSelected;
                        for (final c in activeChaptersList) {
                          c['isSelected'] = targetVal;
                          for (final sub in (c['subtopics'] as List)) {
                            sub['isSelected'] = targetVal;
                          }
                        }
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Search Bar Input
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _chapterSearchController,
                  onChanged: (val) {
                    setState(() => _chapterSearchQuery = val);
                  },
                  style: const TextStyle(fontSize: 13.5, color: Color(0xFF0F172A)),
                  decoration: const InputDecoration(
                    hintText: 'Search chapters',
                    hintStyle: TextStyle(fontSize: 13.5, color: Color(0xFF94A3B8)),
                    prefixIcon: Icon(Icons.search_rounded, size: 20, color: Color(0xFF94A3B8)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Chapters Accordion List
              ...filteredChapters.map((ch) {
                final int chNum = ch['number'];
                final bool isExpanded = _expandedChapterIndices.contains(chNum);
                final bool isChSelected = ch['isSelected'] ?? false;
                final List subtopics = ch['subtopics'] ?? [];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isExpanded ? const Color(0xFFC7D2FE) : const Color(0xFFE5E7EB),
                      width: isExpanded ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Accordion Header
                      InkWell(
                        onTap: () {
                          setState(() {
                            if (isExpanded) {
                              _expandedChapterIndices.remove(chNum);
                            } else {
                              _expandedChapterIndices.add(chNum);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          child: Row(
                            children: [
                              _buildPurpleCheckbox(
                                isChecked: isChSelected,
                                onTap: () {
                                  setState(() {
                                    final newVal = !isChSelected;
                                    ch['isSelected'] = newVal;
                                    for (final sub in subtopics) {
                                      sub['isSelected'] = newVal;
                                    }
                                  });
                                },
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${ch['name']}',
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${ch['topicsCountText']}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF5E46E4),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                size: 20,
                                color: const Color(0xFF64748B),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Expanded Subtopics List
                      if (isExpanded && subtopics.isNotEmpty) ...[
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        ...subtopics.map((sub) {
                          final bool isSubSelected = sub['isSelected'] ?? false;
                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 12),
                                    _buildPurpleCheckbox(
                                      isChecked: isSubSelected,
                                      onTap: () {
                                        setState(() {
                                          sub['isSelected'] = !isSubSelected;
                                          final selectedCount = subtopics.where((s) => s['isSelected'] == true).length;
                                          ch['topicsCountText'] = '$selectedCount Topics Selected';
                                          ch['isSelected'] = selectedCount > 0;
                                        });
                                      },
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        '${sub['name']}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isSubSelected ? FontWeight.w600 : FontWeight.w400,
                                          color: const Color(0xFF1E293B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (sub != subtopics.last)
                                const Divider(height: 1, color: Color(0xFFF8FAFC), indent: 44),
                            ],
                          );
                        }),
                      ],
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  // Reusable subject card widget for Screen 2 (Physics, Chemistry, Biology)
  Widget _buildSubjectSelectCard({
    required String title,
    required String count,
    required Color bgColor,
    required Color borderColor,
    required Color iconAvatarColor,
    required Widget iconWidget,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? borderColor : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconAvatarColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: iconWidget),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                _buildPurpleCheckbox(
                  isChecked: isSelected,
                  onTap: onTap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Standardized Purple Checkbox matching screenshot
  Widget _buildPurpleCheckbox({required bool isChecked, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: isChecked ? const Color(0xFF4F46E5) : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isChecked ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1),
            width: 1.5,
          ),
        ),
        child: isChecked
            ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
            : null,
      ),
    );
  }

  // ==========================================
  // SCREEN 3: PRACTICE SETTINGS (Exact Replica)
  // ==========================================
  Widget _buildScreen3PracticeSettings() {
    final allSourcesSelected = _selectedSources.length == 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 3 of 4',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Practice Settings',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Set your preferences for a customized practice session.',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),

        // Section 1: Select Question Source
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Select Question Source',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  if (allSourcesSelected) {
                    _selectedSources.clear();
                  } else {
                    _selectedSources.addAll(['PYQ', 'NTA', 'NCERT', 'Practice', 'Others']);
                  }
                });
              },
              child: Text(
                allSourcesSelected ? 'Deselect All' : 'Select All',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4F46E5),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 2-Column Grid of 5 Question Sources
        Row(
          children: [
            Expanded(
              child: _buildSourceCard(
                name: 'PYQ',
                icon: Icons.calendar_today_outlined,
                isSelected: _selectedSources.contains('PYQ'),
                onTap: (val) {
                  setState(() {
                    val ? _selectedSources.add('PYQ') : _selectedSources.remove('PYQ');
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSourceCard(
                name: 'NTA',
                icon: Icons.style_outlined,
                isSelected: _selectedSources.contains('NTA'),
                onTap: (val) {
                  setState(() {
                    val ? _selectedSources.add('NTA') : _selectedSources.remove('NTA');
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSourceCard(
                name: 'NCERT',
                icon: Icons.menu_book_outlined,
                isSelected: _selectedSources.contains('NCERT'),
                onTap: (val) {
                  setState(() {
                    val ? _selectedSources.add('NCERT') : _selectedSources.remove('NCERT');
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSourceCard(
                name: 'Practice',
                icon: Icons.track_changes_rounded,
                isSelected: _selectedSources.contains('Practice'),
                onTap: (val) {
                  setState(() {
                    val ? _selectedSources.add('Practice') : _selectedSources.remove('Practice');
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSourceCard(
                name: 'Others',
                icon: Icons.more_horiz_rounded,
                isSelected: _selectedSources.contains('Others'),
                onTap: (val) {
                  setState(() {
                    val ? _selectedSources.add('Others') : _selectedSources.remove('Others');
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
          ],
        ),

        const SizedBox(height: 28),

        // Section 2: Select Difficulty
        const Text(
          'Select Difficulty',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        _buildSegmentedSelector<String>(
          options: ['Easy', 'Medium', 'Hard', 'Mixed'],
          selectedValue: _selectedDifficulty,
          labelBuilder: (val) => val,
          onSelected: (val) => setState(() => _selectedDifficulty = val),
        ),

        const SizedBox(height: 28),

        // Section 3: Number of Questions
        const Text(
          'Number of Questions',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        _buildSegmentedSelector<int>(
          options: [10, 20, 30, 45, 90, -1], // -1 represents 'Custom'
          selectedValue: [10, 20, 30, 45, 90].contains(_questionCount) ? _questionCount : -1,
          labelBuilder: (val) => val == -1 ? 'Custom' : '$val',
          onSelected: (val) {
            if (val == -1) {
              _showCustomQuestionCountDialog();
            } else {
              setState(() => _questionCount = val);
            }
          },
        ),

        const SizedBox(height: 28),

        // Section 4: Time Limit
        const Text(
          'Time Limit',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        _buildSegmentedSelector<int>(
          options: [0, 15, 30, 45, 60],
          selectedValue: [0, 15, 30, 45, 60].contains(_timerMinutes) ? _timerMinutes : -1,
          labelBuilder: (val) => val == 0 ? 'No Limit' : '$val min',
          onSelected: (val) => setState(() => _timerMinutes = val),
        ),
        const SizedBox(height: 10),

        // Custom Timer Edit Button
        OutlinedButton.icon(
          onPressed: _showCustomTimerDialog,
          icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF475569)),
          label: Text(
            _timerMinutes != 0 && ![15, 30, 45, 60].contains(_timerMinutes)
                ? 'Custom: $_timerMinutes min'
                : 'Custom',
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            backgroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  // Question Source Card Widget matching exact layout & colors
  Widget _buildSourceCard({
    required String name,
    required IconData icon,
    required bool isSelected,
    required ValueChanged<bool> onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF5F3FF) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
          width: isSelected ? 1.5 : 1.0,
        ),
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF4F46E5) : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1),
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Connected Segmented Bar Selector Widget matching exact screenshot design
  Widget _buildSegmentedSelector<T>({
    required List<T> options,
    required T selectedValue,
    required String Function(T) labelBuilder,
    required ValueChanged<T> onSelected,
  }) {
    return Container(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Row(
          children: List.generate(options.length, (index) {
            final option = options[index];
            final isSelected = option == selectedValue;

            return Expanded(
              child: GestureDetector(
                onTap: () => onSelected(option),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF4F46E5) : Colors.transparent,
                    border: index > 0 && !isSelected && options[index - 1] != selectedValue
                        ? const Border(left: BorderSide(color: Color(0xFFE2E8F0), width: 1.0))
                        : null,
                  ),
                  child: Text(
                    labelBuilder(option),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF334155),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  void _showCustomTimerDialog() {
    final controller = TextEditingController(text: _timerMinutes > 0 ? '$_timerMinutes' : '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Custom Time Limit'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Minutes',
            hintText: 'Enter duration in minutes (e.g. 25)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final mins = int.tryParse(controller.text.trim());
              if (mins != null && mins >= 0) {
                setState(() => _timerMinutes = mins);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Set Timer'),
          ),
        ],
      ),
    );
  }

  void _showCustomQuestionCountDialog() {
    final controller = TextEditingController(text: _questionCount > 0 ? '$_questionCount' : '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Custom Question Count'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Number of Questions',
            hintText: 'Enter question count (e.g. 40)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final cnt = int.tryParse(controller.text.trim());
              if (cnt != null && cnt > 0) {
                setState(() => _questionCount = cnt);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Set Count'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SCREEN 4: REVIEW & CONFIRM (Exact Replica)
  // ==========================================
  Widget _buildScreen4Overview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 4 of 4',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Review & Confirm',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Please review your practice session details before you start.',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),

        // Summary Card with 8 Rows matching exact screenshot layout
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.02),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Row 1: Exam
              _buildReviewRow(
                iconWidget: const Icon(Icons.medical_services_outlined, size: 20, color: Color(0xFF16A34A)),
                iconBgColor: const Color(0xFFDCFCE7),
                title: 'Exam',
                valueText: _selectedExam,
              ),

              // Row 2: Subjects
              _buildReviewRow(
                iconWidget: const Icon(Icons.bubble_chart_outlined, size: 20, color: Color(0xFF6366F1)),
                iconBgColor: const Color(0xFFEEF2FF),
                title: 'Subjects',
                valueText: _selectedSubjectIds.isEmpty
                    ? 'Physics, Chemistry, Biology'
                    : _availableSubjects.where((s) => _selectedSubjectIds.contains(s.id)).map((s) => s.name).join(', '),
                extraBadge: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_selectedSubjectIds.isEmpty ? 3 : _selectedSubjectIds.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
                ),
              ),

              // Row 3: Chapters
              _buildReviewRow(
                iconWidget: const Icon(Icons.menu_book_outlined, size: 20, color: Color(0xFF0284C7)),
                iconBgColor: const Color(0xFFE0F2FE),
                title: 'Chapters',
                valueText: '${_selectedChapterNames.isEmpty ? 7 : _selectedChapterNames.length} Chapters',
                trailingWidget: _buildChevronCircle(),
              ),

              // Row 4: Topics
              _buildReviewRow(
                iconWidget: const Icon(Icons.format_list_bulleted_rounded, size: 20, color: Color(0xFF2563EB)),
                iconBgColor: const Color(0xFFE0F2FE),
                title: 'Topics',
                valueText: '${_selectedTopicNames.isEmpty ? 16 : _selectedTopicNames.length} Topics',
                trailingWidget: _buildChevronCircle(),
              ),

              // Row 5: Question Source
              _buildReviewRow(
                iconWidget: const Icon(Icons.track_changes_rounded, size: 20, color: Color(0xFF16A34A)),
                iconBgColor: const Color(0xFFDCFCE7),
                title: 'Question Source',
                valueText: _selectedSources.join(', '),
                subRow: _buildSourceBadges(),
              ),

              // Row 6: Difficulty
              _buildReviewRow(
                iconWidget: const Icon(Icons.bar_chart_rounded, size: 20, color: Color(0xFFEA580C)),
                iconBgColor: const Color(0xFFFFEDD5),
                title: 'Difficulty',
                valueText: _selectedDifficulty,
                trailingWidget: _buildDifficultySignalBars(_selectedDifficulty),
              ),

              // Row 7: Number of Questions
              _buildReviewRow(
                iconWidget: const Icon(Icons.numbers_rounded, size: 20, color: Color(0xFFDB2777)),
                iconBgColor: const Color(0xFFFCE7F3),
                title: 'Number of Questions',
                valueText: '$_questionCount Questions',
              ),

              // Row 8: Time Limit
              _buildReviewRow(
                iconWidget: const Icon(Icons.access_time_rounded, size: 20, color: Color(0xFFEF4444)),
                iconBgColor: const Color(0xFFFEE2E2),
                title: 'Time Limit',
                valueText: _timerMinutes == 0 ? 'No Limit' : '$_timerMinutes min',
                showDivider: false,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Banner Card Notification
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F3FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEEF2FF), width: 1.0),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.mode == PracticeTestMode.test ? const Color(0xFFFEF2F2) : const Color(0xFFEEF2FF),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.mode == PracticeTestMode.test ? Icons.warning_amber_rounded : Icons.lightbulb_outline_rounded,
                  color: widget.mode == PracticeTestMode.test ? const Color(0xFFDC2626) : const Color(0xFFEAB308),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.mode == PracticeTestMode.test
                          ? 'Important Notice: Test Mode Active'
                          : 'You\'re all set to start practicing!',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.mode == PracticeTestMode.test
                          ? 'This is a test. Your answers will not show correctness or solutions until you submit the test.'
                          : 'Click on Start Practice to begin your customized session.',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Review Row Helper Widget matching exact row padding & dividers
  Widget _buildReviewRow({
    required Widget iconWidget,
    required Color iconBgColor,
    required String title,
    required String valueText,
    Widget? extraBadge,
    Widget? trailingWidget,
    bool showDivider = true,
    Widget? subRow,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: iconWidget),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        valueText,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      if (extraBadge != null) ...[
                        const SizedBox(width: 8),
                        extraBadge,
                      ],
                      if (trailingWidget != null) ...[
                        const SizedBox(width: 8),
                        trailingWidget,
                      ],
                    ],
                  ),
                ],
              ),
              if (subRow != null) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 52),
                  child: subRow,
                ),
              ],
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 16, endIndent: 16),
      ],
    );
  }

  // Difficulty Signal Bar Graphic Widget
  Widget _buildDifficultySignalBars(String diff) {
    int activeBars = 2;
    if (diff == 'Easy') activeBars = 1;
    if (diff == 'Hard') activeBars = 3;
    if (diff == 'Mixed') activeBars = 2;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(3, (index) {
        final isActive = index < activeBars;
        return Container(
          width: 3.5,
          height: (index + 1) * 4.5 + 4,
          margin: const EdgeInsets.only(left: 2.5),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1),
            borderRadius: BorderRadius.circular(1.5),
          ),
        );
      }),
    );
  }

  // Source Badges Row Widget
  Widget _buildSourceBadges() {
    final sources = _selectedSources.isNotEmpty ? _selectedSources.toList() : ['PYQ', 'NTA', 'Practice'];
    return Wrap(
      spacing: 6,
      children: sources.map((src) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F3FF),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            src,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4F46E5),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Right Chevron Circle Widget
  Widget _buildChevronCircle() {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: Color(0xFFF5F3FF),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF4F46E5)),
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
                  if (_currentStep == 3) ...[
                    Icon(
                      widget.mode == PracticeTestMode.test ? Icons.assignment_turned_in_outlined : Icons.play_arrow_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.mode == PracticeTestMode.test ? 'Start Test' : 'Start Practice',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
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
