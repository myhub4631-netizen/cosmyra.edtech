import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../core/services/supabase_service.dart';

class PyqNtaScreen extends StatefulWidget {
  final String activeExam;
  final Function(List<QuestionModel> questions) onStartPractice;

  const PyqNtaScreen({
    Key? key,
    required this.activeExam,
    required this.onStartPractice,
  }) : super(key: key);

  @override
  State<PyqNtaScreen> createState() => _PyqNtaScreenState();
}

class _PyqNtaScreenState extends State<PyqNtaScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedYear = 2024;
  String _selectedSource = 'pyq';
  bool _isLoading = false;
  List<QuestionModel> _questions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoading = true);
    final questions = await SupabaseService.fetchQuestions(
      examId: widget.activeExam,
      source: _selectedSource,
    );
    setState(() {
      _questions = questions;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.activeExam} PYQ & NTA Question Banks'),
        bottom: TabBar(
          controller: _tabController,
          onTap: (idx) {
            setState(() {
              _selectedSource = idx == 0 ? 'pyq' : 'nta';
            });
            _loadQuestions();
          },
          tabs: const [
            Tab(icon: Icon(Icons.history_edu_rounded), text: 'Previous Year Papers (PYQ)'),
            Tab(icon: Icon(Icons.verified_rounded), text: 'NTA Official Practice Sets'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text('Select Year: ', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _selectedYear,
                  items: [2025, 2024, 2023, 2022, 2021, 2020].map((y) {
                    return DropdownMenuItem<int>(value: y, child: Text('$y Paper'));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedYear = val);
                      _loadQuestions();
                    }
                  },
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _questions.isEmpty ? null : () => widget.onStartPractice(_questions),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text('Practice All ${_questions.length} Questions'),
                ),
              ],
            ),
          ),

          // Question Bank List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _questions.length,
                    itemBuilder: (ctx, idx) {
                      final q = _questions[idx];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                            child: Text('${idx + 1}', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                          ),
                          title: Text(q.questionText, maxLines: 2, overflow: TextOverflow.ellipsis),
                          subtitle: Text('Source: ${q.sourceName ?? q.source.toUpperCase()} • Marks: +${q.marks.toInt()}/-${q.negativeMarks.toInt()}'),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                          onTap: () => widget.onStartPractice([q]),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
