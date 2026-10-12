import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../lib/core/services/supabase_service.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    HttpOverrides.global = MyHttpOverrides();
    SharedPreferences.setMockInitialValues({});
    await SupabaseService.initialize();
  });

  test('Detailed Inspection of 180 Questions for NEET 2026 Paper 1', () async {
    final qRes = await SupabaseService.client
        .from('questions')
        .select('id, question_number, paper, year, subject_id')
        .or('paper.eq.NEET 2026 Paper 1,paper.eq.NEET 2026 Phase 1');

    print('Total Questions Found: ${(qRes as List).length}');
    final List<dynamic> list = qRes;
    
    // Sort by question_number if present
    list.sort((a, b) {
      final qA = int.tryParse((a['question_number'] ?? '0').toString()) ?? 0;
      final qB = int.tryParse((b['question_number'] ?? '0').toString()) ?? 0;
      return qA.compareTo(qB);
    });

    final Map<String, int> subjectIdCounts = {};

    for (var q in list) {
      final sId = (q['subject_id'] ?? '').toString();
      subjectIdCounts[sId] = (subjectIdCounts[sId] ?? 0) + 1;
    }

    print('Subject ID Breakdown: $subjectIdCounts');

    print('\nFirst 5 Questions:');
    for (int i = 0; i < 5 && i < list.length; i++) {
      print('   ${list[i]}');
    }

    print('\nQuestions around 45..50:');
    for (int i = 43; i < 52 && i < list.length; i++) {
      print('   ${list[i]}');
    }

    print('\nQuestions around 90..95:');
    for (int i = 88; i < 97 && i < list.length; i++) {
      print('   ${list[i]}');
    }
  });
}
