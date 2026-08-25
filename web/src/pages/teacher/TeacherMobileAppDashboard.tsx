import React from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Users,
  PlusCircle,
  BarChart3,
  FileSpreadsheet,
  CheckCircle2,
  Clock,
  Send,
  Sparkles,
  Bell,
  ChevronDown,
  ArrowRight,
  TrendingUp,
  Home,
  BookOpen,
  UserCheck,
} from 'lucide-react';

export const TeacherMobileAppDashboard: React.FC = () => {
  const navigate = useNavigate();

  return (
    <div className="min-h-screen bg-slate-950 py-6 px-2 sm:px-4 flex items-center justify-center font-sans text-slate-900">
      {/* Mobile Device Frame Container */}
      <div className="w-full max-w-[430px] bg-white rounded-[48px] shadow-2xl shadow-purple-950/50 border-[10px] border-slate-900 overflow-hidden flex flex-col min-h-[900px] relative select-none">
        {/* Status Bar */}
        <div className="pt-3 px-7 pb-2 flex items-center justify-between text-xs font-bold text-slate-900 bg-white">
          <span>9:41</span>
          <div className="w-24 h-4 bg-slate-900 rounded-full" />
          <div className="flex items-center gap-1 text-[10px]">
            <span>📶</span>
            <span>🔋</span>
          </div>
        </div>

        {/* App Bar (Header) */}
        <div className="px-5 py-3 flex items-center justify-between bg-white border-b border-slate-100">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-xl bg-purple-600 flex items-center justify-center text-white shadow-md shadow-purple-600/30">
              <Sparkles className="w-5 h-5 fill-white" />
            </div>
            <div>
              <span className="text-lg font-extrabold text-slate-900 leading-none block">Cosmyra</span>
              <span className="text-[9px] font-bold text-purple-600 uppercase block">Teacher App</span>
            </div>
          </div>

          <button className="p-2 text-slate-700 hover:bg-slate-100 rounded-xl relative transition-colors">
            <Bell className="w-5 h-5" />
            <span className="absolute top-1 right-1 bg-purple-600 text-white text-[10px] font-bold w-4 h-4 rounded-full flex items-center justify-center border-2 border-white">
              3
            </span>
          </button>
        </div>

        {/* Scrollable Main Content Area */}
        <div className="flex-1 overflow-y-auto px-4 py-4 space-y-4 bg-[#F8FAFC] custom-scrollbar">
          {/* User Greeting & Batch Selector */}
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <img
                src="https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&auto=format&fit=crop&q=80"
                alt="Dr. Neha Sharma"
                className="w-12 h-12 rounded-full object-cover border-2 border-purple-600 p-0.5"
              />
              <div>
                <h2 className="text-base font-extrabold text-slate-900">Dr. Neha Sharma 👋</h2>
                <div className="flex items-center gap-1 text-purple-600 text-xs font-bold mt-0.5">
                  <span>NEET Biology Faculty</span>
                  <ChevronDown className="w-3.5 h-3.5" />
                </div>
              </div>
            </div>

            <button
              onClick={() => navigate('/create-test')}
              className="px-3 py-2 bg-purple-600 hover:bg-purple-700 text-white text-xs font-bold rounded-2xl shadow-md shadow-purple-600/30 flex items-center gap-1.5"
            >
              <PlusCircle className="w-4 h-4" />
              <span>New Test</span>
            </button>
          </div>

          {/* 1. TEACHER OVERVIEW STATS CARD */}
          <div className="bg-gradient-to-br from-[#2E1065] via-[#3B0764] to-[#4C1D95] text-white rounded-3xl p-4 shadow-xl space-y-3">
            <div className="flex items-center justify-between border-b border-purple-700/50 pb-2">
              <span className="text-xs font-bold text-purple-200">Active Test Overview</span>
              <span className="text-[10px] font-bold text-emerald-400 bg-emerald-500/20 px-2 py-0.5 rounded-full border border-emerald-500/30">
                ● 2 Live Tests
              </span>
            </div>

            <div className="grid grid-cols-3 gap-2 text-center pt-1">
              <div className="bg-white/10 p-2.5 rounded-2xl border border-white/10">
                <span className="text-[9px] text-purple-300 block font-semibold">Total Students</span>
                <span className="text-base font-extrabold text-white block mt-0.5">1,248</span>
              </div>
              <div className="bg-white/10 p-2.5 rounded-2xl border border-white/10">
                <span className="text-[9px] text-purple-300 block font-semibold">Tests Created</span>
                <span className="text-base font-extrabold text-white block mt-0.5">38</span>
              </div>
              <div className="bg-white/10 p-2.5 rounded-2xl border border-white/10">
                <span className="text-[9px] text-purple-300 block font-semibold">Avg Batch Score</span>
                <span className="text-base font-extrabold text-emerald-400 block mt-0.5">74.2%</span>
              </div>
            </div>
          </div>

          {/* 2. RECENT TEACHER TESTS LIST */}
          <div className="bg-white p-4 rounded-3xl border border-slate-200/80 shadow-sm space-y-3">
            <div className="flex items-center justify-between">
              <h3 className="text-xs font-extrabold text-slate-900">Your Recent Tests</h3>
              <button onClick={() => navigate('/invitations')} className="text-[11px] font-bold text-purple-600 hover:underline">
                View All
              </button>
            </div>

            <div className="space-y-2.5">
              {[
                { title: 'NEET Biology Mock 05', code: 'NEET-BIO-882', status: 'Active', submissions: 342 },
                { title: 'Human Physiology Quiz', code: 'PHYSIO-492', status: 'Active', submissions: 189 },
                { title: 'Plant Kingdom Chapter Test', code: 'PLANT-104', status: 'Completed', submissions: 420 },
              ].map((t, i) => (
                <div key={i} className="p-3 rounded-2xl border border-slate-100 bg-slate-50/50 flex items-center justify-between text-xs">
                  <div>
                    <span className="font-extrabold text-slate-900 block leading-tight">{t.title}</span>
                    <span className="text-[10px] text-slate-400 font-semibold block mt-0.5">Code: {t.code} • {t.submissions} Submissions</span>
                  </div>

                  <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${
                    t.status === 'Active' ? 'bg-emerald-100 text-emerald-700' : 'bg-slate-200 text-slate-700'
                  }`}>
                    {t.status}
                  </span>
                </div>
              ))}
            </div>
          </div>

          {/* 3. STUDENT PERFORMANCE PREVIEW */}
          <div className="bg-white p-4 rounded-3xl border border-slate-200/80 shadow-sm space-y-3">
            <div className="flex items-center justify-between">
              <h3 className="text-xs font-extrabold text-slate-900">Top Performing Students</h3>
              <button onClick={() => navigate('/analytics')} className="text-[11px] font-bold text-purple-600 hover:underline">
                Analytics
              </button>
            </div>

            <div className="space-y-2">
              {[
                { name: 'Arjun Singh', score: '680 / 720', rank: 'Rank 1', avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=60&auto=format&fit=crop&q=80' },
                { name: 'Priya Sharma', score: '672 / 720', rank: 'Rank 2', avatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=60&auto=format&fit=crop&q=80' },
              ].map((st, i) => (
                <div key={i} className="flex items-center justify-between p-2 rounded-xl bg-slate-50 text-xs">
                  <div className="flex items-center gap-2.5">
                    <img src={st.avatar} alt={st.name} className="w-7 h-7 rounded-full object-cover" />
                    <div>
                      <span className="font-bold text-slate-900 block leading-tight">{st.name}</span>
                      <span className="text-[9px] text-slate-400 font-semibold">{st.rank}</span>
                    </div>
                  </div>
                  <span className="font-bold text-purple-600">{st.score}</span>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* MOBILE BOTTOM NAVIGATION BAR */}
        <div className="bg-white border-t border-slate-200 px-6 py-2 flex items-center justify-between text-xs font-bold text-slate-400">
          <button onClick={() => navigate('/dashboard')} className="flex flex-col items-center gap-0.5 text-purple-600">
            <Home className="w-5 h-5" />
            <span className="text-[10px]">Home</span>
          </button>

          <button onClick={() => navigate('/create-test')} className="flex flex-col items-center gap-0.5 hover:text-slate-700">
            <PlusCircle className="w-5 h-5" />
            <span className="text-[10px]">Create Test</span>
          </button>

          <button onClick={() => navigate('/invitations')} className="flex flex-col items-center gap-0.5 hover:text-slate-700">
            <Send className="w-5 h-5" />
            <span className="text-[10px]">Invites</span>
          </button>

          <button onClick={() => navigate('/analytics')} className="flex flex-col items-center gap-0.5 hover:text-slate-700">
            <BarChart3 className="w-5 h-5" />
            <span className="text-[10px]">Analytics</span>
          </button>
        </div>
      </div>
    </div>
  );
};
