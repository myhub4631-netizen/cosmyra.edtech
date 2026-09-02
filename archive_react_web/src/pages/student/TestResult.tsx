import React from 'react';
import { Question, TestAttempt } from '../../types';
import { MathText } from '../../components/common/MathText';
import { Trophy, CheckCircle2, XCircle, Clock, RotateCcw, BookOpen, Bookmark, AlertCircle } from 'lucide-react';

interface TestResultViewProps {
  attempt: TestAttempt;
  questions: Question[];
  selectedAnswers: Record<string, string>;
  onRetake: () => void;
}

export const TestResultView: React.FC<TestResultViewProps> = ({
  attempt,
  questions,
  selectedAnswers,
  onRetake,
}) => {
  return (
    <div className="max-w-4xl mx-auto space-y-6">
      {/* Top Banner */}
      <div className="bg-gradient-to-r from-blue-900/60 via-slate-900 to-slate-900 border border-blue-500/20 rounded-2xl p-6 lg:p-8 space-y-6">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 text-xs font-semibold mb-2">
              <CheckCircle2 className="w-3.5 h-3.5" /> Test Completed Successfully
            </span>
            <h2 className="text-2xl font-black text-white">Performance Scorecard</h2>
            <p className="text-xs text-slate-400">Detailed question-wise analysis and solutions breakdown.</p>
          </div>

          <button
            onClick={onRetake}
            className="px-4 py-2.5 rounded-xl bg-blue-600 hover:bg-blue-500 text-white text-xs font-bold flex items-center gap-2 transition-all shadow-md shadow-blue-600/20"
          >
            <RotateCcw className="w-3.5 h-3.5" /> Retake Test
          </button>
        </div>

        {/* Score metrics grid */}
        <div className="grid grid-cols-2 sm:grid-cols-5 gap-3">
          <div className="bg-slate-950 p-4 rounded-xl border border-slate-800">
            <p className="text-[10px] font-bold text-slate-500 uppercase">Total Score</p>
            <p className="text-2xl font-black text-blue-400 mt-1">
              {attempt.total_score} <span className="text-xs font-normal text-slate-500">/ {attempt.max_score}</span>
            </p>
          </div>

          <div className="bg-slate-950 p-4 rounded-xl border border-slate-800">
            <p className="text-[10px] font-bold text-slate-500 uppercase">Accuracy Rate</p>
            <p className="text-2xl font-black text-emerald-400 mt-1">{attempt.accuracy_percentage}%</p>
          </div>

          <div className="bg-slate-950 p-4 rounded-xl border border-slate-800">
            <p className="text-[10px] font-bold text-slate-500 uppercase">Correct</p>
            <p className="text-2xl font-black text-emerald-400 mt-1">{attempt.correct_count}</p>
          </div>

          <div className="bg-slate-950 p-4 rounded-xl border border-slate-800">
            <p className="text-[10px] font-bold text-slate-500 uppercase">Incorrect</p>
            <p className="text-2xl font-black text-rose-400 mt-1">{attempt.incorrect_count}</p>
          </div>

          <div className="bg-slate-950 p-4 rounded-xl border border-slate-800">
            <p className="text-[10px] font-bold text-slate-500 uppercase">Time Spent</p>
            <p className="text-2xl font-black text-purple-400 mt-1">
              {Math.floor(attempt.time_spent_seconds / 60)}m {attempt.time_spent_seconds % 60}s
            </p>
          </div>
        </div>
      </div>

      {/* Detailed Question Review & Solutions */}
      <div className="space-y-4">
        <h3 className="text-base font-bold text-white flex items-center gap-2">
          <BookOpen className="w-4 h-4 text-blue-400" /> Detailed Question Solutions & Review
        </h3>

        {questions.map((q, idx) => {
          const userAnsId = selectedAnswers[q.id];
          const correctOpt = q.options.find((o) => o.is_correct);
          const isCorrect = userAnsId && correctOpt && userAnsId === correctOpt.id;
          const isUnattempted = !userAnsId;

          return (
            <div
              key={q.id}
              className={`bg-slate-900/90 border rounded-2xl p-6 space-y-4 ${
                isCorrect
                  ? 'border-emerald-500/30'
                  : isUnattempted
                  ? 'border-slate-800'
                  : 'border-rose-500/30'
              }`}
            >
              <div className="flex items-center justify-between pb-3 border-b border-slate-800">
                <div className="flex items-center gap-2">
                  <span className="text-xs font-bold text-slate-200">Question {idx + 1}</span>
                  {isCorrect ? (
                    <span className="px-2.5 py-0.5 rounded-full bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 text-[10px] font-semibold">
                      Correct (+4 Marks)
                    </span>
                  ) : isUnattempted ? (
                    <span className="px-2.5 py-0.5 rounded-full bg-slate-800 text-slate-400 text-[10px] font-semibold">
                      Unattempted (0 Marks)
                    </span>
                  ) : (
                    <span className="px-2.5 py-0.5 rounded-full bg-rose-500/10 text-rose-400 border border-rose-500/20 text-[10px] font-semibold">
                      Incorrect (-1 Mark)
                    </span>
                  )}
                </div>

                <span className="text-[11px] text-slate-400 uppercase font-semibold">{q.difficulty}</span>
              </div>

              {/* Question Text */}
              <div className="text-sm font-medium text-slate-100">
                <MathText text={q.question_text} />
              </div>

              {/* Options */}
              <div className="space-y-2">
                {q.options.map((opt, oIdx) => {
                  const letter = String.fromCharCode(65 + oIdx);
                  const isSelected = userAnsId === opt.id;
                  let optStyle = 'bg-slate-950 border-slate-800 text-slate-400';

                  if (opt.is_correct) {
                    optStyle = 'bg-emerald-500/10 border-emerald-500 text-emerald-300 font-semibold';
                  } else if (isSelected && !opt.is_correct) {
                    optStyle = 'bg-rose-500/10 border-rose-500 text-rose-300 font-semibold';
                  }

                  return (
                    <div key={opt.id} className={`p-3 rounded-xl border text-xs flex items-center gap-3 ${optStyle}`}>
                      <span className="w-5 h-5 rounded bg-slate-800 text-slate-300 font-bold flex items-center justify-center text-[10px]">
                        {letter}
                      </span>
                      <MathText text={opt.option_text} />
                    </div>
                  );
                })}
              </div>

              {/* Solution Drawer */}
              <div className="p-4 rounded-xl bg-slate-950 border border-slate-800 space-y-2 text-xs text-slate-300">
                <p className="font-bold text-slate-200">Concept & Explanation:</p>
                <MathText text={q.explanation || ''} />

                <p className="font-bold text-slate-200 mt-2">Step-by-step Solution:</p>
                <MathText text={q.solution || ''} />
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};
