import React, { useState } from 'react';
import { Question } from '../../types';
import { MOCK_QUESTIONS, MOCK_SUBJECTS, MOCK_CHAPTERS } from '../../lib/mockData';
import { MathText } from '../../components/common/MathText';
import { Target, CheckCircle2, XCircle, Bookmark, AlertTriangle, ArrowRight, ArrowLeft, RefreshCw, Sparkles, BookOpen } from 'lucide-react';

export const CustomPractice: React.FC = () => {
  // Configuration State
  const [selectedSubjects, setSelectedSubjects] = useState<string[]>(['s1111111-1111-1111-1111-111111111111']);
  const [selectedDifficulty, setSelectedDifficulty] = useState<string>('all');
  const [questionLimit, setQuestionLimit] = useState<number>(10);
  const [isStarted, setIsStarted] = useState<boolean>(false);

  // Active Practice State
  const [currentIndex, setCurrentIndex] = useState<number>(0);
  const [userAnswers, setUserAnswers] = useState<Record<string, string>>({}); // question_id -> option_id
  const [bookmarkedIds, setBookmarkedIds] = useState<Set<string>>(new Set());
  const [showReportModal, setShowReportModal] = useState<boolean>(false);
  const [reportReason, setReportReason] = useState<string>('');

  const questions: Question[] = MOCK_QUESTIONS;
  const currentQuestion = questions[currentIndex];
  const selectedOptionId = userAnswers[currentQuestion?.id];
  const isAnswered = Boolean(selectedOptionId);

  const toggleSubject = (subjectId: string) => {
    setSelectedSubjects((prev) =>
      prev.includes(subjectId) ? prev.filter((id) => id !== subjectId) : [...prev, subjectId]
    );
  };

  const handleSelectOption = (optionId: string) => {
    if (isAnswered) return; // Prevent changing after immediate reveal
    setUserAnswers((prev) => ({ ...prev, [currentQuestion.id]: optionId }));
  };

  const toggleBookmark = (qId: string) => {
    setBookmarkedIds((prev) => {
      const next = new Set(prev);
      if (next.has(qId)) next.delete(qId);
      else next.add(qId);
      return next;
    });
  };

  if (!isStarted) {
    return (
      <div className="max-w-4xl mx-auto space-y-6">
        <div className="bg-slate-900/90 border border-slate-800 rounded-2xl p-6 lg:p-8 space-y-6">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-blue-500/10 text-blue-400 flex items-center justify-center">
              <Target className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-xl font-bold text-white">Custom Practice Session</h2>
              <p className="text-xs text-slate-400">
                Configure your custom question set. Answers and step-by-step solutions appear immediately.
              </p>
            </div>
          </div>

          {/* Subject Filter */}
          <div className="space-y-2">
            <label className="text-xs font-bold text-slate-300 uppercase tracking-wider">Select Subjects</label>
            <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
              {MOCK_SUBJECTS.map((sub) => {
                const isSelected = selectedSubjects.includes(sub.id);
                return (
                  <button
                    key={sub.id}
                    onClick={() => toggleSubject(sub.id)}
                    className={`p-3 rounded-xl border text-left text-xs font-semibold transition-all ${
                      isSelected
                        ? 'bg-blue-600/10 border-blue-500 text-blue-400'
                        : 'bg-slate-950 border-slate-800 text-slate-400 hover:text-slate-200'
                    }`}
                  >
                    <div className="flex items-center justify-between">
                      <span>{sub.name}</span>
                      {isSelected && <CheckCircle2 className="w-4 h-4 text-blue-400" />}
                    </div>
                  </button>
                );
              })}
            </div>
          </div>

          {/* Difficulty Filter */}
          <div className="space-y-2">
            <label className="text-xs font-bold text-slate-300 uppercase tracking-wider">Difficulty Level</label>
            <div className="grid grid-cols-4 gap-3">
              {['all', 'easy', 'medium', 'hard'].map((diff) => (
                <button
                  key={diff}
                  onClick={() => setSelectedDifficulty(diff)}
                  className={`p-2.5 rounded-xl border text-xs font-semibold capitalize transition-all ${
                    selectedDifficulty === diff
                      ? 'bg-indigo-600/10 border-indigo-500 text-indigo-400'
                      : 'bg-slate-950 border-slate-800 text-slate-400 hover:text-slate-200'
                  }`}
                >
                  {diff}
                </button>
              ))}
            </div>
          </div>

          {/* Question Limit */}
          <div className="space-y-2">
            <label className="text-xs font-bold text-slate-300 uppercase tracking-wider">Number of Questions</label>
            <div className="flex gap-3">
              {[5, 10, 20, 30].map((num) => (
                <button
                  key={num}
                  onClick={() => setQuestionLimit(num)}
                  className={`px-4 py-2 rounded-xl border text-xs font-semibold transition-all ${
                    questionLimit === num
                      ? 'bg-purple-600/10 border-purple-500 text-purple-400'
                      : 'bg-slate-950 border-slate-800 text-slate-400'
                  }`}
                >
                  {num} Questions
                </button>
              ))}
            </div>
          </div>

          <button
            onClick={() => setIsStarted(true)}
            className="w-full py-3.5 rounded-xl bg-gradient-to-r from-blue-600 to-indigo-600 text-white font-bold text-sm shadow-lg shadow-blue-600/20 hover:from-blue-500 hover:to-indigo-500 transition-all flex items-center justify-center gap-2"
          >
            <Sparkles className="w-4 h-4" /> Start Custom Practice Now
          </button>
        </div>
      </div>
    );
  }

  // Active Practice UI
  const isCorrect = selectedOptionId
    ? currentQuestion.options.find((o) => o.id === selectedOptionId)?.is_correct
    : null;

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      {/* Top Navigation & Status */}
      <div className="flex items-center justify-between bg-slate-900/90 border border-slate-800 rounded-xl p-4">
        <div className="flex items-center gap-3">
          <button
            onClick={() => setIsStarted(false)}
            className="p-1.5 rounded-lg bg-slate-800 text-slate-300 hover:text-white"
          >
            <ArrowLeft className="w-4 h-4" />
          </button>
          <span className="text-xs font-bold text-slate-200">
            Question {currentIndex + 1} of {questions.length}
          </span>
        </div>

        <div className="flex items-center gap-2">
          <span className="px-2.5 py-1 rounded-full bg-slate-800 text-[11px] font-semibold text-slate-300 uppercase">
            {currentQuestion.difficulty}
          </span>
          <button
            onClick={() => toggleBookmark(currentQuestion.id)}
            className={`p-2 rounded-lg border transition-colors ${
              bookmarkedIds.has(currentQuestion.id)
                ? 'bg-amber-500/10 border-amber-500/30 text-amber-400'
                : 'bg-slate-950 border-slate-800 text-slate-400 hover:text-slate-200'
            }`}
          >
            <Bookmark className="w-4 h-4" />
          </button>
        </div>
      </div>

      {/* Main Question Card */}
      <div className="bg-slate-900/90 border border-slate-800 rounded-2xl p-6 space-y-6">
        {/* Question Text */}
        <div className="text-base font-medium text-slate-100 leading-relaxed">
          <MathText text={currentQuestion.question_text} />
        </div>

        {/* Options Grid */}
        <div className="space-y-3">
          {currentQuestion.options.map((opt, idx) => {
            const letter = String.fromCharCode(65 + idx);
            const isSelected = selectedOptionId === opt.id;
            let optionStyle = 'bg-slate-950 border-slate-800 text-slate-300 hover:border-slate-700';

            if (isAnswered) {
              if (opt.is_correct) {
                optionStyle = 'bg-emerald-500/10 border-emerald-500 text-emerald-300 font-semibold';
              } else if (isSelected && !opt.is_correct) {
                optionStyle = 'bg-rose-500/10 border-rose-500 text-rose-300 font-semibold';
              } else {
                optionStyle = 'bg-slate-950/50 border-slate-800/50 text-slate-500 opacity-60';
              }
            }

            return (
              <button
                key={opt.id}
                disabled={isAnswered}
                onClick={() => handleSelectOption(opt.id)}
                className={`w-full text-left p-4 rounded-xl border transition-all flex items-start gap-3 ${optionStyle}`}
              >
                <span className="w-6 h-6 rounded-lg bg-slate-800 text-slate-300 font-bold text-xs flex items-center justify-center flex-shrink-0">
                  {letter}
                </span>
                <div className="flex-1 pt-0.5 text-sm">
                  <MathText text={opt.option_text} />
                </div>
              </button>
            );
          })}
        </div>

        {/* Immediate Solution Drawer */}
        {isAnswered && (
          <div
            className={`p-5 rounded-xl border ${
              isCorrect
                ? 'bg-emerald-950/30 border-emerald-500/30 text-emerald-200'
                : 'bg-rose-950/30 border-rose-500/30 text-rose-200'
            }`}
          >
            <div className="flex items-center gap-2 mb-3">
              {isCorrect ? (
                <>
                  <CheckCircle2 className="w-5 h-5 text-emerald-400" />
                  <span className="text-sm font-bold text-emerald-400">Correct Answer! (+4 Marks)</span>
                </>
              ) : (
                <>
                  <XCircle className="w-5 h-5 text-rose-400" />
                  <span className="text-sm font-bold text-rose-400">Incorrect (-1 Negative Mark)</span>
                </>
              )}
            </div>

            <div className="space-y-2 text-xs leading-relaxed text-slate-300">
              <p className="font-bold text-slate-200 flex items-center gap-1.5">
                <BookOpen className="w-3.5 h-3.5 text-blue-400" /> Explanation & Concept:
              </p>
              <MathText text={currentQuestion.explanation || ''} />

              <p className="font-bold text-slate-200 mt-3">Step-by-step Solution:</p>
              <MathText text={currentQuestion.solution || ''} />
            </div>
          </div>
        )}

        {/* Navigation Controls */}
        <div className="flex items-center justify-between pt-4 border-t border-slate-800">
          <button
            disabled={currentIndex === 0}
            onClick={() => setCurrentIndex((prev) => Math.max(0, prev - 1))}
            className="px-4 py-2 rounded-xl bg-slate-800 disabled:opacity-40 text-slate-300 text-xs font-semibold flex items-center gap-1.5"
          >
            <ArrowLeft className="w-3.5 h-3.5" /> Previous
          </button>

          <button
            onClick={() => setShowReportModal(true)}
            className="text-xs text-slate-400 hover:text-rose-400 flex items-center gap-1"
          >
            <AlertTriangle className="w-3.5 h-3.5" /> Report Issue
          </button>

          {currentIndex < questions.length - 1 ? (
            <button
              onClick={() => setCurrentIndex((prev) => prev + 1)}
              className="px-5 py-2 rounded-xl bg-blue-600 hover:bg-blue-500 text-white text-xs font-bold flex items-center gap-1.5 shadow-md shadow-blue-600/20"
            >
              Next <ArrowRight className="w-3.5 h-3.5" />
            </button>
          ) : (
            <button
              onClick={() => setIsStarted(false)}
              className="px-5 py-2 rounded-xl bg-emerald-600 text-white text-xs font-bold flex items-center gap-1.5"
            >
              Complete Session
            </button>
          )}
        </div>
      </div>

      {/* Report Modal */}
      {showReportModal && (
        <div className="fixed inset-0 bg-slate-950/80 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl max-w-md w-full p-6 space-y-4">
            <h3 className="text-base font-bold text-white flex items-center gap-2">
              <AlertTriangle className="w-4 h-4 text-rose-400" /> Report Question Error
            </h3>
            <p className="text-xs text-slate-400">Describe any error in question text, options, or explanation.</p>

            <textarea
              value={reportReason}
              onChange={(e) => setReportReason(e.target.value)}
              placeholder="e.g. Typo in equation coefficient, wrong answer key..."
              className="w-full h-24 bg-slate-950 border border-slate-800 rounded-xl p-3 text-xs text-slate-200 focus:outline-none focus:border-blue-500"
            />

            <div className="flex gap-2 justify-end">
              <button
                onClick={() => setShowReportModal(false)}
                className="px-4 py-2 rounded-xl bg-slate-800 text-xs font-medium text-slate-300"
              >
                Cancel
              </button>
              <button
                onClick={() => {
                  alert('Report submitted for admin review!');
                  setShowReportModal(false);
                  setReportReason('');
                }}
                className="px-4 py-2 rounded-xl bg-rose-600 text-xs font-bold text-white"
              >
                Submit Report
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
