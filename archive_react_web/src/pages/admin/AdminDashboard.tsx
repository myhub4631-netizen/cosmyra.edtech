import React from 'react';
import {
  Users,
  UserCheck,
  HelpCircle,
  FileSpreadsheet,
  Target,
  TrendingUp,
  Download,
  Calendar,
  ChevronDown,
  ArrowUpRight,
  CheckCircle2,
  AlertCircle,
  FileText,
  Clock,
  Award,
  Zap,
} from 'lucide-react';

export const AdminDashboardView: React.FC = () => {
  return (
    <div className="space-y-6 font-sans text-gray-800 pb-12">
      {/* Top Header Title & Global Controls */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 tracking-tight">Dashboard</h1>
          <p className="text-xs text-gray-500 mt-0.5">
            Welcome back, Super Admin! Here's what's happening on your platform.
          </p>
        </div>

        <div className="flex items-center gap-3">
          {/* Date Picker Button */}
          <button className="flex items-center gap-2 px-3 py-2 bg-white border border-gray-200 rounded-xl text-xs font-semibold text-gray-700 shadow-sm hover:bg-gray-50 transition-colors">
            <Calendar className="w-3.5 h-3.5 text-gray-500" />
            <span>May 18, 2024 - Jun 17, 2024</span>
            <ChevronDown className="w-3.5 h-3.5 text-gray-400" />
          </button>

          {/* Export Report Button */}
          <button className="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-xl text-xs font-bold shadow-md shadow-blue-600/20 transition-all">
            <Download className="w-3.5 h-3.5" />
            <span>Export Report</span>
          </button>
        </div>
      </div>

      {/* ROW 1: 6 KPI METRIC CARDS */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-6 gap-4">
        {/* Card 1: Total Students */}
        <div className="bg-white p-4 rounded-2xl border border-gray-200 shadow-sm space-y-3">
          <div className="flex items-center justify-between">
            <div className="w-9 h-9 rounded-full bg-blue-50 text-blue-600 flex items-center justify-center">
              <Users className="w-4 h-4" />
            </div>
          </div>
          <div>
            <span className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider block">
              Total Students
            </span>
            <div className="flex items-baseline justify-between mt-1">
              <span className="text-xl font-bold text-gray-900">248,689</span>
              <span className="inline-flex items-center text-[10px] font-bold text-emerald-600 bg-emerald-50 px-1.5 py-0.5 rounded-full">
                <ArrowUpRight className="w-3 h-3 mr-0.5" /> 12.4%
              </span>
            </div>
            <span className="text-[10px] text-gray-400 mt-1 block">vs last 30 days</span>
          </div>
        </div>

        {/* Card 2: Total Teachers */}
        <div className="bg-white p-4 rounded-2xl border border-gray-200 shadow-sm space-y-3">
          <div className="flex items-center justify-between">
            <div className="w-9 h-9 rounded-full bg-emerald-50 text-emerald-600 flex items-center justify-center">
              <UserCheck className="w-4 h-4" />
            </div>
          </div>
          <div>
            <span className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider block">
              Total Teachers
            </span>
            <div className="flex items-baseline justify-between mt-1">
              <span className="text-xl font-bold text-gray-900">12,753</span>
              <span className="inline-flex items-center text-[10px] font-bold text-emerald-600 bg-emerald-50 px-1.5 py-0.5 rounded-full">
                <ArrowUpRight className="w-3 h-3 mr-0.5" /> 8.7%
              </span>
            </div>
            <span className="text-[10px] text-gray-400 mt-1 block">vs last 30 days</span>
          </div>
        </div>

        {/* Card 3: Questions */}
        <div className="bg-white p-4 rounded-2xl border border-gray-200 shadow-sm space-y-3">
          <div className="flex items-center justify-between">
            <div className="w-9 h-9 rounded-full bg-amber-50 text-amber-600 flex items-center justify-center">
              <HelpCircle className="w-4 h-4" />
            </div>
          </div>
          <div>
            <span className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider block">
              Questions
            </span>
            <div className="flex items-baseline justify-between mt-1">
              <span className="text-xl font-bold text-gray-900">1,257,684</span>
              <span className="inline-flex items-center text-[10px] font-bold text-emerald-600 bg-emerald-50 px-1.5 py-0.5 rounded-full">
                <ArrowUpRight className="w-3 h-3 mr-0.5" /> 15.3%
              </span>
            </div>
            <span className="text-[10px] text-gray-400 mt-1 block">vs last 30 days</span>
          </div>
        </div>

        {/* Card 4: Tests Attempted */}
        <div className="bg-white p-4 rounded-2xl border border-gray-200 shadow-sm space-y-3">
          <div className="flex items-center justify-between">
            <div className="w-9 h-9 rounded-full bg-cyan-50 text-cyan-600 flex items-center justify-center">
              <FileSpreadsheet className="w-4 h-4" />
            </div>
          </div>
          <div>
            <span className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider block">
              Tests Attempted
            </span>
            <div className="flex items-baseline justify-between mt-1">
              <span className="text-xl font-bold text-gray-900">845,932</span>
              <span className="inline-flex items-center text-[10px] font-bold text-emerald-600 bg-emerald-50 px-1.5 py-0.5 rounded-full">
                <ArrowUpRight className="w-3 h-3 mr-0.5" /> 18.6%
              </span>
            </div>
            <span className="text-[10px] text-gray-400 mt-1 block">vs last 30 days</span>
          </div>
        </div>

        {/* Card 5: Practice Sessions */}
        <div className="bg-white p-4 rounded-2xl border border-gray-200 shadow-sm space-y-3">
          <div className="flex items-center justify-between">
            <div className="w-9 h-9 rounded-full bg-rose-50 text-rose-600 flex items-center justify-center">
              <Target className="w-4 h-4" />
            </div>
          </div>
          <div>
            <span className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider block">
              Practice Sessions
            </span>
            <div className="flex items-baseline justify-between mt-1">
              <span className="text-xl font-bold text-gray-900">2,453,892</span>
              <span className="inline-flex items-center text-[10px] font-bold text-emerald-600 bg-emerald-50 px-1.5 py-0.5 rounded-full">
                <ArrowUpRight className="w-3 h-3 mr-0.5" /> 22.1%
              </span>
            </div>
            <span className="text-[10px] text-gray-400 mt-1 block">vs last 30 days</span>
          </div>
        </div>

        {/* Card 6: Revenue */}
        <div className="bg-white p-4 rounded-2xl border border-gray-200 shadow-sm space-y-3">
          <div className="flex items-center justify-between">
            <div className="w-9 h-9 rounded-full bg-emerald-50 text-emerald-600 flex items-center justify-center font-bold">
              ₹
            </div>
          </div>
          <div>
            <span className="text-[11px] font-semibold text-gray-500 uppercase tracking-wider block">
              Revenue (₹)
            </span>
            <div className="flex items-baseline justify-between mt-1">
              <span className="text-xl font-bold text-gray-900">₹12,45,320</span>
              <span className="inline-flex items-center text-[10px] font-bold text-emerald-600 bg-emerald-50 px-1.5 py-0.5 rounded-full">
                <ArrowUpRight className="w-3 h-3 mr-0.5" /> 16.2%
              </span>
            </div>
            <span className="text-[10px] text-gray-400 mt-1 block">vs last 30 days</span>
          </div>
        </div>
      </div>

      {/* ROW 2: 3 CHARTS (Performance Overview, Top Exams Donut, Daily Active Users Bar) */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        {/* Chart 1: Performance Overview Line Chart (6 cols) */}
        <div className="lg:col-span-6 bg-white p-5 rounded-2xl border border-gray-200 shadow-sm space-y-4">
          <div className="flex items-center justify-between">
            <h3 className="text-sm font-bold text-gray-900">Performance Overview</h3>
            <button className="flex items-center gap-1.5 px-2.5 py-1 bg-gray-50 border border-gray-200 rounded-lg text-[11px] font-semibold text-gray-600">
              <span>Last 30 Days</span>
              <ChevronDown className="w-3 h-3 text-gray-400" />
            </button>
          </div>

          {/* Legend */}
          <div className="flex items-center gap-4 text-[11px] font-medium text-gray-600">
            <div className="flex items-center gap-1.5">
              <span className="w-2.5 h-2.5 rounded-full bg-blue-500" />
              <span>Tests Attempted</span>
            </div>
            <div className="flex items-center gap-1.5">
              <span className="w-2.5 h-2.5 rounded-full bg-emerald-500" />
              <span>Practice Sessions</span>
            </div>
            <div className="flex items-center gap-1.5">
              <span className="w-2.5 h-2.5 rounded-full bg-purple-500" />
              <span>Questions Attempted</span>
            </div>
          </div>

          {/* SVG Smooth Multi-Line Chart */}
          <div className="h-52 w-full pt-2">
            <svg viewBox="0 0 500 180" className="w-full h-full overflow-visible">
              {/* Y Axis Grid lines */}
              <line x1="30" y1="20" x2="490" y2="20" stroke="#f1f5f9" strokeWidth="1" />
              <text x="5" y="24" fontSize="9" fill="#94a3b8">100K</text>

              <line x1="30" y1="60" x2="490" y2="60" stroke="#f1f5f9" strokeWidth="1" />
              <text x="5" y="64" fontSize="9" fill="#94a3b8">80K</text>

              <line x1="30" y1="100" x2="490" y2="100" stroke="#f1f5f9" strokeWidth="1" />
              <text x="5" y="104" fontSize="9" fill="#94a3b8">40K</text>

              <line x1="30" y1="140" x2="490" y2="140" stroke="#f1f5f9" strokeWidth="1" />
              <text x="5" y="144" fontSize="9" fill="#94a3b8">20K</text>

              <line x1="30" y1="170" x2="490" y2="170" stroke="#e2e8f0" strokeWidth="1" />
              <text x="15" y="174" fontSize="9" fill="#94a3b8">0</text>

              {/* Line 1: Questions Attempted (Purple) */}
              <path
                d="M 30,120 Q 70,80 110,95 T 190,65 T 270,45 T 350,75 T 430,40 T 490,60"
                fill="none"
                stroke="#a855f7"
                strokeWidth="2.5"
              />

              {/* Line 2: Practice Sessions (Green) */}
              <path
                d="M 30,135 Q 70,110 110,115 T 190,95 T 270,85 T 350,110 T 430,85 T 490,95"
                fill="none"
                stroke="#10b981"
                strokeWidth="2.5"
              />

              {/* Line 3: Tests Attempted (Blue) */}
              <path
                d="M 30,150 Q 70,135 110,130 T 190,120 T 270,110 T 350,135 T 430,115 T 490,130"
                fill="none"
                stroke="#3b82f6"
                strokeWidth="2.5"
              />

              {/* X Axis Dates */}
              <text x="30" y="185" fontSize="9" fill="#94a3b8">18 May</text>
              <text x="110" y="185" fontSize="9" fill="#94a3b8">23 May</text>
              <text x="190" y="185" fontSize="9" fill="#94a3b8">28 May</text>
              <text x="270" y="185" fontSize="9" fill="#94a3b8">02 Jun</text>
              <text x="350" y="185" fontSize="9" fill="#94a3b8">07 Jun</text>
              <text x="430" y="185" fontSize="9" fill="#94a3b8">12 Jun</text>
              <text x="475" y="185" fontSize="9" fill="#94a3b8">17 Jun</text>
            </svg>
          </div>
        </div>

        {/* Chart 2: Top Exams by Usage Donut Chart (3 cols) */}
        <div className="lg:col-span-3 bg-white p-5 rounded-2xl border border-gray-200 shadow-sm space-y-4">
          <h3 className="text-sm font-bold text-gray-900">Top Exams by Usage</h3>

          <div className="flex items-center gap-4">
            {/* SVG Donut */}
            <div className="w-28 h-28 flex-shrink-0">
              <svg viewBox="0 0 36 36" className="w-full h-full transform -rotate-90">
                <path
                  d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                  fill="none"
                  stroke="#3b82f6"
                  strokeWidth="6"
                  strokeDasharray="40.2, 100"
                />
                <path
                  d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                  fill="none"
                  stroke="#10b981"
                  strokeWidth="6"
                  strokeDasharray="28.1, 100"
                  strokeDashoffset="-40.2"
                />
                <path
                  d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                  fill="none"
                  stroke="#f59e0b"
                  strokeWidth="6"
                  strokeDasharray="12.4, 100"
                  strokeDashoffset="-68.3"
                />
                <path
                  d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                  fill="none"
                  stroke="#ec4899"
                  strokeWidth="6"
                  strokeDasharray="8.7, 100"
                  strokeDashoffset="-80.7"
                />
                <path
                  d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                  fill="none"
                  stroke="#94a3b8"
                  strokeWidth="6"
                  strokeDasharray="10.6, 100"
                  strokeDashoffset="-89.4"
                />
              </svg>
            </div>

            {/* Donut Legend */}
            <div className="space-y-1.5 text-[11px] font-medium text-gray-700 flex-1">
              <div className="flex justify-between items-center">
                <span className="flex items-center gap-1.5">
                  <span className="w-2 h-2 rounded-full bg-blue-500" /> NEET
                </span>
                <span className="font-bold text-gray-900">40.2% <span className="text-[10px] text-gray-400 font-normal">(987,654)</span></span>
              </div>
              <div className="flex justify-between items-center">
                <span className="flex items-center gap-1.5">
                  <span className="w-2 h-2 rounded-full bg-emerald-500" /> JEE Main
                </span>
                <span className="font-bold text-gray-900">28.1% <span className="text-[10px] text-gray-400 font-normal">(689,124)</span></span>
              </div>
              <div className="flex justify-between items-center">
                <span className="flex items-center gap-1.5">
                  <span className="w-2 h-2 rounded-full bg-amber-500" /> JEE Advanced
                </span>
                <span className="font-bold text-gray-900">12.4% <span className="text-[10px] text-gray-400 font-normal">(305,654)</span></span>
              </div>
              <div className="flex justify-between items-center">
                <span className="flex items-center gap-1.5">
                  <span className="w-2 h-2 rounded-full bg-pink-500" /> CUET
                </span>
                <span className="font-bold text-gray-900">8.7% <span className="text-[10px] text-gray-400 font-normal">(213,654)</span></span>
              </div>
              <div className="flex justify-between items-center">
                <span className="flex items-center gap-1.5">
                  <span className="w-2 h-2 rounded-full bg-slate-400" /> Other Exams
                </span>
                <span className="font-bold text-gray-900">10.6% <span className="text-[10px] text-gray-400 font-normal">(258,123)</span></span>
              </div>
            </div>
          </div>
        </div>

        {/* Chart 3: Daily Active Users Bar Chart (3 cols) */}
        <div className="lg:col-span-3 bg-white p-5 rounded-2xl border border-gray-200 shadow-sm space-y-4">
          <div className="flex items-center justify-between">
            <h3 className="text-sm font-bold text-gray-900">Daily Active Users</h3>
            <button className="flex items-center gap-1 px-2 py-0.5 bg-gray-50 border border-gray-200 rounded text-[10px] font-semibold text-gray-600">
              <span>Last 30 Days</span>
              <ChevronDown className="w-3 h-3" />
            </button>
          </div>

          <div className="flex items-baseline justify-between">
            <span className="text-xl font-bold text-gray-900">95,385</span>
            <span className="inline-flex items-center text-[10px] font-bold text-emerald-600 bg-emerald-50 px-1.5 py-0.5 rounded-full">
              <ArrowUpRight className="w-3 h-3 mr-0.5" /> 14.6%
            </span>
          </div>

          {/* SVG Bar Chart */}
          <div className="h-32 w-full pt-1">
            <svg viewBox="0 0 200 80" className="w-full h-full">
              {[40, 50, 45, 60, 55, 70, 65, 50, 60, 75, 70, 65, 80, 85, 90, 70, 65, 80, 85, 75, 70, 95, 80, 85, 90, 75, 80].map((h, i) => (
                <rect
                  key={i}
                  x={i * 7 + 2}
                  y={80 - h * 0.7}
                  width="4.5"
                  height={h * 0.7}
                  fill="#6366f1"
                  rx="1.5"
                />
              ))}
            </svg>
          </div>

          <div className="flex justify-between text-[9px] text-gray-400 font-medium">
            <span>18 May</span>
            <span>28 May</span>
            <span>07 Jun</span>
            <span>17 Jun</span>
          </div>
        </div>
      </div>

      {/* ROW 3: 4 TABLES/LISTS (Recent Registrations, Recent Teacher Tests, Most Attempted Topics, System Health) */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {/* Panel 1: Recent Registrations */}
        <div className="bg-white p-4 rounded-2xl border border-gray-200 shadow-sm space-y-3">
          <div className="flex items-center justify-between pb-2 border-b border-gray-100">
            <h3 className="text-xs font-bold text-gray-900">Recent Registrations</h3>
            <button className="text-[10px] font-semibold text-blue-600 hover:underline">View All</button>
          </div>

          <div className="space-y-2.5">
            {[
              { name: 'Rohan Kumar', role: 'Student', time: '2 min ago', avatar: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=80&auto=format&fit=crop&q=80' },
              { name: 'Priya Sharma', role: 'Student', time: '5 min ago', avatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=80&auto=format&fit=crop&q=80' },
              { name: 'Arjun Singh', role: 'Student', time: '8 min ago', avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=80&auto=format&fit=crop&q=80' },
              { name: 'Neha Gupta', role: 'Student', time: '15 min ago', avatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=80&auto=format&fit=crop&q=80' },
              { name: 'Dr. Amit Verma', role: 'Teacher', time: '18 min ago', avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=80&auto=format&fit=crop&q=80' },
            ].map((u, i) => (
              <div key={i} className="flex items-center justify-between text-xs">
                <div className="flex items-center gap-2.5">
                  <img src={u.avatar} alt={u.name} className="w-7 h-7 rounded-full object-cover" />
                  <div>
                    <span className="font-bold text-gray-800 block text-xs leading-tight">{u.name}</span>
                    <span className="text-[10px] text-gray-400 block">{u.role}</span>
                  </div>
                </div>
                <span className="text-[10px] text-gray-400 font-medium">{u.time}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Panel 2: Recent Teacher Tests */}
        <div className="bg-white p-4 rounded-2xl border border-gray-200 shadow-sm space-y-3">
          <div className="flex items-center justify-between pb-2 border-b border-gray-100">
            <h3 className="text-xs font-bold text-gray-900">Recent Teacher Tests</h3>
            <button className="text-[10px] font-semibold text-blue-600 hover:underline">View All</button>
          </div>

          <div className="space-y-2.5">
            {[
              { title: 'JEE Main Full Mock Test 05', author: 'By Rahul Verma', status: 'Active', badgeStyle: 'bg-emerald-50 text-emerald-600 border-emerald-200' },
              { title: 'NEET Biology Chapter Test', author: 'By Dr. Neha Sharma', status: 'Active', badgeStyle: 'bg-emerald-50 text-emerald-600 border-emerald-200' },
              { title: 'Physics Daily Challenge #12', author: 'By Amit Singh', status: 'Scheduled', badgeStyle: 'bg-blue-50 text-blue-600 border-blue-200' },
              { title: 'Chemistry Weekly Test', author: 'By Pooja Patel', status: 'Completed', badgeStyle: 'bg-gray-100 text-gray-600 border-gray-200' },
              { title: 'Maths Topic Test - Calculus', author: 'By Vikram Joshi', status: 'Active', badgeStyle: 'bg-emerald-50 text-emerald-600 border-emerald-200' },
            ].map((t, i) => (
              <div key={i} className="flex items-center justify-between text-xs">
                <div>
                  <span className="font-bold text-gray-800 block text-xs leading-tight">{t.title}</span>
                  <span className="text-[10px] text-gray-400 block">{t.author}</span>
                </div>
                <span className={`text-[10px] font-bold px-2 py-0.5 rounded border ${t.badgeStyle}`}>
                  {t.status}
                </span>
              </div>
            ))}
          </div>
        </div>

        {/* Panel 3: Most Attempted Topics */}
        <div className="bg-white p-4 rounded-2xl border border-gray-200 shadow-sm space-y-3">
          <div className="flex items-center justify-between pb-2 border-b border-gray-100">
            <h3 className="text-xs font-bold text-gray-900">Most Attempted Topics</h3>
            <button className="text-[10px] font-semibold text-blue-600 hover:underline">View All</button>
          </div>

          <div className="space-y-2.5">
            {[
              { rank: 1, name: 'Mechanics', subject: 'Physics', count: '124,569' },
              { rank: 2, name: 'Organic Chemistry', subject: 'Chemistry', count: '98,214' },
              { rank: 3, name: 'Human Physiology', subject: 'Biology', count: '86,542' },
              { rank: 4, name: 'Coordinate Geometry', subject: 'Maths', count: '78,125' },
              { rank: 5, name: 'Thermodynamics', subject: 'Physics', count: '66,214' },
            ].map((tp, i) => (
              <div key={i} className="flex items-center justify-between text-xs">
                <div className="flex items-center gap-2.5">
                  <span className="w-5 h-5 font-bold text-xs text-gray-500 flex items-center justify-center">
                    {tp.rank}
                  </span>
                  <div>
                    <span className="font-bold text-gray-800 block text-xs leading-tight">{tp.name}</span>
                    <span className="text-[10px] text-gray-400 block">{tp.subject}</span>
                  </div>
                </div>
                <span className="text-xs font-bold text-gray-700">{tp.count}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Panel 4: System Health */}
        <div className="bg-white p-4 rounded-2xl border border-gray-200 shadow-sm space-y-3">
          <div className="flex items-center justify-between pb-2 border-b border-gray-100">
            <h3 className="text-xs font-bold text-gray-900">System Health</h3>
            <button className="text-[10px] font-semibold text-blue-600 hover:underline">View All</button>
          </div>

          <div className="space-y-2.5">
            {[
              'API Status',
              'Database',
              'Storage',
              'Edge Functions',
              'Realtime',
              'Notifications',
            ].map((sys, i) => (
              <div key={i} className="flex items-center justify-between text-xs">
                <span className="text-xs font-semibold text-gray-700 flex items-center gap-1.5">
                  <span className="w-2 h-2 rounded-full bg-emerald-500" /> {sys}
                </span>
                <span className="text-[10px] font-bold text-emerald-600 bg-emerald-50 px-2 py-0.5 rounded border border-emerald-200">
                  Operational
                </span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* ROW 4: 3 BOTTOM INSIGHT PANELS (Question Quality Ring, Leaderboard, Activity Feed) */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        {/* Panel 1: Question Quality Overview (4 cols) */}
        <div className="lg:col-span-4 bg-white p-5 rounded-2xl border border-gray-200 shadow-sm space-y-4">
          <h3 className="text-sm font-bold text-gray-900">Question Quality Overview</h3>

          <div className="flex items-center gap-6">
            {/* SVG Donut Ring with Center Text */}
            <div className="relative w-32 h-32 flex-shrink-0 flex items-center justify-center">
              <svg viewBox="0 0 36 36" className="w-full h-full transform -rotate-90">
                <path
                  d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                  fill="none"
                  stroke="#10b981"
                  strokeWidth="4"
                  strokeDasharray="71.1, 100"
                />
                <path
                  d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                  fill="none"
                  stroke="#f59e0b"
                  strokeWidth="4"
                  strokeDasharray="12.5, 100"
                  strokeDashoffset="-71.1"
                />
                <path
                  d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                  fill="none"
                  stroke="#f97316"
                  strokeWidth="4"
                  strokeDasharray="7.9, 100"
                  strokeDashoffset="-83.6"
                />
                <path
                  d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                  fill="none"
                  stroke="#ec4899"
                  strokeWidth="4"
                  strokeDasharray="3.7, 100"
                  strokeDashoffset="-91.5"
                />
                <path
                  d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                  fill="none"
                  stroke="#ef4444"
                  strokeWidth="4"
                  strokeDasharray="2.6, 100"
                  strokeDashoffset="-95.2"
                />
                <path
                  d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                  fill="none"
                  stroke="#94a3b8"
                  strokeWidth="4"
                  strokeDasharray="2.2, 100"
                  strokeDashoffset="-97.8"
                />
              </svg>
              <div className="absolute text-center leading-none">
                <span className="text-base font-bold text-gray-900 block">1.25M</span>
                <span className="text-[9px] text-gray-400 uppercase font-semibold">Total</span>
              </div>
            </div>

            {/* Legend Breakdown */}
            <div className="space-y-1.5 text-[11px] font-medium text-gray-700 flex-1">
              <div className="flex justify-between items-center">
                <span className="flex items-center gap-1.5">
                  <span className="w-2 h-2 rounded-full bg-emerald-500" /> Approved
                </span>
                <span className="font-bold text-gray-900">892,456 <span className="text-[10px] text-gray-400 font-normal">(71.1%)</span></span>
              </div>
              <div className="flex justify-between items-center">
                <span className="flex items-center gap-1.5">
                  <span className="w-2 h-2 rounded-full bg-amber-500" /> Pending Review
                </span>
                <span className="font-bold text-gray-900">156,325 <span className="text-[10px] text-gray-400 font-normal">(12.5%)</span></span>
              </div>
              <div className="flex justify-between items-center">
                <span className="flex items-center gap-1.5">
                  <span className="w-2 h-2 rounded-full bg-orange-500" /> AI Review
                </span>
                <span className="font-bold text-gray-900">98,654 <span className="text-[10px] text-gray-400 font-normal">(7.9%)</span></span>
              </div>
              <div className="flex justify-between items-center">
                <span className="flex items-center gap-1.5">
                  <span className="w-2 h-2 rounded-full bg-pink-500" /> Reported
                </span>
                <span className="font-bold text-gray-900">45,876 <span className="text-[10px] text-gray-400 font-normal">(3.7%)</span></span>
              </div>
              <div className="flex justify-between items-center">
                <span className="flex items-center gap-1.5">
                  <span className="w-2 h-2 rounded-full bg-rose-500" /> Rejected
                </span>
                <span className="font-bold text-gray-900">32,373 <span className="text-[10px] text-gray-400 font-normal">(2.6%)</span></span>
              </div>
              <div className="flex justify-between items-center">
                <span className="flex items-center gap-1.5">
                  <span className="w-2 h-2 rounded-full bg-slate-400" /> Draft
                </span>
                <span className="font-bold text-gray-900">31,456 <span className="text-[10px] text-gray-400 font-normal">(2.2%)</span></span>
              </div>
            </div>
          </div>
        </div>

        {/* Panel 2: Leaderboard (This Week) (4 cols) */}
        <div className="lg:col-span-4 bg-white p-5 rounded-2xl border border-gray-200 shadow-sm space-y-4">
          <div className="flex items-center justify-between pb-2 border-b border-gray-100">
            <h3 className="text-sm font-bold text-gray-900">Leaderboard (This Week)</h3>
            <button className="text-[10px] font-semibold text-blue-600 hover:underline">View All</button>
          </div>

          <div className="space-y-2.5">
            {[
              { rank: 1, name: 'Arjun Singh', pts: '248,750 Pts', avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=80&auto=format&fit=crop&q=80' },
              { rank: 2, name: 'Rohan Kumar', pts: '215,680 Pts', avatar: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=80&auto=format&fit=crop&q=80' },
              { rank: 3, name: 'Priya Sharma', pts: '198,450 Pts', avatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=80&auto=format&fit=crop&q=80' },
              { rank: 4, name: 'Neha Gupta', pts: '178,250 Pts', avatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=80&auto=format&fit=crop&q=80' },
              { rank: 5, name: 'Aditya Verma', pts: '165,230 Pts', avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=80&auto=format&fit=crop&q=80' },
            ].map((st, i) => (
              <div key={i} className="flex items-center justify-between text-xs">
                <div className="flex items-center gap-3">
                  <span className="w-5 h-5 font-bold text-xs text-gray-500 flex items-center justify-center">
                    {st.rank === 1 ? '🥇' : st.rank === 2 ? '🥈' : st.rank === 3 ? '🥉' : st.rank}
                  </span>
                  <img src={st.avatar} alt={st.name} className="w-7 h-7 rounded-full object-cover" />
                  <span className="font-bold text-gray-800 text-xs">{st.name}</span>
                </div>
                <span className="text-xs font-bold text-gray-700">{st.pts}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Panel 3: Platform Activity Feed (4 cols) */}
        <div className="lg:col-span-4 bg-white p-5 rounded-2xl border border-gray-200 shadow-sm space-y-4">
          <div className="flex items-center justify-between pb-2 border-b border-gray-100">
            <h3 className="text-sm font-bold text-gray-900">Platform Activity Feed</h3>
            <button className="text-[10px] font-semibold text-blue-600 hover:underline">View All</button>
          </div>

          <div className="space-y-3">
            {[
              { text: 'New test "JEE Main Mock Test 06" created by Rahul Verma', time: '2 min ago', icon: FileText, color: 'text-purple-600 bg-purple-50' },
              { text: '500 new questions added in NEET Physics by Admin', time: '15 min ago', icon: HelpCircle, color: 'text-blue-600 bg-blue-50' },
              { text: 'Student Arjun Singh scored 98.5% in JEE Main Mock Test 05', time: '30 min ago', icon: Award, color: 'text-emerald-600 bg-emerald-50' },
              { text: 'Teacher Dr. Neha Sharma created a new quiz', time: '1 hour ago', icon: Zap, color: 'text-amber-600 bg-amber-50' },
              { text: 'Subscription plan "Premium Yearly" purchased by 25 students', time: '2 hours ago', icon: TrendingUp, color: 'text-indigo-600 bg-indigo-50' },
            ].map((act, i) => {
              const Icon = act.icon;
              return (
                <div key={i} className="flex items-start gap-2.5 text-xs">
                  <div className={`w-6 h-6 rounded-full flex items-center justify-center flex-shrink-0 mt-0.5 ${act.color}`}>
                    <Icon className="w-3.5 h-3.5" />
                  </div>
                  <div className="flex-1 leading-snug">
                    <p className="text-xs font-semibold text-gray-800">{act.text}</p>
                    <span className="text-[10px] text-gray-400 font-medium block mt-0.5">{act.time}</span>
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
