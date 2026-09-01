import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/models.dart';

/// Helper utility for extracting clean, user-facing rendered question content
/// suitable for pasting directly into ChatGPT, Word, Google Docs, etc.
class QuestionCopyHelper {
  /// Cleans HTML tags, internal editor JSON/markup, and normalizes line breaks.
  static String cleanTextContent(String raw) {
    if (raw.trim().isEmpty) return '';
    String text = raw;

    // Replace HTML break tags with newlines
    text = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'</div>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'</li>', caseSensitive: false), '\n');

    // Strip remaining HTML tags
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');

    // Replace HTML entities
    text = text.replaceAll('&nbsp;', ' ');
    text = text.replaceAll('&amp;', '&');
    text = text.replaceAll('&lt;', '<');
    text = text.replaceAll('&gt;', '>');
    text = text.replaceAll('&quot;', '"');

    // Normalize multiple consecutive blank lines (more than 2 -> 2)
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return text.trim();
  }

  /// Formats a question into clean, user-facing text with options A, B, C, D.
  static String formatForClipboard({
    required String questionText,
    required List<dynamic> options,
    String? explanation,
    int? questionIndex,
  }) {
    final StringBuffer sb = StringBuffer();

    final String cleanQText = cleanTextContent(questionText);
    if (questionIndex != null && questionIndex > 0) {
      sb.writeln('Q$questionIndex. $cleanQText');
    } else {
      sb.writeln(cleanQText);
    }
    sb.writeln();

    if (options.isNotEmpty) {
      sb.writeln('Options:');
      for (int i = 0; i < options.length; i++) {
        final letter = String.fromCharCode(65 + i); // 'A', 'B', 'C', 'D'
        final opt = options[i];
        String optText = '';
        if (opt is QuestionOptionModel) {
          optText = opt.optionText;
        } else if (opt is Map) {
          optText = (opt['option_text'] ?? opt['optionText'] ?? opt['text'] ?? opt.toString()).toString();
        } else {
          optText = opt.toString();
        }

        final cleanOpt = cleanTextContent(optText);
        sb.writeln('Option $letter: $cleanOpt');
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
