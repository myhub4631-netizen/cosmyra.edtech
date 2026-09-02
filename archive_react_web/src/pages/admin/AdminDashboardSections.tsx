import React, { useState, useEffect } from 'react';
import {
  LayoutDashboard,
  Eye,
  Settings,
  ShieldCheck,
  Plus,
  Edit2,
  Trash2,
  CheckCircle2,
  XCircle,
  HelpCircle,
  Sparkles,
  ArrowRight,
  ChevronRight,
  ChevronUp,
  ChevronDown,
  Flame,
  Target,
  FileSpreadsheet,
  BookOpen,
  Award,
  Calendar,
  Layers,
  Move,
  Check,
  MoreVertical,
  Save,
} from 'lucide-react';
import {
  fetchDashboardSections,
  updateSectionVisibility,
  updateSectionEnabled,
  updateSectionOrders,
  fetchBanners,
  saveBanner,
  deleteBanner,
  updateBannerOrders,
  fetchQuickStats,
  saveQuickStat,
  deleteQuickStat,
  fetchQuickActions,
  saveQuickAction,
  deleteQuickAction,
  fetchAuditLogs,
} from '../../services/dashboardCmsService';
import {
  DashboardSection,
  DashboardBanner,
  DashboardQuickStat,
  DashboardQuickAction,
  AuditLogEntry,
} from '../../types/dashboardCms';

export const AdminDashboardSections: React.FC = () => {
  const [activeTab, setActiveTab] = useState<string>('Dashboard Sections');
  const [sections, setSections] = useState<DashboardSection[]>([]);
  const [banners, setBanners] = useState<DashboardBanner[]>([]);
  const [quickStats, setQuickStats] = useState<DashboardQuickStat[]>([]);
  const [quickActions, setQuickActions] = useState<DashboardQuickAction[]>([]);
  const [auditLogs, setAuditLogs] = useState<AuditLogEntry[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [isPreviewMobile, setIsPreviewMobile] = useState<boolean>(false);
  const [activeBannerDot, setActiveBannerDot] = useState<number>(0);
  const [toastMessage, setToastMessage] = useState<string | null>(null);
  const [openBannerMenuId, setOpenBannerMenuId] = useState<string | null>(null);

  // Modals State
  const [isBannerModalOpen, setIsBannerModalOpen] = useState<boolean>(false);
  const [editingBanner, setEditingBanner] = useState<Partial<DashboardBanner> | null>(null);

  const [isManageBannerOrderOpen, setIsManageBannerOrderOpen] = useState<boolean>(false);
  const [reorderBanners, setReorderBanners] = useState<DashboardBanner[]>([]);

  const [isStatModalOpen, setIsStatModalOpen] = useState<boolean>(false);
  const [editingStat, setEditingStat] = useState<Partial<DashboardQuickStat> | null>(null);

  const [isActionModalOpen, setIsActionModalOpen] = useState<boolean>(false);
  const [editingAction, setEditingAction] = useState<Partial<DashboardQuickAction> | null>(null);

  useEffect(() => {
    loadData();
  }, []);

  const showNotification = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 3000);
  };

  const loadData = async () => {
    setLoading(true);
    const secs = await fetchDashboardSections();
    const bans = await fetchBanners();
    const stats = await fetchQuickStats();
    const acts = await fetchQuickActions();
    const logs = await fetchAuditLogs();

    setSections(secs);
    setBanners(bans);
    setQuickStats(stats);
    setQuickActions(acts);
    setAuditLogs(logs);
    setLoading(false);
  };

  // TOGGLES
  const handleToggleVisibility = async (sectionKey: string, currentVisibility: boolean) => {
    const success = await updateSectionVisibility(sectionKey, !currentVisibility);
    if (success) {
      setSections((prev) =>
        prev.map((s) => (s.section_key === sectionKey ? { ...s, is_visible: !currentVisibility } : s))
      );
      showNotification(`Visibility updated for section: ${sectionKey}`);
    }
  };

  const handleToggleEnabled = async (sectionKey: string, currentEnabled: boolean) => {
    const success = await updateSectionEnabled(sectionKey, !currentEnabled);
    if (success) {
      setSections((prev) =>
        prev.map((s) => (s.section_key === sectionKey ? { ...s, is_enabled: !currentEnabled } : s))
      );
      showNotification(`Section enabled state updated.`);
    }
  };

  // SAVE ALL CHANGES
  const handleSaveChangesAll = async () => {
    const successSec = await updateSectionOrders(sections);
    const successBan = await updateBannerOrders(banners);
    if (successSec || successBan) {
      showNotification('All dashboard layout changes saved successfully!');
      loadData();
    }
  };

  // BANNER CRUD
  const handleSaveBannerSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingBanner) return;
    const success = await saveBanner(editingBanner);
    if (success) {
      setIsBannerModalOpen(false);
      setEditingBanner(null);
      showNotification('Banner saved successfully!');
      loadData();
    }
  };

  const handleDeleteBannerClick = async (id: string) => {
    setOpenBannerMenuId(null);
    if (window.confirm('Are you sure you want to delete this banner?')) {
      const success = await deleteBanner(id);
      if (success) {
        showNotification('Banner deleted.');
        loadData();
      }
    }
  };

  const handleSaveBannerOrder = async () => {
    const success = await updateBannerOrders(reorderBanners);
    if (success) {
      setIsManageBannerOrderOpen(false);
      showNotification('Banner order saved!');
      loadData();
    }
  };

  const moveBannerItem = (index: number, direction: 'up' | 'down') => {
    const list = [...reorderBanners];
    const targetIndex = direction === 'up' ? index - 1 : index + 1;
    if (targetIndex < 0 || targetIndex >= list.length) return;
    const temp = list[index];
    list[index] = list[targetIndex];
    list[targetIndex] = temp;
    setReorderBanners(list);
  };

  // QUICK STAT CRUD
  const handleSaveStatSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingStat) return;
    const success = await saveQuickStat(editingStat);
    if (success) {
      setIsStatModalOpen(false);
      setEditingStat(null);
      showNotification('Quick Stat saved!');
      loadData();
    }
  };

  const handleDeleteStatClick = async (id: string) => {
    if (window.confirm('Are you sure you want to delete this statistic?')) {
      const success = await deleteQuickStat(id);
      if (success) {
        showNotification('Quick Stat deleted.');
        loadData();
      }
    }
  };

  // QUICK ACTION CRUD
  const handleSaveActionSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingAction) return;
    const success = await saveQuickAction(editingAction);
    if (success) {
      setIsActionModalOpen(false);
      setEditingAction(null);
      showNotification('Quick Action saved!');
      loadData();
    }
  };

  const handleDeleteActionClick = async (id: string) => {
    if (window.confirm('Are you sure you want to delete this action?')) {
      const success = await deleteQuickAction(id);
      if (success) {
        showNotification('Quick Action deleted.');
        loadData();
      }
    }
  };

  // LAYOUT REORDER
  const moveSectionItem = (index: number, direction: 'up' | 'down') => {
    const list = [...sections];
    const targetIndex = direction === 'up' ? index - 1 : index + 1;
    if (targetIndex < 0 || targetIndex >= list.length) return;
    const temp = list[index];
    list[index] = list[targetIndex];
    list[targetIndex] = temp;
    setSections(list);
  };

  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[400px] space-y-3">
        <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-indigo-600"></div>
        <span className="text-xs text-slate-500 font-semibold">Loading Dashboard CMS...</span>
      </div>
    );
  }

  const isSectionEnabled = (key: string) => sections.find((s) => s.section_key === key)?.is_enabled ?? true;

  return (
    <div className="space-y-6 font-sans text-gray-800 pb-12 relative">
      {/* Toast Notification */}
      {toastMessage && (
        <div className="fixed bottom-6 right-6 bg-slate-900 text-white px-4 py-3 rounded-xl shadow-xl text-xs font-bold flex items-center gap-2 z-50 animate-bounce">
          <CheckCircle2 className="w-4 h-4 text-emerald-400" />
          <span>{toastMessage}</span>
        </div>
      )}

      {/* Top Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 tracking-tight">Dashboard Layout Management</h1>
          <p className="text-xs text-slate-500 mt-0.5">
            Customize and manage all sections that appear on the user dashboard.
          </p>
        </div>

        <button
          onClick={handleSaveChangesAll}
          className="flex items-center gap-2 px-5 py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl text-xs font-bold shadow-md shadow-indigo-600/20 transition-all cursor-pointer"
        >
          <Save className="w-4 h-4" />
          <span>Save Changes</span>
        </button>
      </div>

      {/* Sub Header Tabs */}
      <div className="border-b border-slate-200 flex gap-6">
        {['Dashboard Sections', 'Layout & Visibility', 'Settings', 'Preview Dashboard', 'Audit Logs'].map((tab) => {
          const isSelected = activeTab === tab;
          return (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`pb-3 text-sm font-semibold transition-all relative cursor-pointer ${
                isSelected ? 'text-indigo-600 border-b-2 border-indigo-600 font-bold' : 'text-slate-500 hover:text-slate-800'
              }`}
            >
              {tab}
            </button>
          );
        })}
      </div>

      {/* TAB 1: DASHBOARD SECTIONS */}
      {activeTab === 'Dashboard Sections' && (
        <div className="grid grid-cols-1 lg:grid-cols-4 gap-6">
          {/* Main Left Column (3 cols) */}
          <div className="lg:col-span-3 space-y-6">
            {/* 1. BANNER SLIDER CARD */}
            <div className="bg-white rounded-2xl border border-slate-200 p-6 shadow-sm space-y-4">
              <div className="flex flex-wrap items-center justify-between gap-4">
                <div className="flex items-center gap-3">
                  <div className="w-7 h-7 rounded-full bg-indigo-600 text-white flex items-center justify-center font-bold text-xs">
                    1
                  </div>
                  <div>
                    <h2 className="text-base font-bold text-slate-900">Banner Slider</h2>
                    <p className="text-xs text-slate-500">
                      Manage promotional banners that appear at the top of the dashboard
                    </p>
                  </div>
                </div>

                <div className="flex items-center gap-3">
                  <label className="flex items-center gap-2 cursor-pointer text-xs font-semibold text-slate-600">
                    <span>Enable Section</span>
                    <input
                      type="checkbox"
                      checked={isSectionEnabled('banner_slider')}
                      onChange={() => handleToggleEnabled('banner_slider', isSectionEnabled('banner_slider'))}
                      className="w-4 h-4 text-indigo-600 rounded cursor-pointer"
                    />
                  </label>

                  <button
                    onClick={() => {
                      setEditingBanner({
                        title: '',
                        subtitle: '',
                        cta_text: 'Subscribe Now',
                        cta_destination: '/practice',
                        bg_color: '#5B21B6',
                        btn_color: '#FACC15',
                        btn_text_color: '#1E1B4B',
                        target_audience: 'All Students',
                        is_active: true,
                        sort_order: banners.length + 1,
                      });
                      setIsBannerModalOpen(true);
                    }}
                    className="flex items-center gap-1.5 px-3.5 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl text-xs font-bold shadow-sm transition-all cursor-pointer"
                  >
                    <Plus className="w-3.5 h-3.5" />
                    <span>Add Banner</span>
                  </button>

                  <button
                    onClick={() => {
                      setReorderBanners([...banners]);
                      setIsManageBannerOrderOpen(true);
                    }}
                    className="flex items-center gap-1.5 px-3 py-2 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-xl text-xs font-semibold transition-all border border-slate-200 cursor-pointer"
                  >
                    <Move className="w-3.5 h-3.5" />
                    <span>Manage Order</span>
                  </button>
                </div>
              </div>

              {/* Banner Cards Grid / Scroll */}
              <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-4 pt-2">
                {banners.map((b) => (
                  <div
                    key={b.id}
                    className="p-4 rounded-2xl text-white relative shadow-sm flex flex-col justify-between transition-transform hover:-translate-y-0.5"
                    style={{ backgroundColor: b.bg_color || '#5B21B6' }}
                  >
                    <div className="flex items-center justify-between">
                      <span className="text-[10px] font-bold uppercase tracking-wider bg-white/20 px-2.5 py-0.5 rounded-full">
                        {b.is_active ? 'Active' : 'Disabled'}
                      </span>
                      <div className="relative">
                        <button
                          onClick={() => setOpenBannerMenuId(openBannerMenuId === b.id ? null : b.id)}
                          className="p-1 hover:bg-white/20 rounded cursor-pointer"
                        >
                          <MoreVertical className="w-4 h-4 text-white" />
                        </button>

                        {openBannerMenuId === b.id && (
                          <div className="absolute right-0 top-6 w-32 bg-white rounded-xl shadow-xl py-1 text-slate-800 text-xs font-semibold z-20 border border-slate-100">
                            <button
                              onClick={() => {
                                setOpenBannerMenuId(null);
                                setEditingBanner(b);
                                setIsBannerModalOpen(true);
                              }}
                              className="w-full text-left px-3 py-1.5 hover:bg-slate-50 flex items-center gap-2 text-slate-700"
                            >
                              <Edit2 className="w-3.5 h-3.5 text-indigo-600" />
                              <span>Edit</span>
                            </button>
                            <button
                              onClick={() => handleDeleteBannerClick(b.id)}
                              className="w-full text-left px-3 py-1.5 hover:bg-rose-50 flex items-center gap-2 text-rose-600"
                            >
                              <Trash2 className="w-3.5 h-3.5" />
                              <span>Delete</span>
                            </button>
                          </div>
                        )}
                      </div>
                    </div>

                    <div className="my-4">
                      <h3 className="text-sm font-bold whitespace-pre-line leading-tight">{b.title}</h3>
                      <p className="text-[11px] text-white/80 mt-1">{b.subtitle}</p>
                    </div>

                    <div>
                      <span
                        className="inline-block px-3 py-1 rounded-lg text-[11px] font-bold shadow-sm"
                        style={{ backgroundColor: b.btn_color || '#FACC15', color: b.btn_text_color || '#1E1B4B' }}
                      >
                        {b.cta_text}
                      </span>
                    </div>
                  </div>
                ))}
              </div>

              {/* Carousel Dots */}
              <div className="flex items-center justify-center gap-1.5 pt-2">
                {banners.map((_, i) => (
                  <button
                    key={i}
                    onClick={() => setActiveBannerDot(i)}
                    className={`h-2 rounded-full transition-all cursor-pointer ${
                      activeBannerDot === i ? 'w-6 bg-indigo-600' : 'w-2 bg-slate-300'
                    }`}
                  />
                ))}
              </div>
            </div>

            {/* 2. QUICK STATS CARD */}
            <div className="bg-white rounded-2xl border border-slate-200 p-6 shadow-sm space-y-4">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className="w-7 h-7 rounded-full bg-indigo-600 text-white flex items-center justify-center font-bold text-xs">
                    2
                  </div>
                  <div>
                    <h2 className="text-base font-bold text-slate-900">Quick Stats</h2>
                    <p className="text-xs text-slate-500">Manage the statistics cards shown below the banner</p>
                  </div>
                </div>

                <div className="flex items-center gap-4">
                  <label className="flex items-center gap-2 cursor-pointer text-xs font-semibold text-slate-600">
                    <span>Enable Section</span>
                    <input
                      type="checkbox"
                      checked={isSectionEnabled('quick_stats')}
                      onChange={() => handleToggleEnabled('quick_stats', isSectionEnabled('quick_stats'))}
                      className="w-4 h-4 text-indigo-600 rounded cursor-pointer"
                    />
                  </label>

                  <button
                    onClick={() => {
                      setEditingStat({
                        title: '',
                        data_source: 'user_stats.questions_attempted',
                        change_text: '↑ 10%',
                        status: 'Active',
                        is_enabled: true,
                        sort_order: quickStats.length + 1,
                      });
                      setIsStatModalOpen(true);
                    }}
                    className="flex items-center gap-1.5 px-3.5 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl text-xs font-bold shadow-sm transition-all cursor-pointer"
                  >
                    <Plus className="w-3.5 h-3.5" />
                    <span>Add Stat</span>
                  </button>
                </div>
              </div>

              {/* Table */}
              <div className="overflow-x-auto">
                <table className="w-full text-left text-xs">
                  <thead>
                    <tr className="border-b border-slate-200 text-slate-400 font-bold uppercase tracking-wider">
                      <th className="pb-3 px-2">#</th>
                      <th className="pb-3 px-2">Title</th>
                      <th className="pb-3 px-2">Data Source</th>
                      <th className="pb-3 px-2">Change (vs last 7 days)</th>
                      <th className="pb-3 px-2">Status</th>
                      <th className="pb-3 px-2 text-right">Actions</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100 font-medium">
                    {quickStats.map((s, idx) => (
                      <tr key={s.id} className="hover:bg-slate-50/50">
                        <td className="py-3 px-2 text-slate-400">{idx + 1}</td>
                        <td className="py-3 px-2 font-bold text-slate-900">{s.title}</td>
                        <td className="py-3 px-2 font-mono text-slate-500">{s.data_source}</td>
                        <td className="py-3 px-2 text-emerald-600 font-bold">{s.change_text}</td>
                        <td className="py-3 px-2">
                          <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-emerald-50 text-emerald-600">
                            {s.status}
                          </span>
                        </td>
                        <td className="py-3 px-2 text-right space-x-2">
                          <button
                            onClick={() => {
                              setEditingStat(s);
                              setIsStatModalOpen(true);
                            }}
                            className="p-1.5 hover:bg-slate-100 rounded text-indigo-600 cursor-pointer"
                            title="Edit Stat"
                          >
                            <Edit2 className="w-3.5 h-3.5" />
                          </button>
                          <button
                            onClick={() => handleDeleteStatClick(s.id)}
                            className="p-1.5 hover:bg-rose-50 rounded text-rose-600 cursor-pointer"
                            title="Delete Stat"
                          >
                            <Trash2 className="w-3.5 h-3.5" />
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>

            {/* 3. QUICK ACTIONS CARD */}
            <div className="bg-white rounded-2xl border border-slate-200 p-6 shadow-sm space-y-4">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className="w-7 h-7 rounded-full bg-indigo-600 text-white flex items-center justify-center font-bold text-xs">
                    3
                  </div>
                  <div>
                    <h2 className="text-base font-bold text-slate-900">Quick Actions</h2>
                    <p className="text-xs text-slate-500">Manage quick action buttons for easy navigation</p>
                  </div>
                </div>

                <div className="flex items-center gap-4">
                  <label className="flex items-center gap-2 cursor-pointer text-xs font-semibold text-slate-600">
                    <span>Enable Section</span>
                    <input
                      type="checkbox"
                      checked={isSectionEnabled('quick_actions')}
                      onChange={() => handleToggleEnabled('quick_actions', isSectionEnabled('quick_actions'))}
                      className="w-4 h-4 text-indigo-600 rounded cursor-pointer"
                    />
                  </label>

                  <button
                    onClick={() => {
                      setEditingAction({
                        title: '',
                        description: '',
                        destination: '/practice',
                        is_enabled: true,
                        sort_order: quickActions.length + 1,
                        target_exam: 'All',
                      });
                      setIsActionModalOpen(true);
                    }}
                    className="flex items-center gap-1.5 px-3.5 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl text-xs font-bold shadow-sm transition-all cursor-pointer"
                  >
                    <Plus className="w-3.5 h-3.5" />
                    <span>Add Action</span>
                  </button>
                </div>
              </div>

              {/* Table */}
              <div className="overflow-x-auto">
                <table className="w-full text-left text-xs">
                  <thead>
                    <tr className="border-b border-slate-200 text-slate-400 font-bold uppercase tracking-wider">
                      <th className="pb-3 px-2">#</th>
                      <th className="pb-3 px-2">Title</th>
                      <th className="pb-3 px-2">Navigation Destination</th>
                      <th className="pb-3 px-2">Status</th>
                      <th className="pb-3 px-2 text-right">Actions</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100 font-medium">
                    {quickActions.map((a, idx) => (
                      <tr key={a.id} className="hover:bg-slate-50/50">
                        <td className="py-3 px-2 text-slate-400">{idx + 1}</td>
                        <td className="py-3 px-2 font-bold text-slate-900">{a.title}</td>
                        <td className="py-3 px-2 font-mono text-indigo-600">Navigate to {a.destination}</td>
                        <td className="py-3 px-2">
                          <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-emerald-50 text-emerald-600">
                            Active
                          </span>
                        </td>
                        <td className="py-3 px-2 text-right space-x-2">
                          <button
                            onClick={() => {
                              setEditingAction(a);
                              setIsActionModalOpen(true);
                            }}
                            className="p-1.5 hover:bg-slate-100 rounded text-indigo-600 cursor-pointer"
                            title="Edit Action"
                          >
                            <Edit2 className="w-3.5 h-3.5" />
                          </button>
                          <button
                            onClick={() => handleDeleteActionClick(a.id)}
                            className="p-1.5 hover:bg-rose-50 rounded text-rose-600 cursor-pointer"
                            title="Delete Action"
                          >
                            <Trash2 className="w-3.5 h-3.5" />
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          {/* Right Column: Section Visibility Panel */}
          <div className="space-y-6">
            <div className="bg-white rounded-2xl border border-slate-200 p-5 shadow-sm space-y-4">
              <div>
                <h3 className="text-sm font-bold text-slate-900">Section Visibility</h3>
                <p className="text-[11px] text-slate-500">Show / hide entire sections on the dashboard</p>
              </div>

              <div className="space-y-3">
                {sections.map((sec) => (
                  <div key={sec.section_key} className="flex items-center justify-between text-xs font-semibold text-slate-700">
                    <span>{sec.title}</span>
                    <input
                      type="checkbox"
                      checked={sec.is_visible}
                      onChange={() => handleToggleVisibility(sec.section_key, sec.is_visible)}
                      className="w-4 h-4 text-indigo-600 rounded cursor-pointer accent-indigo-600"
                    />
                  </div>
                ))}
              </div>
            </div>

            {/* Tips Card */}
            <div className="bg-amber-50/70 border border-amber-200 p-4 rounded-2xl text-xs space-y-2">
              <div className="flex items-center gap-2 text-amber-800 font-bold">
                <Sparkles className="w-4 h-4 text-amber-600" />
                <span>Tips</span>
              </div>
              <ul className="space-y-1 text-amber-700 text-[11px]">
                <li>• Drag and drop to reorder items in each section.</li>
                <li>• Changes reflect in real-time on user dashboard.</li>
                <li>• Use Preview to see how changes look for users.</li>
              </ul>
            </div>

            {/* Need Help Card */}
            <div className="bg-white border border-slate-200 p-4 rounded-2xl text-xs space-y-2">
              <span className="font-bold text-slate-900 block">Need Help?</span>
              <p className="text-[11px] text-slate-500">Learn how to customize the dashboard with our guide.</p>
              <button className="px-3 py-1.5 border border-indigo-200 text-indigo-600 hover:bg-indigo-50 rounded-lg text-xs font-bold transition-all cursor-pointer">
                View Documentation
              </button>
            </div>
          </div>
        </div>
      )}

      {/* TAB 2: LAYOUT & VISIBILITY */}
      {activeTab === 'Layout & Visibility' && (
        <div className="bg-white rounded-2xl border border-slate-200 p-6 shadow-sm space-y-6">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-base font-bold text-slate-900">Reorder Dashboard Sections</h2>
              <p className="text-xs text-slate-500">Move sections up/down to customize the Student App layout.</p>
            </div>
            <button
              onClick={handleSaveChangesAll}
              className="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl text-xs font-bold shadow-sm cursor-pointer"
            >
              Save Layout Order
            </button>
          </div>

          <div className="space-y-2">
            {sections.map((sec, idx) => (
              <div key={sec.section_key} className="flex items-center justify-between p-3.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold text-slate-800">
                <div className="flex items-center gap-3">
                  <span className="w-6 h-6 rounded-full bg-slate-200 text-slate-700 flex items-center justify-center font-bold text-[11px]">
                    {idx + 1}
                  </span>
                  <div>
                    <span className="font-bold block">{sec.title}</span>
                    <span className="text-[10px] text-slate-400 font-normal">{sec.subtitle}</span>
                  </div>
                </div>

                <div className="flex items-center gap-2">
                  <button onClick={() => moveSectionItem(idx, 'up')} disabled={idx === 0} className="p-1 hover:bg-slate-200 rounded disabled:opacity-30 cursor-pointer">
                    <ChevronUp className="w-4 h-4" />
                  </button>
                  <button onClick={() => moveSectionItem(idx, 'down')} disabled={idx === sections.length - 1} className="p-1 hover:bg-slate-200 rounded disabled:opacity-30 cursor-pointer">
                    <ChevronDown className="w-4 h-4" />
                  </button>
                  <label className="flex items-center gap-1 ml-4 cursor-pointer">
                    <span className="text-[11px] text-slate-500">Visible</span>
                    <input
                      type="checkbox"
                      checked={sec.is_visible}
                      onChange={() => handleToggleVisibility(sec.section_key, sec.is_visible)}
                      className="w-4 h-4 text-indigo-600 rounded cursor-pointer"
                    />
                  </label>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* TAB 4: PREVIEW DASHBOARD */}
      {activeTab === 'Preview Dashboard' && (
        <div className="bg-white rounded-2xl border border-slate-200 p-6 shadow-sm space-y-6">
          <div className="bg-indigo-600 text-white p-4 rounded-xl flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Eye className="w-5 h-5" />
              <span className="font-bold text-sm">PREVIEW MODE - Student App Simulation</span>
            </div>
            <div className="flex gap-2">
              <button
                onClick={() => setIsPreviewMobile(false)}
                className={`px-3 py-1 rounded-lg text-xs font-bold cursor-pointer ${!isPreviewMobile ? 'bg-white text-indigo-600' : 'bg-indigo-700'}`}
              >
                Desktop
              </button>
              <button
                onClick={() => setIsPreviewMobile(true)}
                className={`px-3 py-1 rounded-lg text-xs font-bold cursor-pointer ${isPreviewMobile ? 'bg-white text-indigo-600' : 'bg-indigo-700'}`}
              >
                Mobile
              </button>
            </div>
          </div>

          <div className={`mx-auto p-6 bg-slate-50 rounded-2xl border border-slate-200 space-y-6 ${isPreviewMobile ? 'max-w-md' : 'w-full'}`}>
            <h2 className="text-xl font-bold text-slate-900">Good Morning, Arjun! 👋</h2>
            {banners.filter((b) => b.is_active)[0] && (
              <div
                className="p-6 rounded-2xl text-white space-y-2 shadow-md"
                style={{ backgroundColor: banners.filter((b) => b.is_active)[0].bg_color || '#5B21B6' }}
              >
                <h3 className="text-lg font-bold">{banners.filter((b) => b.is_active)[0].title}</h3>
                <p className="text-xs text-white/80">{banners.filter((b) => b.is_active)[0].subtitle}</p>
                <button
                  className="px-4 py-2 rounded-lg text-xs font-bold mt-2"
                  style={{
                    backgroundColor: banners.filter((b) => b.is_active)[0].btn_color || '#FACC15',
                    color: banners.filter((b) => b.is_active)[0].btn_text_color || '#1E1B4B',
                  }}
                >
                  {banners.filter((b) => b.is_active)[0].cta_text}
                </button>
              </div>
            )}
          </div>
        </div>
      )}

      {/* TAB 5: AUDIT LOGS */}
      {activeTab === 'Audit Logs' && (
        <div className="bg-white rounded-2xl border border-slate-200 p-6 shadow-sm space-y-4">
          <h2 className="text-base font-bold text-slate-900">Admin Audit Log History</h2>
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead>
                <tr className="border-b border-slate-200 text-slate-400 font-bold uppercase tracking-wider">
                  <th className="pb-3 px-2">Timestamp</th>
                  <th className="pb-3 px-2">Admin User</th>
                  <th className="pb-3 px-2">Action</th>
                  <th className="pb-3 px-2">Entity Type</th>
                  <th className="pb-3 px-2">Details</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 font-medium">
                {auditLogs.map((log) => (
                  <tr key={log.id} className="hover:bg-slate-50/50">
                    <td className="py-3 px-2 text-slate-500">{new Date(log.created_at).toLocaleString()}</td>
                    <td className="py-3 px-2 font-bold text-slate-800">{log.user_email}</td>
                    <td className="py-3 px-2 text-indigo-600 font-bold">{log.action}</td>
                    <td className="py-3 px-2 text-slate-600">{log.entity_type}</td>
                    <td className="py-3 px-2 font-mono text-[10px] text-slate-400">{JSON.stringify(log.details)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* MODAL: ADD / EDIT BANNER */}
      {isBannerModalOpen && editingBanner && (
        <div className="fixed inset-0 bg-slate-900/50 flex items-center justify-center p-4 z-50">
          <form onSubmit={handleSaveBannerSubmit} className="bg-white rounded-2xl p-6 max-w-md w-full space-y-4 shadow-xl">
            <h3 className="text-base font-bold text-slate-900">
              {editingBanner.id ? 'Edit Banner' : 'Add Banner'}
            </h3>

            <div className="space-y-3 text-xs">
              <div>
                <label className="font-semibold block mb-1">Title</label>
                <textarea
                  required
                  rows={2}
                  value={editingBanner.title || ''}
                  onChange={(e) => setEditingBanner({ ...editingBanner, title: e.target.value })}
                  className="w-full p-2 border border-slate-200 rounded-lg"
                />
              </div>

              <div>
                <label className="font-semibold block mb-1">Subtitle</label>
                <input
                  type="text"
                  value={editingBanner.subtitle || ''}
                  onChange={(e) => setEditingBanner({ ...editingBanner, subtitle: e.target.value })}
                  className="w-full p-2 border border-slate-200 rounded-lg"
                />
              </div>

              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="font-semibold block mb-1">CTA Button Text</label>
                  <input
                    type="text"
                    value={editingBanner.cta_text || ''}
                    onChange={(e) => setEditingBanner({ ...editingBanner, cta_text: e.target.value })}
                    className="w-full p-2 border border-slate-200 rounded-lg"
                  />
                </div>
                <div>
                  <label className="font-semibold block mb-1">Destination Route</label>
                  <input
                    type="text"
                    value={editingBanner.cta_destination || ''}
                    onChange={(e) => setEditingBanner({ ...editingBanner, cta_destination: e.target.value })}
                    className="w-full p-2 border border-slate-200 rounded-lg"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="font-semibold block mb-1">Background Color</label>
                  <input
                    type="color"
                    value={editingBanner.bg_color || '#5B21B6'}
                    onChange={(e) => setEditingBanner({ ...editingBanner, bg_color: e.target.value })}
                    className="w-full h-8 p-1 border border-slate-200 rounded-lg cursor-pointer"
                  />
                </div>
                <div>
                  <label className="font-semibold block mb-1">Target Audience</label>
                  <select
                    value={editingBanner.target_audience || 'All Students'}
                    onChange={(e) => setEditingBanner({ ...editingBanner, target_audience: e.target.value })}
                    className="w-full p-2 border border-slate-200 rounded-lg"
                  >
                    <option value="All Students">All Students</option>
                    <option value="NEET">NEET</option>
                    <option value="JEE Main">JEE Main</option>
                    <option value="JEE Advanced">JEE Advanced</option>
                  </select>
                </div>
              </div>
            </div>

            <div className="flex justify-end gap-3 pt-4 border-t border-slate-100">
              <button
                type="button"
                onClick={() => setIsBannerModalOpen(false)}
                className="px-4 py-2 bg-slate-100 hover:bg-slate-200 rounded-lg text-xs font-semibold text-slate-700 cursor-pointer"
              >
                Cancel
              </button>
              <button
                type="submit"
                className="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg text-xs font-bold cursor-pointer"
              >
                Save Banner
              </button>
            </div>
          </form>
        </div>
      )}

      {/* MODAL: MANAGE BANNER ORDER */}
      {isManageBannerOrderOpen && (
        <div className="fixed inset-0 bg-slate-900/50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl p-6 max-w-md w-full space-y-4 shadow-xl">
            <h3 className="text-base font-bold text-slate-900">Manage Banner Order</h3>

            <div className="space-y-2 max-h-[300px] overflow-y-auto">
              {reorderBanners.map((b, idx) => (
                <div key={b.id} className="flex items-center justify-between p-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold">
                  <div className="truncate max-w-[200px]">
                    <span className="font-bold">{idx + 1}. </span>
                    <span>{b.title.replaceAll('\n', ' ')}</span>
                  </div>
                  <div className="flex items-center gap-1">
                    <button onClick={() => moveBannerItem(idx, 'up')} disabled={idx === 0} className="p-1 hover:bg-slate-200 rounded disabled:opacity-30 cursor-pointer">
                      <ChevronUp className="w-4 h-4" />
                    </button>
                    <button onClick={() => moveBannerItem(idx, 'down')} disabled={idx === reorderBanners.length - 1} className="p-1 hover:bg-slate-200 rounded disabled:opacity-30 cursor-pointer">
                      <ChevronDown className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              ))}
            </div>

            <div className="flex justify-end gap-3 pt-4 border-t border-slate-100">
              <button onClick={() => setIsManageBannerOrderOpen(false)} className="px-4 py-2 bg-slate-100 rounded-lg text-xs font-semibold cursor-pointer">
                Cancel
              </button>
              <button onClick={handleSaveBannerOrder} className="px-4 py-2 bg-indigo-600 text-white rounded-lg text-xs font-bold cursor-pointer">
                Save Order
              </button>
            </div>
          </div>
        </div>
      )}

      {/* MODAL: ADD / EDIT STAT */}
      {isStatModalOpen && editingStat && (
        <div className="fixed inset-0 bg-slate-900/50 flex items-center justify-center p-4 z-50">
          <form onSubmit={handleSaveStatSubmit} className="bg-white rounded-2xl p-6 max-w-md w-full space-y-4 shadow-xl">
            <h3 className="text-base font-bold text-slate-900">
              {editingStat.id ? 'Edit Quick Stat' : 'Add Quick Stat'}
            </h3>

            <div className="space-y-3 text-xs">
              <div>
                <label className="font-semibold block mb-1">Stat Title</label>
                <input
                  type="text"
                  required
                  value={editingStat.title || ''}
                  onChange={(e) => setEditingStat({ ...editingStat, title: e.target.value, stat_key: e.target.value.toLowerCase().replaceAll(' ', '_') })}
                  className="w-full p-2 border border-slate-200 rounded-lg"
                />
              </div>

              <div>
                <label className="font-semibold block mb-1">Data Source Field</label>
                <select
                  value={editingStat.data_source || 'user_stats.questions_attempted'}
                  onChange={(e) => setEditingStat({ ...editingStat, data_source: e.target.value })}
                  className="w-full p-2 border border-slate-200 rounded-lg font-mono text-xs"
                >
                  <option value="user_stats.questions_attempted">user_stats.questions_attempted</option>
                  <option value="user_stats.accuracy">user_stats.accuracy</option>
                  <option value="user_stats.tests_completed">user_stats.tests_completed</option>
                  <option value="user_stats.study_streak">user_stats.study_streak</option>
                </select>
              </div>

              <div>
                <label className="font-semibold block mb-1">Change Label (vs 7 days)</label>
                <input
                  type="text"
                  value={editingStat.change_text || ''}
                  onChange={(e) => setEditingStat({ ...editingStat, change_text: e.target.value })}
                  className="w-full p-2 border border-slate-200 rounded-lg"
                />
              </div>
            </div>

            <div className="flex justify-end gap-3 pt-4 border-t border-slate-100">
              <button type="button" onClick={() => setIsStatModalOpen(false)} className="px-4 py-2 bg-slate-100 rounded-lg text-xs font-semibold cursor-pointer">
                Cancel
              </button>
              <button type="submit" className="px-4 py-2 bg-indigo-600 text-white rounded-lg text-xs font-bold cursor-pointer">
                Save Stat
              </button>
            </div>
          </form>
        </div>
      )}

      {/* MODAL: ADD / EDIT ACTION */}
      {isActionModalOpen && editingAction && (
        <div className="fixed inset-0 bg-slate-900/50 flex items-center justify-center p-4 z-50">
          <form onSubmit={handleSaveActionSubmit} className="bg-white rounded-2xl p-6 max-w-md w-full space-y-4 shadow-xl">
            <h3 className="text-base font-bold text-slate-900">
              {editingAction.id ? 'Edit Quick Action' : 'Add Quick Action'}
            </h3>

            <div className="space-y-3 text-xs">
              <div>
                <label className="font-semibold block mb-1">Action Title</label>
                <input
                  type="text"
                  required
                  value={editingAction.title || ''}
                  onChange={(e) => setEditingAction({ ...editingAction, title: e.target.value, action_key: e.target.value.toLowerCase().replaceAll(' ', '_') })}
                  className="w-full p-2 border border-slate-200 rounded-lg"
                />
              </div>

              <div>
                <label className="font-semibold block mb-1">Destination Route</label>
                <input
                  type="text"
                  required
                  value={editingAction.destination || ''}
                  onChange={(e) => setEditingAction({ ...editingAction, destination: e.target.value })}
                  className="w-full p-2 border border-slate-200 rounded-lg font-mono text-xs"
                />
              </div>
            </div>

            <div className="flex justify-end gap-3 pt-4 border-t border-slate-100">
              <button type="button" onClick={() => setIsActionModalOpen(false)} className="px-4 py-2 bg-slate-100 rounded-lg text-xs font-semibold cursor-pointer">
                Cancel
              </button>
              <button type="submit" className="px-4 py-2 bg-indigo-600 text-white rounded-lg text-xs font-bold cursor-pointer">
                Save Action
              </button>
            </div>
          </form>
        </div>
      )}
    </div>
  );
};
