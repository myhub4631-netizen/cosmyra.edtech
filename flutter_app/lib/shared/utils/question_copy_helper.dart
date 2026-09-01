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

    // 6. Convert LaTeX math expressions (\frac{3mL^3}{8\pi} -> (3mL³)/(8π))
    text = convertLatexToPlainText(text);

    // 7. Fix inverted fraction artifacts (8π3mL3 -> (3mL³)/(8π))
    text = fixInvertedFractionArtifacts(text);

    // 8. Normalize line breaks and remove extra trailing blank lines
    text = text.replaceAll(RegExp(r'\r\n|\r'), '\n');
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return text.trim();
  }

  /// Fixes inverted denominator-first copy/extraction artifacts like "8π3mL3" or "8\pi3mL3" -> "(3mL³)/(8π)"
  static String fixInvertedFractionArtifacts(String raw) {
    if (raw.trim().isEmpty) return raw;
    String str = raw.trim();

    // Pattern 1: "8π3mL3" or "8π^2 3mL^3" or "8\pi 3mL3" -> "(3mL³)/(8π)"
    final invertedRegex = RegExp(r'^(\d+\\?(?:pi|π|alpha|beta|gamma|theta|omega|degree|°)?[\^0-9²³]*)\s*(\d+[a-zA-Z]+[\^0-9²³0-9]*)$');
    final match = invertedRegex.firstMatch(str);
    if (match != null) {
      String denom = match.group(1)!;
      String num = match.group(2)!;

      // Clean denominator and numerator
      denom = convertLatexToPlainText(denom);
      num = convertLatexToPlainText(num);

      // Convert trailing digits like "3mL3" -> "3mL³"
      final superDigits = {'0':'⁰','1':'¹','2':'²','3':'³','4':'⁴','5':'⁵','6':'⁶','7':'⁷','8':'⁸','9':'⁹'};
      num = num.replaceAllMapped(RegExp(r'([a-zA-Z])([0-9])$'), (m) {
        return '${m.group(1)}${superDigits[m.group(2)] ?? m.group(2)}';
      });
      denom = denom.replaceAllMapped(RegExp(r'([a-zA-Z])([0-9])$'), (m) {
        return '${m.group(1)}${superDigits[m.group(2)] ?? m.group(2)}';
      });

      return '($num)/($denom)';
    }

    // Pattern 2: Multiline numeric fraction artifact "120\n1\ns"
    final multilineRegex = RegExp(r'^(\d+)\s*[\r\n]+\s*(\d+)\s*[\r\n]+\s*([a-zA-Z°%]+)$');
    final m2 = multilineRegex.firstMatch(str);
    if (m2 != null) {
      final p1 = m2.group(1)!;
      final p2 = m2.group(2)!;
      final u = m2.group(3)!;
      final n1 = int.tryParse(p1) ?? 0;
      final n2 = int.tryParse(p2) ?? 0;
      if (n1 < n2) {
        return '($p1/$p2) $u';
      } else {
        return '($p2/$p1) $u';
      }
    }

    return str;
  }

  /// Converts LaTeX math expressions into clean readable plain text
  static String convertLatexToPlainText(String raw) {
    if (raw.trim().isEmpty) return raw;
    String text = raw;

    // 1. Convert LaTeX fractions \frac{num}{denom} or \dfrac{num}{denom} -> (num)/(denom)
    text = _convertLatexFractions(text);

    // 2. Convert LaTeX square roots \sqrt{x} -> √(x)
    text = text.replaceAllMapped(RegExp(r'\\sqrt\s*\{([^\}]+)\}'), (m) => '√(${m.group(1)})');
    text = text.replaceAll(r'\sqrt', '√');

    // 3. Convert Greek letters
    final greekMap = {
      r'\alpha': 'α', r'\beta': 'β', r'\gamma': 'γ', r'\delta': 'δ',
      r'\epsilon': 'ε', r'\varepsilon': 'ε', r'\zeta': 'ζ', r'\eta': 'η',
      r'\theta': 'θ', r'\iota': 'ι', r'\kappa': 'κ', r'\lambda': 'λ',
      r'\mu': 'μ', r'\nu': 'ν', r'\xi': 'ξ', r'\pi': 'π', r'\rho': 'ρ',
      r'\sigma': 'σ', r'\tau': 'τ', r'\upsilon': 'υ', r'\phi': 'ϕ',
      r'\chi': 'χ', r'\psi': 'ψ', r'\omega': 'ω',
      r'\Gamma': 'Γ', r'\Delta': 'Δ', r'\Theta': 'Θ', r'\Lambda': 'Λ',
      r'\Xi': 'Ξ', r'\Pi': 'Π', r'\Sigma': 'Σ', r'\Upsilon': 'Υ',
      r'\Phi': 'Φ', r'\Psi': 'Ψ', r'\Omega': 'Ω',
    };
    greekMap.forEach((key, value) {
      text = text.replaceAll(key, value);
    });

    // 4. Convert Math operators & symbols
    final mathSymbols = {
      r'\infty': '∞', r'\pm': '±', r'\mp': '∓', r'\times': '×', r'\div': '÷',
      r'\cdot': '·', r'\le': '≤', r'\leq': '≤', r'\ge': '≥', r'\geq': '≥',
      r'\neq': '≠', r'\approx': '≈', r'\propto': '∝', r'\partial': '∂',
      r'\int': '∫', r'\sum': '∑', r'\prod': '∏', r'\degree': '°',
      r'\vec': '', r'\overrightarrow': '', r'\hat': '', r'\bar': '',
      r'\text': '', r'\mathrm': '', r'\mathbf': '', r'\mathit': '',
    };
    mathSymbols.forEach((key, value) {
      text = text.replaceAll(key, value);
    });

    // 5. Convert Superscripts & Subscripts (e.g. L^3 -> L³, x_1 -> x₁)
    text = _convertSuperscriptsAndSubscripts(text);

    // 6. Clean braces and dollar sign enclosers
    text = text.replaceAll(RegExp(r'\$|\$\$|\\\(|\\\)|\\\[|\\\]'), '');
    text = text.replaceAll(RegExp(r'[\{\}]'), '');

    // 7. Clean extra spaces
    text = text.replaceAll(RegExp(r'[ \t]+'), ' ');

    return text.trim();
  }

  static String _convertLatexFractions(String text) {
    String result = text;
    final fracPattern = RegExp(r'\\d?frac\s*\{');
    
    int maxIterations = 20;
    while (fracPattern.hasMatch(result) && maxIterations > 0) {
      maxIterations--;
      final match = fracPattern.firstMatch(result);
      if (match == null) break;
      final startIdx = match.start;

      int numStart = match.end - 1; // pointing at '{'
      int numEnd = _findMatchingBrace(result, numStart);
      if (numEnd == -1) break;
      String numText = result.substring(numStart + 1, numEnd).trim();

      int denomStart = result.indexOf('{', numEnd + 1);
      if (denomStart == -1 || result.substring(numEnd + 1, denomStart).trim().isNotEmpty) {
        break;
      }
      int denomEnd = _findMatchingBrace(result, denomStart);
      if (denomEnd == -1) break;
      String denomText = result.substring(denomStart + 1, denomEnd).trim();

      numText = _convertLatexFractions(numText);
      denomText = _convertLatexFractions(denomText);

      String formattedFrac;
      if (numText.length <= 4 && !numText.contains(' ') && !numText.contains('+') && !numText.contains('-')) {
        formattedFrac = '$numText/$denomText';
      } else {
        formattedFrac = '($numText)/($denomText)';
      }

      result = result.substring(0, startIdx) + formattedFrac + result.substring(denomEnd + 1);
    }

    return result;
  }

  static int _findMatchingBrace(String text, int openPos) {
    int depth = 0;
    for (int i = openPos; i < text.length; i++) {
      if (text[i] == '{') {
        depth++;
      } else if (text[i] == '}') {
        depth--;
        if (depth == 0) return i;
      }
    }
    return -1;
  }

  static String _convertSuperscriptsAndSubscripts(String text) {
    final superMap = {'0':'⁰','1':'¹','2':'²','3':'³','4':'⁴','5':'⁵','6':'⁶','7':'⁷','8':'⁸','9':'⁹','+':'⁺','-':'⁻','=':'⁼','(':'⁽',')':'⁾','n':'ⁿ','i':'ⁱ'};
    final subMap   = {'0':'₀','1':'₁','2':'₂','3':'₃','4':'₄','5':'₅','6':'₆','7':'₇','8':'₈','9':'₉','+':'₊','-':'₋','=':'₌','(':'₍',')':'₎','a':'ₐ','e':'ₑ','o':'ₒ','x':'ₓ'};

    String res = text;

    res = res.replaceAllMapped(RegExp(r'\^\{([^\}]+)\}'), (match) {
      final inner = match.group(1) ?? '';
      final converted = inner.split('').map((ch) => superMap[ch] ?? ch).join('');
      return converted;
    });
    res = res.replaceAllMapped(RegExp(r'\^([0-9a-zA-Z])'), (match) {
      final ch = match.group(1) ?? '';
      return superMap[ch] ?? '^$ch';
    });

    res = res.replaceAllMapped(RegExp(r'_\{([^\}]+)\}'), (match) {
      final inner = match.group(1) ?? '';
      final converted = inner.split('').map((ch) => subMap[ch] ?? ch).join('');
      return converted;
    });
    res = res.replaceAllMapped(RegExp(r'_([0-9a-zA-Z])'), (match) {
      final ch = match.group(1) ?? '';
      return subMap[ch] ?? '_$ch';
    });

    return res;
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
