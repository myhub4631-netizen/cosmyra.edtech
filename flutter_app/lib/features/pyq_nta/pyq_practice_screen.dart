import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/models.dart';
import '../../models/pyq_models.dart';
import '../../core/services/supabase_service.dart';
import '../../shared/widgets/app_sidebar.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/utils/neet_subject_helper.dart';

class ChapterItem {
  final String id;
  final String name;
  final List<TopicItem> topics;
  bool isExpanded;
  bool isSelected;

  ChapterItem({
    required this.id,
    required this.name,
    required this.topics,
    this.isExpanded = true,
    this.isSelected = false,
  });

  bool get isFullySelected {
    if (topics.isEmpty) return isSelected;
    return isSelected || topics.every((t) => t.isSelected);
  }

  bool get isPartiallySelected {
    if (topics.isEmpty) return false;
    return !isFullySelected && topics.any((t) => t.isSelected);
  }

  int get selectedTopicCount => topics.where((t) => t.isSelected).length;
}

class TopicItem {
  final String id;
  final String name;
  final String chapterId;
  final String chapterName;
  bool isSelected;

  TopicItem({
    required this.id,
    required this.name,
    required this.chapterId,
    required this.chapterName,
    this.isSelected = false,
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
  int _currentStep = 1; // 1 = Practice Mode, 2 = Select Subjects, 3 = Chapters/Topics or Paper Selection

  late String _selectedExam;
  late Set<String> _selectedSubjects;
  PYQPracticeMode _selectedMode = PYQPracticeMode.chapterWise;

  int _questionCount = 20;
  String _difficulty = 'Medium';

  bool _isLoadingStats = true;
  bool _isLoadingTaxonomy = true;
  bool _isLoadingPapers = false;
  bool _isStarting = false;

  int _availableQuestionsCount = 1248;
  int _availablePapersCount = 98;
  double _userAccuracy = 72.4;
  int _timeSpentSeconds = 101700;
  Map<String, int> _subjectPYQCounts = {};

  String _searchQuery = '';
  int _activeViewTab = 0; // 0 = Chapters, 1 = Topics

  // Multi-Subject Chapters Map (PCB for NEET, PCM for JEE)
  Map<String, List<ChapterItem>> _subjectChaptersMap = {};
  String _activeStep3Subject = 'Physics';

  List<Map<String, dynamic>> _savedPresets = [];

  // Paper-wise Mode State
  List<Map<String, dynamic>> _availablePaperRecords = [];
  Map<String, dynamic>? _selectedPaperRecord;

  @override
  void initState() {
    super.initState();
    _selectedExam = widget.activeExam.contains('JEE') ? 'JEE Main 2026' : 'NEET 2026';
    _selectedSubjects = _selectedExam.contains('NEET')
        ? {'Physics', 'Chemistry', 'Biology'}
        : {'Physics', 'Chemistry', 'Mathematics'};
    _activeStep3Subject = 'Physics';
    _loadStats();
    _initChapters();
    _loadAvailablePapers();
    _loadSavedPresets();
  }

  Future<void> _loadSavedPresets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('pyq_practice_presets');
      if (str != null && str.isNotEmpty) {
        final List list = jsonDecode(str);
        if (mounted) {
          setState(() {
            _savedPresets = List<Map<String, dynamic>>.from(list);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading saved presets: $e');
    }
  }

  Future<void> _savePresetToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pyq_practice_presets', jsonEncode(_savedPresets));
    } catch (e) {
      debugPrint('Error saving preset to prefs: $e');
    }
  }

  Future<void> _loadAvailablePapers() async {
    setState(() => _isLoadingPapers = true);
    final papers = await SupabaseService.fetchAllPapersAndTestSeries(
      exam: _selectedExam,
      forceRefresh: true,
    );

    final isNeet = _selectedExam.contains('NEET');
    final List<Map<String, dynamic>> canonicalList = isNeet
        ? [
            {
              'id': 'neet_2026_phase_1',
              'name': 'NEET 2026 Phase 1',
              'title': 'NEET 2026 Phase 1',
              'year': 2026,
              'exam': 'NEET 2026',
              'questionsCount': 180,
              'subjects': ['Physics', 'Chemistry', 'Biology'],
            },
            {
              'id': 'neet_2026_reneet',
              'name': 'NEET 2026 Re-NEET',
              'title': 'NEET 2026 Re-NEET',
              'year': 2026,
              'exam': 'NEET 2026',
              'questionsCount': 180,
              'subjects': ['Physics', 'Chemistry', 'Biology'],
            },
            {
              'id': 'neet_2025_paper_1',
              'name': 'NEET 2025 (Official PYQ)',
              'title': 'NEET 2025 (Official PYQ)',
              'year': 2025,
              'exam': 'NEET 2025',
              'questionsCount': 200,
              'subjects': ['Physics', 'Chemistry', 'Biology'],
            },
            {
              'id': 'neet_2024_paper_1',
              'name': 'NEET 2024 (Official PYQ)',
              'title': 'NEET 2024 (Official PYQ)',
              'year': 2024,
              'exam': 'NEET 2024',
              'questionsCount': 200,
              'subjects': ['Physics', 'Chemistry', 'Biology'],
            },
            {
              'id': 'neet_2023_paper_1',
              'name': 'NEET 2023 (Official PYQ)',
              'title': 'NEET 2023 (Official PYQ)',
              'year': 2023,
              'exam': 'NEET 2023',
              'questionsCount': 200,
              'subjects': ['Physics', 'Chemistry', 'Biology'],
            },
            {
              'id': 'neet_2022_paper_1',
              'name': 'NEET 2022 (Official PYQ)',
              'title': 'NEET 2022 (Official PYQ)',
              'year': 2022,
              'exam': 'NEET 2022',
              'questionsCount': 200,
              'subjects': ['Physics', 'Chemistry', 'Biology'],
            },
            {
              'id': 'neet_2021_paper_1',
              'name': 'NEET 2021 (Official PYQ)',
              'title': 'NEET 2021 (Official PYQ)',
              'year': 2021,
              'exam': 'NEET 2021',
              'questionsCount': 200,
              'subjects': ['Physics', 'Chemistry', 'Biology'],
            },
          ]
        : [
            {
              'id': 'jee_main_2026_s1',
              'name': 'JEE Main 2026 Shift 1',
              'title': 'JEE Main 2026 Shift 1',
              'year': 2026,
              'exam': 'JEE Main 2026',
              'questionsCount': 75,
              'subjects': ['Physics', 'Chemistry', 'Mathematics'],
            },
            {
              'id': 'jee_main_2025_s1',
              'name': 'JEE Main 2025 Shift 1',
              'title': 'JEE Main 2025 Shift 1',
              'year': 2025,
              'exam': 'JEE Main 2025',
              'questionsCount': 75,
              'subjects': ['Physics', 'Chemistry', 'Mathematics'],
            },
            {
              'id': 'jee_main_2024_s1',
              'name': 'JEE Main 2024 Shift 1',
              'title': 'JEE Main 2024 Shift 1',
              'year': 2024,
              'exam': 'JEE Main 2024',
              'questionsCount': 75,
              'subjects': ['Physics', 'Chemistry', 'Mathematics'],
            },
          ];

    final Set<String> ids = {};
    final List<Map<String, dynamic>> combined = [];

    for (var p in papers) {
      final name = (p['paper_name'] ?? p['paperName'] ?? p['title'] ?? p['name'] ?? '').toString();
      if (name.isNotEmpty && !ids.contains(name.toLowerCase())) {
        ids.add(name.toLowerCase());
        combined.add(p);
      }
    }

    for (var c in canonicalList) {
      final name = (c['name'] ?? '').toString();
      if (!ids.contains(name.toLowerCase())) {
        ids.add(name.toLowerCase());
        combined.add(c);
      }
    }

    if (mounted) {
      setState(() {
        _availablePaperRecords = combined;
        if (_availablePaperRecords.isNotEmpty) {
          _selectedPaperRecord = _availablePaperRecords.first;
        }
        _isLoadingPapers = false;
      });
    }
  }

  Future<void> _initChapters() async {
    setState(() => _isLoadingTaxonomy = true);
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

      final existingChapters = _subjectChaptersMap[sub] ?? [];
      final Set<String> selChapterIds = { for (var c in existingChapters.where((c) => c.isSelected)) c.id };
      final Set<String> selTopicIds = {};
      for (var c in existingChapters) {
        for (var t in c.topics.where((t) => t.isSelected)) {
          selTopicIds.add(t.id);
        }
      }

      final List<ChapterItem> chapterItems = rawChapters.map((cMap) {
        final cId = (cMap['id'] ?? '').toString();
        final cName = (cMap['name'] ?? '').toString();

        final rawTopics = (cMap['topicsList'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        final topicItems = rawTopics.map((tMap) {
          final tId = (tMap['id'] ?? '').toString();
          return TopicItem(
            id: tId,
            name: (tMap['name'] ?? '').toString(),
            chapterId: cId,
            chapterName: cName,
            isSelected: selTopicIds.contains(tId),
          );
        }).toList();

        final isChapSel = selChapterIds.contains(cId) || (topicItems.isNotEmpty && topicItems.every((t) => t.isSelected));

        return ChapterItem(
          id: cId,
          name: cName,
          isExpanded: false,
          isSelected: isChapSel,
          topics: topicItems,
        );
      }).toList();

      if (chapterItems.isNotEmpty) {
        chapterItems.first.isExpanded = true;
      }

      newMap[sub] = chapterItems;
    }

    if (mounted) {
      setState(() {
        _subjectChaptersMap = newMap;
        if (!_subjectChaptersMap.containsKey(_activeStep3Subject) && _subjectChaptersMap.isNotEmpty) {
          _activeStep3Subject = _subjectChaptersMap.keys.first;
        }
        _isLoadingTaxonomy = false;
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
        _activeStep3Subject = 'Physics';
      } else {
        _selectedSubjects = {'Physics', 'Chemistry', 'Mathematics'};
        _activeStep3Subject = 'Physics';
      }
      _subjectChaptersMap.clear();
      _selectedPaperRecord = null;
      _initChapters();
      _loadAvailablePapers();
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

  List<ChapterItem> get _activeChapters => _subjectChaptersMap[_activeStep3Subject] ?? [];

  int get _totalSelectedChaptersCount {
    int total = 0;
    _subjectChaptersMap.forEach((sub, chapters) {
      total += chapters.where((c) => c.isFullySelected || c.isPartiallySelected).length;
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
      final targetChapters = _searchQuery.isEmpty
          ? _activeChapters
          : _activeChapters.where((c) =>
              c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              c.topics.any((t) => t.name.toLowerCase().contains(_searchQuery.toLowerCase()))
            ).toList();

      for (var c in targetChapters) {
        c.isSelected = select;
        for (var t in c.topics) {
          t.isSelected = select;
        }
      }
    });
  }

  void _toggleChapterSelection(ChapterItem chapter, bool? val) {
    setState(() {
      final select = val ?? !chapter.isFullySelected;
      chapter.isSelected = select;
      for (var t in chapter.topics) {
        t.isSelected = select;
      }
    });
  }

  void _toggleTopicSelection(TopicItem topic, bool? val) {
    setState(() {
      final select = val ?? !topic.isSelected;
      topic.isSelected = select;
      _syncChapterFromTopics(topic.chapterId);
    });
  }

  void _syncChapterFromTopics(String chapterId) {
    for (var sub in _subjectChaptersMap.keys) {
      for (var c in _subjectChaptersMap[sub]!) {
        if (c.id == chapterId) {
          if (c.topics.isNotEmpty) {
            c.isSelected = c.topics.every((t) => t.isSelected);
          }
          return;
        }
      }
    }
  }

  String _formatTimeSpent(int seconds) {
    final hours = seconds ~/ 3600;
    final mins = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }

  Future<void> _startChapterPracticeSession(bool isTestMode) async {
    final hasSelection = _totalSelectedChaptersCount > 0 || _totalSelectedTopicsCount > 0;
    if (!hasSelection) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one chapter or topic to start.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isStarting = true);

    final List<String> selectedChapterIds = [];
    final List<String> selectedTopicIds = [];
    final List<String> activeSubjects = [];

    _subjectChaptersMap.forEach((sub, chapters) {
      bool subjectSelected = false;
      for (var c in chapters) {
        if (c.isFullySelected || c.isPartiallySelected || c.isSelected) {
          selectedChapterIds.add(c.id);
          subjectSelected = true;
          for (var t in c.topics) {
            if (t.isSelected) {
              selectedTopicIds.add(t.id);
            }
          }
        }
      }
      if (subjectSelected) {
        activeSubjects.add(sub);
      }
    });

    final rawQuestions = await SupabaseService.fetchPYQQuestions(
      exam: _selectedExam,
      subjects: activeSubjects.isEmpty ? _selectedSubjects.toList() : activeSubjects,
      chapterIds: selectedChapterIds,
      topicIds: selectedTopicIds,
      difficulty: _difficulty,
      limit: _questionCount,
    );

    final questions = NeetSubjectHelper.sortQuestionsForNEET(rawQuestions);

    setState(() => _isStarting = false);

    if (!mounted) return;

    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No PYQs available matching your selected chapters/topics and filters.'),
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

  Future<void> _startPaperPracticeSession(bool isTestMode) async {
    if (_selectedPaperRecord == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a PYQ paper to continue.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isStarting = true);

    final paperId = (_selectedPaperRecord!['id'] ?? _selectedPaperRecord!['paper_id'] ?? '').toString();
    final paperName = (_selectedPaperRecord!['name'] ?? _selectedPaperRecord!['title'] ?? _selectedPaperRecord!['paper_name'] ?? 'Official Paper').toString();

    final rawQuestions = await SupabaseService.fetchTestSeriesQuestions(
      paperId: paperId.isNotEmpty ? paperId : paperName,
      exam: _selectedExam,
      limit: 200,
      forceRefresh: true,
    );

    final activeSubs = _selectedSubjects.toList();
    final filtered = rawQuestions.where((q) {
      final subName = NeetSubjectHelper.getSubjectNameFromId(q.subjectId);
      if (activeSubs.isNotEmpty) {
        return activeSubs.any((s) => s.toLowerCase() == subName.toLowerCase() || q.subjectId.toLowerCase().contains(s.toLowerCase()));
      }
      return true;
    }).toList();

    final questions = NeetSubjectHelper.sortQuestionsForNEET(filtered.isEmpty ? rawQuestions : filtered);

    setState(() => _isStarting = false);

    if (!mounted) return;

    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No questions uploaded yet in database for "$paperName".'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final timerMins = isTestMode ? (questions.length * 1.5).ceil() : 0;

    if (widget.onStartPYQSession != null) {
      widget.onStartPYQSession!(questions, timerMins, isTestMode);
    } else if (widget.onStartPractice != null) {
      widget.onStartPractice!(questions, timerMins);
    }
  }

  void _showSavePresetDialog() {
    final bool isChapterMode = _selectedMode == PYQPracticeMode.chapterWise;
    final defaultName = isChapterMode
        ? '$_selectedExam Custom (${_totalSelectedChaptersCount} Chaps)'
        : '$_selectedExam (${_selectedPaperRecord?['name'] ?? 'Paper'})';
    final controller = TextEditingController(text: defaultName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Save Practice Preset', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Save your practice mode, exam, subjects, and paper/chapter configuration for quick 1-tap launch later.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Preset Name',
                hintText: 'e.g. Mechanics & Optics Focus',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim().isEmpty ? defaultName : controller.text.trim();
              final List<String> selChapIds = [];
              final List<String> selTopIds = [];
              _subjectChaptersMap.forEach((sub, chapters) {
                for (var c in chapters) {
                  if (c.isSelected || c.isFullySelected || c.isPartiallySelected) {
                    selChapIds.add(c.id);
                    for (var t in c.topics) {
                      if (t.isSelected) selTopIds.add(t.id);
                    }
                  }
                }
              });

              final preset = {
                'id': 'preset_${DateTime.now().millisecondsSinceEpoch}',
                'name': name,
                'exam': _selectedExam,
                'mode': isChapterMode ? 'chapterWise' : 'yearWise',
                'subjects': _selectedSubjects.toList(),
                'paperId': _selectedPaperRecord?['id'],
                'paperName': _selectedPaperRecord?['name'] ?? _selectedPaperRecord?['title'],
                'chapterIds': selChapIds,
                'topicIds': selTopIds,
                'questionCount': _questionCount,
                'difficulty': _difficulty,
                'createdAt': DateTime.now().toIso8601String(),
              };
              setState(() {
                _savedPresets.insert(0, preset);
              });
              _savePresetToPrefs();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Preset "$name" saved successfully!'),
                  backgroundColor: const Color(0xFF16A34A),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save Preset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSavedPresetsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Saved Presets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: SizedBox(
          width: double.maxFinite,
          child: _savedPresets.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No saved presets yet.\nConfigure your mode/subjects and tap "Save Preset".',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _savedPresets.length,
                  itemBuilder: (context, index) {
                    final p = _savedPresets[index];
                    final mode = p['mode'] == 'yearWise' ? 'Year-wise Paper' : 'Chapter-wise';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: ListTile(
                        title: Text(
                          p['name'] ?? 'Saved Preset',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Text(
                          '${p['exam']} • $mode',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                              onPressed: () {
                                setState(() {
                                  _savedPresets.removeAt(index);
                                });
                                _savePresetToPrefs();
                                Navigator.pop(ctx);
                                _showSavedPresetsDialog();
                              },
                            ),
                            ElevatedButton(
                              onPressed: () {
                                _loadPreset(p);
                                Navigator.pop(ctx);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7C3AED),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Apply', style: TextStyle(fontSize: 12, color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _loadPreset(Map<String, dynamic> preset) {
    final String exam = preset['exam'] ?? _selectedExam;
    final String modeStr = preset['mode'] ?? 'chapterWise';
    final List subs = preset['subjects'] ?? [];
    final List chapIds = preset['chapterIds'] ?? [];
    final List topIds = preset['topicIds'] ?? [];

    setState(() {
      _selectedExam = exam;
      _selectedMode = modeStr == 'yearWise' ? PYQPracticeMode.yearWise : PYQPracticeMode.chapterWise;
      if (subs.isNotEmpty) {
        _selectedSubjects = Set<String>.from(subs.map((s) => s.toString()));
      }
      if (preset['questionCount'] != null) _questionCount = preset['questionCount'];
      if (preset['difficulty'] != null) _difficulty = preset['difficulty'];

      if (_selectedMode == PYQPracticeMode.yearWise && preset['paperId'] != null) {
        final pId = preset['paperId'].toString();
        final match = _availablePaperRecords.firstWhere(
          (p) => (p['id'] ?? p['paper_id'] ?? '').toString() == pId,
          orElse: () => _availablePaperRecords.isNotEmpty ? _availablePaperRecords.first : {},
        );
        if (match.isNotEmpty) _selectedPaperRecord = match;
      } else {
        _subjectChaptersMap.forEach((sub, chapters) {
          for (var c in chapters) {
            final matchChap = chapIds.contains(c.id);
            c.isSelected = matchChap;
            for (var t in c.topics) {
              t.isSelected = topIds.contains(t.id) || matchChap;
            }
          }
        });
      }
      _currentStep = 3;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Preset "${preset['name']}" applied!'),
        backgroundColor: const Color(0xFF7C3AED),
      ),
    );
  }

  void _showCustomQuestionCountDialog() {
    final controller = TextEditingController(text: _questionCount > 0 ? '$_questionCount' : '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Custom Question Count', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Number of Questions',
            hintText: 'Enter question count (e.g. 40)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 992;
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const Drawer(
        child: AppSidebar(selectedIndex: 4),
      ),
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              activeExam: _selectedExam,
              onOpenDrawer: () => scaffoldKey.currentState?.openDrawer(),
            ),
            Expanded(
              child: Row(
                children: [
                  if (isDesktop)
                    const AppSidebar(selectedIndex: 4),
                  Expanded(
                    child: Column(
                      children: [
                        // Subtitle & Dynamic Progress Indicator Header
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.arrow_back, color: Color(0xFF7C3AED)),
                                    onPressed: () {
                                      if (_currentStep > 1) {
                                        setState(() => _currentStep--);
                                      } else {
                                        if (widget.onBack != null) {
                                          widget.onBack!();
                                        } else {
                                          Navigator.maybePop(context);
                                        }
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'PYQ Practice Engine',
                                    style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const Spacer(),
                                  if (_savedPresets.isNotEmpty) ...[
                                    TextButton.icon(
                                      onPressed: _showSavedPresetsDialog,
                                      icon: const Icon(Icons.bookmarks_outlined, size: 14, color: Color(0xFF7C3AED)),
                                      label: Text(
                                        'Presets (${_savedPresets.length})',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  OutlinedButton.icon(
                                    onPressed: _showSavePresetDialog,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF7C3AED),
                                      side: const BorderSide(color: Color(0xFF7C3AED), width: 1.2),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: const Icon(Icons.bookmark_border_rounded, size: 14, color: Color(0xFF7C3AED)),
                                    label: const Text('Save Preset', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _buildProgressIndicator(),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),

                        // Body (Step 1, Step 2, or Step 3)
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: _buildCurrentStepView(),
                          ),
                        ),

                        // Sticky Bottom Action Bar (Only on Step 3)
                        if (_currentStep == 3) _buildStickyBottomBarStep3(),
                      ],
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

  // ================= DYNAMIC 3-STEP PROGRESS INDICATOR =================

  Widget _buildProgressIndicator() {
    final step3Label = _selectedMode == PYQPracticeMode.chapterWise ? 'Select Chapters' : 'Select Paper';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Step 1: Mode
        _buildStepBadge(1, 'Practice Mode', _currentStep == 1, _currentStep > 1),
        _buildStepConnector(_currentStep > 1),

        // Step 2: Subjects
        _buildStepBadge(2, 'Subjects', _currentStep == 2, _currentStep > 2),
        _buildStepConnector(_currentStep > 2),

        // Step 3: Selection
        _buildStepBadge(3, step3Label, _currentStep == 3, false),
      ],
    );
  }

  Widget _buildStepBadge(int stepNum, String label, bool isActive, bool isDone) {
    Color bg = const Color(0xFFF1F5F9);
    Color border = const Color(0xFFCBD5E1);
    Color textColor = const Color(0xFF64748B);

    if (isDone) {
      bg = const Color(0xFFDCFCE7);
      border = const Color(0xFF16A34A);
      textColor = const Color(0xFF16A34A);
    } else if (isActive) {
      bg = const Color(0xFF7C3AED);
      border = const Color(0xFF7C3AED);
      textColor = const Color(0xFF7C3AED);
    }

    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(color: border, width: 2),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 14, color: Color(0xFF16A34A))
                : Text(
                    '$stepNum',
                    style: TextStyle(
                      color: isActive ? Colors.white : const Color(0xFF64748B),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive || isDone ? FontWeight.bold : FontWeight.w500,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(bool isDone) {
    return Container(
      width: 24,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: isDone ? const Color(0xFF7C3AED) : const Color(0xFFCBD5E1),
    );
  }

  Widget _buildCurrentStepView() {
    switch (_currentStep) {
      case 1:
        return _buildStep1ModeView();
      case 2:
        return _buildStep2SubjectView();
      case 3:
      default:
        return _selectedMode == PYQPracticeMode.chapterWise
            ? _buildStep3ChapterWiseView()
            : _buildStep3YearWiseView();
    }
  }

  // ================= 1. COMPACT STATISTICS ROW =================

  Widget _buildCompactStatsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCompactStatItem(
            icon: Icons.track_changes_rounded,
            iconColor: const Color(0xFF16A34A),
            value: '$_availableQuestionsCount',
            label: 'Questions',
          ),
          _buildVerticalDivider(),
          _buildCompactStatItem(
            icon: Icons.assignment_outlined,
            iconColor: const Color(0xFF2563EB),
            value: '$_availablePapersCount',
            label: 'Papers',
          ),
          _buildVerticalDivider(),
          _buildCompactStatItem(
            icon: Icons.trending_up_rounded,
            iconColor: const Color(0xFF9333EA),
            value: '$_userAccuracy%',
            label: 'Accuracy',
          ),
          _buildVerticalDivider(),
          _buildCompactStatItem(
            icon: Icons.access_time_rounded,
            iconColor: const Color(0xFFEA580C),
            value: _formatTimeSpent(_timeSpentSeconds),
            label: 'Time',
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 26,
      width: 1,
      color: const Color(0xFFE2E8F0),
    );
  }

  Widget _buildCompactStatItem({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: iconColor, size: 14),
              const SizedBox(width: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ================= STEP 1 VIEW — CHOOSE PRACTICE MODE =================

  Widget _buildStep1ModeView() {
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
        const SizedBox(height: 16),

        // Compact Horizontal Stats Row
        _isLoadingStats
            ? const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
            : _buildCompactStatsRow(),
        const SizedBox(height: 22),

        // Section Title
        const Text(
          '1. Choose Practice Mode',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 12),

        // Mode Cards Side-by-Side
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
                subtitle: 'Practice questions from a specific previous-year paper',
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Next Step Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              setState(() => _currentStep = 2);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Next: Select Subjects',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ================= STEP 2 VIEW — SELECT SUBJECTS =================

  Widget _buildStep2SubjectView() {
    final isNeet = _selectedExam.contains('NEET');
    final availableSubjects = isNeet ? ['Physics', 'Chemistry', 'Biology'] : ['Physics', 'Chemistry', 'Mathematics'];
    final allSelected = _selectedSubjects.length == availableSubjects.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '2. Select Subjects',
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
        const SizedBox(height: 14),
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
        const SizedBox(height: 28),

        // Proceed to Step 3 Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              if (_selectedSubjects.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select at least one subject to continue.')),
                );
                return;
              }
              setState(() => _currentStep = 3);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _selectedMode == PYQPracticeMode.chapterWise
                      ? 'Next: Select Chapters & Topics'
                      : 'Next: Select PYQ Paper',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ================= STEP 3 VIEW — CHAPTER-WISE MODE =================

  Widget _buildStep3ChapterWiseView() {
    final isNeet = _selectedExam.contains('NEET');
    final availableSubjects = isNeet ? ['Physics', 'Chemistry', 'Biology'] : ['Physics', 'Chemistry', 'Mathematics'];
    final activeSubject = _activeStep3Subject;
    final currentChapters = _activeChapters;

    final filteredChapters = _searchQuery.isEmpty
        ? currentChapters
        : currentChapters.where((c) =>
            c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            c.topics.any((t) => t.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          ).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Subject Selector Tab Bar
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: availableSubjects.map((sub) {
              final isSel = _activeStep3Subject == sub;
              final subChapters = _subjectChaptersMap[sub] ?? [];

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
                  onTap: () => setState(() => _activeStep3Subject = sub),
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
                width: 44,
                height: 44,
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
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activeSubject,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${currentChapters.length} Chapters • ${currentChapters.fold(0, (s, c) => s + c.topics.length)} Topics',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // View Mode Switch Tabs (Chapters vs Topics)
        Container(
          height: 42,
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

        // Search Input Box
        Container(
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
                    hintText: _activeViewTab == 0 ? 'Search $activeSubject chapters...' : 'Search $activeSubject topics...',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              if (_searchQuery.isNotEmpty)
                GestureDetector(
                  onTap: () => setState(() => _searchQuery = ''),
                  child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Number of Questions & Difficulty Controls
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Number of Questions', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: [10, 20, 30, 45, 90].contains(_questionCount) ? _questionCount : -1,
                        isExpanded: true,
                        isDense: true,
                        items: [
                          ...[10, 20, 30, 45, 90].map((c) {
                            return DropdownMenuItem<int>(
                              value: c,
                              child: Text('$c Qs', style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B))),
                            );
                          }),
                          DropdownMenuItem<int>(
                            value: -1,
                            child: Text(
                              [10, 20, 30, 45, 90].contains(_questionCount) ? 'Custom' : 'Custom ($_questionCount)',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          if (val == -1) {
                            _showCustomQuestionCountDialog();
                          } else if (val != null) {
                            setState(() => _questionCount = val);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Difficulty Level', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _difficulty,
                        isExpanded: true,
                        isDense: true,
                        items: ['Mixed', 'Easy', 'Medium', 'Hard'].map((d) {
                          return DropdownMenuItem<String>(
                            value: d,
                            child: Text(d, style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B))),
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
        const SizedBox(height: 16),

        // Select All Active Subject Chapters Header Bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
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
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            Text(
              '${currentChapters.where((c) => c.isFullySelected || c.isPartiallySelected).length} selected',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (_isLoadingTaxonomy)
          const Center(child: Padding(padding: EdgeInsets.all(28), child: CircularProgressIndicator()))
        else if (_activeViewTab == 0)
          _buildChaptersView(filteredChapters)
        else
          _buildTopicsView(currentChapters),

        const SizedBox(height: 20),
      ],
    );
  }

  // ================= STEP 3 VIEW — YEAR-WISE MODE (PAPER SELECTOR) =================

  Widget _buildStep3YearWiseView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select PYQ Paper',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 4),
        const Text(
          'Choose an official previous year paper from the verified database catalogue.',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 16),

        _isLoadingPapers
            ? const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
            : Column(
                children: [
                  // Paper Dropdown / List
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Map<String, dynamic>>(
                        value: _selectedPaperRecord,
                        isExpanded: true,
                        hint: const Text('Select a paper'),
                        items: _availablePaperRecords.map((p) {
                          final title = (p['paper_name'] ?? p['paperName'] ?? p['title'] ?? p['name'] ?? 'Paper').toString();
                          final qCount = p['questionsCount'] ?? p['questions_count'] ?? p['total_questions'] ?? 180;
                          return DropdownMenuItem<Map<String, dynamic>>(
                            value: p,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3E8FF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$qCount Qs',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedPaperRecord = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Selected Paper Info Summary Card
                  if (_selectedPaperRecord != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF7C3AED), width: 1.5),
                        boxShadow: const [
                          BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 3)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEEF2FF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.assignment_rounded, color: Color(0xFF7C3AED), size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (_selectedPaperRecord!['paper_name'] ?? _selectedPaperRecord!['paperName'] ?? _selectedPaperRecord!['title'] ?? _selectedPaperRecord!['name'] ?? 'Selected Paper').toString(),
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Target: $_selectedExam',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24, color: Color(0xFFF1F5F9)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Text('Total Paper Size', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_selectedPaperRecord!['questionsCount'] ?? _selectedPaperRecord!['questions_count'] ?? 180} Questions',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
                                  ),
                                ],
                              ),
                              Container(height: 20, width: 1, color: const Color(0xFFE2E8F0)),
                              Column(
                                children: [
                                  const Text('Subjects', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                  const SizedBox(height: 2),
                                  Text(
                                    _selectedSubjects.join(' • '),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildChaptersView(List<ChapterItem> filteredChapters) {
    if (filteredChapters.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Text(
          _searchQuery.isNotEmpty ? 'No chapters match "$_searchQuery"' : 'No chapters available for $_activeStep3Subject.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
      );
    }

    return Column(
      children: filteredChapters.map((chapter) {
        final isFully = chapter.isFullySelected;
        final isPartial = chapter.isPartiallySelected;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isFully ? const Color(0xFF7C3AED) : (isPartial ? const Color(0xFFA78BFA) : const Color(0xFFE2E8F0)),
              width: isFully || isPartial ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              // Chapter Main Row
              InkWell(
                onTap: () {
                  setState(() => chapter.isExpanded = !chapter.isExpanded);
                },
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: isFully ? true : (isPartial ? null : false),
                          tristate: true,
                          activeColor: const Color(0xFF7C3AED),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (val) => _toggleChapterSelection(chapter, val),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          chapter.name,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                      ),
                      Text(
                        chapter.topics.isNotEmpty
                            ? '${chapter.selectedTopicCount} / ${chapter.topics.length} Topics'
                            : (chapter.isSelected ? 'Selected' : '0 Topics'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: (chapter.isSelected || isFully || isPartial) ? const Color(0xFF7C3AED) : const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        chapter.isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: const Color(0xFF94A3B8),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),

              // Expanded Topics List
              if (chapter.isExpanded && chapter.topics.isNotEmpty) ...[
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                Padding(
                  padding: const EdgeInsets.only(left: 10, right: 10, top: 4, bottom: 6),
                  child: Column(
                    children: chapter.topics.map((topic) {
                      return InkWell(
                        onTap: () => _toggleTopicSelection(topic, null),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: Checkbox(
                                  value: topic.isSelected,
                                  activeColor: const Color(0xFF7C3AED),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  onChanged: (val) => _toggleTopicSelection(topic, val),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  topic.name,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF334155), fontWeight: FontWeight.w500),
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
      }).toList(),
    );
  }

  Widget _buildTopicsView(List<ChapterItem> chapters) {
    final List<TopicItem> allTopics = [];
    for (var c in chapters) {
      allTopics.addAll(c.topics);
    }

    final filteredTopics = _searchQuery.isEmpty
        ? allTopics
        : allTopics.where((t) =>
            t.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            t.chapterName.toLowerCase().contains(_searchQuery.toLowerCase())
          ).toList();

    if (allTopics.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Column(
          children: [
            const Icon(Icons.format_list_bulleted_outlined, size: 36, color: Color(0xFF94A3B8)),
            const SizedBox(height: 10),
            Text(
              'No topics listed for $_activeStep3Subject yet.',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    if (filteredTopics.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Text(
          'No topics match "$_searchQuery"',
          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
      );
    }

    return Column(
      children: filteredTopics.map((topic) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: topic.isSelected ? const Color(0xFF7C3AED) : const Color(0xFFE2E8F0)),
          ),
          child: InkWell(
            onTap: () => _toggleTopicSelection(topic, null),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: topic.isSelected,
                      activeColor: const Color(0xFF7C3AED),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      onChanged: (val) => _toggleTopicSelection(topic, val),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          topic.name,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          topic.chapterName,
                          style: const TextStyle(fontSize: 10, color: Color(0xFF7C3AED), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ================= STICKY BOTTOM ACTION BAR (STEP 3) =================

  Widget _buildStickyBottomBarStep3() {
    final isNeet = _selectedExam.contains('NEET');
    final pcbPcmLabel = isNeet ? 'PCB' : 'PCM';
    final isChapterMode = _selectedMode == PYQPracticeMode.chapterWise;

    final hasSelection = isChapterMode
        ? (_totalSelectedChaptersCount > 0 || _totalSelectedTopicsCount > 0)
        : (_selectedPaperRecord != null);

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: isMobile ? 10 : 14,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isMobile) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFDDD6FE)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF7C3AED), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          isChapterMode ? 'Selected ($pcbPcmLabel): ' : 'Paper: ',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                        Text(
                          isChapterMode
                              ? '$_totalSelectedChaptersCount Chap • $_totalSelectedTopicsCount Top'
                              : (_selectedPaperRecord?['name'] ?? _selectedPaperRecord?['title'] ?? 'Select Paper').toString(),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$_questionCount Qs • $_difficulty',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: OutlinedButton(
                        onPressed: (!hasSelection || _isStarting)
                            ? null
                            : () => isChapterMode ? _startChapterPracticeSession(false) : _startPaperPracticeSession(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF7C3AED),
                          side: BorderSide(
                            color: hasSelection ? const Color(0xFF7C3AED) : const Color(0xFFCBD5E1),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.play_arrow_rounded, size: 18),
                            SizedBox(width: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Start Practice',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        onPressed: (!hasSelection || _isStarting)
                            ? null
                            : () => isChapterMode ? _startChapterPracticeSession(true) : _startPaperPracticeSession(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          disabledBackgroundColor: const Color(0xFFCBD5E1),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.assignment_turned_in_rounded, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Start Test',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isChapterMode ? 'Selected ($pcbPcmLabel)' : 'Selected Paper', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                        Text(
                          isChapterMode
                              ? '$_totalSelectedChaptersCount Chap • $_totalSelectedTopicsCount Top'
                              : (_selectedPaperRecord?['name'] ?? _selectedPaperRecord?['title'] ?? 'Select Paper').toString(),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: (!hasSelection || _isStarting)
                            ? null
                            : () => isChapterMode ? _startChapterPracticeSession(false) : _startPaperPracticeSession(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF7C3AED),
                          side: BorderSide(
                            color: hasSelection ? const Color(0xFF7C3AED) : const Color(0xFFCBD5E1),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded, color: Color(0xFF7C3AED), size: 20),
                        label: const Text(
                          'Start Practice',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: (!hasSelection || _isStarting)
                            ? null
                            : () => isChapterMode ? _startChapterPracticeSession(true) : _startPaperPracticeSession(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          disabledBackgroundColor: const Color(0xFFCBD5E1),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.assignment_turned_in_rounded, color: Colors.white, size: 18),
                        label: const Text(
                          'Start Test',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
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
