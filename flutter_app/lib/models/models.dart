import 'package:flutter/foundation.dart';

/// User Profile & Role Model
class UserProfileModel {
  final String id;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final String? phoneNumber;
  final String targetExam;
  final int targetYear;
  final String role; // student, admin, teacher
  final int studyStreak;
  final int questionsAttempted;
  final int totalCorrect;
  final double accuracy;
  final int rank;
  final bool isPublicOnLeaderboard;

  UserProfileModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    this.phoneNumber,
    this.targetExam = 'NEET',
    this.targetYear = 2026,
    this.role = 'student',
    this.studyStreak = 1,
    this.questionsAttempted = 0,
    this.totalCorrect = 0,
    this.accuracy = 0.0,
    this.rank = 0,
    this.isPublicOnLeaderboard = true,
  });

  bool get isAdmin => role == 'admin' || role == 'superadmin' || role == 'super_admin' || email.toLowerCase().trim() == '1mdollar2027@gmail.com';
  bool get isSuperAdmin => role == 'superadmin' || role == 'super_admin' || email.toLowerCase().trim() == '1mdollar2027@gmail.com';

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? json['fullName'] ?? 'Student',
      avatarUrl: json['avatar_url'],
      phoneNumber: json['phone_number'],
      targetExam: json['target_exam'] ?? 'NEET',
      targetYear: json['target_year'] ?? 2026,
      role: json['role'] ?? 'student',
      studyStreak: json['study_streak'] ?? json['streak'] ?? 1,
      questionsAttempted: json['questions_attempted'] ?? 0,
      totalCorrect: json['total_correct'] ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      rank: json['rank'] ?? 0,
      isPublicOnLeaderboard: json['is_public_on_leaderboard'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'avatar_url': avatarUrl,
        'phone_number': phoneNumber,
        'target_exam': targetExam,
        'target_year': targetYear,
        'role': role,
        'is_public_on_leaderboard': isPublicOnLeaderboard,
      };
}

/// Exam Model (NEET, JEE Main, JEE Advanced)
class ExamModel {
  final String id;
  final String name;
  final String code;
  final String? description;
  final bool isActive;

  ExamModel({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    this.isActive = true,
  });

  factory ExamModel.fromJson(Map<String, dynamic> json) {
    return ExamModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      description: json['description'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'description': description,
        'is_active': isActive,
      };
}

/// Subject Model (Physics, Chemistry, Biology, Mathematics)
class SubjectModel {
  final String id;
  final String examId;
  final String name;
  final String code;
  final String colorHex;
  final int displayOrder;

  SubjectModel({
    required this.id,
    required this.examId,
    required this.name,
    required this.code,
    required this.colorHex,
    this.displayOrder = 1,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: json['id'] ?? '',
      examId: json['exam_id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      colorHex: json['color_hex'] ?? '#3B82F6',
      displayOrder: json['display_order'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'exam_id': examId,
        'name': name,
        'code': code,
        'color_hex': colorHex,
        'display_order': displayOrder,
      };
}

/// Chapter Model
class ChapterModel {
  final String id;
  final String subjectId;
  final String name;
  final String code;
  final int classLevel;
  final double masteryPercentage;

  ChapterModel({
    required this.id,
    required this.subjectId,
    required this.name,
    required this.code,
    this.classLevel = 11,
    this.masteryPercentage = 0.0,
  });

  factory ChapterModel.fromJson(Map<String, dynamic> json) {
    return ChapterModel(
      id: json['id'] ?? '',
      subjectId: json['subject_id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      classLevel: json['class_level'] ?? 11,
      masteryPercentage: (json['mastery_percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'subject_id': subjectId,
        'name': name,
        'code': code,
        'class_level': classLevel,
      };
}

/// Topic Model
class TopicModel {
  final String id;
  final String chapterId;
  final String name;
  final String code;

  TopicModel({
    required this.id,
    required this.chapterId,
    required this.name,
    required this.code,
  });

  factory TopicModel.fromJson(Map<String, dynamic> json) {
    return TopicModel(
      id: json['id'] ?? '',
      chapterId: json['chapter_id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'chapter_id': chapterId,
        'name': name,
        'code': code,
      };
}

/// Question Option Model
class QuestionOptionModel {
  final String id;
  final String questionId;
  final int optionIndex;
  final String optionText;
  final bool isCorrect;
  final String? optionImage;

  QuestionOptionModel({
    required this.id,
    required this.questionId,
    required this.optionIndex,
    required this.optionText,
    required this.isCorrect,
    this.optionImage,
  });

  factory QuestionOptionModel.fromJson(Map<String, dynamic> json) {
    return QuestionOptionModel(
      id: json['id'] ?? '',
      questionId: json['question_id'] ?? '',
      optionIndex: json['option_index'] ?? 0,
      optionText: json['option_text'] ?? '',
      isCorrect: json['is_correct'] ?? false,
      optionImage: json['option_image'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'question_id': questionId,
        'option_index': optionIndex,
        'option_text': optionText,
        'is_correct': isCorrect,
        'option_image': optionImage,
      };
}

/// Question Model (Single Correct, Multiple Correct, Numerical)
class QuestionModel {
  final String id;
  final String examId;
  final String subjectId;
  final String chapterId;
  final String? topicId;
  final String questionText;
  final String? questionImage;
  final String qType; // single_correct, multiple_correct, numerical
  final String difficulty; // easy, medium, hard
  final String source; // pyq, nta, practice, admin_created
  final String? sourceName;
  final double marks;
  final double negativeMarks;
  final int? year;
  final String? session;
  final String? shift;
  final String? paper;
  final int? questionNumber;
  final String? numericalAnswer;
  final double? numericalTolerance;
  final String? explanation;
  final String? solution;
  final String? hint;
  final List<String> tags;
  final String status; // draft, published, archived
  final List<QuestionOptionModel> options;

  QuestionModel({
    required this.id,
    required this.examId,
    required this.subjectId,
    required this.chapterId,
    this.topicId,
    required this.questionText,
    this.questionImage,
    this.qType = 'single_correct',
    this.difficulty = 'medium',
    this.source = 'practice',
    this.sourceName,
    this.marks = 4.0,
    this.negativeMarks = 1.0,
    this.year,
    this.session,
    this.shift,
    this.paper,
    this.questionNumber,
    this.numericalAnswer,
    this.numericalTolerance,
    this.explanation,
    this.solution,
    this.hint,
    this.tags = const [],
    this.status = 'published',
    required this.options,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    var rawOptions = json['options'] as List? ?? json['question_options'] as List? ?? [];
    List<QuestionOptionModel> parsedOptions = rawOptions
        .map((opt) => QuestionOptionModel.fromJson(opt as Map<String, dynamic>))
        .toList();

    List<String> parsedTags = [];
    if (json['tags'] is List) {
      parsedTags = (json['tags'] as List).map((t) => t.toString()).toList();
    }

    return QuestionModel(
      id: json['id'] ?? '',
      examId: json['exam_id'] ?? '',
      subjectId: json['subject_id'] ?? '',
      chapterId: json['chapter_id'] ?? '',
      topicId: json['topic_id'],
      questionText: json['question_text'] ?? '',
      questionImage: json['question_image'],
      qType: json['q_type'] ?? json['question_type'] ?? 'single_correct',
      difficulty: json['difficulty'] ?? 'medium',
      source: json['source'] ?? 'practice',
      sourceName: json['source_name'],
      marks: (json['marks'] as num?)?.toDouble() ?? 4.0,
      negativeMarks: (json['negative_marks'] as num?)?.toDouble() ?? 1.0,
      year: json['year'] as int?,
      session: json['session'],
      shift: json['shift'],
      paper: json['paper'],
      questionNumber: json['question_number'] as int?,
      numericalAnswer: json['numerical_answer']?.toString(),
      numericalTolerance: (json['numerical_tolerance'] as num?)?.toDouble(),
      explanation: json['explanation'],
      solution: json['solution'],
      hint: json['hint'],
      tags: parsedTags,
      status: json['status'] ?? 'published',
      options: parsedOptions,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'exam_id': examId,
        'subject_id': subjectId,
        'chapter_id': chapterId,
        'topic_id': topicId,
        'question_text': questionText,
        'question_image': questionImage,
        'q_type': qType,
        'difficulty': difficulty,
        'source': source,
        'source_name': sourceName,
        'marks': marks,
        'negative_marks': negativeMarks,
        'year': year,
        'session': session,
        'shift': shift,
        'paper': paper,
        'question_number': questionNumber,
        'numerical_answer': numericalAnswer,
        'numerical_tolerance': numericalTolerance,
        'explanation': explanation,
        'solution': solution,
        'hint': hint,
        'tags': tags,
        'status': status,
      };
}

/// Custom Test Template Model
class TestTemplateModel {
  final String id;
  final String title;
  final String examId;
  final String testType; // custom_test, teacher_test, mock_exam
  final int totalQuestions;
  final double totalMarks;
  final int durationMinutes;
  final double positiveMarks;
  final double negativeMarks;
  final String? instructions;

  TestTemplateModel({
    required this.id,
    required this.title,
    required this.examId,
    this.testType = 'custom_test',
    required this.totalQuestions,
    required this.totalMarks,
    required this.durationMinutes,
    this.positiveMarks = 4.0,
    this.negativeMarks = 1.0,
    this.instructions,
  });

  factory TestTemplateModel.fromJson(Map<String, dynamic> json) {
    return TestTemplateModel(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Mock Test',
      examId: json['exam_id'] ?? '',
      testType: json['test_type'] ?? 'custom_test',
      totalQuestions: json['total_questions'] ?? json['questions'] ?? 30,
      totalMarks: (json['total_marks'] as num?)?.toDouble() ?? 120.0,
      durationMinutes: json['duration_minutes'] ?? 60,
      positiveMarks: (json['positive_marks'] as num?)?.toDouble() ?? 4.0,
      negativeMarks: (json['negative_marks'] as num?)?.toDouble() ?? 1.0,
      instructions: json['instructions'],
    );
  }
}

/// Test Attempt Session
class TestAttemptModel {
  final String id;
  final String userId;
  final String testTemplateId;
  final String testTitle;
  final DateTime startedAt;
  final DateTime expiresAt;
  final DateTime? submittedAt;
  final String status; // in_progress, submitted, expired
  final double? totalScore;
  final double? maxMarks;
  final int totalQuestions;
  final int attemptedCount;
  final int correctCount;
  final int incorrectCount;
  final int unattemptedCount;
  final double accuracy;
  final int timeSpentSeconds;

  TestAttemptModel({
    required this.id,
    required this.userId,
    required this.testTemplateId,
    required this.testTitle,
    required this.startedAt,
    required this.expiresAt,
    this.submittedAt,
    this.status = 'in_progress',
    this.totalScore,
    this.maxMarks,
    this.totalQuestions = 0,
    this.attemptedCount = 0,
    this.correctCount = 0,
    this.incorrectCount = 0,
    this.unattemptedCount = 0,
    this.accuracy = 0.0,
    this.timeSpentSeconds = 0,
  });

  bool get isSubmitted => status == 'submitted' || status == 'expired';

  factory TestAttemptModel.fromJson(Map<String, dynamic> json) {
    return TestAttemptModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      testTemplateId: json['test_template_id'] ?? '',
      testTitle: json['test_title'] ?? json['title'] ?? 'Custom Test',
      startedAt: DateTime.parse(json['started_at'] ?? DateTime.now().toIso8601String()),
      expiresAt: DateTime.parse(json['expires_at'] ?? DateTime.now().add(const Duration(hours: 1)).toIso8601String()),
      submittedAt: json['submitted_at'] != null ? DateTime.parse(json['submitted_at']) : null,
      status: json['status'] ?? 'in_progress',
      totalScore: (json['total_score'] as num?)?.toDouble(),
      maxMarks: (json['max_marks'] as num?)?.toDouble(),
      totalQuestions: json['total_questions'] ?? 0,
      attemptedCount: json['attempted_count'] ?? 0,
      correctCount: json['correct_count'] ?? 0,
      incorrectCount: json['incorrect_count'] ?? 0,
      unattemptedCount: json['unattempted_count'] ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      timeSpentSeconds: json['time_spent_seconds'] ?? 0,
    );
  }
}

/// User Question Bookmark Model
class BookmarkModel {
  final String id;
  final String userId;
  final String questionId;
  final String category; // important, difficult, revision, mistake
  final DateTime createdAt;
  final QuestionModel? question;

  BookmarkModel({
    required this.id,
    required this.userId,
    required this.questionId,
    this.category = 'important',
    required this.createdAt,
    this.question,
  });

  factory BookmarkModel.fromJson(Map<String, dynamic> json) {
    return BookmarkModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      questionId: json['question_id'] ?? '',
      category: json['category'] ?? 'important',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      question: json['question'] != null ? QuestionModel.fromJson(json['question']) : null,
    );
  }
}

/// User Mistake Book Model
class MistakeModel {
  final String id;
  final String userId;
  final String questionId;
  final int attemptCount;
  final String? lastSelectedAnswer;
  final DateTime lastAttemptedAt;
  final QuestionModel? question;

  MistakeModel({
    required this.id,
    required this.userId,
    required this.questionId,
    this.attemptCount = 1,
    this.lastSelectedAnswer,
    required this.lastAttemptedAt,
    this.question,
  });

  factory MistakeModel.fromJson(Map<String, dynamic> json) {
    return MistakeModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      questionId: json['question_id'] ?? '',
      attemptCount: json['attempt_count'] ?? 1,
      lastSelectedAnswer: json['last_selected_answer'],
      lastAttemptedAt: DateTime.parse(json['last_attempted_at'] ?? DateTime.now().toIso8601String()),
      question: json['question'] != null ? QuestionModel.fromJson(json['question']) : null,
    );
  }
}

/// Leaderboard Entry Model
class LeaderboardEntryModel {
  final int rank;
  final String userId;
  final String fullName;
  final String? avatarUrl;
  final double score;
  final int questionsAttempted;
  final double accuracy;
  final int streakDays;

  LeaderboardEntryModel({
    required this.rank,
    required this.userId,
    required this.fullName,
    this.avatarUrl,
    required this.score,
    required this.questionsAttempted,
    required this.accuracy,
    this.streakDays = 1,
  });

  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json, int defaultRank) {
    return LeaderboardEntryModel(
      rank: json['rank'] ?? defaultRank,
      userId: json['user_id'] ?? json['id'] ?? '',
      fullName: json['full_name'] ?? json['fullName'] ?? 'Aspirant',
      avatarUrl: json['avatar_url'],
      score: (json['score'] as num?)?.toDouble() ?? (json['total_score'] as num?)?.toDouble() ?? 0.0,
      questionsAttempted: json['questions_attempted'] ?? json['questions'] ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      streakDays: json['streak_days'] ?? json['streak'] ?? 1,
    );
  }
}

/// Admin Reported Question Model
class ReportModel {
  final String id;
  final String userId;
  final String questionId;
  final String reason;
  final String status; // open, under_review, resolved, rejected
  final DateTime createdAt;
  final QuestionModel? question;
  final String? reporterName;

  ReportModel({
    required this.id,
    required this.userId,
    required this.questionId,
    required this.reason,
    this.status = 'open',
    required this.createdAt,
    this.question,
    this.reporterName,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      questionId: json['question_id'] ?? '',
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'open',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      question: json['question'] != null ? QuestionModel.fromJson(json['question']) : null,
      reporterName: json['reporter_name'] ?? 'Student',
    );
  }
}
