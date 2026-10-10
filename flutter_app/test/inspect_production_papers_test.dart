import 'package:flutter_test/flutter_test.dart';
import '../lib/core/services/supabase_service.dart';

void main() {
  test('Verify ExamPaperFormatConfig and Paper Resolution', () {
    final neetFormat = ExamPaperFormatConfig.getPaperFormat(exam: 'NEET', year: '2026');
    expect(neetFormat['totalQuestions'], equals(180));
    expect(neetFormat['physicsCount'], equals(45));
    expect(neetFormat['chemistryCount'], equals(45));
    expect(neetFormat['botanyCount'], equals(45));
    expect(neetFormat['zoologyCount'], equals(45));

    final jeeFormat = ExamPaperFormatConfig.getPaperFormat(exam: 'JEE Main', year: '2026');
    expect(jeeFormat['totalQuestions'], equals(75));
    expect(jeeFormat['physicsCount'], equals(25));
    expect(jeeFormat['chemistryCount'], equals(25));
    expect(jeeFormat['mathematicsCount'], equals(25));
  });
}
