import 'package:flutter/foundation.dart';

/// Centralized mapper layer between Flutter UI models and Supabase PostgreSQL Database Schema Enums
class SupabaseQuestionMapper {
  /// Map UI Question Type string to exact Supabase PostgreSQL `question_type` enum value
  /// Valid DB values: 'single_correct', 'multiple_correct', 'numerical', 'assertion_reason', 'match_following', 'true_false', 'passage_based', 'image_based'
  static String toDbQuestionType(dynamic input) {
    if (input == null) return 'single_correct';
    final str = input.toString().trim().toLowerCase();
    
    if (str == 'single_correct' || str.contains('single') || str.contains('mcq')) {
      return 'single_correct';
    }
    if (str == 'multiple_correct' || str.contains('multi')) {
      return 'multiple_correct';
    }
    if (str == 'numerical' || str.contains('numeric') || str.contains('integer')) {
      return 'numerical';
    }
    if (str == 'assertion_reason' || str.contains('assertion') || str.contains('reason')) {
      return 'assertion_reason';
    }
    if (str == 'match_following' || str.contains('match')) {
      return 'match_following';
    }
    if (str == 'true_false' || str.contains('true') || str.contains('false')) {
      return 'true_false';
    }
    if (str == 'passage_based' || str.contains('passage')) {
      return 'passage_based';
    }
    if (str == 'image_based' || str.contains('image')) {
      return 'image_based';
    }
    return 'single_correct';
  }

  /// Map UI Difficulty string to exact Supabase PostgreSQL `difficulty_level` enum value
  /// Valid DB values: 'easy', 'medium', 'hard'
  static String toDbDifficulty(dynamic input) {
    if (input == null) return 'medium';
    final str = input.toString().trim().toLowerCase();
    if (str == 'easy') return 'easy';
    if (str == 'hard' || str == 'tough' || str == 'difficult') return 'hard';
    return 'medium';
  }

  /// Map UI Source/Category string to exact Supabase PostgreSQL `question_source` enum value
  /// Valid DB values: 'pyq', 'nta', 'teacher_created', 'admin_created', 'ai_generated', 'imported', 'practice', 'mock_test'
  static String toDbQuestionSource(dynamic input) {
    if (input == null) return 'practice';
    final str = input.toString().trim().toLowerCase();
    if (str.contains('pyq')) return 'pyq';
    if (str.contains('nta')) return 'nta';
    if (str.contains('mock')) return 'mock_test';
    if (str.contains('teacher')) return 'teacher_created';
    if (str.contains('admin')) return 'admin_created';
    if (str.contains('ai')) return 'ai_generated';
    if (str.contains('import')) return 'imported';
    if (str.contains('custom') || str.contains('practice')) return 'practice';
    return 'practice';
  }

  /// Map UI Status string to exact Supabase PostgreSQL `question_status` enum value
  /// Valid DB values: 'draft', 'submitted', 'under_review', 'approved', 'rejected', 'published'
  static String toDbQuestionStatus(dynamic input) {
    if (input == null) return 'published';
    final str = input.toString().trim().toLowerCase();
    if (str == 'active' || str == 'published' || str == 'approved') return 'published';
    if (str == 'draft') return 'draft';
    if (str == 'submitted') return 'submitted';
    if (str == 'under_review') return 'under_review';
    if (str == 'rejected') return 'rejected';
    return 'published';
  }

  /// Map DB `question_type` back to UI Display string
  static String toDisplayQuestionType(String? dbType) {
    switch (dbType) {
      case 'multiple_correct':
        return 'Multiple Choice (Multiple Correct)';
      case 'numerical':
        return 'Numerical Value';
      case 'assertion_reason':
        return 'Assertion & Reason';
      case 'match_following':
        return 'Match the Following';
      case 'true_false':
        return 'True / False';
      case 'passage_based':
        return 'Passage Based';
      case 'image_based':
        return 'Image Based';
      case 'single_correct':
      default:
        return 'MCQ (Single Correct)';
    }
  }

  /// Map DB `difficulty_level` back to UI Display string
  static String toDisplayDifficulty(String? dbDiff) {
    switch (dbDiff?.toLowerCase()) {
      case 'easy':
        return 'Easy';
      case 'hard':
        return 'Hard';
      case 'medium':
      default:
        return 'Medium';
    }
  }

  /// Map DB `question_status` back to UI Display string
  static String toDisplayStatus(String? dbStatus) {
    switch (dbStatus?.toLowerCase()) {
      case 'draft':
        return 'Draft';
      case 'submitted':
        return 'Submitted';
      case 'under_review':
        return 'Under Review';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'published':
      default:
        return 'Active';
    }
  }
}
