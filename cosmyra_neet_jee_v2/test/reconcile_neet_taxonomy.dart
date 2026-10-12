import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = MyHttpOverrides();
    SharedPreferences.setMockInitialValues({});
    await SupabaseService.initialize();
  });

  test('Idempotent NEET 2026 Taxonomy & Deduplication Reconciliation', () async {
    final client = Supabase.instance.client;

    print('\n=== STEP 1: AUDIT NEET 2026 PAPER 1 QUESTIONS ===');
    final paperRows = await client
        .from('questions')
        .select('id, question_number, subject_id, chapter_id, topic_id, source, paper')
        .eq('paper', 'NEET 2026 Paper 1')
        .order('question_number', ascending: true);

    print('Found ${paperRows.length} rows for NEET 2026 Paper 1');

    // 1. Check duplicate Q22
    final q22Rows = paperRows.where((r) => r['question_number'] == 22).toList();
    print('Q22 rows count: ${q22Rows.length}');
    for (var r in q22Rows) {
      print('  Q22 ID: ${r['id']}, source: ${r['source']}, subject_id: ${r['subject_id']}');
    }

    if (q22Rows.length > 1) {
      final dup = q22Rows.firstWhere(
        (r) => r['id'].toString().startsWith('69f96550'),
        orElse: () => q22Rows.last,
      );
      print('Deleting duplicate Q22 row: ${dup['id']}');
      final delRes = await client.from('questions').delete().eq('id', dup['id']).select();
      print('Deleted Q22 duplicate: $delRes');
    }

    // 2. Fetch all chapters with their subject_id
    final chapters = await client.from('chapters').select('id, name, subject_id');
    final chapterSubjectMap = <String, String>{};
    for (var c in chapters) {
      chapterSubjectMap[c['id'].toString()] = c['subject_id'].toString();
    }

    // 3. Check and reconcile each question in NEET 2026 Paper 1
    final updatedPaperRows = await client
        .from('questions')
        .select('id, question_number, subject_id, chapter_id, topic_id, source, paper')
        .eq('paper', 'NEET 2026 Paper 1')
        .order('question_number', ascending: true);

    print('\n=== STEP 2: RECONCILING SUBJECT IDS BASED ON CHAPTER & NEET SEQUENCE ===');
    print('Remaining Paper 1 rows: ${updatedPaperRows.length}');

    int phyCount = 0;
    int chemCount = 0;
    int bioCount = 0;
    final List<Map<String, dynamic>> pendingUpdates = [];

    for (var q in updatedPaperRows) {
      final qId = q['id'].toString();
      final qNum = q['question_number'] as int? ?? 0;
      final currentSubId = q['subject_id']?.toString();
      final chId = q['chapter_id']?.toString();

      // Determine expected subject ID:
      // a1111111-1111-1111-1111-111111111111 -> NEET Physics
      // a2222222-2222-2222-2222-222222222222 -> NEET Chemistry
      // a3333333-3333-3333-3333-333333333333 -> NEET Biology
      String targetSubId;
      if (chId != null && chapterSubjectMap.containsKey(chId)) {
        targetSubId = chapterSubjectMap[chId]!;
      } else {
        if (qNum <= 45) {
          targetSubId = 'a1111111-1111-1111-1111-111111111111';
        } else if (qNum <= 90) {
          targetSubId = 'a2222222-2222-2222-2222-222222222222';
        } else {
          targetSubId = 'a3333333-3333-3333-3333-333333333333';
        }
      }

      if (targetSubId.startsWith('a1111111')) phyCount++;
      if (targetSubId.startsWith('a2222222')) chemCount++;
      if (targetSubId.startsWith('a3333333')) bioCount++;

      final updates = <String, dynamic>{};
      if (currentSubId != targetSubId) {
        updates['subject_id'] = targetSubId;
      }
      if (q['source'] != 'pyq') {
        updates['source'] = 'pyq';
      }

      if (updates.isNotEmpty) {
        pendingUpdates.add({'id': qId, 'data': updates});
      }
    }

    print('Pending updates count: ${pendingUpdates.length}');
    // Execute in parallel batches of 15
    for (int i = 0; i < pendingUpdates.length; i += 15) {
      final end = (i + 15 < pendingUpdates.length) ? i + 15 : pendingUpdates.length;
      final batch = pendingUpdates.sublist(i, end);
      await Future.wait(batch.map((item) => client.from('questions').update(item['data']).eq('id', item['id'])));
      print('Updated batch ${i + 1} to $end of ${pendingUpdates.length}');
    }

    print('Reconciliation complete. Updated ${pendingUpdates.length} questions.');
    print('Target distribution: Physics: $phyCount, Chemistry: $chemCount, Biology: $bioCount');

    // 4. Handle stray questions
    print('\n=== STEP 3: RECONCILE STRAY NON-PYQ QUESTIONS ===');
    // b2c05510-7af4-4411-a017-b2c07af4d411 -> Test Series paper
    final stray1 = await client.from('questions').select('id, source, paper').eq('id', 'b2c05510-7af4-4411-a017-b2c07af4d411').maybeSingle();
    if (stray1 != null) {
      print('Updating stray1 b2c05510 source to mock_test (paper: ${stray1['paper']})');
      await client.from('questions').update({'source': 'mock_test'}).eq('id', 'b2c05510-7af4-4411-a017-b2c07af4d411');
    }

    // 2d07a050-41b6-4169-a028-2d0741b60169 -> Practice / unfinalized
    final stray2 = await client.from('questions').select('id, source, paper').eq('id', '2d07a050-41b6-4169-a028-2d0741b60169').maybeSingle();
    if (stray2 != null) {
      print('Updating stray2 2d07a050 source to practice (paper: ${stray2['paper']})');
      await client.from('questions').update({'source': 'practice'}).eq('id', '2d07a050-41b6-4169-a028-2d0741b60169');
    }

    // 5. Final verification of PYQ counts via SupabaseService
    print('\n=== STEP 4: VERIFY SupabaseService.fetchSubjectPYQCounts ===');
    final counts = await SupabaseService.fetchSubjectPYQCounts('NEET 2026');
    print('Fetched counts: $counts');

    expect(counts['Physics'], equals(45));
    expect(counts['Chemistry'], equals(45));
    expect(counts['Biology'], equals(90));
    print('\nSUCCESS! Subject counts strictly match 45 Physics, 45 Chemistry, 90 Biology (Total 180).');
  }, timeout: const Timeout(Duration(minutes: 5)));
}
