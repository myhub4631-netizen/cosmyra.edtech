import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  ArrowLeft,
  Lightbulb,
  BookCheck,
  Bot,
  Bookmark,
  ArrowRight,
  Sparkles,
} from 'lucide-react';

interface DetailedSolutionViewProps {
  onBack?: () => void;
  isMobileFrame?: boolean;
}

export const DetailedSolutionView: React.FC<DetailedSolutionViewProps> = ({
  onBack,
  isMobileFrame = false,
}) => {
  const navigate = useNavigate();
  const [isBookmarked, setIsBookmarked] = useState<boolean>(false);

  const handleBack = () => {
    if (onBack) onBack();
    else navigate(-1);
  };

  return (
    <div className={`w-full font-sans bg-white text-slate-900 select-none pb-8 ${isMobileFrame ? 'px-0 py-0' : 'max-w-md mx-auto min-h-screen shadow-xl rounded-3xl pb-10'}`}>
      
      {/* ========================================================================= */}
      {/* 1. PURPLE TOP HEADER BAR ("Solution") */}
      {/* ========================================================================= */}
      <div className="bg-[#4F46E5] text-white px-4 py-3.5 flex items-center justify-between sticky top-0 z-30 shadow-md">
        <button
          onClick={handleBack}
          className="p-1 hover:opacity-80 transition-opacity"
        >
          <ArrowLeft className="w-5 h-5 stroke-[2.5]" />
        </button>
        <h1 className="text-base sm:text-lg font-extrabold tracking-tight text-white">
          Solution
        </h1>
        <div className="w-5" /> {/* Spacer balance */}
      </div>

      {/* ========================================================================= */}
      {/* 2. MAIN CONTENT BODY */}
      {/* ========================================================================= */}
      <div className="p-4 space-y-4">

        {/* Question Summary & Comparison Card */}
        <div className="bg-white rounded-3xl border border-slate-200 p-4 space-y-3 shadow-sm">
          {/* Question Meta Row */}
          <div className="flex items-center justify-between">
            <div className="text-xs font-extrabold">
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
          <p className="text-xs sm:text-sm font-bold text-slate-900 leading-relaxed">
            A body of mass <span className="font-serif italic font-normal">m</span> is projected with velocity <span className="font-serif italic font-normal">u</span> at an angle <span className="font-serif italic font-normal">θ</span> with the horizontal. The maximum height attained by the body is:
          </p>

          {/* Answer Comparison Row (Your Answer vs Correct Answer) */}
          <div className="grid grid-cols-2 gap-3 pt-1">
            {/* Your Answer */}
            <div className="space-y-1">
              <span className="text-[11px] text-slate-500 font-semibold block">Your Answer:</span>
              <div className="flex items-center gap-2 p-2 rounded-xl bg-rose-50 border border-rose-200">
                <div className="w-5 h-5 rounded-full border border-rose-400 text-rose-500 font-bold text-[11px] flex items-center justify-center bg-white flex-shrink-0">
                  C
                </div>
                <div className="font-serif text-slate-900 text-xs flex flex-col items-center leading-none">
                  <span className="border-b border-slate-900 pb-0.5 font-bold">u² sin² θ</span>
                  <span className="pt-0.5 font-bold">g</span>
                </div>
              </div>
            </div>

            {/* Correct Answer */}
            <div className="space-y-1">
              <span className="text-[11px] text-slate-500 font-semibold block">Correct Answer:</span>
              <div className="flex items-center gap-2 p-2 rounded-xl bg-emerald-50 border border-emerald-200">
                <div className="w-5 h-5 rounded-full border border-emerald-500 text-emerald-600 font-bold text-[11px] flex items-center justify-center bg-white flex-shrink-0">
                  D
                </div>
                <div className="font-serif text-slate-900 text-xs flex flex-col items-center leading-none">
                  <span className="border-b border-slate-900 pb-0.5 font-bold">u² cos² θ</span>
                  <span className="pt-0.5 font-bold">g</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Detailed Solution Container */}
        <div className="bg-white rounded-3xl border border-slate-200 p-4 space-y-4 shadow-sm">
          <div className="flex items-center gap-2 text-[#4F46E5]">
            <Lightbulb className="w-5 h-5 fill-[#4F46E5] text-[#4F46E5]" />
            <h3 className="text-sm font-extrabold text-slate-900">Detailed Solution</h3>
          </div>

          <p className="text-xs text-slate-700 font-medium leading-relaxed">
            Let the body be projected with velocity <span className="font-serif italic">u</span> at an angle <span className="font-serif italic">θ</span> with the horizontal.
          </p>

          {/* Two-Column Step Derivation + Vector Diagram */}
          <div className="flex flex-col md:flex-row items-start gap-4">
            
            {/* Left Steps */}
            <div className="space-y-3 flex-1 text-xs text-slate-800">
              
              {/* Step 1 */}
              <div>
                <h4 className="font-extrabold text-slate-900 flex items-center gap-1.5 text-xs">
                  <span className="text-[#4F46E5] font-bold">•</span> Resolve the velocity:
                </h4>
                <div className="pl-3.5 space-y-0.5 font-serif text-slate-800 text-[11px] mt-0.5">
                  <p>Vertical component, <span className="font-semibold">u<sub>y</sub> = u sin θ</span></p>
                  <p>Horizontal component, <span className="font-semibold">u<sub>x</sub> = u cos θ</span></p>
                </div>
              </div>

              {/* Step 2 */}
              <div>
                <h4 className="font-extrabold text-slate-900 flex items-center gap-1.5 text-xs">
                  <span className="text-[#4F46E5] font-bold">•</span> At maximum height:
                </h4>
                <div className="pl-3.5 space-y-0.5 font-serif text-slate-800 text-[11px] mt-0.5">
                  <p>Final vertical velocity, <span className="font-semibold">v<sub>y</sub> = 0</span></p>
                  <p>Acceleration due to gravity, <span className="font-semibold">a = −g</span></p>
                </div>
              </div>

              {/* Step 3 */}
              <div>
                <h4 className="font-extrabold text-slate-900 flex items-center gap-1.5 text-xs">
                  <span className="text-[#4F46E5] font-bold">•</span> Use the kinematic equation:
                </h4>
                <div className="pl-3.5 space-y-0.5 mt-0.5">
                  <p className="font-serif font-bold text-xs">v<sub>y</sub><sup>2</sup> = u<sub>y</sub><sup>2</sup> + 2as</p>
                  <p className="text-[10px] text-slate-500 font-sans">(where s is the maximum height H)</p>
                </div>
              </div>

              {/* Step 4 */}
              <div>
                <h4 className="font-extrabold text-slate-900 flex items-center gap-1.5 text-xs">
                  <span className="text-[#4F46E5] font-bold">•</span> Substitute the values:
                </h4>
                <div className="pl-3.5 font-serif font-bold text-xs mt-0.5">
                  0 = (u sin θ)<sup>2</sup> + 2(−g)H
                </div>
              </div>

              {/* Step 5 */}
              <div>
                <h4 className="font-extrabold text-slate-900 flex items-center gap-1.5 text-xs">
                  <span className="text-[#4F46E5] font-bold">•</span> Solve for H:
                </h4>
                <div className="pl-3.5 space-y-2 mt-0.5">
                  <p className="font-serif font-bold text-xs">2gH = u<sup>2</sup> sin<sup>2</sup> θ</p>
                  
                  {/* Highlighted Result Box */}
                  <div className="p-3 rounded-2xl bg-[#F5F3FF] border border-purple-200 text-center font-serif text-xs inline-flex items-center justify-center gap-2">
                    <span className="font-bold text-sm">H =</span>
                    <div className="flex flex-col items-center leading-none">
                      <span className="border-b border-slate-900 pb-0.5 font-bold">u² sin² θ</span>
                      <span className="pt-0.5 font-bold">2g</span>
                    </div>
                  </div>
                </div>
              </div>

            </div>

            {/* Right Projectile Vector Diagram SVG */}
            <div className="w-full md:w-44 bg-[#F8FAFC] border border-slate-200 rounded-2xl p-3 flex flex-col items-center justify-center flex-shrink-0">
              <svg viewBox="0 0 200 150" className="w-full h-auto max-w-[180px]">
                {/* Axes */}
                <line x1="20" y1="130" x2="190" y2="130" stroke="#64748B" strokeWidth="1.5" markerEnd="url(#arrow)" />
                <line x1="20" y1="130" x2="20" y2="10" stroke="#64748B" strokeWidth="1.5" markerEnd="url(#arrow)" />

                {/* Arrow markers */}
                <defs>
                  <marker id="arrow" viewBox="0 0 10 10" refX="5" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
                    <path d="M 0 0 L 10 5 L 0 10 z" fill="#64748B" />
                  </marker>
                  <marker id="arrowPurple" viewBox="0 0 10 10" refX="5" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
                    <path d="M 0 0 L 10 5 L 0 10 z" fill="#4F46E5" />
                  </marker>
                </defs>

                {/* Trajectory Parabola Curve */}
                <path d="M 20 130 Q 90 20 160 130" fill="none" stroke="#4F46E5" strokeWidth="2" />

                {/* Highest Point Marker */}
                <line x1="90" y1="42" x2="90" y2="130" stroke="#64748B" strokeWidth="1" strokeDasharray="3 3" />
                <text x="95" y="80" fontSize="10" fontWeight="bold" fill="#334155">H</text>
                <text x="80" y="25" fontSize="8" fontWeight="bold" fill="#334155">v<tspan dy="2" fontSize="6">y</tspan><tspan dy="-2"> = 0</tspan></text>
                <text x="65" y="35" fontSize="7" fill="#64748B">(at highest point)</text>

                {/* Initial Velocity Vector u */}
                <line x1="20" y1="130" x2="55" y2="75" stroke="#334155" strokeWidth="1.5" markerEnd="url(#arrow)" />
                <text x="45" y="70" fontSize="10" fontWeight="bold" fontStyle="italic" fill="#334155">u</text>

                {/* Components */}
                <line x1="20" y1="130" x2="20" y2="85" stroke="#4F46E5" strokeWidth="1.5" markerEnd="url(#arrowPurple)" />
                <text x="2" y="98" fontSize="8" fontWeight="bold" fill="#4F46E5">u<tspan dy="2" fontSize="6">y</tspan><tspan dy="-2"> =</tspan></text>
                <text x="2" y="108" fontSize="8" fontStyle="italic" fill="#4F46E5">u sin θ</text>

                <line x1="20" y1="130" x2="65" y2="130" stroke="#4F46E5" strokeWidth="1.5" markerEnd="url(#arrowPurple)" />
                <text x="35" y="145" fontSize="8" fontStyle="italic" fill="#4F46E5">u<tspan dy="2" fontSize="6">x</tspan><tspan dy="-2"> = u cos θ</tspan></text>

                {/* Angle Theta arc */}
                <path d="M 35 130 A 15 15 0 0 0 30 115" fill="none" stroke="#334155" strokeWidth="1" />
                <text x="36" y="122" fontSize="9" fontStyle="italic" fill="#334155">θ</text>

                {/* Point Labels */}
                <text x="12" y="142" fontSize="9" fontWeight="bold" fontStyle="italic" fill="#334155">O</text>
                <text x="86" y="142" fontSize="9" fontWeight="bold" fontStyle="italic" fill="#334155">P</text>
                <text x="185" y="142" fontSize="9" fontStyle="italic" fill="#334155">x</text>
                <text x="10" y="15" fontSize="9" fontStyle="italic" fill="#334155">y</text>
              </svg>
            </div>

          </div>
        </div>

        {/* Key Takeaway Card */}
        <div className="bg-[#F0FDF4] border border-emerald-300 rounded-2xl p-3.5 flex items-start gap-3 shadow-sm">
          <div className="p-1 rounded-lg bg-emerald-100 text-emerald-700 flex-shrink-0 mt-0.5">
            <BookCheck className="w-4 h-4" />
          </div>
          <div>
            <h4 className="text-xs font-extrabold text-emerald-800">Key Takeaway</h4>
            <p className="text-xs text-slate-700 font-medium leading-relaxed mt-0.5">
              Maximum height depends on the vertical component of the initial velocity (<span className="font-serif italic">u sin θ</span>) and is given by <span className="font-serif font-bold">H = u² sin² θ / 2g</span>.
            </p>
          </div>
        </div>

        {/* Ask AI Tutor Banner */}
        <div className="bg-[#F5F3FF] border border-purple-200 p-3.5 rounded-2xl flex items-center justify-between shadow-sm">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-2xl bg-purple-100 text-[#4F46E5] flex items-center justify-center flex-shrink-0">
              <Bot className="w-5 h-5" />
            </div>
            <div>
              <h4 className="text-xs font-extrabold text-slate-900">Still have doubts?</h4>
              <p className="text-[11px] text-[#4F46E5] font-semibold">Ask our AI Tutor for a better understanding</p>
            </div>
          </div>

          <button className="px-3 py-1.5 rounded-xl border border-[#4F46E5] text-[#4F46E5] bg-white font-extrabold text-xs flex items-center gap-1.5 hover:bg-indigo-50 transition-colors shadow-sm">
            <Bot className="w-3.5 h-3.5" />
            <span>Ask AI Tutor</span>
          </button>
        </div>

        {/* Bottom Navigation Action Buttons */}
        <div className="grid grid-cols-3 gap-2 pt-2">
          <button
            onClick={handleBack}
            className="py-3 px-2 rounded-2xl border-2 border-[#4F46E5] text-[#4F46E5] bg-white font-extrabold text-xs flex items-center justify-center gap-1 hover:bg-indigo-50 transition-colors"
          >
            <ArrowLeft className="w-4 h-4 stroke-[2.5]" />
            <span className="text-[11px]">Previous Question</span>
          </button>

          <button
            onClick={() => setIsBookmarked(!isBookmarked)}
            className="py-3 px-2 rounded-2xl border border-slate-200 bg-white text-slate-700 font-extrabold text-xs flex items-center justify-center gap-1.5 hover:bg-slate-50 transition-colors"
          >
            <Bookmark className={`w-4 h-4 ${isBookmarked ? 'fill-[#4F46E5] text-[#4F46E5]' : 'text-slate-600'}`} />
            <span className="text-[11px]">Bookmark</span>
          </button>

          <button
            onClick={handleBack}
            className="py-3 px-2 rounded-2xl bg-[#4F46E5] hover:bg-[#4338CA] text-white font-extrabold text-xs flex items-center justify-center gap-1 shadow-md shadow-indigo-600/25 transition-all"
          >
            <span className="text-[11px]">Next Question</span>
            <ArrowRight className="w-4 h-4 stroke-[2.5]" />
          </button>
        </div>

      </div>
    </div>
  );
};
