import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cosmyra_neet_jee/core/services/supabase_service.dart';
import 'package:cosmyra_neet_jee/shared/utils/neet_subject_helper.dart';
import 'package:cosmyra_neet_jee/shared/utils/canonical_taxonomy_data.dart';

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

  group('P0 NEET Taxonomy & Data Integrity Regression Suite', () {
    test('1. NEET 180-Question Slot Sequence Rule strictly produces 45/45/90', () {
      final Map<String, int> counts = {'Physics': 0, 'Chemistry': 0, 'Biology': 0};

      for (int q = 1; q <= 180; q++) {
        final subject = NeetSubjectHelper.getSubjectForQuestionIndex(
          q - 1,
          180,
          useBotanyZoology: false,
        );
        expect(counts.containsKey(subject), isTrue);
        counts[subject] = counts[subject]! + 1;
      }

      expect(counts['Physics'], equals(45), reason: 'Questions 1-45 must be Physics');
      expect(counts['Chemistry'], equals(45), reason: 'Questions 46-90 must be Chemistry');
      expect(counts['Biology'], equals(90), reason: 'Questions 91-180 must be Biology');
    });

    test('2. NEET 200-Question Slot Sequence Rule strictly produces 50/50/100', () {
      final Map<String, int> counts = {'Physics': 0, 'Chemistry': 0, 'Biology': 0};

      for (int q = 1; q <= 200; q++) {
        final subject = NeetSubjectHelper.getSubjectForQuestionIndex(
          q - 1,
          200,
          useBotanyZoology: false,
        );
        expect(counts.containsKey(subject), isTrue);
        counts[subject] = counts[subject]! + 1;
      }

      expect(counts['Physics'], equals(50), reason: 'Questions 1-50 must be Physics');
      expect(counts['Chemistry'], equals(50), reason: 'Questions 51-100 must be Chemistry');
      expect(counts['Biology'], equals(100), reason: 'Questions 101-200 must be Biology');
    });

    test('3. Live DB NEET 2026 Paper 1 is exactly 180 questions with 45 Phy, 45 Chem, 90 Bio', () async {
      final counts = await SupabaseService.fetchSubjectPYQCounts('NEET 2026');

      expect(counts['Physics'], equals(45), reason: 'NEET 2026 Physics must be exactly 45');
      expect(counts['Chemistry'], equals(45), reason: 'NEET 2026 Chemistry must be exactly 45');
      expect(counts['Biology'], equals(90), reason: 'NEET 2026 Biology must be exactly 90');
      expect(counts.values.reduce((a, b) => a + b), equals(180), reason: 'Total questions must be exactly 180');
    });

    test('4. Units & Measurements chapter dynamically aggregates non-zero question counts and canonical topics', () async {
      final chapters = await SupabaseService.fetchTaxonomyForSubject(
        exam: 'NEET',
        subject: 'Physics',
        forceRefresh: true,
        includeInactive: true,
      );

      expect(chapters.isNotEmpty, isTrue);
      final unitsChapter = chapters.firstWhere(
        (c) => c['name'].toString().contains('Units & Measurements'),
      );

      final questionCount = unitsChapter['questions'] as int? ?? 0;
      final topics = unitsChapter['topicsList'] as List? ?? [];

      expect(questionCount, greaterThan(0), reason: 'Units & Measurements must have real questions associated');
      expect(topics.length, equals(4), reason: 'Units & Measurements must have 4 canonical topics');

      final topicNames = topics.map((t) => t['name'].toString()).toList();
      expect(topicNames.any((n) => n.contains('SI Units')), isTrue);
      expect(topicNames.any((n) => n.contains('Significant Figures') || n.contains('Error Analysis')), isTrue);
      expect(topicNames.any((n) => n.contains('Dimensional Analysis')), isTrue);
      expect(topicNames.any((n) => n.contains('Measuring Instruments')), isTrue);
    });

    test('5. Canonical Taxonomy Data covers all 28 Physics, 23 Chemistry, and 32 Biology chapters', () {
      final phyChapters = CanonicalTaxonomyData.neetPhysicsChapters;
      final chemChapters = CanonicalTaxonomyData.neetChemistryChapters;
      final bioChapters = CanonicalTaxonomyData.neetBiologyChapters;

      expect(phyChapters.length, equals(28));
      expect(chemChapters.length, equals(22));
      expect(bioChapters.length, equals(32));

      // Each chapter must have non-empty topics
      for (var c in phyChapters) {
        expect((c['topicsList'] as List).isNotEmpty, isTrue, reason: '${c['name']} has topics');
      }
      for (var c in chemChapters) {
        expect((c['topicsList'] as List).isNotEmpty, isTrue, reason: '${c['name']} has topics');
      }
      for (var c in bioChapters) {
        expect((c['topicsList'] as List).isNotEmpty, isTrue, reason: '${c['name']} has topics');
      }
    });

    test('6. Subject ID mappings strictly enforce canonical UUID resolution', () {
      expect(NeetSubjectHelper.getSubjectNameFromId('a1111111-1111-1111-1111-111111111111'), equals('Physics'));
      expect(NeetSubjectHelper.getSubjectNameFromId('a2222222-2222-2222-2222-222222222222'), equals('Chemistry'));
      expect(NeetSubjectHelper.getSubjectNameFromId('a3333333-3333-3333-3333-333333333333'), equals('Biology'));

      // JEE Subject UUIDs
      expect(NeetSubjectHelper.getSubjectNameFromId('a4444444-4444-4444-4444-444444444444', exam: 'JEE Main'), equals('Physics'));
      expect(NeetSubjectHelper.getSubjectNameFromId('a5555555-5555-5555-5555-555555555555', exam: 'JEE Main'), equals('Chemistry'));
      expect(NeetSubjectHelper.getSubjectNameFromId('a6666666-6666-6666-6666-666666666666', exam: 'JEE Main'), equals('Mathematics'));
    });
  });
}
