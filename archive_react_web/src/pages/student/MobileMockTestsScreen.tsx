import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Menu,
  Search,
  ArrowRight,
  ClipboardList,
  Clock,
  TrendingUp,
  Award,
  ChevronDown,
  Filter,
  Bookmark,
  FileText,
  Trophy,
  CheckCircle2,
  Check,
} from 'lucide-react';

interface MobileMockTestsScreenProps {
  onOpenDrawer?: () => void;
  onStartTest?: (testId?: number) => void;
  onPreviewTest?: (testId?: number) => void;
  isMobileFrame?: boolean;
}

interface MockTestItem {
  id: number;
  title: string;
  isLatest?: boolean;
  subjects: string;
  syllabus: string;
  questions: number;
  marks: number;
  duration: string;
  iconBg: string;
  iconColor: string;
  category: 'full' | 'chapter' | 'subject';
}

export const MobileMockTestsScreen: React.FC<MobileMockTestsScreenProps> = ({
  onOpenDrawer,
  onStartTest,
  onPreviewTest,
  isMobileFrame = false,
}) => {
  const navigate = useNavigate();

  // State
  const [activeCategoryTab, setActiveCategoryTab] = useState<string>('all');
  const [selectedClass, setSelectedClass] = useState<string>('Class 12');
  const [selectedExam, setSelectedExam] = useState<string>('NEET');
  const [selectedSubject, setSelectedSubject] = useState<string>('All Subjects');

  // Filter dropdown toggle
  const [activeDropdown, setActiveDropdown] = useState<'class' | 'exam' | 'subject' | null>(null);

  // Bookmarks state
  const [bookmarkedIds, setBookmarkedIds] = useState<number[]>([]);

  const toggleBookmark = (id: number, e: React.MouseEvent) => {
    e.stopPropagation();
    setBookmarkedIds((prev) =>
      prev.includes(id) ? prev.filter((item) => item !== id) : [...prev, id]
    );
  };

  const handleStart = (id?: number) => {
    if (onStartTest) onStartTest(id);
    else navigate('/app/test');
  };

  const handlePreview = (id?: number) => {
    if (onPreviewTest) onPreviewTest(id);
    else navigate('/app/test');
  };

  const mockTestsList: MockTestItem[] = [
    {
      id: 1,
      title: 'NEET 2024 Mock Test - 1',
      isLatest: true,
      subjects: 'All Subjects',
      syllabus: 'Full Syllabus',
      questions: 180,
      marks: 720,
      duration: '3:20 Hrs',
      iconBg: 'bg-emerald-50',
      iconColor: 'text-emerald-600',
      category: 'full',
    },
    {
      id: 2,
      title: 'NEET 2024 Mock Test - 2',
      subjects: 'All Subjects',
      syllabus: 'Full Syllabus',
      questions: 180,
      marks: 720,
      duration: '3:20 Hrs',
      iconBg: 'bg-orange-50',
      iconColor: 'text-orange-600',
      category: 'full',
    },
    {
      id: 3,
      title: 'NEET 2024 Mock Test - 3',
      subjects: 'All Subjects',
      syllabus: 'Full Syllabus',
      questions: 180,
      marks: 720,
      duration: '3:20 Hrs',
      iconBg: 'bg-purple-50',
      iconColor: 'text-[#5D3EED]',
      category: 'full',
    },
  ];

  // Filtered mock tests based on active tab
  const filteredTests = mockTestsList.filter((test) => {
    if (activeCategoryTab === 'all') return true;
    return test.category === activeCategoryTab;
  });

  return (
    <div className={`w-full font-sans bg-[#F8FAFC] text-slate-900 select-none pb-12 ${isMobileFrame ? 'px-0 py-0' : 'max-w-md mx-auto min-h-screen shadow-xl rounded-3xl'}`}>
      
      {/* ========================================================================= */}
      {/* 1. TOP TITLE HEADER (MATCHING SCREENSHOT TOP BADGE) */}
      {/* ========================================================================= */}
      <div className="p-4 pb-2 bg-white flex items-center justify-between border-b border-slate-100 sticky top-0 z-30 shadow-2xs">
        <h1 className="text-xl font-black text-slate-900 tracking-tight">
          Mock Tests
        </h1>
        <span className="px-3 py-1.5 rounded-xl bg-[#EEF2FF] text-[#4F46E5] font-extrabold text-xs tracking-wide shadow-2xs border border-indigo-100/50">
          NCERT / NTA
        </span>
      </div>

      <div className="p-4 space-y-4">

        {/* ========================================================================= */}
        {/* 2. INNER HEADER CARD BAR */}
        {/* ========================================================================= */}
        <div className="bg-white px-4 py-3 rounded-2xl border border-slate-200/80 flex items-center justify-between shadow-xs">
          <button
            onClick={onOpenDrawer}
            className="p-1 text-slate-800 hover:text-[#5D3EED] transition-colors"
          >
            <Menu className="w-5 h-5 stroke-[2.5]" />
          </button>

          <h2 className="text-sm font-black text-slate-900 text-center flex-1">
            Mock Tests
          </h2>

          <button className="p-1 text-slate-800 hover:text-[#5D3EED] transition-colors">
            <Search className="w-5 h-5 stroke-[2.5]" />
          </button>
        </div>

        {/* ========================================================================= */}
        {/* 3. HERO GRADIENT BANNER */}
        {/* ========================================================================= */}
        <div className="bg-gradient-to-r from-[#4F46E5] via-[#5D3EED] to-[#6366F1] text-white p-5 rounded-3xl relative overflow-hidden shadow-lg shadow-indigo-600/20 flex items-center justify-between">
          <div className="space-y-2 z-10 max-w-[210px]">
            <h2 className="text-lg font-black leading-tight tracking-tight">
              Assess Yourself.<br />Improve Every Day.
            </h2>
            <p className="text-[11px] text-indigo-100 font-medium leading-normal">
              Take full length mock tests simulating the real exam.
            </p>
            <button
              onClick={() => handleStart(1)}
              className="mt-2 bg-white text-[#5D3EED] font-extrabold text-xs px-4 py-2.5 rounded-full hover:bg-purple-50 inline-flex items-center gap-1.5 shadow-md active:scale-95 transition-all"
            >
              <span>Take a Test</span>
              <ArrowRight className="w-3.5 h-3.5" />
            </button>
          </div>

          {/* Right Clipboard & Clock Illustration Graphic */}
          <div className="relative z-10 flex-shrink-0">
            <div className="w-24 h-24 bg-white/15 rounded-2xl backdrop-blur-xs p-3 border border-white/20 shadow-inner flex flex-col items-center justify-center space-y-1.5">
              <div className="w-10 h-10 rounded-full bg-white text-[#5D3EED] flex items-center justify-center shadow-md">
                <CheckCircle2 className="w-6 h-6 text-[#5D3EED]" />
              </div>
              <div className="space-y-1 w-full text-center">
                <div className="w-12 h-1.5 bg-white/80 rounded-full mx-auto" />
                <div className="w-8 h-1.5 bg-white/60 rounded-full mx-auto" />
              </div>
            </div>
            
            {/* Clock Overlay Badge */}
            <div className="absolute -bottom-2 -right-2 bg-white text-[#5D3EED] p-2 rounded-full shadow-lg border-2 border-indigo-500">
              <Clock className="w-4 h-4" />
            </div>
          </div>

          {/* Background Decorative Circles */}
          <div className="absolute -top-10 -right-10 w-40 h-40 bg-white/10 rounded-full blur-xl pointer-events-none" />
          <div className="absolute -bottom-10 -left-10 w-32 h-32 bg-indigo-400/20 rounded-full blur-lg pointer-events-none" />
        </div>

        {/* ========================================================================= */}
        {/* 4. 4 METRIC QUICK SUMMARY CARDS GRID */}
        {/* ========================================================================= */}
        <div className="grid grid-cols-4 gap-2">
          {/* Card 1: Tests Taken */}
          <div className="bg-white border border-slate-200/80 rounded-2xl p-2.5 text-center shadow-2xs flex flex-col items-center justify-center hover:border-blue-300 transition-colors">
            <div className="w-9 h-9 rounded-2xl bg-blue-50 text-blue-600 flex items-center justify-center">
              <ClipboardList className="w-4 h-4" />
            </div>
            <span className="text-sm font-black text-slate-900 mt-1.5 block">32</span>
            <span className="text-[9px] text-slate-400 font-extrabold block">Tests Taken</span>
          </div>

          {/* Card 2: Avg. Score */}
          <div className="bg-white border border-slate-200/80 rounded-2xl p-2.5 text-center shadow-2xs flex flex-col items-center justify-center hover:border-orange-300 transition-colors">
            <div className="w-9 h-9 rounded-2xl bg-orange-50 text-orange-600 flex items-center justify-center">
              <Clock className="w-4 h-4" />
            </div>
            <span className="text-sm font-black text-slate-900 mt-1.5 block">78%</span>
            <span className="text-[9px] text-slate-400 font-extrabold block">Avg. Score</span>
          </div>

          {/* Card 3: Best Score */}
          <div className="bg-white border border-slate-200/80 rounded-2xl p-2.5 text-center shadow-2xs flex flex-col items-center justify-center hover:border-emerald-300 transition-colors">
            <div className="w-9 h-9 rounded-2xl bg-emerald-50 text-emerald-600 flex items-center justify-center">
              <TrendingUp className="w-4 h-4" />
            </div>
            <span className="text-sm font-black text-slate-900 mt-1.5 block">1280</span>
            <span className="text-[9px] text-slate-400 font-extrabold block">Best Score</span>
          </div>

          {/* Card 4: Hours Practiced */}
          <div className="bg-white border border-slate-200/80 rounded-2xl p-2.5 text-center shadow-2xs flex flex-col items-center justify-center hover:border-purple-300 transition-colors">
            <div className="w-9 h-9 rounded-2xl bg-purple-50 text-[#5D3EED] flex items-center justify-center">
              <Award className="w-4 h-4 text-[#5D3EED]" />
            </div>
            <span className="text-sm font-black text-slate-900 mt-1.5 block">15</span>
            <span className="text-[9px] text-slate-400 font-extrabold block">Hours Practiced</span>
          </div>
        </div>

        {/* ========================================================================= */}
        {/* 5. TEST CATEGORY FILTER TABS (HORIZONTAL SEGMENTED CONTROL BAR) */}
        {/* ========================================================================= */}
        <div className="bg-slate-100/90 p-1.5 rounded-2xl flex items-center justify-between text-xs font-bold text-slate-600 shadow-inner">
          <button
            onClick={() => setActiveCategoryTab('all')}
            className={`flex-1 py-2 rounded-xl text-center transition-all ${
              activeCategoryTab === 'all'
                ? 'bg-white text-[#5D3EED] font-black shadow-xs'
                : 'hover:text-slate-900'
            }`}
          >
            All Tests
          </button>

          <button
            onClick={() => setActiveCategoryTab('full')}
            className={`flex-1 py-2 rounded-xl text-center transition-all ${
              activeCategoryTab === 'full'
                ? 'bg-white text-[#5D3EED] font-black shadow-xs'
                : 'hover:text-slate-900'
            }`}
          >
            Full Test
          </button>

          <button
            onClick={() => setActiveCategoryTab('chapter')}
            className={`flex-1 py-2 rounded-xl text-center transition-all ${
              activeCategoryTab === 'chapter'
                ? 'bg-white text-[#5D3EED] font-black shadow-xs'
                : 'hover:text-slate-900'
            }`}
          >
            Chapter Test
          </button>

          <button
            onClick={() => setActiveCategoryTab('subject')}
            className={`flex-1 py-2 rounded-xl text-center transition-all ${
              activeCategoryTab === 'subject'
                ? 'bg-white text-[#5D3EED] font-black shadow-xs'
                : 'hover:text-slate-900'
            }`}
          >
            Subject Test
          </button>
        </div>

        {/* ========================================================================= */}
        {/* 6. DROPDOWN FILTERS & FILTER BUTTON ROW */}
        {/* ========================================================================= */}
        <div className="relative">
          <div className="flex items-center gap-2 overflow-x-auto custom-scrollbar pb-1">
            {/* Class Dropdown Pill */}
            <div
              onClick={() => setActiveDropdown((prev) => (prev === 'class' ? null : 'class'))}
              className={`flex items-center gap-1.5 bg-white border ${
                activeDropdown === 'class' ? 'border-[#5D3EED] ring-2 ring-purple-100' : 'border-slate-200/90'
              } rounded-xl px-3 py-2 text-xs font-bold text-slate-700 flex-shrink-0 cursor-pointer shadow-2xs hover:bg-slate-50 transition-all`}
            >
              <span>{selectedClass}</span>
              <ChevronDown className={`w-3.5 h-3.5 text-slate-400 transition-transform ${activeDropdown === 'class' ? 'rotate-180 text-[#5D3EED]' : ''}`} />
            </div>

            {/* Exam Dropdown Pill */}
            <div
              onClick={() => setActiveDropdown((prev) => (prev === 'exam' ? null : 'exam'))}
              className={`flex items-center gap-1.5 bg-white border ${
                activeDropdown === 'exam' ? 'border-[#5D3EED] ring-2 ring-purple-100' : 'border-slate-200/90'
              } rounded-xl px-3 py-2 text-xs font-bold text-slate-700 flex-shrink-0 cursor-pointer shadow-2xs hover:bg-slate-50 transition-all`}
            >
              <span>{selectedExam}</span>
              <ChevronDown className={`w-3.5 h-3.5 text-slate-400 transition-transform ${activeDropdown === 'exam' ? 'rotate-180 text-[#5D3EED]' : ''}`} />
            </div>

            {/* Subject Dropdown Pill */}
            <div
              onClick={() => setActiveDropdown((prev) => (prev === 'subject' ? null : 'subject'))}
              className={`flex items-center gap-1.5 bg-white border ${
                activeDropdown === 'subject' ? 'border-[#5D3EED] ring-2 ring-purple-100' : 'border-slate-200/90'
              } rounded-xl px-3 py-2 text-xs font-bold text-slate-700 flex-shrink-0 cursor-pointer shadow-2xs hover:bg-slate-50 transition-all`}
            >
              <span>{selectedSubject}</span>
              <ChevronDown className={`w-3.5 h-3.5 text-slate-400 transition-transform ${activeDropdown === 'subject' ? 'rotate-180 text-[#5D3EED]' : ''}`} />
            </div>

            {/* Filter Action Button */}
            <button
              onClick={() => setActiveDropdown(null)}
              className="p-2 rounded-xl bg-purple-50 text-[#5D3EED] border border-purple-100 flex items-center justify-center flex-shrink-0 hover:bg-purple-100 transition-colors shadow-2xs"
            >
              <Filter className="w-4 h-4 text-[#5D3EED]" />
            </button>
          </div>

          {/* Class Dropdown Overlay */}
          {activeDropdown === 'class' && (
            <div className="absolute top-11 left-0 z-40 bg-white border border-slate-200 rounded-2xl shadow-xl p-2 w-44 space-y-1 animate-in fade-in zoom-in-95 duration-150">
              {['Class 11', 'Class 12', 'Dropper / Repeater'].map((c) => (
                <button
                  key={c}
                  onClick={() => {
                    setSelectedClass(c);
                    setActiveDropdown(null);
                  }}
                  className={`w-full text-left px-3 py-2 rounded-xl text-xs font-bold flex items-center justify-between transition-colors ${
                    selectedClass === c ? 'bg-purple-50 text-[#5D3EED]' : 'text-slate-700 hover:bg-slate-50'
                  }`}
                >
                  <span>{c}</span>
                  {selectedClass === c && <Check className="w-3.5 h-3.5 text-[#5D3EED]" />}
                </button>
              ))}
            </div>
          )}

          {/* Exam Dropdown Overlay */}
          {activeDropdown === 'exam' && (
            <div className="absolute top-11 left-24 z-40 bg-white border border-slate-200 rounded-2xl shadow-xl p-2 w-40 space-y-1 animate-in fade-in zoom-in-95 duration-150">
              {['NEET', 'JEE Main', 'JEE Advanced'].map((e) => (
                <button
                  key={e}
                  onClick={() => {
                    setSelectedExam(e);
                    setActiveDropdown(null);
                  }}
                  className={`w-full text-left px-3 py-2 rounded-xl text-xs font-bold flex items-center justify-between transition-colors ${
                    selectedExam === e ? 'bg-purple-50 text-[#5D3EED]' : 'text-slate-700 hover:bg-slate-50'
                  }`}
                >
                  <span>{e}</span>
                  {selectedExam === e && <Check className="w-3.5 h-3.5 text-[#5D3EED]" />}
                </button>
              ))}
            </div>
          )}

          {/* Subject Dropdown Overlay */}
          {activeDropdown === 'subject' && (
            <div className="absolute top-11 left-48 z-40 bg-white border border-slate-200 rounded-2xl shadow-xl p-2 w-44 space-y-1 animate-in fade-in zoom-in-95 duration-150">
              {['All Subjects', 'Physics', 'Chemistry', 'Biology'].map((s) => (
                <button
                  key={s}
                  onClick={() => {
                    setSelectedSubject(s);
                    setActiveDropdown(null);
                  }}
                  className={`w-full text-left px-3 py-2 rounded-xl text-xs font-bold flex items-center justify-between transition-colors ${
                    selectedSubject === s ? 'bg-purple-50 text-[#5D3EED]' : 'text-slate-700 hover:bg-slate-50'
                  }`}
                >
                  <span>{s}</span>
                  {selectedSubject === s && <Check className="w-3.5 h-3.5 text-[#5D3EED]" />}
                </button>
              ))}
            </div>
          )}
        </div>

        {/* ========================================================================= */}
        {/* 7. FULL LENGTH MOCK TESTS CARDS STACK */}
        {/* ========================================================================= */}
        <div className="space-y-3.5 pt-1">
          <div className="flex items-center justify-between">
            <h3 className="text-sm font-extrabold text-slate-900">
              Full Length Mock Tests
            </h3>
            <button className="text-[#5D3EED] font-extrabold text-xs hover:underline">
              View All
            </button>
          </div>

          <div className="space-y-3.5">
            {filteredTests.map((test) => {
              const isBookmarked = bookmarkedIds.includes(test.id);

              return (
                <div
                  key={test.id}
                  className="bg-white border border-slate-200/90 rounded-3xl p-4 space-y-3 shadow-2xs hover:border-indigo-300 hover:shadow-md transition-all"
                >
                  {/* Top Title & Icon Row */}
                  <div className="flex items-start justify-between">
                    <div className="flex items-start gap-3">
                      <div className={`w-11 h-11 rounded-2xl ${test.iconBg} ${test.iconColor} flex items-center justify-center flex-shrink-0 mt-0.5 shadow-2xs`}>
                        <ClipboardList className="w-5.5 h-5.5" />
                      </div>

                      <div className="space-y-0.5">
                        <div className="flex items-center gap-2">
                          <h4 className="text-sm font-extrabold text-slate-900">
                            {test.title}
                          </h4>
                          {test.isLatest && (
                            <span className="px-2 py-0.5 rounded-md bg-emerald-100 text-emerald-700 text-[9px] font-black uppercase tracking-wider">
                              Latest
                            </span>
                          )}
                        </div>
                        <p className="text-xs text-slate-400 font-bold">
                          {test.subjects} • {test.syllabus}
                        </p>
                      </div>
                    </div>

                    <button
                      onClick={(e) => toggleBookmark(test.id, e)}
                      className={`p-1.5 rounded-xl transition-colors ${
                        isBookmarked ? 'text-[#5D3EED] bg-purple-50' : 'text-slate-400 hover:text-[#5D3EED]'
                      }`}
                    >
                      <Bookmark className={`w-4.5 h-4.5 ${isBookmarked ? 'fill-[#5D3EED]' : ''}`} />
                    </button>
                  </div>

                  {/* Meta Stats Row */}
                  <div className="flex items-center gap-4 text-xs font-bold text-slate-600 pt-1">
                    <div className="flex items-center gap-1.5">
                      <FileText className="w-3.5 h-3.5 text-slate-400" />
                      <span>{test.questions} Qs</span>
                    </div>

                    <div className="flex items-center gap-1.5">
                      <Trophy className="w-3.5 h-3.5 text-slate-400" />
                      <span>{test.marks} Marks</span>
                    </div>

                    <div className="flex items-center gap-1.5">
                      <Clock className="w-3.5 h-3.5 text-slate-400" />
                      <span>{test.duration}</span>
                    </div>
                  </div>

                  {/* Action Buttons (2-Column Grid) */}
                  <div className="grid grid-cols-2 gap-3 pt-1">
                    <button
                      onClick={() => handlePreview(test.id)}
                      className="py-2.5 rounded-xl border border-[#5D3EED] text-[#5D3EED] bg-white font-extrabold text-xs hover:bg-purple-50 transition-colors flex items-center justify-center gap-1.5 shadow-2xs active:scale-95"
                    >
                      <span>Preview</span>
                    </button>

                    <button
                      onClick={() => handleStart(test.id)}
                      className="py-2.5 rounded-xl bg-[#5D3EED] hover:bg-[#4F46E5] text-white font-extrabold text-xs transition-colors flex items-center justify-center gap-1.5 shadow-sm active:scale-95"
                    >
                      <span>Start Test</span>
                    </button>
                  </div>

                </div>
              );
            })}
          </div>

        </div>

      </div>

    </div>
  );
};
