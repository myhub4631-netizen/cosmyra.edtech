import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  ArrowLeft,
  ChevronRight,
  FileText,
  Trophy,
  Clock,
  BookOpen,
  ClipboardCheck,
  Zap,
} from 'lucide-react';

interface MobilePaperPredictionProps {
  onBack?: () => void;
  onStartPractice?: () => void;
  onStartTest?: () => void;
  isMobileFrame?: boolean;
}

interface PredictionSet {
  id: number;
  title: string;
  setNumber: string;
  isLatest?: boolean;
  subjects: { name: string; bg: string; text: string }[];
  questions: number;
  marks: number;
  duration: string;
}

export const MobilePaperPrediction: React.FC<MobilePaperPredictionProps> = ({
  onBack,
  onStartPractice,
  onStartTest,
  isMobileFrame = false,
}) => {
  const navigate = useNavigate();
  const [activeFilter, setActiveFilter] = useState<string>('all');

  const handleBack = () => {
    if (onBack) onBack();
    else navigate(-1);
  };

  const handlePractice = () => {
    if (onStartPractice) onStartPractice();
    else navigate('/app/active-practice');
  };

  const handleTest = () => {
    if (onStartTest) onStartTest();
    else navigate('/app/test');
  };

  const predictionSets: PredictionSet[] = [
    {
      id: 1,
      title: 'NEET 2024 Paper Prediction',
      setNumber: 'Set - 1',
      isLatest: true,
      subjects: [
        { name: 'Physics', bg: 'bg-blue-50', text: 'text-blue-600' },
        { name: 'Chemistry', bg: 'bg-cyan-50', text: 'text-cyan-600' },
        { name: 'Biology', bg: 'bg-emerald-50', text: 'text-emerald-600' },
      ],
      questions: 180,
      marks: 540,
      duration: '3:20 Hrs',
    },
    {
      id: 2,
      title: 'NEET 2024 Paper Prediction',
      setNumber: 'Set - 2',
      subjects: [
        { name: 'Physics', bg: 'bg-blue-50', text: 'text-blue-600' },
        { name: 'Chemistry', bg: 'bg-cyan-50', text: 'text-cyan-600' },
        { name: 'Biology', bg: 'bg-emerald-50', text: 'text-emerald-600' },
      ],
      questions: 180,
      marks: 540,
      duration: '3:20 Hrs',
    },
    {
      id: 3,
      title: 'NEET 2024 Paper Prediction',
      setNumber: 'Set - 3',
      subjects: [
        { name: 'Physics', bg: 'bg-blue-50', text: 'text-blue-600' },
        { name: 'Chemistry', bg: 'bg-cyan-50', text: 'text-cyan-600' },
        { name: 'Biology', bg: 'bg-emerald-50', text: 'text-emerald-600' },
      ],
      questions: 180,
      marks: 540,
      duration: '3:20 Hrs',
    },
    {
      id: 4,
      title: 'NEET 2024 Paper Prediction',
      setNumber: 'Set - 4',
      subjects: [
        { name: 'Physics', bg: 'bg-blue-50', text: 'text-blue-600' },
        { name: 'Chemistry', bg: 'bg-cyan-50', text: 'text-cyan-600' },
        { name: 'Biology', bg: 'bg-emerald-50', text: 'text-emerald-600' },
      ],
      questions: 180,
      marks: 540,
      duration: '3:20 Hrs',
    },
  ];

  return (
    <div className={`w-full font-sans bg-[#FDFDFF] text-slate-900 select-none pb-12 ${isMobileFrame ? 'px-0 py-0' : 'max-w-md mx-auto min-h-screen shadow-xl rounded-3xl pb-16'}`}>
      
      {/* ========================================================================= */}
      {/* 1. TOP HEADER BAR */}
      {/* ========================================================================= */}
      <div className="bg-white px-4 py-3 border-b border-slate-100 flex items-center justify-between sticky top-0 z-30 shadow-xs">
        <button
          onClick={handleBack}
          className="p-1 text-slate-800 hover:text-[#5D3EED] transition-colors"
        >
          <ArrowLeft className="w-5 h-5 stroke-[2.5]" />
        </button>

        <h1 className="text-base font-black text-slate-900 text-center flex-1 pr-6">
          Paper Prediction
        </h1>
      </div>

      {/* ========================================================================= */}
      {/* 2. SUBJECT FILTER TABS (HORIZONTAL PILL BAR) */}
      {/* ========================================================================= */}
      <div className="p-4 overflow-x-auto custom-scrollbar flex items-center gap-2.5">
        <button
          onClick={() => setActiveFilter('all')}
          className={`px-5 py-2 rounded-full font-extrabold text-xs transition-all shadow-xs ${
            activeFilter === 'all'
              ? 'bg-[#5D3EED] text-white shadow-indigo-600/30'
              : 'bg-slate-100 text-slate-700 hover:bg-slate-200'
          }`}
        >
          All
        </button>

        <button
          onClick={() => setActiveFilter('physics')}
          className={`px-5 py-2 rounded-full font-extrabold text-xs transition-all ${
            activeFilter === 'physics'
              ? 'bg-[#5D3EED] text-white shadow-indigo-600/30'
              : 'bg-slate-100 text-slate-700 hover:bg-slate-200'
          }`}
        >
          Physics
        </button>

        <button
          onClick={() => setActiveFilter('chemistry')}
          className={`px-5 py-2 rounded-full font-extrabold text-xs transition-all ${
            activeFilter === 'chemistry'
              ? 'bg-[#5D3EED] text-white shadow-indigo-600/30'
              : 'bg-slate-100 text-slate-700 hover:bg-slate-200'
          }`}
        >
          Chemistry
        </button>

        <button
          onClick={() => setActiveFilter('biology')}
          className={`px-5 py-2 rounded-full font-extrabold text-xs transition-all ${
            activeFilter === 'biology'
              ? 'bg-[#5D3EED] text-white shadow-indigo-600/30'
              : 'bg-slate-100 text-slate-700 hover:bg-slate-200'
          }`}
        >
          Biology
        </button>
      </div>

      {/* ========================================================================= */}
      {/* 3. PAPER PREDICTION CARDS STACK */}
      {/* ========================================================================= */}
      <div className="px-4 space-y-4">
        {predictionSets.map((set) => (
          <div
            key={set.id}
            className="bg-white border border-slate-200/80 rounded-3xl p-4 space-y-3.5 shadow-xs hover:border-indigo-300 transition-all relative"
          >
            {/* Top Badge & Header */}
            <div className="flex items-start justify-between">
              <div className="space-y-1">
                {set.isLatest && (
                  <span className="px-2 py-0.5 rounded-md bg-emerald-100 text-emerald-800 text-[9px] font-extrabold tracking-wider uppercase inline-block">
                    LATEST
                  </span>
                )}
                <div className="flex items-center gap-1.5">
                  <h3 className="text-base font-extrabold text-slate-900 leading-tight">
                    {set.title}
                  </h3>
                </div>
                <span className="text-sm font-extrabold text-slate-800 block">
                  {set.setNumber}
                </span>
              </div>

              <ChevronRight className="w-5 h-5 text-slate-400 mt-1" />
            </div>

            {/* Subject Tags Row */}
            <div className="flex items-center gap-1.5 pt-0.5">
              {set.subjects.map((sub, index) => (
                <span
                  key={index}
                  className={`px-2.5 py-1 rounded-lg text-[10px] font-bold ${sub.bg} ${sub.text}`}
                >
                  {sub.name}
                </span>
              ))}
            </div>

            {/* Meta Stats Row */}
            <div className="flex items-center gap-4 text-xs font-bold text-slate-600 pt-1">
              <div className="flex items-center gap-1.5">
                <FileText className="w-3.5 h-3.5 text-slate-400" />
                <span>{set.questions} Questions</span>
              </div>

              <div className="flex items-center gap-1.5">
                <Trophy className="w-3.5 h-3.5 text-slate-400" />
                <span>{set.marks} Marks</span>
              </div>

              <div className="flex items-center gap-1.5">
                <Clock className="w-3.5 h-3.5 text-slate-400" />
                <span>{set.duration}</span>
              </div>
            </div>

            {/* Action Buttons (2-Column Grid) */}
            <div className="grid grid-cols-2 gap-3 pt-1">
              <button
                onClick={handlePractice}
                className="py-2.5 rounded-xl border border-[#5D3EED] text-[#5D3EED] bg-white font-extrabold text-xs hover:bg-purple-50 transition-colors flex items-center justify-center gap-1.5 shadow-xs"
              >
                <BookOpen className="w-4 h-4" />
                <span>Practice</span>
              </button>

              <button
                onClick={handleTest}
                className="py-2.5 rounded-xl bg-[#5D3EED] hover:bg-[#4F46E5] text-white font-extrabold text-xs transition-colors flex items-center justify-center gap-1.5 shadow-sm"
              >
                <ClipboardCheck className="w-4 h-4" />
                <span>Start as Test</span>
              </button>
            </div>

          </div>
        ))}
      </div>

    </div>
  );
};
