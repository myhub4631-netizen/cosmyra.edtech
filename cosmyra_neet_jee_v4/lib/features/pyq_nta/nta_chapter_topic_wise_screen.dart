import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../core/services/supabase_service.dart';

class NtaChapterTopicWiseScreen extends StatefulWidget {
  final String activeExam;
  final VoidCallback? onBack;
  final Function(List<QuestionModel> questions, int timerMinutes, bool isTestMode)? onStartSession;

  const NtaChapterTopicWiseScreen({
    Key? key,
    this.activeExam = 'NEET 2026',
    this.onBack,
    this.onStartSession,
  }) : super(key: key);

  @override
  State<NtaChapterTopicWiseScreen> createState() => _NtaChapterTopicWiseScreenState();
}

class _NtaChapterTopicWiseScreenState extends State<NtaChapterTopicWiseScreen> {
  late String _selectedExam;
  String _selectedSubject = 'Physics';
  String _searchQuery = '';

  bool _isLoading = true;
  List<Map<String, dynamic>> _chaptersList = [];
  final Set<String> _expandedChapterIds = {};

  @override
  void initState() {
    super.initState();
    _selectedExam = widget.activeExam.contains('NEET') ? 'NEET 2026' : 'JEE Main 2026';
    _loadTaxonomyData();
  }

  Future<void> _loadTaxonomyData() async {
    setState(() => _isLoading = true);
    try {
      final cleanExam = _selectedExam.contains('JEE') ? 'JEE Main' : 'NEET';
      final rawChapters = await SupabaseService.fetchTaxonomyForSubject(
        exam: cleanExam,
        subject: _selectedSubject,
        forceRefresh: true,
      );

      final List<Map<String, dynamic>> formatted = [];

      for (int i = 0; i < rawChapters.length; i++) {
        final c = rawChapters[i];
        final rawTopics = (c['topicsList'] as List?)?.cast<Map<String, dynamic>>() ?? [];

        final subtopics = rawTopics.map((t) {
          return {
            'id': t['id'] ?? '',
            'name': t['name'] ?? '',
            'questionsCount': (t['questionsCount'] as int?) ?? 20,
            'isSelected': true,
          };
        }).toList();

        // Default mock counts if subtopics list is empty for demo completeness
        final fallbackTopics = subtopics.isNotEmpty
            ? subtopics
            : [
                {'id': 'tp_1', 'name': 'Kinematics', 'questionsCount': 24, 'isSelected': true},
                {'id': 'tp_2', 'name': 'Laws of Motion', 'questionsCount': 28, 'isSelected': true},
                {'id': 'tp_3', 'name': 'Work, Energy and Power', 'questionsCount': 20, 'isSelected': true},
                {'id': 'tp_4', 'name': 'System of Particles', 'questionsCount': 18, 'isSelected': true},
                {'id': 'tp_5', 'name': 'Gravitation', 'questionsCount': 16, 'isSelected': true},
                {'id': 'tp_6', 'name': 'Properties of Matter', 'questionsCount': 20, 'isSelected': true},
              ];

        final chId = c['id']?.toString() ?? 'ch_$i';
        formatted.add({
          'id': chId,
          'name': c['name'] ?? 'Chapter ${i + 1}',
          'isSelected': true,
          'subtopics': fallbackTopics,
        });
      }

      if (mounted) {
        setState(() {
          _chaptersList = formatted;
          if (_chaptersList.isNotEmpty) {
            _expandedChapterIds.add(_chaptersList.first['id']);
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onExamChanged(String? newExam) {
    if (newExam == null) return;
    setState(() {
      _selectedExam = newExam;
      if (newExam.contains('JEE') && _selectedSubject == 'Biology') {
        _selectedSubject = 'Physics';
      }
    });
    _loadTaxonomyData();
  }

  void _onSubjectChanged(String? newSub) {
    if (newSub == null) return;
    setState(() {
      _selectedSubject = newSub;
    });
    _loadTaxonomyData();
  }

  int get _selectedChaptersCount {
    return _chaptersList.where((c) {
      final sub = (c['subtopics'] as List?) ?? [];
      return sub.any((t) => t['isSelected'] == true);
    }).length;
  }

  int get _selectedTopicsCount {
    int total = 0;
    for (var c in _chaptersList) {
      final sub = (c['subtopics'] as List?) ?? [];
      total += sub.where((t) => t['isSelected'] == true).length;
    }
    return total;
  }

  int get _selectedQuestionsCount {
    int total = 0;
    for (var c in _chaptersList) {
      final sub = (c['subtopics'] as List?) ?? [];
      for (var t in sub) {
        if (t['isSelected'] == true) {
          total += (t['questionsCount'] as int? ?? 20);
        }
      }
    }
    return total;
  }

  void _continueToPractice() async {
    final cleanExam = _selectedExam.contains('JEE') ? 'JEE Main' : 'NEET';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Preparing practice session for $_selectedChaptersCount Chapters & $_selectedTopicsCount Topics...'),
        duration: const Duration(seconds: 1),
      ),
    );

    final questions = await SupabaseService.fetchPYQQuestions(
      exam: cleanExam,
      subjects: [_selectedSubject],
      limit: 30,
    );

    if (widget.onStartSession != null) {
      widget.onStartSession!(questions, 45, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjectsList = _selectedExam.contains('JEE')
        ? ['Physics', 'Chemistry', 'Mathematics']
        : ['Physics', 'Chemistry', 'Biology'];

    final filteredChapters = _searchQuery.isEmpty
        ? _chaptersList
        : _chaptersList.where((c) {
            final nameMatch = (c['name'] as String).toLowerCase().contains(_searchQuery.toLowerCase());
            final subtopics = (c['subtopics'] as List?) ?? [];
            final topicMatch = subtopics.any((t) => (t['name'] as String).toLowerCase().contains(_searchQuery.toLowerCase()));
            return nameMatch || topicMatch;
          }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFD),
      body: SafeArea(
        child: Column(
          children: [
            // Top Header Bar
            _buildHeaderBar(),

            // Step Progress Indicator Bar
            _buildStepProgressBar(),

            const SizedBox(height: 14),

            // Scrollable Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
                  : RefreshIndicator(
                      onRefresh: _loadTaxonomyData,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        physics: const BouncingScrollPhysics(),
                        children: [
                          // Exam & Subject Dropdowns Row
                          _buildExamSubjectDropdowns(subjectsList),

                          const SizedBox(height: 14),

                          // Search Bar & Filter Button Row
                          _buildSearchBarWithFilter(),

                          const SizedBox(height: 16),

                          // Accordion Chapters List
                          ...filteredChapters.map((ch) {
                            final chId = ch['id'].toString();
                            final isExpanded = _expandedChapterIds.contains(chId);
                            final subtopics = (ch['subtopics'] as List?) ?? [];
                            final selectedSubCount = subtopics.where((t) => t['isSelected'] == true).length;
                            final isAllSubSelected = subtopics.isNotEmpty && selectedSubCount == subtopics.length;
                            final isPartialSelected = selectedSubCount > 0 && !isAllSubSelected;

                            final totalQs = subtopics.fold<int>(0, (sum, t) => sum + ((t['questionsCount'] as int?) ?? 20));

                            return _buildChapterAccordionCard(
                              chapterId: chId,
                              title: ch['name'] ?? '',
                              topicsCount: subtopics.length,
                              questionsCount: totalQs,
                              isExpanded: isExpanded,
                              isChecked: isAllSubSelected,
                              isTristate: isPartialSelected,
                              subtopics: subtopics,
                              onHeaderTap: () {
                                setState(() {
                                  if (isExpanded) {
                                    _expandedChapterIds.remove(chId);
                                  } else {
                                    _expandedChapterIds.add(chId);
                                  }
                                });
                              },
                              onCheckboxTap: () {
                                setState(() {
                                  final targetVal = !isAllSubSelected;
                                  ch['isSelected'] = targetVal;
                                  for (var t in subtopics) {
                                    t['isSelected'] = targetVal;
                                  }
                                });
                              },
                              onTopicCheckTap: (tIdx) {
                                setState(() {
                                  subtopics[tIdx]['isSelected'] = !(subtopics[tIdx]['isSelected'] ?? false);
                                });
                              },
                            );
                          }).toList(),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
            ),

            // Bottom Selection Summary Bar & Action Button
            _buildBottomSummaryBar(),
          ],
        ),
      ),
    );
  }

  // Header Bar
  Widget _buildHeaderBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
            'Chapter & Topic Practice/Test',
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
                const SnackBar(content: Text('Select chapters and topics to practice.')),
              );
            },
          ),
        ],
      ),
    );
  }

  // Step Progress Indicator Bar
  Widget _buildStepProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Column(
        children: [
          Row(
            children: [
              // Step 1: Green Checked Circle
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
              ),

              // Green to Purple Line
              Expanded(
                child: Container(
                  height: 3,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF4F46E5)],
                    ),
                  ),
                ),
              ),

              // Step 2: Purple Active Circle
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFF4F46E5),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '2',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),

              // Dashed Line to Step 3
              Expanded(
                child: Row(
                  children: List.generate(8, (index) {
                    return Expanded(
                      child: Container(
                        height: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        color: const Color(0xFFCBD5E1),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Step Labels Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Exam, Subject\n& Mode',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500, color: Color(0xFF64748B), height: 1.2),
              ),
              Text(
                'Select\nChapters & Topics',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5), height: 1.2),
              ),
              SizedBox(width: 40),
            ],
          ),
        ],
      ),
    );
  }

  // Exam & Subject Dropdowns
  Widget _buildExamSubjectDropdowns(List<String> subjectsList) {
    return Row(
      children: [
        // Exam Dropdown
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEEF2FF)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedExam,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF4338CA), size: 20),
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF4338CA)),
                onChanged: _onExamChanged,
                items: ['NEET 2026', 'NEET 2025', 'JEE Main 2026', 'JEE Main 2025'].map((e) {
                  return DropdownMenuItem<String>(
                    value: e,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Exam', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.normal)),
                        Text(e, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF4338CA))),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Subject Dropdown
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEEF2FF)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedSubject,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF4338CA), size: 20),
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF4338CA)),
                onChanged: _onSubjectChanged,
                items: subjectsList.map((s) {
                  return DropdownMenuItem<String>(
                    value: s,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Subject', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.normal)),
                        Text(s, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF4338CA))),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Search Bar with Filter Icon Button
  Widget _buildSearchBarWithFilter() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, size: 20, color: Color(0xFF94A3B8)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: const InputDecoration(
                      hintText: 'Search chapters or topics...',
                      hintStyle: TextStyle(fontSize: 13.5, color: Color(0xFF94A3B8)),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: IconButton(
            icon: const Icon(Icons.tune_rounded, color: Color(0xFF4F46E5), size: 20),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Filter settings opened.')),
              );
            },
          ),
        ),
      ],
    );
  }

  // Chapter Accordion Card
  Widget _buildChapterAccordionCard({
    required String chapterId,
    required String title,
    required int topicsCount,
    required int questionsCount,
    required bool isExpanded,
    required bool isChecked,
    required bool isTristate,
    required List<dynamic> subtopics,
    required VoidCallback onHeaderTap,
    required VoidCallback onCheckboxTap,
    required Function(int tIdx) onTopicCheckTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isExpanded ? const Color(0xFFEEF2FF) : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x04000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          // Header Card Row
          InkWell(
            onTap: onHeaderTap,
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(14),
              bottom: Radius.circular(isExpanded ? 0 : 14),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: isExpanded ? const Color(0xFFF5F3FF) : Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(14),
                  bottom: Radius.circular(isExpanded ? 0 : 14),
                ),
              ),
              child: Row(
                children: [
                  // Checkbox
                  InkWell(
                    onTap: onCheckboxTap,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: isChecked || isTristate ? const Color(0xFF4F46E5) : Colors.white,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: isChecked || isTristate ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8),
                          width: 1.5,
                        ),
                      ),
                      child: isChecked
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                          : (isTristate
                              ? const Icon(Icons.remove_rounded, color: Colors.white, size: 14)
                              : null),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Title
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Stats (6 Topics • 126 Qs)
                  Text(
                    '$topicsCount Topics  •  $questionsCount Qs',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Chevron Arrow Up/Down
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF0F172A),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Subtopics Expanded List
          if (isExpanded && subtopics.isNotEmpty) ...[
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: subtopics.asMap().entries.map((entry) {
                  final tIdx = entry.key;
                  final topic = entry.value;
                  final isSubSel = topic['isSelected'] == true;
                  final qCount = (topic['questionsCount'] as int?) ?? 20;

                  return InkWell(
                    onTap: () => onTopicCheckTap(tIdx),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          const SizedBox(width: 14),
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: isSubSel ? const Color(0xFF4F46E5) : Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isSubSel ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8),
                                width: 1.5,
                              ),
                            ),
                            child: isSubSel
                                ? const Icon(Icons.check_rounded, color: Colors.white, size: 13)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              topic['name'] ?? '',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: isSubSel ? FontWeight.w600 : FontWeight.w400,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          Text(
                            '$qCount Qs',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6366F1),
                            ),
                          ),
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
  }

  // Bottom Summary Bar & Action Button
  Widget _buildBottomSummaryBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1.0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Selected Summary Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Selected: ',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
              ),
              Text(
                '$_selectedChaptersCount Chapters  •  $_selectedTopicsCount Topics  •  $_selectedQuestionsCount Questions',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4F46E5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Main Action Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _selectedChaptersCount > 0 ? _continueToPractice : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                elevation: 3,
                shadowColor: const Color(0x404F46E5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
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
        ],
      ),
    );
  }
}
