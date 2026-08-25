import React from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import {
  LayoutDashboard,
  Target,
  FileSpreadsheet,
  BookOpen,
  HelpCircle,
  Zap,
  Award,
  Bookmark,
  AlertTriangle,
  History,
  Users,
  FileText,
  BarChart2,
  PieChart,
  Grid,
  Sun,
  ChevronDown,
  Newspaper,
  BookCheck,
  User,
} from 'lucide-react';

export const StudentSidebar: React.FC = () => {
  const location = useLocation();
  const navigate = useNavigate();

  const isNavActive = (path: string) => {
    if (path === '/student') return location.pathname === '/student';
    return location.pathname.startsWith(path);
  };

  return (
    <aside className="w-64 bg-white text-gray-700 border-r border-gray-200 flex flex-col justify-between min-h-[calc(100vh-65px)] z-20 font-sans select-none">
      <div className="p-3 space-y-5 overflow-y-auto max-h-[calc(100vh-120px)] custom-scrollbar">
        {/* Active Top Dashboard Button */}
        <div>
          <button
            onClick={() => navigate('/student')}
            className={`w-full flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-xs font-bold transition-all ${
              isNavActive('/student') && location.pathname === '/student'
                ? 'bg-purple-50 text-indigo-600 shadow-sm border border-purple-100'
                : 'text-gray-600 hover:text-gray-900 hover:bg-gray-50'
            }`}
          >
            <LayoutDashboard className="w-4 h-4 text-indigo-600" />
            <span>Dashboard</span>
          </button>
        </div>

        {/* Section: PRACTICE */}
        <div className="space-y-1">
          <div className="px-3 text-[10px] font-bold uppercase tracking-wider text-gray-400 mb-1">
            Practice
          </div>

          <button
            onClick={() => navigate('/student/practice')}
            className={`w-full flex items-center gap-3 px-3 py-2 rounded-xl text-xs font-semibold transition-colors ${
              isNavActive('/student/practice')
                ? 'bg-purple-50 text-indigo-600 font-bold'
                : 'text-gray-600 hover:text-gray-900 hover:bg-gray-50'
            }`}
          >
            <Target className="w-4 h-4 text-gray-400" />
            <span>Custom Practice</span>
          </button>

          <button
            onClick={() => navigate('/student/test')}
            className={`w-full flex items-center gap-3 px-3 py-2 rounded-xl text-xs font-semibold transition-colors ${
              isNavActive('/student/test')
                ? 'bg-purple-50 text-indigo-600 font-bold'
                : 'text-gray-600 hover:text-gray-900 hover:bg-gray-50'
            }`}
          >
            <FileSpreadsheet className="w-4 h-4 text-gray-400" />
            <span>Custom Test</span>
          </button>

          <button
            onClick={() => navigate('/student/pyq')}
            className={`w-full flex items-center justify-between px-3 py-2 rounded-xl text-xs font-semibold transition-colors ${
              isNavActive('/student/pyq')
                ? 'bg-purple-50 text-indigo-600 font-bold'
                : 'text-gray-600 hover:text-gray-900 hover:bg-gray-50'
            }`}
          >
            <div className="flex items-center gap-3">
              <BookOpen className="w-4 h-4 text-gray-400" />
              <span>PYQ Practice</span>
            </div>
            <span className="px-1.5 py-0.5 rounded bg-purple-100 text-indigo-700 text-[9px] font-bold">
              New
            </span>
          </button>

          <button
            onClick={() => navigate('/student/nta')}
            className="w-full flex items-center justify-between px-3 py-2 rounded-xl text-xs font-semibold text-gray-600 hover:text-gray-900 hover:bg-gray-50 transition-colors"
          >
            <div className="flex items-center gap-3">
              <Grid className="w-4 h-4 text-gray-400" />
              <span>NTA Questions</span>
            </div>
            <span className="px-1.5 py-0.5 rounded bg-purple-100 text-indigo-700 text-[9px] font-bold">
              New
            </span>
          </button>

          <button
            onClick={() => navigate('/student/practice')}
            className="w-full flex items-center gap-3 px-3 py-2 rounded-xl text-xs font-semibold text-gray-600 hover:text-gray-900 hover:bg-gray-50 transition-colors"
          >
            <Zap className="w-4 h-4 text-gray-400" />
            <span>Daily Quiz</span>
          </button>
        </div>

        {/* Section: TESTS */}
        <div className="space-y-1">
          <div className="px-3 text-[10px] font-bold uppercase tracking-wider text-gray-400 mb-1">
            Tests
          </div>

          <button
            onClick={() => navigate('/student/test')}
            className="w-full flex items-center gap-3 px-3 py-2 rounded-xl text-xs font-semibold text-gray-600 hover:text-gray-900 hover:bg-gray-50 transition-colors"
          >
            <FileText className="w-4 h-4 text-gray-400" />
            <span>All Tests</span>
          </button>

          <button
            onClick={() => navigate('/student/test')}
            className="w-full flex items-center gap-3 px-3 py-2 rounded-xl text-xs font-semibold text-gray-600 hover:text-gray-900 hover:bg-gray-50 transition-colors"
          >
            <FileSpreadsheet className="w-4 h-4 text-gray-400" />
            <span>Mock Tests</span>
          </button>

          <button
            onClick={() => navigate('/student/teacher-tests')}
            className="w-full flex items-center justify-between px-3 py-2 rounded-xl text-xs font-semibold text-gray-600 hover:text-gray-900 hover:bg-gray-50 transition-colors"
          >
            <div className="flex items-center gap-3">
              <Users className="w-4 h-4 text-gray-400" />
              <span>Teacher Tests</span>
            </div>
            <span className="w-4 h-4 rounded-full bg-rose-100 text-rose-600 text-[10px] font-bold flex items-center justify-center">
              3
            </span>
          </button>

          <button
            onClick={() => navigate('/student/history')}
            className="w-full flex items-center gap-3 px-3 py-2 rounded-xl text-xs font-semibold text-gray-600 hover:text-gray-900 hover:bg-gray-50 transition-colors"
          >
            <History className="w-4 h-4 text-gray-400" />
            <span>My Attempts</span>
          </button>
        </div>

        {/* Section: ANALYTICS */}
        <div className="space-y-1">
          <div className="px-3 text-[10px] font-bold uppercase tracking-wider text-gray-400 mb-1">
            Analytics
          </div>

          <button
            onClick={() => navigate('/student/analytics')}
            className="w-full flex items-center gap-3 px-3 py-2 rounded-xl text-xs font-semibold text-gray-600 hover:text-gray-900 hover:bg-gray-50 transition-colors"
          >
            <BarChart2 className="w-4 h-4 text-gray-400" />
            <span>Performance</span>
          </button>

          <button
            onClick={() => navigate('/student/analytics')}
            className="w-full flex items-center gap-3 px-3 py-2 rounded-xl text-xs font-semibold text-gray-600 hover:text-gray-900 hover:bg-gray-50 transition-colors"
          >
            <PieChart className="w-4 h-4 text-gray-400" />
            <span>Chapter-wise</span>
          </button>

          <button
            onClick={() => navigate('/student/analytics')}
            className="w-full flex items-center gap-3 px-3 py-2 rounded-xl text-xs font-semibold text-gray-600 hover:text-gray-900 hover:bg-gray-50 transition-colors"
          >
            <BookOpen className="w-4 h-4 text-gray-400" />
            <span>Subject-wise</span>
          </button>

          <button
            onClick={() => navigate('/student/analytics')}
            className="w-full flex items-center gap-3 px-3 py-2 rounded-xl text-xs font-semibold text-gray-600 hover:text-gray-900 hover:bg-gray-50 transition-colors"
          >
            <Grid className="w-4 h-4 text-gray-400" />
            <span>Topic-wise</span>
          </button>

          <button
            onClick={() => navigate('/student/analytics')}
            className="w-full flex items-center gap-3 px-3 py-2 rounded-xl text-xs font-semibold text-gray-600 hover:text-gray-900 hover:bg-gray-50 transition-colors"
          >
            <AlertTriangle className="w-4 h-4 text-gray-400" />
            <span>Weak Areas</span>
          </button>
        </div>

        {/* Section: MY SPACE */}
        <div className="space-y-1">
          <div className="px-3 text-[10px] font-bold uppercase tracking-wider text-gray-400 mb-1">
            My Space
          </div>

          <button
            onClick={() => navigate('/student/bookmarks')}
            className="w-full flex items-center justify-between px-3 py-2 rounded-xl text-xs font-semibold text-gray-600 hover:text-gray-900 hover:bg-gray-50 transition-colors"
          >
            <div className="flex items-center gap-3">
              <Bookmark className="w-4 h-4 text-gray-400" />
              <span>Bookmarks</span>
            </div>
            <span className="text-[10px] font-bold text-gray-400">26</span>
          </button>

          <button
            onClick={() => navigate('/student/mistakes')}
            className="w-full flex items-center justify-between px-3 py-2 rounded-xl text-xs font-semibold text-gray-600 hover:text-gray-900 hover:bg-gray-50 transition-colors"
          >
            <div className="flex items-center gap-3">
              <AlertTriangle className="w-4 h-4 text-gray-400" />
              <span>My Mistakes</span>
            </div>
            <span className="text-[10px] font-bold text-gray-400">42</span>
          </button>

          <button
            onClick={() => navigate('/student')}
            className="w-full flex items-center gap-3 px-3 py-2 rounded-xl text-xs font-semibold text-gray-600 hover:text-gray-900 hover:bg-gray-50 transition-colors"
          >
            <BookCheck className="w-4 h-4 text-gray-400" />
            <span>Study Plan</span>
          </button>

          <button
            onClick={() => navigate('/student/leaderboard')}
            className={`w-full flex items-center gap-3 px-3 py-2 rounded-xl text-xs font-semibold transition-colors ${
              isNavActive('/student/leaderboard')
                ? 'bg-purple-50 text-indigo-600 font-bold'
                : 'text-gray-600 hover:text-gray-900 hover:bg-gray-50'
            }`}
          >
            <Award className="w-4 h-4 text-gray-400" />
            <span>Leaderboard</span>
          </button>

          <button
            onClick={() => navigate('/student/profile')}
            className={`w-full flex items-center gap-3 px-3 py-2 rounded-xl text-xs font-semibold transition-colors ${
              isNavActive('/student/profile')
                ? 'bg-purple-50 text-indigo-600 font-bold'
                : 'text-gray-600 hover:text-gray-900 hover:bg-gray-50'
            }`}
          >
            <User className="w-4 h-4 text-gray-400" />
            <span>My Profile</span>
          </button>
        </div>

        {/* Section: MORE */}
        <div className="space-y-1">
          <div className="px-3 text-[10px] font-bold uppercase tracking-wider text-gray-400 mb-1">
            More
          </div>

          <button className="w-full flex items-center gap-3 px-3 py-2 rounded-xl text-xs font-semibold text-gray-600 hover:text-gray-900 hover:bg-gray-50 transition-colors">
            <Newspaper className="w-4 h-4 text-gray-400" />
            <span>News & Updates</span>
          </button>

          <button className="w-full flex items-center gap-3 px-3 py-2 rounded-xl text-xs font-semibold text-gray-600 hover:text-gray-900 hover:bg-gray-50 transition-colors">
            <HelpCircle className="w-4 h-4 text-gray-400" />
            <span>Help & Support</span>
          </button>
        </div>
      </div>

      {/* Light Mode Selector Footer */}
      <div className="p-3 border-t border-gray-100">
        <button className="w-full flex items-center justify-between px-3 py-2 border border-gray-200 rounded-xl text-xs font-semibold text-gray-700 bg-gray-50 hover:bg-white transition-colors">
          <div className="flex items-center gap-2">
            <Sun className="w-4 h-4 text-amber-500" />
            <span>Light</span>
          </div>
          <ChevronDown className="w-3.5 h-3.5 text-gray-400" />
        </button>
      </div>
    </aside>
  );
};
