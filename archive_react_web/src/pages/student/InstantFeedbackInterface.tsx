import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  ArrowLeft,
  ChevronDown,
  Bookmark,
  Clock,
  Check,
  X,
  Lightbulb,
  ChevronUp,
  ArrowRight,
  Atom,
} from 'lucide-react';

interface InstantFeedbackInterfaceProps {
  onBack?: () => void;
  onViewSolution?: () => void;
  isMobileFrame?: boolean;
}

export const InstantFeedbackInterface: React.FC<InstantFeedbackInterfaceProps> = ({
  onBack,
  onViewSolution,
  isMobileFrame = false,
}) => {
  const navigate = useNavigate();

  const [isBookmarked, setIsBookmarked] = useState<boolean>(false);
  const [showExplanation, setShowExplanation] = useState<boolean>(true);
  const [selectedOption, setSelectedOption] = useState<string>('C');

  const question = {
    num: 12,
    total: 20,
    subject: 'Physics',
    difficulty: 'Medium',
    tag: 'NCERT',
    text: 'A body of mass m is projected with velocity u at an angle θ with the horizontal. The maximum height attained by the body is:',
    options: [
      { id: 'A', formulaHTML: 'u² sin² θ / 2g', numerator: 'u² sin² θ', denominator: '2g' },
      { id: 'B', formulaHTML: 'u² cos² θ / 2g', numerator: 'u² cos² θ', denominator: '2g' },
      { id: 'C', formulaHTML: 'u² sin² θ / g', numerator: 'u² sin² θ', denominator: 'g' },
      { id: 'D', formulaHTML: 'u² cos² θ / g', numerator: 'u² cos² θ', denominator: 'g' },
    ],
    correctOption: 'D',
    userOption: 'C',
  };

  const handleBack = () => {
    if (onBack) onBack();
    else navigate(-1);
  };

  return (
    <div className={`w-full font-sans bg-white text-slate-900 select-none pb-8 ${isMobileFrame ? 'px-0 py-0' : 'max-w-md mx-auto min-h-screen shadow-xl rounded-3xl pb-10'}`}>
      
      {/* ========================================================================= */}
      {/* 1. PURPLE TOP HEADER BAR ("INSTANT FEEDBACK") */}
      {/* ========================================================================= */}
      <div className="bg-[#4F46E5] text-white px-4 py-3.5 flex items-center justify-between sticky top-0 z-30 shadow-md">
        <button
          onClick={handleBack}
          className="p-1 hover:opacity-80 transition-opacity"
        >
          <ArrowLeft className="w-5 h-5 stroke-[2.5]" />
        </button>
        <h1 className="text-sm sm:text-base font-extrabold tracking-wider uppercase text-white">
          INSTANT FEEDBACK
        </h1>
        <div className="w-5" /> {/* Spacer balance */}
      </div>

      {/* ========================================================================= */}
      {/* 2. SUB-HEADER BAR (Subject & Timer) */}
      {/* ========================================================================= */}
      <div className="px-4 py-2.5 bg-white border-b border-slate-100 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <button
            onClick={handleBack}
            className="p-1 text-slate-700 hover:text-slate-900 transition-colors"
          >
            <ArrowLeft className="w-4 h-4 stroke-[2.5]" />
          </button>

          {/* Subject Dropdown Pill */}
          <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-purple-50 border border-purple-100 text-indigo-700 text-xs font-bold">
            <Atom className="w-4 h-4 text-indigo-600" />
            <span>Physics</span>
            <ChevronDown className="w-3.5 h-3.5 text-indigo-600 stroke-[2.5]" />
          </div>
        </div>

        {/* Right Actions: Bookmark & Timer */}
        <div className="flex items-center gap-3">
          <button
            onClick={() => setIsBookmarked(!isBookmarked)}
            className={`p-1.5 rounded-xl transition-colors ${
              isBookmarked ? 'text-indigo-600 bg-indigo-50' : 'text-slate-600 hover:bg-slate-100'
            }`}
          >
            <Bookmark className={`w-4 h-4 ${isBookmarked ? 'fill-indigo-600' : ''}`} />
          </button>

          <div className="flex items-center gap-1 text-xs font-bold text-slate-800">
            <Clock className="w-4 h-4 text-slate-600" />
            <span>00:25:30</span>
          </div>
        </div>
      </div>

      {/* ========================================================================= */}
      {/* 3. MAIN CONTENT BODY */}
      {/* ========================================================================= */}
      <div className="p-4 space-y-4">
        
        {/* Question Meta Row */}
        <div className="flex items-center justify-between">
          <div className="text-sm font-extrabold">
            <span className="text-[#4F46E5]">Question 12</span>
            <span className="text-slate-400 font-semibold"> / 20</span>
          </div>

          <div className="flex items-center gap-2">
            <span className="px-2.5 py-0.5 rounded-lg bg-amber-50 border border-amber-200 text-amber-700 text-[11px] font-bold">
              Medium
            </span>
            <span className="px-2.5 py-0.5 rounded-lg bg-purple-50 border border-purple-200 text-purple-700 text-[11px] font-bold">
              NCERT
            </span>
          </div>
        </div>

        {/* Question Statement */}
        <p className="text-sm font-bold text-slate-900 leading-relaxed">
          A body of mass <span className="font-serif italic font-normal">m</span> is projected with velocity <span className="font-serif italic font-normal">u</span> at an angle <span className="font-serif italic font-normal">θ</span> with the horizontal. The maximum height attained by the body is:
        </p>

        {/* Options List (A, B, C, D) */}
        <div className="space-y-2.5">
          {question.options.map((opt) => {
            const isIncorrectSelected = opt.id === 'C';
            const isCorrectAnswer = opt.id === 'D';

            return (
              <div
                key={opt.id}
                onClick={() => setSelectedOption(opt.id)}
                className={`p-3.5 rounded-2xl border transition-all cursor-pointer flex items-center justify-between ${
                  isCorrectAnswer
                    ? 'bg-[#F0FDF4] border-2 border-emerald-500 shadow-sm'
                    : isIncorrectSelected
                    ? 'bg-[#FFF5F5] border border-rose-300 shadow-sm'
                    : 'bg-[#FFF5F5] border border-rose-100 hover:border-rose-200'
                }`}
              >
                <div className="flex items-center gap-3">
                  <div
                    className={`w-7 h-7 rounded-full border flex items-center justify-center text-xs font-bold ${
                      isCorrectAnswer
                        ? 'border-emerald-500 text-emerald-600 bg-white'
                        : 'border-rose-400 text-rose-500 bg-white'
                    }`}
                  >
                    {opt.id}
                  </div>

                  <span className="text-xs font-extrabold text-slate-900 mr-2">{opt.id}</span>

                  {/* Math Fraction Display */}
                  <div className="inline-flex items-center gap-1 font-serif text-slate-900 text-xs">
                    <div className="flex flex-col items-center leading-none text-center">
                      <span className="border-b border-slate-900 pb-0.5 font-bold">{opt.numerator}</span>
                      <span className="pt-0.5 font-bold">{opt.denominator}</span>
                    </div>
                  </div>
                </div>

                {/* Right Status Badge */}
                {isCorrectAnswer && (
                  <div className="w-5 h-5 rounded-full border-2 border-emerald-500 text-emerald-600 bg-white flex items-center justify-center flex-shrink-0">
                    <Check className="w-3.5 h-3.5 stroke-[3]" />
                  </div>
                )}

                {isIncorrectSelected && (
                  <div className="w-5 h-5 rounded-full border-2 border-rose-500 text-rose-500 bg-white flex items-center justify-center flex-shrink-0">
                    <X className="w-3.5 h-3.5 stroke-[3]" />
                  </div>
                )}
              </div>
            );
          })}
        </div>

        {/* Correct/Incorrect Banner */}
        <div className="bg-[#F0FDF4] border border-emerald-200 rounded-2xl p-3.5 flex items-center justify-between shadow-sm">
          <div className="flex items-center gap-3">
            <div className="w-6 h-6 rounded-full bg-emerald-500 text-white flex items-center justify-center flex-shrink-0">
              <Check className="w-4 h-4 stroke-[3]" />
            </div>
            <div>
              <h4 className="text-xs font-extrabold text-emerald-700">Correct!</h4>
              <p className="text-[11px] text-slate-600 font-semibold mt-0.5">The correct answer is D</p>
            </div>
          </div>

          <button
            onClick={() => {
              if (onViewSolution) onViewSolution();
              else navigate('/student/practice/solution');
            }}
            className="px-3 py-1.5 rounded-xl border border-[#4F46E5] text-[#4F46E5] bg-white font-extrabold text-xs hover:bg-indigo-50 transition-colors cursor-pointer"
          >
            View Solution
          </button>
        </div>

        {/* Explanation Card */}
        <div className="bg-[#F8F7FF] border border-purple-200/80 rounded-2xl p-4 space-y-2">
          <div
            onClick={() => setShowExplanation(!showExplanation)}
            className="flex items-center justify-between cursor-pointer"
          >
            <div className="flex items-center gap-2">
              <Lightbulb className="w-4 h-4 text-indigo-600" />
              <span className="text-xs font-extrabold text-slate-900">Explanation</span>
            </div>
            <ChevronDown
              className={`w-4 h-4 text-indigo-600 transition-transform ${
                showExplanation ? 'rotate-180' : ''
              }`}
            />
          </div>

          {showExplanation && (
            <div className="text-xs text-slate-700 font-medium leading-relaxed space-y-2 pt-1">
              <p>
                The maximum height of a projectile is given by:
              </p>
              
              <div className="flex items-center gap-2 my-1 font-serif text-slate-900 text-sm">
                <span className="font-bold">H = </span>
                <div className="flex flex-col items-center leading-none text-center">
                  <span className="border-b border-slate-900 pb-0.5 font-bold">u² sin² θ</span>
                  <span className="pt-0.5 font-bold">2g</span>
                </div>
                <span className="text-xs font-sans text-slate-600 pl-1">
                  where u is the initial velocity,
                </span>
              </div>

              <p className="text-xs text-slate-600 font-medium leading-relaxed">
                θ is the angle of projection and g is acceleration due to gravity.
              </p>
            </div>
          )}
        </div>

        {/* Bottom Navigation Buttons */}
        <div className="grid grid-cols-2 gap-3 pt-2">
          <button
            onClick={handleBack}
            className="w-full py-3.5 rounded-2xl border-2 border-[#4F46E5] text-[#4F46E5] bg-white font-extrabold text-sm hover:bg-indigo-50 transition-colors flex items-center justify-center gap-2"
          >
            <ArrowLeft className="w-4 h-4 stroke-[2.5]" />
            <span>Previous</span>
          </button>

          <button
            onClick={handleBack}
            className="w-full py-3.5 rounded-2xl bg-[#4F46E5] hover:bg-[#4338CA] text-white font-extrabold text-sm shadow-lg shadow-indigo-600/30 transition-colors flex items-center justify-center gap-2"
          >
            <span>Next Question</span>
            <ArrowRight className="w-4 h-4 stroke-[2.5]" />
          </button>
        </div>

      </div>
    </div>
  );
};
