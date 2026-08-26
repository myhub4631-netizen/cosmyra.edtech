import 'package:flutter/material.dart';
import '../../shared/widgets/latex_view.dart';

class AdminPdfSideBySideReviewDialog extends StatefulWidget {
  final Map<String, dynamic> questionData;
  final String fileName;
  final Function(Map<String, dynamic> updatedData)? onSave;

  const AdminPdfSideBySideReviewDialog({
    Key? key,
    required this.questionData,
    required this.fileName,
    this.onSave,
  }) : super(key: key);

  @override
  State<AdminPdfSideBySideReviewDialog> createState() => _AdminPdfSideBySideReviewDialogState();
}

class _AdminPdfSideBySideReviewDialogState extends State<AdminPdfSideBySideReviewDialog> {
  late TextEditingController _questionTextController;
  late TextEditingController _explanationController;
  late String _selectedSubject;
  late String _selectedChapter;
  late String _selectedSource;
  late String _selectedDifficulty;
  late String _correctAnswer;
  late List<TextEditingController> _optionControllers;
  int _pdfPageNumber = 1;
  double _pdfZoom = 1.0;

  @override
  void initState() {
    super.initState();
    _pdfPageNumber = widget.questionData['page_number'] ?? 1;
    _questionTextController = TextEditingController(text: widget.questionData['question_text'] ?? '');
    _explanationController = TextEditingController(text: widget.questionData['explanation'] ?? '');
    _selectedSubject = widget.questionData['subject'] ?? 'Physics';
    _selectedChapter = widget.questionData['chapter'] ?? 'Laws of Motion';
    _selectedSource = widget.questionData['source_type'] ?? 'NTA';
    _selectedDifficulty = widget.questionData['difficulty'] ?? 'Medium';
    _correctAnswer = widget.questionData['correct_answer'] ?? 'Option A';

    final opts = widget.questionData['options'] as List? ?? ['Option A', 'Option B', 'Option C', 'Option D'];
    _optionControllers = opts.map((opt) {
      if (opt is Map) {
        return TextEditingController(text: opt['text'] ?? '');
      }
      return TextEditingController(text: opt.toString());
    }).toList();
  }

  @override
  void dispose() {
    _questionTextController.dispose();
    _explanationController.dispose();
    for (var c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _handleSaveAndApprove() {
    final updated = {
      ...widget.questionData,
      'question_text': _questionTextController.text,
      'explanation': _explanationController.text,
      'subject': _selectedSubject,
      'chapter': _selectedChapter,
      'source_type': _selectedSource,
      'difficulty': _selectedDifficulty,
      'correct_answer': _correctAnswer,
      'options': _optionControllers.map((c) => c.text).toList(),
      'status': 'approved',
    };

    if (widget.onSave != null) {
      widget.onSave!(updated);
    }
    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.92,
        height: MediaQuery.of(context).size.height * 0.90,
        child: Column(
          children: [
            // Top Modal Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.picture_in_picture_rounded, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Side-by-Side Review — Question #${widget.questionData['question_number'] ?? 1} (${widget.fileName})',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Confidence: ${(widget.questionData['confidence'] ?? 97.5)}%',
                      style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Main Split Workspace
            Expanded(
              child: Row(
                children: [
                  // Left Side: PDF Document Page Viewer
                  Expanded(
                    flex: 5,
                    child: Container(
                      color: const Color(0xFFF1F5F9),
                      child: Column(
                        children: [
                          // PDF Viewer Toolbar
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            color: Colors.white,
                            child: Row(
                              children: [
                                const Text('Original PDF Page', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.navigate_before_rounded),
                                  onPressed: _pdfPageNumber > 1 ? () => setState(() => _pdfPageNumber--) : null,
                                ),
                                Text('Page $_pdfPageNumber', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                IconButton(
                                  icon: const Icon(Icons.navigate_next_rounded),
                                  onPressed: () => setState(() => _pdfPageNumber++),
                                ),
                                const VerticalDivider(indent: 8, endIndent: 8),
                                IconButton(
                                  icon: const Icon(Icons.zoom_out_rounded, size: 20),
                                  onPressed: () => setState(() => _pdfZoom = (_pdfZoom - 0.2).clamp(0.6, 2.5)),
                                ),
                                Text('${(_pdfZoom * 100).toInt()}%', style: const TextStyle(fontSize: 12)),
                                IconButton(
                                  icon: const Icon(Icons.zoom_in_rounded, size: 20),
                                  onPressed: () => setState(() => _pdfZoom = (_pdfZoom + 0.2).clamp(0.6, 2.5)),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),

                          // PDF Render Canvas
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(24),
                              child: Center(
                                child: Transform.scale(
                                  scale: _pdfZoom,
                                  child: Container(
                                    width: 520,
                                    padding: const EdgeInsets.all(28),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4)),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('NEET / JEE EXAM PAPER — PAGE $_pdfPageNumber', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                                            const Text('CODE A1', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                                          ],
                                        ),
                                        const Divider(height: 16),
                                        Text(
                                          'Q${widget.questionData['question_number'] ?? 1}. ${widget.questionData['raw_text'] ?? widget.questionData['question_text']}',
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A), height: 1.5),
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(r'(A) $10\text{ N}$', style: TextStyle(fontSize: 13, color: Color(0xFF334155))),
                                        const SizedBox(height: 6),
                                        const Text(r'(B) $15\text{ N}$', style: TextStyle(fontSize: 13, color: Color(0xFF334155))),
                                        const SizedBox(height: 6),
                                        const Text(r'(C) $20\text{ N}$', style: TextStyle(fontSize: 13, color: Color(0xFF334155))),
                                        const SizedBox(height: 6),
                                        const Text(r'(D) $25\text{ N}$', style: TextStyle(fontSize: 13, color: Color(0xFF334155))),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const VerticalDivider(width: 1),

                  // Right Side: Structured Extracted Question Editor
                  Expanded(
                    flex: 6,
                    child: Container(
                      color: Colors.white,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Structured Question Editor', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            const SizedBox(height: 16),

                            // Question Text Field
                            const Text('Question Text (LaTeX Supported)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569))),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _questionTextController,
                              maxLines: 4,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),

                            const SizedBox(height: 12),

                            // LaTeX Live Preview
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('LaTeX Live Render Preview:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                  const SizedBox(height: 6),
                                  LaTeXView(text: _questionTextController.text),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Options A-D Editor
                            const Text('Options', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                            const SizedBox(height: 10),
                            ...List.generate(_optionControllers.length, (idx) {
                              final label = String.fromCharCode(65 + idx);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: const Color(0xFFEEF2FF),
                                      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF4F46E5))),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextField(
                                        controller: _optionControllers[idx],
                                        decoration: InputDecoration(
                                          isDense: true,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),

                            const SizedBox(height: 16),

                            // Correct Answer Dropdown
                            const Text('Correct Answer', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569))),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: _correctAnswer,
                              decoration: InputDecoration(
                                isDense: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              items: ['Option A', 'Option B', 'Option C', 'Option D', r'$20\text{ N}$', 'Neopentane', 'HCl and Intrinsic Factor']
                                  .map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                              onChanged: (v) => setState(() => _correctAnswer = v!),
                            ),

                            const SizedBox(height: 16),

                            // Explanation Box
                            const Text('Explanation / Solution', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569))),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _explanationController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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

            // Bottom Actions Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Cancel'),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _handleSaveAndApprove,
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text('Save & Approve Question'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
}
