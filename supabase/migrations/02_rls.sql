-- ========================================================
-- COSMYRA COMPETITIVE EXAM PRACTICE PLATFORM - RLS POLICIES
-- Migration: 02_rls.sql (Idempotent & Re-runnable)
-- ========================================================

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teachers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chapters ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.topics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subtopics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.question_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.question_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.test_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.test_invites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.test_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.test_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookmarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mistake_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.streaks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leaderboard_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;

-- HELPER FUNCTIONS FOR ROLE CHECKING
CREATE OR REPLACE FUNCTION public.has_role(target_user_id UUID, check_role user_role)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.user_roles 
    WHERE user_id = target_user_id AND role = check_role
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.is_admin(user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  IF user_id IS NULL THEN
    RETURN FALSE;
  END IF;

  RETURN public.has_role(user_id, 'admin') 
      OR public.has_role(user_id, 'super_admin')
      OR EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE id = user_id AND LOWER(role) IN ('admin', 'super_admin')
      );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.is_teacher(user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  IF user_id IS NULL THEN
    RETURN FALSE;
  END IF;

  RETURN public.has_role(user_id, 'teacher') 
      OR public.is_admin(user_id)
      OR EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE id = user_id AND LOWER(role) IN ('teacher', 'admin', 'super_admin')
      );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 1. PROFILES
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Profiles viewable by all" ON public.profiles;
DROP POLICY IF EXISTS "Profiles insertable by all" ON public.profiles;
DROP POLICY IF EXISTS "Profiles updatable by all" ON public.profiles;
DROP POLICY IF EXISTS "Profiles manageable by all" ON public.profiles;
DROP POLICY IF EXISTS "Profiles full public access" ON public.profiles;
CREATE POLICY "Profiles full public access" ON public.profiles FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

-- 2. USER ROLES
DROP POLICY IF EXISTS "Admins can view and manage all user roles" ON public.user_roles;
DROP POLICY IF EXISTS "Users can view their own roles" ON public.user_roles;
CREATE POLICY "Admins can view and manage all user roles" ON public.user_roles FOR ALL TO authenticated USING (public.is_admin(auth.uid()));
CREATE POLICY "Users can view their own roles" ON public.user_roles FOR SELECT TO authenticated USING (auth.uid() = user_id);

-- 3. TEACHERS
DROP POLICY IF EXISTS "Authenticated users can view approved teachers" ON public.teachers;
DROP POLICY IF EXISTS "Teachers can insert and update their own application" ON public.teachers;
CREATE POLICY "Authenticated users can view approved teachers" ON public.teachers FOR SELECT TO authenticated USING (verification_status = 'approved' OR auth.uid() = id OR public.is_admin(auth.uid()));
CREATE POLICY "Teachers can insert and update their own application" ON public.teachers FOR ALL TO authenticated USING (auth.uid() = id);

-- 4. TAXONOMY (Exams, Subjects, Chapters, Topics, Subtopics, Tags)
ALTER TABLE public.exams DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.subjects DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.chapters DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.topics DISABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Taxonomy is readable by everyone" ON public.exams;
DROP POLICY IF EXISTS "Taxonomy is readable by everyone" ON public.subjects;
DROP POLICY IF EXISTS "Taxonomy is readable by everyone" ON public.chapters;
DROP POLICY IF EXISTS "Taxonomy is readable by everyone" ON public.topics;
DROP POLICY IF EXISTS "Admins manage taxonomy" ON public.exams;
DROP POLICY IF EXISTS "Admins manage taxonomy" ON public.subjects;
DROP POLICY IF EXISTS "Admins manage taxonomy" ON public.chapters;
DROP POLICY IF EXISTS "Admins manage taxonomy" ON public.topics;
DROP POLICY IF EXISTS "Taxonomy full public access" ON public.exams;
DROP POLICY IF EXISTS "Taxonomy full public access" ON public.subjects;
DROP POLICY IF EXISTS "Taxonomy full public access" ON public.chapters;
DROP POLICY IF EXISTS "Taxonomy full public access" ON public.topics;

CREATE POLICY "Taxonomy full public access" ON public.exams FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Taxonomy full public access" ON public.subjects FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Taxonomy full public access" ON public.chapters FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Taxonomy full public access" ON public.topics FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

-- 5. QUESTIONS & OPTIONS
ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.question_options ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Published questions viewable by authenticated users" ON public.questions;
DROP POLICY IF EXISTS "Questions viewable by users" ON public.questions;
DROP POLICY IF EXISTS "Teachers and admins can insert questions" ON public.questions;
DROP POLICY IF EXISTS "Admins and creators can update questions" ON public.questions;
DROP POLICY IF EXISTS "Admins can delete questions" ON public.questions;
DROP POLICY IF EXISTS "Questions select policy" ON public.questions;
DROP POLICY IF EXISTS "Questions insert policy" ON public.questions;
DROP POLICY IF EXISTS "Questions update policy" ON public.questions;
DROP POLICY IF EXISTS "Questions delete policy" ON public.questions;

-- SELECT Policy
CREATE POLICY "Questions select policy"
ON public.questions FOR SELECT TO anon, authenticated 
USING (status = 'published' OR status = 'Active' OR status = 'draft' OR created_by = auth.uid() OR public.is_admin(auth.uid()));

-- INSERT Policy
CREATE POLICY "Questions insert policy"
ON public.questions FOR INSERT TO anon, authenticated 
WITH CHECK (
  (auth.uid() IS NOT NULL AND (public.is_admin(auth.uid()) OR public.is_teacher(auth.uid())))
  OR auth.role() = 'anon'
);

-- UPDATE Policy
CREATE POLICY "Questions update policy"
ON public.questions FOR UPDATE TO anon, authenticated 
USING (
  (auth.uid() IS NOT NULL AND (public.is_admin(auth.uid()) OR public.is_teacher(auth.uid()) OR created_by = auth.uid()))
  OR auth.role() = 'anon'
);

-- DELETE Policy
CREATE POLICY "Questions delete policy"
ON public.questions FOR DELETE TO anon, authenticated 
USING (
  (auth.uid() IS NOT NULL AND (public.is_admin(auth.uid()) OR public.is_teacher(auth.uid()) OR created_by = auth.uid()))
  OR auth.role() = 'anon'
);

-- Question Options Policies
DROP POLICY IF EXISTS "Options viewable by authenticated users" ON public.question_options;
DROP POLICY IF EXISTS "Teachers and admins manage options" ON public.question_options;
DROP POLICY IF EXISTS "Options select policy" ON public.question_options;
DROP POLICY IF EXISTS "Options insert policy" ON public.question_options;
DROP POLICY IF EXISTS "Options update policy" ON public.question_options;
DROP POLICY IF EXISTS "Options delete policy" ON public.question_options;

CREATE POLICY "Options select policy"
ON public.question_options FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "Options insert policy"
ON public.question_options FOR INSERT TO anon, authenticated WITH CHECK (true);

CREATE POLICY "Options update policy"
ON public.question_options FOR UPDATE TO anon, authenticated USING (true);

CREATE POLICY "Options delete policy"
ON public.question_options FOR DELETE TO anon, authenticated USING (true);

-- 6. TESTS & INVITATIONS
DROP POLICY IF EXISTS "Published tests viewable by authenticated users" ON public.tests;
DROP POLICY IF EXISTS "Teachers can manage their own tests" ON public.tests;
DROP POLICY IF EXISTS "Test questions viewable by authenticated users" ON public.test_questions;
DROP POLICY IF EXISTS "Teachers manage test questions for their tests" ON public.test_questions;
DROP POLICY IF EXISTS "Test invites viewable by everyone" ON public.test_invites;
DROP POLICY IF EXISTS "Teachers create test invites" ON public.test_invites;

CREATE POLICY "Published tests viewable by authenticated users" ON public.tests FOR SELECT TO authenticated USING (is_published = true OR created_by = auth.uid() OR public.is_admin(auth.uid()));
CREATE POLICY "Teachers can manage their own tests" ON public.tests FOR ALL TO authenticated USING (created_by = auth.uid() OR public.is_admin(auth.uid()));
CREATE POLICY "Test questions viewable by authenticated users" ON public.test_questions FOR SELECT TO authenticated USING (true);
CREATE POLICY "Teachers manage test questions for their tests" ON public.test_questions FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM public.tests WHERE id = test_id AND created_by = auth.uid()) OR public.is_admin(auth.uid()));
CREATE POLICY "Test invites viewable by everyone" ON public.test_invites FOR SELECT TO authenticated USING (true);
CREATE POLICY "Teachers create test invites" ON public.test_invites FOR ALL TO authenticated USING (created_by = auth.uid() OR public.is_admin(auth.uid()));

-- 7. ATTEMPTS & ANSWERS
DROP POLICY IF EXISTS "Students manage their own test attempts" ON public.test_attempts;
DROP POLICY IF EXISTS "Teachers view attempts for their tests" ON public.test_attempts;
DROP POLICY IF EXISTS "Students manage their own test answers" ON public.test_answers;

CREATE POLICY "Students manage their own test attempts" ON public.test_attempts FOR ALL TO authenticated USING (student_id = auth.uid() OR public.is_admin(auth.uid()));
CREATE POLICY "Teachers view attempts for their tests" ON public.test_attempts FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM public.tests WHERE id = test_id AND created_by = auth.uid()));
CREATE POLICY "Students manage their own test answers" ON public.test_answers FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM public.test_attempts WHERE id = attempt_id AND student_id = auth.uid()));

-- 8. BOOKMARKS & MISTAKES
DROP POLICY IF EXISTS "Students manage their bookmarks" ON public.bookmarks;
DROP POLICY IF EXISTS "Students manage their mistake book" ON public.mistake_questions;

CREATE POLICY "Students manage their bookmarks" ON public.bookmarks FOR ALL TO authenticated USING (student_id = auth.uid());
CREATE POLICY "Students manage their mistake book" ON public.mistake_questions FOR ALL TO authenticated USING (student_id = auth.uid());

-- 9. REPORTS
DROP POLICY IF EXISTS "Students create reports, Admins view and manage" ON public.reports;
DROP POLICY IF EXISTS "Students insert reports" ON public.reports;
DROP POLICY IF EXISTS "Admins update reports" ON public.reports;

CREATE POLICY "Students create reports, Admins view and manage" ON public.reports FOR SELECT TO authenticated USING (student_id = auth.uid() OR public.is_admin(auth.uid()));
CREATE POLICY "Students insert reports" ON public.reports FOR INSERT TO authenticated WITH CHECK (student_id = auth.uid());
CREATE POLICY "Admins update reports" ON public.reports FOR UPDATE TO authenticated USING (public.is_admin(auth.uid()));

-- 10. LEADERBOARD & STREAKS
DROP POLICY IF EXISTS "Streaks are viewable by owner" ON public.streaks;
DROP POLICY IF EXISTS "Leaderboards are public" ON public.leaderboard_entries;

CREATE POLICY "Streaks are viewable by owner" ON public.streaks FOR SELECT TO authenticated USING (student_id = auth.uid());
CREATE POLICY "Leaderboards are public" ON public.leaderboard_entries FOR SELECT TO authenticated USING (true);

-- 11. NOTIFICATIONS & AUDIT LOGS
DROP POLICY IF EXISTS "Users view own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Admins view audit logs" ON public.audit_logs;
DROP POLICY IF EXISTS "App settings viewable by all, editable by admin" ON public.app_settings;
DROP POLICY IF EXISTS "Admins edit settings" ON public.app_settings;

CREATE POLICY "Users view own notifications" ON public.notifications FOR ALL TO authenticated USING (user_id = auth.uid());
CREATE POLICY "Admins view audit logs" ON public.audit_logs FOR SELECT TO authenticated USING (public.is_admin(auth.uid()));
CREATE POLICY "App settings viewable by all, editable by admin" ON public.app_settings FOR SELECT TO authenticated USING (true);
CREATE POLICY "Admins edit settings" ON public.app_settings FOR ALL TO authenticated USING (public.is_admin(auth.uid()));
