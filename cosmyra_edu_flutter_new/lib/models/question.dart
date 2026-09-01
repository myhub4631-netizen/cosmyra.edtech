class QuestionOption {
  final String id;
  final String questionId;
  final int optionIndex;
  final String optionText;
  final bool isCorrect;

  QuestionOption({
    required this.id,
    required this.questionId,
    required this.optionIndex,
    required this.optionText,
    required this.isCorrect,
  });

  factory QuestionOption.fromJson(Map<String, dynamic> json) {
    return QuestionOption(
      id: json['id'] ?? '',
      questionId: json['question_id'] ?? '',
      optionIndex: json['option_index'] ?? 0,
      optionText: json['option_text'] ?? '',
      isCorrect: json['is_correct'] ?? false,
    );
  }
}

class Question {
  final String id;
  final String examId;
  final String subjectId;
  final String chapterId;
  final String questionText;
  final String qType;
  final String difficulty;
  final String source;
  final String? explanation;
  final String? solution;
  final double marks;
  final double negativeMarks;
  final int? year;
  final List<QuestionOption> options;

  Question({
    required this.id,
    required this.examId,
    required this.subjectId,
    required this.chapterId,
    required this.questionText,
    required this.qType,
    required this.difficulty,
    required this.source,
    this.explanation,
    this.solution,
    required this.marks,
    required this.negativeMarks,
    this.year,
    required this.options,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] ?? '',
      examId: json['exam_id'] ?? '',
      subjectId: json['subject_id'] ?? '',
      chapterId: json['chapter_id'] ?? '',
      questionText: json['question_text'] ?? '',
      qType: json['q_type'] ?? 'single_correct',
      difficulty: json['difficulty'] ?? 'medium',
      source: json['source'] ?? 'practice',
      explanation: json['explanation'],
      solution: json['solution'],
      marks: (json['marks'] as num?)?.toDouble() ?? 4.0,
      negativeMarks: (json['negative_marks'] as num?)?.toDouble() ?? 1.0,
      year: json['year'],
      options: (json['options'] as List? ?? [])
          .map((o) => QuestionOption.fromJson(o))
          .toList(),
    );
  }
}
