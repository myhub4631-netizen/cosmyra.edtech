/// Practice mode selection for PYQs
enum PYQPracticeMode { chapterWise, yearWise }

/// Filter configuration for PYQ Practice
class PYQFilterConfigModel {
  final String exam; // NEET, JEE Main, JEE Advanced
  final List<String> selectedSubjects; // Physics, Chemistry, Biology / Mathematics
  final PYQPracticeMode mode;
  final List<String> selectedChapterIds;
  final List<String> selectedTopicIds;
  final List<int> selectedYears;
  final String? selectedSession;
  final String? selectedShift;
  final String difficulty; // Mixed, Easy, Medium, Hard
  final String questionType; // All, MCQ, Numerical
  final int questionCount;

  PYQFilterConfigModel({
    required this.exam,
    required this.selectedSubjects,
    this.mode = PYQPracticeMode.chapterWise,
    this.selectedChapterIds = const [],
    this.selectedTopicIds = const [],
    this.selectedYears = const [],
    this.selectedSession,
    this.selectedShift,
    this.difficulty = 'Mixed',
    this.questionType = 'All',
    this.questionCount = 20,
  });

  Map<String, dynamic> toJson() => {
        'exam': exam,
        'selected_subjects': selectedSubjects,
        'mode': mode.name,
        'selected_chapter_ids': selectedChapterIds,
        'selected_topic_ids': selectedTopicIds,
        'selected_years': selectedYears,
        'selected_session': selectedSession,
        'selected_shift': selectedShift,
        'difficulty': difficulty,
        'question_type': questionType,
        'question_count': questionCount,
      };

  factory PYQFilterConfigModel.fromJson(Map<String, dynamic> json) {
    return PYQFilterConfigModel(
      exam: json['exam'] ?? 'NEET',
      selectedSubjects: List<String>.from(json['selected_subjects'] ?? []),
      mode: json['mode'] == 'yearWise' ? PYQPracticeMode.yearWise : PYQPracticeMode.chapterWise,
      selectedChapterIds: List<String>.from(json['selected_chapter_ids'] ?? []),
      selectedTopicIds: List<String>.from(json['selected_topic_ids'] ?? []),
      selectedYears: List<int>.from(json['selected_years'] ?? []),
      selectedSession: json['selected_session'],
      selectedShift: json['selected_shift'],
      difficulty: json['difficulty'] ?? 'Mixed',
      questionType: json['question_type'] ?? 'All',
      questionCount: json['question_count'] ?? 20,
    );
  }
}

/// Subject-wise performance accuracy breakdown for PYQs
class SubjectAccuracyBreakdown {
  final String subjectName;
  final int totalQuestions;
  final int correctCount;
  final int incorrectCount;
  final double accuracy;

  SubjectAccuracyBreakdown({
    required this.subjectName,
    required this.totalQuestions,
    required this.correctCount,
    required this.incorrectCount,
    required this.accuracy,
  });
}

/// Year-wise performance accuracy breakdown for PYQs
class YearAccuracyBreakdown {
  final int year;
  final int totalQuestions;
  final int correctCount;
  final double accuracy;

  YearAccuracyBreakdown({
    required this.year,
    required this.totalQuestions,
    required this.correctCount,
    required this.accuracy,
  });
}

/// PYQ Practice Session Result
class PYQSessionResultModel {
  final String id;
  final String userId;
  final String exam;
  final PYQPracticeMode mode;
  final List<String> subjects;
  final List<int> years;
  final DateTime attemptedAt;
  final int totalQuestions;
  final int attemptedCount;
  final int correctCount;
  final int incorrectCount;
  final int skippedCount;
  final double accuracy;
  final int timeSpentSeconds;
  final List<SubjectAccuracyBreakdown> subjectBreakdowns;
  final List<YearAccuracyBreakdown> yearBreakdowns;

  PYQSessionResultModel({
    required this.id,
    required this.userId,
    required this.exam,
    required this.mode,
    required this.subjects,
    required this.years,
    required this.attemptedAt,
    required this.totalQuestions,
    required this.attemptedCount,
    required this.correctCount,
    required this.incorrectCount,
    required this.skippedCount,
    required this.accuracy,
    required this.timeSpentSeconds,
    this.subjectBreakdowns = const [],
    this.yearBreakdowns = const [],
  });
}
