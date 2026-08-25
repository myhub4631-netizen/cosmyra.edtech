import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../core/services/supabase_service.dart';

class CustomPracticeWizardModal extends StatefulWidget {
  final String initialExam;
  final Function(List<QuestionModel> questions, int timerMinutes) onStartPractice;

  const CustomPracticeWizardModal({
    Key? key,
    required this.initialExam,
    required this.onStartPractice,
  }) : super(key: key);

  @override
  State<CustomPracticeWizardModal> createState() => _CustomPracticeWizardModalState();
}

class _CustomPracticeWizardModalState extends State<CustomPracticeWizardModal> {
  int _currentStep = 0;
  late String _selectedExam;

  List<SubjectModel> _availableSubjects = [];
  final Set<String> _selectedSubjectIds = {};

  List<ChapterModel> _availableChapters = [];
  final Set<String> _selectedChapterIds = {};

  String _selectedSource = 'Mixed';
  String _selectedDifficulty = 'Mixed';
  int _questionCount = 10;
  int _timerMinutes = 15;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedExam = widget.initialExam;
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    setState(() => _isLoading = true);
    final subjects = await SupabaseService.getSubjects(
      examId: _selectedExam.contains('JEE') ? '22222222-2222-2222-2222-222222222222' : '11111111-1111-1111-1111-111111111111',
    );
    setState(() {
      _availableSubjects = subjects;
      _selectedSubjectIds.clear();
      if (subjects.isNotEmpty) {
        _selectedSubjectIds.add(subjects.first.id);
      }
      _isLoading = false;
    });
    _loadChapters();
  }

  Future<void> _loadChapters() async {
    if (_selectedSubjectIds.isEmpty) return;
    final chapters = await SupabaseService.getChapters(_selectedSubjectIds.first);
    setState(() {
      _availableChapters = chapters;
      _selectedChapterIds.clear();
      for (final ch in chapters) {
        _selectedChapterIds.add(ch.id);
      }
    });
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 600,
        height: 620,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Custom Practice Builder', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('Step ${_currentStep + 1} of 8: ${_getStepTitle()}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: (_currentStep + 1) / 8,
              backgroundColor: Colors.grey.withOpacity(0.2),
            ),
            const SizedBox(height: 20),

            // Step Content Body
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildStepBody(),
            ),

            const SizedBox(height: 16),

            // Footer Navigation Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 0)
                  OutlinedButton(
                    onPressed: () => setState(() => _currentStep--),
                    child: const Text('Back'),
                  )
                else
                  const SizedBox.shrink(),

                ElevatedButton(
                  onPressed: () {
                    if (_currentStep < 7) {
                      setState(() => _currentStep++);
                    } else {
                      _handleStartSession();
                    }
                  },
                  child: Text(_currentStep == 7 ? 'Generate & Start Session 🚀' : 'Next Step'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0: return 'Select Competitive Exam Target';
      case 1: return 'Choose Exam Subjects';
      case 2: return 'Select Specific Chapters';
      case 3: return 'Select Topics & Subtopics';
      case 4: return 'Choose Question Sources';
      case 5: return 'Set Difficulty Level';
      case 6: return 'Question Quantity';
      case 7: return 'Practice Timer & Summary';
      default: return '';
    }
  }

  Widget _buildStepBody() {
    switch (_currentStep) {
      case 0:
        return ListView(
          children: [
            _buildChoiceCard('NEET UG', 'Medical Entrance Exam (Physics, Chemistry, Biology)', _selectedExam == 'NEET', () {
              setState(() => _selectedExam = 'NEET');
              _loadSubjects();
            }),
            _buildChoiceCard('JEE Main', 'Engineering Entrance (Physics, Chemistry, Mathematics)', _selectedExam == 'JEE_MAIN', () {
              setState(() => _selectedExam = 'JEE_MAIN');
              _loadSubjects();
            }),
            _buildChoiceCard('JEE Advanced', 'IIT Entrance Examination', _selectedExam == 'JEE_ADV', () {
              setState(() => _selectedExam = 'JEE_ADV');
              _loadSubjects();
            }),
          ],
        );
      case 1:
        return ListView(
          children: _availableSubjects.map((sub) {
            final isSelected = _selectedSubjectIds.contains(sub.id);
            return CheckboxListTile(
              title: Text(sub.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              value: isSelected,
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
            );
          }).toList(),
        );
      case 2:
        return ListView(
          children: _availableChapters.map((ch) {
            final isSelected = _selectedChapterIds.contains(ch.id);
            return CheckboxListTile(
              title: Text(ch.name),
              subtitle: Text('Class ${ch.classLevel} Syllabus'),
              value: isSelected,
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    _selectedChapterIds.add(ch.id);
                  } else {
                    _selectedChapterIds.remove(ch.id);
                  }
                });
              },
            );
          }).toList(),
        );
      case 3:
        return const Center(child: Text('All topics selected within selected chapters automatically.'));
      case 4:
        return ListView(
          children: ['Mixed', 'PYQ (Previous Years)', 'NTA Question Bank', 'NCERT Exemplar', 'Practice Questions']
              .map((src) => ListTile(
                    title: Text(src),
                    leading: Icon(
                      _selectedSource == src ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: _selectedSource == src ? Theme.of(context).primaryColor : Colors.grey,
                    ),
                    onTap: () => setState(() => _selectedSource = src),
                  ))
              .toList(),
        );
      case 5:
        return ListView(
          children: ['Mixed', 'Easy', 'Medium', 'Hard']
              .map((diff) => ListTile(
                    title: Text(diff),
                    leading: Icon(
                      _selectedDifficulty == diff ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: _selectedDifficulty == diff ? Theme.of(context).primaryColor : Colors.grey,
                    ),
                    onTap: () => setState(() => _selectedDifficulty = diff),
                  ))
              .toList(),
        );
      case 6:
        return ListView(
          children: [5, 10, 15, 20, 30, 50]
              .map((cnt) => ListTile(
                    title: Text('$cnt Questions'),
                    leading: Icon(
                      _questionCount == cnt ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: _questionCount == cnt ? Theme.of(context).primaryColor : Colors.grey,
                    ),
                    onTap: () => setState(() => _questionCount = cnt),
                  ))
              .toList(),
        );
      case 7:
        return ListView(
          children: [
            const Text('Choose Practice Timer:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [0, 5, 10, 15, 30, 45, 60].map((mins) {
                final isSelected = _timerMinutes == mins;
                return ChoiceChip(
                  label: Text(mins == 0 ? 'No Timer' : '$mins Mins'),
                  selected: isSelected,
                  onSelected: (val) => setState(() => _timerMinutes = mins),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Practice Session Summary:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('• Exam: $_selectedExam'),
                  Text('• Questions: $_questionCount Questions'),
                  Text('• Source: $_selectedSource'),
                  Text('• Difficulty: $_selectedDifficulty'),
                  Text('• Duration: ${_timerMinutes == 0 ? "Unlimited" : "$_timerMinutes Minutes"}'),
                ],
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildChoiceCard(String title, String subtitle, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).dividerColor.withOpacity(0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked, color: isSelected ? Theme.of(context).primaryColor : Colors.grey),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
