import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  ArrowLeft,
  ChevronDown,
  Bookmark,
  MoreHorizontal,
  CheckCircle2,
  XCircle,
  MinusCircle,
  AlertTriangle,
  Grid,
  Lightbulb,
  ChevronUp,
  ArrowRight,
  Clock,
  Check,
  AlignLeft,
  Sparkles,
} from 'lucide-react';

interface ActivePracticeInterfaceProps {
  onBack?: () => void;
  isMobileFrame?: boolean;
}

export const ActivePracticeInterface: React.FC<ActivePracticeInterfaceProps> = ({
  onBack,
  isMobileFrame = false,
}) => {
  const navigate = useNavigate();

  // Active State
  const [selectedOption, setSelectedOption] = useState<string>('B');
  const [isBookmarked, setIsBookmarked] = useState<boolean>(false);
  const [showExplanation, setShowExplanation] = useState<boolean>(true);
  const [currentQuestionNum, setCurrentQuestionNum] = useState<number>(10);

  const question = {
    id: 10,
    number: 'Q10.',
    topic: 'Units and Measurements',
    difficulty: 'Easy',
    text: 'The fundamental unit of length in the International System of Units (SI) is:',
    tag: 'Single Correct',
    options: [
      { id: 'A', text: 'Centimetre (cm)' },
      { id: 'B', text: 'Metre (m)' },
      { id: 'C', text: 'Kilometre (km)' },
      { id: 'D', text: 'Millimetre (mm)' },
    ],
    correctOption: 'B',
    explanation:
      'The metre (m) is the fundamental unit of length in the International System of Units (SI). All other units of length are derived from the metre.',
  };

  // Palette status mock: 7 (green correct), 8 (green correct), 9 (red incorrect), 10 (active purple), 11-14 (grey unattempted)
  const questionPalette = [
    { num: 7, status: 'correct' },
    { num: 8, status: 'correct' },
    { num: 9, status: 'incorrect' },
    { num: 10, status: 'active' },
    { num: 11, status: 'unattempted' },
    { num: 12, status: 'unattempted' },
    { num: 13, status: 'unattempted' },
    { num: 14, status: 'unattempted' },
  ];

  const handleBack = () => {
    if (onBack) onBack();
    else navigate(-1);
  };

  return (
    <div className={`w-full font-sans bg-[#FAFAFD] text-slate-900 select-none flex flex-col justify-between min-h-screen ${isMobileFrame ? 'px-0 py-0 pb-16' : 'max-w-md mx-auto min-h-screen shadow-xl rounded-3xl pb-20'}`}>
      
      <div>
        {/* ========================================================================= */}
        {/* 1. TOP HEADER BAR */}
        {/* ========================================================================= */}
        <div className="bg-white px-4 py-3 border-b border-slate-100 flex items-center justify-between sticky top-0 z-30">
          <div className="flex items-center gap-3">
            <button
              onClick={handleBack}
              className="p-1 text-slate-900 hover:text-indigo-600 transition-colors"
            >
              <ArrowLeft className="w-5 h-5 stroke-[2.5]" />
            </button>
            <div>
              <button className="flex items-center gap-1 font-extrabold text-slate-900 text-base leading-tight">
                <span>Physics</span>
                <ChevronDown className="w-4 h-4 text-slate-500 stroke-[2.5]" />
              </button>
              <p className="text-[11px] text-slate-400 font-semibold mt-0.5">NEET UG 2026 • NTA</p>
            </div>
          </div>

          <div className="flex items-center gap-4">
            <button
              onClick={() => setIsBookmarked(!isBookmarked)}
              className={`flex flex-col items-center gap-0.5 text-[10px] font-bold ${
                isBookmarked ? 'text-[#4F46E5]' : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              <Bookmark className={`w-5 h-5 ${isBookmarked ? 'fill-[#4F46E5]' : ''}`} />
              <span>Bookmark</span>
            </button>

            <button className="flex flex-col items-center gap-0.5 text-[10px] font-bold text-slate-600 hover:text-slate-900">
              <div className="w-6 h-6 rounded-full border border-slate-300 flex items-center justify-center">
                <MoreHorizontal className="w-4 h-4 text-slate-600" />
              </div>
              <span>More</span>
            </button>
          </div>
        </div>

        {/* ========================================================================= */}
        {/* 2. PROGRESS STATS STRIP */}
        {/* ========================================================================= */}
        <div className="bg-white px-4 py-2.5 border-b border-slate-100 flex items-center justify-between text-xs font-semibold">
          {/* Donut percentage ring */}
          <div className="flex items-center gap-2">
            <div className="relative w-10 h-10 flex items-center justify-center">
              <svg viewBox="0 0 36 36" className="w-full h-full transform -rotate-90">
                <path
                  d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                  fill="none"
                  stroke="#EEF2FF"
                  strokeWidth="4"
                />
                <path
                  d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                  fill="none"
                  stroke="#4F46E5"
                  strokeWidth="4"
                  strokeDasharray="12, 100"
                />
              </svg>
              <span className="absolute text-[10px] font-extrabold text-slate-900">12%</span>
            </div>
            <div className="leading-tight">
              <span className="text-[10px] text-slate-400 block font-medium">You have answered</span>
              <span className="text-xs font-extrabold text-[#4F46E5] block">6 / 20</span>
            </div>
          </div>

          <div className="h-6 w-px bg-slate-200" />

          {/* Correct */}
          <div className="flex items-center gap-1.5">
            <div className="w-5 h-5 rounded-full bg-emerald-500 text-white flex items-center justify-center">
              <Check className="w-3.5 h-3.5 stroke-[3]" />
            </div>
            <div className="leading-tight">
              <span className="text-xs font-extrabold text-emerald-600 block">5</span>
              <span className="text-[9px] text-slate-400 font-semibold block">Correct</span>
            </div>
          </div>

          {/* Incorrect */}
          <div className="flex items-center gap-1.5">
            <div className="w-5 h-5 rounded-full bg-rose-500 text-white flex items-center justify-center">
              <span className="text-xs font-bold leading-none">✕</span>
            </div>
            <div className="leading-tight">
              <span className="text-xs font-extrabold text-rose-600 block">1</span>
              <span className="text-[9px] text-slate-400 font-semibold block">Incorrect</span>
            </div>
          </div>

          {/* Skipped */}
          <div className="flex items-center gap-1.5">
            <div className="w-5 h-5 rounded-full bg-slate-400 text-white flex items-center justify-center">
              <span className="text-xs font-bold leading-none">−</span>
            </div>
            <div className="leading-tight">
              <span className="text-xs font-extrabold text-slate-600 block">0</span>
              <span className="text-[9px] text-slate-400 font-semibold block">Skipped</span>
            </div>
          </div>
        </div>

        {/* ========================================================================= */}
        {/* 3. TOPIC HEADER & QUESTION BUBBLE PALETTE */}
        {/* ========================================================================= */}
        <div className="bg-white px-4 py-3 space-y-3">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <h2 className="text-xs font-extrabold text-slate-900">{question.topic}</h2>
              <span className="px-2 py-0.5 rounded-lg bg-indigo-50 border border-indigo-200 text-[#4F46E5] text-[10px] font-bold">
                {question.difficulty}
              </span>
            </div>
            <button className="flex items-center gap-1 text-[11px] font-bold text-slate-500 hover:text-slate-800">
              <AlertTriangle className="w-3.5 h-3.5 text-slate-400" />
              <span>Report</span>
            </button>
          </div>

          {/* Question Bubbles Palette Row */}
          <div className="flex items-center justify-between gap-1 overflow-x-auto custom-scrollbar pb-1">
            <div className="flex items-center gap-2">
              {questionPalette.map((q) => {
                if (q.status === 'active') {
                  return (
                    <button
                      key={q.num}
                      onClick={() => setCurrentQuestionNum(q.num)}
                      className="w-8 h-8 rounded-full bg-[#4F46E5] text-white font-extrabold text-xs flex items-center justify-center shadow-md shadow-indigo-600/30 flex-shrink-0"
                    >
                      {q.num}
                    </button>
                  );
                }
                if (q.status === 'correct') {
                  return (
                    <button
                      key={q.num}
                      onClick={() => setCurrentQuestionNum(q.num)}
                      className="w-8 h-8 rounded-full border-2 border-emerald-500 bg-white text-emerald-600 font-bold text-xs flex items-center justify-center flex-shrink-0"
                    >
                      {q.num}
                    </button>
                  );
                }
                if (q.status === 'incorrect') {
                  return (
                    <button
                      key={q.num}
                      onClick={() => setCurrentQuestionNum(q.num)}
                      className="w-8 h-8 rounded-full border-2 border-rose-500 bg-white text-rose-600 font-bold text-xs flex items-center justify-center flex-shrink-0"
                    >
                      {q.num}
                    </button>
                  );
                }
                return (
                  <button
                    key={q.num}
                    onClick={() => setCurrentQuestionNum(q.num)}
                    className="w-8 h-8 rounded-full border border-slate-200 bg-white text-slate-600 font-bold text-xs flex items-center justify-center flex-shrink-0 hover:border-slate-400"
                  >
                    {q.num}
                  </button>
                );
              })}
            </div>

            {/* Grid Palette Launcher Button */}
            <button className="w-8 h-8 rounded-xl bg-slate-100 text-slate-700 flex items-center justify-center flex-shrink-0 ml-1">
              <Grid className="w-4 h-4" />
            </button>
          </div>
        </div>

        {/* ========================================================================= */}
        {/* 4. MAIN QUESTION CARD */}
        {/* ========================================================================= */}
        <div className="p-4 space-y-4">
          <div className="bg-white rounded-3xl border border-slate-200 p-5 space-y-4 shadow-sm">
            {/* Question Number & Text */}
            <div className="space-y-2">
              <h3 className="text-sm font-extrabold text-[#4F46E5]">{question.number}</h3>
              <p className="text-sm font-extrabold text-slate-900 leading-relaxed">
                {question.text}
              </p>
              <div className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg bg-indigo-50 text-[#4F46E5] text-[10px] font-extrabold">
                <AlignLeft className="w-3 h-3" />
                <span>{question.tag}</span>
              </div>
            </div>

            {/* Options List A, B, C, D */}
            <div className="space-y-2.5">
              {question.options.map((opt) => {
                const isSelected = selectedOption === opt.id;

                return (
                  <div
                    key={opt.id}
                    onClick={() => setSelectedOption(opt.id)}
                    className={`p-3.5 rounded-2xl border transition-all cursor-pointer flex items-center justify-between gap-3 ${
                      isSelected
                        ? 'border-[#4F46E5] bg-[#F5F3FF] ring-1 ring-[#4F46E5]'
                        : 'border-slate-200 bg-white hover:border-slate-300'
                    }`}
                  >
                    <div className="flex items-center gap-3">
                      <div
                        className={`w-7 h-7 rounded-full border flex items-center justify-center text-xs font-bold ${
                          isSelected
                            ? 'border-[#4F46E5] text-[#4F46E5] bg-white'
                            : 'border-indigo-300 text-indigo-600 bg-white'
                        }`}
                      >
                        {opt.id}
                      </div>
                      <span className="text-xs font-bold text-slate-900">{opt.text}</span>
                    </div>

                    {isSelected && (
                      <div className="w-5 h-5 rounded-full bg-[#4F46E5] text-white flex items-center justify-center flex-shrink-0">
                        <Check className="w-3.5 h-3.5 stroke-[3]" />
                      </div>
                    )}
                  </div>
                );
              })}
            </div>

            {/* Collapsible Explanation Box */}
            <div className="bg-[#F8F7FF] border border-purple-200/80 rounded-2xl p-4 space-y-2">
              <div
                onClick={() => setShowExplanation(!showExplanation)}
                className="flex items-center justify-between cursor-pointer"
              >
                <div className="flex items-center gap-2 text-[#4F46E5]">
                  <Lightbulb className="w-4 h-4 text-[#4F46E5]" />
                  <span className="text-xs font-extrabold text-slate-900">Explanation</span>
                </div>
                <ChevronUp
                  className={`w-4 h-4 text-[#4F46E5] transition-transform ${
                    showExplanation ? '' : 'rotate-180'
                  }`}
                />
              </div>

              {showExplanation && (
                <p className="text-xs text-slate-600 font-medium leading-relaxed pt-1">
                  {question.explanation}
                </p>
              )}
            </div>

            {/* Question Action Buttons (Previous, Bookmark, Next) */}
            <div className="grid grid-cols-3 gap-2 pt-2">
              <button
                onClick={() => setCurrentQuestionNum(Math.max(1, currentQuestionNum - 1))}
                className="py-3 px-2 rounded-2xl border border-[#4F46E5] text-[#4F46E5] font-extrabold text-xs flex items-center justify-center gap-1 hover:bg-indigo-50 transition-colors"
              >
                <ArrowLeft className="w-4 h-4 stroke-[2.5]" />
                <span>Previous</span>
              </button>

              <button
                onClick={() => setIsBookmarked(!isBookmarked)}
                className="py-3 px-2 rounded-2xl border border-slate-200 bg-white text-slate-700 font-extrabold text-xs flex items-center justify-center gap-1.5 hover:bg-slate-50 transition-colors"
              >
                <Bookmark className={`w-4 h-4 ${isBookmarked ? 'fill-[#4F46E5] text-[#4F46E5]' : 'text-slate-600'}`} />
                <span>Bookmark</span>
              </button>

              <button
                onClick={() => setCurrentQuestionNum(currentQuestionNum + 1)}
                className="py-3 px-2 rounded-2xl bg-[#4F46E5] hover:bg-[#4338CA] text-white font-extrabold text-xs flex items-center justify-center gap-1 shadow-md shadow-indigo-600/25 transition-all"
              >
                <span>Next</span>
                <ArrowRight className="w-4 h-4 stroke-[2.5]" />
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* ========================================================================= */}
      {/* 5. FIXED BOTTOM ACTION BAR (Timer, Review & Finish, Submit Test) */}
      {/* ========================================================================= */}
      <div className="bg-white border-t border-slate-200 px-4 py-3 flex items-center justify-between fixed bottom-0 left-0 right-0 z-40 max-w-md mx-auto shadow-2xl">
        {/* Timer Counter */}
        <div className="flex items-center gap-2">
          <Clock className="w-6 h-6 text-slate-900 stroke-[2]" />
          <div className="leading-none">
            <span className="text-[10px] text-slate-400 font-bold block">Time Left</span>
            <span className="text-xs font-black text-slate-900 block mt-0.5">01:20:45</span>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="flex items-center gap-2">
          <button
            onClick={() => navigate('/student/test')}
            className="px-3.5 py-2.5 rounded-2xl border-2 border-indigo-300 text-[#4F46E5] font-extrabold text-xs hover:bg-indigo-50 transition-colors"
          >
            Review & Finish
          </button>

          <button
            onClick={() => navigate('/student/test')}
            className="px-4 py-2.5 rounded-2xl bg-[#4F46E5] hover:bg-[#4338CA] text-white font-extrabold text-xs shadow-md shadow-indigo-600/30 transition-colors"
          >
            Submit Test
          </button>
        </div>
      </div>
    </div>
  );
};
