import React from 'react';
import {
  GraduationCap,
  Target,
  FileSpreadsheet,
  Clock,
  TrendingUp,
  Flame,
  CheckCircle2,
  BookOpen,
  Zap,
  ArrowRight,
  ChevronDown,
  ChevronLeft,
  ChevronRight,
  AlertTriangle,
  Calendar,
  Sparkles,
} from 'lucide-react';

interface StudentDashboardProps {
  onNavigate: (tab: string) => void;
  selectedExam: string;
}

export const StudentDashboard: React.FC<StudentDashboardProps> = ({
  onNavigate,
  selectedExam = 'NEET',
}) => {
  return (
    <div className="space-y-6 font-sans text-gray-800 pb-12">
      {/* Header Bar & Streak Tracker */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 tracking-tight">Good Morning, Arjun! 👋</h1>
          <p className="text-xs text-gray-500 mt-0.5">Let's continue your {selectedExam} preparation journey.</p>
        </div>

        {/* Streak Counter Card (Top Right) */}
        <div className="bg-white border border-gray-200 rounded-2xl p-3 shadow-sm flex items-center gap-4">
          <div className="flex items-center gap-2">
            <div className="w-9 h-9 rounded-xl bg-orange-50 text-orange-500 flex items-center justify-center font-bold">
              <Flame className="w-5 h-5 fill-orange-500" />
            </div>
            <div>
              <span className="text-sm font-bold text-gray-900 block leading-tight">12 <span className="text-xs font-semibold text-gray-500">Day Streak</span></span>
              <span className="text-[10px] text-gray-400 font-medium block">Keep it up!</span>
            </div>
          </div>

          {/* Weekday Circles T W T F S S M */}
          <div className="flex items-center gap-1 border-l border-gray-100 pl-3">
            {['T', 'W', 'T', 'F', 'S', 'S'].map((day, i) => (
              <div key={i} className="text-center">
                <span className="text-[9px] font-bold text-gray-400 block mb-0.5">{day}</span>
                <span className="w-4 h-4 rounded-full bg-emerald-500 text-white text-[9px] font-bold flex items-center justify-center">
                  ✓
                </span>
              </div>
            ))}
            <div className="text-center">
              <span className="text-[9px] font-bold text-gray-400 block mb-0.5">M</span>
              <span className="w-4 h-4 rounded-full bg-gray-100 text-gray-400 text-[9px] font-bold flex items-center justify-center">
                
              </span>
            </div>
          </div>
        </div>
      </div>

      {/* ROW 1: 5 KPI METRIC CARDS */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4">
        {/* Card 1: Questions Solved */}
        <div className="bg-white p-4 rounded-2xl border border-gray-200 shadow-sm flex items-center gap-3">
          <div className="w-10 h-10 rounded-full bg-purple-50 text-indigo-600 flex items-center justify-center flex-shrink-0">
            <GraduationCap className="w-5 h-5" />
          </div>
          <div>
            <span className="text-xl font-bold text-gray-900 block leading-tight">2,458</span>
            <span className="text-[11px] font-semibold text-gray-400 block">Questions Solved</span>
            <span className="text-[10px] font-bold text-emerald-600 block mt-0.5">▲ 18% <span className="text-gray-400 font-normal">vs last 7 days</span></span>
          </div>
        </div>

        {/* Card 2: Accuracy */}
        <div className="bg-white p-4 rounded-2xl border border-gray-200 shadow-sm flex items-center gap-3">
          <div className="w-10 h-10 rounded-full bg-emerald-50 text-emerald-600 flex items-center justify-center flex-shrink-0">
            <Target className="w-5 h-5" />
          </div>
          <div>
            <span className="text-xl font-bold text-gray-900 block leading-tight">78.4%</span>
            <span className="text-[11px] font-semibold text-gray-400 block">Accuracy</span>
            <span className="text-[10px] font-bold text-emerald-600 block mt-0.5">▲ 6.3% <span className="text-gray-400 font-normal">vs last 7 days</span></span>
          </div>
        </div>

        {/* Card 3: Tests Completed */}
        <div className="bg-white p-4 rounded-2xl border border-gray-200 shadow-sm flex items-center gap-3">
          <div className="w-10 h-10 rounded-full bg-blue-50 text-blue-600 flex items-center justify-center flex-shrink-0">
            <FileSpreadsheet className="w-5 h-5" />
          </div>
          <div>
            <span className="text-xl font-bold text-gray-900 block leading-tight">28</span>
            <span className="text-[11px] font-semibold text-gray-400 block">Tests Completed</span>
            <span className="text-[10px] font-bold text-emerald-600 block mt-0.5">▲ 4 <span className="text-gray-400 font-normal">vs last 7 days</span></span>
          </div>
        </div>

        {/* Card 4: Study Time */}
        <div className="bg-white p-4 rounded-2xl border border-gray-200 shadow-sm flex items-center gap-3">
          <div className="w-10 h-10 rounded-full bg-amber-50 text-amber-600 flex items-center justify-center flex-shrink-0">
            <Clock className="w-5 h-5" />
          </div>
          <div>
            <span className="text-xl font-bold text-gray-900 block leading-tight">36h 45m</span>
            <span className="text-[11px] font-semibold text-gray-400 block">Study Time</span>
            <span className="text-[10px] font-bold text-emerald-600 block mt-0.5">▲ 8h <span className="text-gray-400 font-normal">vs last 7 days</span></span>
          </div>
        </div>

        {/* Card 5: Current Rank */}
        <div className="bg-white p-4 rounded-2xl border border-gray-200 shadow-sm flex items-center gap-3">
          <div className="w-10 h-10 rounded-full bg-rose-50 text-rose-600 flex items-center justify-center flex-shrink-0">
            <TrendingUp className="w-5 h-5" />
          </div>
          <div>
            <span className="text-xl font-bold text-gray-900 block leading-tight">635</span>
            <span className="text-[11px] font-semibold text-gray-400 block">Current Rank</span>
            <span className="text-[10px] font-bold text-emerald-600 block mt-0.5">▲ 120 <span className="text-gray-400 font-normal">vs last week</span></span>
          </div>
        </div>
      </div>

      {/* ROW 2: RECOMMENDED FOR YOU (4 ACTION CARDS GRID) */}
      <div className="space-y-3">
        <h3 className="text-xs font-bold text-gray-900 uppercase tracking-wider">Recommended For You</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          {/* Action Card 1: Custom Practice */}
          <div className="bg-gradient-to-br from-purple-50/60 to-indigo-50/30 p-5 rounded-2xl border border-purple-100 flex flex-col justify-between space-y-4">
            <div className="space-y-2">
              <div className="w-9 h-9 rounded-xl bg-indigo-600 text-white flex items-center justify-center shadow-md shadow-indigo-600/20">
                <Target className="w-5 h-5" />
              </div>
              <h4 className="text-sm font-bold text-gray-900">Custom Practice</h4>
              <p className="text-xs text-gray-500">Practice questions from your weak topics</p>
            </div>
            <button
              onClick={() => onNavigate('custom_practice')}
              className="w-full py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white text-xs font-bold transition-all shadow-sm flex items-center justify-center gap-1.5"
            >
              <span>Start Practice</span>
              <ArrowRight className="w-3.5 h-3.5" />
            </button>
          </div>

          {/* Action Card 2: Take a Test */}
          <div className="bg-gradient-to-br from-emerald-50/60 to-teal-50/30 p-5 rounded-2xl border border-emerald-100 flex flex-col justify-between space-y-4">
            <div className="space-y-2">
              <div className="w-9 h-9 rounded-xl bg-emerald-600 text-white flex items-center justify-center shadow-md shadow-emerald-600/20">
                <FileSpreadsheet className="w-5 h-5" />
              </div>
              <h4 className="text-sm font-bold text-gray-900">Take a Test</h4>
              <p className="text-xs text-gray-500">Simulate exam and improve your performance</p>
            </div>
            <button
              onClick={() => onNavigate('custom_test')}
              className="w-full py-2.5 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold transition-all shadow-sm flex items-center justify-center gap-1.5"
            >
              <span>Start Test</span>
              <ArrowRight className="w-3.5 h-3.5" />
            </button>
          </div>

          {/* Action Card 3: PYQ Practice */}
          <div className="bg-gradient-to-br from-amber-50/60 to-orange-50/30 p-5 rounded-2xl border border-amber-100 flex flex-col justify-between space-y-4">
            <div className="space-y-2">
              <div className="w-9 h-9 rounded-xl bg-amber-500 text-white flex items-center justify-center shadow-md shadow-amber-500/20">
                <BookOpen className="w-5 h-5" />
              </div>
              <h4 className="text-sm font-bold text-gray-900">PYQ Practice</h4>
              <p className="text-xs text-gray-500">Practice previous year questions</p>
            </div>
            <button
              onClick={() => onNavigate('pyq')}
              className="w-full py-2.5 rounded-xl bg-amber-500 hover:bg-amber-600 text-white text-xs font-bold transition-all shadow-sm flex items-center justify-center gap-1.5"
            >
              <span>Practice PYQs</span>
              <ArrowRight className="w-3.5 h-3.5" />
            </button>
          </div>

          {/* Action Card 4: Daily Quiz */}
          <div className="bg-gradient-to-br from-blue-50/60 to-sky-50/30 p-5 rounded-2xl border border-blue-100 flex flex-col justify-between space-y-4">
            <div className="space-y-2">
              <div className="w-9 h-9 rounded-xl bg-blue-600 text-white flex items-center justify-center shadow-md shadow-blue-600/20">
                <Zap className="w-5 h-5" />
              </div>
              <h4 className="text-sm font-bold text-gray-900">Daily Quiz</h4>
              <p className="text-xs text-gray-500">Play daily quiz and boost your rank</p>
            </div>
            <button
              onClick={() => onNavigate('custom_practice')}
              className="w-full py-2.5 rounded-xl bg-blue-600 hover:bg-blue-700 text-white text-xs font-bold transition-all shadow-sm flex items-center justify-center gap-1.5"
            >
              <span>Attempt Quiz</span>
              <ArrowRight className="w-3.5 h-3.5" />
            </button>
          </div>
        </div>
      </div>

      {/* ROW 3: MIDDLE SECTION (2 COLUMNS: LEFT MAIN CONTENT 8 COLS VS RIGHT SIDEBAR 4 COLS) */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        {/* LEFT COLUMN: Continue Prep & Progress Chart (8 cols) */}
        <div className="lg:col-span-8 space-y-6">
          {/* Continue Your Preparation Card */}
          <div className="bg-white p-5 rounded-2xl border border-gray-200 shadow-sm space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="text-sm font-bold text-gray-900">Continue Your Preparation</h3>
              <button className="text-xs font-semibold text-indigo-600 hover:underline">View All</button>
            </div>

            <div className="space-y-3">
              {[
                {
                  title: 'NEET Biology - Plant Kingdom',
                  progress: '12 / 25 Questions',
                  percent: 48,
                  img: 'https://images.unsplash.com/photo-1518531933037-91b2f5f229cc?w=100&auto=format&fit=crop&q=80',
                },
                {
                  title: 'NEET Chemistry - Chemical Bonding',
                  progress: '18 / 30 Questions',
                  percent: 60,
                  img: 'https://images.unsplash.com/photo-1532187863486-abf9dbad1b69?w=100&auto=format&fit=crop&q=80',
                },
                {
                  title: 'NEET Physics - Current Electricity',
                  progress: '8 / 20 Questions',
                  percent: 40,
                  img: 'https://images.unsplash.com/photo-1555680202-c86f0e12f086?w=100&auto=format&fit=crop&q=80',
                },
                {
                  title: 'Human Physiology - Digestion',
                  progress: '15 / 25 Questions',
                  percent: 60,
                  img: 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=100&auto=format&fit=crop&q=80',
                },
              ].map((item, i) => (
                <div
                  key={i}
                  className="p-3.5 rounded-xl border border-gray-100 bg-gray-50/50 hover:bg-white transition-all flex items-center justify-between gap-4"
                >
                  <div className="flex items-center gap-3 min-w-0 flex-1">
                    <img src={item.img} alt={item.title} className="w-10 h-10 rounded-lg object-cover flex-shrink-0" />
                    <div className="min-w-0 flex-1">
                      <span className="text-xs font-bold text-gray-900 block truncate">{item.title}</span>
                      <div className="flex items-center gap-3 mt-1.5">
                        <div className="w-36 bg-gray-200 rounded-full h-1.5">
                          <div className="bg-indigo-600 h-1.5 rounded-full" style={{ width: `${item.percent}%` }} />
                        </div>
                        <span className="text-[10px] font-semibold text-gray-400">{item.progress}</span>
                      </div>
                    </div>
                  </div>

                  <button
                    onClick={() => onNavigate('custom_practice')}
                    className="px-3.5 py-1.5 bg-purple-50 hover:bg-purple-100 text-indigo-600 text-xs font-bold rounded-lg border border-purple-100 transition-colors flex-shrink-0"
                  >
                    Continue
                  </button>
                </div>
              ))}
            </div>
          </div>

          {/* Your Progress Chart Card */}
          <div className="bg-white p-5 rounded-2xl border border-gray-200 shadow-sm space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="text-sm font-bold text-gray-900">Your Progress</h3>
              <button className="flex items-center gap-1.5 px-2.5 py-1 bg-gray-50 border border-gray-200 rounded-lg text-[11px] font-semibold text-gray-600">
                <span>This Month</span>
                <ChevronDown className="w-3 h-3 text-gray-400" />
              </button>
            </div>

            {/* Legend */}
            <div className="flex items-center gap-4 text-[11px] font-medium text-gray-600">
              <div className="flex items-center gap-1.5">
                <span className="w-2.5 h-2.5 rounded-full bg-indigo-600" />
                <span>Questions Solved</span>
              </div>
              <div className="flex items-center gap-1.5">
                <span className="w-2.5 h-2.5 rounded-full bg-emerald-500" />
                <span>Tests Completed</span>
              </div>
            </div>

            {/* SVG Progress Line Chart */}
            <div className="h-44 w-full pt-2">
              <svg viewBox="0 0 500 140" className="w-full h-full overflow-visible">
                <line x1="30" y1="20" x2="490" y2="20" stroke="#f1f5f9" strokeWidth="1" />
                <text x="5" y="24" fontSize="9" fill="#94a3b8">2K</text>

                <line x1="30" y1="60" x2="490" y2="60" stroke="#f1f5f9" strokeWidth="1" />
                <text x="5" y="64" fontSize="9" fill="#94a3b8">1.5K</text>

                <line x1="30" y1="90" x2="490" y2="90" stroke="#f1f5f9" strokeWidth="1" />
                <text x="5" y="94" fontSize="9" fill="#94a3b8">1K</text>

                <line x1="30" y1="120" x2="490" y2="120" stroke="#e2e8f0" strokeWidth="1" />
                <text x="15" y="124" fontSize="9" fill="#94a3b8">0</text>

                {/* Line 1: Questions Solved (Purple) */}
                <path
                  d="M 30,110 Q 110,85 190,75 T 350,45 T 490,30"
                  fill="none"
                  stroke="#4f46e5"
                  strokeWidth="2.5"
                />

                {/* Line 2: Tests Completed (Green) */}
                <path
                  d="M 30,120 Q 110,105 190,95 T 350,80 T 490,55"
                  fill="none"
                  stroke="#10b981"
                  strokeWidth="2.5"
                />

                <text x="30" y="135" fontSize="9" fill="#94a3b8">1 May</text>
                <text x="145" y="135" fontSize="9" fill="#94a3b8">7 May</text>
                <text x="260" y="135" fontSize="9" fill="#94a3b8">14 May</text>
                <text x="375" y="135" fontSize="9" fill="#94a3b8">21 May</text>
                <text x="460" y="135" fontSize="9" fill="#94a3b8">28 May</text>
              </svg>
            </div>

            {/* Bottom Metrics Bar */}
            <div className="grid grid-cols-3 gap-4 pt-3 border-t border-gray-100 text-center">
              <div>
                <span className="text-[10px] font-semibold text-gray-400 uppercase block">Questions Solved</span>
                <span className="text-base font-bold text-gray-900 mt-0.5 block">
                  1,245 <span className="text-[10px] font-bold text-emerald-600">↑ 32%</span>
                </span>
              </div>

              <div>
                <span className="text-[10px] font-semibold text-gray-400 uppercase block">Tests Completed</span>
                <span className="text-base font-bold text-gray-900 mt-0.5 block">
                  16 <span className="text-[10px] font-bold text-emerald-600">↑ 23%</span>
                </span>
              </div>

              <div>
                <span className="text-[10px] font-semibold text-gray-400 uppercase block">Study Time</span>
                <span className="text-base font-bold text-gray-900 mt-0.5 block">
                  42h 30m <span className="text-[10px] font-bold text-rose-500">↓ 18%</span>
                </span>
              </div>
            </div>
          </div>
        </div>

        {/* RIGHT COLUMN: Performance Summary, Weak Areas, Upcoming Tests (4 cols) */}
        <div className="lg:col-span-4 space-y-6">
          {/* Card 1: Your Performance Summary */}
          <div className="bg-white p-5 rounded-2xl border border-gray-200 shadow-sm space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="text-sm font-bold text-gray-900">Your Performance Summary</h3>
              <button className="flex items-center gap-1 px-2 py-0.5 bg-gray-50 border border-gray-200 rounded text-[10px] font-semibold text-gray-600">
                <span>This Week</span>
                <ChevronDown className="w-3 h-3" />
              </button>
            </div>

            {/* Score Metric */}
            <div className="space-y-1">
              <span className="text-[11px] font-semibold text-gray-400 uppercase">Score</span>
              <div className="flex items-baseline justify-between">
                <span className="text-2xl font-bold text-gray-900">612 <span className="text-xs text-gray-400 font-normal">/ 720</span></span>
                <span className="text-xs font-bold text-indigo-600">85%</span>
              </div>
              <div className="w-full bg-gray-100 rounded-full h-2">
                <div className="bg-gradient-to-r from-indigo-600 to-purple-600 h-2 rounded-full" style={{ width: '85%' }} />
              </div>
            </div>

            <div className="grid grid-cols-3 gap-2 text-center pt-2">
              <div className="bg-gray-50 p-2.5 rounded-xl border border-gray-100">
                <span className="text-[10px] text-gray-400 block font-semibold">Accuracy</span>
                <span className="text-xs font-bold text-gray-900 block mt-0.5">78.4%</span>
              </div>
              <div className="bg-gray-50 p-2.5 rounded-xl border border-gray-100">
                <span className="text-[10px] text-gray-400 block font-semibold">Questions Solved</span>
                <span className="text-xs font-bold text-gray-900 block mt-0.5">245</span>
              </div>
              <div className="bg-gray-50 p-2.5 rounded-xl border border-gray-100">
                <span className="text-[10px] text-gray-400 block font-semibold">Time Taken</span>
                <span className="text-xs font-bold text-gray-900 block mt-0.5">6h 25m</span>
              </div>
            </div>

            <button
              onClick={() => onNavigate('analytics')}
              className="w-full text-center text-xs font-bold text-indigo-600 hover:underline flex items-center justify-center gap-1"
            >
              <span>View Detailed Analysis</span>
              <ArrowRight className="w-3.5 h-3.5" />
            </button>
          </div>

          {/* Card 2: Weak Areas */}
          <div className="bg-white p-5 rounded-2xl border border-gray-200 shadow-sm space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="text-sm font-bold text-gray-900">Weak Areas</h3>
              <button className="text-xs font-semibold text-indigo-600 hover:underline">View All</button>
            </div>

            <div className="space-y-3">
              {[
                { name: 'Organic Chemistry', acc: '42% Accuracy', status: 'Weak', pill: 'bg-rose-50 text-rose-600 border-rose-200' },
                { name: 'Electrostatics', acc: '48% Accuracy', status: 'Weak', pill: 'bg-rose-50 text-rose-600 border-rose-200' },
                { name: 'Human Physiology', acc: '55% Accuracy', status: 'Average', pill: 'bg-amber-50 text-amber-600 border-amber-200' },
                { name: 'Modern Physics', acc: '62% Accuracy', status: 'Average', pill: 'bg-amber-50 text-amber-600 border-amber-200' },
                { name: 'Biotechnology', acc: '78% Accuracy', status: 'Strong', pill: 'bg-emerald-50 text-emerald-600 border-emerald-200' },
              ].map((w, i) => (
                <div key={i} className="flex items-center justify-between text-xs">
                  <div className="flex items-center gap-2.5">
                    <div className="w-6 h-6 rounded-full bg-gray-100 flex items-center justify-center text-gray-500 text-[10px]">
                      {i + 1}
                    </div>
                    <div>
                      <span className="font-bold text-gray-900 block text-xs leading-tight">{w.name}</span>
                      <span className="text-[10px] text-gray-400 font-medium block">{w.acc}</span>
                    </div>
                  </div>

                  <span className={`text-[10px] font-bold px-2.5 py-0.5 rounded border ${w.pill}`}>
                    {w.status}
                  </span>
                </div>
              ))}
            </div>
          </div>

          {/* Card 3: Upcoming Tests */}
          <div className="bg-white p-5 rounded-2xl border border-gray-200 shadow-sm space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="text-sm font-bold text-gray-900">Upcoming Tests</h3>
              <button className="text-xs font-semibold text-indigo-600 hover:underline">View All</button>
            </div>

            <div className="space-y-3">
              {[
                { title: 'NEET Full Syllabus Test 05', time: '20th May, 2024 • 11:00 AM', tag: 'Full Syllabus', pill: 'bg-purple-50 text-indigo-600 border-purple-200' },
                { title: 'Physics Chapter Test', sub: 'Kinematics', time: '21st May, 2024 • 10:00 AM', tag: 'Physics', pill: 'bg-blue-50 text-blue-600 border-blue-200' },
                { title: 'Chemistry Quiz', sub: 'Periodic Table', time: '22nd May, 2024 • 09:00 AM', tag: 'Chemistry', pill: 'bg-emerald-50 text-emerald-600 border-emerald-200' },
              ].map((u, i) => (
                <div key={i} className="flex items-center justify-between text-xs p-2.5 rounded-xl border border-gray-100 bg-gray-50/50">
                  <div className="flex items-center gap-3">
                    <div className="w-8 h-8 rounded-xl bg-indigo-600 text-white flex items-center justify-center font-bold text-xs flex-shrink-0">
                      <Calendar className="w-4 h-4" />
                    </div>
                    <div>
                      <span className="font-bold text-gray-900 block text-xs leading-tight">{u.title}</span>
                      <span className="text-[10px] text-gray-400 block mt-0.5">{u.time}</span>
                    </div>
                  </div>

                  <span className={`text-[10px] font-bold px-2 py-0.5 rounded border flex-shrink-0 ${u.pill}`}>
                    {u.tag}
                  </span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* ROW 4: EXPLORE BY SUBJECT (BOTTOM ROW) */}
      <div className="space-y-3 pt-2">
        <div className="flex items-center justify-between">
          <h3 className="text-xs font-bold text-gray-900 uppercase tracking-wider">Explore by Subject</h3>
          <div className="flex items-center gap-1">
            <button className="p-1 rounded-lg border border-gray-200 bg-white text-gray-400 hover:text-gray-700">
              <ChevronLeft className="w-4 h-4" />
            </button>
            <button className="p-1 rounded-lg border border-gray-200 bg-white text-gray-400 hover:text-gray-700">
              <ChevronRight className="w-4 h-4" />
            </button>
          </div>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4">
          {[
            { name: 'Physics', qCount: '512 Questions', accuracy: '78% Accuracy', color: 'bg-indigo-600', fill: '78%' },
            { name: 'Chemistry', qCount: '612 Questions', accuracy: '76% Accuracy', color: 'bg-emerald-500', fill: '76%' },
            { name: 'Biology', qCount: '1,124 Questions', accuracy: '80% Accuracy', color: 'bg-blue-600', fill: '80%' },
            { name: 'Zoology', qCount: '564 Questions', accuracy: '81% Accuracy', color: 'bg-orange-500', fill: '81%' },
            { name: 'Botany', qCount: '580 Questions', accuracy: '79% Accuracy', color: 'bg-teal-500', fill: '79%' },
          ].map((sub, i) => (
            <div key={i} className="bg-white p-4 rounded-2xl border border-gray-200 shadow-sm space-y-3 hover:border-indigo-300 transition-colors">
              <div className="flex items-center gap-3">
                <div className="w-9 h-9 rounded-xl bg-purple-50 text-indigo-600 flex items-center justify-center font-bold">
                  <BookOpen className="w-4 h-4" />
                </div>
                <div>
                  <h4 className="text-xs font-bold text-gray-900">{sub.name}</h4>
                  <span className="text-[10px] text-gray-400 font-medium block">{sub.qCount}</span>
                </div>
              </div>

              <div className="space-y-1 pt-1">
                <div className="flex justify-between text-[10px]">
                  <span className="text-gray-400 font-medium">Accuracy</span>
                  <span className="font-bold text-gray-800">{sub.accuracy}</span>
                </div>
                <div className="w-full bg-gray-100 rounded-full h-1.5">
                  <div className={`h-1.5 rounded-full ${sub.color}`} style={{ width: sub.fill }} />
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};
