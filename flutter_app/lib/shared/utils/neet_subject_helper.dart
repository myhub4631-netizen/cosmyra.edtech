import 'package:flutter/foundation.dart';

/// Helper utility for NEET & JEE Subject-Wise Question Ordering and Test Grid Mapping
class NeetSubjectHelper {
  /// Map UUIDs, codes, or raw string identifiers to canonical subject names
  static String getSubjectNameFromId(String rawId) {
    if (rawId.trim().isEmpty) return '';
    final s = rawId.trim().toLowerCase();

    // Canonical UUID & Code Mappings
    if (s.contains('a1111111') || s.contains('phys')) return 'Physics';
    if (s.contains('a2222222') || s.contains('chem')) return 'Chemistry';
    if (s.contains('a4444444') || s.contains('botan')) return 'Botany';
    if (s.contains('a5555555') || s.contains('zool')) return 'Zoology';
    if (s.contains('a3333333') || s.contains('bio')) return 'Biology';
    if (s.contains('a6666666') || s.contains('math')) return 'Mathematics';

    return rawId;
  }

  /// Calculate subject distribution & ranges for NEET paper of any question count
  static Map<String, dynamic> getNEETSubjectDistribution(int totalQuestions) {
    int p = (totalQuestions * 0.25).round();
    int c = (totalQuestions * 0.25).round();
    int b = totalQuestions - p - c;
    int bot = (b / 2).floor();
    int zoo = b - bot;

    return {
      'physicsCount': p,
      'chemistryCount': c,
      'biologyCount': b,
      'botanyCount': bot,
      'zoologyCount': zoo,
      'physicsRange': [1, p],
      'chemistryRange': [p + 1, p + c],
      'biologyRange': [p + c + 1, totalQuestions],
      'botanyRange': [p + c + 1, p + c + bot],
      'zoologyRange': [p + c + bot + 1, totalQuestions],
    };
  }

  /// Resolve canonical subject name for a 0-indexed question position in a test paper
  static String getSubjectForQuestionIndex(
    int index,
    int totalQuestions, {
    String? explicitSubject,
    bool isNeet = true,
    bool useBotanyZoology = true,
  }) {
    // 1. Resolve explicit subject if provided
    if (explicitSubject != null && explicitSubject.trim().isNotEmpty) {
      final mapped = getSubjectNameFromId(explicitSubject);
      if (mapped.isNotEmpty && mapped != explicitSubject) {
        if (mapped == 'Botany' && !useBotanyZoology) return 'Biology';
        if (mapped == 'Zoology' && !useBotanyZoology) return 'Biology';
        return mapped;
      }
      final s = explicitSubject.trim().toLowerCase();
      if (!s.contains('uuid') && s.length < 30) {
        if (s.contains('physic')) return 'Physics';
        if (s.contains('chemist')) return 'Chemistry';
        if (s.contains('botany')) return useBotanyZoology ? 'Botany' : 'Biology';
        if (s.contains('zoology')) return useBotanyZoology ? 'Zoology' : 'Biology';
        if (s.contains('biolog')) return 'Biology';
        if (s.contains('math')) return 'Mathematics';
      }
    }

    // 2. Infer by canonical paper ranges
    final qNum = index + 1;
    if (isNeet) {
      final dist = getNEETSubjectDistribution(totalQuestions);
      final List<int> pRange = List<int>.from(dist['physicsRange'] as List);
      final List<int> cRange = List<int>.from(dist['chemistryRange'] as List);
      final List<int> botRange = List<int>.from(dist['botanyRange'] as List);

      if (qNum <= pRange[1]) return 'Physics';
      if (qNum <= cRange[1]) return 'Chemistry';
      if (useBotanyZoology) {
        if (qNum <= botRange[1]) return 'Botany';
        return 'Zoology';
      }
      return 'Biology';
    } else {
      // JEE Main / Advanced
      final int perSub = (totalQuestions / 3).round();
      if (qNum <= perSub) return 'Physics';
      if (qNum <= perSub * 2) return 'Chemistry';
      return 'Mathematics';
    }
  }

  /// Returns 0-based question indices corresponding to a target subject
  static List<int> getQuestionIndicesForSubject({
    required String subject,
    required int totalQuestions,
    required List<dynamic> questions,
    bool isNeet = true,
  }) {
    final target = subject.trim().toLowerCase();
    final List<int> indices = [];
    final dist = getNEETSubjectDistribution(totalQuestions);

    final List<int> pRange = List<int>.from(dist['physicsRange'] as List);
    final List<int> cRange = List<int>.from(dist['chemistryRange'] as List);
    final List<int> bRange = List<int>.from(dist['biologyRange'] as List);
    final List<int> botRange = List<int>.from(dist['botanyRange'] as List);
    final List<int> zooRange = List<int>.from(dist['zoologyRange'] as List);

    for (int i = 0; i < totalQuestions; i++) {
      String explicitSub = '';
      if (i < questions.length) {
        final q = questions[i];
        if (q is Map) {
          explicitSub = (q['subject'] ?? q['subject_name'] ?? q['subjectId'] ?? q['subject_id'] ?? '').toString();
        } else {
          try {
            explicitSub = (q.subjectId ?? q.subject ?? q.subjectName ?? '').toString();
          } catch (_) {}
        }
      }

      final resolved = getSubjectForQuestionIndex(
        i,
        totalQuestions,
        explicitSubject: explicitSub,
        isNeet: isNeet,
        useBotanyZoology: true,
      ).toLowerCase();

      bool matches = false;
      if (target == 'physics' && (resolved == 'physics' || (i >= pRange[0] - 1 && i <= pRange[1] - 1))) {
        matches = true;
      } else if (target == 'chemistry' && (resolved == 'chemistry' || (i >= cRange[0] - 1 && i <= cRange[1] - 1))) {
        matches = true;
      } else if (target == 'botany' && (resolved == 'botany' || (resolved == 'biology' && i >= botRange[0] - 1 && i <= botRange[1] - 1))) {
        matches = true;
      } else if (target == 'zoology' && (resolved == 'zoology' || (resolved == 'biology' && i >= zooRange[0] - 1 && i <= zooRange[1] - 1))) {
        matches = true;
      } else if (target == 'biology' && (resolved == 'biology' || resolved == 'botany' || resolved == 'zoology' || (i >= bRange[0] - 1 && i <= bRange[1] - 1))) {
        matches = true;
      } else if (target == 'mathematics' && resolved == 'mathematics') {
        matches = true;
      }

      if (matches) {
        indices.add(i);
      }
    }

    // Fallback if explicit matching produced 0 items
    if (indices.isEmpty) {
      if (target == 'physics') {
        for (int i = pRange[0] - 1; i < pRange[1]; i++) indices.add(i);
      } else if (target == 'chemistry') {
        for (int i = cRange[0] - 1; i < cRange[1]; i++) indices.add(i);
      } else if (target == 'botany') {
        for (int i = botRange[0] - 1; i < botRange[1]; i++) indices.add(i);
      } else if (target == 'zoology') {
        for (int i = zooRange[0] - 1; i < zooRange[1]; i++) indices.add(i);
      } else if (target == 'biology') {
        for (int i = bRange[0] - 1; i < bRange[1]; i++) indices.add(i);
      }
    }

    return indices;
  }

  /// Sorts a list of question maps or models canonically for NEET (Physics -> Chemistry -> Botany -> Zoology)
  static List<T> sortQuestionsForNEET<T>(List<T> questions) {
    final subjectRank = {
      'physics': 1,
      'chemistry': 2,
      'botany': 3,
      'biology': 3,
      'zoology': 4,
      'mathematics': 5,
    };

    final List<T> sorted = List<T>.from(questions);
    sorted.sort((a, b) {
      String rawSubA = '';
      String rawSubB = '';

      if (a is Map) {
        rawSubA = (a['subject'] ?? a['subject_name'] ?? a['subjectId'] ?? a['subject_id'] ?? '').toString();
      } else {
        try {
          rawSubA = (a as dynamic).subjectId?.toString() ?? (a as dynamic).subject?.toString() ?? '';
        } catch (_) {}
      }

      if (b is Map) {
        rawSubB = (b['subject'] ?? b['subject_name'] ?? b['subjectId'] ?? b['subject_id'] ?? '').toString();
      } else {
        try {
          rawSubB = (b as dynamic).subjectId?.toString() ?? (b as dynamic).subject?.toString() ?? '';
        } catch (_) {}
      }

      final subA = getSubjectNameFromId(rawSubA).toLowerCase();
      final subB = getSubjectNameFromId(rawSubB).toLowerCase();

      int rankA = 99;
      int rankB = 99;

      subjectRank.forEach((k, v) {
        if (subA.contains(k) && v < rankA) rankA = v;
        if (subB.contains(k) && v < rankB) rankB = v;
      });

      if (rankA != rankB) {
        return rankA.compareTo(rankB);
      }

      // If ranks are equal, sort by question number if available
      int qNumA = 0;
      int qNumB = 0;

      if (a is Map) {
        qNumA = int.tryParse((a['question_number'] ?? a['questionNumber'] ?? 0).toString()) ?? 0;
      } else {
        try {
          qNumA = (a as dynamic).questionNumber ?? 0;
        } catch (_) {}
      }

      if (b is Map) {
        qNumB = int.tryParse((b['question_number'] ?? b['questionNumber'] ?? 0).toString()) ?? 0;
      } else {
        try {
          qNumB = (b as dynamic).questionNumber ?? 0;
        } catch (_) {}
      }

      if (qNumA > 0 && qNumB > 0) {
        return qNumA.compareTo(qNumB);
      }

      return 0;
    });

    return sorted;
  }
}
