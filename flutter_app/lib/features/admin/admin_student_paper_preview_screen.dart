import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/supabase_service.dart';
import '../../models/models.dart';
import '../tests/test_screen.dart';
import '../tests/test_result_screen.dart';

class AdminStudentPaperPreviewScreen extends StatefulWidget {
  final String paperId;

  const AdminStudentPaperPreviewScreen({
    Key? key,
    required this.paperId,
  }) : super(key: key);

  @override
  State<AdminStudentPaperPreviewScreen> createState() => _AdminStudentPaperPreviewScreenState();
}

class _AdminStudentPaperPreviewScreenState extends State<AdminStudentPaperPreviewScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<QuestionModel> _questions = [];
  Map<String, dynamic>? _paperMetadata;
  int _durationMinutes = 180;

  bool _showResultScreen = false;
  TestAttemptModel? _submittedAttempt;
  Map<int, String> _submittedAnswers = {};

  @override
  void initState() {
    super.initState();
    _loadPaperAndQuestions();
  }

  Future<void> _loadPaperAndQuestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final allPapers = await SupabaseService.fetchAllPapersAndTestSeries(forceRefresh: true);
      final pMeta = allPapers.firstWhere(
        (p) => (p['id'] ?? p['paper_id'] ?? '').toString() == widget.paperId,
        orElse: () => <String, dynamic>{},
      );

      final qList = await SupabaseService.fetchTestSeriesQuestions(paperId: widget.paperId);

      if (mounted) {
        setState(() {
          _paperMetadata = pMeta;
          _questions = qList;
          final exam = (pMeta['exam'] ?? pMeta['exam_name'] ?? 'NEET').toString().toUpperCase();
          if (exam.contains('JEE')) {
            _durationMinutes = 180;
          } else {
            _durationMinutes = 180;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load paper: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _handleTestSubmitted(TestAttemptModel attempt, Map<int, String> userAnswers) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: Color(0xFF16A34A), size: 28),
            SizedBox(width: 10),
            Text('Admin Preview Completed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Preview completed successfully. No student attempt, result, or progress data was saved to the database.',
              style: TextStyle(fontSize: 13.5, color: Color(0xFF334155), height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, size: 18, color: Color(0xFF475569)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Score: ${attempt.totalScore?.toStringAsFixed(1) ?? '0'} / ${attempt.maxMarks?.toStringAsFixed(1) ?? '720'}  |  Accuracy: ${attempt.accuracy}%',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/admin/papers');
            },
            child: const Text('Exit to Catalogue'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _submittedAttempt = attempt;
                _submittedAnswers = userAnswers;
                _showResultScreen = true;
              });
            },
            child: const Text('View Report Preview', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF7C3AED)),
              SizedBox(height: 16),
              Text('Loading student preview interface...', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null || _questions.isEmpty) {
      final paperTitle = (_paperMetadata?['paper_name'] ?? _paperMetadata?['title'] ?? widget.paperId).toString();
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Admin Student Preview'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/admin/papers'),
          ),
        ),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 350, maxWidth: 480),
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10)],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 48, color: Color(0xFFD97706)),
                const SizedBox(height: 12),
                Text('Paper Empty or Missing', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  _errorMessage ?? 'No questions available for paper "$paperTitle" ($widget.paperId).',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => context.go('/admin/papers'),
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: const Text('Back to Catalogue'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
                      onPressed: _loadPaperAndQuestions,
                      icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
                      label: const Text('Retry Loading', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_showResultScreen && _submittedAttempt != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF7C3AED),
          title: const Text('Admin Preview — Result Report', style: TextStyle(color: Colors.white, fontSize: 16)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => setState(() => _showResultScreen = false),
          ),
        ),
        body: Column(
          children: [
            _buildAdminPreviewBanner(),
            Expanded(
              child: TestResultScreen(
                attempt: _submittedAttempt!,
                questions: _questions,
                userAnswers: _submittedAnswers,
                onBackToDashboard: () => context.go('/admin/papers'),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildAdminPreviewBanner(),
            Expanded(
              child: CustomTestScreen(
                questions: _questions,
                durationMinutes: _durationMinutes,
                isPreview: true,
                onTestSubmitted: _handleTestSubmitted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminPreviewBanner() {
    final paperTitle = (_paperMetadata?['paper_name'] ?? _paperMetadata?['title'] ?? widget.paperId).toString();
    final exam = (_paperMetadata?['exam'] ?? 'NEET').toString();
    final year = (_paperMetadata?['year'] ?? '').toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFFEF3C7),
        border: Border(bottom: BorderSide(color: Color(0xFFFDE68A), width: 1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFD97706).withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFFB45309), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text(
                      'ADMIN PREVIEW — NO RESULTS WILL BE SAVED',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF92400E),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$exam $year',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Simulating student exam flow for "$paperTitle" (${_questions.length} Questions). All answers and attempts are isolated in memory.',
                  style: const TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF92400E),
              side: const BorderSide(color: Color(0xFFF59E0B)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => context.go('/admin/papers'),
            icon: const Icon(Icons.exit_to_app_rounded, size: 14),
            label: const Text('Exit Preview', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
