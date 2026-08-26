import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../shared/widgets/latex_view.dart';
import '../../core/services/supabase_service.dart';
import 'admin_pdf_side_by_side_review_dialog.dart';

class AdminPdfImportPreviewScreen extends StatefulWidget {
  final UserProfileModel userProfile;
  final String jobId;
  final String fileName;
  final String sourceType;
  final String exam;
  final String subject;

  const AdminPdfImportPreviewScreen({
    Key? key,
    required this.userProfile,
    required this.jobId,
    required this.fileName,
    required this.sourceType,
    required this.exam,
    required this.subject,
  }) : super(key: key);

  @override
  State<AdminPdfImportPreviewScreen> createState() => _AdminPdfImportPreviewScreenState();
}

class _AdminPdfImportPreviewScreenState extends State<AdminPdfImportPreviewScreen> {
  final Set<String> _selectedQuestionIds = {};
  late List<Map<String, dynamic>> _extractedQuestions;

  @override
  void initState() {
    super.initState();
    _extractedQuestions = [
      {
        'id': 'EXT_1',
        'question_number': 1,
        'page_number': 1,
        'question_text': r'A block of mass $m = 5\text{ kg}$ rests on a rough horizontal surface with coefficient of static friction $\mu_s = 0.4$. What is the minimum horizontal force $F$ required to initiate motion? (Take $g = 10\text{ m/s}^2$)',
        'subject': 'Physics',
        'chapter': 'Laws of Motion',
        'topic': 'Friction',
        'source_type': widget.sourceType,
        'difficulty': 'Medium',
        'options': [r'$10\text{ N}$', r'$15\text{ N}$', r'$20\text{ N}$', r'$25\text{ N}$'],
        'correct_answer': r'$20\text{ N}$',
        'explanation': r'Limiting static friction is given by $f_s = \mu_s N = \mu_s m g = 0.4 \times 5 \times 10 = 20\text{ N}$.',
        'confidence': 98.5,
        'status': 'ready',
      },
      {
        'id': 'EXT_2',
        'question_number': 2,
        'page_number': 1,
        'question_text': 'Which of the following alkanes gives only one monochloro derivative upon photochemical chlorination?',
        'subject': 'Chemistry',
        'chapter': 'Hydrocarbons',
        'topic': 'Alkanes',
        'source_type': widget.sourceType,
        'difficulty': 'Easy',
        'options': ['n-Pentane', 'Isopentane', 'Neopentane', '2-Methylbutane'],
        'correct_answer': 'Neopentane',
        'explanation': 'Neopentane possesses 12 equivalent hydrogens, yielding a single monochloro product.',
        'confidence': 99.0,
        'status': 'ready',
      },
      {
        'id': 'EXT_3',
        'question_number': 3,
        'page_number': 2,
        'question_text': 'Parietal cells (Oxyntic cells) in the gastric mucosa of human stomach secrete:',
        'subject': 'Biology',
        'chapter': 'Digestion and Absorption',
        'topic': 'Stomach Secretions',
        'source_type': widget.sourceType,
        'difficulty': 'Easy',
        'options': ['Pepsinogen and Mucus', 'HCl and Intrinsic Factor', 'Trypsinogen and Amylase', 'Gastrin and Secretin'],
        'correct_answer': 'HCl and Intrinsic Factor',
        'explanation': 'Oxyntic cells secrete HCl and Castle Intrinsic Factor.',
        'confidence': 94.0,
        'status': 'needs_review',
      },
      {
        'id': 'EXT_4',
        'question_number': 4,
        'page_number': 2,
        'question_text': r'Evaluate the numerical value of $\lim_{x \to 0} \frac{\sin(4x)}{2x}$.',
        'subject': 'Mathematics',
        'chapter': 'Limits and Derivatives',
        'topic': 'Trigonometric Limits',
        'source_type': widget.sourceType,
        'difficulty': 'Medium',
        'options': ['1', '2', '4', '1/2'],
        'correct_answer': '2',
        'explanation': r'Using standard limit formula $\lim_{u \to 0} \frac{\sin u}{u} = 1$.',
        'confidence': 96.5,
        'status': 'ready',
      },
    ];
  }

  void _openSideBySideReview(Map<String, dynamic> question) async {
    final result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AdminPdfSideBySideReviewDialog(
        questionData: question,
        fileName: widget.fileName,
        onSave: (updated) {
          setState(() {
            final idx = _extractedQuestions.indexWhere((q) => q['id'] == updated['id']);
            if (idx != -1) {
              _extractedQuestions[idx] = updated;
            }
          });
        },
      ),
    );

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Question review saved successfully!'), backgroundColor: Color(0xFF16A34A)),
      );
    }
  }

  void _approveAllReadyQuestions() async {
    final readyList = _extractedQuestions.where((q) => q['status'] == 'ready' || q['status'] == 'approved').toList();

    for (var q in readyList) {
      final newQ = {
        'id': 'Q${132202 + DateTime.now().millisecondsSinceEpoch % 1000}',
        'questionText': q['question_text'],
        'subject': q['subject'],
        'chapter': q['chapter'],
        'topic': q['topic'] ?? '',
        'subTopic': '',
        'sourceType': widget.sourceType,
        'difficulty': q['difficulty'],
        'questionType': 'Single Choice (MCQ)',
        'marks': '4',
        'negativeMarks': '1',
        'hasImage': false,
        'tags': [q['subject'], 'Imported PDF'],
        'usedIn': ['Custom Practice', 'Custom Test', 'PYQ Practice', 'NTA Question Practice'],
        'addedOn': 'Just now',
        'options': q['options'],
        'correctAnswer': q['correct_answer'],
        'explanation': q['explanation'],
        'isActive': true,
      };

      await SupabaseService.saveQuestionMap(newQ);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Successfully imported ${readyList.length} questions into main Question Bank!'),
        backgroundColor: const Color(0xFF16A34A),
      ),
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final readyCount = _extractedQuestions.where((q) => q['status'] == 'ready' || q['status'] == 'approved').length;
    final reviewCount = _extractedQuestions.where((q) => q['status'] == 'needs_review').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: Text('Import Preview — ${widget.fileName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Summary Cards
            Row(
              children: [
                _buildMetricCard('Questions Detected', '${_extractedQuestions.length}', Icons.auto_awesome_rounded, const Color(0xFF4F46E5)),
                const SizedBox(width: 16),
                _buildMetricCard('Ready to Import', '$readyCount', Icons.check_circle_rounded, const Color(0xFF16A34A)),
                const SizedBox(width: 16),
                _buildMetricCard('Needs Review', '$reviewCount', Icons.error_outline_rounded, const Color(0xFFF59E0B)),
                const SizedBox(width: 16),
                _buildMetricCard('Duplicates Detected', '0', Icons.copy_rounded, const Color(0xFF64748B)),
              ],
            ),

            const SizedBox(height: 24),

            // Main Preview Data Table Container
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action Header Bar
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Extracted Questions Review Table', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        ElevatedButton.icon(
                          onPressed: readyCount == 0 ? null : _approveAllReadyQuestions,
                          icon: const Icon(Icons.file_download_done_rounded),
                          label: Text('Approve & Import ($readyCount Questions)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // Data Table
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFC)),
                      columns: const [
                        DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Question Text', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Subject', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Chapter', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Confidence', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: _extractedQuestions.map((q) {
                        final isReady = q['status'] == 'ready' || q['status'] == 'approved';
                        return DataRow(
                          cells: [
                            DataCell(Text('Q${q['question_number']}')),
                            DataCell(
                              SizedBox(
                                width: 380,
                                child: LaTeXView(text: q['question_text']),
                              ),
                            ),
                            DataCell(Text(q['subject'])),
                            DataCell(Text(q['chapter'])),
                            DataCell(
                              Row(
                                children: [
                                  SizedBox(
                                    width: 60,
                                    child: LinearProgressIndicator(
                                      value: (q['confidence'] as double) / 100,
                                      backgroundColor: const Color(0xFFE2E8F0),
                                      valueColor: AlwaysStoppedAnimation<Color>(isReady ? const Color(0xFF16A34A) : const Color(0xFFF59E0B)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('${q['confidence']}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isReady ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isReady ? 'Ready' : 'Needs Review',
                                  style: TextStyle(color: isReady ? const Color(0xFF15803D) : const Color(0xFFB45309), fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ),
                            DataCell(
                              ElevatedButton.icon(
                                onPressed: () => _openSideBySideReview(q),
                                icon: const Icon(Icons.remove_red_eye_rounded, size: 14),
                                label: const Text('Review Side-by-Side', style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4F46E5),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
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

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
