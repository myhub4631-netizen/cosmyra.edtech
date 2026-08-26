-- ========================================================
-- COSMYRA COMPETITIVE EXAM PRACTICE PLATFORM - RLS POLICIES
-- Migration: 02_rls.sql
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
  RETURN public.has_role(user_id, 'admin') OR public.has_role(user_id, 'super_admin');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.is_teacher(user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN public.has_role(user_id, 'teacher') OR public.is_admin(user_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 1. PROFILES
CREATE POLICY "Public profiles are viewable by authenticated users" 
ON public.profiles FOR SELECT TO authenticated USING (true);

CREATE POLICY "Users can insert their own profile" 
ON public.profiles FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile" 
ON public.profiles FOR UPDATE TO authenticated USING (auth.uid() = id);

CREATE POLICY "Admins can manage all profiles" 
ON public.profiles FOR ALL TO authenticated USING (public.is_admin(auth.uid()));

-- 2. USER ROLES
CREATE POLICY "Admins can view and manage all user roles"
ON public.user_roles FOR ALL TO authenticated USING (public.is_admin(auth.uid()));

CREATE POLICY "Users can view their own roles"
ON public.user_roles FOR SELECT TO authenticated USING (auth.uid() = user_id);

-- 3. TEACHERS
CREATE POLICY "Authenticated users can view approved teachers"
ON public.teachers FOR SELECT TO authenticated USING (verification_status = 'approved' OR auth.uid() = id OR public.is_admin(auth.uid()));

CREATE POLICY "Teachers can insert and update their own application"
ON public.teachers FOR ALL TO authenticated USING (auth.uid() = id);

-- 4. TAXONOMY (Exams, Subjects, Chapters, Topics, Subtopics, Tags)
CREATE POLICY "Taxonomy is readable by everyone" ON public.exams FOR SELECT TO authenticated USING (true);
CREATE POLICY "Taxonomy is readable by everyone" ON public.subjects FOR SELECT TO authenticated USING (true);
CREATE POLICY "Taxonomy is readable by everyone" ON public.chapters FOR SELECT TO authenticated USING (true);
CREATE POLICY "Taxonomy is readable by everyone" ON public.topics FOR SELECT TO authenticated USING (true);
CREATE POLICY "Taxonomy is readable by everyone" ON public.subtopics FOR SELECT TO authenticated USING (true);
CREATE POLICY "Taxonomy is readable by everyone" ON public.tags FOR SELECT TO authenticated USING (true);

CREATE POLICY "Admins manage taxonomy" ON public.exams FOR ALL TO authenticated USING (public.is_admin(auth.uid()));
CREATE POLICY "Admins manage taxonomy" ON public.subjects FOR ALL TO authenticated USING (public.is_admin(auth.uid()));
CREATE POLICY "Admins manage taxonomy" ON public.chapters FOR ALL TO authenticated USING (public.is_admin(auth.uid()));
CREATE POLICY "Admins manage taxonomy" ON public.topics FOR ALL TO authenticated USING (public.is_admin(auth.uid()));
CREATE POLICY "Admins manage taxonomy" ON public.subtopics FOR ALL TO authenticated USING (public.is_admin(auth.uid()));

-- 5. QUESTIONS & OPTIONS
CREATE POLICY "Published questions viewable by authenticated users"
ON public.questions FOR SELECT TO authenticated 
USING (status = 'published' OR created_by = auth.uid() OR public.is_admin(auth.uid()));

CREATE POLICY "Teachers and admins can insert questions"
ON public.questions FOR INSERT TO authenticated 
WITH CHECK (public.is_teacher(auth.uid()) OR public.is_admin(auth.uid()));

CREATE POLICY "Admins and creators can update questions"
ON public.questions FOR UPDATE TO authenticated 
USING (created_by = auth.uid() OR public.is_admin(auth.uid()));

CREATE POLICY "Options viewable by authenticated users"
ON public.question_options FOR SELECT TO authenticated USING (true);

CREATE POLICY "Teachers and admins manage options"
ON public.question_options FOR ALL TO authenticated 
USING (public.is_teacher(auth.uid()) OR public.is_admin(auth.uid()));

-- 6. TESTS & INVITATIONS
CREATE POLICY "Published tests viewable by authenticated users"
ON public.tests FOR SELECT TO authenticated 
USING (is_published = true OR created_by = auth.uid() OR public.is_admin(auth.uid()));

CREATE POLICY "Teachers can manage their own tests"
ON public.tests FOR ALL TO authenticated 
USING (created_by = auth.uid() OR public.is_admin(auth.uid()));

CREATE POLICY "Test questions viewable by authenticated users"
ON public.test_questions FOR SELECT TO authenticated USING (true);

CREATE POLICY "Teachers manage test questions for their tests"
ON public.test_questions FOR ALL TO authenticated 
USING (EXISTS (SELECT 1 FROM public.tests WHERE id = test_id AND created_by = auth.uid()) OR public.is_admin(auth.uid()));

CREATE POLICY "Test invites viewable by everyone"
ON public.test_invites FOR SELECT TO authenticated USING (true);

CREATE POLICY "Teachers create test invites"
ON public.test_invites FOR ALL TO authenticated 
USING (created_by = auth.uid() OR public.is_admin(auth.uid()));

-- 7. ATTEMPTS & ANSWERS
CREATE POLICY "Students manage their own test attempts"
ON public.test_attempts FOR ALL TO authenticated 
USING (student_id = auth.uid() OR public.is_admin(auth.uid()));

CREATE POLICY "Teachers view attempts for their tests"
ON public.test_attempts FOR SELECT TO authenticated 
USING (EXISTS (SELECT 1 FROM public.tests WHERE id = test_id AND created_by = auth.uid()));

CREATE POLICY "Students manage their own test answers"
ON public.test_answers FOR ALL TO authenticated 
USING (EXISTS (SELECT 1 FROM public.test_attempts WHERE id = attempt_id AND student_id = auth.uid()));

-- 8. BOOKMARKS & MISTAKES
CREATE POLICY "Students manage their bookmarks"
ON public.bookmarks FOR ALL TO authenticated USING (student_id = auth.uid());

CREATE POLICY "Students manage their mistake book"
ON public.mistake_questions FOR ALL TO authenticated USING (student_id = auth.uid());

-- 9. REPORTS
CREATE POLICY "Students create reports, Admins view and manage"
ON public.reports FOR SELECT TO authenticated USING (student_id = auth.uid() OR public.is_admin(auth.uid()));
CREATE POLICY "Students insert reports" ON public.reports FOR INSERT TO authenticated WITH CHECK (student_id = auth.uid());
CREATE POLICY "Admins update reports" ON public.reports FOR UPDATE TO authenticated USING (public.is_admin(auth.uid()));

-- 10. LEADERBOARD & STREAKS
CREATE POLICY "Streaks are viewable by owner" ON public.streaks FOR SELECT TO authenticated USING (student_id = auth.uid());
CREATE POLICY "Leaderboards are public" ON public.leaderboard_entries FOR SELECT TO authenticated USING (true);

-- 11. NOTIFICATIONS & AUDIT LOGS
CREATE POLICY "Users view own notifications" ON public.notifications FOR ALL TO authenticated USING (user_id = auth.uid());
CREATE POLICY "Admins view audit logs" ON public.audit_logs FOR SELECT TO authenticated USING (public.is_admin(auth.uid()));
CREATE POLICY "App settings viewable by all, editable by admin" ON public.app_settings FOR SELECT TO authenticated USING (true);
CREATE POLICY "Admins edit settings" ON public.app_settings FOR ALL TO authenticated USING (public.is_admin(auth.uid()));
