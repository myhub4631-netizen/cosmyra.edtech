import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  User,
  Mail,
  Phone,
  GraduationCap,
  Award,
  Flame,
  CheckCircle2,
  BarChart3,
  ShieldCheck,
  Settings,
  Bell,
  LogOut,
  ChevronRight,
  BookOpen,
  Sparkles,
  Edit3,
  Moon,
  Sun,
  Lock,
  HelpCircle,
  FileText,
} from 'lucide-react';

export const StudentProfile: React.FC = () => {
  const navigate = useNavigate();
  const [selectedExam, setSelectedExam] = useState('NEET UG');
  const [notificationsEnabled, setNotificationsEnabled] = useState(true);
  const [darkMode, setDarkMode] = useState(false);

  const studentData = {
    name: 'Mahboob Hasan',
    role: 'NEET / JEE Aspirant',
    avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&auto=format&fit=crop&q=80',
    email: 'mahboob.hasan@example.com',
    phone: '+91 98765 43210',
    enrollmentId: 'CSM-2026-8942',
    targetExam: 'NEET UG 2026',
    targetScore: '700 / 720',
    streak: 12,
    rank: 42,
    totalTests: 24,
    questionsSolved: 5420,
    accuracy: '78.5%',
    badge: 'Pro NEET Aspirant',
  };

  return (
    <div className="max-w-4xl mx-auto space-y-6 pb-12 font-sans text-slate-800">
      {/* 1. HERO PROFILE HEADER CARD */}
      <div className="bg-gradient-to-br from-indigo-900 via-indigo-800 to-purple-900 rounded-3xl p-6 md:p-8 text-white shadow-xl relative overflow-hidden">
        {/* Background glow graphics */}
        <div className="absolute top-0 right-0 -mt-10 -mr-10 w-64 h-64 bg-purple-500/20 rounded-full blur-3xl pointer-events-none" />
        <div className="absolute bottom-0 left-0 -mb-10 -ml-10 w-64 h-64 bg-indigo-500/20 rounded-full blur-3xl pointer-events-none" />

        <div className="relative z-10 flex flex-col sm:flex-row items-center sm:items-start gap-6">
          {/* User Avatar */}
          <div className="relative">
            <img
              src={studentData.avatar}
              alt={studentData.name}
              className="w-24 h-24 sm:w-28 sm:h-28 rounded-full object-cover border-4 border-white/20 shadow-2xl"
            />
            <span className="w-5 h-5 bg-emerald-500 border-2 border-indigo-900 rounded-full absolute bottom-1 right-1 shadow-md" />
            <button className="absolute top-0 right-0 p-1.5 bg-indigo-600 hover:bg-indigo-500 text-white rounded-full shadow-lg transition-transform hover:scale-110">
              <Edit3 className="w-3.5 h-3.5" />
            </button>
          </div>

          {/* User Info */}
          <div className="flex-1 text-center sm:text-left space-y-2">
            <div className="flex flex-wrap items-center justify-center sm:justify-start gap-2">
              <h1 className="text-2xl sm:text-3xl font-extrabold tracking-tight">{studentData.name}</h1>
              <span className="px-2.5 py-0.5 rounded-full bg-purple-500/30 border border-purple-400/40 text-purple-200 text-xs font-bold flex items-center gap-1">
                <Sparkles className="w-3 h-3 text-amber-300" />
                {studentData.badge}
              </span>
            </div>

            <p className="text-indigo-200 text-sm font-medium flex items-center justify-center sm:justify-start gap-2">
              <GraduationCap className="w-4 h-4 text-indigo-300" />
              <span>Target: {studentData.targetExam}</span>
              <span>•</span>
              <span>Target Score: {studentData.targetScore}</span>
            </p>

            <div className="flex flex-wrap items-center justify-center sm:justify-start gap-4 pt-2 text-xs font-semibold text-indigo-100">
              <div className="flex items-center gap-1.5 bg-white/10 px-3 py-1.5 rounded-xl border border-white/10">
                <Mail className="w-3.5 h-3.5 text-indigo-300" />
                <span>{studentData.email}</span>
              </div>
              <div className="flex items-center gap-1.5 bg-white/10 px-3 py-1.5 rounded-xl border border-white/10">
                <Phone className="w-3.5 h-3.5 text-indigo-300" />
                <span>{studentData.phone}</span>
              </div>
              <div className="flex items-center gap-1.5 bg-amber-500/20 text-amber-300 px-3 py-1.5 rounded-xl border border-amber-500/30 font-bold">
                <Flame className="w-4 h-4 fill-amber-400 text-amber-400" />
                <span>{studentData.streak} Days Streak 🔥</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* 2. QUICK STATS SUMMARY */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm flex items-center gap-3">
          <div className="p-3 rounded-xl bg-indigo-50 text-indigo-600">
            <FileText className="w-5 h-5" />
          </div>
          <div>
            <span className="text-xl font-extrabold text-slate-900 block leading-tight">{studentData.totalTests}</span>
            <span className="text-xs text-slate-500 font-semibold">Tests Completed</span>
          </div>
        </div>

        <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm flex items-center gap-3">
          <div className="p-3 rounded-xl bg-purple-50 text-purple-600">
            <CheckCircle2 className="w-5 h-5" />
          </div>
          <div>
            <span className="text-xl font-extrabold text-slate-900 block leading-tight">{studentData.questionsSolved}</span>
            <span className="text-xs text-slate-500 font-semibold">Questions Solved</span>
          </div>
        </div>

        <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm flex items-center gap-3">
          <div className="p-3 rounded-xl bg-emerald-50 text-emerald-600">
            <BarChart3 className="w-5 h-5" />
          </div>
          <div>
            <span className="text-xl font-extrabold text-slate-900 block leading-tight">{studentData.accuracy}</span>
            <span className="text-xs text-slate-500 font-semibold">Avg. Accuracy</span>
          </div>
        </div>

        <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm flex items-center gap-3">
          <div className="p-3 rounded-xl bg-amber-50 text-amber-600">
            <Award className="w-5 h-5" />
          </div>
          <div>
            <span className="text-xl font-extrabold text-slate-900 block leading-tight">#{studentData.rank}</span>
            <span className="text-xs text-slate-500 font-semibold">All India Rank</span>
          </div>
        </div>
      </div>

      {/* 3. ACADEMIC & ACCOUNT PREFERENCES */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Academic Profile */}
        <div className="bg-white p-6 rounded-3xl border border-slate-200 shadow-sm space-y-4">
          <div className="flex items-center justify-between border-b border-slate-100 pb-3">
            <h2 className="text-base font-bold text-slate-900 flex items-center gap-2">
              <BookOpen className="w-5 h-5 text-indigo-600" />
              <span>Academic Details</span>
            </h2>
            <button className="text-xs font-bold text-indigo-600 hover:underline">Edit</button>
          </div>

          <div className="space-y-3 text-xs">
            <div className="flex justify-between py-1.5 border-b border-slate-50">
              <span className="text-slate-500 font-semibold">Enrollment ID</span>
              <span className="font-bold text-slate-900 font-mono">{studentData.enrollmentId}</span>
            </div>

            <div className="flex justify-between items-center py-1.5 border-b border-slate-50">
              <span className="text-slate-500 font-semibold">Active Goal</span>
              <select
                value={selectedExam}
                onChange={(e) => setSelectedExam(e.target.value)}
                className="bg-slate-50 border border-slate-200 font-bold text-indigo-600 px-2.5 py-1 rounded-lg focus:outline-none cursor-pointer"
              >
                <option value="NEET UG">NEET UG</option>
                <option value="JEE Main">JEE Main</option>
                <option value="JEE Advanced">JEE Advanced</option>
                <option value="CUET">CUET</option>
              </select>
            </div>

            <div className="flex justify-between py-1.5 border-b border-slate-50">
              <span className="text-slate-500 font-semibold">Target Batch</span>
              <span className="font-bold text-indigo-600">NEET Ultimate Achiever 2026</span>
            </div>

            <div className="flex justify-between py-1.5">
              <span className="text-slate-500 font-semibold">Subscription Status</span>
              <span className="font-bold text-emerald-600 flex items-center gap-1">
                <ShieldCheck className="w-4 h-4 text-emerald-500" /> Active PRO
              </span>
            </div>
          </div>
        </div>

        {/* App Preferences & Settings */}
        <div className="bg-white p-6 rounded-3xl border border-slate-200 shadow-sm space-y-4">
          <div className="flex items-center justify-between border-b border-slate-100 pb-3">
            <h2 className="text-base font-bold text-slate-900 flex items-center gap-2">
              <Settings className="w-5 h-5 text-indigo-600" />
              <span>App Settings</span>
            </h2>
          </div>

          <div className="space-y-3 text-xs">
            {/* Toggle Push Notifications */}
            <div className="flex items-center justify-between py-1">
              <div className="flex items-center gap-2.5">
                <div className="p-2 rounded-lg bg-slate-100 text-slate-600">
                  <Bell className="w-4 h-4" />
                </div>
                <div>
                  <span className="font-bold text-slate-800 block">Notifications</span>
                  <span className="text-[10px] text-slate-400">Daily reminders & test updates</span>
                </div>
              </div>
              <button
                onClick={() => setNotificationsEnabled(!notificationsEnabled)}
                className={`w-11 h-6 rounded-full p-1 transition-colors ${
                  notificationsEnabled ? 'bg-indigo-600' : 'bg-slate-300'
                }`}
              >
                <div
                  className={`w-4 h-4 rounded-full bg-white transition-transform ${
                    notificationsEnabled ? 'translate-x-5' : 'translate-x-0'
                  }`}
                />
              </button>
            </div>

            {/* Toggle Dark Mode */}
            <div className="flex items-center justify-between py-1 border-t border-slate-50">
              <div className="flex items-center gap-2.5">
                <div className="p-2 rounded-lg bg-slate-100 text-slate-600">
                  {darkMode ? <Moon className="w-4 h-4" /> : <Sun className="w-4 h-4 text-amber-500" />}
                </div>
                <div>
                  <span className="font-bold text-slate-800 block">Theme Mode</span>
                  <span className="text-[10px] text-slate-400">{darkMode ? 'Dark Mode' : 'Light Mode'}</span>
                </div>
              </div>
              <button
                onClick={() => setDarkMode(!darkMode)}
                className={`w-11 h-6 rounded-full p-1 transition-colors ${
                  darkMode ? 'bg-indigo-600' : 'bg-slate-300'
                }`}
              >
                <div
                  className={`w-4 h-4 rounded-full bg-white transition-transform ${
                    darkMode ? 'translate-x-5' : 'translate-x-0'
                  }`}
                />
              </button>
            </div>

            {/* Security & Password */}
            <button className="w-full flex items-center justify-between py-2 border-t border-slate-50 text-left hover:bg-slate-50 px-2 rounded-xl transition-colors">
              <div className="flex items-center gap-2.5">
                <div className="p-2 rounded-lg bg-slate-100 text-slate-600">
                  <Lock className="w-4 h-4" />
                </div>
                <div>
                  <span className="font-bold text-slate-800 block">Security & Password</span>
                  <span className="text-[10px] text-slate-400">Manage account access</span>
                </div>
              </div>
              <ChevronRight className="w-4 h-4 text-slate-400" />
            </button>

            {/* Help & Support */}
            <button className="w-full flex items-center justify-between py-2 border-t border-slate-50 text-left hover:bg-slate-50 px-2 rounded-xl transition-colors">
              <div className="flex items-center gap-2.5">
                <div className="p-2 rounded-lg bg-slate-100 text-slate-600">
                  <HelpCircle className="w-4 h-4" />
                </div>
                <div>
                  <span className="font-bold text-slate-800 block">Help & Support</span>
                  <span className="text-[10px] text-slate-400">FAQs & student helpline</span>
                </div>
              </div>
              <ChevronRight className="w-4 h-4 text-slate-400" />
            </button>
          </div>
        </div>
      </div>

      {/* 4. LOGOUT BUTTON */}
      <div className="flex justify-end pt-4">
        <button
          onClick={() => navigate('/')}
          className="flex items-center gap-2 px-5 py-2.5 bg-rose-50 text-rose-600 hover:bg-rose-100 rounded-2xl font-bold text-xs border border-rose-200 transition-colors"
        >
          <LogOut className="w-4 h-4" />
          <span>Log Out of Account</span>
        </button>
      </div>
    </div>
  );
};
