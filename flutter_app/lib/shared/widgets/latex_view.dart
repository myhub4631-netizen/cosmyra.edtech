import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../utils/question_copy_helper.dart';

/// Renders math expressions mixed with normal text seamlessly.
/// Supports inline and display math delimited by:
/// - $$...$$ or \[...\]
/// - $...$ or \(...\)
class LaTeXView extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;

  const LaTeXView({
    Key? key,
    required this.text,
    this.style,
    this.textAlign = TextAlign.start,
  }) : super(key: key);

  /// Helper to normalize multiline vertical fraction copy artifacts like "120\n1\ns"
  static String normalizeText(String raw) {
    if (raw.trim().isEmpty) return raw;
    String str = raw.trim();

    // Convert raw Markdown/ASCII pipe tables (| List I | List II |) & HTML tables into clean text
    if (str.contains('|') || str.contains('<table') || str.contains('<br') || str.contains('</p>')) {
      str = QuestionCopyHelper.cleanTextContent(str);
    }

    // Fix inverted denominator-first fraction artifacts like "8π3mL3" -> "(3mL³)/(8π)"
    str = QuestionCopyHelper.fixInvertedFractionArtifacts(str);

    return str;
  }

  @override
  Widget build(BuildContext context) {
    final cleanText = normalizeText(text);
    if (cleanText.isEmpty) {
      return const SizedBox.shrink();
    }

    final defaultStyle = style ?? Theme.of(context).textTheme.bodyMedium ?? const TextStyle(fontSize: 15, color: Color(0xFF0F172A));

    String processed = cleanText;
    if (!processed.contains('\$') && !processed.contains(r'\(') && !processed.contains(r'\[')) {
      if (processed.contains(r'\frac') ||
          processed.contains(r'\sqrt') ||
          processed.contains(r'\alpha') ||
          processed.contains(r'\beta') ||
          processed.contains(r'\theta') ||
          processed.contains(r'\pi') ||
          processed.contains(r'\infty')) {
        processed = '\$${processed}\$';
      }
    }

    // Regex for matching $$...$$, \[...\], \(...\), and $...$
    final RegExp mathRegex = RegExp(
      r'\$\$(.*?)\$\$|\\\[(.*?)\\\]|\\\((.*?)\\\)|\$([^\$\n]+?)\$',
      dotAll: true,
    );

    final matches = mathRegex.allMatches(processed);

    if (matches.isEmpty) {
      return SelectableText(
        processed,
        style: defaultStyle,
        textAlign: textAlign,
      );
    }

    final List<InlineSpan> spans = [];
    int lastEnd = 0;

    for (final match in matches) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: processed.substring(lastEnd, match.start),
          style: defaultStyle,
        ));
      }

      String mathExpr = match.group(1) ?? match.group(2) ?? match.group(3) ?? match.group(4) ?? '';
      mathExpr = mathExpr.trim();

      if (mathExpr.isNotEmpty) {
        final sanitizedExpr = mathExpr.replaceAll(r'\,', r'\text{ }');

        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: Math.tex(
              sanitizedExpr,
              textStyle: defaultStyle,
              onErrorFallback: (err) {
                try {
                  return Math.tex(
                    mathExpr,
                    textStyle: defaultStyle,
                    onErrorFallback: (_) => Text(
                      mathExpr,
                      style: defaultStyle,
                    ),
                  );
                } catch (_) {
                  return Text(
                    mathExpr,
                    style: defaultStyle,
                  );
                }
              },
            ),
          ),
        ));
      }

      lastEnd = match.end;
    }

    if (lastEnd < processed.length) {
      spans.add(TextSpan(
        text: processed.substring(lastEnd),
        style: defaultStyle,
      ));
    }

    return Semantics(
      label: cleanText,
      value: cleanText,
      child: SelectionArea(
        child: RichText(
          textAlign: textAlign,
          text: TextSpan(children: spans),
        ),
      ),
    );
  }
}
