import React from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import {
  LayoutDashboard,
  HelpCircle,
  BookOpen,
  Layers,
  FileCheck,
  Tag,
  FileSpreadsheet,
  Users,
  Award,
  BarChart2,
  FileText,
  Bell,
  CreditCard,
  Bot,
  Settings,
  ShieldCheck,
  Activity,
  ChevronDown,
  ChevronLeft,
  Sparkles,
} from 'lucide-react';

interface AdminSidebarProps {
  isCollapsed?: boolean;
  onToggleCollapse?: () => void;
}

export const AdminSidebar: React.FC<AdminSidebarProps> = ({
  isCollapsed = false,
  onToggleCollapse,
}) => {
  const location = useLocation();
  const navigate = useNavigate();

  const isNavActive = (path: string) => {
    if (path === '/admin') return location.pathname === '/admin';
    return location.pathname.startsWith(path);
  };

  return (
    <aside
      className={`bg-[#0F172A] text-slate-300 border-r border-slate-800 flex flex-col justify-between transition-all duration-200 ${
        isCollapsed ? 'w-16' : 'w-64'
      } min-h-screen z-40 select-none`}
    >
      <div>
        {/* Brand Header */}
        <div className="h-14 px-4 flex items-center gap-3 border-b border-slate-800/80">
          <div className="w-7 h-7 rounded-lg bg-blue-600 flex items-center justify-center text-white shadow-md shadow-blue-500/20 flex-shrink-0">
            <Sparkles className="w-4 h-4 fill-white" />
          </div>
          {!isCollapsed && (
            <span className="text-base font-bold text-white tracking-tight">ExamPrep Admin</span>
          )}
        </div>

        {/* Navigation Content List */}
        <div className="p-3 space-y-5 overflow-y-auto max-h-[calc(100vh-100px)] custom-scrollbar">
          {/* Main Dashboard Link */}
          <div>
            <button
              onClick={() => navigate('/admin')}
              className={`w-full flex items-center justify-between px-3 py-2.5 rounded-lg text-xs font-semibold transition-all ${
                isNavActive('/admin') && location.pathname === '/admin'
                  ? 'bg-blue-600 text-white shadow-md shadow-blue-600/30 font-bold'
                  : 'text-slate-400 hover:text-slate-100 hover:bg-slate-800/50'
              }`}
            >
              <div className="flex items-center gap-3">
                <LayoutDashboard className="w-4 h-4" />
                {!isCollapsed && <span>Dashboard</span>}
              </div>
            </button>
          </div>

          {/* Section: CONTENT MANAGEMENT */}
          <div className="space-y-1">
            {!isCollapsed && (
              <div className="px-3 text-[10px] font-bold uppercase tracking-wider text-slate-500 mb-1">
                Content Management
              </div>
            )}

            <button
              onClick={() => navigate('/admin/moderation')}
              className={`w-full flex items-center justify-between px-3 py-2 rounded-lg text-xs font-medium transition-colors ${
                isNavActive('/admin/moderation')
                  ? 'bg-slate-800 text-white font-semibold'
                  : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/40'
              }`}
            >
              <div className="flex items-center gap-3">
                <HelpCircle className="w-4 h-4 text-slate-400" />
                {!isCollapsed && <span>Questions</span>}
              </div>
              {!isCollapsed && <ChevronDown className="w-3.5 h-3.5 text-slate-500" />}
            </button>

            <button
              onClick={() => navigate('/admin/moderation')}
              className="w-full flex items-center gap-3 px-3 py-2 rounded-lg text-xs font-medium text-slate-400 hover:text-slate-200 hover:bg-slate-800/40 transition-colors"
            >
              <BookOpen className="w-4 h-4 text-slate-400" />
              {!isCollapsed && <span>PYQ Bank</span>}
            </button>

            <button
              onClick={() => navigate('/admin/moderation')}
              className="w-full flex items-center gap-3 px-3 py-2 rounded-lg text-xs font-medium text-slate-400 hover:text-slate-200 hover:bg-slate-800/40 transition-colors"
            >
              <FileCheck className="w-4 h-4 text-slate-400" />
              {!isCollapsed && <span>NTA Bank</span>}
            </button>

            <button
              onClick={() => navigate('/admin/taxonomy')}
              className={`w-full flex items-center gap-3 px-3 py-2 rounded-lg text-xs font-medium transition-colors ${
                isNavActive('/admin/taxonomy')
                  ? 'bg-slate-800 text-white font-semibold'
                  : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/40'
              }`}
            >
              <Layers className="w-4 h-4 text-slate-400" />
              {!isCollapsed && <span>Exams</span>}
            </button>

            <button
              onClick={() => navigate('/admin/taxonomy')}
              className="w-full flex items-center gap-3 px-3 py-2 rounded-lg text-xs font-medium text-slate-400 hover:text-slate-200 hover:bg-slate-800/40 transition-colors"
            >
              <BookOpen className="w-4 h-4 text-slate-400" />
              {!isCollapsed && <span>Subjects</span>}
            </button>

            <button
              onClick={() => navigate('/admin/taxonomy')}
              className="w-full flex items-center gap-3 px-3 py-2 rounded-lg text-xs font-medium text-slate-400 hover:text-slate-200 hover:bg-slate-800/40 transition-colors"
            >
              <Layers className="w-4 h-4 text-slate-400" />
              {!isCollapsed && <span>Chapters</span>}
            </button>

            <button
              onClick={() => navigate('/admin/taxonomy')}
              className="w-full flex items-center gap-3 px-3 py-2 rounded-lg text-xs font-medium text-slate-400 hover:text-slate-200 hover:bg-slate-800/40 transition-colors"
            >
              <Tag className="w-4 h-4 text-slate-400" />
              {!isCollapsed && <span>Topics</span>}
            </button>

            <button
              onClick={() => navigate('/admin/questions')}
              className={`w-full flex items-center justify-between px-3 py-2 rounded-lg text-xs font-medium transition-colors ${
                isNavActive('/admin/questions') || isNavActive('/admin/question-bank')
                  ? 'bg-gradient-to-r from-[#5D3EED] to-[#4F46E5] text-white font-bold shadow-md shadow-indigo-600/30'
                  : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/40'
              }`}
            >
              <div className="flex items-center gap-3">
                <HelpCircle className="w-4 h-4 text-purple-300" />
                {!isCollapsed && <span>Question Bank</span>}
              </div>
              {!isCollapsed && <ChevronDown className="w-3.5 h-3.5" />}
            </button>
          </div>

          {/* Section: TEST & QUIZ MANAGEMENT */}
          <div className="space-y-1">
            {!isCollapsed && (
              <div className="px-3 text-[10px] font-bold uppercase tracking-wider text-slate-500 mb-1">
                Test & Quiz Management
              </div>
            )}

            <button
              onClick={() => navigate('/admin')}
              className="w-full flex items-center justify-between px-3 py-2 rounded-lg text-xs font-medium text-slate-400 hover:text-slate-200 hover:bg-slate-800/40 transition-colors"
            >
              <div className="flex items-center gap-3">
                <FileSpreadsheet className="w-4 h-4 text-slate-400" />
                {!isCollapsed && <span>Tests</span>}
              </div>
              {!isCollapsed && <ChevronDown className="w-3.5 h-3.5 text-slate-500" />}
            </button>

            <button
              onClick={() => navigate('/admin')}
              className="w-full flex items-center gap-3 px-3 py-2 rounded-lg text-xs font-medium text-slate-400 hover:text-slate-200 hover:bg-slate-800/40 transition-colors"
            >
              <HelpCircle className="w-4 h-4 text-slate-400" />
              {!isCollapsed && <span>Quizzes</span>}
            </button>

            <button
              onClick={() => navigate('/admin')}
              className="w-full flex items-center gap-3 px-3 py-2 rounded-lg text-xs font-medium text-slate-400 hover:text-slate-200 hover:bg-slate-800/40 transition-colors"
            >
              <Users className="w-4 h-4 text-slate-400" />
              {!isCollapsed && <span>Teacher Tests</span>}
            </button>

            <button
              onClick={() => navigate('/admin')}
              className="w-full flex items-center gap-3 px-3 py-2 rounded-lg text-xs font-medium text-slate-400 hover:text-slate-200 hover:bg-slate-800/40 transition-colors"
            >
              <Tag className="w-4 h-4 text-slate-400" />
              {!isCollapsed && <span>Invitations</span>}
            </button>
          </div>

          {/* Section: USER MANAGEMENT */}
          <div className="space-y-1">
            {!isCollapsed && (
              <div className="px-3 text-[10px] font-bold uppercase tracking-wider text-slate-500 mb-1">
                User Management
              </div>
            )}

            <button
              onClick={() => navigate('/admin/students')}
              className="w-full flex items-center justify-between px-3 py-2 rounded-lg text-xs font-medium text-slate-400 hover:text-slate-200 hover:bg-slate-800/40 transition-colors"
            >
              <div className="flex items-center gap-3">
                <Users className="w-4 h-4 text-slate-400" />
                {!isCollapsed && <span>Students</span>}
              </div>
              {!isCollapsed && <ChevronDown className="w-3.5 h-3.5 text-slate-500" />}
            </button>

            <button
              onClick={() => navigate('/admin/teachers')}
              className="w-full flex items-center gap-3 px-3 py-2 rounded-lg text-xs font-medium text-slate-400 hover:text-slate-200 hover:bg-slate-800/40 transition-colors"
            >
              <Users className="w-4 h-4 text-slate-400" />
              {!isCollapsed && <span>Teachers</span>}
            </button>

            <button
              onClick={() => navigate('/admin')}
              className="w-full flex items-center gap-3 px-3 py-2 rounded-lg text-xs font-medium text-slate-400 hover:text-slate-200 hover:bg-slate-800/40 transition-colors"
            >
              <ShieldCheck className="w-4 h-4 text-slate-400" />
              {!isCollapsed && <span>Roles & Permissions</span>}
            </button>
          </div>

          {/* Section: ANALYTICS & REPORTS */}
          <div className="space-y-1">
            {!isCollapsed && (
              <div className="px-3 text-[10px] font-bold uppercase tracking-wider text-slate-500 mb-1">
                Analytics & Reports
              </div>
            )}

            <button
              onClick={() => navigate('/admin')}
              className="w-full flex items-center justify-between px-3 py-2 rounded-lg text-xs font-medium text-slate-400 hover:text-slate-200 hover:bg-slate-800/40 transition-colors"
            >
              <div className="flex items-center gap-3">
                <BarChart2 className="w-4 h-4 text-slate-400" />
                {!isCollapsed && <span>Analytics</span>}
              </div>
              {!isCollapsed && <ChevronDown className="w-3.5 h-3.5 text-slate-500" />}
            </button>

            <button
              onClick={() => navigate('/student/leaderboard')}
              className="w-full flex items-center gap-3 px-3 py-2 rounded-lg text-xs font-medium text-slate-400 hover:text-slate-200 hover:bg-slate-800/40 transition-colors"
            >
              <Award className="w-4 h-4 text-slate-400" />
              {!isCollapsed && <span>Leaderboard</span>}
            </button>

            <button
              onClick={() => navigate('/admin')}
              className="w-full flex items-center gap-3 px-3 py-2 rounded-lg text-xs font-medium text-slate-400 hover:text-slate-200 hover:bg-slate-800/40 transition-colors"
            >
              <FileText className="w-4 h-4 text-slate-400" />
              {!isCollapsed && <span>Reports</span>}
            </button>
          </div>

          {/* Section: OTHER */}
          <div className="space-y-1">
            {!isCollapsed && (
              <div className="px-3 text-[10px] font-bold uppercase tracking-wider text-slate-500 mb-1">
                Other
              </div>
            )}

            <button
              onClick={() => navigate('/admin')}
              className="w-full flex items-center gap-3 px-3 py-2 rounded-lg text-xs font-medium text-slate-400 hover:text-slate-200 hover:bg-slate-800/40 transition-colors"
            >
              <Bell className="w-4 h-4 text-slate-400" />
              {!isCollapsed && <span>Notifications</span>}
            </button>

            <button
              onClick={() => navigate('/admin/pricing')}
              className={`w-full flex items-center gap-3 px-3 py-2 rounded-lg text-xs font-medium transition-colors ${
                isNavActive('/admin/pricing')
                  ? 'bg-[#4F46E5] text-white font-bold'
                  : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/40'
              }`}
            >
              <CreditCard className="w-4 h-4 text-slate-400" />
              {!isCollapsed && <span>Pricing & Plans</span>}
            </button>

            <button
              onClick={() => navigate('/admin/offers')}
              className={`w-full flex items-center justify-between px-3 py-2 rounded-lg text-xs font-medium transition-colors ${
                isNavActive('/admin/offers') || isNavActive('/admin/coupons')
                  ? 'bg-gradient-to-r from-[#5D3EED] to-[#4F46E5] text-white font-bold shadow-md shadow-indigo-600/30'
                  : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/40'
              }`}
            >
              <div className="flex items-center gap-3">
                <Tag className="w-4 h-4" />
                {!isCollapsed && <span>Offers & Coupons</span>}
              </div>
              {!isCollapsed && <ChevronDown className="w-3.5 h-3.5" />}
            </button>

            <button
              onClick={() => navigate('/admin')}
              className="w-full flex items-center justify-between px-3 py-2 rounded-lg text-xs font-medium text-slate-400 hover:text-slate-200 hover:bg-slate-800/40 transition-colors"
            >
              <div className="flex items-center gap-3">
                <Bot className="w-4 h-4 text-slate-400" />
                {!isCollapsed && <span>AI Tools</span>}
              </div>
              {!isCollapsed && (
                <span className="px-1.5 py-0.5 rounded bg-blue-600 text-white text-[9px] font-bold uppercase">
                  New
                </span>
              )}
            </button>

            <button
              onClick={() => navigate('/admin/settings')}
              className={`w-full flex items-center gap-3 px-3 py-2 rounded-lg text-xs font-medium transition-colors ${
                isNavActive('/admin/settings')
                  ? 'bg-slate-800 text-white font-semibold'
                  : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/40'
              }`}
            >
              <Settings className="w-4 h-4 text-slate-400" />
              {!isCollapsed && <span>System Settings</span>}
            </button>

            <button
              onClick={() => navigate('/admin/audit-logs')}
              className="w-full flex items-center gap-3 px-3 py-2 rounded-lg text-xs font-medium text-slate-400 hover:text-slate-200 hover:bg-slate-800/40 transition-colors"
            >
              <ShieldCheck className="w-4 h-4 text-slate-400" />
              {!isCollapsed && <span>Audit Logs</span>}
            </button>

            <button
              onClick={() => navigate('/admin')}
              className="w-full flex items-center gap-3 px-3 py-2 rounded-lg text-xs font-medium text-slate-400 hover:text-slate-200 hover:bg-slate-800/40 transition-colors"
            >
              <ShieldCheck className="w-4 h-4 text-slate-400" />
              {!isCollapsed && <span>Security Center</span>}
            </button>

            <button
              onClick={() => navigate('/admin')}
              className="w-full flex items-center gap-3 px-3 py-2 rounded-lg text-xs font-medium text-slate-400 hover:text-slate-200 hover:bg-slate-800/40 transition-colors"
            >
              <Activity className="w-4 h-4 text-slate-400" />
              {!isCollapsed && <span>Platform Health</span>}
            </button>
          </div>
        </div>
      </div>

      {/* Collapse Toggle Footer */}
      <div className="p-3 border-t border-slate-800/80">
        <button
          onClick={onToggleCollapse}
          className="w-full flex items-center gap-2 px-3 py-2 rounded-lg text-xs font-medium text-slate-400 hover:text-slate-200 hover:bg-slate-800/40 transition-colors"
        >
          <ChevronLeft className={`w-4 h-4 transition-transform ${isCollapsed ? 'rotate-180' : ''}`} />
          {!isCollapsed && <span>Collapse</span>}
        </button>
      </div>
    </aside>
  );
};
