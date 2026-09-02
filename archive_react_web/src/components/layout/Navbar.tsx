import React from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { Sparkles, Shield, GraduationCap, User, Bell, ChevronDown } from 'lucide-react';

interface NavbarProps {
  selectedExam: string;
  setSelectedExam: (exam: string) => void;
  userName?: string;
}

export const Navbar: React.FC<NavbarProps> = ({
  selectedExam,
  setSelectedExam,
  userName = 'Mahboob Hasan',
}) => {
  const location = useLocation();
  const navigate = useNavigate();

  const isTeacher = location.pathname.startsWith('/teacher');
  const isAdmin = location.pathname.startsWith('/admin');
  const isStudent = !isTeacher && !isAdmin;

  const currentRole = isTeacher ? 'teacher' : isAdmin ? 'admin' : 'student';

  return (
    <header className="sticky top-0 z-40 bg-slate-900/80 backdrop-blur-md border-b border-slate-800 px-4 lg:px-8 py-3 flex items-center justify-between">
      {/* Brand Logo */}
      <div
        onClick={() => navigate('/student')}
        className="flex items-center gap-3 cursor-pointer group"
      >
        <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-blue-600 via-indigo-500 to-purple-500 p-0.5 shadow-lg shadow-blue-500/20 group-hover:scale-105 transition-transform">
          <div className="w-full h-full bg-slate-950 rounded-[10px] flex items-center justify-center">
            <Sparkles className="w-5 h-5 text-blue-400 animate-pulse" />
          </div>
        </div>
        <div>
          <h1 className="text-xl font-extrabold bg-gradient-to-r from-blue-400 via-indigo-300 to-purple-400 bg-clip-text text-transparent">
            COSMYRA
          </h1>
          <span className="text-[10px] tracking-wider text-slate-400 uppercase font-semibold">
            NEET • JEE • EXAM PLATFORM
          </span>
        </div>
      </div>

      {/* Product Portal URL Navigation Tabs */}
      <div className="hidden md:flex items-center gap-4">
        <div className="bg-slate-950/80 p-1 rounded-xl border border-slate-800 flex items-center gap-1">
          <button
            onClick={() => navigate('/student')}
            className={`flex items-center gap-1.5 px-3.5 py-1.5 rounded-lg text-xs font-semibold transition-all ${
              isStudent
                ? 'bg-blue-600 text-white shadow-md shadow-blue-600/30'
                : 'text-slate-400 hover:text-slate-200'
            }`}
          >
            <GraduationCap className="w-3.5 h-3.5" />
            Student App (/student)
          </button>
          <button
            onClick={() => navigate('/teacher')}
            className={`flex items-center gap-1.5 px-3.5 py-1.5 rounded-lg text-xs font-semibold transition-all ${
              isTeacher
                ? 'bg-purple-600 text-white shadow-md shadow-purple-600/30'
                : 'text-slate-400 hover:text-slate-200'
            }`}
          >
            <User className="w-3.5 h-3.5" />
            Teacher Portal (/teacher)
          </button>
          <button
            onClick={() => navigate('/admin')}
            className={`flex items-center gap-1.5 px-3.5 py-1.5 rounded-lg text-xs font-semibold transition-all ${
              isAdmin
                ? 'bg-emerald-600 text-white shadow-md shadow-emerald-600/30'
                : 'text-slate-400 hover:text-slate-200'
            }`}
          >
            <Shield className="w-3.5 h-3.5" />
            Admin Console (/admin)
          </button>
        </div>

        {/* Target Exam Dropdown */}
        {isStudent && (
          <div className="relative">
            <select
              value={selectedExam}
              onChange={(e) => setSelectedExam(e.target.value)}
              className="bg-slate-950 text-slate-200 text-xs font-semibold px-3 py-1.5 pr-8 rounded-xl border border-slate-800 focus:outline-none focus:border-blue-500 appearance-none cursor-pointer"
            >
              <option value="NEET UG">NEET UG</option>
              <option value="JEE Main">JEE Main</option>
              <option value="JEE Advanced">JEE Advanced</option>
              <option value="CUET">CUET</option>
            </select>
            <ChevronDown className="w-3.5 h-3.5 text-slate-400 absolute right-2.5 top-2.5 pointer-events-none" />
          </div>
        )}
      </div>

      {/* Profile & Notifications */}
      <div className="flex items-center gap-3">
        <button className="p-2 rounded-xl bg-slate-800/60 hover:bg-slate-800 text-slate-400 hover:text-slate-200 transition-colors relative">
          <Bell className="w-4 h-4" />
          <span className="w-2 h-2 rounded-full bg-blue-500 absolute top-1.5 right-1.5 animate-ping" />
        </button>

        <div className="flex items-center gap-2 pl-2 border-l border-slate-800">
          <div className="w-8 h-8 rounded-full bg-gradient-to-tr from-blue-500 to-indigo-600 flex items-center justify-center font-bold text-xs text-white shadow-md">
            {userName.slice(0, 2).toUpperCase()}
          </div>
          <div className="hidden lg:block text-left">
            <p className="text-xs font-semibold text-slate-200 leading-tight">{userName}</p>
            <p className="text-[10px] text-slate-400 capitalize">{currentRole} Portal</p>
          </div>
        </div>
      </div>
    </header>
  );
};
