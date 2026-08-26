import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/models.dart';

class AdminPdfImportHistoryScreen extends StatefulWidget {
  final UserProfileModel userProfile;

  const AdminPdfImportHistoryScreen({
    Key? key,
    required this.userProfile,
  }) : super(key: key);

  @override
  State<AdminPdfImportHistoryScreen> createState() => _AdminPdfImportHistoryScreenState();
}

class _AdminPdfImportHistoryScreenState extends State<AdminPdfImportHistoryScreen> {
  List<Map<String, dynamic>> _importHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImportHistory();
  }

  Future<void> _loadImportHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyStr = prefs.getString('cosmyra_pdf_import_history');
      if (historyStr != null && historyStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(historyStr);
        setState(() {
          _importHistory = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('Error loading import history: $e');
    }

    // Default sample job history
    setState(() {
      _importHistory = [
        {
          'id': 'JOB_178776100000',
          'file_name': 'NEET_2024_Physics_Paper_Code_A.pdf',
          'file_size_bytes': 14285712,
          'total_pages': 18,
          'source_type': 'NTA',
          'exam': 'NEET',
          'subject': 'Physics',
          'status': 'completed',
          'created_at': '2026-08-26T22:15:00Z',
          'questions_detected': 50,
          'questions_imported': 50,
          'duplicates_count': 0,
          'errors_count': 0,
        },
        {
          'id': 'JOB_178776200000',
          'file_name': 'JEE_Main_2024_Chemistry_Shift_1.pdf',
          'file_size_bytes': 9410214,
          'total_pages': 14,
          'source_type': 'PYQ',
          'exam': 'JEE Main',
          'subject': 'Chemistry',
          'status': 'awaiting_review',
          'created_at': '2026-08-26T23:30:00Z',
          'questions_detected': 30,
          'questions_imported': 20,
          'duplicates_count': 1,
          'errors_count': 0,
        },
      ];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: const Text('PDF Import Job History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('All PDF Import Jobs & Processing Logs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        ),
                        const Divider(height: 1),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFC)),
                            columns: const [
                              DataColumn(label: Text('Job ID', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('File Name', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Exam / Subject', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Pages', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Detected', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Imported', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: _importHistory.map((job) {
                              final status = job['status'] ?? 'completed';
                              final isCompleted = status == 'completed';

                              return DataRow(
                                cells: [
                                  DataCell(Text(job['id'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                                  DataCell(Text(job['file_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500))),
                                  DataCell(Text('${job['exam']} • ${job['subject']}')),
                                  DataCell(Text('${job['total_pages'] ?? 0}')),
                                  DataCell(Text('${job['questions_detected'] ?? 0}')),
                                  DataCell(Text('${job['questions_imported'] ?? 0}')),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isCompleted ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isCompleted ? 'Completed' : 'Awaiting Review',
                                        style: TextStyle(
                                          color: isCompleted ? const Color(0xFF15803D) : const Color(0xFFB45309),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    TextButton(
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Job logs and details retrieved.')),
                                        );
                                      },
                                      child: const Text('View Logs'),
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
}
