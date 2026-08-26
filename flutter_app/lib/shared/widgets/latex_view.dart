import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

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

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    final defaultStyle = style ?? Theme.of(context).textTheme.bodyMedium ?? const TextStyle(fontSize: 15, color: Color(0xFF0F172A));

    // Regex for matching $$...$$, \[...\], \(...\), and $...$
    final RegExp mathRegex = RegExp(
      r'\$\$(.*?)\$\$|\\\[(.*?)\\\]|\\\((.*?)\\\)|\$([^\$\n]+?)\$',
      dotAll: true,
    );

    final matches = mathRegex.allMatches(text);

    if (matches.isEmpty) {
      return Text(
        text,
        style: defaultStyle,
        textAlign: textAlign,
      );
    }

    final List<InlineSpan> spans = [];
    int lastEnd = 0;

    for (final match in matches) {
      // Append text preceding the math match
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: defaultStyle,
        ));
      }

      String mathExpr = match.group(1) ?? match.group(2) ?? match.group(3) ?? match.group(4) ?? '';
      mathExpr = mathExpr.trim();

      if (mathExpr.isNotEmpty) {
        // Sanitize math expressions with units like 5\,kg -> 5\text{ }kg
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

    // Append remaining text after last match
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: defaultStyle,
      ));
    }

    return RichText(
      textAlign: textAlign,
      text: TextSpan(children: spans),
    );
  }
}
