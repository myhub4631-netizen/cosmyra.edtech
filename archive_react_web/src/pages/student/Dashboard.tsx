import React, { useState, useEffect } from 'react';
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
import {
  fetchDashboardSections,
  fetchBanners,
  fetchQuickStats,
  fetchQuickActions,
} from '../../services/dashboardCmsService';
import {
  DashboardSection,
  DashboardBanner,
  DashboardQuickStat,
  DashboardQuickAction,
} from '../../types/dashboardCms';

interface StudentDashboardProps {
  onNavigate: (tab: string) => void;
  selectedExam: string;
}

export const StudentDashboard: React.FC<StudentDashboardProps> = ({
  onNavigate,
  selectedExam = 'NEET',
}) => {
  const [sections, setSections] = useState<DashboardSection[]>([]);
  const [banners, setBanners] = useState<DashboardBanner[]>([]);
  const [quickStats, setQuickStats] = useState<DashboardQuickStat[]>([]);
  const [quickActions, setQuickActions] = useState<DashboardQuickAction[]>([]);
  const [activeBannerIdx, setActiveBannerIdx] = useState<number>(0);

  useEffect(() => {
    loadCmsData();
  }, []);

  const loadCmsData = async () => {
    const secs = await fetchDashboardSections();
    const bans = await fetchBanners();
    const stats = await fetchQuickStats();
    const acts = await fetchQuickActions();

    setSections(secs);
    setBanners(bans.filter((b) => b.is_active));
    setQuickStats(stats.filter((s) => s.is_enabled));
    setQuickActions(acts.filter((a) => a.is_enabled));
  };

  const isVisible = (key: string) => {
    if (sections.length === 0) return true;
    const sec = sections.find((s) => s.section_key === key);
    return sec ? sec.is_enabled && sec.is_visible : true;
  };

  return (
    <div className="space-y-6 font-sans text-gray-800 pb-12">
      {/* Header Bar & Streak Tracker */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 tracking-tight">Good Morning, Arjun! 👋</h1>
          <p className="text-xs text-gray-500 mt-0.5">Let's continue your {selectedExam} preparation journey.</p>
        </div>

        {/* Streak Counter Card */}
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

          <div className="flex items-center gap-1 border-l border-gray-100 pl-3">
            {['T', 'W', 'T', 'F', 'S', 'S'].map((day, i) => (
              <div key={i} className="text-center">
                <span className="text-[9px] font-bold text-gray-400 block mb-0.5">{day}</span>
                <span className="w-4 h-4 rounded-full bg-emerald-500 text-white text-[9px] font-bold flex items-center justify-center">
                  ✓
                </span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* DYNAMIC BANNER SLIDER */}
      {isVisible('banner_slider') && banners.length > 0 && (
        <div
          className="p-6 rounded-2xl text-white relative shadow-md transition-all space-y-3"
          style={{ backgroundColor: banners[activeBannerIdx]?.bg_color || '#5B21B6' }}
        >
          <div className="flex justify-between items-start">
            <div>
              <span className="text-[10px] font-bold uppercase tracking-wider bg-white/20 px-2.5 py-0.5 rounded-full">
                Featured • {banners[activeBannerIdx]?.target_audience || 'All'}
              </span>
              <h2 className="text-xl font-bold whitespace-pre-line leading-tight mt-2">
                {banners[activeBannerIdx]?.title}
              </h2>
              <p className="text-xs text-white/80 mt-1">{banners[activeBannerIdx]?.subtitle}</p>
            </div>
          </div>

          <div className="flex items-center justify-between pt-2">
            <button
              onClick={() => onNavigate('custom_practice')}
              className="px-4 py-2 rounded-xl text-xs font-bold shadow-sm transition-transform hover:scale-105"
              style={{
                backgroundColor: banners[activeBannerIdx]?.btn_color || '#FACC15',
                color: banners[activeBannerIdx]?.btn_text_color || '#1E1B4B',
              }}
            >
              {banners[activeBannerIdx]?.cta_text || 'Start Practicing'}
            </button>

            <div className="flex items-center gap-1.5">
              {banners.map((_, i) => (
                <button
                  key={i}
                  onClick={() => setActiveBannerIdx(i)}
                  className={`h-2 rounded-full transition-all cursor-pointer ${
                    activeBannerIdx === i ? 'w-6 bg-white' : 'w-2 bg-white/40'
                  }`}
                />
              ))}
            </div>
          </div>
        </div>
      )}

      {/* DYNAMIC QUICK STATS */}
      {isVisible('quick_stats') && (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {quickStats.map((stat) => (
            <div key={stat.id} className="bg-white p-4 rounded-2xl border border-gray-200 shadow-sm flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-indigo-50 text-indigo-600 flex items-center justify-center flex-shrink-0">
                <Target className="w-5 h-5" />
              </div>
              <div>
                <span className="text-xl font-bold text-gray-900 block leading-tight">
                  {stat.stat_key === 'questions_attempted' ? '2,458' : stat.stat_key === 'accuracy' ? '78.4%' : stat.stat_key === 'tests_completed' ? '14' : '12 Days'}
                </span>
                <span className="text-[11px] font-semibold text-gray-400 block">{stat.title}</span>
                <span className="text-[10px] font-bold text-emerald-600 block mt-0.5">{stat.change_text}</span>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* DYNAMIC QUICK ACTIONS */}
      {isVisible('quick_actions') && (
        <div className="bg-white p-5 rounded-2xl border border-gray-200 shadow-sm space-y-3">
          <h3 className="text-sm font-bold text-gray-900">Quick Actions</h3>
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
            {quickActions.map((action) => (
              <button
                key={action.id}
                onClick={() => {
                  if (action.destination.includes('practice')) onNavigate('custom_practice');
                  else if (action.destination.includes('test')) onNavigate('custom_test');
                  else if (action.destination.includes('pyq')) onNavigate('pyq');
                  else onNavigate('custom_practice');
                }}
                className="p-3 bg-slate-50 hover:bg-slate-100 rounded-xl border border-slate-200 text-left transition-all cursor-pointer space-y-1"
              >
                <span className="text-xs font-bold text-slate-800 block">{action.title}</span>
                <span className="text-[10px] text-slate-400 block">{action.description || 'Quick launch'}</span>
              </button>
            ))}
          </div>
        </div>
      )}
    </div>
  );
};
