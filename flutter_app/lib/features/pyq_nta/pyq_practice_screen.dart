import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../models/pyq_models.dart';
import '../../core/services/supabase_service.dart';

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
  int _currentStep = 1; // 1 = Select Subject, 2 = Select Chapters & Topics

  late String _selectedExam;
  String _selectedSubject = 'Physics';
  
  bool _isLoadingStats = true;
  bool _isStarting = false;

  int _availableQuestionsCount = 1248;
  int _availablePapersCount = 98;
  double _userAccuracy = 72.4;
  int _timeSpentSeconds = 101700;
  Map<String, int> _subjectPYQCounts = {};

  String _searchQuery = '';
  int _activeViewTab = 0; // 0 = Chapters, 1 = Topics
  List<ChapterItem> _chapters = [];

  @override
  void initState() {
    super.initState();
    _selectedExam = widget.activeExam.contains('JEE') ? 'JEE Main 2026' : 'NEET 2026';
    _selectedSubject = 'Physics';
    _loadStats();
    _initChapters();
  }

  void _initChapters() {
    if (_selectedSubject == 'Physics') {
      _chapters = [
        ChapterItem(
          id: 'c1',
          name: '1. Mechanics',
          isExpanded: true,
          topics: [
            TopicItem(id: 't1_1', name: '1.1 Physical World & Measurement', isSelected: true),
            TopicItem(id: 't1_2', name: '1.2 Kinematics', isSelected: true),
            TopicItem(id: 't1_3', name: '1.3 Laws of Motion', isSelected: true),
            TopicItem(id: 't1_4', name: '1.4 Work, Energy & Power', isSelected: true),
          ],
        ),
        ChapterItem(
          id: 'c2',
          name: '2. Thermal Properties of Matter',
          isExpanded: false,
          topics: [
            TopicItem(id: 't2_1', name: '2.1 Heat Transfer & Calorimetry', isSelected: true),
            TopicItem(id: 't2_2', name: '2.2 Thermodynamics & Kinetic Theory', isSelected: true),
          ],
        ),
        ChapterItem(
          id: 'c3',
          name: '3. Current Electricity',
          isExpanded: false,
          topics: [
            TopicItem(id: 't3_1', name: '3.1 Ohm\'s Law & Kirchhoff\'s Rules', isSelected: true),
            TopicItem(id: 't3_2', name: '3.2 Potentiometer & Meter Bridge', isSelected: true),
          ],
        ),
        ChapterItem(
          id: 'c4',
          name: '4. Modern Physics',
          isExpanded: false,
          topics: [
            TopicItem(id: 't4_1', name: '4.1 Dual Nature of Radiation & Matter', isSelected: true),
            TopicItem(id: 't4_2', name: '4.2 Atoms & Nuclei', isSelected: true),
          ],
        ),
        ChapterItem(
          id: 'c5',
          name: '5. Optics',
          isExpanded: false,
          topics: [
            TopicItem(id: 't5_1', name: '5.1 Ray Optics & Optical Instruments', isSelected: true),
            TopicItem(id: 't5_2', name: '5.2 Wave Optics & Interference', isSelected: true),
          ],
        ),
        ChapterItem(
          id: 'c6',
          name: '6. Electrostatics',
          isExpanded: false,
          topics: [
            TopicItem(id: 't6_1', name: '6.1 Electric Fields & Potentials', isSelected: true),
            TopicItem(id: 't6_2', name: '6.2 Capacitance & Dielectrics', isSelected: true),
          ],
        ),
      ];
    } else if (_selectedSubject == 'Chemistry') {
      _chapters = [
        ChapterItem(
          id: 'cc1',
          name: '1. Physical Chemistry',
          isExpanded: true,
          topics: [
            TopicItem(id: 'ct1_1', name: '1.1 Some Basic Concepts of Chemistry', isSelected: true),
            TopicItem(id: 'ct1_2', name: '1.2 Chemical Thermodynamics & Energetics', isSelected: true),
            TopicItem(id: 'ct1_3', name: '1.3 Chemical & Ionic Equilibrium', isSelected: true),
          ],
        ),
        ChapterItem(
          id: 'cc2',
          name: '2. Organic Chemistry',
          isExpanded: false,
          topics: [
            TopicItem(id: 'ct2_1', name: '2.1 Hydrocarbons & Alkanes', isSelected: true),
            TopicItem(id: 'ct2_2', name: '2.2 Haloalkanes & Haloarenes', isSelected: true),
            TopicItem(id: 'ct2_3', name: '2.3 Aldehydes, Ketones & Carboxylic Acids', isSelected: true),
          ],
        ),
        ChapterItem(
          id: 'cc3',
          name: '3. Inorganic Chemistry',
          isExpanded: false,
          topics: [
            TopicItem(id: 'ct3_1', name: '3.1 Periodic Classification & Chemical Bonding', isSelected: true),
            TopicItem(id: 'ct3_2', name: '3.2 Coordination Compounds & d-Block', isSelected: true),
          ],
        ),
      ];
    } else if (_selectedSubject == 'Biology') {
      _chapters = [
        ChapterItem(
          id: 'bc1',
          name: '1. Human Physiology',
          isExpanded: true,
          topics: [
            TopicItem(id: 'bt1_1', name: '1.1 Digestion & Absorption', isSelected: true),
            TopicItem(id: 'bt1_2', name: '1.2 Breathing & Exchange of Gases', isSelected: true),
            TopicItem(id: 'bt1_3', name: '1.3 Body Fluids & Circulation', isSelected: true),
            TopicItem(id: 'bt1_4', name: '1.4 Neural Control & Coordination', isSelected: true),
          ],
        ),
        ChapterItem(
          id: 'bc2',
          name: '2. Plant Physiology',
          isExpanded: false,
          topics: [
            TopicItem(id: 'bt2_1', name: '2.1 Transport in Plants & Mineral Nutrition', isSelected: true),
            TopicItem(id: 'bt2_2', name: '2.2 Photosynthesis & Respiration', isSelected: true),
          ],
        ),
        ChapterItem(
          id: 'bc3',
          name: '3. Genetics & Molecular Biology',
          isExpanded: false,
          topics: [
            TopicItem(id: 'bt3_1', name: '3.1 Principles of Inheritance & Variation', isSelected: true),
            TopicItem(id: 'bt3_2', name: '3.2 Molecular Basis of Inheritance', isSelected: true),
          ],
        ),
      ];
    } else {
      _chapters = [
        ChapterItem(
          id: 'mc1',
          name: '1. Calculus',
          isExpanded: true,
          topics: [
            TopicItem(id: 'mt1_1', name: '1.1 Limits, Continuity & Differentiability', isSelected: true),
            TopicItem(id: 'mt1_2', name: '1.2 Indefinite & Definite Integrals', isSelected: true),
            TopicItem(id: 'mt1_3', name: '1.3 Differential Equations & Applications', isSelected: true),
          ],
        ),
        ChapterItem(
          id: 'mc2',
          name: '2. Algebra',
          isExpanded: false,
          topics: [
            TopicItem(id: 'mt2_1', name: '2.1 Matrices & Determinants', isSelected: true),
            TopicItem(id: 'mt2_2', name: '2.2 Complex Numbers & Quadratic Equations', isSelected: true),
            TopicItem(id: 'mt2_3', name: '2.3 Sequences, Series & Binomial Theorem', isSelected: true),
          ],
        ),
        ChapterItem(
          id: 'mc3',
          name: '3. Coordinate Geometry & Vectors',
          isExpanded: false,
          topics: [
            TopicItem(id: 'mt3_1', name: '3.1 Straight Lines & Circles', isSelected: true),
            TopicItem(id: 'mt3_2', name: '3.2 Conic Sections (Parabola, Ellipse, Hyperbola)', isSelected: true),
            TopicItem(id: 'mt3_3', name: '3.3 Vector Algebra & 3D Geometry', isSelected: true),
          ],
        ),
      ];
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
        _selectedSubject = 'Physics';
      } else {
        _selectedSubject = 'Physics';
      }
      _initChapters();
    });
    _loadStats();
  }

  void _selectSubject(String subName) {
    setState(() {
      _selectedSubject = subName;
      _initChapters();
    });
  }

  int get _totalSelectedChaptersCount => _chapters.where((c) => c.topics.any((t) => t.isSelected)).length;
  int get _totalSelectedTopicsCount => _chapters.fold(0, (sum, c) => sum + c.selectedTopicCount);
  int get _totalAllTopicsCount => _chapters.fold(0, (sum, c) => sum + c.topics.length);

  bool get _areAllChaptersSelected => _chapters.isNotEmpty && _chapters.every((c) => c.isFullySelected);

  void _toggleSelectAllChapters(bool? val) {
    final select = val ?? !_areAllChaptersSelected;
    setState(() {
      for (var c in _chapters) {
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
          content: Text('Select at least one chapter or topic to continue.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isStarting = true);

    final questions = await SupabaseService.fetchPYQQuestions(
      exam: _selectedExam,
      subjects: [_selectedSubject],
      limit: 20,
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

    final timerMins = isTestMode ? 30 : 0;

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
                side: const BorderSide(color: Color(0xFFDDD6FE)),
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
                      ? 'Practice previous year questions chapter-wise and year-wise to ace NEET & JEE'
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

        // Section 1: Select Subject
        const Text(
          '1. Select Subject',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 12),
        Row(
          children: availableSubjects.map((subName) {
            final isSelected = _selectedSubject == subName;
            final count = _subjectPYQCounts[subName] ?? (subName == 'Physics' ? 486 : (subName == 'Chemistry' ? 436 : (isNeet ? 292 : 480)));

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
                  onTap: () => _selectSubject(subName),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? themeColor.withOpacity(0.06) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? themeColor : const Color(0xFFE2E8F0),
                        width: isSelected ? 2.5 : 1,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(color: themeColor.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Column(
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
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),

        // Action Button to proceed to Step 2
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
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
                  'Continue to Select Chapters & Topics →',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ================= STEP 2 VIEW (EXACT SCREENSHOT DESIGN) =================

  Widget _buildStep2View() {
    final availablePyqs = _subjectPYQCounts[_selectedSubject] ?? 486;

    final filteredChapters = _searchQuery.isEmpty
        ? _chapters
        : _chapters.where((c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase()) || c.topics.any((t) => t.name.toLowerCase().contains(_searchQuery.toLowerCase()))).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                      _selectedSubject == 'Chemistry'
                          ? Icons.science_rounded
                          : (_selectedSubject == 'Biology'
                              ? Icons.coronavirus_outlined
                              : (_selectedSubject == 'Mathematics' ? Icons.calculate_outlined : Icons.science_outlined)),
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
                          _selectedSubject,
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
                      '${_chapters.length} Chapters',
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
                      '$_totalAllTopicsCount Topics',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Choose the chapters and topics you want to practice PYQs from. ($availablePyqs PYQs Available)',
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
                        decoration: const InputDecoration(
                          hintText: 'Search chapters...',
                          hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
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

        // Select All Chapters Header Bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _areAllChaptersSelected,
                    activeColor: const Color(0xFF7C3AED),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: _toggleSelectAllChapters,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Select All Chapters',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  '$_totalSelectedChaptersCount selected',
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

  // ================= STICKY BOTTOM ACTION BAR (MATCHING SCREENSHOT) =================

  Widget _buildStickyBottomBarStep2() {
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
                // Selected Counter Pill Card
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
                          const Text('Selected', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                          Text(
                            '$_totalSelectedChaptersCount Chapters • $_totalSelectedTopicsCount Topics',
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
}
