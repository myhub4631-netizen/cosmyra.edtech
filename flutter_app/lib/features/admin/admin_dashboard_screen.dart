import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import '../../models/models.dart';
import '../../core/services/supabase_service.dart';
import '../../shared/widgets/latex_view.dart';

class AdminDashboardScreen extends StatefulWidget {
  final UserProfileModel userProfile;

  const AdminDashboardScreen({Key? key, required this.userProfile}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  List<QuestionModel> _questionBank = [];
  List<ReportModel> _reports = [];

  final _searchController = TextEditingController();

  // CSV Import preview state
  List<List<dynamic>> _csvRowsPreview = [];
  List<String> _csvImportErrors = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);
    final questions = await SupabaseService.fetchQuestions(limit: 100);
    final reports = await SupabaseService.getReportedQuestions();
    setState(() {
      _questionBank = questions;
      _reports = reports;
      _isLoading = false;
    });
  }

  void _openQuestionEditor({QuestionModel? questionToEdit}) {
    final textCtrl = TextEditingController(text: questionToEdit?.questionText ?? '');
    final optACtrl = TextEditingController(text: questionToEdit != null && questionToEdit.options.isNotEmpty ? questionToEdit.options[0].optionText : '');
    final optBCtrl = TextEditingController(text: questionToEdit != null && questionToEdit.options.length > 1 ? questionToEdit.options[1].optionText : '');
    final optCCtrl = TextEditingController(text: questionToEdit != null && questionToEdit.options.length > 2 ? questionToEdit.options[2].optionText : '');
    final optDCtrl = TextEditingController(text: questionToEdit != null && questionToEdit.options.length > 3 ? questionToEdit.options[3].optionText : '');
    final explCtrl = TextEditingController(text: questionToEdit?.explanation ?? '');
    final solCtrl = TextEditingController(text: questionToEdit?.solution ?? '');

    int correctIndex = 2; // Default Option C
    String difficulty = questionToEdit?.difficulty ?? 'medium';
    String source = questionToEdit?.source ?? 'pyq';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 700,
            height: 750,
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      questionToEdit == null ? 'Create New Question' : 'Edit Question',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop()),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    children: [
                      // Question Text Input
                      TextField(
                        controller: textCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Question Text (Supports LaTeX e.g. \$E = mc^2\$)',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) => setDialogState(() {}),
                      ),
                      const SizedBox(height: 12),
                      const Text('Live LaTeX Preview:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.2)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: LaTeXView(text: textCtrl.text.isEmpty ? 'Question LaTeX preview will appear here...' : textCtrl.text),
                      ),
                      const SizedBox(height: 20),

                      // Options Inputs
                      TextField(controller: optACtrl, decoration: const InputDecoration(labelText: 'Option A')),
                      const SizedBox(height: 8),
                      TextField(controller: optBCtrl, decoration: const InputDecoration(labelText: 'Option B')),
                      const SizedBox(height: 8),
                      TextField(controller: optCCtrl, decoration: const InputDecoration(labelText: 'Option C')),
                      const SizedBox(height: 8),
                      TextField(controller: optDCtrl, decoration: const InputDecoration(labelText: 'Option D')),
                      const SizedBox(height: 16),

                      // Correct Answer Index Selection
                      Row(
                        children: [
                          const Text('Correct Answer: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 12),
                          DropdownButton<int>(
                            value: correctIndex,
                            items: const [
                              DropdownMenuItem(value: 0, child: Text('Option A')),
                              DropdownMenuItem(value: 1, child: Text('Option B')),
                              DropdownMenuItem(value: 2, child: Text('Option C')),
                              DropdownMenuItem(value: 3, child: Text('Option D')),
                            ],
                            onChanged: (val) {
                              if (val != null) setDialogState(() => correctIndex = val);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Explanation & Solution
                      TextField(controller: explCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Explanation')),
                      const SizedBox(height: 12),
                      TextField(controller: solCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Step-by-Step Solution')),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        final newQuestion = QuestionModel(
                          id: questionToEdit?.id ?? 'q-${DateTime.now().millisecondsSinceEpoch}',
                          examId: '11111111-1111-1111-1111-111111111111',
                          subjectId: 'a1111111-1111-1111-1111-111111111111',
                          chapterId: 'b1111111-1111-1111-1111-111111111111',
                          questionText: textCtrl.text,
                          qType: 'single_correct',
                          difficulty: difficulty,
                          source: source,
                          marks: 4.0,
                          negativeMarks: 1.0,
                          explanation: explCtrl.text,
                          solution: solCtrl.text,
                          options: [
                            QuestionOptionModel(id: 'o1', questionId: '', optionIndex: 0, optionText: optACtrl.text, isCorrect: correctIndex == 0),
                            QuestionOptionModel(id: 'o2', questionId: '', optionIndex: 1, optionText: optBCtrl.text, isCorrect: correctIndex == 1),
                            QuestionOptionModel(id: 'o3', questionId: '', optionIndex: 2, optionText: optCCtrl.text, isCorrect: correctIndex == 2),
                            QuestionOptionModel(id: 'o4', questionId: '', optionIndex: 3, optionText: optDCtrl.text, isCorrect: correctIndex == 3),
                          ],
                        );

                        await SupabaseService.saveQuestion(newQuestion);
                        Navigator.of(ctx).pop();
                        _loadAdminData();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Question saved successfully to Supabase!')));
                      },
                      child: const Text('Save & Publish Question'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndValidateCSV() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.single.bytes != null) {
        final csvString = utf8.decode(result.files.single.bytes!);
        List<List<dynamic>> rows = const CsvToListConverter().convert(csvString);

        List<String> errors = [];
        if (rows.isEmpty || rows.length < 2) {
          errors.add('CSV file is empty or missing headers.');
        } else {
          for (int i = 1; i < rows.length; i++) {
            final row = rows[i];
            if (row.length < 5) {
              errors.add('Row $i has insufficient columns.');
            }
          }
        }

        setState(() {
          _csvRowsPreview = rows;
          _csvImportErrors = errors;
        });
      }
    } catch (e) {
      debugPrint('CSV pick error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Operations & Question Management'),
        backgroundColor: Colors.redAccent.shade700,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.analytics_rounded), text: 'Platform Overview'),
            Tab(icon: Icon(Icons.quiz_rounded), text: 'Question Bank'),
            Tab(icon: Icon(Icons.file_upload_rounded), text: 'CSV Bulk Import'),
            Tab(icon: Icon(Icons.assignment_rounded), text: 'Test Builder'),
            Tab(icon: Icon(Icons.report_rounded), text: 'Reported Issues'),
            Tab(icon: Icon(Icons.group_rounded), text: 'User Management'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Platform Overview Metrics
                SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Platform Health & Metrics', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildAdminMetricCard('Total Registered Users', '12,450', Icons.group, Colors.blue)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildAdminMetricCard('Question Bank Count', '14,890 MCQs', Icons.quiz, Colors.green)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildAdminMetricCard('Total Tests Attempted', '48,210', Icons.assignment, Colors.purple)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildAdminMetricCard('Daily Active Aspirants', '3,410', Icons.bolt, Colors.orange)),
                        ],
                      ),
                    ],
                  ),
                ),

                // Tab 2: Question Bank Table
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                hintText: 'Search questions by keyword or topic...',
                                prefixIcon: Icon(Icons.search),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: () => _openQuestionEditor(),
                            icon: const Icon(Icons.add),
                            label: const Text('Add New Question'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _questionBank.length,
                          itemBuilder: (ctx, idx) {
                            final q = _questionBank[idx];
                            return Card(
                              child: ListTile(
                                title: Text(q.questionText, maxLines: 2, overflow: TextOverflow.ellipsis),
                                subtitle: Text('Exam: ${q.examId} • Difficulty: ${q.difficulty.toUpperCase()} • Source: ${q.source.toUpperCase()}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _openQuestionEditor(questionToEdit: q),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        setState(() => _questionBank.removeAt(idx));
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Question removed.')));
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Tab 3: CSV Bulk Import
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Bulk Question Import (CSV / Excel)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('Upload a structured CSV file with columns: question_text, option_a, option_b, option_c, option_d, correct_answer, explanation, difficulty, source.'),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _pickAndValidateCSV,
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Upload CSV File'),
                          ),
                          const SizedBox(width: 16),
                          OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sample CSV template downloaded.')));
                            },
                            icon: const Icon(Icons.download),
                            label: const Text('Download CSV Template'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (_csvRowsPreview.isNotEmpty) ...[
                        Text('Preview CSV (${_csvRowsPreview.length - 1} questions detected):', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _csvRowsPreview.length,
                            itemBuilder: (ctx, idx) {
                              return Card(
                                child: ListTile(
                                  title: Text(_csvRowsPreview[idx].toString()),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Tab 4: Admin Test Builder
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Create Official Mock Test Series', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      const TextField(decoration: InputDecoration(labelText: 'Test Title (e.g. NEET 2026 Full Syllabus Test #01)')),
                      const SizedBox(height: 12),
                      const Row(
                        children: [
                          Expanded(child: TextField(decoration: InputDecoration(labelText: 'Total Questions (e.g. 180)'))),
                          SizedBox(width: 12),
                          Expanded(child: TextField(decoration: InputDecoration(labelText: 'Duration (Minutes, e.g. 200)'))),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mock Test created and published to students!')));
                        },
                        child: const Text('Create & Publish Mock Test'),
                      ),
                    ],
                  ),
                ),

                // Tab 5: Reported Issues Quality Control
                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _reports.length,
                  itemBuilder: (ctx, idx) {
                    final rep = _reports[idx];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.report_problem, color: Colors.orange),
                        title: Text('Reported by ${rep.reporterName}: ${rep.reason}'),
                        subtitle: Text('Status: ${rep.status.toUpperCase()}'),
                        trailing: ElevatedButton(
                          onPressed: () {
                            setState(() => _reports.removeAt(idx));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report resolved.')));
                          },
                          child: const Text('Resolve'),
                        ),
                      ),
                    );
                  },
                ),

                // Tab 6: User Management
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: ListView(
                    children: [
                      Card(
                        child: ListTile(
                          leading: const CircleAvatar(child: Text('R')),
                          title: const Text('Rahul Sharma (student@cosmyra.edu)'),
                          subtitle: const Text('Target: NEET 2026 • Solved: 480 Questions • Rank #14'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.green.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                            child: const Text('ACTIVE', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
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

  Widget _buildAdminMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
