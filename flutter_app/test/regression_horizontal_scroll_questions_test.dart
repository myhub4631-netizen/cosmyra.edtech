import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cosmyra_neet_jee/shared/widgets/latex_view.dart';
import 'package:cosmyra_neet_jee/shared/widgets/horizontal_scrollable_block.dart';

void main() {
  const q5Text = r'''\item Match List I with List II.

\[
\begin{array}{ll}
\text{List I} & \text{List II}\\
A.\ \text{Genetically modified organism} & I.\ \textit{Agrobacterium tumefaciens}\\
B.\ \text{Thermostable DNA polymerase} & II.\ \text{Bt cotton}\\
C.\ \text{Ti plasmid} & III.\ \textit{Thermus aquaticus}\\
D.\ \text{pBR322} & IV.\ \textit{Escherichia coli}
\end{array}
\]

Choose the correct answer from the options given below:''';

  const q6Text = r'''\item Match List I with List II.

\[
\begin{array}{ll}
\text{List I} & \text{List II}\\
A.\ \text{Productivity} & I.\ \text{Gross primary productivity minus respiration losses}\\
B.\ \text{Net primary productivity} & II.\ \text{Rate of formation of new organic matter by consumers}\\
C.\ \text{Gross primary productivity} & III.\ \text{Rate of biomass production}\\
D.\ \text{Secondary productivity} & IV.\ \text{Rate of production of organic matter during photosynthesis}
\end{array}
\]''';

  const normalQText = '''In angiosperms, root hairs arise from which one of the following regions of the root?
(1) The root cap zone
(2) The region of meristematic activity
(3) The region of elongation
(4) The region of maturation''';

  const markdownTableQText = '''Match List I with List II:

| List I | List II |
| --- | --- |
| A. Mitochondria | I. ATP production |
| B. Chloroplast | II. Photosynthesis in green plant cells |
| C. Ribosome | III. Protein synthesis machinery |
| D. Lysosome | IV. Intracellular hydrolytic digestion |
''';

  const htmlTableQText = '''Match List I with List II:
<table>
  <tr><th>List I</th><th>List II</th></tr>
  <tr><td>A. Transcription</td><td>I. DNA to RNA synthesis</td></tr>
  <tr><td>B. Translation</td><td>II. Protein synthesis from mRNA</td></tr>
</table>''';

  const longEquationText = r'''\[ \Delta G^\circ = -RT \ln K_{eq} = \Delta H^\circ - T \Delta S^\circ = -nFE^\circ_{cell} = \frac{-2.303 RT}{F} \log_{10} K_{eq} \]''';

  group('Regression Test Suite: Wide Questions & Horizontal Scroll Support', () {
    testWidgets('1. Wide two-column matching question (Q5) renders and scrolls horizontally in both directions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 340, // Standard narrow mobile width
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: LaTeXView(text: q5Text),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Zero overflow exceptions thrown during pump
      expect(tester.takeException(), isNull);

      // Verify header text and scrollable block are present
      expect(find.byType(HorizontalScrollableBlock), findsOneWidget);
      expect(find.text('Scroll horizontally'), findsOneWidget);

      // Verify horizontal scroll view has positive scroll extent
      final scrollableFinder = find.descendant(
        of: find.byType(HorizontalScrollableBlock),
        matching: find.byType(SingleChildScrollView),
      );
      expect(scrollableFinder, findsOneWidget);

      final scrollableState = tester.state<ScrollableState>(
        find.descendant(of: scrollableFinder, matching: find.byType(Scrollable)),
      );
      final scrollController = scrollableState.position;
      expect(scrollController.maxScrollExtent, greaterThan(100.0));
      expect(scrollController.pixels, equals(0.0));

      // Scroll right (drag left) to reveal List II completely
      await tester.drag(scrollableFinder, const Offset(-50, 0));
      await tester.pumpAndSettle();
      expect(scrollController.pixels, greaterThan(0.0));

      // Scroll left (drag right) to return to List I
      await tester.drag(scrollableFinder, const Offset(50, 0));
      await tester.pumpAndSettle();
      expect(scrollController.pixels, equals(0.0));
    });

    testWidgets('2. Ecological productivity matching question (Q6) renders without overflow and scrolls', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320, // Compact mobile width
              child: LaTeXView(text: q6Text),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(HorizontalScrollableBlock), findsOneWidget);

      final scrollableFinder = find.descendant(
        of: find.byType(HorizontalScrollableBlock),
        matching: find.byType(SingleChildScrollView),
      );
      // Scroll right and left
      await tester.drag(scrollableFinder, const Offset(-150, 0));
      await tester.pumpAndSettle();
      await tester.drag(scrollableFinder, const Offset(150, 0));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('3. Markdown pipe table question renders as Table and scrolls horizontally', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: LaTeXView(text: markdownTableQText),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(Table), findsOneWidget);
      expect(find.byType(HorizontalScrollableBlock), findsOneWidget);
      expect(find.text('A. Mitochondria'), findsOneWidget);
    });

    testWidgets('4. HTML table question renders as Table with cells and horizontal scrolling', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: LaTeXView(text: htmlTableQText),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(Table), findsOneWidget);
      expect(find.text('A. Transcription'), findsOneWidget);
    });

    testWidgets('5. Normal-width single column question wraps naturally without unnecessary horizontal scroll overflow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              child: LaTeXView(text: normalQText),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Normal text should not create a HorizontalScrollableBlock
      expect(find.byType(HorizontalScrollableBlock), findsNothing);
      expect(find.text('Scroll horizontally'), findsNothing);
      expect(find.byType(SelectableText), findsOneWidget);
    });

    testWidgets('6. Vertical page scrolling remains fully functional with wide question card on screen', (tester) async {
      final verticalController = ScrollController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 500,
              child: SingleChildScrollView(
                key: const ValueKey('vertical_page_scroll'),
                controller: verticalController,
                child: Column(
                  children: [
                    Container(height: 100, color: Colors.blue, child: const Center(child: Text('Top Exam Header'))),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: LaTeXView(text: q5Text),
                    ),
                    Container(height: 400, color: Colors.green, child: const Center(child: Text('Bottom Options Area'))),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(verticalController.offset, equals(0.0));

      final verticalFinder = find.byKey(const ValueKey('vertical_page_scroll'));

      // Drag up to scroll page vertically down
      await tester.drag(verticalFinder, const Offset(0, -50));
      await tester.pumpAndSettle();
      expect(verticalController.offset, greaterThan(0.0));

      // Drag down to scroll page vertically up
      await tester.drag(verticalFinder, const Offset(0, 50));
      await tester.pumpAndSettle();
      expect(verticalController.offset, equals(0.0));
    });

    testWidgets('7. Answer controls remain usable after horizontal scrolling', (tester) async {
      int selectedOption = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SizedBox(
                  width: 340,
                  child: Column(
                    children: [
                      LaTeXView(text: q5Text),
                      const SizedBox(height: 16),
                      // Option radio cards
                      ...List.generate(4, (i) {
                        return ListTile(
                          title: Text('Option ${String.fromCharCode(65 + i)}'),
                          leading: Radio<int>(
                            value: i,
                            groupValue: selectedOption,
                            onChanged: (val) => setState(() => selectedOption = val!),
                          ),
                          onTap: () => setState(() => selectedOption = i),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(selectedOption, equals(-1));

      // Scroll the wide question card
      final scrollableFinder = find.descendant(
        of: find.byType(HorizontalScrollableBlock),
        matching: find.byType(SingleChildScrollView),
      );
      await tester.drag(scrollableFinder, const Offset(-150, 0));
      await tester.pumpAndSettle();

      // Tap Option B
      await tester.tap(find.text('Option B'));
      await tester.pumpAndSettle();
      expect(selectedOption, equals(1));

      // Tap Option D
      await tester.tap(find.text('Option D'));
      await tester.pumpAndSettle();
      expect(selectedOption, equals(3));
    });

    testWidgets('8. Resilient across different mobile viewport widths (320px, 360px, 390px, 412px)', (tester) async {
      for (final width in [320.0, 360.0, 390.0, 412.0]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: width,
                child: LaTeXView(text: q5Text),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Failed on viewport width $width');
        expect(find.byType(HorizontalScrollableBlock), findsOneWidget);
      }
    });

    testWidgets('9. Long mathematical expression scrolls horizontally without overflow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: LaTeXView(text: longEquationText),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(HorizontalScrollableBlock), findsOneWidget);

      final scrollableFinder = find.descendant(
        of: find.byType(HorizontalScrollableBlock),
        matching: find.byType(SingleChildScrollView),
      );
      await tester.drag(scrollableFinder, const Offset(-100, 0));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
