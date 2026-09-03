import 'package:flutter/foundation.dart';
export 'cms_models.dart';

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

  // Academic Profile & Goal Details
  final String classLevel; // 'Dropper', 'Class 12', 'Class 11'
  final String preferredLanguage; // 'English', 'Hindi'
  final String targetScore; // '650+', '700+'
  final String targetRank; // 'Top 10,000', 'Top 1,000'
  final String subjectsFocus; // 'PCB', 'PCM'
  final String studyGoal; // 'MBBS in Govt. College', 'IIT Bombay CS'
  final String city; // 'Supaul'
  final String state; // 'Bihar'

  UserProfileModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    this.phoneNumber,
    this.targetExam = 'NEET',
    this.targetYear = 2026,
    this.role = 'student',
    this.studyStreak = 7,
    this.questionsAttempted = 2840,
    this.totalCorrect = 2215,
    this.accuracy = 78.0,
    this.rank = 1284,
    this.isPublicOnLeaderboard = true,
    this.classLevel = 'Dropper',
    this.preferredLanguage = 'English',
    this.targetScore = '650+',
    this.targetRank = 'Top 10,000',
    this.subjectsFocus = 'PCB',
    this.studyGoal = 'MBBS in Govt. College',
    this.city = 'Supaul',
    this.state = 'Bihar',
  });

  bool get isAdmin =>
      role == 'admin' ||
      role == 'superadmin' ||
      role == 'super_admin' ||
      email.toLowerCase().trim() == '1mdollar2027@gmail.com';

  bool get isSuperAdmin =>
      role == 'superadmin' ||
      role == 'super_admin' ||
      email.toLowerCase().trim() == '1mdollar2027@gmail.com';

  UserProfileModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? avatarUrl,
    String? phoneNumber,
    String? targetExam,
    int? targetYear,
    String? role,
    int? studyStreak,
    int? questionsAttempted,
    int? totalCorrect,
    double? accuracy,
    int? rank,
    bool? isPublicOnLeaderboard,
    String? classLevel,
    String? preferredLanguage,
    String? targetScore,
    String? targetRank,
    String? subjectsFocus,
    String? studyGoal,
    String? city,
    String? state,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      targetExam: targetExam ?? this.targetExam,
      targetYear: targetYear ?? this.targetYear,
      role: role ?? this.role,
      studyStreak: studyStreak ?? this.studyStreak,
      questionsAttempted: questionsAttempted ?? this.questionsAttempted,
      totalCorrect: totalCorrect ?? this.totalCorrect,
      accuracy: accuracy ?? this.accuracy,
      rank: rank ?? this.rank,
      isPublicOnLeaderboard: isPublicOnLeaderboard ?? this.isPublicOnLeaderboard,
      classLevel: classLevel ?? this.classLevel,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      targetScore: targetScore ?? this.targetScore,
      targetRank: targetRank ?? this.targetRank,
      subjectsFocus: subjectsFocus ?? this.subjectsFocus,
      studyGoal: studyGoal ?? this.studyGoal,
      city: city ?? this.city,
      state: state ?? this.state,
    );
  }

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? json['fullName'] ?? 'Mahboob Hasan',
      avatarUrl: json['avatar_url'],
      phoneNumber: json['phone_number'],
      targetExam: json['target_exam'] ?? 'NEET',
      targetYear: json['target_year'] ?? 2026,
      role: json['role'] ?? 'student',
      studyStreak: json['study_streak'] ?? json['streak'] ?? 7,
      questionsAttempted: json['questions_attempted'] ?? 2840,
      totalCorrect: json['total_correct'] ?? 2215,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 78.0,
      rank: json['rank'] ?? 1284,
      isPublicOnLeaderboard: json['is_public_on_leaderboard'] ?? true,
      classLevel: json['class_level'] ?? json['classLevel'] ?? 'Dropper',
      preferredLanguage: json['preferred_language'] ?? json['preferredLanguage'] ?? 'English',
      targetScore: json['target_score'] ?? json['targetScore'] ?? '650+',
      targetRank: json['target_rank'] ?? json['targetRank'] ?? 'Top 10,000',
      subjectsFocus: json['subjects_focus'] ?? json['subjectsFocus'] ?? 'PCB',
      studyGoal: json['study_goal'] ?? json['studyGoal'] ?? 'MBBS in Govt. College',
      city: json['city'] ?? 'Supaul',
      state: json['state'] ?? 'Bihar',
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
        'class_level': classLevel,
        'preferred_language': preferredLanguage,
        'target_score': targetScore,
        'target_rank': targetRank,
        'subjects_focus': subjectsFocus,
        'study_goal': studyGoal,
        'city': city,
        'state': state,
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
  final List<String> availableIn; // ['custom_practice', 'custom_test', 'pyq_practice', 'nta_questions', 'test_series']
  final String status; // draft, published, archived
  final List<QuestionOptionModel> options;

  static const List<String> allVisibilityKeys = [
    'custom_practice',
    'custom_test',
    'pyq_practice',
    'nta_questions',
    'test_series',
  ];

  static const Map<String, String> visibilityLabelsMap = {
    'custom_practice': 'Custom Practice',
    'custom_test': 'Custom Test',
    'pyq_practice': 'PYQ Practice',
    'nta_questions': 'NTA Questions',
    'test_series': 'Test Series',
  };

  static bool _isTechnicalId(String? s) {
    if (s == null) return true;
    final str = s.trim();
    if (str.isEmpty) return true;
    if (RegExp(r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}').hasMatch(str)) return true;
    if (str.contains('11111111-1111') || str.contains('00000000-0000')) return true;
    final lower = str.toLowerCase();
    if (lower.startsWith('tmpl-') || lower.startsWith('att-') || lower.startsWith('session_') || lower.startsWith('opt_') || lower.startsWith('q_')) return true;
    if (lower == 'practice question' || lower == 'pyq' || lower == 'nta' || lower == 'custom_practice' || lower == 'custom_test') return true;
    return false;
  }

  /// Returns clean human-readable question source (e.g., "NEET 2026 Phase 1", "NTA Abhyas Test 14", "JEE Main 2024 Shift 1")
  String get displaySource {
    final String sName = (sourceName ?? '').trim();
    if (sName.isNotEmpty && !_isTechnicalId(sName)) {
      return sName;
    }

    final String paperStr = (paper ?? '').trim();
    if (paperStr.isNotEmpty && !_isTechnicalId(paperStr)) {
      return paperStr;
    }

    final List<String> parts = [];
    String eId = examId.trim();
    if (_isTechnicalId(eId)) {
      eId = '';
    }

    final String uSource = source.trim().toUpperCase();

    if (eId.isNotEmpty) {
      parts.add(eId.toUpperCase());
    } else if (uSource == 'PYQ' || uSource.contains('NEET') || uSource.contains('JEE') || uSource == 'PRACTICE' || uSource == 'CUSTOM_TEST' || uSource == 'CUSTOM_PRACTICE') {
      if (uSource.contains('JEE')) {
        parts.add('JEE Main');
      } else {
        parts.add('NEET');
      }
    } else if (uSource == 'NTA' || uSource == 'NTA_QUESTIONS') {
      parts.add('NTA Abhyas');
    } else {
      parts.add('NEET');
    }

    final int y = (year != null && year! > 0) ? year! : 2026;
    parts.add('$y');

    if (session != null && session!.trim().isNotEmpty && !_isTechnicalId(session)) {
      parts.add(session!.trim());
    } else {
      parts.add('Phase 1');
    }

    if (shift != null && shift!.trim().isNotEmpty && !_isTechnicalId(shift)) {
      parts.add(shift!.trim());
    }

    return parts.join(' ');
  }

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
    this.availableIn = const [
      'custom_practice',
      'custom_test',
      'pyq_practice',
      'nta_questions',
      'test_series',
    ],
    this.status = 'published',
    required this.options,
  });

  static int resolveCorrectOptionIndex(Map<String, dynamic> map, List<String> opts) {
    // 1. Direct numeric index in map
    dynamic rawIdx = map['correct_option_index'] ?? map['correctOptionIndex'];
    if (rawIdx is num && rawIdx >= 0 && rawIdx < opts.length) {
      return rawIdx.toInt();
    }
    if (rawIdx != null) {
      int? parsed = int.tryParse(rawIdx.toString().trim());
      if (parsed != null && parsed >= 0 && parsed < opts.length) {
        return parsed;
      }
    }

    // 2. Check options array for is_correct or isCorrect flag
    var rawOptions = map['options'] as List? ?? map['question_options'] as List? ?? [];
    for (int i = 0; i < rawOptions.length; i++) {
      final opt = rawOptions[i];
      if (opt is Map && (opt['is_correct'] == true || opt['isCorrect'] == true)) {
        if (i < opts.length) return i;
      }
    }

    // 3. Parse correct_answer / correctAnswer / correctText string
    final String caStr = (map['correct_answer'] ?? map['correctAnswer'] ?? map['correctText'] ?? '').toString().trim();
    if (caStr.isNotEmpty) {
      final uStr = caStr.toUpperCase();

      if (uStr.startsWith('OPTION ') || uStr.startsWith('OPT ') || uStr.startsWith('OPT. ')) {
        String sub = uStr.replaceAll(RegExp(r'^OPT(ION)?\.?\s*'), '').trim();
        if (sub.length == 1 && RegExp(r'[A-D]').hasMatch(sub)) {
          return sub.codeUnitAt(0) - 65;
        }
        int? n = int.tryParse(sub);
        if (n != null && n >= 1 && n <= opts.length) {
          return n - 1;
        }
      }

      final cleanLetter = uStr.replaceAll(RegExp(r'[\(\)\.]'), '').trim();
      if (cleanLetter.length == 1 && RegExp(r'[A-D]').hasMatch(cleanLetter)) {
        return cleanLetter.codeUnitAt(0) - 65;
      }

      if (cleanLetter.length == 1 && RegExp(r'[1-4]').hasMatch(cleanLetter)) {
        return int.parse(cleanLetter) - 1;
      }

      final normCa = caStr.replaceAll(RegExp(r'\s+'), '').toLowerCase();
      for (int i = 0; i < opts.length; i++) {
        final normOpt = opts[i].replaceAll(RegExp(r'\s+'), '').toLowerCase();
        if (normOpt.isNotEmpty && normCa.isNotEmpty && normOpt == normCa) {
          return i;
        }
      }
      for (int i = 0; i < opts.length; i++) {
        final normOpt = opts[i].replaceAll(RegExp(r'\s+'), '').toLowerCase();
        if (normOpt.isNotEmpty && normCa.isNotEmpty && (normOpt.contains(normCa) || normCa.contains(normOpt))) {
          return i;
        }
      }
    }

    return -1;
  }

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    var rawOptions = json['options'] as List? ?? json['question_options'] as List? ?? [];
    int targetCorrectIdx = -1;

    // 1. Check explicit correct option index
    if (json['correct_option_index'] != null) {
      targetCorrectIdx = (json['correct_option_index'] as num).toInt();
    } else if (json['correctOptionIndex'] != null) {
      targetCorrectIdx = (json['correctOptionIndex'] as num).toInt();
    }

    // 2. Check if rawOptions contains an option with is_correct / isCorrect = true
    if (targetCorrectIdx == -1) {
      for (int i = 0; i < rawOptions.length; i++) {
        final opt = rawOptions[i];
        if (opt is Map && (opt['is_correct'] == true || opt['isCorrect'] == true)) {
          targetCorrectIdx = i;
          break;
        }
      }
    }

    // 3. Parse correct_answer / correctAnswer / correctText string
    if (targetCorrectIdx == -1) {
      final String corrStr = (json['correct_answer'] ?? json['correctAnswer'] ?? json['correctText'] ?? '').toString().trim();
      final String uCorr = corrStr.toUpperCase();
      if (uCorr.startsWith('OPTION ')) {
        final sub = uCorr.substring(7).trim();
        if (sub.length == 1 && RegExp(r'[A-D]').hasMatch(sub)) {
          targetCorrectIdx = sub.codeUnitAt(0) - 65;
        } else {
          final optNum = int.tryParse(sub) ?? -1;
          if (optNum != -1) targetCorrectIdx = (optNum - 1).clamp(0, 5);
        }
      } else if (uCorr.length == 1 && RegExp(r'[A-D]').hasMatch(uCorr)) {
        targetCorrectIdx = uCorr.codeUnitAt(0) - 65;
      } else if (uCorr.length == 1 && RegExp(r'[1-4]').hasMatch(uCorr)) {
        targetCorrectIdx = int.parse(uCorr) - 1;
      }

      if (targetCorrectIdx == -1 && corrStr.isNotEmpty) {
        for (int i = 0; i < rawOptions.length; i++) {
          final rawOpt = rawOptions[i];
          final String optText = (rawOpt is Map ? (rawOpt['option_text'] ?? rawOpt['optionText'] ?? '') : rawOpt.toString()).trim();
          if (optText.isNotEmpty && (optText.toLowerCase() == corrStr.toLowerCase() || optText.replaceAll(RegExp(r'\s+'), '').toLowerCase() == corrStr.replaceAll(RegExp(r'\s+'), '').toLowerCase())) {
            targetCorrectIdx = i;
            break;
          }
        }
      }
    }

    debugPrint('[QuestionModel.fromJson] QID: ${json['id']} | TargetCorrectIdx: $targetCorrectIdx (Option ${targetCorrectIdx != -1 ? String.fromCharCode(65 + targetCorrectIdx) : "None"})');

    List<QuestionOptionModel> parsedOptions = [];

    for (int i = 0; i < rawOptions.length; i++) {
      final rawOpt = rawOptions[i];
      if (rawOpt is Map) {
        final mapOpt = Map<String, dynamic>.from(rawOpt);
        bool isOptCorrect = (targetCorrectIdx != -1)
            ? (i == targetCorrectIdx)
            : (mapOpt['is_correct'] == true || mapOpt['isCorrect'] == true);
        parsedOptions.add(QuestionOptionModel.fromJson({
          ...mapOpt,
          'option_index': mapOpt['option_index'] ?? mapOpt['optionIndex'] ?? i,
          'is_correct': isOptCorrect,
        }));
      } else {
        final String textVal = rawOpt?.toString() ?? '';
        final bool isOptCorrect = (targetCorrectIdx != -1) ? (i == targetCorrectIdx) : false;
        parsedOptions.add(QuestionOptionModel(
          id: 'opt_${json['id']}_$i',
          questionId: json['id']?.toString() ?? '',
          optionIndex: i,
          optionText: textVal,
          isCorrect: isOptCorrect,
        ));
      }
    }

    if (parsedOptions.isNotEmpty && !parsedOptions.any((o) => o.isCorrect)) {
      int fallbackIdx = (targetCorrectIdx >= 0 && targetCorrectIdx < parsedOptions.length)
          ? targetCorrectIdx
          : resolveCorrectOptionIndex(json, parsedOptions.map((o) => o.optionText).toList());
      if (fallbackIdx >= 0 && fallbackIdx < parsedOptions.length) {
        parsedOptions[fallbackIdx] = QuestionOptionModel(
          id: parsedOptions[fallbackIdx].id,
          questionId: parsedOptions[fallbackIdx].questionId,
          optionIndex: parsedOptions[fallbackIdx].optionIndex,
          optionText: parsedOptions[fallbackIdx].optionText,
          isCorrect: true,
          optionImage: parsedOptions[fallbackIdx].optionImage,
        );
      }
    }

    List<String> parsedTags = [];
    if (json['tags'] is List) {
      parsedTags = (json['tags'] as List).map((t) => t.toString()).toList();
    }

    List<String> parsedAvailableIn = [];
    if (json['available_in'] is List) {
      parsedAvailableIn = (json['available_in'] as List).map((v) => v.toString()).toList();
    } else if (json['availableIn'] is List) {
      parsedAvailableIn = (json['availableIn'] as List).map((v) => v.toString()).toList();
    }
    if (parsedAvailableIn.isEmpty) {
      parsedAvailableIn = List<String>.from(allVisibilityKeys);
    }

    return QuestionModel(
      id: json['id']?.toString() ?? '',
      examId: json['exam_id']?.toString() ?? '',
      subjectId: json['subject_id']?.toString() ?? '',
      chapterId: json['chapter_id']?.toString() ?? '',
      topicId: json['topic_id']?.toString(),
      questionText: json['question_text'] ?? json['questionText'] ?? '',
      questionImage: json['question_image'] ?? json['questionImage'],
      qType: json['q_type'] ?? json['question_type'] ?? json['qType'] ?? 'single_correct',
      difficulty: json['difficulty'] ?? 'medium',
      source: json['source'] ?? json['sourceType'] ?? json['source_type'] ?? 'practice',
      sourceName: json['source_name'] ?? json['sourceName'] ?? json['paper_name'] ?? json['paperName'] ?? json['test_title'] ?? json['testTitle'] ?? json['paper'],
      marks: (json['marks'] as num?)?.toDouble() ?? 4.0,
      negativeMarks: (json['negative_marks'] as num?)?.toDouble() ?? 1.0,
      year: (json['year'] ?? json['exam_year'] ?? json['examYear']) is int
          ? (json['year'] ?? json['exam_year'] ?? json['examYear']) as int
          : int.tryParse((json['year'] ?? json['exam_year'] ?? json['examYear'] ?? '').toString()),
      session: (json['session'] ?? json['exam_session'] ?? json['examSession'])?.toString(),
      shift: (json['shift'] ?? json['exam_shift'] ?? json['examShift'])?.toString(),
      paper: (json['paper'] ?? json['paper_name'] ?? json['paperName'])?.toString(),
      questionNumber: (json['question_number'] ?? json['questionNumber']) as int?,
      numericalAnswer: json['numerical_answer']?.toString(),
      numericalTolerance: (json['numerical_tolerance'] as num?)?.toDouble(),
      explanation: json['explanation']?.toString(),
      solution: json['solution']?.toString(),
      hint: json['hint']?.toString(),
      tags: parsedTags,
      availableIn: parsedAvailableIn,
      status: json['status']?.toString() ?? 'published',
      options: parsedOptions,
    );
  }

  Map<String, dynamic> toJson() {
    final int corrIdx = options.indexWhere((o) => o.isCorrect);
    final String? corrAnsStr = corrIdx != -1 ? 'Option ${String.fromCharCode(65 + corrIdx)}' : null;

    return {
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
      'available_in': availableIn,
      'availableIn': availableIn,
      'status': status,
      'options': options.map((o) => o.toJson()).toList(),
      'correct_answer': corrAnsStr,
      'correctAnswer': corrAnsStr,
      'correct_option_index': corrIdx != -1 ? corrIdx : null,
      'correctOptionIndex': corrIdx != -1 ? corrIdx : null,
    };
  }
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

/// Mode for custom practice vs custom test sessions
enum PracticeTestMode { practice, test }

/// Unified configuration model for Custom Practice and Custom Test
class PracticeTestConfigModel {
  final String exam; // NEET, JEE
  final List<String> selectedSubjects;
  final List<String> selectedChapterIds;
  final List<String> selectedTopicIds;
  final List<String> selectedSources; // PYQ, NTA, NCERT, Practice, Others
  final String difficulty; // Easy, Medium, Hard, Mixed
  final int questionCount;
  final int timeLimitMinutes;
  final PracticeTestMode mode;

  PracticeTestConfigModel({
    required this.exam,
    required this.selectedSubjects,
    required this.selectedChapterIds,
    required this.selectedTopicIds,
    required this.selectedSources,
    required this.difficulty,
    required this.questionCount,
    required this.timeLimitMinutes,
    this.mode = PracticeTestMode.practice,
  });

  bool get isTest => mode == PracticeTestMode.test;

  Map<String, dynamic> toJson() => {
        'exam': exam,
        'selected_subjects': selectedSubjects,
        'selected_chapter_ids': selectedChapterIds,
        'selected_topic_ids': selectedTopicIds,
        'selected_sources': selectedSources,
        'difficulty': difficulty,
        'question_count': questionCount,
        'time_limit_minutes': timeLimitMinutes,
        'mode': mode.name,
      };

  factory PracticeTestConfigModel.fromJson(Map<String, dynamic> json) {
    return PracticeTestConfigModel(
      exam: json['exam'] ?? 'NEET',
      selectedSubjects: List<String>.from(json['selected_subjects'] ?? []),
      selectedChapterIds: List<String>.from(json['selected_chapter_ids'] ?? []),
      selectedTopicIds: List<String>.from(json['selected_topic_ids'] ?? []),
      selectedSources: List<String>.from(json['selected_sources'] ?? []),
      difficulty: json['difficulty'] ?? 'Medium',
      questionCount: json['question_count'] ?? 20,
      timeLimitMinutes: json['time_limit_minutes'] ?? 30,
      mode: (json['mode'] == 'test') ? PracticeTestMode.test : PracticeTestMode.practice,
    );
  }
}

/// Audit Log Model
class AuditLogModel {
  final String id;
  final String userEmail;
  final String action;
  final String entityType;
  final String entityId;
  final Map<String, dynamic> details;
  final DateTime createdAt;

  AuditLogModel({
    required this.id,
    required this.userEmail,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.details,
    required this.createdAt,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: json['id']?.toString() ?? '',
      userEmail: json['user_email'] ?? 'Admin',
      action: json['action'] ?? '',
      entityType: json['entity_type'] ?? '',
      entityId: json['entity_id']?.toString() ?? '',
      details: json['details'] is Map<String, dynamic> ? json['details'] : {},
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

/// Dynamic Dashboard Banner Model
class DashboardBannerModel {
  final String id;
  final String title;
  final String subtitle;
  final String ctaText;
  final String ctaDestination;
  final String? imageUrl;
  final String bgColor;
  final String btnColor;
  final String btnTextColor;
  final String iconName;
  final bool isActive;
  final int sortOrder;
  final DateTime? startAt;
  final DateTime? endAt;
  final String targetAudience;
  final int priority;
  final bool showTextOverlay;
  final bool showButton;
  final double overlayOpacity;
  final DateTime createdAt;
  final DateTime updatedAt;

  DashboardBannerModel({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.ctaText = 'Explore Now',
    this.ctaDestination = '/practice',
    this.imageUrl,
    this.bgColor = '#5B21B6',
    this.btnColor = '#FACC15',
    this.btnTextColor = '#1E1B4B',
    this.iconName = 'school',
    this.isActive = true,
    this.sortOrder = 0,
    this.startAt,
    this.endAt,
    this.targetAudience = 'All Students',
    this.priority = 1,
    this.showTextOverlay = true,
    this.showButton = true,
    this.overlayOpacity = 0.0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isScheduledActive {
    if (!isActive) return false;
    final now = DateTime.now();
    if (startAt != null && now.isBefore(startAt!)) return false;
    if (endAt != null && now.isAfter(endAt!)) return false;
    return true;
  }

  factory DashboardBannerModel.fromJson(Map<String, dynamic> json) {
    bool showText = true;
    bool showBtn = true;
    double opacity = 0.0;

    // Check if visual config is encoded in icon_name (e.g. cfg:text=0;btn=0;op=0.0)
    final iconField = json['icon_name']?.toString() ?? 'school';
    if (iconField.startsWith('cfg:')) {
      final parts = iconField.substring(4).split(';');
      for (final p in parts) {
        if (p.startsWith('text=')) showText = p.substring(5) == '1';
        if (p.startsWith('btn=')) showBtn = p.substring(4) == '1';
        if (p.startsWith('op=')) opacity = double.tryParse(p.substring(3)) ?? 0.0;
      }
    } else {
      if (json.containsKey('show_text_overlay')) {
        showText = json['show_text_overlay'] == true;
      } else if (json['image_url'] != null && json['image_url'].toString().isNotEmpty && (json['title'] == null || json['title'].toString().isEmpty)) {
        showText = false;
      }
      if (json.containsKey('show_button')) {
        showBtn = json['show_button'] == true;
      }
      if (json['overlay_opacity'] is num) {
        opacity = (json['overlay_opacity'] as num).toDouble();
      }
    }

    return DashboardBannerModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      ctaText: json['cta_text'] ?? 'Explore Now',
      ctaDestination: json['cta_destination'] ?? '/practice',
      imageUrl: json['image_url'],
      bgColor: json['bg_color'] ?? '#5B21B6',
      btnColor: json['btn_color'] ?? '#FACC15',
      btnTextColor: json['btn_text_color'] ?? '#1E1B4B',
      iconName: iconField,
      isActive: json['is_active'] ?? true,
      sortOrder: json['sort_order'] ?? 0,
      startAt: json['start_at'] != null ? DateTime.tryParse(json['start_at'].toString()) : null,
      endAt: json['end_at'] != null ? DateTime.tryParse(json['end_at'].toString()) : null,
      targetAudience: json['target_audience'] ?? 'All Students',
      priority: json['priority'] ?? 1,
      showTextOverlay: showText,
      showButton: showBtn,
      overlayOpacity: opacity,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    // Encapsulate extra display preferences into icon_name column which exists in Supabase
    final encodedConfig = 'cfg:text=${showTextOverlay ? 1 : 0};btn=${showButton ? 1 : 0};op=${overlayOpacity.toStringAsFixed(2)}';

    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'cta_text': ctaText,
      'cta_destination': ctaDestination,
      'image_url': imageUrl,
      'bg_color': bgColor,
      'btn_color': btnColor,
      'btn_text_color': btnTextColor,
      'icon_name': encodedConfig,
      'is_active': isActive,
      'sort_order': sortOrder,
      'start_at': startAt?.toIso8601String(),
      'end_at': endAt?.toIso8601String(),
      'target_audience': targetAudience,
      'priority': priority,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  DashboardBannerModel copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? ctaText,
    String? ctaDestination,
    String? imageUrl,
    String? bgColor,
    String? btnColor,
    String? btnTextColor,
    String? iconName,
    bool? isActive,
    int? sortOrder,
    DateTime? startAt,
    DateTime? endAt,
    String? targetAudience,
    int? priority,
    bool? showTextOverlay,
    bool? showButton,
    double? overlayOpacity,
  }) {
    return DashboardBannerModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      ctaText: ctaText ?? this.ctaText,
      ctaDestination: ctaDestination ?? this.ctaDestination,
      imageUrl: imageUrl ?? this.imageUrl,
      bgColor: bgColor ?? this.bgColor,
      btnColor: btnColor ?? this.btnColor,
      btnTextColor: btnTextColor ?? this.btnTextColor,
      iconName: iconName ?? this.iconName,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      targetAudience: targetAudience ?? this.targetAudience,
      priority: priority ?? this.priority,
      showTextOverlay: showTextOverlay ?? this.showTextOverlay,
      showButton: showButton ?? this.showButton,
      overlayOpacity: overlayOpacity ?? this.overlayOpacity,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
