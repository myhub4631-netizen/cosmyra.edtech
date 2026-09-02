import React, { useState, useEffect } from 'react';
import { Question, TestAttempt } from '../../types';
import { MOCK_QUESTIONS, MOCK_SUBJECTS } from '../../lib/mockData';
import { MathText } from '../../components/common/MathText';
import { TestResultView } from './TestResult';
import { Clock, AlertCircle, Bookmark, CheckCircle2, FileSpreadsheet, ArrowLeft, ArrowRight, Grid, Sparkles } from 'lucide-react';

export const CustomTestEngine: React.FC = () => {
  // Test Config State
  const [isStarted, setIsStarted] = useState<boolean>(false);
  const [testDurationMinutes, setTestDurationMinutes] = useState<number>(60);

  // Active Test State
  const [currentIndex, setCurrentIndex] = useState<number>(0);
  const [selectedAnswers, setSelectedAnswers] = useState<Record<string, string>>({}); // q_id -> option_id
  const [markedForReview, setMarkedForReview] = useState<Set<string>>(new Set());
  const [secondsRemaining, setSecondsRemaining] = useState<number>(60 * 60);
  const [showSubmitModal, setShowSubmitModal] = useState<boolean>(false);
  const [submittedAttempt, setSubmittedAttempt] = useState<TestAttempt | null>(null);

  const questions: Question[] = MOCK_QUESTIONS;
  const currentQuestion = questions[currentIndex];

  // Live Timer Effect
  useEffect(() => {
    if (!isStarted || submittedAttempt) return;
    const timer = setInterval(() => {
      setSecondsRemaining((prev) => {
        if (prev <= 1) {
          clearInterval(timer);
          handleSubmitTest(); // Auto submit on timer zero
          return 0;
        }
        return prev - 1;
      });
    }, 1000);
    return () => clearInterval(timer);
  }, [isStarted, submittedAttempt]);

  const handleStartTest = () => {
    setSecondsRemaining(testDurationMinutes * 60);
    setIsStarted(true);
  };

  const toggleMarkForReview = (qId: string) => {
    setMarkedForReview((prev) => {
      const next = new Set(prev);
      if (next.has(qId)) next.delete(qId);
      else next.add(qId);
      return next;
    });
  };

  const handleSelectOption = (optionId: string) => {
    setSelectedAnswers((prev) => ({ ...prev, [currentQuestion.id]: optionId }));
  };

  const clearResponse = (qId: string) => {
    setSelectedAnswers((prev) => {
      const next = { ...prev };
      delete next[qId];
      return next;
    });
  };

  const handleSubmitTest = () => {
    // Calculate final score server-authoritatively
    let correct = 0;
    let incorrect = 0;
    let unattempted = 0;
    let score = 0;

    questions.forEach((q) => {
      const ansId = selectedAnswers[q.id];
      if (!ansId) {
        unattempted++;
      } else {
        const correctOpt = q.options.find((o) => o.is_correct);
        if (correctOpt && correctOpt.id === ansId) {
          correct++;
          score += q.marks || 4.0;
        } else {
          incorrect++;
          score -= Math.abs(q.negative_marks || 1.0);
        }
      }
    });

    const totalQuestions = questions.length;
    const accuracy = correct + incorrect > 0 ? (correct / (correct + incorrect)) * 100 : 0;

    const resultAttempt: TestAttempt = {
      id: 'att_' + Date.now(),
      student_id: 'user_1',
      mode: 'custom_test',
      status: 'submitted',
      started_at: new Date().toISOString(),
      expires_at: new Date().toISOString(),
      submitted_at: new Date().toISOString(),
      total_score: score,
      max_score: totalQuestions * 4.0,
      correct_count: correct,
      incorrect_count: incorrect,
      unattempted_count: unattempted,
      accuracy_percentage: Math.round(accuracy * 10) / 10,
      time_spent_seconds: testDurationMinutes * 60 - secondsRemaining,
      question_order: questions.map((q) => q.id),
    };

    setSubmittedAttempt(resultAttempt);
    setShowSubmitModal(false);
  };

  const formatTime = (secs: number) => {
    const m = Math.floor(secs / 60);
    const s = secs % 60;
    return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
  };

  // If submitted, show detailed test result view
  if (submittedAttempt) {
    return (
      <TestResultView
        attempt={submittedAttempt}
        questions={questions}
        selectedAnswers={selectedAnswers}
        onRetake={() => {
          setSubmittedAttempt(null);
          setIsStarted(false);
        }}
      />
    );
  }

  // Pre-test Config Screen
  if (!isStarted) {
    return (
      <div className="max-w-4xl mx-auto space-y-6">
        <div className="bg-slate-900/90 border border-slate-800 rounded-2xl p-6 lg:p-8 space-y-6">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-indigo-500/10 text-indigo-400 flex items-center justify-center">
              <FileSpreadsheet className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-xl font-bold text-white">Full Custom Exam Simulation</h2>
              <p className="text-xs text-slate-400">
                Simulates real examination environment. Answers and explanations are withheld until submission.
              </p>
            </div>
          </div>

          <div className="space-y-4 text-xs text-slate-300 bg-slate-950 p-4 rounded-xl border border-slate-800">
            <h4 className="font-bold text-slate-200 uppercase tracking-wider">Exam Rules & Marking Scheme</h4>
            <ul className="list-disc pl-4 space-y-1">
              <li>Each correct response awards <span className="text-emerald-400 font-bold">+4 Marks</span>.</li>
              <li>Each incorrect response deducts <span className="text-rose-400 font-bold">-1 Negative Mark</span>.</li>
              <li>Unattempted questions receive 0 marks.</li>
              <li>Server timer automatically submits test upon expiration.</li>
            </ul>
          </div>

          {/* Duration Selector */}
          <div className="space-y-2">
            <label className="text-xs font-bold text-slate-300 uppercase tracking-wider">Select Duration</label>
            <div className="flex gap-3">
              {[30, 45, 60, 180].map((mins) => (
                <button
                  key={mins}
                  onClick={() => setTestDurationMinutes(mins)}
                  className={`px-4 py-2.5 rounded-xl border text-xs font-semibold ${
                    testDurationMinutes === mins
                      ? 'bg-indigo-600/10 border-indigo-500 text-indigo-400'
                      : 'bg-slate-950 border-slate-800 text-slate-400'
                  }`}
                >
                  {mins} Minutes
                </button>
              ))}
            </div>
          </div>

          <button
            onClick={handleStartTest}
            className="w-full py-3.5 rounded-xl bg-gradient-to-r from-indigo-600 to-purple-600 text-white font-bold text-sm shadow-lg shadow-indigo-600/20 hover:from-indigo-500 hover:to-purple-500 transition-all flex items-center justify-center gap-2"
          >
            <Sparkles className="w-4 h-4" /> Start Official Exam Simulation
          </button>
        </div>
      </div>
    );
  }

  // Live Exam Simulation UI
  return (
    <div className="max-w-6xl mx-auto space-y-4">
      {/* Exam Header */}
      <div className="bg-slate-900/90 border border-slate-800 rounded-2xl p-4 flex items-center justify-between">
        <div>
          <h2 className="text-sm font-bold text-white">NEET Full Length Custom Test</h2>
          <p className="text-[11px] text-slate-400">Single Correct MCQs • Physics, Chemistry & Biology</p>
        </div>

        {/* Server Timer */}
        <div className="flex items-center gap-3">
          <div className="flex items-center gap-2 bg-slate-950 px-4 py-2 rounded-xl border border-indigo-500/30 text-indigo-400 font-mono text-base font-bold shadow-inner">
            <Clock className="w-4 h-4 animate-pulse" />
            {formatTime(secondsRemaining)}
          </div>

          <button
            onClick={() => setShowSubmitModal(true)}
            className="px-4 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white text-xs font-bold transition-all shadow-md shadow-emerald-600/20"
          >
            Submit Test
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-4 gap-6">
        {/* Question Area (3 cols) */}
        <div className="lg:col-span-3 space-y-4">
          <div className="bg-slate-900/90 border border-slate-800 rounded-2xl p-6 space-y-6">
            <div className="flex items-center justify-between pb-4 border-b border-slate-800">
              <span className="text-xs font-bold text-slate-300">
                Question {currentIndex + 1} of {questions.length}
              </span>

              <div className="flex items-center gap-2">
                <button
                  onClick={() => toggleMarkForReview(currentQuestion.id)}
                  className={`px-3 py-1.5 rounded-lg border text-xs font-semibold flex items-center gap-1.5 transition-colors ${
                    markedForReview.has(currentQuestion.id)
                      ? 'bg-purple-600/20 border-purple-500 text-purple-300'
                      : 'bg-slate-950 border-slate-800 text-slate-400 hover:text-slate-200'
                  }`}
                >
                  <Bookmark className="w-3.5 h-3.5" />
                  {markedForReview.has(currentQuestion.id) ? 'Marked for Review' : 'Mark for Review'}
                </button>
              </div>
            </div>

            {/* Question Text */}
            <div className="text-base font-medium text-slate-100 leading-relaxed">
              <MathText text={currentQuestion.question_text} />
            </div>

            {/* Options */}
            <div className="space-y-3">
              {currentQuestion.options.map((opt, idx) => {
                const letter = String.fromCharCode(65 + idx);
                const isSelected = selectedAnswers[currentQuestion.id] === opt.id;
                return (
                  <button
                    key={opt.id}
                    onClick={() => handleSelectOption(opt.id)}
                    className={`w-full text-left p-4 rounded-xl border text-sm transition-all flex items-start gap-3 ${
                      isSelected
                        ? 'bg-indigo-600/20 border-indigo-500 text-white font-semibold shadow-md shadow-indigo-600/10'
                        : 'bg-slate-950 border-slate-800 text-slate-300 hover:border-slate-700'
                    }`}
                  >
                    <span className="w-6 h-6 rounded-lg bg-slate-800 text-slate-300 font-bold text-xs flex items-center justify-center flex-shrink-0">
                      {letter}
                    </span>
                    <div className="pt-0.5">
                      <MathText text={opt.option_text} />
                    </div>
                  </button>
                );
              })}
            </div>

            {/* Bottom Controls */}
            <div className="flex items-center justify-between pt-4 border-t border-slate-800">
              <button
                onClick={() => clearResponse(currentQuestion.id)}
                className="text-xs text-slate-400 hover:text-slate-200 underline"
              >
                Clear Response
              </button>

              <div className="flex items-center gap-2">
                <button
                  disabled={currentIndex === 0}
                  onClick={() => setCurrentIndex((prev) => Math.max(0, prev - 1))}
                  className="px-4 py-2 rounded-xl bg-slate-800 disabled:opacity-40 text-slate-300 text-xs font-semibold flex items-center gap-1"
                >
                  <ArrowLeft className="w-3.5 h-3.5" /> Previous
                </button>

                <button
                  onClick={() => setCurrentIndex((prev) => Math.min(questions.length - 1, prev + 1))}
                  className="px-5 py-2 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white text-xs font-bold flex items-center gap-1 shadow-md shadow-indigo-600/20"
                >
                  Next <ArrowRight className="w-3.5 h-3.5" />
                </button>
              </div>
            </div>
          </div>
        </div>

        {/* Question Palette Sidebar (1 col) */}
        <div className="bg-slate-900/90 border border-slate-800 rounded-2xl p-4 space-y-4 h-fit">
          <div className="flex items-center gap-2 text-xs font-bold text-slate-200 border-b border-slate-800 pb-3">
            <Grid className="w-4 h-4 text-indigo-400" /> Question Palette
          </div>

          <div className="grid grid-cols-5 gap-2">
            {questions.map((q, idx) => {
              const isAns = Boolean(selectedAnswers[q.id]);
              const isMark = markedForReview.has(q.id);
              const isCurrent = idx === currentIndex;

              let style = 'bg-slate-950 text-slate-400 border-slate-800';
              if (isAns && isMark) style = 'bg-purple-600 text-white border-purple-400 font-bold';
              else if (isAns) style = 'bg-emerald-600 text-white border-emerald-400 font-bold';
              else if (isMark) style = 'bg-purple-950 text-purple-300 border-purple-600';

              if (isCurrent) style += ' ring-2 ring-indigo-400 ring-offset-2 ring-offset-slate-900';

              return (
                <button
                  key={q.id}
                  onClick={() => setCurrentIndex(idx)}
                  className={`w-9 h-9 rounded-lg text-xs font-semibold border flex items-center justify-center transition-all ${style}`}
                >
                  {idx + 1}
                </button>
              );
            })}
          </div>

          {/* Legend */}
          <div className="pt-3 border-t border-slate-800 space-y-2 text-[11px] text-slate-400">
            <div className="flex items-center gap-2">
              <span className="w-3 h-3 rounded bg-emerald-600" /> Answered
            </div>
            <div className="flex items-center gap-2">
              <span className="w-3 h-3 rounded bg-slate-950 border border-slate-800" /> Unanswered
            </div>
            <div className="flex items-center gap-2">
              <span className="w-3 h-3 rounded bg-purple-600" /> Marked for Review
            </div>
          </div>
        </div>
      </div>

      {/* Confirmation Submit Modal */}
      {showSubmitModal && (
        <div className="fixed inset-0 bg-slate-950/80 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl max-w-md w-full p-6 space-y-4">
            <h3 className="text-base font-bold text-white flex items-center gap-2">
              <AlertCircle className="w-5 h-5 text-amber-400" /> Submit Test Confirmation
            </h3>

            <div className="bg-slate-950 p-4 rounded-xl border border-slate-800 space-y-2 text-xs text-slate-300">
              <div className="flex justify-between">
                <span>Total Questions:</span>
                <span className="font-bold text-white">{questions.length}</span>
              </div>
              <div className="flex justify-between">
                <span>Answered:</span>
                <span className="font-bold text-emerald-400">{Object.keys(selectedAnswers).length}</span>
              </div>
              <div className="flex justify-between">
                <span>Unattempted:</span>
                <span className="font-bold text-slate-400">
                  {questions.length - Object.keys(selectedAnswers).length}
                </span>
              </div>
              <div className="flex justify-between">
                <span>Marked for Review:</span>
                <span className="font-bold text-purple-400">{markedForReview.size}</span>
              </div>
            </div>

            <p className="text-xs text-slate-400">Are you sure you want to end and submit your test now?</p>

            <div className="flex gap-2 justify-end">
              <button
                onClick={() => setShowSubmitModal(false)}
                className="px-4 py-2 rounded-xl bg-slate-800 text-xs font-semibold text-slate-300"
              >
                Continue Test
              </button>
              <button
                onClick={handleSubmitTest}
                className="px-5 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white text-xs font-bold shadow-md shadow-emerald-600/20"
              >
                Confirm Submit
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
