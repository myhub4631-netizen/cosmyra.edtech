import 'package:flutter/material.dart';
import '../../core/services/supabase_service.dart';
import '../../models/models.dart';
import 'admin_bulk_upload_step2_screen.dart';

class AdminBulkUploadStep1Screen extends StatefulWidget {
  final UserProfileModel userProfile;
  final VoidCallback? onBack;
  final Function(Map<String, dynamic> paperDetails)? onProceedToStep2;

  const AdminBulkUploadStep1Screen({
    Key? key,
    required this.userProfile,
    this.onBack,
    this.onProceedToStep2,
  }) : super(key: key);

  @override
  State<AdminBulkUploadStep1Screen> createState() => _AdminBulkUploadStep1ScreenState();
}

class _AdminBulkUploadStep1ScreenState extends State<AdminBulkUploadStep1Screen> {
  // Form Controllers
  late TextEditingController _paperNameCtrl;
  late TextEditingController _paperCodeCtrl;
  late TextEditingController _questionCountCtrl;
  late TextEditingController _totalMarksCtrl;
  late TextEditingController _durationCtrl;
  late TextEditingController _negativeMarksCtrl;
  late TextEditingController _positiveMarksCtrl;
  late TextEditingController _instructionsCtrl;

  // Dropdown Values
  String _sourceCategory = 'PYQ';
  String _examName = 'NEET';
  String _year = '2026';
  String _phaseSession = 'Phase 1';
  String _paperType = 'Medical (UG)';
  String _language = 'English';
  String _conductingBody = 'NTA';
  String _negativeMarking = 'Yes';
  String? _paperShift;
  String? _difficultyDistribution;
  String _questionOrdering = 'Subject-wise';

  // Test Series Selection State
  String _testSeriesOption = 'existing'; // 'existing' or 'new'
  String _existingTestSeries = 'NEET 2026 Full Syllabus Test Series';
  late TextEditingController _newTestSeriesCtrl;

  // Checkboxes for subjects
  bool _subjectPhysics = true;
  bool _subjectChemistry = true;
  bool _subjectBotany = true;
  bool _subjectZoology = true;

  // Upload Method Radio
  String _uploadMethod = 'manual'; // 'manual', 'excel', 'paste'

  // Toggle Switch
  bool _showSectionBreaks = true;

  // Active Sidebar Item tracking
  String _activeSidebarItem = 'Question & Paper Bank';

  @override
  void initState() {
    super.initState();
    _paperNameCtrl = TextEditingController(text: 'NEET 2026 Phase 1');
    _paperCodeCtrl = TextEditingController(text: 'N26P1');
    _questionCountCtrl = TextEditingController(text: '200');
    _totalMarksCtrl = TextEditingController(text: '720');
    _durationCtrl = TextEditingController(text: '180');
    _negativeMarksCtrl = TextEditingController(text: '-4');
    _positiveMarksCtrl = TextEditingController(text: '+4');
    _instructionsCtrl = TextEditingController();
    _newTestSeriesCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _paperNameCtrl.dispose();
    _paperCodeCtrl.dispose();
    _questionCountCtrl.dispose();
    _totalMarksCtrl.dispose();
    _durationCtrl.dispose();
    _negativeMarksCtrl.dispose();
    _positiveMarksCtrl.dispose();
    _instructionsCtrl.dispose();
    _newTestSeriesCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleProceed() async {
    final String pName = _paperNameCtrl.text.trim().isNotEmpty ? _paperNameCtrl.text.trim() : 'NEET 2026 Phase 1';
    final String paperId = SupabaseService.toValidUuid('paper_${_examName}_${_year}_${_phaseSession}_$pName');

    final Map<String, dynamic> paperDetails = {
      'id': paperId,
      'sourceCategory': _sourceCategory,
      'examName': _examName,
      'year': _year,
      'phaseSession': _phaseSession,
      'paperType': _paperType,
      'paperName': pName,
      'paperCode': _paperCodeCtrl.text.trim(),
      'language': _language,
      'conductingBody': _conductingBody,
      'questionCount': int.tryParse(_questionCountCtrl.text) ?? 200,
      'totalMarks': int.tryParse(_totalMarksCtrl.text) ?? 720,
      'durationMinutes': int.tryParse(_durationCtrl.text) ?? 180,
      'negativeMarking': _negativeMarking == 'Yes',
      'negativeMarks': double.tryParse(_negativeMarksCtrl.text) ?? -4.0,
      'positiveMarks': double.tryParse(_positiveMarksCtrl.text) ?? 4.0,
      'subjects': [
        if (_subjectPhysics) 'Physics',
        if (_subjectChemistry) 'Chemistry',
        if (_subjectBotany) 'Botany',
        if (_subjectZoology) 'Zoology',
      ],
      'paperShift': _paperShift,
      'instructions': _instructionsCtrl.text,
      'uploadMethod': _uploadMethod,
      'difficultyDistribution': _difficultyDistribution,
      'questionOrdering': _questionOrdering,
      'showSectionBreaks': _showSectionBreaks,
    };

    try {
      await SupabaseService.savePaperRecord(paperDetails);
    } catch (e) {
      debugPrint('Notice saving paper record: $e');
    }

    if (widget.onProceedToStep2 != null) {
      widget.onProceedToStep2!(paperDetails);
    } else {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AdminBulkUploadStep2Screen(
            userProfile: widget.userProfile,
            paperRecord: paperDetails,
            paperName: pName,
            totalQuestionsCount: paperDetails['questionCount'] as int? ?? 200,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // 1. Top Navbar Header
          _buildTopHeader(),

          // 2. Main Content Split (Sidebar + Scrollable Form Area)
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Sidebar
                SizedBox(
                  width: 240,
                  child: _buildLeftSidebar(),
                ),

                // Vertical Divider
                Container(width: 1, color: const Color(0xFFE2E8F0)),

                // Right Scrollable Page Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Breadcrumbs
                        _buildBreadcrumbs(),

                        const SizedBox(height: 12),

                        // Title & Subtitle
                        Text(
                          'Upload Questions in Bulk - Step 1 of 2',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Enter paper details and settings. You will add questions in the next step.',
                          style: TextStyle(
                            fontSize: 14,
                            color: const Color(0xFF64748B),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Stepper Bar
                        _buildStepperBar(),

                        const SizedBox(height: 32),

                        // Card 1: Paper / Exam Details
                        _buildPaperExamDetailsCard(),

                        const SizedBox(height: 24),

                        // Card 2: Upload Options
                        _buildUploadOptionsCard(),

                        const SizedBox(height: 24),

                        // Card 3: Other Settings
                        _buildOtherSettingsCard(),

                        const SizedBox(height: 24),

                        // Tip Card
                        _buildTipCard(),

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
  // TOP NAVBAR HEADER WIDGET
  // ==========================================
  Widget _buildTopHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: App Brand Logo & Name
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Cosmyra Edu Admin',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),

          // Right: Notification Bell & Admin Profile
          Row(
            children: [
              // Notification Bell with red badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      color: Color(0xFF475569),
                      size: 22,
                    ),
                  ),
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: const Text(
                        '12',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 20),

              // Admin Avatar & User Info Dropdown
              InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&auto=format&fit=crop&q=80',
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Container(
                            width: 36,
                            height: 36,
                            color: const Color(0xFF6366F1),
                            child: const Icon(Icons.person, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Admin User',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Super Admin',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF64748B),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // LEFT SIDEBAR NAVIGATION WIDGET
  // ==========================================
  Widget _buildLeftSidebar() {
    return Container(
      color: Colors.white,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // Single top item
          _buildSidebarItem('Dashboard', Icons.space_dashboard_outlined),

          const SizedBox(height: 16),
          _buildSidebarSectionHeader('CONTENT MANAGEMENT'),
          _buildSidebarItem('Exams', Icons.assignment_outlined),
          _buildSidebarItem('Subjects', Icons.tune_outlined),
          _buildSidebarItem('Chapters', Icons.menu_book_outlined),
          _buildSidebarItem('Topics', Icons.topic_outlined),
          _buildSidebarItem('Question & Paper Bank', Icons.quiz_outlined, isActive: true),
          _buildSidebarItem('NTA Mock Papers', Icons.collections_bookmark_outlined),

          const SizedBox(height: 16),
          _buildSidebarSectionHeader('PRACTICE & TEST'),
          _buildSidebarItem('Custom Practice', Icons.edit_note_outlined),
          _buildSidebarItem('Custom Tests', Icons.timer_outlined),
          _buildSidebarItem('PYQ Practice', Icons.history_edu_outlined),
          _buildSidebarItem('Test Series', Icons.track_changes_outlined),
          _buildSidebarItem('Mock Tests', Icons.fact_check_outlined),

          const SizedBox(height: 16),
          _buildSidebarSectionHeader('TEST MANAGEMENT'),
          _buildSidebarItem('Test Attempts', Icons.assignment_turned_in_outlined),
          _buildSidebarItem('Analytics', Icons.bar_chart_outlined),

          const SizedBox(height: 16),
          _buildSidebarSectionHeader('USER MANAGEMENT'),
          _buildSidebarItem('Users', Icons.people_outline_rounded),
          _buildSidebarItem('Roles & Permissions', Icons.key_outlined),

          const SizedBox(height: 16),
          _buildSidebarSectionHeader('OTHER'),
          _buildSidebarItem('Settings', Icons.settings_outlined),
          _buildSidebarItem('Logs', Icons.grid_view_outlined),
          _buildSidebarItem('Help & Support', Icons.help_outline_rounded),
        ],
      ),
    );
  }

  Widget _buildSidebarSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF94A3B8),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildSidebarItem(String title, IconData icon, {bool isActive = false}) {
    final bool selected = isActive || (_activeSidebarItem == title);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFEEF2FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        minLeadingWidth: 24,
        leading: Icon(
          icon,
          size: 18,
          color: selected ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            color: selected ? const Color(0xFF4F46E5) : const Color(0xFF334155),
          ),
        ),
        onTap: () {
          setState(() {
            _activeSidebarItem = title;
          });
          if (title == 'Dashboard' && widget.onBack != null) {
            widget.onBack!();
          }
        },
      ),
    );
  }

  // ==========================================
  // BREADCRUMBS WIDGET
  // ==========================================
  Widget _buildBreadcrumbs() {
    return Row(
      children: const [
        Text(
          'Question & Paper Bank',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: 8),
        Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
        SizedBox(width: 8),
        Text(
          'Upload Questions',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF475569),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // STEPPER BAR WIDGET
  // ==========================================
  Widget _buildStepperBar() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Step 1 Circle + Label
            Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4F46E5),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '1',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Paper Details',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4F46E5),
                  ),
                ),
              ],
            ),

            // Dotted Connecting Line
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24, left: 12, right: 12),
                child: CustomPaint(
                  size: const Size(double.infinity, 2),
                  painter: DashedLinePainter(color: const Color(0xFFCBD5E1)),
                ),
              ),
            ),

            // Step 2 Circle + Label
            Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                  ),
                  child: const Center(
                    child: Text(
                      '2',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add Questions',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // CARD 1: PAPER / EXAM DETAILS
  // ==========================================
  Widget _buildPaperExamDetailsCard() {
    return _buildCardContainer(
      title: 'Paper / Exam Details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1 (5 Dropdowns)
          LayoutBuilder(
            builder: (context, constraints) {
              return _buildResponsiveGrid(
                constraints: constraints,
                columns: 5,
                children: [
                  _buildDropdownField(
                    label: 'Source Category *',
                    value: _sourceCategory,
                    items: ['PYQ', 'NTA', 'Questions', 'Test Series'],
                    onChanged: (val) {
                      setState(() {
                        _sourceCategory = val!;
                        if (_sourceCategory == 'PYQ' && !['NEET', 'JEE Main', 'JEE Advanced', 'AIIMS'].contains(_examName)) {
                          _examName = 'NEET';
                        }
                      });
                    },
                  ),
                  _buildDropdownField(
                    label: 'Exam Name *',
                    value: ['NEET', 'JEE Main', 'JEE Advanced', 'AIIMS', 'CUET', 'CBSE 12'].contains(_examName) ? _examName : 'NEET',
                    items: _sourceCategory == 'PYQ'
                        ? ['NEET', 'JEE Main', 'JEE Advanced', 'AIIMS']
                        : ['NEET', 'JEE Main', 'JEE Advanced', 'AIIMS', 'CUET', 'CBSE 12'],
                    onChanged: (val) => setState(() => _examName = val!),
                  ),
                  _buildDropdownField(
                    label: 'Year *',
                    value: _year,
                    items: ['2026', '2025', '2024', '2023', '2022'],
                    onChanged: (val) => setState(() => _year = val!),
                  ),
                  _buildDropdownField(
                    label: 'Phase / Session *',
                    value: _phaseSession,
                    items: ['Phase 1', 'Phase 2', 'Session 1', 'Session 2', 'Full Paper'],
                    onChanged: (val) => setState(() => _phaseSession = val!),
                  ),
                  _buildDropdownField(
                    label: 'Paper Type *',
                    value: _paperType,
                    items: ['Medical (UG)', 'Engineering', 'Foundation', 'Board'],
                    onChanged: (val) => setState(() => _paperType = val!),
                  ),
                ],
              );
            },
          ),

          // Conditional Test Series Card Block (When Source Category == 'Test Series')
          if (_sourceCategory == 'Test Series') ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFC7D2FE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Test Series Option *',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF3730A3)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Row(
                        children: [
                          Radio<String>(
                            value: 'existing',
                            groupValue: _testSeriesOption,
                            activeColor: const Color(0xFF4F46E5),
                            onChanged: (val) => setState(() => _testSeriesOption = val!),
                          ),
                          const Text('Select Existing Test Series', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E1B4B))),
                        ],
                      ),
                      const SizedBox(width: 24),
                      Row(
                        children: [
                          Radio<String>(
                            value: 'new',
                            groupValue: _testSeriesOption,
                            activeColor: const Color(0xFF4F46E5),
                            onChanged: (val) => setState(() => _testSeriesOption = val!),
                          ),
                          const Text('Create New Test Series', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E1B4B))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_testSeriesOption == 'existing')
                    _buildDropdownField(
                      label: 'Select Test Series *',
                      value: _existingTestSeries,
                      items: [
                        'NEET 2026 Full Syllabus Test Series',
                        'NEET 2026 Chapter Wise Test Series',
                        'NEET 2026 Topic Wise Test Series',
                        'NEET 2026 Previous Year Papers',
                      ],
                      onChanged: (val) => setState(() => _existingTestSeries = val!),
                    )
                  else
                    _buildTextField(
                      label: 'New Test Series Title *',
                      controller: _newTestSeriesCtrl,
                    ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Row 2 (5 Fields)
          LayoutBuilder(
            builder: (context, constraints) {
              return _buildResponsiveGrid(
                constraints: constraints,
                columns: 5,
                children: [
                  _buildTextField(
                    label: 'Paper Name *',
                    controller: _paperNameCtrl,
                  ),
                  _buildTextField(
                    label: 'Paper Code (Optional)',
                    controller: _paperCodeCtrl,
                  ),
                  _buildDropdownField(
                    label: 'Language *',
                    value: _language,
                    items: ['English', 'Hindi', 'Bilingual'],
                    onChanged: (val) => setState(() => _language = val!),
                  ),
                  _buildDropdownField(
                    label: 'Conducting Body *',
                    value: _conductingBody,
                    items: ['NTA', 'CBSE', 'State Board', 'Cosmyra'],
                    onChanged: (val) => setState(() => _conductingBody = val!),
                  ),
                  _buildTextField(
                    label: 'Question Count *',
                    controller: _questionCountCtrl,
                    keyboardType: TextInputType.number,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          // Row 3 (5 Fields)
          LayoutBuilder(
            builder: (context, constraints) {
              return _buildResponsiveGrid(
                constraints: constraints,
                columns: 5,
                children: [
                  _buildTextField(
                    label: 'Total Marks *',
                    controller: _totalMarksCtrl,
                    keyboardType: TextInputType.number,
                  ),
                  _buildTextField(
                    label: 'Duration (Minutes) *',
                    controller: _durationCtrl,
                    keyboardType: TextInputType.number,
                  ),
                  _buildDropdownField(
                    label: 'Negative Marking *',
                    value: _negativeMarking,
                    items: ['Yes', 'No'],
                    onChanged: (val) => setState(() => _negativeMarking = val!),
                  ),
                  _buildTextField(
                    label: 'Negative Marks',
                    controller: _negativeMarksCtrl,
                  ),
                  _buildTextField(
                    label: 'Positive Marks',
                    controller: _positiveMarksCtrl,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // Row 4: Split Subjects Checkboxes + Paper Shift Dropdown
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Subjects Checkboxes
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Subjects In This Paper (Select all that apply) *'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        _buildCheckboxItem('Physics', _subjectPhysics, (v) => setState(() => _subjectPhysics = v!)),
                        _buildCheckboxItem('Chemistry', _subjectChemistry, (v) => setState(() => _subjectChemistry = v!)),
                        _buildCheckboxItem('Botany', _subjectBotany, (v) => setState(() => _subjectBotany = v!)),
                        _buildCheckboxItem('Zoology', _subjectZoology, (v) => setState(() => _subjectZoology = v!)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 24),

              // Right: Paper Shift Dropdown
              Expanded(
                flex: 4,
                child: _buildDropdownField(
                  label: 'Paper Shift (If Applicable)',
                  value: _paperShift,
                  hintText: 'Select Shift',
                  items: ['Select Shift', 'Shift 1 (Morning)', 'Shift 2 (Afternoon)', 'N/A'],
                  onChanged: (val) => setState(() => _paperShift = val == 'Select Shift' ? null : val),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Row 5: Instructions
          _buildFieldLabel('Instructions (Optional)'),
          const SizedBox(height: 8),
          TextField(
            controller: _instructionsCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Enter paper instructions or notes...',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // CARD 2: UPLOAD OPTIONS
  // ==========================================
  Widget _buildUploadOptionsCard() {
    return _buildCardContainer(
      title: 'Upload Options',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column: Upload Method Radio Buttons
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Upload Method',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                _buildRadioButton(
                  title: 'Enter Questions Manually',
                  value: 'manual',
                  groupValue: _uploadMethod,
                  onChanged: (val) => setState(() => _uploadMethod = val!),
                ),
                const SizedBox(height: 8),
                _buildRadioButton(
                  title: 'Upload from Excel / CSV',
                  value: 'excel',
                  groupValue: _uploadMethod,
                  onChanged: (val) => setState(() => _uploadMethod = val!),
                ),
                const SizedBox(height: 8),
                _buildRadioButton(
                  title: 'Copy & Paste',
                  value: 'paste',
                  groupValue: _uploadMethod,
                  onChanged: (val) => setState(() => _uploadMethod = val!),
                ),
              ],
            ),
          ),

          const SizedBox(width: 24),

          // Right Column: Recommended Excel Banner Box
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3FF), // Soft indigo tint
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE0E7FF), width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFC7D2FE)),
                    ),
                    child: const Icon(
                      Icons.article_outlined,
                      color: Color(0xFF4F46E5),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recommended Excel Format',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Download our sample Excel file and fill your questions.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Downloading sample Excel file...'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.download_rounded, size: 16, color: Color(0xFF4F46E5)),
                          label: const Text(
                            'Download Sample File',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4F46E5),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFF4F46E5), width: 1.2),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // CARD 3: OTHER SETTINGS & ACTIONS
  // ==========================================
  Widget _buildOtherSettingsCard() {
    return _buildCardContainer(
      title: 'Other Settings',
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Col 1: Difficulty Distribution
              Expanded(
                child: _buildDropdownField(
                  label: 'Difficulty Distribution (Optional)',
                  value: _difficultyDistribution,
                  hintText: 'Select Difficulty Distribution',
                  items: [
                    'Select Difficulty Distribution',
                    'Standard (30% Easy, 50% Medium, 20% Hard)',
                    'Balanced (33% Each)',
                    'Custom'
                  ],
                  onChanged: (val) => setState(() => _difficultyDistribution = val == 'Select Difficulty Distribution' ? null : val),
                ),
              ),

              const SizedBox(width: 20),

              // Col 2: Question Ordering
              Expanded(
                child: _buildDropdownField(
                  label: 'Question Ordering',
                  value: _questionOrdering,
                  items: ['Subject-wise', 'Randomized', 'Sequential'],
                  onChanged: (val) => setState(() => _questionOrdering = val!),
                ),
              ),

              const SizedBox(width: 20),

              // Col 3: Show Section / Subject Breaks
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Show Section / Subject Breaks'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Transform.scale(
                          scale: 0.85,
                          child: Switch(
                            value: _showSectionBreaks,
                            activeColor: Colors.white,
                            activeTrackColor: const Color(0xFF4F46E5),
                            inactiveTrackColor: const Color(0xFFCBD5E1),
                            onChanged: (val) => setState(() => _showSectionBreaks = val),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _showSectionBreaks ? 'Yes' : 'No',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Bottom Action Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Cancel Button
              OutlinedButton(
                onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
              ),

              // Right: Proceed Button
              ElevatedButton.icon(
                onPressed: _handleProceed,
                icon: const Text(
                  'Proceed to Add Questions',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                label: const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TIP CARD WIDGET
  // ==========================================
  Widget _buildTipCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E7FF)),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFC7D2FE)),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFF4F46E5),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Tip: After clicking "Proceed to Add Questions", you will be able to add 200 questions one by one.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4338CA),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // HELPER REUSABLE WIDGETS
  // ==========================================
  Widget _buildCardContainer({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.02),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    final bool isRequired = label.contains('*');
    if (!isRequired) {
      return Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF334155),
        ),
      );
    }

    final String textWithoutAsterisk = label.replaceAll('*', '').trim();
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: textWithoutAsterisk,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          const TextSpan(
            text: ' *',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFFEF4444),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label),
        const SizedBox(height: 6),
        SizedBox(
          height: 42,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? hintText,
  }) {
    final String displayValue = value ?? hintText ?? items.first;
    final bool isHintSelected = (value == null && hintText != null) || displayValue == hintText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label),
        const SizedBox(height: 6),
        SizedBox(
          height: 42,
          child: DropdownButtonFormField<String>(
            value: items.contains(displayValue) ? displayValue : items.first,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B), size: 20),
            style: TextStyle(
              fontSize: 13,
              color: isHintSelected ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
              fontWeight: isHintSelected ? FontWeight.normal : FontWeight.w500,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
              ),
            ),
            items: items.map((item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: TextStyle(
                    color: (item == hintText) ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxItem(String title, bool value, ValueChanged<bool?> onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: value,
            activeColor: const Color(0xFF4F46E5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildRadioButton({
    required String title,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    final bool selected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Radio<String>(
              value: value,
              groupValue: groupValue,
              activeColor: const Color(0xFF4F46E5),
              onChanged: onChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected ? const Color(0xFF0F172A) : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveGrid({
    required BoxConstraints constraints,
    required int columns,
    required List<Widget> children,
  }) {
    if (constraints.maxWidth > 900) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children.map((w) => Expanded(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: w,
        ))).toList(),
      );
    } else {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: children.map((w) => SizedBox(width: (constraints.maxWidth - 24) / 2, child: w)).toList(),
      );
    }
  }
}

// Custom Painter for Stepper Dashed Line
class DashedLinePainter extends CustomPainter {
  final Color color;
  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    double dashWidth = 4, dashSpace = 4, startX = 0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
