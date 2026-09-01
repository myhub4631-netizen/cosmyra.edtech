import 'package:flutter_test/flutter_test.dart';
import 'package:cosmyra_edu_flutter/shared/utils/question_copy_helper.dart';

void main() {
  test('Test QuestionCopyHelper clean formatting matching exact user screenshot', () {
    final sampleQ7 = '''
Match List I with List II:

| List I | List II |
| ---------------------------------- | ---------------------------------- |
| A. E = hv | I. de Broglie wavelength |
| B. Diffraction and Interference | II. Particle nature of light |
| C. λ = h/p | III. Wave nature of light |
| D. Compton effect | IV. Energy of photon |

Choose the correct answer from the options given below:
''';

    final options = [
      '(1) A-IV, B-III, C-II, D-I',
      '(2) A-IV, B-III, C-I, D-II',
      '(3) A-I, B-IV, C-III, D-II',
      '(4) A-IV, B-I, C-II, D-III'
    ];

    final result = QuestionCopyHelper.formatForClipboard(
      questionText: sampleQ7,
      options: options,
      questionIndex: 7,
    );

    print("=== RESULT OUTPUT ===");
    print(result);
    print("=====================");

    expect(result.contains('|'), isFalse);
    expect(result.contains('Options:'), isFalse);
    expect(result.contains('Option A:'), isFalse);
    expect(result.contains('(1) A-IV, B-III, C-II, D-I'), isTrue);
  });
}
