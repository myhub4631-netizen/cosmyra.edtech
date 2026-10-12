import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../utils/question_copy_helper.dart';
import 'horizontal_scrollable_block.dart';

/// Content block interface for structured question rendering
abstract class _ContentBlock {}

class _TextBlock extends _ContentBlock {
  final String text;
  _TextBlock(this.text);
}

class _DisplayMathBlock extends _ContentBlock {
  final String mathExpr;
  _DisplayMathBlock(this.mathExpr);
}

class _TableBlock extends _ContentBlock {
  final List<List<String>> rows;
  final bool hasHeader;
  _TableBlock(this.rows, {this.hasHeader = false});
}

enum _SpanType { math, htmlTable, mdTable }

class _MatchSpan {
  final int start;
  final int end;
  final _SpanType type;
  final String content;
  _MatchSpan(this.start, this.end, this.type, this.content);
}

/// Renders math expressions, tables, and mixed text seamlessly.
/// Supports:
/// - Inline math: $...$ or \(...\)
/// - Display math: $$...$$ or \[...\] or \begin{array|matrix|...}
/// - Horizontal scrolling for oversized content (tables, two-column lists, long equations)
/// - Markdown pipe tables & HTML tables
class LaTeXView extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;

  const LaTeXView({
    super.key,
    required this.text,
    this.style,
    this.textAlign = TextAlign.start,
  });

  /// Normalizes question text, stripping unwanted formatting artifacts while
  /// preserving LaTeX math syntax, tables, and chemical structures.
  static String normalizeText(String raw) {
    if (raw.trim().isEmpty) return raw;
    String str = raw.trim();

    // Strip leading question number prefixes like \textbf{29.} or \textbf{29}
    str = str.replaceAll(RegExp(r'^\\textbf\{\s*(?:Q\.?\s*)?\d+[\.\)]?\s*\}', caseSensitive: false), '').trim();

    // Clean HTML line breaks into standard newlines without stripping table structures
    str = str.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    str = str.replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n\n');
    str = str.replaceAll(RegExp(r'<p[^>]*>', caseSensitive: false), '');
    str = str.replaceAll(RegExp(r'</div>', caseSensitive: false), '\n');
    str = str.replaceAll(RegExp(r'<div[^>]*>', caseSensitive: false), '');
    str = str.replaceAll(RegExp(r'</li>', caseSensitive: false), '\n');
    str = str.replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '');

    // Decode common HTML entities
    str = str.replaceAll('&nbsp;', ' ');
    str = str.replaceAll('&amp;', '&');
    str = str.replaceAll('&lt;', '<');
    str = str.replaceAll('&gt;', '>');
    str = str.replaceAll('&quot;', '"');
    str = str.replaceAll('&#39;', "'");

    // Clean TeX bold/italic macros only outside math environments
    if (!str.contains(r'\begin{') && !str.contains(r'\[') && !str.contains(r'$$') && !str.contains(r'$')) {
      str = str.replaceAllMapped(RegExp(r'\\textbf\{([^\}]+)\}'), (m) => m.group(1) ?? '');
      str = str.replaceAllMapped(RegExp(r'\\textit\{([^\}]+)\}'), (m) => m.group(1) ?? '');
    }

    // Strip enumerate and itemize wrappers
    if (str.contains(r'\begin{enumerate}') || str.contains(r'\begin{itemize}')) {
      str = str.replaceAll(RegExp(r'\\begin\{(?:enumerate|itemize)\}'), '');
      str = str.replaceAll(RegExp(r'\\end\{(?:enumerate|itemize)\}'), '');
    }
    str = str.replaceAll(RegExp(r'\\item\s*'), '\n');

    // Fix inverted denominator-first fraction artifacts like "8π3mL3" -> "(3mL³)/(8π)"
    str = QuestionCopyHelper.fixInvertedFractionArtifacts(str);

    return str.trim();
  }

  static List<_ContentBlock> _parseContentBlocks(String raw) {
    if (raw.trim().isEmpty) return [];

    // Match Display math: \[, $$, or \begin{array|matrix|...}
    final RegExp blockMathRegex = RegExp(
      r'\\\[([\s\S]*?)\\\]|'
      r'\$\$([\s\S]*?)\$\$|'
      r'\\begin\{(array|matrix|pmatrix|bmatrix|vmatrix|Vmatrix|aligned|align|cases|tabular)\*?\}[\s\S]*?\\end\{\1\*?\}',
      caseSensitive: false,
    );

    // Match HTML tables
    final RegExp htmlTableRegex = RegExp(
      r'<table[^>]*>([\s\S]*?)</table>',
      caseSensitive: false,
    );

    // Match Markdown pipe tables: 2 or more lines starting and ending with |
    final RegExp mdTableRegex = RegExp(
      r'(?:^[ \t]*\|.+?\|[ \t]*(?:\r?\n|$)){2,}',
      multiLine: true,
    );

    final List<_MatchSpan> allMatches = [];

    for (final m in blockMathRegex.allMatches(raw)) {
      allMatches.add(_MatchSpan(m.start, m.end, _SpanType.math, m.group(0)!));
    }
    for (final m in htmlTableRegex.allMatches(raw)) {
      allMatches.add(_MatchSpan(m.start, m.end, _SpanType.htmlTable, m.group(0)!));
    }
    for (final m in mdTableRegex.allMatches(raw)) {
      allMatches.add(_MatchSpan(m.start, m.end, _SpanType.mdTable, m.group(0)!));
    }

    allMatches.sort((a, b) => a.start.compareTo(b.start));

    // Filter overlapping spans
    final List<_MatchSpan> filteredMatches = [];
    int curEnd = 0;
    for (final span in allMatches) {
      if (span.start >= curEnd) {
        filteredMatches.add(span);
        curEnd = span.end;
      }
    }

    final List<_ContentBlock> blocks = [];
    int lastIndex = 0;

    for (final span in filteredMatches) {
      if (span.start > lastIndex) {
        final textChunk = raw.substring(lastIndex, span.start).trim();
        if (textChunk.isNotEmpty) {
          blocks.add(_TextBlock(textChunk));
        }
      }

      if (span.type == _SpanType.math) {
        String expr = span.content.trim();
        if (expr.startsWith(r'\[') && expr.endsWith(r'\]')) {
          expr = expr.substring(2, expr.length - 2).trim();
        } else if (expr.startsWith(r'$$') && expr.endsWith(r'$$')) {
          expr = expr.substring(2, expr.length - 2).trim();
        }
        blocks.add(_DisplayMathBlock(expr));
      } else if (span.type == _SpanType.htmlTable) {
        final rows = _parseHtmlTable(span.content);
        if (rows.isNotEmpty) {
          blocks.add(_TableBlock(rows, hasHeader: true));
        } else {
          blocks.add(_TextBlock(span.content));
        }
      } else if (span.type == _SpanType.mdTable) {
        final rows = _parseMdTable(span.content);
        if (rows.isNotEmpty) {
          blocks.add(_TableBlock(rows, hasHeader: true));
        } else {
          blocks.add(_TextBlock(span.content));
        }
      }

      lastIndex = span.end;
    }

    if (lastIndex < raw.length) {
      final textChunk = raw.substring(lastIndex).trim();
      if (textChunk.isNotEmpty) {
        blocks.add(_TextBlock(textChunk));
      }
    }

    return blocks;
  }

  static List<List<String>> _parseHtmlTable(String html) {
    final trRegex = RegExp(r'<tr[^>]*>([\s\S]*?)</tr>', caseSensitive: false);
    final trMatches = trRegex.allMatches(html);
    if (trMatches.isEmpty) return [];

    final List<List<String>> rows = [];
    for (final tr in trMatches) {
      final rowContent = tr.group(1) ?? '';
      final cellRegex = RegExp(r'<(?:td|th)[^>]*>([\s\S]*?)</(?:td|th)>', caseSensitive: false);
      final cellMatches = cellRegex.allMatches(rowContent);
      final List<String> rowCells = [];
      for (final cell in cellMatches) {
        String cellText = cell.group(1) ?? '';
        cellText = cellText.replaceAll(RegExp(r'<[^>]*>'), '').trim();
        rowCells.add(cellText);
      }
      if (rowCells.isNotEmpty) {
        rows.add(rowCells);
      }
    }
    return rows;
  }

  static List<List<String>> _parseMdTable(String md) {
    final lines = md.trim().split(RegExp(r'\r?\n'));
    final List<List<String>> rows = [];

    for (final line in lines) {
      final trimmed = line.trim();
      if (!trimmed.contains('|')) continue;
      // Skip delimiter row like |---|---|
      if (RegExp(r'^[\|\s\-\:]+$').hasMatch(trimmed)) continue;

      String cleanLine = trimmed;
      if (cleanLine.startsWith('|')) cleanLine = cleanLine.substring(1);
      if (cleanLine.endsWith('|')) cleanLine = cleanLine.substring(0, cleanLine.length - 1);

      final cells = cleanLine.split('|').map((c) => c.trim()).toList();
      if (cells.isNotEmpty && cells.any((c) => c.isNotEmpty)) {
        rows.add(cells);
      }
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final cleanText = normalizeText(text);
    if (cleanText.isEmpty) {
      return const SizedBox.shrink();
    }

    final defaultStyle = style ??
        Theme.of(context).textTheme.bodyMedium ??
        const TextStyle(fontSize: 15, color: Color(0xFF0F172A));

    final blocks = _parseContentBlocks(cleanText);

    if (blocks.isEmpty) {
      return SelectableText(
        cleanText,
        style: defaultStyle,
        textAlign: textAlign,
      );
    }

    // Single text block optimization
    if (blocks.length == 1 && blocks.first is _TextBlock) {
      return _renderTextBlock(context, blocks.first as _TextBlock, defaultStyle);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: blocks.map((block) => _renderBlock(context, block, defaultStyle)).toList(),
    );
  }

  Widget _renderBlock(BuildContext context, _ContentBlock block, TextStyle defaultStyle) {
    if (block is _TextBlock) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: _renderTextBlock(context, block, defaultStyle),
      );
    } else if (block is _DisplayMathBlock) {
      return _renderDisplayMathBlock(context, block, defaultStyle);
    } else if (block is _TableBlock) {
      return _renderTableBlock(context, block, defaultStyle);
    }
    return const SizedBox.shrink();
  }

  Widget _renderTextBlock(BuildContext context, _TextBlock block, TextStyle defaultStyle) {
    final str = block.text;

    // Check for inline math patterns: $...$ or \(...\)
    final RegExp inlineMathRegex = RegExp(
      r'\\\(([\s\S]*?)\\\)|\$([^\$\n]+?)\$',
      dotAll: true,
    );

    final matches = inlineMathRegex.allMatches(str);

    if (matches.isEmpty) {
      return SelectableText(
        str,
        style: defaultStyle,
        textAlign: textAlign,
      );
    }

    final List<InlineSpan> spans = [];
    int lastEnd = 0;

    for (final match in matches) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: str.substring(lastEnd, match.start),
          style: defaultStyle,
        ));
      }

      String mathExpr = match.group(1) ?? match.group(2) ?? '';
      mathExpr = mathExpr.trim();

      if (mathExpr.isNotEmpty) {
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: Math.tex(
              mathExpr,
              textStyle: defaultStyle,
              onErrorFallback: (_) => Text(
                mathExpr,
                style: defaultStyle,
              ),
            ),
          ),
        ));
      }

      lastEnd = match.end;
    }

    if (lastEnd < str.length) {
      spans.add(TextSpan(
        text: str.substring(lastEnd),
        style: defaultStyle,
      ));
    }

    return Semantics(
      label: str,
      value: str,
      child: SelectionArea(
        child: RichText(
          textAlign: textAlign,
          text: TextSpan(children: spans),
        ),
      ),
    );
  }

  Widget _renderDisplayMathBlock(BuildContext context, _DisplayMathBlock block, TextStyle defaultStyle) {
    final expr = block.mathExpr;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: HorizontalScrollableBlock(
        child: Math.tex(
          expr,
          textStyle: defaultStyle,
          onErrorFallback: (err) {
            return SelectableText(
              expr,
              style: defaultStyle,
            );
          },
        ),
      ),
    );
  }

  Widget _renderTableBlock(BuildContext context, _TableBlock block, TextStyle defaultStyle) {
    return HorizontalScrollableBlock(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFCBD5E1)),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Table(
            defaultColumnWidth: const IntrinsicColumnWidth(),
            border: TableBorder.all(
              color: const Color(0xFFE2E8F0),
              width: 1,
            ),
            children: block.rows.asMap().entries.map((entry) {
              final rowIndex = entry.key;
              final row = entry.value;
              final isHeader = block.hasHeader && rowIndex == 0;
              return TableRow(
                decoration: BoxDecoration(
                  color: isHeader
                      ? const Color(0xFFF1F5F9)
                      : (rowIndex % 2 == 1 ? const Color(0xFFF8FAFC) : Colors.white),
                ),
                children: row.map((cellText) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: LaTeXView(
                      text: cellText,
                      style: defaultStyle.copyWith(
                        fontWeight: isHeader ? FontWeight.bold : FontWeight.w500,
                        fontSize: isHeader
                            ? (defaultStyle.fontSize ?? 15)
                            : (defaultStyle.fontSize ?? 15) * 0.95,
                        color: isHeader ? const Color(0xFF1E293B) : defaultStyle.color,
                      ),
                    ),
                  );
                }).toList(),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
