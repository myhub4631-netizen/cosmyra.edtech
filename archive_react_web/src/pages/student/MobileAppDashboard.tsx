import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Flame,
  Search,
  BookOpen,
  Target,
  FileSpreadsheet,
  BarChart3,
  User,
  Home,
  CheckCircle2,
  Lock,
  Sparkles,
  ChevronRight,
  TrendingUp,
  Award,
  ChevronDown,
  ArrowRight,
  Bookmark,
  AlertCircle,
  Zap,
  Crown,
  Clock,
  ShieldCheck,
  Check,
  Plus,
  Compass,
  FileText,
  Sliders,
  Settings,
  HelpCircle,
  Bell,
  Activity,
  Layers,
  Percent,
  Bot,
  Rocket,
  Gem,
  Menu,
} from 'lucide-react';
import { BottomNav } from '../../components/layout/BottomNav';
import { NewPracticeWizard } from './NewPracticeWizard';
import { ActivePracticeInterface } from './ActivePracticeInterface';
import { InstantFeedbackInterface } from './InstantFeedbackInterface';
import { DetailedSolutionView } from './DetailedSolutionView';
import { MobilePricingScreen } from './MobilePricingScreen';
import { MobilePaymentScreen } from './MobilePaymentScreen';
import { MobilePaperPrediction } from './MobilePaperPrediction';
import { MobileMockTestsScreen } from './MobileMockTestsScreen';
import { MobileAnalyticsScreen } from './MobileAnalyticsScreen';
import { MobileProfileScreen } from './MobileProfileScreen';
import { MobileAppDrawer } from '../../components/layout/MobileAppDrawer';

interface MobileAppDashboardProps {
  initialTab?: 'home' | 'test' | 'tests' | 'practice' | 'analytics' | 'profile';
  initialWizard?: boolean;
  initialActivePractice?: boolean;
  initialFeedback?: boolean;
  initialSolution?: boolean;
  initialMobilePricing?: boolean;
  initialPayment?: boolean;
  initialPrediction?: boolean;
}

export const MobileAppDashboard: React.FC<MobileAppDashboardProps> = ({
  initialTab = 'test',
  initialWizard = false,
  initialActivePractice = false,
  initialFeedback = false,
  initialSolution = false,
  initialMobilePricing = false,
  initialPayment = false,
  initialPrediction = false,
}) => {
  const navigate = useNavigate();
  const [activeTab, setActiveTab] = useState<'home' | 'test' | 'tests' | 'practice' | 'analytics' | 'profile'>(initialTab);
  const [isCreatingPractice, setIsCreatingPractice] = useState<boolean>(initialWizard);
  const [isActivePractice, setIsActivePractice] = useState<boolean>(initialActivePractice);
  const [isFeedbackMode, setIsFeedbackMode] = useState<boolean>(initialFeedback);
  const [isSolutionMode, setIsSolutionMode] = useState<boolean>(initialSolution);
  const [isMobilePricing, setIsMobilePricing] = useState<boolean>(initialMobilePricing);
  const [isPaymentMode, setIsPaymentMode] = useState<boolean>(initialPayment);
  const [isPredictionMode, setIsPredictionMode] = useState<boolean>(initialPrediction);
  const [isDrawerOpen, setIsDrawerOpen] = useState<boolean>(false);

  // State for Practice Screen
  const [practiceMode, setPracticeMode] = useState<'subject' | 'chapter' | 'topic' | 'custom'>('subject');
  const [selectedSubjects, setSelectedSubjects] = useState<string[]>(['physics', 'chemistry', 'biology']);

  const toggleSubject = (subjectId: string) => {
    setSelectedSubjects((prev) =>
      prev.includes(subjectId) ? prev.filter((id) => id !== subjectId) : [...prev, subjectId]
    );
  };

  return (
    <div className="min-h-screen bg-slate-900 py-6 px-2 sm:px-4 flex items-center justify-center font-sans text-slate-900">
      
      {/* CENTER MOBILE PHONE DEVICE FRAME */}
      <div className="w-full max-w-[430px] bg-white rounded-[48px] shadow-2xl shadow-purple-950/40 border-[10px] border-slate-950 overflow-hidden flex flex-col min-h-[900px] relative select-none">
          
          {/* Status Bar */}
          <div className="pt-3 px-7 pb-2 flex items-center justify-between text-xs font-bold text-slate-900 bg-white">
            <span>9:41</span>
            {/* Dynamic Island Notch */}
            <div className="w-24 h-4 bg-slate-950 rounded-full" />
            <div className="flex items-center gap-1 text-[10px]">
              <span>📶</span>
              <span>🔋</span>
            </div>
          </div>

          {/* App Bar (Top Header) */}
          <div className="px-5 py-3 flex items-center justify-between bg-white border-b border-slate-100 sticky top-0 z-20">
            <div className="flex items-center gap-2.5">
              {/* Hamburger Menu Trigger */}
              <button
                onClick={() => setIsDrawerOpen(true)}
                className="p-1.5 rounded-xl text-slate-700 hover:bg-slate-100 transition-colors -ml-1"
              >
                <Menu className="w-5 h-5 stroke-[2.5]" />
              </button>

              <div className="w-7 h-7 rounded-xl bg-[#5D3EED] flex items-center justify-center text-white shadow-md shadow-indigo-600/30">
                <Flame className="w-4 h-4 fill-white" />
              </div>
              <span className="text-xl font-extrabold text-slate-900 tracking-tight">Cosmyra</span>
            </div>

            <button className="relative p-2 rounded-xl text-slate-600 hover:bg-slate-50 transition-colors">
              <Bell className="w-5 h-5" />
              <span className="absolute top-1 right-1 bg-rose-500 text-white text-[10px] font-bold w-4 h-4 rounded-full flex items-center justify-center border-2 border-white">
                2
              </span>
            </button>
          </div>

          {/* Sliding Side Navigation Drawer */}
          <MobileAppDrawer
            isOpen={isDrawerOpen}
            onClose={() => setIsDrawerOpen(false)}
            onNavigateTab={(tab, extraState) => {
              setIsCreatingPractice(false);
              setIsActivePractice(false);
              setIsFeedbackMode(false);
              setIsSolutionMode(false);
              setIsMobilePricing(false);
              setIsPaymentMode(false);
              setIsPredictionMode(false);

              if (extraState?.initialMobilePricing) setIsMobilePricing(true);
              if (extraState?.initialPayment) setIsPaymentMode(true);
              if (extraState?.initialPrediction) setIsPredictionMode(true);

              setActiveTab(tab as any);
            }}
          />

          {/* Scrollable Main Content Area */}
          <div className="flex-1 overflow-y-auto px-4 py-4 space-y-4 bg-[#F8FAFC] custom-scrollbar">

            {isPredictionMode ? (
              <MobilePaperPrediction
                isMobileFrame={true}
                onBack={() => setIsPredictionMode(false)}
                onStartPractice={() => {
                  setIsPredictionMode(false);
                  setIsActivePractice(true);
                }}
                onStartTest={() => {
                  setIsPredictionMode(false);
                  setActiveTab('test');
                }}
              />
            ) : isPaymentMode ? (
              <MobilePaymentScreen
                isMobileFrame={true}
                onBack={() => setIsPaymentMode(false)}
              />
            ) : isMobilePricing ? (
              <MobilePricingScreen
                isMobileFrame={true}
                onBack={() => setIsMobilePricing(false)}
                onSelectPlan={() => {
                  setIsMobilePricing(false);
                  setIsPaymentMode(true);
                }}
              />
            ) : isSolutionMode ? (
              <DetailedSolutionView
                isMobileFrame={true}
                onBack={() => setIsSolutionMode(false)}
              />
            ) : isFeedbackMode ? (
              <InstantFeedbackInterface
                isMobileFrame={true}
                onBack={() => setIsFeedbackMode(false)}
                onViewSolution={() => {
                  setIsFeedbackMode(false);
                  setIsSolutionMode(true);
                }}
              />
            ) : isActivePractice ? (
              <ActivePracticeInterface
                isMobileFrame={true}
                onBack={() => setIsActivePractice(false)}
              />
            ) : isCreatingPractice ? (
              <NewPracticeWizard
                isMobileFrame={true}
                onBack={() => setIsCreatingPractice(false)}
                onStartSession={() => {
                  setIsCreatingPractice(false);
                  setIsFeedbackMode(true);
                }}
              />
            ) : (
              <>
                {/* ========================================================================= */}
                {/* 1. PRACTICE TAB */}
                {/* ========================================================================= */}
                {activeTab === 'practice' && (
                  <NewPracticeWizard
                    isMobileFrame={true}
                    onBack={() => setActiveTab('home')}
                    onStartSession={() => {
                      setIsFeedbackMode(true);
                    }}
                  />
                )}

                {/* ========================================================================= */}
                {/* 3. ANALYTICS TAB */}
                {/* ========================================================================= */}
                {activeTab === 'analytics' && (
                  <div className="space-y-4">
                    <h1 className="text-xl font-extrabold text-slate-900 tracking-tight">Analytics & Rank</h1>
                  </div>
                )}

                {/* ========================================================================= */}
                {/* ========================================================================= */}
                {/* 4. PROFILE TAB */}
                {/* ========================================================================= */}
                {activeTab === 'profile' && (
                  <MobileProfileScreen
                    isMobileFrame={true}
                    onOpenDrawer={() => setIsDrawerOpen(true)}
                    onNavigatePlan={() => setIsMobilePricing(true)}
                  />
                )}

                {/* ========================================================================= */}
                {/* 5. HOME SCREEN (PIXEL-PERFECT FROM USER SCREENSHOT) */}
                {/* ========================================================================= */}
                {activeTab === 'home' && (
                  <div className="space-y-4">
                    
                    {/* User Profile & Streak Header */}
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-3">
                        <div className="relative">
                          <img
                            src="https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&auto=format&fit=crop&q=80"
                            alt="Mahboob Hasan"
                            className="w-12 h-12 rounded-full object-cover border-2 border-[#5D3EED] p-0.5"
                          />
                          <span className="w-3.5 h-3.5 bg-emerald-500 border-2 border-white rounded-full absolute bottom-0 right-0" />
                        </div>
                        <div>
                          <h2 className="text-base font-extrabold text-slate-900 flex items-center gap-1">
                            Hello, Mahboob 👋
                          </h2>
                          <div className="flex items-center gap-1 text-[#5D3EED] text-xs font-bold mt-0.5 cursor-pointer">
                            <span>NEET UG 2026</span>
                            <ChevronDown className="w-3.5 h-3.5 stroke-[2.5]" />
                          </div>
                        </div>
                      </div>

                      {/* Streak Pill */}
                      <div className="bg-amber-50 border border-amber-200/80 rounded-2xl p-2.5 text-right space-y-0.5 shadow-xs">
                        <div className="flex items-center gap-1 justify-end text-amber-600 font-extrabold text-xs">
                          <Flame className="w-4 h-4 fill-amber-500 text-amber-500" />
                          <span>12 Days Streak</span>
                        </div>
                        <span className="text-[10px] font-semibold text-amber-600 block">Keep it up! 🔥</span>
                      </div>
                    </div>

                    {/* 1. YOUR PREPARATION PROGRESS HERO CARD */}
                    <div className="bg-gradient-to-br from-[#1E1B4B] via-[#0F172A] to-[#312E81] text-white rounded-3xl p-4 shadow-xl space-y-4 relative overflow-hidden">
                      <div className="flex items-center justify-between border-b border-white/10 pb-2">
                        <span className="text-xs font-bold text-slate-200">Your Preparation Progress</span>
                        <button className="text-[11px] font-bold text-indigo-300 hover:text-white transition-colors flex items-center gap-1">
                          <span>View Full Report</span>
                          <ArrowRight className="w-3 h-3" />
                        </button>
                      </div>

                      <div className="flex items-center gap-4">
                        {/* Donut Chart */}
                        <div className="relative w-28 h-28 flex-shrink-0 flex items-center justify-center">
                          <svg viewBox="0 0 36 36" className="w-full h-full transform -rotate-90">
                            <path
                              d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                              fill="none"
                              stroke="rgba(255,255,255,0.15)"
                              strokeWidth="4"
                            />
                            <path
                              d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                              fill="none"
                              stroke="url(#purpleGradient2)"
                              strokeWidth="4"
                              strokeDasharray="78, 100"
                            />
                            <defs>
                              <linearGradient id="purpleGradient2" x1="0%" y1="0%" x2="100%" y2="100%">
                                <stop offset="0%" stopColor="#818CF8" />
                                <stop offset="100%" stopColor="#C084FC" />
                              </linearGradient>
                            </defs>
                          </svg>
                          <div className="absolute text-center leading-none">
                            <span className="text-xl font-extrabold text-white block">78%</span>
                            <span className="text-[9px] text-indigo-200 font-semibold block mt-0.5">Completed</span>
                            <span className="text-xs block mt-1">🏆</span>
                          </div>
                        </div>

                        {/* 4 Stats List */}
                        <div className="space-y-2 flex-1 text-xs font-semibold">
                          <div className="flex items-center justify-between">
                            <span className="text-indigo-200 flex items-center gap-1.5">
                              <span>📝</span> Tests Taken
                            </span>
                            <span className="font-extrabold text-white">24</span>
                          </div>
                          <div className="flex items-center justify-between">
                            <span className="text-indigo-200 flex items-center gap-1.5">
                              <span>🚀</span> Accuracy
                            </span>
                            <span className="font-extrabold text-white">68.7%</span>
                          </div>
                          <div className="flex items-center justify-between">
                            <span className="text-indigo-200 flex items-center gap-1.5">
                              <span>🎯</span> Questions Solved
                            </span>
                            <span className="font-extrabold text-white">5420</span>
                          </div>
                          <div className="flex items-center justify-between">
                            <span className="text-indigo-200 flex items-center gap-1.5">
                              <span>👑</span> Rank (All India)
                            </span>
                            <span className="font-extrabold text-emerald-400">Top 8%</span>
                          </div>
                        </div>
                      </div>

                      {/* Bottom Banner Strip */}
                      <div className="bg-white/10 rounded-2xl p-2.5 flex items-center justify-between text-xs">
                        <div className="flex items-center gap-2">
                          <span className="text-amber-300">🏅</span>
                          <div className="leading-tight">
                            <span className="font-extrabold text-white text-[11px] block">Excellent Performance! 🎉</span>
                            <span className="text-[10px] text-indigo-200 block">You're doing great. Keep pushing!</span>
                          </div>
                        </div>
                        <button
                          onClick={() => setActiveTab('analytics')}
                          className="px-3 py-1.5 rounded-xl bg-white/15 hover:bg-white/25 text-white font-extrabold text-[11px] flex items-center gap-1 transition-colors"
                        >
                          <BarChart3 className="w-3.5 h-3.5" />
                          <span>View Analytics →</span>
                        </button>
                      </div>
                    </div>

                    {/* 2. QUICK ACTIONS (5 CARDS GRID) */}
                    <div className="space-y-2">
                      <div className="flex items-center justify-between">
                        <h3 className="text-xs font-extrabold text-slate-900">Quick Actions</h3>
                        <button className="text-[11px] font-bold text-slate-500 flex items-center gap-1">
                          <Sliders className="w-3 h-3" />
                          <span>Customize</span>
                        </button>
                      </div>

                      <div className="grid grid-cols-5 gap-1.5 text-center">
                        {/* 1. Practice Questions */}
                        <div
                          onClick={() => setIsCreatingPractice(true)}
                          className="bg-white p-2.5 rounded-2xl border border-slate-200 shadow-xs cursor-pointer hover:border-indigo-500 transition-all flex flex-col items-center justify-center space-y-1.5"
                        >
                          <div className="w-9 h-9 rounded-xl bg-[#F5F3FF] text-[#5D3EED] flex items-center justify-center">
                            <Target className="w-4 h-4" />
                          </div>
                          <span className="text-[10px] font-extrabold text-slate-800 leading-tight">Practice Questions</span>
                        </div>

                        {/* 2. Mock Tests */}
                        <div
                          onClick={() => setActiveTab('test')}
                          className="bg-white p-2.5 rounded-2xl border border-slate-200 shadow-xs cursor-pointer hover:border-blue-500 transition-all flex flex-col items-center justify-center space-y-1.5"
                        >
                          <div className="w-9 h-9 rounded-xl bg-[#EFF6FF] text-[#2563EB] flex items-center justify-center">
                            <FileSpreadsheet className="w-4 h-4" />
                          </div>
                          <span className="text-[10px] font-extrabold text-slate-800 leading-tight">Mock Tests</span>
                        </div>

                        {/* 3. PYQ Bank */}
                        <div
                          onClick={() => navigate('/pyq')}
                          className="bg-white p-2.5 rounded-2xl border border-slate-200 shadow-xs cursor-pointer hover:border-amber-500 transition-all flex flex-col items-center justify-center space-y-1.5"
                        >
                          <div className="w-9 h-9 rounded-xl bg-[#FFFBEB] text-[#D97706] flex items-center justify-center">
                            <Award className="w-4 h-4" />
                          </div>
                          <span className="text-[10px] font-extrabold text-slate-800 leading-tight">PYQ Bank</span>
                        </div>

                        {/* 4. Custom Test */}
                        <div
                          onClick={() => setIsCreatingPractice(true)}
                          className="bg-white p-2.5 rounded-2xl border border-slate-200 shadow-xs cursor-pointer hover:border-emerald-500 transition-all flex flex-col items-center justify-center space-y-1.5"
                        >
                          <div className="w-9 h-9 rounded-xl bg-[#ECFDF5] text-[#059669] flex items-center justify-center">
                            <FileText className="w-4 h-4" />
                          </div>
                          <span className="text-[10px] font-extrabold text-slate-800 leading-tight">Custom Test</span>
                        </div>

                        {/* 5. Topic Wise */}
                        <div
                          onClick={() => setIsCreatingPractice(true)}
                          className="bg-white p-2.5 rounded-2xl border border-slate-200 shadow-xs cursor-pointer hover:border-pink-500 transition-all flex flex-col items-center justify-center space-y-1.5"
                        >
                          <div className="w-9 h-9 rounded-xl bg-[#FDF2F8] text-[#DB2777] flex items-center justify-center">
                            <Layers className="w-4 h-4" />
                          </div>
                          <span className="text-[10px] font-extrabold text-slate-800 leading-tight">Topic Wise</span>
                        </div>
                      </div>
                    </div>

                    {/* 3. TODAY'S TARGET CARD */}
                    <div className="bg-white rounded-3xl border border-slate-200 p-4 space-y-3 shadow-xs">
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-2">
                          <Target className="w-4 h-4 text-[#5D3EED]" />
                          <h3 className="text-xs font-extrabold text-slate-900">Today's Target</h3>
                        </div>
                        <button className="text-[11px] font-bold text-[#5D3EED]">Edit Target</button>
                      </div>

                      <div className="grid grid-cols-12 gap-3 items-center">
                        {/* Target Bars */}
                        <div className="col-span-8 space-y-2.5 text-xs font-bold text-slate-700">
                          {/* Item 1 */}
                          <div className="space-y-1">
                            <div className="flex items-center justify-between text-[11px]">
                              <span className="flex items-center gap-1.5">
                                <ShieldCheck className="w-3.5 h-3.5 text-emerald-500" />
                                <span>Solve 60 Questions</span>
                              </span>
                              <span className="font-extrabold text-slate-900">42 / 60</span>
                            </div>
                            <div className="w-full h-2 bg-slate-100 rounded-full overflow-hidden">
                              <div className="h-full bg-emerald-500 rounded-full w-[70%]" />
                            </div>
                          </div>

                          {/* Item 2 */}
                          <div className="space-y-1">
                            <div className="flex items-center justify-between text-[11px]">
                              <span className="flex items-center gap-1.5">
                                <FileText className="w-3.5 h-3.5 text-blue-500" />
                                <span>Take 1 Mock Test</span>
                              </span>
                              <span className="font-extrabold text-slate-900">0 / 1</span>
                            </div>
                            <div className="w-full h-2 bg-slate-100 rounded-full overflow-hidden">
                              <div className="h-full bg-blue-500 rounded-full w-[10%]" />
                            </div>
                          </div>

                          {/* Item 3 */}
                          <div className="space-y-1">
                            <div className="flex items-center justify-between text-[11px]">
                              <span className="flex items-center gap-1.5">
                                <Clock className="w-3.5 h-3.5 text-purple-500" />
                                <span>Study Time</span>
                              </span>
                              <span className="font-extrabold text-slate-900">120 / 180 mins</span>
                            </div>
                            <div className="w-full h-2 bg-slate-100 rounded-full overflow-hidden">
                              <div className="h-full bg-[#5D3EED] rounded-full w-[66%]" />
                            </div>
                          </div>
                        </div>

                        {/* Right Target Donut Chart */}
                        <div className="col-span-4 flex flex-col items-center justify-center text-center">
                          <div className="relative w-20 h-20 flex items-center justify-center">
                            <svg viewBox="0 0 36 36" className="w-full h-full transform -rotate-90">
                              <path
                                d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                                fill="none"
                                stroke="#EEF2FF"
                                strokeWidth="4"
                              />
                              <path
                                d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                                fill="none"
                                stroke="#5D3EED"
                                strokeWidth="4"
                                strokeDasharray="70, 100"
                              />
                            </svg>
                            <div className="absolute text-center leading-none">
                              <span className="text-sm font-extrabold text-slate-900 block">70%</span>
                              <span className="text-[8px] text-slate-400 font-bold block mt-0.5">Targets Completed</span>
                            </div>
                          </div>

                          <button className="mt-2 px-3 py-1.5 rounded-xl bg-[#5D3EED] hover:bg-[#4F46E5] text-white font-extrabold text-[10px] shadow-sm">
                            View All Targets →
                          </button>
                        </div>
                      </div>
                    </div>

                    {/* 4. GO PREMIUM BANNER */}
                    <div
                      onClick={() => setIsMobilePricing(true)}
                      className="bg-gradient-to-r from-[#1E1B4B] to-[#312E81] text-white rounded-3xl p-4 flex items-center justify-between shadow-lg cursor-pointer hover:opacity-95 transition-opacity"
                    >
                      <div className="space-y-1 max-w-[220px]">
                        <div className="flex items-center gap-1.5">
                          <Crown className="w-5 h-5 text-amber-300 fill-amber-300" />
                          <h3 className="text-xs font-extrabold text-white">Go Premium. Go Unlimited. 🚀</h3>
                        </div>
                        <p className="text-[10px] text-slate-300 font-medium leading-tight">
                          Unlock unlimited practice, detailed solutions, All India Rank, performance insights & more.
                        </p>
                        <div className="flex items-center gap-2 pt-1 text-[9px] font-bold text-amber-200">
                          <span>✔ Unlimited Practice</span>
                          <span>✔ All India Rank</span>
                          <span>✔ Detailed Solutions</span>
                        </div>
                      </div>

                      <div className="text-right space-y-1">
                        <span className="px-2 py-0.5 rounded-full bg-emerald-500 text-white font-extrabold text-[9px]">
                          🔥 30% OFF
                        </span>
                        <div>
                          <span className="text-base font-black text-white block leading-none">₹299 <span className="text-[9px] font-normal text-slate-300">/ month</span></span>
                          <span className="text-[9px] text-slate-400 line-through block">₹429/month</span>
                        </div>
                        <button className="px-3 py-1.5 rounded-xl bg-white text-[#4F46E5] font-extrabold text-[10px] shadow-sm hover:bg-slate-50 transition-colors">
                          Upgrade Now →
                        </button>
                      </div>
                    </div>

                    {/* 5. DAILY PREDICTION TEST CARD */}
                    <div className="bg-gradient-to-r from-[#F0FDF4] to-white border border-emerald-200 rounded-3xl p-4 space-y-3 shadow-xs">
                      <div className="flex items-start justify-between">
                        <div className="flex items-center gap-3">
                          <div className="w-10 h-10 rounded-2xl bg-emerald-100 text-emerald-600 flex items-center justify-center flex-shrink-0">
                            <Target className="w-5 h-5" />
                          </div>
                          <div>
                            <div className="flex items-center gap-2">
                              <h3 className="text-xs font-extrabold text-slate-900">Daily Prediction Test</h3>
                              <span className="px-2 py-0.5 rounded-lg bg-emerald-100 text-emerald-800 text-[9px] font-bold">
                                New
                              </span>
                            </div>
                            <p className="text-[10px] text-slate-500 font-medium">Practice today's most expected questions prepared by our expert faculty.</p>
                          </div>
                        </div>

                        <button
                          onClick={() => setActiveTab('test')}
                          className="px-3.5 py-2 rounded-xl bg-[#059669] hover:bg-[#047857] text-white font-extrabold text-xs shadow-sm flex-shrink-0"
                        >
                          Start Test Now →
                        </button>
                      </div>

                      <div className="flex items-center gap-4 text-[10px] font-bold text-slate-600 border-t border-emerald-100 pt-2">
                        <span>📋 180 Questions</span>
                        <span>⏱️ 180 Marks</span>
                        <span>⏱️ 180 Mins</span>
                        <span className="text-emerald-600 ml-auto">Available Now</span>
                      </div>
                    </div>

                    {/* 6. YOUR ALL INDIA RANK & TOP PERFORMERS CARD */}
                    <div className="bg-white rounded-3xl border border-slate-200 p-4 space-y-3 shadow-xs">
                      <div className="flex items-center justify-between">
                        <h3 className="text-xs font-extrabold text-slate-900">Your All India Rank</h3>
                        <button
                          onClick={() => navigate('/student/leaderboard')}
                          className="text-[11px] font-bold text-[#5D3EED]"
                        >
                          View Leaderboard →
                        </button>
                      </div>

                      <div className="grid grid-cols-12 gap-3 items-center">
                        {/* Rank */}
                        <div className="col-span-4 border-r border-slate-100 pr-2">
                          <span className="text-2xl font-black text-slate-900 block">12,458</span>
                          <span className="text-[9px] text-slate-400 font-semibold block">Out of 2,35,680 Students</span>
                        </div>

                        {/* Top Performers Avatars */}
                        <div className="col-span-5 flex items-center justify-center gap-2">
                          <div className="text-center">
                            <span className="w-3.5 h-3.5 bg-amber-400 text-white rounded-full text-[9px] font-bold inline-flex items-center justify-center mb-0.5">1</span>
                            <img
                              src="https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=60&auto=format&fit=crop&q=80"
                              alt="Rank 1"
                              className="w-7 h-7 rounded-full object-cover mx-auto border border-amber-400"
                            />
                            <span className="text-[8px] font-bold text-slate-700 block mt-0.5">720 Score</span>
                          </div>

                          <div className="text-center">
                            <span className="w-3.5 h-3.5 bg-slate-300 text-slate-700 rounded-full text-[9px] font-bold inline-flex items-center justify-center mb-0.5">2</span>
                            <img
                              src="https://images.unsplash.com/photo-1517841905240-472988babdf9?w=60&auto=format&fit=crop&q=80"
                              alt="Rank 2"
                              className="w-7 h-7 rounded-full object-cover mx-auto border border-slate-300"
                            />
                            <span className="text-[8px] font-bold text-slate-700 block mt-0.5">715 Score</span>
                          </div>

                          <div className="text-center">
                            <span className="w-3.5 h-3.5 bg-amber-700 text-white rounded-full text-[9px] font-bold inline-flex items-center justify-center mb-0.5">3</span>
                            <img
                              src="https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=60&auto=format&fit=crop&q=80"
                              alt="Rank 3"
                              className="w-7 h-7 rounded-full object-cover mx-auto border border-amber-700"
                            />
                            <span className="text-[8px] font-bold text-slate-700 block mt-0.5">710 Score</span>
                          </div>
                        </div>

                        {/* Your Score */}
                        <div className="col-span-3 text-right border-l border-slate-100 pl-2">
                          <span className="text-[9px] text-slate-400 font-bold block">Your Score</span>
                          <div className="flex items-center justify-end gap-1.5 mt-0.5">
                            <img
                              src="https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=60&auto=format&fit=crop&q=80"
                              alt="Your avatar"
                              className="w-6 h-6 rounded-full object-cover"
                            />
                            <span className="text-xs font-black text-[#5D3EED]">680</span>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                )}

                {/* ========================================================================= */}
                {/* 2. TESTS TAB */}
                {/* ========================================================================= */}
                {(activeTab === 'test' || activeTab === 'tests') && (
                  <MobileMockTestsScreen
                    isMobileFrame={true}
                    onOpenDrawer={() => setIsDrawerOpen(true)}
                    onStartTest={() => {
                      setIsCreatingPractice(false);
                      setIsActivePractice(true);
                    }}
                    onPreviewTest={() => {
                      setIsCreatingPractice(false);
                      setIsActivePractice(true);
                    }}
                  />
                )}

                {/* ========================================================================= */}
                {/* 3. ANALYTICS TAB */}
                {/* ========================================================================= */}
                {activeTab === 'analytics' && (
                  <MobileAnalyticsScreen
                    isMobileFrame={true}
                    onOpenDrawer={() => setIsDrawerOpen(true)}
                  />
                )}
              </>
            )}
          </div>

          {/* MOBILE BOTTOM NAVIGATION BAR (5 OPTIONS: Home, Tests, Practice, Analytics, Profile) */}
          <BottomNav
            activeTab={activeTab}
            onTabChange={(tab) => {
              setIsCreatingPractice(false);
              setIsActivePractice(false);
              setIsFeedbackMode(false);
              setIsSolutionMode(false);
              setIsMobilePricing(false);
              setIsPaymentMode(false);
              setIsPredictionMode(false);
              setActiveTab(tab as any);
            }}
            isMobileFrame={true}
          />
        </div>

    </div>
  );
};
