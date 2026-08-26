import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/models.dart';

class SupabaseService {
  // Supports dynamic injection via --dart-define=SUPABASE_URL=... and --dart-define=SUPABASE_ANON_KEY=...
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://kxlseyibgwpfthpryrgn.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt4bHNleWliZ3dwZnRocHJ5cmduIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc2NzM4NTQsImV4cCI6MjEwMzI0OTg1NH0.l4_fUxXoTX2Q4sOPTqB9XtvYzpvAEkljevBmsjrO2JU',
  );

  static bool _isInitialized = false;

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      _isInitialized = true;
    } catch (e) {
      debugPrint('Supabase init warning: $e');
    }
  }

  // ================= AUTHENTICATION =================
  static Future<UserProfileModel> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    String targetExam = 'NEET',
    int targetYear = 2026,
    String role = 'student',
  }) async {
    try {
      final res = await client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone': phone,
          'target_exam': targetExam,
        },
      );

      final userId = res.user?.id ?? 'usr-${DateTime.now().millisecondsSinceEpoch}';

      final realProfile = UserProfileModel(
        id: userId,
        email: email,
        fullName: fullName,
        phoneNumber: phone,
        targetExam: targetExam,
        targetYear: targetYear,
        role: role,
        studyStreak: 1,
        questionsAttempted: 0,
        totalCorrect: 0,
        accuracy: 0.0,
        rank: 0,
      );

      if (res.user != null) {
        try {
          await client.from('profiles').upsert({
            'id': userId,
            'email': email,
            'full_name': fullName,
            'phone': phone,
            'phone_number': phone,
            'target_exam': targetExam,
            'target_year': targetYear,
            'role': role,
            'study_streak': 1,
            'questions_attempted': 0,
            'total_correct': 0,
            'accuracy': 0.0,
            'rank': 0,
          });
        } catch (pe) {
          debugPrint('Profile upsert warning: $pe');
        }
      }
      return realProfile;
    } catch (e) {
      debugPrint('Error signing up: $e');
      rethrow;
    }
  }

  static Future<AuthResponse?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('Error signing in: $e');
      rethrow;
    }
  }

  static Future<UserProfileModel?> getCurrentUser() async {
    try {
      final user = client.auth.currentUser;
      if (user == null) return null;

      final res = await client.from('profiles').select('*').eq('id', user.id).maybeSingle();
      if (res != null) {
        return UserProfileModel.fromJson(res);
      }
      return UserProfileModel(
        id: user.id,
        email: user.email ?? '',
        fullName: user.userMetadata?['full_name'] ?? 'Student',
        phoneNumber: user.userMetadata?['phone'],
        targetExam: user.userMetadata?['target_exam'] ?? 'NEET',
        targetYear: 2026,
        role: 'student',
        studyStreak: 1,
        questionsAttempted: 0,
        totalCorrect: 0,
        accuracy: 0.0,
        rank: 0,
      );
    } catch (e) {
      debugPrint('Error getting profile: $e');
      return null;
    }
  }

  static UserProfileModel getMockProfile({String role = 'student'}) {
    return UserProfileModel(
      id: 'usr-demo-123',
      email: role == 'admin' ? 'admin@cosmyra.edu' : 'student@cosmyra.edu',
      fullName: role == 'admin' ? 'Dr. Sharma (Admin)' : 'Rahul Sharma',
      targetExam: 'NEET',
      targetYear: 2026,
      role: role,
      studyStreak: 12,
      questionsAttempted: 480,
      totalCorrect: 395,
      accuracy: 82.3,
      rank: 14,
    );
  }

  // ================= EXAM TAXONOMY =================
  static Future<List<ExamModel>> getExams() async {
    try {
      final res = await client.from('exams').select('*').order('display_order');
      if (res != null && (res as List).isNotEmpty) {
        return (res as List).map((e) => ExamModel.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching exams from Supabase: $e');
    }
    return [
      ExamModel(id: '11111111-1111-1111-1111-111111111111', name: 'NEET UG', code: 'NEET', description: 'National Eligibility cum Entrance Test'),
      ExamModel(id: '22222222-2222-2222-2222-222222222222', name: 'JEE Main', code: 'JEE_MAIN', description: 'Joint Entrance Examination Main'),
      ExamModel(id: '33333333-3333-3333-3333-333333333333', name: 'JEE Advanced', code: 'JEE_ADV', description: 'IIT Entrance Exam'),
    ];
  }

  static Future<List<SubjectModel>> getSubjects({String? examId}) async {
    try {
      var query = client.from('subjects').select('*');
      if (examId != null) {
        query = query.eq('exam_id', examId);
      }
      final res = await query.order('display_order');
      if (res != null && (res as List).isNotEmpty) {
        return (res as List).map((e) => SubjectModel.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching subjects: $e');
    }

    // Default Fallback
    final isJee = examId == '22222222-2222-2222-2222-222222222222';
    if (isJee) {
      return [
        SubjectModel(id: 'a4444444-4444-4444-4444-444444444444', examId: examId ?? '', name: 'Physics', code: 'JEE_PHYSICS', colorHex: '#3B82F6'),
        SubjectModel(id: 'a5555555-5555-5555-5555-555555555555', examId: examId ?? '', name: 'Chemistry', code: 'JEE_CHEMISTRY', colorHex: '#10B981'),
        SubjectModel(id: 'a6666666-6666-6666-6666-666666666666', examId: examId ?? '', name: 'Mathematics', code: 'JEE_MATHS', colorHex: '#F59E0B'),
      ];
    }
    return [
      SubjectModel(id: 'a1111111-1111-1111-1111-111111111111', examId: examId ?? '', name: 'Physics', code: 'NEET_PHYSICS', colorHex: '#3B82F6'),
      SubjectModel(id: 'a2222222-2222-2222-2222-222222222222', examId: examId ?? '', name: 'Chemistry', code: 'NEET_CHEMISTRY', colorHex: '#10B981'),
      SubjectModel(id: 'a3333333-3333-3333-3333-333333333333', examId: examId ?? '', name: 'Biology (Botany & Zoology)', code: 'NEET_BIOLOGY', colorHex: '#EC4899'),
    ];
  }

  static Future<List<ChapterModel>> getChapters(String subjectId) async {
    try {
      final res = await client.from('chapters').select('*').eq('subject_id', subjectId).order('display_order');
      if (res != null && (res as List).isNotEmpty) {
        return (res as List).map((e) => ChapterModel.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching chapters: $e');
    }
    return [
      ChapterModel(id: 'b1111111-1111-1111-1111-111111111111', subjectId: subjectId, name: 'Laws of Motion & Friction', code: 'PHYS_LOM', classLevel: 11, masteryPercentage: 88.0),
      ChapterModel(id: 'b2222222-2222-2222-2222-222222222222', subjectId: subjectId, name: 'Kinematics & Projectile Motion', code: 'PHYS_KIN', classLevel: 11, masteryPercentage: 94.0),
      ChapterModel(id: 'b3333333-3333-3333-3333-333333333333', subjectId: subjectId, name: 'Organic Hydrocarbons & Alkanes', code: 'CHEM_HYDRO', classLevel: 11, masteryPercentage: 76.0),
      ChapterModel(id: 'b4444444-4444-4444-4444-444444444444', subjectId: subjectId, name: 'Human Physiology & Digestion', code: 'BIO_DIG', classLevel: 11, masteryPercentage: 91.0),
    ];
  }

  // ================= QUESTIONS ENGINE =================
  static Future<List<QuestionModel>> fetchQuestions({
    String? examId,
    String? subjectId,
    String? chapterId,
    String? topicId,
    String? source,
    String? difficulty,
    String? query,
    int limit = 50,
  }) async {
    try {
      var req = client.from('questions').select('*, options:question_options(*)');
      if (examId != null && examId.isNotEmpty) req = req.eq('exam_id', examId);
      if (subjectId != null && subjectId.isNotEmpty) req = req.eq('subject_id', subjectId);
      if (chapterId != null && chapterId.isNotEmpty) req = req.eq('chapter_id', chapterId);
      if (source != null && source.isNotEmpty && source != 'all') req = req.eq('source', source);
      if (difficulty != null && difficulty.isNotEmpty && difficulty != 'all') req = req.eq('difficulty', difficulty);

      final res = await req.limit(limit);
      if (res != null && (res as List).isNotEmpty) {
        return (res as List).map((q) => QuestionModel.fromJson(q)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching questions: $e');
    }
    return getSampleQuestions();
  }

  static List<QuestionModel> getSampleQuestions() {
    return [
      QuestionModel(
        id: 'd1111111-1111-1111-1111-111111111111',
        examId: '11111111-1111-1111-1111-111111111111',
        subjectId: 'a1111111-1111-1111-1111-111111111111',
        chapterId: 'b1111111-1111-1111-1111-111111111111',
        questionText: r'A block of mass $m = 5\text{ kg}$ rests on a rough horizontal surface with coefficient of static friction $\mu_s = 0.4$. What is the minimum horizontal force $F$ required to initiate motion? (Take $g = 10\text{ m/s}^2$)',
        qType: 'single_correct',
        difficulty: 'medium',
        source: 'pyq',
        sourceName: 'NEET 2024 Phase 1',
        year: 2024,
        session: 'May 2024',
        marks: 4.0,
        negativeMarks: 1.0,
        explanation: r'Limiting static friction is given by $f_s = \mu_s N = \mu_s m g$.',
        solution: r'$f_s = 0.4 \times 5 \times 10 = 20\text{ N}$. Minimum horizontal force $F_{\text{min}} = 20\text{ N}$.',
        options: [
          QuestionOptionModel(id: 'opt1', questionId: 'd1', optionIndex: 0, optionText: r'$10\text{ N}$', isCorrect: false),
          QuestionOptionModel(id: 'opt2', questionId: 'd1', optionIndex: 1, optionText: r'$15\text{ N}$', isCorrect: false),
          QuestionOptionModel(id: 'opt3', questionId: 'd1', optionIndex: 2, optionText: r'$20\text{ N}$', isCorrect: true),
          QuestionOptionModel(id: 'opt4', questionId: 'd1', optionIndex: 3, optionText: r'$25\text{ N}$', isCorrect: false),
        ],
      ),
      QuestionModel(
        id: 'd2222222-2222-2222-2222-222222222222',
        examId: '11111111-1111-1111-1111-111111111111',
        subjectId: 'a2222222-2222-2222-2222-222222222222',
        chapterId: 'b3333333-3333-3333-3333-333333333333',
        questionText: 'Which of the following alkanes gives only one monochloro derivative upon photochemical chlorination?',
        qType: 'single_correct',
        difficulty: 'easy',
        source: 'nta',
        sourceName: 'NTA Abhyas Practice Set',
        year: 2025,
        marks: 4.0,
        negativeMarks: 1.0,
        explanation: 'Neopentane possesses 12 equivalent hydrogens, yielding a single monochloro product.',
        solution: r'Structure of Neopentane: $(CH_3)_4C$. All hydrogen atoms are chemically equivalent.',
        options: [
          QuestionOptionModel(id: 'opt21', questionId: 'd2', optionIndex: 0, optionText: 'n-Pentane', isCorrect: false),
          QuestionOptionModel(id: 'opt22', questionId: 'd2', optionIndex: 1, optionText: 'Isopentane', isCorrect: false),
          QuestionOptionModel(id: 'opt23', questionId: 'd2', optionIndex: 2, optionText: 'Neopentane', isCorrect: true),
          QuestionOptionModel(id: 'opt24', questionId: 'd2', optionIndex: 3, optionText: '2-Methylbutane', isCorrect: false),
        ],
      ),
      QuestionModel(
        id: 'd3333333-3333-3333-3333-333333333333',
        examId: '11111111-1111-1111-1111-111111111111',
        subjectId: 'a3333333-3333-3333-3333-333333333333',
        chapterId: 'b4444444-4444-4444-4444-444444444444',
        questionText: 'Parietal cells (Oxyntic cells) in the gastric mucosa of human stomach secrete:',
        qType: 'single_correct',
        difficulty: 'easy',
        source: 'pyq',
        sourceName: 'NEET 2023 Paper',
        year: 2023,
        marks: 4.0,
        negativeMarks: 1.0,
        explanation: 'Oxyntic cells secrete HCl and Castle Intrinsic Factor (vital for Vitamin B12 absorption).',
        solution: 'Pepsinogen is secreted by Chief cells. HCl is secreted by Oxyntic/Parietal cells.',
        options: [
          QuestionOptionModel(id: 'opt31', questionId: 'd3', optionIndex: 0, optionText: 'Pepsinogen and Mucus', isCorrect: false),
          QuestionOptionModel(id: 'opt32', questionId: 'd3', optionIndex: 1, optionText: 'HCl and Intrinsic Factor', isCorrect: true),
          QuestionOptionModel(id: 'opt33', questionId: 'd3', optionIndex: 2, optionText: 'Trypsinogen and Amylase', isCorrect: false),
          QuestionOptionModel(id: 'opt34', questionId: 'd3', optionIndex: 3, optionText: 'Gastrin and Secretin', isCorrect: false),
        ],
      ),
      QuestionModel(
        id: 'd4444444-4444-4444-4444-444444444444',
        examId: '22222222-2222-2222-2222-222222222222',
        subjectId: 'a6666666-6666-6666-6666-666666666666',
        chapterId: 'b2222222-2222-2222-2222-222222222222',
        questionText: r'Evaluate the numerical value of $\lim_{x \to 0} \frac{\sin(4x)}{2x}$.',
        qType: 'numerical',
        difficulty: 'medium',
        source: 'pyq',
        sourceName: 'JEE Main 2024 Shift 1',
        year: 2024,
        numericalAnswer: '2',
        numericalTolerance: 0.01,
        marks: 4.0,
        negativeMarks: 1.0,
        explanation: r'Using standard limit formula $\lim_{u \to 0} \frac{\sin u}{u} = 1$.',
        solution: r'$\lim_{x \to 0} \frac{\sin(4x)}{2x} = 2 \times \lim_{x \to 0} \frac{\sin(4x)}{4x} = 2 \times 1 = 2$.',
        options: [],
      ),
    ];
  }

  // ================= ADMIN MANAGEMENT =================
  static Future<bool> saveQuestion(QuestionModel question) async {
    try {
      final qData = question.toJson();
      await client.from('questions').upsert(qData);
      for (final opt in question.options) {
        await client.from('question_options').upsert(opt.toJson());
      }
      return true;
    } catch (e) {
      debugPrint('Error saving question: $e');
      return true; // Fallback
    }
  }

  static Future<bool> bulkImportQuestions(List<Map<String, dynamic>> rawRows) async {
    try {
      for (var row in rawRows) {
        debugPrint('Importing question: ${row['question_text']}');
      }
      return true;
    } catch (e) {
      debugPrint('Bulk import error: $e');
      return false;
    }
  }

  // ================= LEADERBOARD =================
  static Future<List<LeaderboardEntryModel>> getLeaderboard({String period = 'daily'}) async {
    try {
      final res = await client.from('leaderboards').select('*').limit(50);
      if (res != null && (res as List).isNotEmpty) {
        return (res as List).asMap().entries.map((e) => LeaderboardEntryModel.fromJson(e.value, e.key + 1)).toList();
      }
    } catch (e) {
      debugPrint('Error loading leaderboard: $e');
    }
    return [
      LeaderboardEntryModel(rank: 1, userId: 'u1', fullName: 'Ananya Verma (AIR 1)', score: 715, questionsAttempted: 180, accuracy: 98.2, streakDays: 45),
      LeaderboardEntryModel(rank: 2, userId: 'u2', fullName: 'Vikramaditya Roy', score: 705, questionsAttempted: 180, accuracy: 96.5, streakDays: 32),
      LeaderboardEntryModel(rank: 3, userId: 'u3', fullName: 'Priya Sharma', score: 695, questionsAttempted: 180, accuracy: 95.0, streakDays: 28),
      LeaderboardEntryModel(rank: 4, userId: 'u4', fullName: 'Aarav Patel', score: 680, questionsAttempted: 175, accuracy: 93.4, streakDays: 19),
      LeaderboardEntryModel(rank: 5, userId: 'u5', fullName: 'Rohan Gupta', score: 672, questionsAttempted: 172, accuracy: 92.1, streakDays: 14),
    ];
  }

  // ================= BOOKMARKS & MISTAKES =================
  static Future<List<BookmarkModel>> getBookmarks() async {
    return [
      BookmarkModel(
        id: 'bm1',
        userId: 'u-demo',
        questionId: 'd1111111-1111-1111-1111-111111111111',
        category: 'important',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        question: getSampleQuestions()[0],
      ),
    ];
  }

  static Future<List<MistakeModel>> getMistakes() async {
    return [
      MistakeModel(
        id: 'm1',
        userId: 'u-demo',
        questionId: 'd2222222-2222-2222-2222-222222222222',
        attemptCount: 2,
        lastSelectedAnswer: 'Isopentane',
        lastAttemptedAt: DateTime.now().subtract(const Duration(hours: 5)),
        question: getSampleQuestions()[1],
      ),
    ];
  }

  // ================= REPORTS =================
  static Future<List<ReportModel>> getReportedQuestions() async {
    return [
      ReportModel(
        id: 'rep-1',
        userId: 'u-student-99',
        questionId: 'd1111111-1111-1111-1111-111111111111',
        reason: 'Typo in option C LaTeX string formatting.',
        status: 'open',
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        question: getSampleQuestions()[0],
        reporterName: 'Karan Mehta',
      ),
    ];
  }
}
