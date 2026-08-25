import React from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import {
  LayoutDashboard,
  Target,
  FileSpreadsheet,
  BookOpen,
  Award,
  Bookmark,
  AlertTriangle,
  History,
  Users,
  PlusCircle,
  Link as LinkIcon,
  BarChart3,
  Layers,
  FileUp,
  Settings,
  ShieldAlert,
} from 'lucide-react';

export const Sidebar: React.FC = () => {
  const location = useLocation();
  const navigate = useNavigate();

  const isTeacher = location.pathname.startsWith('/teacher');
  const isAdmin = location.pathname.startsWith('/admin');
  const isStudent = !isTeacher && !isAdmin;

  const studentNav = [
    { path: '/student', label: 'Dashboard', icon: LayoutDashboard },
    { path: '/student/practice', label: 'Custom Practice', icon: Target },
    { path: '/student/test', label: 'Custom Test', icon: FileSpreadsheet },
    { path: '/student/pyq', label: 'PYQ Question Bank', icon: BookOpen },
    { path: '/student/nta', label: 'NTA Abhyas Bank', icon: Layers },
    { path: '/student/teacher-tests', label: 'Teacher Tests', icon: Users },
    { path: '/student/leaderboard', label: 'Leaderboard', icon: Award },
    { path: '/student/analytics', label: 'My Analytics', icon: BarChart3 },
    { path: '/student/bookmarks', label: 'Bookmarks', icon: Bookmark },
    { path: '/student/mistakes', label: 'Mistake Book', icon: AlertTriangle },
    { path: '/student/history', label: 'Attempt History', icon: History },
  ];

  const teacherNav = [
    { path: '/teacher', label: 'Dashboard', icon: LayoutDashboard },
    { path: '/teacher/create-test', label: 'Create Test Wizard', icon: PlusCircle },
    { path: '/teacher/invitations', label: 'Test Invitations', icon: LinkIcon },
    { path: '/teacher/analytics', label: 'Student Performance', icon: BarChart3 },
    { path: '/teacher/questions', label: 'Question Bank', icon: BookOpen },
  ];

  const adminNav = [
    { path: '/admin', label: 'Admin Dashboard', icon: LayoutDashboard },
    { path: '/admin/taxonomy', label: 'Taxonomy Manager', icon: Layers },
    { path: '/admin/moderation', label: 'Question Moderation', icon: BookOpen },
    { path: '/admin/bulk-import', label: 'Bulk Question Import', icon: FileUp },
    { path: '/admin/teachers', label: 'Teacher Verification', icon: Users },
    { path: '/admin/students', label: 'Student Management', icon: Users },
    { path: '/admin/audit-logs', label: 'Audit Logs', icon: ShieldAlert },
    { path: '/admin/settings', label: 'Platform Settings', icon: Settings },
  ];

  const currentNav = isStudent ? studentNav : isTeacher ? teacherNav : adminNav;
  const portalName = isStudent ? 'Student Website' : isTeacher ? 'Teacher Platform' : 'Admin Console';

  return (
    <aside className="w-64 bg-slate-900/90 border-r border-slate-800 p-4 flex flex-col justify-between hidden md:flex min-h-[calc(100vh-61px)]">
      <div className="space-y-1">
        <div className="px-3 py-2 text-[11px] font-bold uppercase tracking-wider text-slate-500">
          {portalName} Navigation
        </div>
        {currentNav.map((item) => {
          const Icon = item.icon;
          const isActive =
            location.pathname === item.path ||
            (item.path !== '/student' && item.path !== '/teacher' && item.path !== '/admin' && location.pathname.startsWith(item.path));
          return (
            <button
              key={item.path}
              onClick={() => navigate(item.path)}
              className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-xs font-semibold transition-all ${
                isActive
                  ? 'bg-blue-600/10 text-blue-400 border border-blue-500/20 shadow-sm'
                  : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/50'
              }`}
            >
              <Icon className={`w-4 h-4 ${isActive ? 'text-blue-400' : 'text-slate-400'}`} />
              <span>{item.label}</span>
            </button>
          );
        })}
      </div>

      <div className="pt-4 border-t border-slate-800/80 text-[11px] text-slate-500 text-center">
        <p className="font-mono text-[10px] text-blue-400">{location.pathname}</p>
        <p className="text-[10px] text-slate-600">Cosmyra Multi-App Architecture</p>
      </div>
    </aside>
  );
};
