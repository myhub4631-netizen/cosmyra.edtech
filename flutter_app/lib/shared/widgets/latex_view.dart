import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

/// Renders math expressions mixed with normal text.
/// Supports inline math delimited by $...$ or \(...\)
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

    final defaultStyle = style ?? Theme.of(context).textTheme.bodyMedium ?? const TextStyle(fontSize: 16);

    // Split text into normal parts and math parts
    final RegExp mathRegex = RegExp(r'\$([^\$]+)\$|\\\(({[^\)]+)|([^\)]+)\\\)');
    final matches = mathRegex.allMatches(text);

    if (matches.isEmpty) {
      return Text(
        text,
        style: defaultStyle,
        textAlign: textAlign,
      );
    }

    List<InlineSpan> spans = [];
    int lastEnd = 0;

    for (final match in matches) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: defaultStyle,
        ));
      }

      String mathExpr = match.group(1) ?? match.group(2) ?? match.group(3) ?? '';
      mathExpr = mathExpr.trim();

      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: Math.tex(
            mathExpr,
            textStyle: defaultStyle,
            onErrorFallback: (err) {
              return Text('\$$mathExpr\$', style: defaultStyle.copyWith(color: Colors.amber.shade800));
            },
          ),
        ),
      ));

      lastEnd = match.end;
    }

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
