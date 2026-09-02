import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Menu,
  GraduationCap,
  Bell,
  ChevronDown,
  Calendar,
  FileText,
  CheckCircle2,
  Trophy,
  Target,
  ArrowRight,
  BookOpen,
  Bookmark,
  Filter,
  ChevronRight,
  Crown,
  Home,
  User,
  BarChart2,
} from 'lucide-react';

interface CategoryItem {
  title: string;
  count: number;
  icon: React.ElementType;
  iconColor: string;
  bgColor: string;
}

interface TestSeriesItem {
  id: string;
  title: string;
  subtitle: string;
  testCount: number;
  durationMinutes: number;
  difficulty: string;
  status: 'In Progress' | 'Not Started' | 'Completed';
  nextTestName: string;
  iconBgColor: string;
  icon: React.ElementType;
}

export const TestSeriesScreen: React.FC = () => {
  const navigate = useNavigate();

  const [selectedCategory, setSelectedCategory] = useState<string>('All Series');
  const [selectedExamFilter, setSelectedExamFilter] = useState<string>('NEET 2026');

  const categories: CategoryItem[] = [
    {
      title: 'All Series',
      count: 24,
      icon: Target,
      iconColor: 'text-blue-600',
      bgColor: 'bg-blue-50',
    },
    {
      title: 'Full Syllabus',
      count: 10,
      icon: FileText,
      iconColor: 'text-emerald-600',
      bgColor: 'bg-emerald-50',
    },
    {
      title: 'Chapter Wise',
      count: 8,
      icon: BookOpen,
      iconColor: 'text-purple-600',
      bgColor: 'bg-purple-50',
    },
    {
      title: 'Topic Wise',
      count: 6,
      icon: Bookmark,
      iconColor: 'text-orange-600',
      bgColor: 'bg-orange-50',
    },
  ];

  const allTestSeries: TestSeriesItem[] = [
    {
      id: 'ts1',
      title: 'NEET 2026 Full Syllabus Test Series',
      subtitle: 'Complete syllabus mock tests',
      testCount: 12,
      durationMinutes: 180,
      difficulty: 'High',
      status: 'In Progress',
      nextTestName: 'Test 09',
      iconBgColor: 'bg-emerald-500',
      icon: FileText,
    },
    {
      id: 'ts2',
      title: 'NEET 2026 Chapter Wise Test Series',
      subtitle: 'Practice by individual chapters',
      testCount: 8,
      durationMinutes: 60,
      difficulty: 'Medium',
      status: 'Not Started',
      nextTestName: 'Chapter 01',
      iconBgColor: 'bg-blue-500',
      icon: BookOpen,
    },
    {
      id: 'ts3',
      title: 'NEET 2026 Topic Wise Test Series',
      subtitle: 'Practice by specific topics',
      testCount: 6,
      durationMinutes: 30,
      difficulty: 'Easy',
      status: 'In Progress',
      nextTestName: 'Topic 05',
      iconBgColor: 'bg-purple-500',
      icon: Bookmark,
    },
    {
      id: 'ts4',
      title: 'NEET 2026 Previous Year Papers',
      subtitle: 'PYQ based mock tests',
      testCount: 5,
      durationMinutes: 180,
      difficulty: 'High',
      status: 'Not Started',
      nextTestName: 'PYQ 2025',
      iconBgColor: 'bg-rose-500',
      icon: Target,
    },
  ];

  return (
    <div className="min-h-screen bg-slate-50 text-slate-800 font-sans pb-20 max-w-md mx-auto shadow-xl border-x border-slate-200">
      {/* 1. Top Header Bar */}
      <header className="h-14 bg-white border-b border-slate-100 px-4 flex items-center justify-between sticky top-0 z-30">
        <div className="flex items-center gap-2.5">
          <button className="text-slate-700 hover:text-slate-900">
            <Menu className="w-5 h-5" />
          </button>
          <div className="w-8 h-8 rounded-lg bg-slate-900 flex items-center justify-center text-white">
            <GraduationCap className="w-4 h-4" />
          </div>
          <div>
            <h1 className="text-sm font-bold text-slate-900 leading-none">ExamPrep</h1>
            <div className="flex items-center gap-0.5 text-[11px] font-semibold text-slate-500 mt-0.5">
              <span>{selectedExamFilter}</span>
              <ChevronDown className="w-3 h-3 text-slate-400" />
            </div>
          </div>
        </div>

        <div className="flex items-center gap-3">
          <div className="relative">
            <div className="w-8 h-8 rounded-full bg-slate-100 flex items-center justify-center text-slate-600">
              <Bell className="w-4 h-4" />
            </div>
            <span className="absolute -top-1 -right-1 w-4 h-4 rounded-full bg-rose-500 text-white text-[9px] font-bold flex items-center justify-center border border-white">
              3
            </span>
          </div>

          <div className="w-8 h-8 rounded-full bg-blue-600 text-white font-bold text-xs flex items-center justify-center">
            M
          </div>
        </div>
      </header>

      {/* Main Content Area */}
      <main className="p-4 space-y-5">
        {/* 2. Page Header Row (Title + Exam Filter) */}
        <div className="flex items-start justify-between gap-2">
          <div>
            <h2 className="text-xl font-black text-slate-900 tracking-tight">Test Series</h2>
            <p className="text-xs text-slate-500 mt-0.5">
              Attempt mock tests and improve your exam readiness.
            </p>
          </div>

          <button className="inline-flex items-center gap-1.5 px-2.5 py-1.5 bg-white border border-slate-200 rounded-lg text-xs font-bold text-slate-800 shadow-xs hover:bg-slate-50 transition-colors">
            <Calendar className="w-3.5 h-3.5 text-emerald-500" />
            <span>{selectedExamFilter}</span>
            <ChevronDown className="w-3.5 h-3.5 text-slate-400" />
          </button>
        </div>

        {/* 3. 4 KPI Stat Summary Cards Row */}
        <div className="bg-white rounded-2xl border border-slate-200/80 p-3.5 shadow-xs grid grid-cols-4 divide-x divide-slate-100">
          <div className="flex flex-col items-center text-center px-1">
            <div className="w-8 h-8 rounded-full bg-blue-50 text-blue-600 flex items-center justify-center mb-1.5">
              <FileText className="w-4 h-4" />
            </div>
            <span className="text-base font-black text-slate-900">24</span>
            <span className="text-[10px] font-semibold text-slate-500 mt-0.5">Total Tests</span>
          </div>

          <div className="flex flex-col items-center text-center px-1">
            <div className="w-8 h-8 rounded-full bg-emerald-50 text-emerald-600 flex items-center justify-center mb-1.5">
              <CheckCircle2 className="w-4 h-4" />
            </div>
            <span className="text-base font-black text-slate-900">8</span>
            <span className="text-[10px] font-semibold text-slate-500 mt-0.5">Tests Attempted</span>
          </div>

          <div className="flex flex-col items-center text-center px-1">
            <div className="w-8 h-8 rounded-full bg-amber-50 text-amber-500 flex items-center justify-center mb-1.5">
              <Trophy className="w-4 h-4" />
            </div>
            <span className="text-base font-black text-slate-900">3,420</span>
            <span className="text-[10px] font-semibold text-slate-500 mt-0.5">Total Score</span>
          </div>

          <div className="flex flex-col items-center text-center px-1">
            <div className="w-8 h-8 rounded-full bg-purple-50 text-purple-600 flex items-center justify-center mb-1.5">
              <Target className="w-4 h-4" />
            </div>
            <span className="text-base font-black text-slate-900">76.4%</span>
            <span className="text-[10px] font-semibold text-slate-500 mt-0.5">Avg Accuracy</span>
          </div>
        </div>

        {/* 4. Your Progress Card */}
        <div className="bg-white rounded-2xl border border-slate-200/80 p-4 shadow-xs space-y-3">
          <div className="flex items-center justify-between">
            <h3 className="text-xs font-bold text-slate-900">Your Progress</h3>
            <button
              onClick={() => navigate('/analytics')}
              className="inline-flex items-center gap-1 text-xs font-bold text-blue-600 hover:text-blue-700"
            >
              <span>View Analytics</span>
              <ArrowRight className="w-3.5 h-3.5" />
            </button>
          </div>

          <div className="flex items-center gap-4">
            {/* Donut Progress Ring */}
            <div className="relative w-16 h-16 flex items-center justify-center flex-shrink-0">
              <svg className="w-16 h-16 transform -rotate-90">
                <circle cx="32" cy="32" r="26" stroke="#F1F5F9" strokeWidth="6" fill="transparent" />
                <circle
                  cx="32"
                  cy="32"
                  r="26"
                  stroke="#10B981"
                  strokeWidth="6"
                  strokeDasharray="163"
                  strokeDashoffset="57"
                  strokeLinecap="round"
                  fill="transparent"
                />
              </svg>
              <span className="absolute text-sm font-black text-slate-900">65%</span>
            </div>

            {/* Stats Column */}
            <div className="flex-1 space-y-2">
              <div className="flex items-center justify-between text-xs">
                <span className="font-medium text-slate-500">Tests Completed</span>
                <span className="font-bold text-slate-800">8 of 24</span>
              </div>

              <div className="w-full h-1.5 bg-slate-100 rounded-full overflow-hidden">
                <div className="h-full bg-emerald-500 rounded-full w-[33%]"></div>
              </div>

              <div className="flex items-center justify-between pt-1 text-xs">
                <div>
                  <span className="text-[10px] font-medium text-slate-400 block">Avg Accuracy</span>
                  <span className="font-bold text-slate-900">76.4%</span>
                </div>
                <div className="text-right">
                  <span className="text-[10px] font-medium text-slate-400 block">Avg Score</span>
                  <span className="font-bold text-slate-900">142 / 180</span>
                </div>
              </div>
            </div>

            <ChevronRight className="w-5 h-5 text-slate-400" />
          </div>
        </div>

        {/* 5. Test Series Categories Section */}
        <div className="space-y-2.5">
          <h3 className="text-xs font-bold text-slate-900">Test Series Categories</h3>
          <div className="flex items-center gap-2.5 overflow-x-auto pb-1 custom-scrollbar">
            {categories.map((cat) => {
              const isSelected = selectedCategory === cat.title;
              const IconComp = cat.icon;

              return (
                <button
                  key={cat.title}
                  onClick={() => setSelectedCategory(cat.title)}
                  className={`flex-1 min-w-[105px] p-3 rounded-xl text-center border transition-all ${
                    isSelected
                      ? 'bg-blue-50 border-blue-200 text-blue-700 shadow-xs'
                      : 'bg-white border-slate-200/80 text-slate-800 hover:bg-slate-50'
                  }`}
                >
                  <div
                    className={`w-7 h-7 mx-auto rounded-full flex items-center justify-center mb-1.5 ${cat.bgColor} ${cat.iconColor}`}
                  >
                    <IconComp className="w-3.5 h-3.5" />
                  </div>
                  <span className="text-xs font-bold block whitespace-nowrap">{cat.title}</span>
                  <span
                    className={`text-[10px] font-medium block mt-0.5 ${
                      isSelected ? 'text-blue-600 font-semibold' : 'text-slate-500'
                    }`}
                  >
                    {cat.count} Tests
                  </span>
                </button>
              );
            })}
          </div>
        </div>

        {/* 6. All Test Series List */}
        <div className="space-y-3">
          <div className="flex items-center justify-between">
            <h3 className="text-xs font-bold text-slate-900">All Test Series</h3>
            <button className="inline-flex items-center gap-1 px-2.5 py-1 bg-white border border-slate-200 rounded-lg text-xs font-bold text-blue-600 hover:bg-slate-50">
              <Filter className="w-3 h-3 text-blue-600" />
              <span>Filter</span>
            </button>
          </div>

          <div className="space-y-2.5">
            {allTestSeries.map((item) => {
              const isInProgress = item.status === 'In Progress';
              const IconComp = item.icon;

              return (
                <div
                  key={item.id}
                  className="bg-white rounded-2xl border border-slate-200/80 p-3.5 shadow-xs flex items-center justify-between gap-3 hover:border-slate-300 transition-all cursor-pointer"
                >
                  <div className="flex items-center gap-3">
                    <div
                      className={`w-10 h-10 rounded-xl ${item.iconBgColor} text-white flex items-center justify-center flex-shrink-0 shadow-xs`}
                    >
                      <IconComp className="w-5 h-5" />
                    </div>

                    <div className="space-y-1">
                      <h4 className="text-xs font-bold text-slate-900 leading-snug">{item.title}</h4>
                      <p className="text-[11px] text-slate-500 leading-none">{item.subtitle}</p>

                      <div className="flex items-center gap-3 pt-0.5 text-[10px] font-semibold text-slate-500">
                        <span className="flex items-center gap-1">
                          <FileText className="w-3 h-3 text-slate-400" />
                          {item.testCount} Tests
                        </span>
                        <span className="flex items-center gap-1">
                          <span className="text-slate-400">🕒</span>
                          {item.durationMinutes} min
                        </span>
                        <span className="flex items-center gap-1">
                          <span className="text-slate-400">📊</span>
                          {item.difficulty}
                        </span>
                      </div>
                    </div>
                  </div>

                  <div className="flex items-center gap-2 flex-shrink-0">
                    <div className="text-right">
                      <span
                        className={`inline-block px-2 py-0.5 rounded-full text-[9px] font-bold ${
                          isInProgress ? 'bg-emerald-50 text-emerald-700' : 'bg-blue-50 text-blue-700'
                        }`}
                      >
                        {item.status}
                      </span>
                      <span className="text-[9px] text-slate-400 font-medium block mt-1">
                        {isInProgress ? 'Next Test' : 'Start Test'}
                      </span>
                      <span className="text-[11px] font-bold text-slate-900 block leading-none">
                        {item.nextTestName}
                      </span>
                    </div>

                    <ChevronRight className="w-4 h-4 text-slate-400" />
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* 7. Go Premium Banner */}
        <div className="bg-gradient-to-r from-purple-50 to-indigo-50 border border-purple-100 rounded-2xl p-4 flex items-center justify-between gap-3 shadow-xs">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-purple-200/60 text-purple-700 flex items-center justify-center flex-shrink-0">
              <Crown className="w-5 h-5 fill-purple-700" />
            </div>

            <div>
              <h4 className="text-xs font-bold text-indigo-700">Go Premium</h4>
              <p className="text-[11px] text-slate-600 mt-0.5 leading-snug max-w-[190px]">
                Unlock all test series, detailed analysis, and exclusive features.
              </p>
            </div>
          </div>

          <button
            onClick={() => navigate('/pricing')}
            className="inline-flex items-center gap-1.5 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl text-xs font-bold shadow-md shadow-indigo-600/30 transition-all flex-shrink-0"
          >
            <span>Upgrade Now</span>
            <ArrowRight className="w-3.5 h-3.5" />
          </button>
        </div>
      </main>

      {/* 8. Bottom Navigation Bar */}
      <nav className="fixed bottom-0 left-0 right-0 max-w-md mx-auto bg-white border-t border-slate-200/80 px-4 h-14 flex items-center justify-around z-40">
        <button onClick={() => navigate('/dashboard')} className="flex flex-col items-center text-slate-500">
          <Home className="w-4 h-4" />
          <span className="text-[10px] font-medium mt-1">Home</span>
        </button>

        <button onClick={() => navigate('/practice')} className="flex flex-col items-center text-slate-500">
          <Target className="w-4 h-4" />
          <span className="text-[10px] font-medium mt-1">Practice</span>
        </button>

        <button className="flex flex-col items-center text-indigo-600 font-bold">
          <Calendar className="w-4 h-4 text-indigo-600" />
          <span className="text-[10px] mt-1">Test Series</span>
        </button>

        <button onClick={() => navigate('/analytics')} className="flex flex-col items-center text-slate-500">
          <BarChart2 className="w-4 h-4" />
          <span className="text-[10px] font-medium mt-1">Analytics</span>
        </button>

        <button onClick={() => navigate('/profile')} className="flex flex-col items-center text-slate-500">
          <User className="w-4 h-4" />
          <span className="text-[10px] font-medium mt-1">Profile</span>
        </button>
      </nav>
    </div>
  );
};
