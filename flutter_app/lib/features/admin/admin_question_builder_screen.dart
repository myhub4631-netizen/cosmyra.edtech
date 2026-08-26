import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/models.dart';
import '../../core/services/supabase_service.dart';

class AdminQuestionBuilderScreen extends StatefulWidget {
  final UserProfileModel userProfile;
  final Map<String, dynamic>? initialQuestionData;
  final VoidCallback? onBack;
  final Function(Map<String, dynamic>)? onQuestionSaved;

  const AdminQuestionBuilderScreen({
    Key? key,
    required this.userProfile,
    this.initialQuestionData,
    this.onBack,
    this.onQuestionSaved,
  }) : super(key: key);

  @override
  State<AdminQuestionBuilderScreen> createState() => _AdminQuestionBuilderScreenState();
}

class _AdminQuestionBuilderScreenState extends State<AdminQuestionBuilderScreen> {
  // Sidebar state
  bool _isSidebarCollapsed = false;
  String _activeSubNav = 'Add New Question';

  // Section 1: Basic Information States
  String _selectedSourceType = 'NTA';
  String _selectedSubject = 'Physics';
  String _selectedChapter = 'Laws of Motion';
  String _selectedTopic = 'Newton\'s Laws of Motion';
  String _selectedSubTopic = 'Second Law & Force';
  String _selectedDifficulty = 'Easy';
  String _selectedQuestionType = 'Single Choice (MCQ)';

  final TextEditingController _marksController = TextEditingController(text: '4');
  final TextEditingController _negativeMarksController = TextEditingController(text: '1');
  bool _hasImageDiagram = false;

  // Section 2: Question Statement
  final TextEditingController _questionTextController = TextEditingController();

  // Section 3: Options State
  bool _shuffleOptions = false;
  final List<Map<String, dynamic>> _optionsList = [
    {'label': 'A', 'controller': TextEditingController(text: 'Option A'), 'hasImage': false},
    {'label': 'B', 'controller': TextEditingController(text: 'Option B'), 'hasImage': false},
    {'label': 'C', 'controller': TextEditingController(text: 'Option C'), 'hasImage': false},
    {'label': 'D', 'controller': TextEditingController(text: 'Option D'), 'hasImage': false},
  ];

  // Section 4: Correct Answer
  String _correctAnswerOption = 'A';

  // Section 5: Explanation
  final TextEditingController _explanationController = TextEditingController();

  // Section 6: Tags
  final List<String> _tags = ['Kinematics', 'Formula'];
  final TextEditingController _tagInputController = TextEditingController();

  // Section 7: Additional Settings Checkboxes
  bool _isActive = true;
  bool _showInCustomPractice = true;
  bool _showInCustomTest = true;
  bool _showInPYQPractice = true;
  bool _showInNTAQuestionPractice = true;
  bool _showInTestSeries = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuestionData != null) {
      final q = widget.initialQuestionData!;
      _selectedSourceType = q['sourceType'] ?? 'NTA';
      _selectedSubject = q['subject'] ?? 'Physics';
      _selectedChapter = q['chapter'] ?? 'Laws of Motion';
      _selectedDifficulty = q['difficulty'] ?? 'Medium';
      _questionTextController.text = q['questionText'] ?? '';
      _explanationController.text = q['explanation'] ?? '';
    }
  }

  @override
  void dispose() {
    _marksController.dispose();
    _negativeMarksController.dispose();
    _questionTextController.dispose();
    _explanationController.dispose();
    _tagInputController.dispose();
    for (var opt in _optionsList) {
      (opt['controller'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionsList.length >= 6) return;
    final nextLabel = String.fromCharCode(65 + _optionsList.length);
    setState(() {
      _optionsList.add({
        'label': nextLabel,
        'controller': TextEditingController(text: 'Option $nextLabel'),
        'hasImage': false,
      });
    });
  }

  void _removeOption(int index) {
    if (_optionsList.length <= 2) return;
    setState(() {
      _optionsList.removeAt(index);
      for (int i = 0; i < _optionsList.length; i++) {
        _optionsList[i]['label'] = String.fromCharCode(65 + i);
      }
      if (_correctAnswerOption.codeUnitAt(0) - 65 >= _optionsList.length) {
        _correctAnswerOption = 'A';
      }
    });
  }

  void _saveAndSubmitQuestion({bool isDraft = false}) {
    final usedIn = <String>[];
    if (_showInCustomPractice) usedIn.add('Custom Practice');
    if (_showInCustomTest) usedIn.add('Custom Test');
    if (_showInPYQPractice) usedIn.add('PYQ Practice');
    if (_showInNTAQuestionPractice) usedIn.add('NTA Question Practice');
    if (_showInTestSeries) usedIn.add('Test Series');

    final optionTexts = _optionsList.map((opt) => (opt['controller'] as TextEditingController).text).toList();
    final correctIndex = _correctAnswerOption.codeUnitAt(0) - 65;
    final correctVal = (correctIndex >= 0 && correctIndex < optionTexts.length)
        ? optionTexts[correctIndex]
        : (optionTexts.isNotEmpty ? optionTexts[0] : '');

    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = monthNames[now.month - 1];
    final year = now.year;
    final timeStr = "${now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour)}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}";

    final qText = _questionTextController.text.trim().isEmpty
        ? 'A body of mass m is moving with velocity v. The kinetic energy of the body is...'
        : _questionTextController.text.trim();

    final newQuestion = {
      'id': widget.initialQuestionData?['id'] ?? 'Q${123461 + DateTime.now().millisecondsSinceEpoch % 10000}',
      'questionText': qText,
      'subject': _selectedSubject,
      'chapter': _selectedChapter,
      'topic': _selectedTopic,
      'subTopic': _selectedSubTopic,
      'sourceType': _selectedSourceType,
      'difficulty': _selectedDifficulty,
      'questionType': _selectedQuestionType,
      'marks': _marksController.text,
      'negativeMarks': _negativeMarksController.text,
      'hasImage': _hasImageDiagram,
      'tags': _tags.isEmpty ? [_selectedSubject, 'General'] : List<String>.from(_tags),
      'usedIn': usedIn.isEmpty ? ['Custom Practice', 'Custom Test'] : usedIn,
      'addedOn': '$day $month $year $timeStr',
      'options': optionTexts,
      'correctAnswer': correctVal,
      'explanation': _explanationController.text,
      'isActive': _isActive,
      'isDraft': isDraft,
    };

    SupabaseService.saveQuestionMap(newQuestion);
    _saveToPrefs(newQuestion);

    if (widget.onQuestionSaved != null) {
      widget.onQuestionSaved!(newQuestion);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isDraft ? 'Draft saved successfully!' : 'Question added to Question Bank successfully!'),
        backgroundColor: isDraft ? const Color(0xFF4F46E5) : const Color(0xFF16A34A),
      ),
    );

    if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context, newQuestion);
    }
  }

  Future<void> _saveToPrefs(Map<String, dynamic> newQuestion) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('cosmyra_saved_custom_questions');
      List<Map<String, dynamic>> list = [];
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        list = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      final idx = list.indexWhere((q) => q['id'] == newQuestion['id']);
      if (idx != -1) {
        list[idx] = newQuestion;
      } else {
        list.insert(0, newQuestion);
      }
      await prefs.setString('cosmyra_saved_custom_questions', jsonEncode(list));
    } catch (e) {
      debugPrint('Error saving question to prefs: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. LEFT SIDEBAR NAVIGATION (Dark Navy #0F172A)
          _buildSidebar(),

          // 2. MAIN CONTENT AREA
          Expanded(
            child: Column(
              children: [
                // TOP APP BAR
                _buildTopAppBar(),

                // MAIN FORM CONTAINER (Scrollable)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Page Breadcrumb, Title & Top Action Buttons
                        _buildPageHeader(),

                        const SizedBox(height: 20),

                        // Two Column Form Layout (Left: Form Sections 1, 2, 3 | Right: Settings Sections 4, 5, 6, 7 & Notes)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // LEFT COLUMN (Flex 7)
                            Expanded(
                              flex: 7,
                              child: Column(
                                children: [
                                  _buildSection1BasicInformation(),
                                  const SizedBox(height: 20),
                                  _buildSection2QuestionStatement(),
                                  const SizedBox(height: 20),
                                  _buildSection3Options(),
                                ],
                              ),
                            ),

                            const SizedBox(width: 20),

                            // RIGHT COLUMN (Flex 3)
                            Expanded(
                              flex: 3,
                              child: Column(
                                children: [
                                  _buildSection4CorrectAnswer(),
                                  const SizedBox(height: 20),
                                  _buildSection5Explanation(),
                                  const SizedBox(height: 20),
                                  _buildSection6Tags(),
                                  const SizedBox(height: 20),
                                  _buildSection7AdditionalSettings(),
                                  const SizedBox(height: 20),
                                  _buildImportantNotesBox(),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 1. SIDEBAR NAVIGATION
  // ==========================================
  Widget _buildSidebar() {
    return Container(
      width: _isSidebarCollapsed ? 70 : 240,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(right: BorderSide(color: Color(0xFF1E293B), width: 1)),
      ),
      child: Column(
        children: [
          // Logo Header
          Container(
            height: 68,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF1E293B), width: 1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.shield_outlined, color: Colors.white, size: 20),
                ),
                if (!_isSidebarCollapsed) ...[
                  const SizedBox(width: 12),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cosmyra Edu',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Admin Panel',
                        style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Nav Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              children: [
                if (!_isSidebarCollapsed)
                  const Padding(
                    padding: EdgeInsets.only(left: 12, bottom: 8),
                    child: Text('MAIN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                  ),
                _buildSidebarNavItem(icon: Icons.dashboard_outlined, title: 'Dashboard'),
                _buildSidebarNavItem(icon: Icons.people_outline_rounded, title: 'Users', hasChevron: true),

                const SizedBox(height: 16),
                if (!_isSidebarCollapsed)
                  const Padding(
                    padding: EdgeInsets.only(left: 12, bottom: 8),
                    child: Text('CONTENT MANAGEMENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                  ),

                // Active Header: Questions Bank
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(color: const Color(0xFF4F46E5), borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      const Icon(Icons.quiz_outlined, size: 20, color: Colors.white),
                      if (!_isSidebarCollapsed) ...[
                        const SizedBox(width: 12),
                        const Expanded(child: Text('Questions Bank', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white))),
                        const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.white),
                      ],
                    ],
                  ),
                ),

                if (!_isSidebarCollapsed)
                  Padding(
                    padding: const EdgeInsets.only(left: 20, top: 8, bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        'All Questions',
                        'Add New Question',
                        'Import Questions',
                        'Question Tags',
                        'Question Sets',
                      ].map((item) {
                        final bool isSubActive = _activeSubNav == item;
                        return InkWell(
                          onTap: () {
                            setState(() => _activeSubNav = item);
                            if (item == 'All Questions' && widget.onBack != null) {
                              widget.onBack!();
                            }
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                            child: Text(
                              item,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSubActive ? FontWeight.w700 : FontWeight.w400,
                                color: isSubActive ? const Color(0xFF818CF8) : const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                _buildSidebarNavItem(icon: Icons.assignment_outlined, title: 'Test Management', hasChevron: true),
                _buildSidebarNavItem(icon: Icons.fitness_center_outlined, title: 'Practice', hasChevron: true),
                _buildSidebarNavItem(icon: Icons.history_edu_outlined, title: 'PYQ', hasChevron: true),
                _buildSidebarNavItem(icon: Icons.description_outlined, title: 'NTA Practice', hasChevron: true),
                _buildSidebarNavItem(icon: Icons.menu_book_outlined, title: 'Study Material', hasChevron: true),

                const SizedBox(height: 16),
                if (!_isSidebarCollapsed)
                  const Padding(
                    padding: EdgeInsets.only(left: 12, bottom: 8),
                    child: Text('ANALYTICS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                  ),
                _buildSidebarNavItem(icon: Icons.bar_chart_rounded, title: 'Analytics'),
                _buildSidebarNavItem(icon: Icons.receipt_long_outlined, title: 'Reports'),

                const SizedBox(height: 16),
                if (!_isSidebarCollapsed)
                  const Padding(
                    padding: EdgeInsets.only(left: 12, bottom: 8),
                    child: Text('SYSTEM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                  ),
                _buildSidebarNavItem(icon: Icons.settings_outlined, title: 'Settings'),
                _buildSidebarNavItem(icon: Icons.admin_panel_settings_outlined, title: 'Roles & Permissions'),
                _buildSidebarNavItem(icon: Icons.list_alt_rounded, title: 'Logs'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarNavItem({required IconData icon, required String title, bool hasChevron = false}) {
    return InkWell(
      onTap: () {
        if (title == 'Dashboard' && widget.onBack != null) {
          widget.onBack!();
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF94A3B8)),
            if (!_isSidebarCollapsed) ...[
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: Color(0xFFCBD5E1)))),
              if (hasChevron) const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF64748B)),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 2. TOP APPLICATION APP BAR
  // ==========================================
  Widget _buildTopAppBar() {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
            icon: const Icon(Icons.menu_rounded, color: Color(0xFF64748B)),
          ),
          const SizedBox(width: 16),

          // Search Box
          Expanded(
            child: Container(
              height: 40,
              constraints: const BoxConstraints(maxWidth: 380),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  SizedBox(width: 12),
                  Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Search anything...', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    margin: EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(color: Color(0xFFE2E8F0), borderRadius: BorderRadius.all(Radius.circular(4))),
                    child: Text('⌘K', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Notification Bell
          Stack(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF64748B), size: 24),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                  child: const Text('12', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
            ],
          ),

          const SizedBox(width: 16),

          // User Profile
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF4F46E5),
                child: Text(
                  widget.userProfile.fullName.isNotEmpty ? widget.userProfile.fullName[0].toUpperCase() : 'A',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userProfile.fullName.isNotEmpty ? widget.userProfile.fullName : 'Admin',
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                  ),
                  const Text('Super Admin', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 3. PAGE HEADER & ACTIONS
  // ==========================================
  Widget _buildPageHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Text('Questions Bank', style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
                SizedBox(width: 6),
                Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFF94A3B8)),
                SizedBox(width: 6),
                Text('Add New Question', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF4F46E5))),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Add New Question',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.5),
            ),
            const SizedBox(height: 4),
            const Text(
              'Create a new question and add it to the question bank.',
              style: TextStyle(fontSize: 13.5, color: Color(0xFF64748B)),
            ),
          ],
        ),

        Row(
          children: [
            TextButton(
              onPressed: () {
                if (widget.onBack != null) {
                  widget.onBack!();
                } else if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Cancel', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: () => _saveAndSubmitQuestion(isDraft: true),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                side: const BorderSide(color: Color(0xFFC7D2FE), width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                backgroundColor: Colors.white,
              ),
              child: const Text('Save as Draft', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF4F46E5))),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _saveAndSubmitQuestion(isDraft: false),
              icon: const Icon(Icons.save_outlined, size: 18, color: Colors.white),
              label: const Text('Save Question', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                backgroundColor: const Color(0xFF4F46E5),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // LEFT COLUMN: SECTION 1 - BASIC INFORMATION
  // ==========================================
  Widget _buildSection1BasicInformation() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.02), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('1. Basic Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),

          // Source Type Pills
          const Text('Source Type *', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildSourcePill('NTA', Icons.event_note_outlined, const Color(0xFFDCFCE7), const Color(0xFF16A34A)),
              const SizedBox(width: 10),
              _buildSourcePill('PYQ', Icons.school_outlined, const Color(0xFFFFEDD5), const Color(0xFFEA580C)),
              const SizedBox(width: 10),
              _buildSourcePill('NCERT', Icons.menu_book_outlined, const Color(0xFFE0F2FE), const Color(0xFF0284C7)),
              const SizedBox(width: 10),
              _buildSourcePill('Practice', Icons.track_changes_rounded, const Color(0xFFFCE7F3), const Color(0xFFDB2777)),
              const SizedBox(width: 10),
              _buildSourcePill('Other', Icons.more_horiz_rounded, const Color(0xFFF1F5F9), const Color(0xFF64748B)),
            ],
          ),

          const SizedBox(height: 18),

          // Subject & Chapter Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Subject *', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedSubject,
                      items: ['Physics', 'Chemistry', 'Biology', 'Mathematics']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedSubject = val!),
                      decoration: InputDecoration(
                        hintText: 'Select Subject',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Chapter *', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedChapter,
                      items: ['Laws of Motion', 'Units & Measurements', 'States of Matter', 'Photosynthesis', 'Solutions']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedChapter = val!),
                      decoration: InputDecoration(
                        hintText: 'Select Chapter',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Topic & Sub Topic Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Topic *', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedTopic,
                      items: ['Newton\'s Laws of Motion', 'Kinematics & Acceleration', 'Work Energy Theorem']
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedTopic = val!),
                      decoration: InputDecoration(
                        hintText: 'Select Topic',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sub Topic (Optional)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedSubTopic,
                      items: ['Second Law & Force', 'Third Law & Action Reaction', 'Friction & Slope']
                          .map((st) => DropdownMenuItem(value: st, child: Text(st)))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedSubTopic = val!),
                      decoration: InputDecoration(
                        hintText: 'Select Sub Topic',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Difficulty Level & Question Type Row
          Row(
            children: [
              // Difficulty Level
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Difficulty Level *', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildDifficultyPill('Easy', const Color(0xFFDCFCE7), const Color(0xFF16A34A)),
                      const SizedBox(width: 8),
                      _buildDifficultyPill('Medium', const Color(0xFFFEF3C7), const Color(0xFFD97706)),
                      const SizedBox(width: 8),
                      _buildDifficultyPill('Hard', const Color(0xFFFEE2E2), const Color(0xFFDC2626)),
                    ],
                  ),
                ],
              ),

              const SizedBox(width: 24),

              // Question Type
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Question Type *', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                        Text('ⓘ Learn about question types', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF4F46E5))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedQuestionType,
                      items: [
                        'Single Choice (MCQ)',
                        'Multiple Choice (MSQ)',
                        'Numerical / Integer Type',
                        'Assertion & Reason Type'
                      ].map((qt) => DropdownMenuItem(value: qt, child: Text(qt))).toList(),
                      onChanged: (val) => setState(() => _selectedQuestionType = val!),
                      decoration: InputDecoration(
                        hintText: 'Select Question Type',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Marks, Negative Marks & Has Image Switch Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Marks *', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _marksController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Negative Marks', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _negativeMarksController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Row(
                  children: [
                    Switch(
                      value: _hasImageDiagram,
                      activeColor: const Color(0xFF4F46E5),
                      onChanged: (val) => setState(() => _hasImageDiagram = val),
                    ),
                    const SizedBox(width: 8),
                    const Text('Has Image / Diagram?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSourcePill(String name, IconData icon, Color bg, Color iconColor) {
    final bool isSelected = _selectedSourceType == name;
    return GestureDetector(
      onTap: () => setState(() => _selectedSourceType = name),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? bg : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? iconColor : const Color(0xFFE2E8F0), width: isSelected ? 1.5 : 1.0),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? iconColor : const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(
              name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? iconColor : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyPill(String name, Color bg, Color activeColor) {
    final bool isSelected = _selectedDifficulty == name;
    return GestureDetector(
      onTap: () => setState(() => _selectedDifficulty = name),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? bg : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? activeColor : const Color(0xFFE2E8F0), width: isSelected ? 1.5 : 1.0),
        ),
        child: Text(
          name,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? activeColor : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // LEFT COLUMN: SECTION 2 - QUESTION STATEMENT
  // ==========================================
  Widget _buildSection2QuestionStatement() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.02), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('2. Question', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                  SizedBox(height: 2),
                  Text('Enter the question text. You can format text, add equations and images.', style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      _questionTextController.text += r' $E = m c^2$ ';
                    },
                    icon: const Icon(Icons.functions_rounded, size: 16, color: Color(0xFF4F46E5)),
                    label: const Text('∑ Add Equation', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF4F46E5))),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      side: const BorderSide(color: Color(0xFFC7D2FE)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add_photo_alternate_outlined, size: 16, color: Color(0xFF4F46E5)),
                    label: const Text('Add Image', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF4F46E5))),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      side: const BorderSide(color: Color(0xFFC7D2FE)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Rich Editor Toolbar Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
              border: Border(
                top: BorderSide(color: Color(0xFFE2E8F0)),
                left: BorderSide(color: Color(0xFFE2E8F0)),
                right: BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: const [
                  Text('Paragraph  v', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                  SizedBox(width: 12),
                  Text('B', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF334155))),
                  SizedBox(width: 12),
                  Text('I', style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, fontWeight: FontWeight.w800, color: Color(0xFF334155))),
                  SizedBox(width: 12),
                  Text('U', style: TextStyle(fontSize: 14, decoration: TextDecoration.underline, fontWeight: FontWeight.w800, color: Color(0xFF334155))),
                  SizedBox(width: 12),
                  Text('S', style: TextStyle(fontSize: 14, decoration: TextDecoration.lineThrough, color: Color(0xFF334155))),
                  SizedBox(width: 16),
                  Icon(Icons.format_list_bulleted_rounded, size: 18, color: Color(0xFF64748B)),
                  SizedBox(width: 12),
                  Icon(Icons.format_list_numbered_rounded, size: 18, color: Color(0xFF64748B)),
                  SizedBox(width: 16),
                  Icon(Icons.format_align_left_rounded, size: 18, color: Color(0xFF64748B)),
                  SizedBox(width: 12),
                  Icon(Icons.format_align_center_rounded, size: 18, color: Color(0xFF64748B)),
                  SizedBox(width: 16),
                  Text('X₂', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  SizedBox(width: 12),
                  Text('X²', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  SizedBox(width: 16),
                  Icon(Icons.link_rounded, size: 18, color: Color(0xFF64748B)),
                  SizedBox(width: 12),
                  Icon(Icons.image_outlined, size: 18, color: Color(0xFF64748B)),
                  SizedBox(width: 16),
                  Icon(Icons.undo_rounded, size: 18, color: Color(0xFF64748B)),
                  SizedBox(width: 12),
                  Icon(Icons.redo_rounded, size: 18, color: Color(0xFF64748B)),
                  SizedBox(width: 16),
                  Icon(Icons.fullscreen_rounded, size: 18, color: Color(0xFF64748B)),
                ],
              ),
            ),
          ),

          // Question Input Textarea
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0)),
                left: BorderSide(color: Color(0xFFE2E8F0)),
                right: BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _questionTextController,
                  maxLines: 5,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontSize: 13.5, color: Color(0xFF0F172A)),
                  decoration: const InputDecoration(
                    hintText: 'Type or paste your question here...',
                    hintStyle: TextStyle(fontSize: 13.5, color: Color(0xFF94A3B8)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(14),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 14, bottom: 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${_questionTextController.text.trim().isEmpty ? 0 : _questionTextController.text.trim().split(RegExp(r'\s+')).length} words',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // LEFT COLUMN: SECTION 3 - OPTIONS
  // ==========================================
  Widget _buildSection3Options() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.02), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('3. Options', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                  SizedBox(height: 2),
                  Text('Enter all the options for this question.', style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
                ],
              ),
              Row(
                children: [
                  const Text('Shuffle Options', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                  const SizedBox(width: 8),
                  Switch(
                    value: _shuffleOptions,
                    activeColor: const Color(0xFF4F46E5),
                    onChanged: (val) => setState(() => _shuffleOptions = val),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Option Rows
          ...List.generate(_optionsList.length, (index) {
            final opt = _optionsList[index];
            final String label = opt['label'];
            final TextEditingController ctrl = opt['controller'];

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Radio<String>(
                    value: label,
                    groupValue: _correctAnswerOption,
                    activeColor: const Color(0xFF4F46E5),
                    onChanged: (val) => setState(() => _correctAnswerOption = val!),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                    child: Center(
                      child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF334155))),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: ctrl,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        hintText: 'Option $label',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.image_outlined, size: 20, color: Color(0xFF64748B)),
                    onPressed: () {},
                    tooltip: 'Upload Option Image',
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF94A3B8)),
                    onPressed: () => _removeOption(index),
                    tooltip: 'Remove Option',
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 8),

          // + Add Option Button
          OutlinedButton.icon(
            onPressed: _addOption,
            icon: const Icon(Icons.add_rounded, size: 18, color: Color(0xFF4F46E5)),
            label: const Text('+ Add Option', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF4F46E5))),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              side: const BorderSide(color: Color(0xFFC7D2FE)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // RIGHT COLUMN: SECTION 4 - CORRECT ANSWER
  // ==========================================
  Widget _buildSection4CorrectAnswer() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.02), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('4. Correct Answer', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          const Text('Select the correct option.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 14),

          Row(
            children: _optionsList.map((opt) {
              final String label = opt['label'];
              final bool isSelected = _correctAnswerOption == label;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _correctAnswerOption = label),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0), width: isSelected ? 1.5 : 1.0),
                    ),
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                          color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // RIGHT COLUMN: SECTION 5 - EXPLANATION
  // ==========================================
  Widget _buildSection5Explanation() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.02), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('5. Explanation (Optional)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          const Text('Add explanation for the correct answer.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 14),

          TextField(
            controller: _explanationController,
            maxLines: 4,
            maxLength: 1000,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              hintText: 'Explain why this answer is correct...',
              hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // RIGHT COLUMN: SECTION 6 - TAGS
  // ==========================================
  Widget _buildSection6Tags() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.02), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('6. Tags', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          const Text('Add relevant tags to help in filtering.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 14),

          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ..._tags.map((t) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(t, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF4F46E5))),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => setState(() => _tags.remove(t)),
                          child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF6366F1)),
                        ),
                      ],
                    ),
                  )),
            ],
          ),

          const SizedBox(height: 10),

          TextField(
            controller: _tagInputController,
            onSubmitted: (val) {
              if (val.trim().isNotEmpty) {
                setState(() {
                  _tags.add(val.trim());
                  _tagInputController.clear();
                });
              }
            },
            decoration: InputDecoration(
              hintText: 'Select or type tags...',
              hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // RIGHT COLUMN: SECTION 7 - ADDITIONAL SETTINGS
  // ==========================================
  Widget _buildSection7AdditionalSettings() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.02), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('7. Additional Settings', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          const SizedBox(height: 12),

          _buildCheckboxItem('Is Active', _isActive, (v) => setState(() => _isActive = v!)),
          _buildCheckboxItem('Show in Custom Practice', _showInCustomPractice, (v) => setState(() => _showInCustomPractice = v!)),
          _buildCheckboxItem('Show in Custom Test', _showInCustomTest, (v) => setState(() => _showInCustomTest = v!)),
          _buildCheckboxItem('Show in PYQ Practice', _showInPYQPractice, (v) => setState(() => _showInPYQPractice = v!)),
          _buildCheckboxItem('Show in NTA Question Practice', _showInNTAQuestionPractice, (v) => setState(() => _showInNTAQuestionPractice = v!)),
          _buildCheckboxItem('Show in Test Series', _showInTestSeries, (v) => setState(() => _showInTestSeries = v!)),
        ],
      ),
    );
  }

  Widget _buildCheckboxItem(String label, bool value, ValueChanged<bool?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: value,
              activeColor: const Color(0xFF4F46E5),
              onChanged: onChanged,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // RIGHT COLUMN: IMPORTANT NOTES BOX
  // ==========================================
  Widget _buildImportantNotesBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFCE8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFEF08A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text('Important Notes', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF854D0E))),
            ],
          ),
          const SizedBox(height: 10),
          _buildNoteBullet('Ensure the question is accurate and error-free.'),
          _buildNoteBullet('Add relevant chapter and topic for better organization.'),
          _buildNoteBullet('You can edit this question later from the question list.'),
          const SizedBox(height: 12),
          const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFEAB308), size: 28),
        ],
      ),
    );
  }

  Widget _buildNoteBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF854D0E))),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF854D0E), height: 1.3)),
          ),
        ],
      ),
    );
  }
}
