import 'package:flutter_test/flutter_test.dart';
import 'package:cosmyra_exam_app/main.dart';

void main() {
  testWidgets('Cosmyra App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CosmyraApp());
    expect(find.byType(CosmyraApp), findsOneWidget);
  });
}
