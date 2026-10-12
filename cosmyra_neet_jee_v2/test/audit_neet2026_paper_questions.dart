import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cosmyra_neet_jee/core/services/supabase_service.dart';

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

  test('Audit NEET 2026 Paper 1 Distinct Questions in Database', () async {
    final res = await SupabaseService.client
        .from('questions')
        .select('id, question_number, paper, year, subject_id')
        .or('paper.eq.NEET 2026 Paper 1,paper.eq.NEET 2026 Phase 1');

    final List<dynamic> rows = res as List;
    print('Total Rows Returned: ${rows.length}');

    final Set<String> distinctIds = {};
    final Set<int> distinctQuestionNumbers = {};
    final Map<int, List<Map<String, dynamic>>> qNumMap = {};

    for (var row in rows) {
      final map = Map<String, dynamic>.from(row as Map);
      final id = map['id'].toString();
      distinctIds.add(id);

      final rawNum = map['question_number'];
      final int qNum = rawNum is num ? rawNum.toInt() : int.tryParse(rawNum?.toString() ?? '0') ?? 0;
      if (qNum > 0) {
        distinctQuestionNumbers.add(qNum);
        qNumMap.putIfAbsent(qNum, () => []).add(map);
      }
    }

    print('Distinct Question IDs: ${distinctIds.length}');
    print('Distinct Question Numbers (1..180): ${distinctQuestionNumbers.length}');

    // Find missing numbers in 1..180 range
    final List<int> missingNumbers = [];
    for (int i = 1; i <= 180; i++) {
      if (!distinctQuestionNumbers.contains(i)) {
        missingNumbers.add(i);
      }
    }
    print('Missing Question Numbers in 1..180 range: $missingNumbers');

    // Find duplicate question numbers
    final List<int> duplicateNumbers = [];
    qNumMap.forEach((num, list) {
      if (list.length > 1) {
        duplicateNumbers.add(num);
      }
    });
    if (duplicateNumbers.isNotEmpty) {
      print('Duplicate Question Numbers: $duplicateNumbers');
      for (var dNum in duplicateNumbers) {
        print('  Question #$dNum has ${qNumMap[dNum]!.length} entries:');
        for (var entry in qNumMap[dNum]!) {
          print('    ID: ${entry['id']} | Paper: ${entry['paper']} | Subject: ${entry['subject_id']}');
        }
      }
    }
  });
}
