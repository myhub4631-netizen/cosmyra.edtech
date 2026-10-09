import 'package:flutter/foundation.dart';

/// Helper utility for NEET & JEE Subject-Wise Question Ordering and Test Grid Mapping
class NeetSubjectHelper {
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
    // 1. Check explicit subject if provided and not a UUID
    if (explicitSubject != null && explicitSubject.trim().isNotEmpty) {
      final s = explicitSubject.trim().toLowerCase();
      if (!s.contains('-') && !s.contains('uuid') && s.length < 30) {
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
      // JEE or General
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
          explicitSub = (q['subject'] ?? q['subject_name'] ?? q['subjectId'] ?? '').toString();
        } else {
          try {
            explicitSub = (q.subject ?? q.subjectName ?? q.subjectId ?? '').toString();
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
      String subA = '';
      String subB = '';

      if (a is Map) {
        subA = (a['subject'] ?? a['subject_name'] ?? a['subjectId'] ?? '').toString().toLowerCase();
      } else {
        try {
          subA = (a as dynamic).subject?.toString().toLowerCase() ?? '';
        } catch (_) {}
      }

      if (b is Map) {
        subB = (b['subject'] ?? b['subject_name'] ?? b['subjectId'] ?? '').toString().toLowerCase();
      } else {
        try {
          subB = (b as dynamic).subject?.toString().toLowerCase() ?? '';
        } catch (_) {}
      }

      int rankA = 99;
      int rankB = 99;

      subjectRank.forEach((k, v) {
        if (subA.contains(k) && v < rankA) rankA = v;
        if (subB.contains(k) && v < rankB) rankB = v;
      });

      return rankA.compareTo(rankB);
    });

    return sorted;
  }
}
