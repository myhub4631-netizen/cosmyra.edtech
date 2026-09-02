import React from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Sparkles,
  ArrowRight,
  BookOpen,
  FileSpreadsheet,
  Award,
  Users,
  GraduationCap,
  FileText,
  TrendingUp,
  Target,
  BarChart3,
  Bookmark,
  Gift,
  Flame,
  ChevronDown,
} from 'lucide-react';

export const LandingPage: React.FC = () => {
  const navigate = useNavigate();

  return (
    <div className="min-h-screen bg-slate-50/60 text-gray-800 font-sans pb-24 overflow-x-hidden">
      {/* 1. HERO SECTION */}
      <section className="pt-8 pb-16 px-4 sm:px-6 lg:px-12 max-w-7xl mx-auto">
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-center">
          {/* LEFT COLUMN: HEADLINE & CTAS (5 cols) */}
          <div className="lg:col-span-5 space-y-6">
            {/* Top Badge */}
            <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-amber-50 border border-amber-200 text-amber-800 text-xs font-bold shadow-sm">
              <span>⭐</span>
              <span>India's Most Trusted Exam Preparation Platform</span>
            </div>

            {/* Main Headline */}
            <h1 className="text-4xl lg:text-5xl font-extrabold text-gray-900 leading-tight tracking-tight">
              Practice <span className="text-indigo-600">Smarter.</span>
              <br />
              Perform <span className="text-indigo-600">Better.</span>
              <br />
              Crack Your Dream Exam.
            </h1>

            {/* Subtitle */}
            <p className="text-sm lg:text-base text-gray-500 font-medium leading-relaxed">
              Ace NEET, JEE and other competitive exams with thousands of practice questions, full-length tests, PYQs, detailed solutions and advanced performance analytics.
            </p>

            {/* CTA Buttons */}
            <div className="flex flex-wrap items-center gap-4 pt-2">
              <button
                onClick={() => navigate('/dashboard')}
                className="px-6 py-3.5 bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-bold rounded-xl shadow-lg shadow-indigo-600/30 transition-all flex items-center gap-2"
              >
                <span>Start Practicing Now</span>
                <ArrowRight className="w-4 h-4" />
              </button>

              <button
                onClick={() => navigate('/test')}
                className="px-6 py-3.5 bg-white border-2 border-indigo-200 hover:bg-indigo-50 text-indigo-600 text-sm font-bold rounded-xl transition-colors shadow-sm"
              >
                Explore Tests
              </button>
            </div>

            {/* Student Avatars & Social Proof */}
            <div className="flex items-center gap-3 pt-3">
              <div className="flex -space-x-2.5">
                <img
                  src="https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=80&auto=format&fit=crop&q=80"
                  alt="Student 1"
                  className="w-9 h-9 rounded-full border-2 border-white object-cover"
                />
                <img
                  src="https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=80&auto=format&fit=crop&q=80"
                  alt="Student 2"
                  className="w-9 h-9 rounded-full border-2 border-white object-cover"
                />
                <img
                  src="https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=80&auto=format&fit=crop&q=80"
                  alt="Student 3"
                  className="w-9 h-9 rounded-full border-2 border-white object-cover"
                />
              </div>
              <span className="text-xs text-gray-500 font-semibold">
                Join <strong className="text-gray-900 font-bold">2M+</strong> students who are preparing smarter every day!
              </span>
            </div>
          </div>

          {/* CENTER & RIGHT COLUMN: BOY STUDENT IMAGE & FLOATING METRIC PILLS (7 cols) */}
          <div className="lg:col-span-7 relative flex flex-col md:flex-row items-center justify-center gap-4">
            
            {/* Center Circular Background Halo Graphic */}
            <div className="absolute w-[440px] h-[440px] bg-gradient-to-tr from-purple-100/90 to-indigo-100/60 rounded-full border border-purple-200/50 blur-sm pointer-events-none" />

            {/* Boy Student Image Box (Exact User Image) */}
            <div className="relative z-10 w-72 sm:w-84 max-w-[360px] h-[440px] flex items-center justify-center flex-shrink-0">
              <img
                src="/student_boy.png"
                alt="ExamPrep Student Aspirant"
                className="w-full h-full object-contain drop-shadow-2xl z-10"
              />

              {/* Floating Pill 1 (Top Left): 10,000+ Practice Questions */}
              <div className="absolute top-8 -left-12 bg-white/95 backdrop-blur-md p-3 rounded-2xl border border-gray-100 shadow-xl flex items-center gap-3 z-20">
                <div className="w-9 h-9 rounded-xl bg-purple-50 text-indigo-600 flex items-center justify-center shadow-sm">
                  <BookOpen className="w-5 h-5" />
                </div>
                <div>
                  <span className="text-xs font-extrabold text-gray-900 block leading-tight">10,000+</span>
                  <span className="text-[10px] text-gray-400 font-semibold block">Practice Questions</span>
                </div>
              </div>

              {/* Floating Pill 2 (Middle Left): 500+ Full Length Tests */}
              <div className="absolute top-44 -left-16 bg-white/95 backdrop-blur-md p-3 rounded-2xl border border-gray-100 shadow-xl flex items-center gap-3 z-20">
                <div className="w-9 h-9 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center shadow-sm">
                  <FileSpreadsheet className="w-5 h-5" />
                </div>
                <div>
                  <span className="text-xs font-extrabold text-gray-900 block leading-tight">500+</span>
                  <span className="text-[10px] text-gray-400 font-semibold block">Full Length Tests</span>
                </div>
              </div>

              {/* Floating Pill 3 (Bottom Left): NEET • JEE Exams */}
              <div className="absolute bottom-6 -left-10 bg-white/95 backdrop-blur-md p-3 rounded-2xl border border-gray-100 shadow-xl flex items-center gap-3 z-20">
                <div className="w-9 h-9 rounded-xl bg-amber-50 text-amber-600 flex items-center justify-center shadow-sm">
                  <Award className="w-5 h-5" />
                </div>
                <div>
                  <span className="text-xs font-extrabold text-gray-900 block leading-tight">NEET • JEE</span>
                  <span className="text-[10px] text-gray-400 font-semibold block">& Many More Exams</span>
                </div>
              </div>
            </div>

            {/* RIGHT COLUMN: 2 FLOATING LIVE PREVIEW CARDS */}
            <div className="flex flex-col gap-4 z-20">
              {/* Card 1: Your Progress Live Preview Card */}
              <div className="bg-white p-4 rounded-2xl border border-gray-200 shadow-xl w-64 space-y-3">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-bold text-gray-900">Your Progress</span>
                  <span className="text-[10px] font-semibold text-gray-400 flex items-center gap-1">
                    This Week <ChevronDown className="w-3 h-3" />
                  </span>
                </div>

                <div className="space-y-1">
                  <span className="text-[10px] font-semibold text-gray-400 block uppercase">Score</span>
                  <div className="flex items-baseline justify-between">
                    <span className="text-xl font-extrabold text-gray-900">612 / 720</span>
                    <span className="text-xs font-bold text-indigo-600">85%</span>
                  </div>
                  <div className="w-full bg-gray-100 rounded-full h-1.5">
                    <div className="bg-indigo-600 h-1.5 rounded-full" style={{ width: '85%' }} />
                  </div>
                </div>

                <div className="grid grid-cols-3 gap-2 text-center pt-2 border-t border-gray-100">
                  <div>
                    <span className="text-[9px] text-gray-400 block font-semibold">Accuracy</span>
                    <span className="text-xs font-bold text-gray-900 block">78.4%</span>
                  </div>
                  <div>
                    <span className="text-[9px] text-gray-400 block font-semibold">Questions Solved</span>
                    <span className="text-xs font-bold text-gray-900 block">245</span>
                  </div>
                  <div>
                    <span className="text-[9px] text-gray-400 block font-semibold">Tests Completed</span>
                    <span className="text-xs font-bold text-gray-900 block">16</span>
                  </div>
                </div>
              </div>

              {/* Card 2: 12 Day Streak Live Preview Card */}
              <div className="bg-white p-4 rounded-2xl border border-gray-200 shadow-xl w-64 space-y-2">
                <div className="flex items-center gap-2">
                  <Flame className="w-5 h-5 text-orange-500 fill-orange-500" />
                  <div>
                    <span className="text-xs font-bold text-gray-900 block leading-tight">12 Day Streak</span>
                    <span className="text-[9px] text-gray-400 font-medium block">Keep it up!</span>
                  </div>
                </div>

                <div className="flex items-center justify-between pt-2 border-t border-gray-100">
                  {['M', 'T', 'W', 'T', 'F', 'S'].map((day, i) => (
                    <div key={i} className="text-center">
                      <span className="text-[8px] font-bold text-gray-400 block mb-0.5">{day}</span>
                      <span className="w-3.5 h-3.5 rounded-full bg-emerald-500 text-white text-[8px] font-bold flex items-center justify-center">
                        ✓
                      </span>
                    </div>
                  ))}
                  <div className="text-center">
                    <span className="text-[8px] font-bold text-gray-400 block mb-0.5">S</span>
                    <span className="w-3.5 h-3.5 rounded-full bg-gray-100 text-gray-400 text-[8px] font-bold flex items-center justify-center">
                      
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* 2. STATS BAR ROW (5 KEY METRICS CONTAINER) */}
      <section className="px-4 sm:px-6 lg:px-12 max-w-7xl mx-auto mb-16">
        <div className="bg-white rounded-2xl border border-gray-200 shadow-sm p-6 grid grid-cols-2 md:grid-cols-5 gap-6 divide-y md:divide-y-0 md:divide-x divide-gray-100 text-center">
          {/* Stat 1: 2M+ Students */}
          <div className="flex items-center justify-center gap-3 pt-4 md:pt-0">
            <div className="w-10 h-10 rounded-full bg-purple-50 text-indigo-600 flex items-center justify-center flex-shrink-0">
              <Users className="w-5 h-5" />
            </div>
            <div className="text-left">
              <span className="text-xl font-extrabold text-gray-900 block leading-tight">2M+</span>
              <span className="text-xs font-semibold text-gray-400">Students</span>
            </div>
          </div>

          {/* Stat 2: 50+ Exams */}
          <div className="flex items-center justify-center gap-3 pt-4 md:pt-0">
            <div className="w-10 h-10 rounded-full bg-blue-50 text-blue-600 flex items-center justify-center flex-shrink-0">
              <GraduationCap className="w-5 h-5" />
            </div>
            <div className="text-left">
              <span className="text-xl font-extrabold text-gray-900 block leading-tight">50+</span>
              <span className="text-xs font-semibold text-gray-400">Exams</span>
            </div>
          </div>

          {/* Stat 3: 1.5M+ Questions */}
          <div className="flex items-center justify-center gap-3 pt-4 md:pt-0">
            <div className="w-10 h-10 rounded-full bg-emerald-50 text-emerald-600 flex items-center justify-center flex-shrink-0">
              <FileSpreadsheet className="w-5 h-5" />
            </div>
            <div className="text-left">
              <span className="text-xl font-extrabold text-gray-900 block leading-tight">1.5M+</span>
              <span className="text-xs font-semibold text-gray-400">Questions</span>
            </div>
          </div>

          {/* Stat 4: 25K+ Tests */}
          <div className="flex items-center justify-center gap-3 pt-4 md:pt-0">
            <div className="w-10 h-10 rounded-full bg-amber-50 text-amber-600 flex items-center justify-center flex-shrink-0">
              <FileText className="w-5 h-5" />
            </div>
            <div className="text-left">
              <span className="text-xl font-extrabold text-gray-900 block leading-tight">25K+</span>
              <span className="text-xs font-semibold text-gray-400">Tests</span>
            </div>
          </div>

          {/* Stat 5: 95% Student Satisfaction */}
          <div className="flex items-center justify-center gap-3 pt-4 md:pt-0">
            <div className="w-10 h-10 rounded-full bg-rose-50 text-rose-600 flex items-center justify-center flex-shrink-0">
              <TrendingUp className="w-5 h-5" />
            </div>
            <div className="text-left">
              <span className="text-xl font-extrabold text-gray-900 block leading-tight">95%</span>
              <span className="text-xs font-semibold text-gray-400">Student Satisfaction</span>
            </div>
          </div>
        </div>
      </section>

      {/* 3. SECTION 2: POWERFUL FEATURES FOR EVERY ASPIRANT */}
      <section className="px-4 sm:px-6 lg:px-12 max-w-7xl mx-auto mb-16 space-y-10">
        <div className="text-center space-y-2 max-w-2xl mx-auto">
          <span className="text-xs font-bold uppercase tracking-wider text-indigo-600 block">
            EVERYTHING YOU NEED TO SUCCEED
          </span>
          <h2 className="text-3xl font-extrabold text-gray-900 tracking-tight">
            Powerful Features for Every Aspirant
          </h2>
          <p className="text-xs lg:text-sm text-gray-500 font-medium">
            All the tools you need to plan, practice, analyze and improve your performance.
          </p>
        </div>

        {/* 6 Feature Cards Grid */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6 gap-5">
          {/* Card 1: Custom Practice */}
          <div className="bg-white p-5 rounded-2xl border border-gray-200 shadow-sm text-center space-y-3 hover:border-indigo-400 transition-colors">
            <div className="w-10 h-10 rounded-xl bg-purple-50 text-indigo-600 flex items-center justify-center mx-auto shadow-sm">
              <Target className="w-5 h-5" />
            </div>
            <h3 className="text-xs font-extrabold text-gray-900">Custom Practice</h3>
            <p className="text-[11px] text-gray-500 leading-relaxed font-medium">
              Practice questions from specific subjects, chapters & topics of your choice.
            </p>
          </div>

          {/* Card 2: Custom Tests */}
          <div className="bg-white p-5 rounded-2xl border border-gray-200 shadow-sm text-center space-y-3 hover:border-indigo-400 transition-colors">
            <div className="w-10 h-10 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center mx-auto shadow-sm">
              <FileSpreadsheet className="w-5 h-5" />
            </div>
            <h3 className="text-xs font-extrabold text-gray-900">Custom Tests</h3>
            <p className="text-[11px] text-gray-500 leading-relaxed font-medium">
              Create your own test with time limit, marks & negative marking and evaluate yourself.
            </p>
          </div>

          {/* Card 3: PYQ & NTA Questions */}
          <div className="bg-white p-5 rounded-2xl border border-gray-200 shadow-sm text-center space-y-3 hover:border-indigo-400 transition-colors">
            <div className="w-10 h-10 rounded-xl bg-amber-50 text-amber-600 flex items-center justify-center mx-auto shadow-sm">
              <BookOpen className="w-5 h-5" />
            </div>
            <h3 className="text-xs font-extrabold text-gray-900">PYQ & NTA Questions</h3>
            <p className="text-[11px] text-gray-500 leading-relaxed font-medium">
              Practice previous year questions and official NTA questions chapter-wise or full syllabus.
            </p>
          </div>

          {/* Card 4: Performance Analytics */}
          <div className="bg-white p-5 rounded-2xl border border-gray-200 shadow-sm text-center space-y-3 hover:border-indigo-400 transition-colors">
            <div className="w-10 h-10 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center mx-auto shadow-sm">
              <BarChart3 className="w-5 h-5" />
            </div>
            <h3 className="text-xs font-extrabold text-gray-900">Performance Analytics</h3>
            <p className="text-[11px] text-gray-500 leading-relaxed font-medium">
              Detailed analysis of your strengths, weaknesses and progress over time.
            </p>
          </div>

          {/* Card 5: Smart Bookmarks */}
          <div className="bg-white p-5 rounded-2xl border border-gray-200 shadow-sm text-center space-y-3 hover:border-indigo-400 transition-colors">
            <div className="w-10 h-10 rounded-xl bg-rose-50 text-rose-600 flex items-center justify-center mx-auto shadow-sm">
              <Bookmark className="w-5 h-5" />
            </div>
            <h3 className="text-xs font-extrabold text-gray-900">Smart Bookmarks</h3>
            <p className="text-[11px] text-gray-500 leading-relaxed font-medium">
              Bookmark important questions and revise them anytime, anywhere.
            </p>
          </div>

          {/* Card 6: Leaderboards */}
          <div className="bg-white p-5 rounded-2xl border border-gray-200 shadow-sm text-center space-y-3 hover:border-indigo-400 transition-colors">
            <div className="w-10 h-10 rounded-xl bg-purple-50 text-purple-600 flex items-center justify-center mx-auto shadow-sm">
              <Award className="w-5 h-5" />
            </div>
            <h3 className="text-xs font-extrabold text-gray-900">Leaderboards</h3>
            <p className="text-[11px] text-gray-500 leading-relaxed font-medium">
              Compete with other aspirants and climb the daily, weekly & monthly leaderboards.
            </p>
          </div>
        </div>
      </section>

      {/* 4. BOTTOM CALLOUT BANNER ("New Here?") */}
      <section className="px-4 sm:px-6 lg:px-12 max-w-7xl mx-auto">
        <div className="bg-purple-50/80 border border-purple-100 rounded-2xl p-6 flex flex-col md:flex-row md:items-center justify-between gap-6 shadow-sm">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 rounded-full bg-purple-100 text-indigo-600 flex items-center justify-center flex-shrink-0 shadow-sm">
              <Gift className="w-6 h-6" />
            </div>
            <div>
              <h3 className="text-base font-extrabold text-gray-900">New Here?</h3>
              <p className="text-xs text-gray-500 font-medium mt-0.5">
                Create your free account and get access to free tests, quizzes and more.
              </p>
            </div>
          </div>

          <button
            onClick={() => navigate('/dashboard')}
            className="px-6 py-3 bg-indigo-600 hover:bg-indigo-700 text-white text-xs font-bold rounded-xl shadow-md shadow-indigo-600/20 transition-all flex items-center justify-center gap-2 flex-shrink-0"
          >
            <span>Create Free Account</span>
            <ArrowRight className="w-4 h-4" />
          </button>
        </div>
      </section>
    </div>
  );
};
