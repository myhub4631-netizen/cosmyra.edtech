import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/models.dart';

/// Helper utility for extracting clean, user-facing rendered question content
/// suitable for pasting directly into ChatGPT, Word, Google Docs, WhatsApp, Notes, etc.
class QuestionCopyHelper {
  /// Cleans HTML tags, parses tables into clean aligned plain text without borders/pipes,
  /// normalizes line breaks and decodes HTML entities.
  static String cleanTextContent(String raw) {
    if (raw.trim().isEmpty) return '';
    String text = raw;

    // 1. Convert HTML <table>...</table> blocks into clean aligned plain text
    final tableRegex = RegExp(r'<table[^>]*>(.*?)</table>', dotAll: true, caseSensitive: false);
    text = text.replaceAllMapped(tableRegex, (match) {
      final tableContent = match.group(1) ?? '';
      return _parseHtmlTableToPlainText(tableContent);
    });

    // 2. Convert Markdown / ASCII Pipe tables (| Col 1 | Col 2 |) into clean aligned text
    text = _parsePipeTableToPlainText(text);

    // 3. Convert HTML paragraph and break tags into clean newlines
    text = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n\n');
    text = text.replaceAll(RegExp(r'</div>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'</li>', caseSensitive: false), '\n');

    // 4. Strip any remaining HTML tags
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');

    // 5. Decode HTML entities & Greek/Math symbols
    text = text.replaceAll('&nbsp;', ' ');
    text = text.replaceAll('&amp;', '&');
    text = text.replaceAll('&lt;', '<');
    text = text.replaceAll('&gt;', '>');
    text = text.replaceAll('&quot;', '"');
    text = text.replaceAll('&#39;', "'");
    text = text.replaceAll('&nu;', 'ν');
    text = text.replaceAll('&lambda;', 'λ');
    text = text.replaceAll('&pi;', 'π');
    text = text.replaceAll('&theta;', 'θ');
    text = text.replaceAll('&alpha;', 'α');
    text = text.replaceAll('&beta;', 'β');
    text = text.replaceAll('&infin;', '∞');

    // 6. Normalize line breaks and remove extra trailing blank lines
    text = text.replaceAll(RegExp(r'\r\n|\r'), '\n');
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return text.trim();
  }

  /// Parses HTML table rows and cells into aligned column text without borders
  static String _parseHtmlTableToPlainText(String tableHtml) {
    final trRegex = RegExp(r'<tr[^>]*>(.*?)</tr>', dotAll: true, caseSensitive: false);
    final trMatches = trRegex.allMatches(tableHtml);
    if (trMatches.isEmpty) return tableHtml;

    List<List<String>> tableRows = [];
    for (final tr in trMatches) {
      final rowHtml = tr.group(1) ?? '';
      final cellRegex = RegExp(r'<(?:td|th)[^>]*>(.*?)</(?:td|th)>', dotAll: true, caseSensitive: false);
      final cellMatches = cellRegex.allMatches(rowHtml);
      List<String> rowCells = [];
      for (final cell in cellMatches) {
        String content = cell.group(1) ?? '';
        content = content.replaceAll(RegExp(r'<[^>]*>'), '').trim();
        rowCells.add(content);
      }
      if (rowCells.isNotEmpty) {
        tableRows.add(rowCells);
      }
    }

    return _formatTableRowsToAlignedColumns(tableRows);
  }

  /// Parses Markdown / ASCII Pipe tables into clean aligned plain text
  static String _parsePipeTableToPlainText(String fullText) {
    final lines = fullText.split('\n');
    List<String> resultLines = [];
    List<List<String>> currentTableBuffer = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      // Check if line is part of a pipe table (contains '|' and has multiple sections)
      if (line.startsWith('|') || (line.contains('|') && line.split('|').length >= 3)) {
        // Skip table separator line like "|---|---|" or "| ------ | ------ |"
        if (RegExp(r'^\|?[\s\-:|]+\|?$').hasMatch(line)) {
          continue;
        }

        final rawCells = line.split('|');
        List<String> cells = [];
        for (var c in rawCells) {
          final trimmed = c.trim();
          cells.add(trimmed);
        }

        // Clean out empty leading/trailing cells caused by outer pipes
        if (cells.isNotEmpty && cells.first.isEmpty) cells.removeAt(0);
        if (cells.isNotEmpty && cells.last.isEmpty) cells.removeLast();

        if (cells.isNotEmpty) {
          currentTableBuffer.add(cells);
          continue;
        }
      }

      // Flush table buffer if we exit table section
      if (currentTableBuffer.isNotEmpty) {
        resultLines.add(_formatTableRowsToAlignedColumns(currentTableBuffer));
        currentTableBuffer.clear();
      }

      resultLines.add(lines[i]);
    }

    if (currentTableBuffer.isNotEmpty) {
      resultLines.add(_formatTableRowsToAlignedColumns(currentTableBuffer));
      currentTableBuffer.clear();
    }

    return resultLines.join('\n');
  }

  /// Formats a 2D list of cells into aligned column plain text without pipes/borders
  static String _formatTableRowsToAlignedColumns(List<List<String>> rows) {
    if (rows.isEmpty) return '';

    int maxCols = 0;
    for (final r in rows) {
      if (r.length > maxCols) maxCols = r.length;
    }

    List<int> colWidths = List.filled(maxCols, 0);
    for (final r in rows) {
      for (int c = 0; c < r.length; c++) {
        final cellLen = r[c].length;
        if (cellLen > colWidths[c]) {
          colWidths[c] = cellLen;
        }
      }
    }

    final StringBuffer sb = StringBuffer();
    sb.writeln(); // Blank space before table
    for (final r in rows) {
      final List<String> formattedCells = [];
      for (int c = 0; c < r.length; c++) {
        final cellText = r[c];
        if (c < r.length - 1) {
          // Align column 1 with spacing (minimum padding of 4 spaces)
          final targetWidth = (colWidths[c] < 30) ? 32 : (colWidths[c] + 4);
          formattedCells.add(cellText.padRight(targetWidth));
        } else {
          formattedCells.add(cellText);
        }
      }
      sb.writeln(formattedCells.join(''));
    }
    sb.writeln(); // Blank space after table
    return sb.toString();
  }

  /// Formats a question into clean, user-facing plain text matching exact prompt specification.
  static String formatForClipboard({
    required String questionText,
    required List<dynamic> options,
    String? explanation,
    int? questionIndex,
  }) {
    final StringBuffer sb = StringBuffer();

    final String cleanQText = cleanTextContent(questionText);
    if (questionIndex != null && questionIndex > 0) {
      sb.writeln('$questionIndex.');
      sb.writeln(cleanQText);
    } else {
      sb.writeln(cleanQText);
    }

    if (options.isNotEmpty) {
      sb.writeln();
      for (int i = 0; i < options.length; i++) {
        final opt = options[i];
        String optText = '';
        if (opt is QuestionOptionModel) {
          optText = opt.optionText;
        } else if (opt is Map) {
          optText = (opt['option_text'] ?? opt['optionText'] ?? opt['text'] ?? opt.toString()).toString();
        } else {
          optText = opt.toString();
        }

        String cleanOpt = cleanTextContent(optText);

        // If option text already has numbering/prefix like "(1)", "(A)", "1.", "A.", print as is
        final hasPrefix = RegExp(r'^\(?(\d+|[A-D])[\.\)]\s*', caseSensitive: false).hasMatch(cleanOpt);
        if (hasPrefix) {
          sb.writeln(cleanOpt);
        } else {
          final letter = String.fromCharCode(65 + i);
          sb.writeln('($letter) $cleanOpt');
        }
      }
    }

    if (explanation != null && cleanTextContent(explanation).isNotEmpty) {
      sb.writeln();
      sb.writeln('Explanation / Solution:');
      sb.writeln(cleanTextContent(explanation));
    }

    return sb.toString().trim();
  }

  /// Copies formatted question to clipboard and shows feedback SnackBar.
  static Future<void> copyQuestionToClipboard(
    BuildContext context, {
    required String questionText,
    required List<dynamic> options,
    String? explanation,
    int? questionIndex,
  }) async {
    final String textToCopy = formatForClipboard(
      questionText: questionText,
      options: options,
      explanation: explanation,
      questionIndex: questionIndex,
    );

    await Clipboard.setData(ClipboardData(text: textToCopy));

    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text(
                'Question copied to clipboard cleanly!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  /// Copy helper directly for QuestionModel.
  static Future<void> copyModelToClipboard(
    BuildContext context,
    QuestionModel model, {
    int? questionIndex,
  }) async {
    await copyQuestionToClipboard(
      context,
      questionText: model.questionText,
      options: model.options,
      explanation: model.explanation,
      questionIndex: questionIndex,
    );
  }

  /// Copy helper directly for question Map.
  static Future<void> copyMapToClipboard(
    BuildContext context,
    Map<String, dynamic> map, {
    int? questionIndex,
  }) async {
    List<dynamic> options = [];
    if (map['options'] is List) {
      options = map['options'] as List;
    } else if (map['question_options'] is List) {
      options = map['question_options'] as List;
    }

    await copyQuestionToClipboard(
      context,
      questionText: (map['questionText'] ?? map['question_text'] ?? '').toString(),
      options: options,
      explanation: (map['explanation'] ?? '').toString(),
      questionIndex: questionIndex,
    );
  }
}
