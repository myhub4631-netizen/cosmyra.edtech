import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Menu,
  Calendar,
  Filter,
  ArrowLeft,
  TrendingUp,
  ClipboardList,
  Target,
  Clock,
  Atom,
  FlaskConical,
  Dna,
  Leaf,
  PawPrint,
  CheckCircle2,
  XCircle,
  HelpCircle,
  ChevronDown,
  ChevronRight,
  Zap,
  Award,
  Timer,
  Check,
  Share2,
} from 'lucide-react';

interface MobileAnalyticsScreenProps {
  onOpenDrawer?: () => void;
  onBack?: () => void;
  isMobileFrame?: boolean;
}

export const MobileAnalyticsScreen: React.FC<MobileAnalyticsScreenProps> = ({
  onOpenDrawer,
  onBack,
  isMobileFrame = false,
}) => {
  const navigate = useNavigate();

  // Active Sub-Navigation Tab: 'overview' | 'tests' | 'subjects' | 'topics'
  const [activeSubTab, setActiveSubTab] = useState<string>('overview');

  // Active View Mode: 'upper' (Overall & Charts) | 'lower' (Difficulty, Question Types, Highlights)
  const [activeViewSection, setActiveViewSection] = useState<'all' | 'upper' | 'lower'>('all');

  // Filters State
  const [selectedClass, setSelectedClass] = useState<string>('Class 12');
  const [selectedExam, setSelectedExam] = useState<string>('NEET');
  const [selectedSubject, setSelectedSubject] = useState<string>('All Subjects');
  const [selectedDays, setSelectedDays] = useState<string>('30 Days');

  const questionTypes = [
    { name: 'MCQ', percentage: 76 },
    { name: 'Assertion Reason', percentage: 68 },
    { name: 'Match the Following', percentage: 72 },
    { name: 'Matrix Match', percentage: 65 },
    { name: 'Integer Type', percentage: 58 },
  ];

  const recentTestHighlights = [
    {
      id: 8,
      title: 'NEET 2024 Mock Test - 8',
      date: '18 May 2024',
      type: 'Full Test',
      score: '680/720',
      percentage: '94.44%',
      iconBg: 'bg-emerald-50',
      iconColor: 'text-emerald-600',
      scoreColor: 'text-emerald-600',
    },
    {
      id: 7,
      title: 'NEET 2024 Mock Test - 7',
      date: '12 May 2024',
      type: 'Full Test',
      score: '612/720',
      percentage: '85.00%',
      iconBg: 'bg-orange-50',
      iconColor: 'text-orange-600',
      scoreColor: 'text-emerald-600',
    },
    {
      id: 6,
      title: 'NEET 2024 Mock Test - 6',
      date: '05 May 2024',
      type: 'Full Test',
      score: '548/720',
      percentage: '76.11%',
      iconBg: 'bg-purple-50',
      iconColor: 'text-[#5D3EED]',
      scoreColor: 'text-[#5D3EED]',
    },
    {
      id: 5,
      title: 'NEET 2024 Mock Test - 5',
      date: '28 Apr 2024',
      type: 'Full Test',
      score: '492/720',
      percentage: '68.33%',
      iconBg: 'bg-blue-50',
      iconColor: 'text-blue-600',
      scoreColor: 'text-blue-600',
    },
  ];

  return (
    <div className={`w-full font-sans bg-[#FDFDFF] text-slate-900 select-none pb-16 ${isMobileFrame ? 'px-0 py-0' : 'max-w-md mx-auto min-h-screen shadow-xl rounded-3xl'}`}>
      
      {/* ========================================================================= */}
      {/* 1. TOP HEADER BAR */}
      {/* ========================================================================= */}
      <div className="bg-white px-4 py-3 border-b border-slate-100 flex items-center justify-between sticky top-0 z-30 shadow-xs">
        <button
          onClick={onOpenDrawer || onBack}
          className="p-1 text-slate-800 hover:text-[#5D3EED] transition-colors"
        >
          {onBack ? <ArrowLeft className="w-5 h-5 stroke-[2.5]" /> : <Menu className="w-5 h-5 stroke-[2.5]" />}
        </button>

        <h1 className="text-base font-black text-slate-900 text-center flex-1">
          Analytics
        </h1>

        <button className="p-1 text-slate-800 hover:text-[#5D3EED] transition-colors">
          <Filter className="w-5 h-5 stroke-[2]" />
        </button>
      </div>

      {/* ========================================================================= */}
      {/* 2. SUB-NAVIGATION TABS (Overview, Tests, Subjects, Topics) */}
      {/* ========================================================================= */}
      <div className="bg-white px-4 pt-2 border-b border-slate-100">
        <div className="bg-slate-100/70 p-1 rounded-2xl flex items-center justify-between text-xs font-bold text-slate-600">
          <button
            onClick={() => setActiveSubTab('overview')}
            className={`flex-1 py-2 rounded-xl text-center transition-all ${
              activeSubTab === 'overview'
                ? 'bg-white text-[#5D3EED] font-black shadow-xs'
                : 'hover:text-slate-900'
            }`}
          >
            Overview
          </button>

          <button
            onClick={() => setActiveSubTab('tests')}
            className={`flex-1 py-2 rounded-xl text-center transition-all ${
              activeSubTab === 'tests'
                ? 'bg-white text-[#5D3EED] font-black shadow-xs'
                : 'hover:text-slate-900'
            }`}
          >
            Tests
          </button>

          <button
            onClick={() => setActiveSubTab('subjects')}
            className={`flex-1 py-2 rounded-xl text-center transition-all ${
              activeSubTab === 'subjects'
                ? 'bg-white text-[#5D3EED] font-black shadow-xs'
                : 'hover:text-slate-900'
            }`}
          >
            Subjects
          </button>

          <button
            onClick={() => setActiveSubTab('topics')}
            className={`flex-1 py-2 rounded-xl text-center transition-all ${
              activeSubTab === 'topics'
                ? 'bg-white text-[#5D3EED] font-black shadow-xs'
                : 'hover:text-slate-900'
            }`}
          >
            Topics
          </button>
        </div>
      </div>

      {/* ========================================================================= */}
      {/* 3. 4 DROPDOWN FILTERS CONTROL ROW */}
      {/* ========================================================================= */}
      <div className="px-4 pt-3 flex items-center gap-2 overflow-x-auto custom-scrollbar">
        <div className="flex items-center gap-1 bg-white border border-slate-200/80 rounded-xl px-3 py-1.5 text-xs font-bold text-slate-700 flex-shrink-0 cursor-pointer shadow-xs">
          <span>{selectedClass}</span>
          <ChevronDown className="w-3.5 h-3.5 text-slate-400" />
        </div>

        <div className="flex items-center gap-1 bg-white border border-slate-200/80 rounded-xl px-3 py-1.5 text-xs font-bold text-slate-700 flex-shrink-0 cursor-pointer shadow-xs">
          <span>{selectedExam}</span>
          <ChevronDown className="w-3.5 h-3.5 text-slate-400" />
        </div>

        <div className="flex items-center gap-1 bg-white border border-slate-200/80 rounded-xl px-3 py-1.5 text-xs font-bold text-slate-700 flex-shrink-0 cursor-pointer shadow-xs">
          <span>{selectedSubject}</span>
          <ChevronDown className="w-3.5 h-3.5 text-slate-400" />
        </div>

        <div className="flex items-center gap-1 bg-white border border-slate-200/80 rounded-xl px-3 py-1.5 text-xs font-bold text-slate-700 flex-shrink-0 cursor-pointer shadow-xs">
          <span>{selectedDays}</span>
          <ChevronDown className="w-3.5 h-3.5 text-slate-400" />
        </div>
      </div>

      <div className="p-4 space-y-4">
        
        {/* ========================================================================= */}
        {/* UPPER PAGE SECTION: HERO PERFORMANCE & SCORE OVER TIME */}
        {/* ========================================================================= */}
        {(activeViewSection === 'all' || activeViewSection === 'upper') && (
          <>
            {/* HERO PERFORMANCE CARD */}
            <div className="bg-gradient-to-r from-[#2E1065] via-[#3B0764] to-[#4C1D95] text-white p-5 rounded-3xl relative overflow-hidden shadow-xl shadow-indigo-950/30 space-y-4">
              <div className="flex items-start justify-between">
                <div>
                  <h2 className="text-base font-extrabold text-white">Your Overall Performance</h2>
                  <p className="text-xs text-indigo-200 font-medium mt-0.5">Keep practicing to achieve your goal!</p>
                </div>

                <div className="bg-white/10 border border-white/20 backdrop-blur-xs text-indigo-100 text-[10px] font-extrabold px-3 py-1 rounded-full flex items-center gap-1 shadow-xs">
                  <TrendingUp className="w-3 h-3 text-emerald-300" />
                  <span>↑ 12% vs last 30 days</span>
                </div>
              </div>

              <div className="flex items-center justify-between gap-4 pt-1">
                <div className="relative w-36 h-20 flex flex-col items-center justify-end">
                  <svg viewBox="0 0 100 55" className="w-full h-full">
                    <path
                      d="M 10 50 A 40 40 0 0 1 90 50"
                      fill="none"
                      stroke="rgba(255,255,255,0.15)"
                      strokeWidth="10"
                      strokeLinecap="round"
                    />
                    <path
                      d="M 10 50 A 40 40 0 0 1 90 50"
                      fill="none"
                      stroke="url(#rainbowGauge2)"
                      strokeWidth="10"
                      strokeLinecap="round"
                      strokeDasharray="125, 130"
                    />
                    <defs>
                      <linearGradient id="rainbowGauge2" x1="0%" y1="0%" x2="100%" y2="0%">
                        <stop offset="0%" stopColor="#10B981" />
                        <stop offset="50%" stopColor="#F59E0B" />
                        <stop offset="100%" stopColor="#818CF8" />
                      </linearGradient>
                    </defs>
                  </svg>

                  <div className="absolute bottom-0 text-center leading-none">
                    <span className="text-2xl font-black text-white block">72%</span>
                    <span className="text-[9px] text-indigo-200 font-semibold block mt-0.5 uppercase tracking-wider">
                      Overall Score
                    </span>
                  </div>
                </div>

                <div className="flex-1 h-16 flex items-end justify-end relative">
                  <svg viewBox="0 0 120 50" className="w-full h-full">
                    <path
                      d="M 5 40 Q 30 30 50 35 T 90 20 T 115 10"
                      fill="none"
                      stroke="#A78BFA"
                      strokeWidth="3"
                      strokeLinecap="round"
                    />
                    <circle cx="5" cy="40" r="3" fill="#DDD6FE" />
                    <circle cx="30" cy="32" r="3" fill="#DDD6FE" />
                    <circle cx="50" cy="35" r="3" fill="#DDD6FE" />
                    <circle cx="75" cy="24" r="3" fill="#DDD6FE" />
                    <circle cx="90" cy="20" r="3" fill="#DDD6FE" />
                    <circle cx="115" cy="10" r="4" fill="#FFFFFF" className="animate-ping" />
                    <circle cx="115" cy="10" r="4" fill="#FFFFFF" />
                  </svg>
                </div>
              </div>
            </div>

            {/* SCORE OVER TIME CARD */}
            <div className="bg-white border border-slate-200/80 rounded-3xl p-4 space-y-3 shadow-xs">
              <div className="flex items-center justify-between">
                <h3 className="text-sm font-extrabold text-slate-900">Score Over Time</h3>
                <button className="text-[#5D3EED] font-extrabold text-xs hover:underline">
                  View Full Report
                </button>
              </div>

              <div className="relative pt-6 pb-2">
                <div className="absolute top-1 right-20 bg-white border border-slate-200 text-slate-900 shadow-md rounded-xl px-2.5 py-1 text-[10px] font-bold flex items-center gap-1.5 z-10">
                  <span className="text-slate-400">12 May</span>
                  <span className="text-[#5D3EED] font-black">Score: 68%</span>
                </div>

                <div className="flex items-stretch gap-3">
                  <div className="flex flex-col justify-between text-[9px] font-bold text-slate-400 text-right h-32 pr-1">
                    <span>100%</span>
                    <span>75%</span>
                    <span>50%</span>
                    <span>25%</span>
                    <span>0%</span>
                  </div>

                  <div className="flex-1 h-32 relative flex flex-col justify-between">
                    <div className="border-b border-slate-100 w-full h-0" />
                    <div className="border-b border-slate-100 w-full h-0" />
                    <div className="border-b border-slate-100 w-full h-0" />
                    <div className="border-b border-slate-100 w-full h-0" />
                    <div className="border-b border-slate-200/80 w-full h-0" />

                    <svg viewBox="0 0 300 120" className="absolute inset-0 w-full h-full overflow-visible">
                      <defs>
                        <linearGradient id="chartGradient2" x1="0" y1="0" x2="0" y2="1">
                          <stop offset="0%" stopColor="#5D3EED" stopOpacity="0.25" />
                          <stop offset="100%" stopColor="#5D3EED" stopOpacity="0.0" />
                        </linearGradient>
                      </defs>

                      <path
                        d="M 10 90 L 30 75 L 50 82 L 70 95 L 90 70 L 110 50 L 130 55 L 150 42 L 170 30 L 190 45 L 210 40 L 230 35 L 250 20 L 270 25 L 290 15 L 290 120 L 10 120 Z"
                        fill="url(#chartGradient2)"
                      />

                      <path
                        d="M 10 90 L 30 75 L 50 82 L 70 95 L 90 70 L 110 50 L 130 55 L 150 42 L 170 30 L 190 45 L 210 40 L 230 35 L 250 20 L 270 25 L 290 15"
                        fill="none"
                        stroke="#5D3EED"
                        strokeWidth="3"
                        strokeLinecap="round"
                      />

                      <circle cx="10" cy="90" r="3" fill="#FFFFFF" stroke="#5D3EED" strokeWidth="2" />
                      <circle cx="30" cy="75" r="3" fill="#FFFFFF" stroke="#5D3EED" strokeWidth="2" />
                      <circle cx="50" cy="82" r="3" fill="#FFFFFF" stroke="#5D3EED" strokeWidth="2" />
                      <circle cx="70" cy="95" r="3" fill="#FFFFFF" stroke="#5D3EED" strokeWidth="2" />
                      <circle cx="90" cy="70" r="3" fill="#FFFFFF" stroke="#5D3EED" strokeWidth="2" />
                      <circle cx="110" cy="50" r="3" fill="#FFFFFF" stroke="#5D3EED" strokeWidth="2" />
                      <circle cx="130" cy="55" r="3" fill="#FFFFFF" stroke="#5D3EED" strokeWidth="2" />
                      <circle cx="150" cy="42" r="3" fill="#FFFFFF" stroke="#5D3EED" strokeWidth="2" />
                      <circle cx="170" cy="30" r="4" fill="#5D3EED" stroke="#FFFFFF" strokeWidth="2" />
                      <circle cx="190" cy="45" r="3" fill="#FFFFFF" stroke="#5D3EED" strokeWidth="2" />
                      <circle cx="210" cy="40" r="3" fill="#FFFFFF" stroke="#5D3EED" strokeWidth="2" />
                      <circle cx="230" cy="35" r="3" fill="#FFFFFF" stroke="#5D3EED" strokeWidth="2" />
                      <circle cx="250" cy="20" r="3" fill="#FFFFFF" stroke="#5D3EED" strokeWidth="2" />
                      <circle cx="270" cy="25" r="3" fill="#FFFFFF" stroke="#5D3EED" strokeWidth="2" />
                      <circle cx="290" cy="15" r="3" fill="#FFFFFF" stroke="#5D3EED" strokeWidth="2" />
                    </svg>
                  </div>
                </div>

                <div className="flex items-center justify-between text-[10px] font-bold text-slate-400 pl-10 pt-2">
                  <span>Apr 22</span>
                  <span>Apr 29</span>
                  <span>May 06</span>
                  <span>May 13</span>
                  <span>May 20</span>
                </div>
              </div>
            </div>
          </>
        )}

        {/* ========================================================================= */}
        {/* LOWER PAGE SECTION: PERFORMANCE BY DIFFICULTY & QUESTION TYPES */}
        {/* ========================================================================= */}
        {(activeViewSection === 'all' || activeViewSection === 'lower') && (
          <>
            {/* 4. PERFORMANCE BY DIFFICULTY CARD */}
            <div className="bg-white border border-slate-200/80 rounded-3xl p-4 space-y-3.5 shadow-xs">
              <div className="flex items-center justify-between">
                <h3 className="text-sm font-extrabold text-slate-900">Performance by Difficulty</h3>
                <button className="text-[#5D3EED] font-extrabold text-xs hover:underline">
                  View All
                </button>
              </div>

              <div className="flex items-center justify-between gap-4 pt-1">
                {/* 3-Color Donut Ring Chart */}
                <div className="relative w-32 h-32 flex-shrink-0 flex items-center justify-center">
                  <svg viewBox="0 0 36 36" className="w-full h-full transform -rotate-90">
                    <path
                      d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                      fill="none"
                      stroke="#10B981"
                      strokeWidth="4"
                      strokeDasharray="45, 100"
                    />
                    <path
                      d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                      fill="none"
                      stroke="#F59E0B"
                      strokeWidth="4"
                      strokeDasharray="30, 100"
                      strokeDashoffset="-45"
                    />
                    <path
                      d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                      fill="none"
                      stroke="#EF4444"
                      strokeWidth="4"
                      strokeDasharray="25, 100"
                      strokeDashoffset="-75"
                    />
                  </svg>

                  <div className="absolute text-center leading-none">
                    <span className="text-xl font-black text-slate-900 block">72%</span>
                    <span className="text-[9px] text-slate-400 font-bold block mt-0.5">Avg. Score</span>
                  </div>
                </div>

                {/* Breakdown Legend */}
                <div className="space-y-2 text-xs font-semibold text-slate-700 flex-1">
                  <div className="flex items-center justify-between">
                    <span className="flex items-center gap-2">
                      <span className="w-2.5 h-2.5 rounded-full bg-emerald-500" />
                      <span className="font-extrabold text-slate-800">Easy</span>
                    </span>
                    <span className="font-black text-slate-900">
                      82% <span className="text-[10px] text-slate-400 font-normal">(656)</span>
                    </span>
                  </div>

                  <div className="flex items-center justify-between">
                    <span className="flex items-center gap-2">
                      <span className="w-2.5 h-2.5 rounded-full bg-amber-500" />
                      <span className="font-extrabold text-slate-800">Medium</span>
                    </span>
                    <span className="font-black text-slate-900">
                      71% <span className="text-[10px] text-slate-400 font-normal">(568)</span>
                    </span>
                  </div>

                  <div className="flex items-center justify-between">
                    <span className="flex items-center gap-2">
                      <span className="w-2.5 h-2.5 rounded-full bg-rose-500" />
                      <span className="font-extrabold text-slate-800">Hard</span>
                    </span>
                    <span className="font-black text-slate-900">
                      54% <span className="text-[10px] text-slate-400 font-normal">(432)</span>
                    </span>
                  </div>
                </div>
              </div>
            </div>

            {/* 5. PERFORMANCE BY QUESTION TYPE CARD */}
            <div className="bg-white border border-slate-200/80 rounded-3xl p-4 space-y-3.5 shadow-xs">
              <div className="flex items-center justify-between">
                <h3 className="text-sm font-extrabold text-slate-900">Performance by Question Type</h3>
                <button className="text-[#5D3EED] font-extrabold text-xs hover:underline">
                  View All
                </button>
              </div>

              <div className="space-y-3 pt-1">
                {questionTypes.map((item, idx) => (
                  <div key={idx} className="space-y-1.5">
                    <div className="flex items-center justify-between text-xs font-extrabold text-slate-800">
                      <span>{item.name}</span>
                      <span className="text-[#5D3EED] font-black">{item.percentage}%</span>
                    </div>
                    <div className="w-full h-2 bg-slate-100 rounded-full overflow-hidden">
                      <div
                        className="h-full bg-[#5D3EED] rounded-full transition-all duration-500"
                        style={{ width: `${item.percentage}%` }}
                      />
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* 6. 4 KEY METRICS SUMMARY CARDS ROW */}
            <div className="grid grid-cols-4 gap-2.5">
              {/* Card 1: Accuracy */}
              <div className="bg-white border border-slate-200/80 rounded-2xl p-2.5 text-center shadow-xs flex flex-col items-center justify-center">
                <div className="w-9 h-9 rounded-2xl bg-emerald-50 text-emerald-600 flex items-center justify-center">
                  <Target className="w-4 h-4" />
                </div>
                <span className="text-[9px] text-slate-400 font-bold block mt-1">Accuracy</span>
                <span className="text-sm font-black text-slate-900 block mt-0.5">78%</span>
                <span className="text-[9px] font-extrabold text-emerald-600 block mt-0.5">↑ 8%</span>
              </div>

              {/* Card 2: Attempted */}
              <div className="bg-white border border-slate-200/80 rounded-2xl p-2.5 text-center shadow-xs flex flex-col items-center justify-center">
                <div className="w-9 h-9 rounded-2xl bg-purple-50 text-[#5D3EED] flex items-center justify-center">
                  <CheckCircle2 className="w-4 h-4 text-[#5D3EED]" />
                </div>
                <span className="text-[9px] text-slate-400 font-bold block mt-1">Attempted</span>
                <span className="text-sm font-black text-slate-900 block mt-0.5">92%</span>
                <span className="text-[9px] font-extrabold text-emerald-600 block mt-0.5">↑ 5%</span>
              </div>

              {/* Card 3: Time / Question */}
              <div className="bg-white border border-slate-200/80 rounded-2xl p-2.5 text-center shadow-xs flex flex-col items-center justify-center">
                <div className="w-9 h-9 rounded-2xl bg-orange-50 text-orange-600 flex items-center justify-center">
                  <Clock className="w-4 h-4 text-orange-600" />
                </div>
                <span className="text-[9px] text-slate-400 font-bold block mt-1">Time / Question</span>
                <span className="text-xs font-black text-slate-900 block mt-0.5">1m 24s</span>
                <span className="text-[9px] font-extrabold text-rose-500 block mt-0.5">↓ 10s</span>
              </div>

              {/* Card 4: Speed */}
              <div className="bg-white border border-slate-200/80 rounded-2xl p-2.5 text-center shadow-xs flex flex-col items-center justify-center">
                <div className="w-9 h-9 rounded-2xl bg-blue-50 text-blue-600 flex items-center justify-center">
                  <Timer className="w-4 h-4 text-blue-600" />
                </div>
                <span className="text-[9px] text-slate-400 font-bold block mt-1">Speed</span>
                <span className="text-xs font-black text-slate-900 block mt-0.5">45 Qs/hr</span>
                <span className="text-[9px] font-extrabold text-emerald-600 block mt-0.5">↑ 6 Qs</span>
              </div>
            </div>

            {/* 7. RECENT TEST HIGHLIGHTS LIST CARD */}
            <div className="bg-white border border-slate-200/80 rounded-3xl p-4 space-y-3.5 shadow-xs">
              <div className="flex items-center justify-between">
                <h3 className="text-sm font-extrabold text-slate-900">Recent Test Highlights</h3>
                <button className="text-[#5D3EED] font-extrabold text-xs hover:underline">
                  View All
                </button>
              </div>

              <div className="space-y-3">
                {recentTestHighlights.map((test) => (
                  <div
                    key={test.id}
                    className="flex items-center justify-between p-2.5 rounded-2xl bg-slate-50/70 border border-slate-100 hover:bg-purple-50/30 transition-all cursor-pointer"
                  >
                    <div className="flex items-center gap-3">
                      <div className={`w-10 h-10 rounded-2xl ${test.iconBg} ${test.iconColor} flex items-center justify-center flex-shrink-0`}>
                        <ClipboardList className="w-5 h-5" />
                      </div>

                      <div className="space-y-0.5">
                        <h4 className="text-xs font-extrabold text-slate-900">{test.title}</h4>
                        <p className="text-[10px] text-slate-400 font-medium">
                          {test.date} • {test.type}
                        </p>
                      </div>
                    </div>

                    <div className="flex items-center gap-2 text-right">
                      <div>
                        <span className={`text-xs font-black block ${test.scoreColor}`}>
                          {test.score}
                        </span>
                        <span className="text-[10px] font-bold text-slate-500 block">
                          {test.percentage}
                        </span>
                      </div>
                      <ChevronRight className="w-4 h-4 text-slate-400" />
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* 8. STRENGTH & WEAKNESS COMPARISON CARD (2 COLUMNS) */}
            <div className="bg-white border border-slate-200/80 rounded-3xl p-4 space-y-3.5 shadow-xs">
              <div className="flex items-center justify-between">
                <h3 className="text-sm font-extrabold text-slate-900">Strength & Weakness</h3>
                <button className="text-[#5D3EED] font-extrabold text-xs hover:underline">
                  View All
                </button>
              </div>

              <div className="grid grid-cols-2 gap-3">
                {/* Top Strengths Box */}
                <div className="bg-[#F0FDF4] border border-emerald-200/80 rounded-2xl p-3 space-y-2.5">
                  <h4 className="text-xs font-black text-emerald-800">Top Strengths</h4>
                  
                  <div className="space-y-2 text-[11px] font-extrabold text-slate-800">
                    <div className="flex items-center gap-1.5">
                      <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600 flex-shrink-0" />
                      <span className="truncate">Units & Measurements</span>
                    </div>

                    <div className="flex items-center gap-1.5">
                      <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600 flex-shrink-0" />
                      <span className="truncate">Plant Physiology</span>
                    </div>

                    <div className="flex items-center gap-1.5">
                      <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600 flex-shrink-0" />
                      <span className="truncate">Thermodynamics</span>
                    </div>
                  </div>
                </div>

                {/* Top Weakness Box */}
                <div className="bg-[#FFF1F2] border border-rose-200/80 rounded-2xl p-3 space-y-2.5">
                  <h4 className="text-xs font-black text-rose-800">Top Weakness</h4>

                  <div className="space-y-2 text-[11px] font-extrabold text-slate-800">
                    <div className="flex items-center gap-1.5">
                      <XCircle className="w-3.5 h-3.5 text-rose-500 flex-shrink-0" />
                      <span className="truncate">Chemical Bonding</span>
                    </div>

                    <div className="flex items-center gap-1.5">
                      <XCircle className="w-3.5 h-3.5 text-rose-500 flex-shrink-0" />
                      <span className="truncate">Human Reproduction</span>
                    </div>

                    <div className="flex items-center gap-1.5">
                      <XCircle className="w-3.5 h-3.5 text-rose-500 flex-shrink-0" />
                      <span className="truncate">Current Electricity</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </>
        )}

      </div>

    </div>
  );
};
