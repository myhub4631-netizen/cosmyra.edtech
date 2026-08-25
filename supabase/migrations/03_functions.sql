-- ========================================================
-- COSMYRA COMPETITIVE EXAM PRACTICE PLATFORM - RPC FUNCTIONS
-- Migration: 03_functions.sql
-- ========================================================

-- 1. FUNCTION: Generate Custom Practice / Test Questions
CREATE OR REPLACE FUNCTION public.get_practice_questions(
  p_exam_id UUID,
  p_subject_ids UUID[],
  p_chapter_ids UUID[],
  p_topic_ids UUID[],
  p_difficulty difficulty_level DEFAULT NULL,
  p_source question_source DEFAULT NULL,
  p_limit INT DEFAULT 20
)
RETURNS TABLE (
  id UUID,
  exam_id UUID,
  subject_id UUID,
  chapter_id UUID,
  topic_id UUID,
  question_text TEXT,
  question_image TEXT,
  q_type question_type,
  difficulty difficulty_level,
  source question_source,
  marks NUMERIC(5,2),
  negative_marks NUMERIC(5,2),
  year INT,
  explanation TEXT,
  solution TEXT,
  options JSONB
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    q.id,
    q.exam_id,
    q.subject_id,
    q.chapter_id,
    q.topic_id,
    q.question_text,
    q.question_image,
    q.q_type,
    q.difficulty,
    q.source,
    q.marks,
    q.negative_marks,
    q.year,
    q.explanation,
    q.solution,
    COALESCE(
      jsonb_agg(
        jsonb_build_object(
          'id', opt.id,
          'option_index', opt.option_index,
          'option_text', opt.option_text,
          'option_image', opt.option_image,
          'is_correct', opt.is_correct
        ) ORDER BY opt.option_index
      ), '[]'::jsonb
    ) AS options
  FROM public.questions q
  LEFT JOIN public.question_options opt ON q.id = opt.question_id
  WHERE q.status = 'published'
    AND q.exam_id = p_exam_id
    AND (p_subject_ids IS NULL OR cardinality(p_subject_ids) = 0 OR q.subject_id = ANY(p_subject_ids))
    AND (p_chapter_ids IS NULL OR cardinality(p_chapter_ids) = 0 OR q.chapter_id = ANY(p_chapter_ids))
    AND (p_topic_ids IS NULL OR cardinality(p_topic_ids) = 0 OR q.topic_id = ANY(p_topic_ids))
    AND (p_difficulty IS NULL OR q.difficulty = p_difficulty)
    AND (p_source IS NULL OR q.source = p_source)
  GROUP BY q.id
  ORDER BY RANDOM()
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. FUNCTION: Create Secure Test Attempt (Hides Correct Answers from payload)
CREATE OR REPLACE FUNCTION public.start_test_attempt(
  p_student_id UUID,
  p_test_id UUID DEFAULT NULL,
  p_mode test_type DEFAULT 'custom_test',
  p_duration_minutes INT DEFAULT 60,
  p_question_ids UUID[] DEFAULT '{}'
)
RETURNS JSONB AS $$
DECLARE
  v_attempt_id UUID;
  v_expires_at TIMESTAMPTZ;
  v_questions JSONB;
BEGIN
  -- Calculate server-authoritative expiration
  v_expires_at := NOW() + (p_duration_minutes || ' minutes')::INTERVAL;

  INSERT INTO public.test_attempts (
    student_id,
    test_id,
    mode,
    status,
    started_at,
    expires_at,
    question_order
  ) VALUES (
    p_student_id,
    p_test_id,
    p_mode,
    'in_progress',
    NOW(),
    v_expires_at,
    p_question_ids
  ) RETURNING id INTO v_attempt_id;

  -- Fetch questions WITHOUT revealing is_correct option keys or solutions during active test
  SELECT jsonb_agg(
    jsonb_build_object(
      'id', q.id,
      'question_text', q.question_text,
      'question_image', q.question_image,
      'q_type', q.q_type,
      'difficulty', q.difficulty,
      'marks', q.marks,
      'negative_marks', q.negative_marks,
      'options', (
        SELECT jsonb_agg(
          jsonb_build_object(
            'id', opt.id,
            'option_index', opt.option_index,
            'option_text', opt.option_text,
            'option_image', opt.option_image
            -- Intentionally EXCLUDING is_correct for test security!
          ) ORDER BY opt.option_index
        )
        FROM public.question_options opt
        WHERE opt.question_id = q.id
      )
    )
  ) INTO v_questions
  FROM public.questions q
  WHERE q.id = ANY(p_question_ids);

  RETURN jsonb_build_object(
    'attempt_id', v_attempt_id,
    'started_at', NOW(),
    'expires_at', v_expires_at,
    'questions', COALESCE(v_questions, '[]'::jsonb)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. FUNCTION: Submit Test Attempt & Server-side Score Calculation
CREATE OR REPLACE FUNCTION public.submit_test_attempt(
  p_attempt_id UUID,
  p_student_id UUID,
  p_answers JSONB -- Array of { question_id, selected_option_ids, numerical_answer, is_marked_for_review, time_spent_seconds }
)
RETURNS JSONB AS $$
DECLARE
  v_attempt public.test_attempts%ROWTYPE;
  v_elem JSONB;
  v_q_id UUID;
  v_selected_opts UUID[];
  v_correct_opts UUID[];
  v_is_correct BOOLEAN;
  v_marks NUMERIC(5,2);
  v_neg_marks NUMERIC(5,2);
  v_awarded NUMERIC(5,2);
  
  v_total_score NUMERIC(6,2) := 0;
  v_max_score NUMERIC(6,2) := 0;
  v_correct_count INT := 0;
  v_incorrect_count INT := 0;
  v_unattempted_count INT := 0;
  v_total_time INT := 0;
  v_accuracy NUMERIC(5,2) := 0;
BEGIN
  -- Verify attempt ownership and state
  SELECT * INTO v_attempt 
  FROM public.test_attempts 
  WHERE id = p_attempt_id AND student_id = p_student_id;

  IF v_attempt.id IS NULL THEN
    RAISE EXCEPTION 'Attempt not found or unauthorized';
  END IF;

  IF v_attempt.status = 'submitted' THEN
    RAISE EXCEPTION 'Attempt has already been submitted';
  END IF;

  -- Process submitted answers
  FOR v_elem IN SELECT * FROM jsonb_array_elements(p_answers)
  LOOP
    v_q_id := (v_elem->>'question_id')::UUID;
    v_selected_opts := ARRAY(SELECT jsonb_array_elements_text(v_elem->'selected_option_ids'))::UUID[];

    -- Fetch correct options and marks
    SELECT array_agg(id) INTO v_correct_opts 
    FROM public.question_options 
    WHERE question_id = v_q_id AND is_correct = true;

    SELECT marks, negative_marks INTO v_marks, v_neg_marks 
    FROM public.questions WHERE id = v_q_id;

    v_max_score := v_max_score + COALESCE(v_marks, 4.0);
    v_total_time := v_total_time + COALESCE((v_elem->>'time_spent_seconds')::INT, 0);

    IF v_selected_opts IS NULL OR cardinality(v_selected_opts) = 0 THEN
      v_unattempted_count := v_unattempted_count + 1;
      v_awarded := 0;
      v_is_correct := false;
    ELSIF v_selected_opts <@ v_correct_opts AND v_correct_opts <@ v_selected_opts THEN
      v_correct_count := v_correct_count + 1;
      v_awarded := COALESCE(v_marks, 4.0);
      v_total_score := v_total_score + v_awarded;
      v_is_correct := true;
    ELSE
      v_incorrect_count := v_incorrect_count + 1;
      v_awarded := -1 * ABS(COALESCE(v_neg_marks, 1.0));
      v_total_score := v_total_score + v_awarded;
      v_is_correct := false;

      -- Add to mistake book automatically
      INSERT INTO public.mistake_questions (student_id, question_id)
      VALUES (p_student_id, v_q_id)
      ON CONFLICT (student_id, question_id) 
      DO UPDATE SET incorrect_attempts = mistake_questions.incorrect_attempts + 1, is_resolved = false;
    END IF;

    -- Store individual answer details
    INSERT INTO public.test_answers (
      attempt_id,
      question_id,
      selected_option_ids,
      numerical_answer,
      is_marked_for_review,
      is_correct,
      marks_awarded,
      time_spent_seconds
    ) VALUES (
      p_attempt_id,
      v_q_id,
      v_selected_opts,
      v_elem->>'numerical_answer',
      COALESCE((v_elem->>'is_marked_for_review')::BOOLEAN, false),
      v_is_correct,
      v_awarded,
      COALESCE((v_elem->>'time_spent_seconds')::INT, 0)
    ) ON CONFLICT (attempt_id, question_id) DO UPDATE SET
      selected_option_ids = EXCLUDED.selected_option_ids,
      is_correct = EXCLUDED.is_correct,
      marks_awarded = EXCLUDED.marks_awarded,
      time_spent_seconds = EXCLUDED.time_spent_seconds;
  END LOOP;

  -- Calculate accuracy percentage
  IF (v_correct_count + v_incorrect_count) > 0 THEN
    v_accuracy := ROUND((v_correct_count::NUMERIC / (v_correct_count + v_incorrect_count)::NUMERIC) * 100, 2);
  END IF;

  -- Update Attempt status
  UPDATE public.test_attempts SET
    status = 'submitted',
    submitted_at = NOW(),
    total_score = v_total_score,
    max_score = v_max_score,
    correct_count = v_correct_count,
    incorrect_count = v_incorrect_count,
    unattempted_count = v_unattempted_count,
    accuracy_percentage = v_accuracy,
    time_spent_seconds = v_total_time,
    updated_at = NOW()
  WHERE id = p_attempt_id;

  -- Update Streak
  INSERT INTO public.streaks (student_id, current_streak, longest_streak, last_activity_date)
  VALUES (p_student_id, 1, 1, CURRENT_DATE)
  ON CONFLICT (student_id) DO UPDATE SET
    current_streak = CASE 
      WHEN streaks.last_activity_date = CURRENT_DATE THEN streaks.current_streak
      WHEN streaks.last_activity_date = CURRENT_DATE - INTERVAL '1 day' THEN streaks.current_streak + 1
      ELSE 1
    END,
    longest_streak = GREATEST(streaks.longest_streak, CASE 
      WHEN streaks.last_activity_date = CURRENT_DATE - INTERVAL '1 day' THEN streaks.current_streak + 1
      ELSE 1
    END),
    last_activity_date = CURRENT_DATE;

  RETURN jsonb_build_object(
    'attempt_id', p_attempt_id,
    'total_score', v_total_score,
    'max_score', v_max_score,
    'correct_count', v_correct_count,
    'incorrect_count', v_incorrect_count,
    'unattempted_count', v_unattempted_count,
    'accuracy_percentage', v_accuracy,
    'time_spent_seconds', v_total_time
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
