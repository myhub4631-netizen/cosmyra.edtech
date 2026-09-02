import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Search,
  Bell,
  HelpCircle,
  Plus,
  Users,
  CheckCircle2,
  Calendar,
  TrendingUp,
  Percent,
  Star,
  Rocket,
  Crown,
  Gem,
  MoreHorizontal,
  ChevronDown,
  Settings,
  PlusCircle,
  SlidersHorizontal,
  FileSpreadsheet,
  Download,
  Edit2,
  ArrowUpRight,
  BookOpen,
  FileText,
  BarChart3,
  Sliders,
  DollarSign,
  ShieldCheck,
  Tag,
  Layers,
  GraduationCap,
} from 'lucide-react';
import { AdminSidebar } from '../../components/layout/AdminSidebar';

export const AdminPricingPlans: React.FC = () => {
  const navigate = useNavigate();

  // State management
  const [activeTab, setActiveTab] = useState<'plans' | 'features' | 'comparisons' | 'subscribers' | 'settings'>('plans');
  const [showInactive, setShowInactive] = useState<boolean>(false);
  const [defaultPlan, setDefaultPlan] = useState<string>('pro');
  const [allowDowngrade, setAllowDowngrade] = useState<boolean>(true);
  const [allowUpgrade, setAllowUpgrade] = useState<boolean>(true);
  const [autoRenewal, setAutoRenewal] = useState<boolean>(true);
  const [selectedPlanView, setSelectedPlanView] = useState<string>('pro');

  // Feature Toggle States for Matrix
  const [features, setFeatures] = useState([
    {
      id: 1,
      name: 'Unlimited Question Practice',
      description: 'Access unlimited questions across all subjects and topics',
      trial: false,
      starter: true,
      pro: true,
      ultimate: true,
    },
    {
      id: 2,
      name: 'Custom Practice',
      description: 'Create custom practice sessions',
      trial: false,
      starter: true,
      pro: true,
      ultimate: true,
    },
    {
      id: 3,
      name: 'Unlimited Mock Tests',
      description: 'Access unlimited mock tests',
      trial: false,
      starter: false,
      pro: true,
      ultimate: true,
    },
  ]);

  const toggleFeature = (id: number, key: 'trial' | 'starter' | 'pro' | 'ultimate') => {
    setFeatures(
      features.map((f) => (f.id === id ? { ...f, [key]: !f[key] } : f))
    );
  };

  return (
    <div className="space-y-6 text-slate-900 select-none">
      
      {/* Top Header Card */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 bg-white p-4 rounded-3xl border border-slate-200/80 shadow-xs">
        <div>
          <h1 className="text-xl font-black text-slate-900 tracking-tight">Pricing & Plans</h1>
          <p className="text-xs text-slate-500 font-medium mt-0.5">
            Manage subscription plans, pricing, features and user access.
          </p>
        </div>

        <div className="flex items-center gap-3">
          {/* Search Bar */}
          <div className="relative hidden md:block">
            <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              placeholder="Search anything... ⌘K"
              className="pl-9 pr-4 py-2 bg-slate-100 border border-slate-200 rounded-xl text-xs text-slate-700 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 w-60"
            />
          </div>

            {/* Notification Bell */}
            <button className="relative p-2 rounded-xl text-slate-600 hover:bg-slate-100 transition-colors">
              <Bell className="w-5 h-5" />
              <span className="absolute top-1 right-1 w-4 h-4 bg-rose-500 text-white text-[10px] font-bold rounded-full flex items-center justify-center border-2 border-white">
                5
              </span>
            </button>

            {/* Help Button */}
            <button className="p-2 rounded-xl text-slate-600 hover:bg-slate-100 transition-colors">
              <HelpCircle className="w-5 h-5" />
            </button>

            {/* User Profile */}
            <div className="flex items-center gap-3.5 pl-2 border-l border-slate-200">
              <div className="w-9 h-9 rounded-full bg-gradient-to-tr from-indigo-500 to-purple-600 text-white flex items-center justify-center font-bold text-xs shadow-sm">
                A
              </div>
              <div className="hidden sm:block leading-tight">
                <span className="text-xs font-bold text-slate-900 block">Admin</span>
                <span className="text-[10px] text-slate-400 font-medium block">Super Admin</span>
              </div>
            </div>

            {/* Create New Plan Action Button */}
            <button className="px-4 py-2.5 bg-[#4F46E5] hover:bg-[#4338CA] text-white font-extrabold text-xs rounded-xl flex items-center gap-1.5 shadow-md shadow-indigo-600/20 transition-all">
              <Plus className="w-4 h-4 stroke-[3]" />
              <span>Create New Plan</span>
            </button>
          </div>
        </div>

        {/* TABS SUB-NAVIGATION BAR */}
        <div className="bg-white border-b border-slate-200 px-6 pt-3 flex items-center gap-8 text-xs font-bold text-slate-500">
          <button
            onClick={() => setActiveTab('plans')}
            className={`pb-3 transition-colors ${
              activeTab === 'plans'
                ? 'text-[#4F46E5] font-extrabold border-b-2 border-[#4F46E5]'
                : 'hover:text-slate-800'
            }`}
          >
            Plans
          </button>
          <button
            onClick={() => setActiveTab('features')}
            className={`pb-3 transition-colors ${
              activeTab === 'features'
                ? 'text-[#4F46E5] font-extrabold border-b-2 border-[#4F46E5]'
                : 'hover:text-slate-800'
            }`}
          >
            Features
          </button>
          <button
            onClick={() => setActiveTab('comparisons')}
            className={`pb-3 transition-colors ${
              activeTab === 'comparisons'
                ? 'text-[#4F46E5] font-extrabold border-b-2 border-[#4F46E5]'
                : 'hover:text-slate-800'
            }`}
          >
            Plan Comparisons
          </button>
          <button
            onClick={() => setActiveTab('subscribers')}
            className={`pb-3 transition-colors ${
              activeTab === 'subscribers'
                ? 'text-[#4F46E5] font-extrabold border-b-2 border-[#4F46E5]'
                : 'hover:text-slate-800'
            }`}
          >
            Subscribers
          </button>
          <button
            onClick={() => setActiveTab('settings')}
            className={`pb-3 transition-colors ${
              activeTab === 'settings'
                ? 'text-[#4F46E5] font-extrabold border-b-2 border-[#4F46E5]'
                : 'hover:text-slate-800'
            }`}
          >
            Settings
          </button>
        </div>

        {/* BODY CONTAINER */}
        <div className="p-6 space-y-6">

          {/* ========================================================================= */}
          {/* 3. TOP 4 KPI SUMMARY METRIC CARDS */}
          {/* ========================================================================= */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            
            {/* KPI 1: Total Plans */}
            <div className="bg-white rounded-2xl p-4 border border-slate-200/80 shadow-sm flex items-center justify-between">
              <div className="space-y-1">
                <span className="text-xs text-slate-500 font-bold block">Total Plans</span>
                <span className="text-2xl font-black text-slate-900 block">4</span>
                <span className="text-[10px] text-slate-400 font-semibold block">Active plans</span>
              </div>
              <div className="w-12 h-12 rounded-2xl bg-indigo-50 text-indigo-600 flex items-center justify-center">
                <Users className="w-6 h-6" />
              </div>
            </div>

            {/* KPI 2: Active Subscribers */}
            <div className="bg-white rounded-2xl p-4 border border-slate-200/80 shadow-sm flex items-center justify-between">
              <div className="space-y-1">
                <span className="text-xs text-slate-500 font-bold block">Active Subscribers</span>
                <span className="text-2xl font-black text-slate-900 block">12,840</span>
                <span className="text-[10px] text-emerald-600 font-bold block flex items-center gap-0.5">
                  <TrendingUp className="w-3 h-3" /> +12.6% vs last 30 days
                </span>
              </div>
              <div className="w-12 h-12 rounded-2xl bg-emerald-50 text-emerald-600 flex items-center justify-center">
                <CheckCircle2 className="w-6 h-6" />
              </div>
            </div>

            {/* KPI 3: Monthly Revenue */}
            <div className="bg-white rounded-2xl p-4 border border-slate-200/80 shadow-sm flex items-center justify-between">
              <div className="space-y-1">
                <span className="text-xs text-slate-500 font-bold block">Monthly Revenue</span>
                <span className="text-2xl font-black text-slate-900 block">₹28,76,540</span>
                <span className="text-[10px] text-emerald-600 font-bold block flex items-center gap-0.5">
                  <TrendingUp className="w-3 h-3" /> +18.3% vs last 30 days
                </span>
              </div>
              <div className="w-12 h-12 rounded-2xl bg-blue-50 text-blue-600 flex items-center justify-center">
                <Calendar className="w-6 h-6" />
              </div>
            </div>

            {/* KPI 4: Conversion Rate / Annual Revenue */}
            <div className="bg-white rounded-2xl p-4 border border-slate-200/80 shadow-sm flex items-center justify-between">
              <div className="space-y-1">
                <span className="text-xs text-slate-500 font-bold block">Conversion Rate</span>
                <span className="text-2xl font-black text-slate-900 block">18.42%</span>
                <span className="text-[10px] text-emerald-600 font-bold block flex items-center gap-0.5">
                  <TrendingUp className="w-3 h-3" /> +2.4% vs last 30 days
                </span>
              </div>
              <div className="w-12 h-12 rounded-2xl bg-purple-50 text-purple-600 flex items-center justify-center">
                <Percent className="w-6 h-6" />
              </div>
            </div>

          </div>

          {/* ========================================================================= */}
          {/* 4. MAIN MIDDLE GRID (Subscription Plans Cards + Right Admin Panel) */}
          {/* ========================================================================= */}
          <div className="grid grid-cols-1 lg:grid-cols-4 gap-6 items-start">
            
            {/* Left 3 Columns: Subscription Plans Section */}
            <div className="lg:col-span-3 space-y-4">
              {/* Section Header */}
              <div className="flex items-center justify-between bg-white p-4 rounded-2xl border border-slate-200/80 shadow-sm">
                <div>
                  <h2 className="text-sm font-extrabold text-slate-900">Subscription Plans</h2>
                  <p className="text-xs text-slate-500 font-medium">Create and manage plans with pricing, duration and features.</p>
                </div>

                {/* Show Inactive Plans Toggle */}
                <div className="flex items-center gap-2.5">
                  <span className="text-xs font-bold text-slate-600">Show Inactive Plans</span>
                  <button
                    onClick={() => setShowInactive(!showInactive)}
                    className={`w-11 h-6 rounded-full transition-colors relative p-0.5 ${
                      showInactive ? 'bg-[#4F46E5]' : 'bg-slate-300'
                    }`}
                  >
                    <div
                      className={`w-5 h-5 rounded-full bg-white transition-transform ${
                        showInactive ? 'translate-x-5' : 'translate-x-0'
                      }`}
                    />
                  </button>
                </div>
              </div>

              {/* 4 Plan Cards Grid */}
              <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
                
                {/* Card 1: Trial Pass */}
                <div className="bg-white rounded-3xl border border-slate-200 p-4 space-y-4 shadow-sm flex flex-col justify-between">
                  <div className="space-y-3">
                    <div className="flex items-center justify-between">
                      <div className="w-10 h-10 rounded-2xl bg-amber-50 text-amber-600 flex items-center justify-center">
                        <Star className="w-5 h-5 fill-amber-500 text-amber-500" />
                      </div>
                      <span className="px-2 py-0.5 rounded-lg bg-amber-50 text-amber-700 border border-amber-200 text-[10px] font-extrabold">
                        Trial
                      </span>
                    </div>

                    <div>
                      <h3 className="text-sm font-extrabold text-slate-900">Trial Pass</h3>
                      <span className="text-[11px] text-slate-400 font-semibold block">1 Month</span>
                    </div>

                    <div>
                      <span className="text-xl font-black text-slate-900">₹99</span>
                      <span className="text-xs text-slate-400 font-medium"> / month</span>
                    </div>

                    <p className="text-[11px] text-slate-500 font-medium leading-tight">
                      Try Cosmyra for 30 days with limited access.
                    </p>

                    <div className="border-b border-slate-100" />

                    {/* Stats Table */}
                    <div className="space-y-1.5 text-[11px] font-semibold text-slate-600">
                      <div className="flex items-center justify-between">
                        <span>Status</span>
                        <span className="text-emerald-600 font-extrabold bg-emerald-50 px-1.5 py-0.5 rounded">Active</span>
                      </div>
                      <div className="flex items-center justify-between">
                        <span>Duration</span>
                        <span className="font-extrabold text-slate-900">30 Days</span>
                      </div>
                      <div className="flex items-center justify-between">
                        <span>Max Questions / Day</span>
                        <span className="font-extrabold text-slate-900">100</span>
                      </div>
                      <div className="flex items-center justify-between">
                        <span>Mock Tests</span>
                        <span className="font-extrabold text-slate-900">5 / Month</span>
                      </div>
                      <div className="flex items-center justify-between">
                        <span>Features</span>
                        <span className="font-extrabold text-slate-900">15</span>
                      </div>
                      <div className="flex items-center justify-between text-slate-400">
                        <span>Created On</span>
                        <span>12 May 2025</span>
                      </div>
                    </div>
                  </div>

                  <div className="flex items-center gap-2 pt-2">
                    <button className="flex-1 py-2 rounded-xl border border-slate-200 text-indigo-600 font-extrabold text-xs hover:bg-indigo-50 transition-colors">
                      Edit Plan
                    </button>
                    <button className="p-2 rounded-xl border border-slate-200 text-slate-500 hover:bg-slate-50">
                      <MoreHorizontal className="w-4 h-4" />
                    </button>
                  </div>
                </div>

                {/* Card 2: Starter */}
                <div className="bg-white rounded-3xl border border-slate-200 p-4 space-y-4 shadow-sm flex flex-col justify-between">
                  <div className="space-y-3">
                    <div className="flex items-center justify-between">
                      <div className="w-10 h-10 rounded-2xl bg-emerald-50 text-emerald-600 flex items-center justify-center">
                        <Rocket className="w-5 h-5 text-emerald-600" />
                      </div>
                      <span className="px-2 py-0.5 rounded-lg bg-emerald-50 text-emerald-700 border border-emerald-200 text-[10px] font-extrabold">
                        Starter
                      </span>
                    </div>

                    <div>
                      <h3 className="text-sm font-extrabold text-slate-900">Starter</h3>
                      <span className="text-[11px] text-slate-400 font-semibold block">4 Months</span>
                    </div>

                    <div>
                      <span className="text-xl font-black text-slate-900">₹249</span>
                      <span className="text-xs text-slate-400 font-medium"> / 4 months</span>
                    </div>

                    <p className="text-[11px] text-slate-500 font-medium leading-tight">
                      Short-term plan for focused preparation.
                    </p>

                    <div className="border-b border-slate-100" />

                    {/* Stats Table */}
                    <div className="space-y-1.5 text-[11px] font-semibold text-slate-600">
                      <div className="flex items-center justify-between">
                        <span>Status</span>
                        <span className="text-emerald-600 font-extrabold bg-emerald-50 px-1.5 py-0.5 rounded">Active</span>
                      </div>
                      <div className="flex items-center justify-between">
                        <span>Duration</span>
                        <span className="font-extrabold text-slate-900">4 Months</span>
                      </div>
                      <div className="flex items-center justify-between">
                        <span>Max Questions / Day</span>
                        <span className="font-extrabold text-slate-900">Unlimited</span>
                      </div>
                      <div className="flex items-center justify-between">
                        <span>Mock Tests</span>
                        <span className="font-extrabold text-slate-900">10 / Month</span>
                      </div>
                      <div className="flex items-center justify-between">
                        <span>Features</span>
                        <span className="font-extrabold text-slate-900">22</span>
                      </div>
                      <div className="flex items-center justify-between text-slate-400">
                        <span>Created On</span>
                        <span>12 May 2025</span>
                      </div>
                    </div>
                  </div>

                  <div className="flex items-center gap-2 pt-2">
                    <button className="flex-1 py-2 rounded-xl border border-slate-200 text-indigo-600 font-extrabold text-xs hover:bg-indigo-50 transition-colors">
                      Edit Plan
                    </button>
                    <button className="p-2 rounded-xl border border-slate-200 text-slate-500 hover:bg-slate-50">
                      <MoreHorizontal className="w-4 h-4" />
                    </button>
                  </div>
                </div>

                {/* Card 3: Pro (HIGHLIGHTED MOST POPULAR) */}
                <div className="bg-[#F8F7FF] rounded-3xl border-2 border-[#4F46E5] p-4 space-y-4 shadow-lg shadow-indigo-600/10 flex flex-col justify-between relative">
                  {/* Floating Most Popular Badge */}
                  <div className="absolute -top-3 left-1/2 -translate-x-1/2 bg-[#4F46E5] text-white text-[10px] font-black uppercase px-3 py-0.5 rounded-full shadow-md">
                    Most Popular
                  </div>

                  <div className="space-y-3 pt-1">
                    <div className="flex items-center justify-between">
                      <div className="w-10 h-10 rounded-2xl bg-purple-100 text-[#4F46E5] flex items-center justify-center">
                        <Crown className="w-5 h-5 text-[#4F46E5]" />
                      </div>
                      <span className="px-2 py-0.5 rounded-lg bg-purple-100 text-[#4F46E5] font-extrabold text-[10px]">
                        Pro
                      </span>
                    </div>

                    <div>
                      <h3 className="text-sm font-extrabold text-slate-900">Pro</h3>
                      <span className="text-[11px] text-slate-500 font-semibold block">8 Months</span>
                    </div>

                    <div>
                      <span className="text-xl font-black text-slate-900">₹449</span>
                      <span className="text-xs text-slate-500 font-medium"> / 8 months</span>
                    </div>

                    <p className="text-[11px] text-slate-600 font-medium leading-tight">
                      Best for serious NEET & JEE aspirants.
                    </p>

                    <div className="border-b border-purple-200" />

                    {/* Stats Table */}
                    <div className="space-y-1.5 text-[11px] font-semibold text-slate-700">
                      <div className="flex items-center justify-between">
                        <span>Status</span>
                        <span className="text-emerald-600 font-extrabold bg-emerald-50 px-1.5 py-0.5 rounded">Active</span>
                      </div>
                      <div className="flex items-center justify-between">
                        <span>Duration</span>
                        <span className="font-extrabold text-slate-900">8 Months</span>
                      </div>
                      <div className="flex items-center justify-between">
                        <span>Max Questions / Day</span>
                        <span className="font-extrabold text-slate-900">Unlimited</span>
                      </div>
                      <div className="flex items-center justify-between">
                        <span>Mock Tests</span>
                        <span className="font-extrabold text-slate-900">Unlimited</span>
                      </div>
                      <div className="flex items-center justify-between">
                        <span>Features</span>
                        <span className="font-extrabold text-slate-900">35</span>
                      </div>
                      <div className="flex items-center justify-between text-slate-400">
                        <span>Created On</span>
                        <span>12 May 2025</span>
                      </div>
                    </div>
                  </div>

                  <div className="flex items-center gap-2 pt-2">
                    <button className="flex-1 py-2 rounded-xl bg-[#4F46E5] hover:bg-[#4338CA] text-white font-extrabold text-xs shadow-md shadow-indigo-600/30 transition-colors">
                      Edit Plan
                    </button>
                    <button className="p-2 rounded-xl border border-purple-200 bg-white text-slate-500 hover:bg-slate-50">
                      <MoreHorizontal className="w-4 h-4" />
                    </button>
                  </div>
                </div>

                {/* Card 4: Ultimate */}
                <div className="bg-white rounded-3xl border border-slate-200 p-4 space-y-4 shadow-sm flex flex-col justify-between">
                  <div className="space-y-3">
                    <div className="flex items-center justify-between">
                      <div className="w-10 h-10 rounded-2xl bg-blue-50 text-blue-600 flex items-center justify-center">
                        <Gem className="w-5 h-5 text-blue-600" />
                      </div>
                      <span className="px-2 py-0.5 rounded-lg bg-blue-50 text-blue-700 border border-blue-200 text-[10px] font-extrabold">
                        Ultimate
                      </span>
                    </div>

                    <div>
                      <h3 className="text-sm font-extrabold text-slate-900">Ultimate</h3>
                      <span className="text-[11px] text-slate-400 font-semibold block">1 Year</span>
                    </div>

                    <div>
                      <span className="text-xl font-black text-slate-900">₹689</span>
                      <span className="text-xs text-slate-400 font-medium"> / year</span>
                    </div>

                    <p className="text-[11px] text-slate-500 font-medium leading-tight">
                      Complete preparation with advanced AI.
                    </p>

                    <div className="border-b border-slate-100" />

                    {/* Stats Table */}
                    <div className="space-y-1.5 text-[11px] font-semibold text-slate-600">
                      <div className="flex items-center justify-between">
                        <span>Status</span>
                        <span className="text-emerald-600 font-extrabold bg-emerald-50 px-1.5 py-0.5 rounded">Active</span>
                      </div>
                      <div className="flex items-center justify-between">
                        <span>Duration</span>
                        <span className="font-extrabold text-slate-900">1 Year</span>
                      </div>
                      <div className="flex items-center justify-between">
                        <span>Max Questions / Day</span>
                        <span className="font-extrabold text-slate-900">Unlimited</span>
                      </div>
                      <div className="flex items-center justify-between">
                        <span>Mock Tests</span>
                        <span className="font-extrabold text-slate-900">Unlimited</span>
                      </div>
                      <div className="flex items-center justify-between">
                        <span>Features</span>
                        <span className="font-extrabold text-slate-900">50</span>
                      </div>
                      <div className="flex items-center justify-between text-slate-400">
                        <span>Created On</span>
                        <span>12 May 2025</span>
                      </div>
                    </div>
                  </div>

                  <div className="flex items-center gap-2 pt-2">
                    <button className="flex-1 py-2 rounded-xl border border-slate-200 text-indigo-600 font-extrabold text-xs hover:bg-indigo-50 transition-colors">
                      Edit Plan
                    </button>
                    <button className="p-2 rounded-xl border border-slate-200 text-slate-500 hover:bg-slate-50">
                      <MoreHorizontal className="w-4 h-4" />
                    </button>
                  </div>
                </div>

              </div>
            </div>

            {/* Right 1 Column: Admin Plan Settings & Quick Actions Panel */}
            <div className="space-y-6">
              
              {/* Plan Settings Box */}
              <div className="bg-white rounded-3xl border border-slate-200/80 p-5 space-y-4 shadow-sm">
                <h3 className="text-sm font-extrabold text-slate-900">Plan Settings</h3>

                <div className="space-y-3 text-xs font-bold text-slate-700">
                  <div className="flex items-center justify-between">
                    <span className="text-slate-500">Currency</span>
                    <span className="text-slate-900 font-black">INR (₹)</span>
                  </div>

                  <div className="flex items-center justify-between">
                    <span className="text-slate-500">Tax (GST)</span>
                    <span className="text-slate-900 font-black">18%</span>
                  </div>

                  <div className="space-y-1">
                    <span className="text-slate-500 text-[11px]">Default Plan</span>
                    <select
                      value={defaultPlan}
                      onChange={(e) => setDefaultPlan(e.target.value)}
                      className="w-full bg-slate-50 border border-slate-200 rounded-xl p-2 text-xs font-bold text-slate-900 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                    >
                      <option value="pro">Pro (8 Months)</option>
                      <option value="starter">Starter (4 Months)</option>
                      <option value="ultimate">Ultimate (1 Year)</option>
                      <option value="trial">Trial Pass</option>
                    </select>
                  </div>

                  {/* Toggle Downgrade */}
                  <div className="flex items-center justify-between pt-1">
                    <span className="text-slate-600 text-xs">Allow Plan Downgrade</span>
                    <button
                      onClick={() => setAllowDowngrade(!allowDowngrade)}
                      className={`w-9 h-5 rounded-full transition-colors relative p-0.5 ${
                        allowDowngrade ? 'bg-[#4F46E5]' : 'bg-slate-300'
                      }`}
                    >
                      <div
                        className={`w-4 h-4 rounded-full bg-white transition-transform ${
                          allowDowngrade ? 'translate-x-4' : 'translate-x-0'
                        }`}
                      />
                    </button>
                  </div>

                  {/* Toggle Upgrade */}
                  <div className="flex items-center justify-between">
                    <span className="text-slate-600 text-xs">Allow Plan Upgrade</span>
                    <button
                      onClick={() => setAllowUpgrade(!allowUpgrade)}
                      className={`w-9 h-5 rounded-full transition-colors relative p-0.5 ${
                        allowUpgrade ? 'bg-[#4F46E5]' : 'bg-slate-300'
                      }`}
                    >
                      <div
                        className={`w-4 h-4 rounded-full bg-white transition-transform ${
                          allowUpgrade ? 'translate-x-4' : 'translate-x-0'
                        }`}
                      />
                    </button>
                  </div>

                  {/* Toggle Auto Renewal */}
                  <div className="flex items-center justify-between">
                    <span className="text-slate-600 text-xs">Auto Renewal</span>
                    <button
                      onClick={() => setAutoRenewal(!autoRenewal)}
                      className={`w-9 h-5 rounded-full transition-colors relative p-0.5 ${
                        autoRenewal ? 'bg-[#4F46E5]' : 'bg-slate-300'
                      }`}
                    >
                      <div
                        className={`w-4 h-4 rounded-full bg-white transition-transform ${
                          autoRenewal ? 'translate-x-4' : 'translate-x-0'
                        }`}
                      />
                    </button>
                  </div>
                </div>

                <button className="w-full py-2.5 rounded-xl bg-[#4F46E5] hover:bg-[#4338CA] text-white font-extrabold text-xs shadow-md shadow-indigo-600/30 transition-colors">
                  Save Settings
                </button>
              </div>

              {/* Quick Actions Box */}
              <div className="bg-white rounded-3xl border border-slate-200/80 p-5 space-y-3 shadow-sm">
                <h3 className="text-sm font-extrabold text-slate-900">Quick Actions</h3>

                <div className="space-y-2 text-xs font-bold text-indigo-600">
                  <button className="w-full flex items-center gap-2 p-2 rounded-xl hover:bg-indigo-50 transition-colors text-left">
                    <Plus className="w-4 h-4 stroke-[2.5]" />
                    <span>Add New Plan</span>
                  </button>
                  <button className="w-full flex items-center gap-2 p-2 rounded-xl hover:bg-indigo-50 transition-colors text-left">
                    <SlidersHorizontal className="w-4 h-4" />
                    <span>Manage Features</span>
                  </button>
                  <button className="w-full flex items-center gap-2 p-2 rounded-xl hover:bg-indigo-50 transition-colors text-left">
                    <FileSpreadsheet className="w-4 h-4" />
                    <span>Plan Comparison</span>
                  </button>
                  <button className="w-full flex items-center gap-2 p-2 rounded-xl hover:bg-indigo-50 transition-colors text-left">
                    <Tag className="w-4 h-4" />
                    <span>Bulk Update Prices</span>
                  </button>
                  <button className="w-full flex items-center gap-2 p-2 rounded-xl hover:bg-indigo-50 transition-colors text-left">
                    <Download className="w-4 h-4" />
                    <span>Import/Export Plans</span>
                  </button>
                </div>
              </div>

            </div>

          </div>

          {/* ========================================================================= */}
          {/* 5. BOTTOM SECTION (Plan Features Management + Plan Performance) */}
          {/* ========================================================================= */}
          <div className="grid grid-cols-1 lg:grid-cols-4 gap-6 items-start">
            
            {/* Left 3 Columns: Plan Features Management Table */}
            <div className="lg:col-span-3 bg-white rounded-3xl border border-slate-200/80 p-5 space-y-4 shadow-sm">
              <div className="flex items-center justify-between">
                <div>
                  <h3 className="text-sm font-extrabold text-slate-900">Plan Features Management</h3>
                  <p className="text-xs text-slate-500 font-medium">Enable or disable features for individual plans.</p>
                </div>

                <div className="flex items-center gap-2 text-xs font-bold">
                  <span className="text-slate-500">View Plan:</span>
                  <select
                    value={selectedPlanView}
                    onChange={(e) => setSelectedPlanView(e.target.value)}
                    className="bg-slate-50 border border-slate-200 rounded-xl px-3 py-1.5 text-slate-900 font-bold focus:outline-none"
                  >
                    <option value="pro">Pro (8 Months)</option>
                    <option value="starter">Starter (4 Months)</option>
                    <option value="ultimate">Ultimate (1 Year)</option>
                    <option value="trial">Trial Pass</option>
                  </select>
                </div>
              </div>

              {/* Table */}
              <div className="overflow-x-auto">
                <table className="w-full text-left text-xs">
                  <thead className="bg-slate-50 border-y border-slate-100 text-slate-600 font-extrabold">
                    <tr>
                      <th className="py-3 px-4">Feature Name</th>
                      <th className="py-3 px-4 text-center">⭐ Trial</th>
                      <th className="py-3 px-4 text-center">🚀 Starter</th>
                      <th className="py-3 px-4 text-center">👑 Pro</th>
                      <th className="py-3 px-4 text-center">💎 Ultimate</th>
                      <th className="py-3 px-4 text-right">Actions</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100 font-bold text-slate-800">
                    {features.map((feat) => (
                      <tr key={feat.id} className="hover:bg-slate-50/80 transition-colors">
                        <td className="py-3.5 px-4">
                          <span className="block text-slate-900 font-extrabold">{feat.name}</span>
                          <span className="block text-[10px] text-slate-400 font-medium mt-0.5">{feat.description}</span>
                        </td>
                        
                        {/* Trial Toggle */}
                        <td className="py-3.5 px-4 text-center">
                          <button
                            onClick={() => toggleFeature(feat.id, 'trial')}
                            className={`w-9 h-5 rounded-full transition-colors inline-block relative p-0.5 ${
                              feat.trial ? 'bg-emerald-500' : 'bg-slate-300'
                            }`}
                          >
                            <div className={`w-4 h-4 rounded-full bg-white transition-transform ${feat.trial ? 'translate-x-4' : 'translate-x-0'}`} />
                          </button>
                        </td>

                        {/* Starter Toggle */}
                        <td className="py-3.5 px-4 text-center">
                          <button
                            onClick={() => toggleFeature(feat.id, 'starter')}
                            className={`w-9 h-5 rounded-full transition-colors inline-block relative p-0.5 ${
                              feat.starter ? 'bg-emerald-500' : 'bg-slate-300'
                            }`}
                          >
                            <div className={`w-4 h-4 rounded-full bg-white transition-transform ${feat.starter ? 'translate-x-4' : 'translate-x-0'}`} />
                          </button>
                        </td>

                        {/* Pro Toggle */}
                        <td className="py-3.5 px-4 text-center">
                          <button
                            onClick={() => toggleFeature(feat.id, 'pro')}
                            className={`w-9 h-5 rounded-full transition-colors inline-block relative p-0.5 ${
                              feat.pro ? 'bg-emerald-500' : 'bg-slate-300'
                            }`}
                          >
                            <div className={`w-4 h-4 rounded-full bg-white transition-transform ${feat.pro ? 'translate-x-4' : 'translate-x-0'}`} />
                          </button>
                        </td>

                        {/* Ultimate Toggle */}
                        <td className="py-3.5 px-4 text-center">
                          <button
                            onClick={() => toggleFeature(feat.id, 'ultimate')}
                            className={`w-9 h-5 rounded-full transition-colors inline-block relative p-0.5 ${
                              feat.ultimate ? 'bg-emerald-500' : 'bg-slate-300'
                            }`}
                          >
                            <div className={`w-4 h-4 rounded-full bg-white transition-transform ${feat.ultimate ? 'translate-x-4' : 'translate-x-0'}`} />
                          </button>
                        </td>

                        <td className="py-3.5 px-4 text-right">
                          <button className="text-indigo-600 font-extrabold hover:text-indigo-800 text-xs">
                            Edit
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>

            {/* Right 1 Column: Plan Performance Widget */}
            <div className="bg-white rounded-3xl border border-slate-200/80 p-5 space-y-4 shadow-sm">
              <div className="flex items-center justify-between">
                <h3 className="text-sm font-extrabold text-slate-900">Plan Performance</h3>
                <select className="bg-slate-50 border border-slate-200 rounded-lg text-[11px] font-bold text-slate-700 px-2 py-1 focus:outline-none">
                  <option>This Month</option>
                  <option>Last Month</option>
                  <option>This Year</option>
                </select>
              </div>

              {/* Performance Item List */}
              <div className="space-y-3">
                <div className="flex items-center justify-between text-xs font-bold">
                  <div className="flex items-center gap-2">
                    <Star className="w-4 h-4 text-amber-500 fill-amber-500" />
                    <span className="text-slate-800">Trial Pass</span>
                  </div>
                  <div className="flex items-center gap-3">
                    <span className="text-slate-900 font-black">251</span>
                    <span className="text-emerald-600 text-[11px] font-extrabold">+8.2%</span>
                  </div>
                </div>

                <div className="flex items-center justify-between text-xs font-bold">
                  <div className="flex items-center gap-2">
                    <Rocket className="w-4 h-4 text-emerald-600" />
                    <span className="text-slate-800">Starter</span>
                  </div>
                  <div className="flex items-center gap-3">
                    <span className="text-slate-900 font-black">1,842</span>
                    <span className="text-emerald-600 text-[11px] font-extrabold">+11.3%</span>
                  </div>
                </div>

                <div className="flex items-center justify-between text-xs font-bold">
                  <div className="flex items-center gap-2">
                    <Crown className="w-4 h-4 text-[#4F46E5]" />
                    <span className="text-slate-800">Pro</span>
                  </div>
                  <div className="flex items-center gap-3">
                    <span className="text-slate-900 font-black">6,732</span>
                    <span className="text-emerald-600 text-[11px] font-extrabold">+15.7%</span>
                  </div>
                </div>

                <div className="flex items-center justify-between text-xs font-bold">
                  <div className="flex items-center gap-2">
                    <Gem className="w-4 h-4 text-blue-600" />
                    <span className="text-slate-800">Ultimate</span>
                  </div>
                  <div className="flex items-center gap-3">
                    <span className="text-slate-900 font-black">4,015</span>
                    <span className="text-emerald-600 text-[11px] font-extrabold">+21.4%</span>
                  </div>
                </div>
              </div>

              <div className="pt-2">
                <button className="text-indigo-600 hover:text-indigo-800 font-extrabold text-xs flex items-center gap-1">
                  <span>View Detailed Report</span>
                  <ArrowUpRight className="w-3.5 h-3.5" />
                </button>
              </div>
            </div>

          </div>

        </div>

    </div>
  );
};
