export type UserRole = 'student' | 'teacher' | 'admin' | 'super_admin';

export type QuestionType =
  | 'single_correct'
  | 'multiple_correct'
  | 'numerical'
  | 'assertion_reason'
  | 'match_following'
  | 'true_false'
  | 'passage_based'
  | 'image_based';

export type DifficultyLevel = 'easy' | 'medium' | 'hard';

export type QuestionSource =
  | 'pyq'
  | 'nta'
  | 'teacher_created'
  | 'admin_created'
  | 'ai_generated'
  | 'imported'
  | 'practice'
  | 'mock_test';

export type QuestionStatus = 'draft' | 'submitted' | 'under_review' | 'approved' | 'rejected' | 'published';

export type TeacherStatus = 'pending' | 'approved' | 'rejected' | 'suspended';

export type TestType = 'custom_practice' | 'custom_test' | 'teacher_test' | 'quiz' | 'mock_exam';

export type AttemptStatus = 'in_progress' | 'submitted' | 'expired' | 'abandoned';

export type BookmarkCategory = 'important' | 'difficult' | 'revision' | 'mistake' | 'custom';

export interface Profile {
  id: string;
  email: string;
  full_name: string;
  avatar_url?: string;
  phone_number?: string;
  target_exam?: string;
  target_year?: number;
  education_level?: string;
  bio?: string;
  is_public_on_leaderboard?: boolean;
  role?: UserRole;
}

export interface Exam {
  id: string;
  name: string;
  code: string;
  description?: string;
  icon_url?: string;
  is_active: boolean;
  display_order: number;
}

export interface Subject {
  id: string;
  exam_id: string;
  name: string;
  code: string;
  description?: string;
  icon_url?: string;
  color_hex: string;
  display_order: number;
}

export interface Chapter {
  id: string;
  subject_id: string;
  name: string;
  code: string;
  description?: string;
  class_level: number;
  display_order: number;
}

export interface Topic {
  id: string;
  chapter_id: string;
  name: string;
  code: string;
  description?: string;
  display_order: number;
}

export interface QuestionOption {
  id: string;
  question_id: string;
  option_index: number;
  option_text: string;
  option_image?: string;
  is_correct?: boolean; // May be omitted during test mode
}

export interface Question {
  id: string;
  exam_id: string;
  subject_id: string;
  chapter_id: string;
  topic_id?: string;
  question_text: string;
  question_image?: string;
  q_type: QuestionType;
  difficulty: DifficultyLevel;
  source: QuestionSource;
  explanation?: string;
  solution?: string;
  marks: number;
  negative_marks: number;
  estimated_seconds?: number;
  year?: number;
  session?: string;
  shift?: string;
  paper?: string;
  question_number?: number;
  language?: string;
  status: QuestionStatus;
  options: QuestionOption[];
}

export interface Test {
  id: string;
  title: string;
  description?: string;
  exam_id: string;
  test_type: TestType;
  duration_minutes: number;
  total_marks: number;
  default_negative_marking: number;
  attempt_limit: number;
  is_published: boolean;
  created_by: string;
  invitation_code?: string;
  created_at?: string;
  question_count?: number;
  teacher_name?: string;
}

export interface TestAttempt {
  id: string;
  student_id: string;
  test_id?: string;
  mode: TestType;
  status: AttemptStatus;
  started_at: string;
  expires_at: string;
  submitted_at?: string;
  total_score: number;
  max_score: number;
  correct_count: number;
  incorrect_count: number;
  unattempted_count: number;
  accuracy_percentage: number;
  time_spent_seconds: number;
  question_order: string[];
}

export interface TestAnswer {
  question_id: string;
  selected_option_ids: string[];
  numerical_answer?: string;
  is_marked_for_review: boolean;
  time_spent_seconds: number;
  is_correct?: boolean;
  marks_awarded?: number;
}

export interface Bookmark {
  id: string;
  student_id: string;
  question_id: string;
  category: BookmarkCategory;
  notes?: string;
  question?: Question;
  created_at: string;
}

export interface MistakeQuestion {
  id: string;
  student_id: string;
  question_id: string;
  incorrect_attempts: number;
  is_resolved: boolean;
  question?: Question;
  last_attempted_at: string;
}

export interface LeaderboardEntry {
  id: string;
  student_id: string;
  student_name: string;
  avatar_url?: string;
  score: number;
  questions_solved: number;
  accuracy: number;
  rank: number;
}

export interface Streak {
  current_streak: number;
  longest_streak: number;
  last_activity_date: string;
}
