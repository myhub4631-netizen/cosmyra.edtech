import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  GraduationCap,
  LayoutDashboard,
  Users,
  BookOpen,
  FileSpreadsheet,
  HelpCircle,
  CreditCard,
  Tag,
  Bell,
  FileText,
  Smartphone,
  Image as ImageIcon,
  RotateCcw,
  BarChart3,
  Settings,
  LogOut,
  MoreVertical,
  Search,
  Calendar,
  Plus,
  TrendingUp,
  CheckCircle2,
  Ticket,
  IndianRupee,
  ChevronDown,
  Filter,
  Copy,
  Eye,
  Edit3,
  Trash2,
  ChevronLeft,
  ChevronRight,
  Gift,
  Megaphone,
  Sun,
  Percent,
  Star,
  ShieldAlert,
} from 'lucide-react';
import { AdminSidebar } from '../../components/layout/AdminSidebar';

export const AdminOffersCoupons: React.FC = () => {
  const navigate = useNavigate();

  // Active Tab & Filter State
  const [activeTab, setActiveTab] = useState<string>('all');
  const [selectedStatus, setSelectedStatus] = useState<string>('all');
  const [selectedType, setSelectedType] = useState<string>('all');
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [copiedCode, setCopiedCode] = useState<string | null>(null);

  const handleCopyCode = (code: string) => {
    navigator.clipboard.writeText(code);
    setCopiedCode(code);
    setTimeout(() => setCopiedCode(null), 2000);
  };

  return (
    <div className="space-y-6 text-slate-900 select-none">
      
      {/* Action Header Row */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 bg-white p-4 rounded-3xl border border-slate-200/80 shadow-xs">
        <div>
          <h1 className="text-xl font-black text-slate-900 tracking-tight">Offers & Coupons</h1>
          <p className="text-xs text-slate-400 font-semibold flex items-center gap-1 mt-0.5">
            <span>Dashboard</span>
            <span>›</span>
            <span className="text-[#5D3EED] font-bold">Offers & Coupons</span>
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-3">
          {/* Search Input */}
          <div className="relative">
            <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              placeholder="Search by coupon name or code..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-64 pl-10 pr-4 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold text-slate-800 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:bg-white"
            />
          </div>

          {/* Date Range Picker */}
          <div className="flex items-center gap-2 bg-white border border-slate-200 rounded-xl px-3.5 py-2 text-xs font-bold text-slate-700 hover:bg-slate-50 cursor-pointer shadow-xs">
            <Calendar className="w-4 h-4 text-slate-500" />
            <span>20 May 2024 - 27 May 2024</span>
            <ChevronDown className="w-3.5 h-3.5 text-slate-400" />
          </div>

          {/* Notification Bell */}
          <button className="relative p-2.5 rounded-xl border border-slate-200 hover:bg-slate-50 text-slate-600 transition-colors bg-white shadow-xs">
            <Bell className="w-4 h-4" />
            <span className="absolute -top-1 -right-1 bg-rose-500 text-white text-[9px] font-bold w-4 h-4 rounded-full flex items-center justify-center border-2 border-white">
              12
            </span>
          </button>

          {/* Primary Action Button */}
          <button className="px-4 py-2.5 rounded-xl bg-[#5D3EED] hover:bg-[#4F46E5] text-white font-extrabold text-xs shadow-md shadow-indigo-600/20 flex items-center gap-1.5 transition-all">
            <Plus className="w-4 h-4 stroke-[3]" />
            <span>Add New Offer</span>
          </button>
        </div>
      </div>

          {/* ========================================================================= */}
          {/* 3. 5 KPI METRIC SUMMARY CARDS ROW */}
          {/* ========================================================================= */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4">
            
            {/* Card 1: Total Offers */}
            <div className="bg-white border border-slate-200/80 rounded-2xl p-4 flex items-center gap-3.5 shadow-xs">
              <div className="w-12 h-12 rounded-2xl bg-purple-50 text-[#5D3EED] border border-purple-100 flex items-center justify-center flex-shrink-0">
                <Tag className="w-6 h-6 stroke-[2]" />
              </div>
              <div>
                <span className="text-[11px] font-bold text-slate-400 block">Total Offers</span>
                <span className="text-xl font-black text-slate-900 block leading-tight">128</span>
                <span className="text-[10px] font-extrabold text-emerald-600 block mt-0.5">
                  ↑ 12 <span className="text-slate-400 font-medium">this week</span>
                </span>
              </div>
            </div>

            {/* Card 2: Active Offers */}
            <div className="bg-white border border-slate-200/80 rounded-2xl p-4 flex items-center gap-3.5 shadow-xs">
              <div className="w-12 h-12 rounded-2xl bg-emerald-50 text-emerald-500 border border-emerald-100 flex items-center justify-center flex-shrink-0">
                <CheckCircle2 className="w-6 h-6 stroke-[2]" />
              </div>
              <div>
                <span className="text-[11px] font-bold text-slate-400 block">Active Offers</span>
                <span className="text-xl font-black text-slate-900 block leading-tight">78</span>
                <span className="text-[10px] font-extrabold text-emerald-600 block mt-0.5">
                  ↑ 8 <span className="text-slate-400 font-medium">this week</span>
                </span>
              </div>
            </div>

            {/* Card 3: Total Coupons */}
            <div className="bg-white border border-slate-200/80 rounded-2xl p-4 flex items-center gap-3.5 shadow-xs">
              <div className="w-12 h-12 rounded-2xl bg-blue-50 text-blue-500 border border-blue-100 flex items-center justify-center flex-shrink-0">
                <Ticket className="w-6 h-6 stroke-[2]" />
              </div>
              <div>
                <span className="text-[11px] font-bold text-slate-400 block">Total Coupons</span>
                <span className="text-xl font-black text-slate-900 block leading-tight">532</span>
                <span className="text-[10px] font-extrabold text-emerald-600 block mt-0.5">
                  ↑ 64 <span className="text-slate-400 font-medium">this week</span>
                </span>
              </div>
            </div>

            {/* Card 4: Total Usage */}
            <div className="bg-white border border-slate-200/80 rounded-2xl p-4 flex items-center gap-3.5 shadow-xs">
              <div className="w-12 h-12 rounded-2xl bg-amber-50 text-amber-500 border border-amber-100 flex items-center justify-center flex-shrink-0">
                <TrendingUp className="w-6 h-6 stroke-[2]" />
              </div>
              <div>
                <span className="text-[11px] font-bold text-slate-400 block">Total Usage</span>
                <span className="text-xl font-black text-slate-900 block leading-tight">12,645</span>
                <span className="text-[10px] font-extrabold text-emerald-600 block mt-0.5">
                  ↑ 1,234 <span className="text-slate-400 font-medium">this week</span>
                </span>
              </div>
            </div>

            {/* Card 5: Total Discount Given */}
            <div className="bg-white border border-slate-200/80 rounded-2xl p-4 flex items-center gap-3.5 shadow-xs">
              <div className="w-12 h-12 rounded-2xl bg-rose-50 text-rose-500 border border-rose-100 flex items-center justify-center flex-shrink-0">
                <IndianRupee className="w-6 h-6 stroke-[2]" />
              </div>
              <div>
                <span className="text-[11px] font-bold text-slate-400 block">Total Discount Given</span>
                <span className="text-xl font-black text-slate-900 block leading-tight">₹1,45,234</span>
                <span className="text-[10px] font-extrabold text-emerald-600 block mt-0.5">
                  ↑ 18.6% <span className="text-slate-400 font-medium">vs last week</span>
                </span>
              </div>
            </div>

          </div>

          {/* ========================================================================= */}
          {/* 4. TABLE FILTERS & CATEGORY SUB-NAV BAR */}
          {/* ========================================================================= */}
          <div className="bg-white border border-slate-200/80 rounded-3xl p-4 space-y-4 shadow-xs">
            
            <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4 border-b border-slate-100 pb-3">
              
              {/* Left Sub-nav Tabs */}
              <div className="flex items-center gap-6 overflow-x-auto custom-scrollbar pb-1 text-xs font-bold text-slate-500">
                <button
                  onClick={() => setActiveTab('all')}
                  className={`pb-2 transition-colors relative whitespace-nowrap ${
                    activeTab === 'all' ? 'text-[#5D3EED] font-black' : 'hover:text-slate-800'
                  }`}
                >
                  All Offers
                  {activeTab === 'all' && (
                    <span className="absolute bottom-0 left-0 right-0 h-0.5 bg-[#5D3EED] rounded-full" />
                  )}
                </button>

                <button
                  onClick={() => setActiveTab('coupons')}
                  className={`pb-2 transition-colors relative whitespace-nowrap ${
                    activeTab === 'coupons' ? 'text-[#5D3EED] font-black' : 'hover:text-slate-800'
                  }`}
                >
                  Coupons
                  {activeTab === 'coupons' && (
                    <span className="absolute bottom-0 left-0 right-0 h-0.5 bg-[#5D3EED] rounded-full" />
                  )}
                </button>

                <button
                  onClick={() => setActiveTab('refer')}
                  className={`pb-2 transition-colors relative whitespace-nowrap ${
                    activeTab === 'refer' ? 'text-[#5D3EED] font-black' : 'hover:text-slate-800'
                  }`}
                >
                  Refer & Earn
                </button>

                <button
                  onClick={() => setActiveTab('b1g1')}
                  className={`pb-2 transition-colors relative whitespace-nowrap ${
                    activeTab === 'b1g1' ? 'text-[#5D3EED] font-black' : 'hover:text-slate-800'
                  }`}
                >
                  Buy 1 Get 1
                </button>

                <button
                  onClick={() => setActiveTab('ugc')}
                  className={`pb-2 transition-colors relative whitespace-nowrap ${
                    activeTab === 'ugc' ? 'text-[#5D3EED] font-black' : 'hover:text-slate-800'
                  }`}
                >
                  UGC Promos
                </button>

                <button
                  onClick={() => setActiveTab('seasonal')}
                  className={`pb-2 transition-colors relative whitespace-nowrap ${
                    activeTab === 'seasonal' ? 'text-[#5D3EED] font-black' : 'hover:text-slate-800'
                  }`}
                >
                  Seasonal Offers
                </button>
              </div>

              {/* Right Filter Controls */}
              <div className="flex items-center gap-3">
                <div className="flex items-center gap-1.5 bg-slate-50 border border-slate-200 rounded-xl px-3 py-1.5 text-xs font-bold text-slate-700 cursor-pointer">
                  <span>All Status</span>
                  <ChevronDown className="w-3.5 h-3.5 text-slate-400" />
                </div>

                <div className="flex items-center gap-1.5 bg-slate-50 border border-slate-200 rounded-xl px-3 py-1.5 text-xs font-bold text-slate-700 cursor-pointer">
                  <span>All Types</span>
                  <ChevronDown className="w-3.5 h-3.5 text-slate-400" />
                </div>

                <button className="flex items-center gap-1.5 bg-white border border-slate-200 rounded-xl px-3 py-1.5 text-xs font-bold text-slate-700 hover:bg-slate-50 transition-colors shadow-xs">
                  <Filter className="w-3.5 h-3.5 text-slate-500" />
                  <span>Filters</span>
                </button>
              </div>

            </div>

            {/* ========================================================================= */}
            {/* 5. OFFERS & COUPONS TABLE DATA */}
            {/* ========================================================================= */}
            <div className="overflow-x-auto custom-scrollbar">
              <table className="w-full text-left text-xs font-semibold text-slate-700">
                <thead>
                  <tr className="border-b border-slate-200/80 text-slate-400 uppercase text-[10px] tracking-wider font-extrabold">
                    <th className="pb-3 pr-4">Offer Name</th>
                    <th className="pb-3 px-3">Type</th>
                    <th className="pb-3 px-3">Coupon Code</th>
                    <th className="pb-3 px-3">Discount</th>
                    <th className="pb-3 px-3">Start Date</th>
                    <th className="pb-3 px-3">End Date</th>
                    <th className="pb-3 px-3">Usage</th>
                    <th className="pb-3 px-3">Status</th>
                    <th className="pb-3 pl-3 text-right">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  
                  {/* Row 1: Flat 20% OFF */}
                  <tr className="hover:bg-slate-50/80 transition-colors">
                    <td className="py-4 pr-4">
                      <div className="flex items-center gap-3">
                        <div className="w-9 h-9 rounded-2xl bg-emerald-100 text-emerald-600 flex items-center justify-center flex-shrink-0">
                          <Percent className="w-4 h-4 stroke-[2.5]" />
                        </div>
                        <div>
                          <span className="font-extrabold text-slate-900 block text-xs">Flat 20% OFF</span>
                          <span className="text-[10px] text-slate-400 block font-normal">Get 20% off on all Pro Plans</span>
                        </div>
                      </div>
                    </td>
                    <td className="py-4 px-3">
                      <span className="px-2.5 py-1 rounded-lg bg-purple-50 text-[#5D3EED] font-bold text-[10px]">
                        Coupon
                      </span>
                    </td>
                    <td className="py-4 px-3">
                      <div className="flex items-center gap-1.5 bg-slate-100 px-2.5 py-1 rounded-lg border border-slate-200/80 max-w-max">
                        <span className="font-black text-slate-800 text-[11px]">PRO20</span>
                        <button
                          onClick={() => handleCopyCode('PRO20')}
                          className="p-0.5 text-slate-400 hover:text-slate-600"
                        >
                          <Copy className="w-3 h-3" />
                        </button>
                      </div>
                    </td>
                    <td className="py-4 px-3">
                      <span className="font-extrabold text-slate-900 block">20% OFF</span>
                      <span className="text-[10px] text-slate-400 font-medium block">on all plans</span>
                    </td>
                    <td className="py-4 px-3">
                      <span className="font-bold text-slate-800 block">20 May 2024</span>
                      <span className="text-[10px] text-slate-400 block">10:00 AM</span>
                    </td>
                    <td className="py-4 px-3">
                      <span className="font-bold text-slate-800 block">31 May 2024</span>
                      <span className="text-[10px] text-slate-400 block">11:59 PM</span>
                    </td>
                    <td className="py-4 px-3 w-36">
                      <div className="space-y-1">
                        <span className="font-extrabold text-slate-900 block text-[11px]">1,245 <span className="text-slate-400 font-normal">/ 5,000</span></span>
                        <div className="w-full h-1.5 bg-slate-100 rounded-full overflow-hidden">
                          <div className="h-full bg-indigo-600 rounded-full w-[25%]" />
                        </div>
                      </div>
                    </td>
                    <td className="py-4 px-3">
                      <span className="px-2.5 py-1 rounded-full bg-emerald-50 text-emerald-600 font-extrabold text-[10px]">
                        Active
                      </span>
                    </td>
                    <td className="py-4 pl-3 text-right">
                      <div className="flex items-center justify-end gap-1.5 text-slate-400">
                        <button className="p-1.5 rounded-lg hover:bg-slate-100 hover:text-slate-600 transition-colors">
                          <Eye className="w-4 h-4" />
                        </button>
                        <button className="p-1.5 rounded-lg hover:bg-slate-100 hover:text-slate-600 transition-colors">
                          <Edit3 className="w-4 h-4" />
                        </button>
                        <button className="p-1.5 rounded-lg hover:bg-rose-50 hover:text-rose-600 transition-colors">
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    </td>
                  </tr>

                  {/* Row 2: Refer & Earn */}
                  <tr className="hover:bg-slate-50/80 transition-colors">
                    <td className="py-4 pr-4">
                      <div className="flex items-center gap-3">
                        <div className="w-9 h-9 rounded-2xl bg-blue-100 text-blue-600 flex items-center justify-center flex-shrink-0">
                          <Gift className="w-4 h-4 stroke-[2.5]" />
                        </div>
                        <div>
                          <span className="font-extrabold text-slate-900 block text-xs">Refer & Earn</span>
                          <span className="text-[10px] text-slate-400 block font-normal">Refer a friend & get 50% off</span>
                        </div>
                      </div>
                    </td>
                    <td className="py-4 px-3">
                      <span className="px-2.5 py-1 rounded-lg bg-blue-50 text-blue-600 font-bold text-[10px]">
                        Refer & Earn
                      </span>
                    </td>
                    <td className="py-4 px-3">
                      <span className="text-slate-400 font-bold text-xs">—</span>
                    </td>
                    <td className="py-4 px-3">
                      <span className="font-extrabold text-slate-900 block">50% OFF</span>
                      <span className="text-[10px] text-slate-400 font-medium block">on next purchase</span>
                    </td>
                    <td className="py-4 px-3">
                      <span className="font-bold text-slate-800 block">18 May 2024</span>
                      <span className="text-[10px] text-slate-400 block">10:00 AM</span>
                    </td>
                    <td className="py-4 px-3">
                      <span className="font-bold text-slate-800 block">30 Jun 2024</span>
                      <span className="text-[10px] text-slate-400 block">11:59 PM</span>
                    </td>
                    <td className="py-4 px-3 w-36">
                      <div className="space-y-1">
                        <span className="font-extrabold text-slate-900 block text-[11px]">2,340 <span className="text-slate-400 font-normal">/ 10,000</span></span>
                        <div className="w-full h-1.5 bg-slate-100 rounded-full overflow-hidden">
                          <div className="h-full bg-indigo-600 rounded-full w-[23%]" />
                        </div>
                      </div>
                    </td>
                    <td className="py-4 px-3">
                      <span className="px-2.5 py-1 rounded-full bg-emerald-50 text-emerald-600 font-extrabold text-[10px]">
                        Active
                      </span>
                    </td>
                    <td className="py-4 pl-3 text-right">
                      <div className="flex items-center justify-end gap-1.5 text-slate-400">
                        <button className="p-1.5 rounded-lg hover:bg-slate-100 hover:text-slate-600 transition-colors">
                          <Eye className="w-4 h-4" />
                        </button>
                        <button className="p-1.5 rounded-lg hover:bg-slate-100 hover:text-slate-600 transition-colors">
                          <Edit3 className="w-4 h-4" />
                        </button>
                        <button className="p-1.5 rounded-lg hover:bg-rose-50 hover:text-rose-600 transition-colors">
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    </td>
                  </tr>

                  {/* Row 3: Buy 1 Get 1 Free */}
                  <tr className="hover:bg-slate-50/80 transition-colors">
                    <td className="py-4 pr-4">
                      <div className="flex items-center gap-3">
                        <div className="w-9 h-9 rounded-2xl bg-amber-100 text-amber-600 flex items-center justify-center flex-shrink-0 font-black text-[10px]">
                          BUY 1
                        </div>
                        <div>
                          <span className="font-extrabold text-slate-900 block text-xs">Buy 1 Get 1 Free</span>
                          <span className="text-[10px] text-slate-400 block font-normal">Applicable on all test series</span>
                        </div>
                      </div>
                    </td>
                    <td className="py-4 px-3">
                      <span className="px-2.5 py-1 rounded-lg bg-amber-50 text-amber-600 font-bold text-[10px]">
                        Buy 1 Get 1
                      </span>
                    </td>
                    <td className="py-4 px-3">
                      <div className="flex items-center gap-1.5 bg-slate-100 px-2.5 py-1 rounded-lg border border-slate-200/80 max-w-max">
                        <span className="font-black text-slate-800 text-[11px]">B1G1</span>
                        <button
                          onClick={() => handleCopyCode('B1G1')}
                          className="p-0.5 text-slate-400 hover:text-slate-600"
                        >
                          <Copy className="w-3 h-3" />
                        </button>
                      </div>
                    </td>
                    <td className="py-4 px-3">
                      <span className="font-extrabold text-slate-900 block">Buy 1 Get 1</span>
                      <span className="text-[10px] text-slate-400 font-medium block">Free</span>
                    </td>
                    <td className="py-4 px-3">
                      <span className="font-bold text-slate-800 block">15 May 2024</span>
                      <span className="text-[10px] text-slate-400 block">10:00 AM</span>
                    </td>
                    <td className="py-4 px-3">
                      <span className="font-bold text-slate-800 block">25 May 2024</span>
                      <span className="text-[10px] text-slate-400 block">11:59 PM</span>
                    </td>
                    <td className="py-4 px-3 w-36">
                      <div className="space-y-1">
                        <span className="font-extrabold text-slate-900 block text-[11px]">845 <span className="text-slate-400 font-normal">/ 2,000</span></span>
                        <div className="w-full h-1.5 bg-slate-100 rounded-full overflow-hidden">
                          <div className="h-full bg-indigo-600 rounded-full w-[42%]" />
                        </div>
                      </div>
                    </td>
                    <td className="py-4 px-3">
                      <span className="px-2.5 py-1 rounded-full bg-emerald-50 text-emerald-600 font-extrabold text-[10px]">
                        Active
                      </span>
                    </td>
                    <td className="py-4 pl-3 text-right">
                      <div className="flex items-center justify-end gap-1.5 text-slate-400">
                        <button className="p-1.5 rounded-lg hover:bg-slate-100 hover:text-slate-600 transition-colors">
                          <Eye className="w-4 h-4" />
                        </button>
                        <button className="p-1.5 rounded-lg hover:bg-slate-100 hover:text-slate-600 transition-colors">
                          <Edit3 className="w-4 h-4" />
                        </button>
                        <button className="p-1.5 rounded-lg hover:bg-rose-50 hover:text-rose-600 transition-colors">
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    </td>
                  </tr>

                  {/* Row 4: UGC Creator Promo */}
                  <tr className="hover:bg-slate-50/80 transition-colors">
                    <td className="py-4 pr-4">
                      <div className="flex items-center gap-3">
                        <div className="w-9 h-9 rounded-2xl bg-purple-100 text-purple-600 flex items-center justify-center flex-shrink-0">
                          <Megaphone className="w-4 h-4 stroke-[2.5]" />
                        </div>
                        <div>
                          <span className="font-extrabold text-slate-900 block text-xs">UGC Creator Promo</span>
                          <span className="text-[10px] text-slate-400 block font-normal">Special discount for creators</span>
                        </div>
                      </div>
                    </td>
                    <td className="py-4 px-3">
                      <span className="px-2.5 py-1 rounded-lg bg-purple-50 text-purple-600 font-bold text-[10px]">
                        UGC Promo
                      </span>
                    </td>
                    <td className="py-4 px-3">
                      <div className="flex items-center gap-1.5 bg-slate-100 px-2.5 py-1 rounded-lg border border-slate-200/80 max-w-max">
                        <span className="font-black text-slate-800 text-[11px]">CREATOR10</span>
                        <button
                          onClick={() => handleCopyCode('CREATOR10')}
                          className="p-0.5 text-slate-400 hover:text-slate-600"
                        >
                          <Copy className="w-3 h-3" />
                        </button>
                      </div>
                    </td>
                    <td className="py-4 px-3">
                      <span className="font-extrabold text-slate-900 block">10% OFF</span>
                      <span className="text-[10px] text-slate-400 font-medium block">on all plans</span>
                    </td>
                    <td className="py-4 px-3">
                      <span className="font-bold text-slate-800 block">10 May 2024</span>
                      <span className="text-[10px] text-slate-400 block">10:00 AM</span>
                    </td>
                    <td className="py-4 px-3">
                      <span className="font-bold text-slate-800 block">10 Jun 2024</span>
                      <span className="text-[10px] text-slate-400 block">11:59 PM</span>
                    </td>
                    <td className="py-4 px-3 w-36">
                      <div className="space-y-1">
                        <span className="font-extrabold text-slate-900 block text-[11px]">320 <span className="text-slate-400 font-normal">/ 1,000</span></span>
                        <div className="w-full h-1.5 bg-slate-100 rounded-full overflow-hidden">
                          <div className="h-full bg-indigo-600 rounded-full w-[32%]" />
                        </div>
                      </div>
                    </td>
                    <td className="py-4 px-3">
                      <span className="px-2.5 py-1 rounded-full bg-emerald-50 text-emerald-600 font-extrabold text-[10px]">
                        Active
                      </span>
                    </td>
                    <td className="py-4 pl-3 text-right">
                      <div className="flex items-center justify-end gap-1.5 text-slate-400">
                        <button className="p-1.5 rounded-lg hover:bg-slate-100 hover:text-slate-600 transition-colors">
                          <Eye className="w-4 h-4" />
                        </button>
                        <button className="p-1.5 rounded-lg hover:bg-slate-100 hover:text-slate-600 transition-colors">
                          <Edit3 className="w-4 h-4" />
                        </button>
                        <button className="p-1.5 rounded-lg hover:bg-rose-50 hover:text-rose-600 transition-colors">
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    </td>
                  </tr>

                  {/* Row 5: Summer Special */}
                  <tr className="hover:bg-slate-50/80 transition-colors">
                    <td className="py-4 pr-4">
                      <div className="flex items-center gap-3">
                        <div className="w-9 h-9 rounded-2xl bg-rose-100 text-rose-600 flex items-center justify-center flex-shrink-0">
                          <Sun className="w-4 h-4 stroke-[2.5]" />
                        </div>
                        <div>
                          <span className="font-extrabold text-slate-900 block text-xs">Summer Special</span>
                          <span className="text-[10px] text-slate-400 block font-normal">Summer season special offer</span>
                        </div>
                      </div>
                    </td>
                    <td className="py-4 px-3">
                      <span className="px-2.5 py-1 rounded-lg bg-rose-50 text-rose-600 font-bold text-[10px]">
                        Coupon
                      </span>
                    </td>
                    <td className="py-4 px-3">
                      <div className="flex items-center gap-1.5 bg-slate-100 px-2.5 py-1 rounded-lg border border-slate-200/80 max-w-max">
                        <span className="font-black text-slate-800 text-[11px]">SUMMER30</span>
                        <button
                          onClick={() => handleCopyCode('SUMMER30')}
                          className="p-0.5 text-slate-400 hover:text-slate-600"
                        >
                          <Copy className="w-3 h-3" />
                        </button>
                      </div>
                    </td>
                    <td className="py-4 px-3">
                      <span className="font-extrabold text-slate-900 block">30% OFF</span>
                      <span className="text-[10px] text-slate-400 font-medium block">on all plans</span>
                    </td>
                    <td className="py-4 px-3">
                      <span className="font-bold text-slate-800 block">01 May 2024</span>
                      <span className="text-[10px] text-slate-400 block">10:00 AM</span>
                    </td>
                    <td className="py-4 px-3">
                      <span className="font-bold text-slate-800 block">31 May 2024</span>
                      <span className="text-[10px] text-slate-400 block">11:59 PM</span>
                    </td>
                    <td className="py-4 px-3 w-36">
                      <div className="space-y-1">
                        <span className="font-extrabold text-slate-900 block text-[11px]">3,210 <span className="text-slate-400 font-normal">/ 6,000</span></span>
                        <div className="w-full h-1.5 bg-slate-100 rounded-full overflow-hidden">
                          <div className="h-full bg-indigo-600 rounded-full w-[53%]" />
                        </div>
                      </div>
                    </td>
                    <td className="py-4 px-3">
                      <span className="px-2.5 py-1 rounded-full bg-emerald-50 text-emerald-600 font-extrabold text-[10px]">
                        Active
                      </span>
                    </td>
                    <td className="py-4 pl-3 text-right">
                      <div className="flex items-center justify-end gap-1.5 text-slate-400">
                        <button className="p-1.5 rounded-lg hover:bg-slate-100 hover:text-slate-600 transition-colors">
                          <Eye className="w-4 h-4" />
                        </button>
                        <button className="p-1.5 rounded-lg hover:bg-slate-100 hover:text-slate-600 transition-colors">
                          <Edit3 className="w-4 h-4" />
                        </button>
                        <button className="p-1.5 rounded-lg hover:bg-rose-50 hover:text-rose-600 transition-colors">
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    </td>
                  </tr>

                  {/* Row 6: New User Offer */}
                  <tr className="hover:bg-slate-50/80 transition-colors opacity-75">
                    <td className="py-4 pr-4">
                      <div className="flex items-center gap-3">
                        <div className="w-9 h-9 rounded-2xl bg-slate-100 text-slate-600 flex items-center justify-center flex-shrink-0">
                          <Percent className="w-4 h-4 stroke-[2.5]" />
                        </div>
                        <div>
                          <span className="font-extrabold text-slate-900 block text-xs">New User Offer</span>
                          <span className="text-[10px] text-slate-400 block font-normal">Flat ₹100 off for new users</span>
                        </div>
                      </div>
                    </td>
                    <td className="py-4 px-3">
                      <span className="px-2.5 py-1 rounded-lg bg-slate-100 text-slate-600 font-bold text-[10px]">
                        Coupon
                      </span>
                    </td>
                    <td className="py-4 px-3">
                      <div className="flex items-center gap-1.5 bg-slate-100 px-2.5 py-1 rounded-lg border border-slate-200/80 max-w-max">
                        <span className="font-black text-slate-800 text-[11px]">NEW100</span>
                        <button
                          onClick={() => handleCopyCode('NEW100')}
                          className="p-0.5 text-slate-400 hover:text-slate-600"
                        >
                          <Copy className="w-3 h-3" />
                        </button>
                      </div>
                    </td>
                    <td className="py-4 px-3">
                      <span className="font-extrabold text-slate-900 block">₹100 OFF</span>
                      <span className="text-[10px] text-slate-400 font-medium block">on all plans</span>
                    </td>
                    <td className="py-4 px-3">
                      <span className="font-bold text-slate-800 block">01 May 2024</span>
                      <span className="text-[10px] text-slate-400 block">10:00 AM</span>
                    </td>
                    <td className="py-4 px-3">
                      <span className="font-bold text-slate-800 block">31 May 2024</span>
                      <span className="text-[10px] text-slate-400 block">11:59 PM</span>
                    </td>
                    <td className="py-4 px-3 w-36">
                      <div className="space-y-1">
                        <span className="font-extrabold text-slate-900 block text-[11px]">1,100 <span className="text-slate-400 font-normal">/ 3,000</span></span>
                        <div className="w-full h-1.5 bg-slate-100 rounded-full overflow-hidden">
                          <div className="h-full bg-slate-400 rounded-full w-[36%]" />
                        </div>
                      </div>
                    </td>
                    <td className="py-4 px-3">
                      <span className="px-2.5 py-1 rounded-full bg-rose-50 text-rose-600 font-extrabold text-[10px]">
                        Inactive
                      </span>
                    </td>
                    <td className="py-4 pl-3 text-right">
                      <div className="flex items-center justify-end gap-1.5 text-slate-400">
                        <button className="p-1.5 rounded-lg hover:bg-slate-100 hover:text-slate-600 transition-colors">
                          <Eye className="w-4 h-4" />
                        </button>
                        <button className="p-1.5 rounded-lg hover:bg-slate-100 hover:text-slate-600 transition-colors">
                          <Edit3 className="w-4 h-4" />
                        </button>
                        <button className="p-1.5 rounded-lg hover:bg-rose-50 hover:text-rose-600 transition-colors">
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    </td>
                  </tr>

                  {/* Row 7: Exam Warriors */}
                  <tr className="hover:bg-slate-50/80 transition-colors">
                    <td className="py-4 pr-4">
                      <div className="flex items-center gap-3">
                        <div className="w-9 h-9 rounded-2xl bg-amber-100 text-amber-600 flex items-center justify-center flex-shrink-0">
                          <Star className="w-4 h-4 stroke-[2.5]" />
                        </div>
                        <div>
                          <span className="font-extrabold text-slate-900 block text-xs">Exam Warriors</span>
                          <span className="text-[10px] text-slate-400 block font-normal">Exclusive for top performers</span>
                        </div>
                      </div>
                    </td>
                    <td className="py-4 px-3">
                      <span className="px-2.5 py-1 rounded-lg bg-amber-50 text-amber-600 font-bold text-[10px]">
                        Coupon
                      </span>
                    </td>
                    <td className="py-4 px-3">
                      <div className="flex items-center gap-1.5 bg-slate-100 px-2.5 py-1 rounded-lg border border-slate-200/80 max-w-max">
                        <span className="font-black text-slate-800 text-[11px]">WARRIOR15</span>
                        <button
                          onClick={() => handleCopyCode('WARRIOR15')}
                          className="p-0.5 text-slate-400 hover:text-slate-600"
                        >
                          <Copy className="w-3 h-3" />
                        </button>
                      </div>
                    </td>
                    <td className="py-4 px-3">
                      <span className="font-extrabold text-slate-900 block">15% OFF</span>
                      <span className="text-[10px] text-slate-400 font-medium block">on all plans</span>
                    </td>
                    <td className="py-4 px-3">
                      <span className="font-bold text-slate-800 block">05 May 2024</span>
                      <span className="text-[10px] text-slate-400 block">10:00 AM</span>
                    </td>
                    <td className="py-4 px-3">
                      <span className="font-bold text-slate-800 block">05 Jun 2024</span>
                      <span className="text-[10px] text-slate-400 block">11:59 PM</span>
                    </td>
                    <td className="py-4 px-3 w-36">
                      <div className="space-y-1">
                        <span className="font-extrabold text-slate-900 block text-[11px]">215 <span className="text-slate-400 font-normal">/ 1,000</span></span>
                        <div className="w-full h-1.5 bg-slate-100 rounded-full overflow-hidden">
                          <div className="h-full bg-blue-600 rounded-full w-[21%]" />
                        </div>
                      </div>
                    </td>
                    <td className="py-4 px-3">
                      <span className="px-2.5 py-1 rounded-full bg-blue-50 text-blue-600 font-extrabold text-[10px]">
                        Scheduled
                      </span>
                    </td>
                    <td className="py-4 pl-3 text-right">
                      <div className="flex items-center justify-end gap-1.5 text-slate-400">
                        <button className="p-1.5 rounded-lg hover:bg-slate-100 hover:text-slate-600 transition-colors">
                          <Eye className="w-4 h-4" />
                        </button>
                        <button className="p-1.5 rounded-lg hover:bg-slate-100 hover:text-slate-600 transition-colors">
                          <Edit3 className="w-4 h-4" />
                        </button>
                        <button className="p-1.5 rounded-lg hover:bg-rose-50 hover:text-rose-600 transition-colors">
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    </td>
                  </tr>

                </tbody>
              </table>
            </div>

            {/* ========================================================================= */}
            {/* 6. BOTTOM TABLE FOOTER & PAGINATION BAR */}
            {/* ========================================================================= */}
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pt-4 border-t border-slate-100 text-xs font-bold text-slate-500">
              
              <span>Showing 1 to 7 of 128 results</span>

              <div className="flex items-center gap-3">
                {/* Numbered Page Buttons */}
                <div className="flex items-center gap-1">
                  <button className="w-8 h-8 rounded-xl border border-slate-200 flex items-center justify-center hover:bg-slate-50 text-slate-400">
                    <ChevronLeft className="w-4 h-4" />
                  </button>

                  <button className="w-8 h-8 rounded-xl bg-[#5D3EED] text-white flex items-center justify-center font-extrabold shadow-sm">
                    1
                  </button>

                  <button className="w-8 h-8 rounded-xl border border-slate-200 flex items-center justify-center hover:bg-slate-50 text-slate-700">
                    2
                  </button>

                  <button className="w-8 h-8 rounded-xl border border-slate-200 flex items-center justify-center hover:bg-slate-50 text-slate-700">
                    3
                  </button>

                  <span className="px-1 text-slate-400 font-bold">...</span>

                  <button className="w-8 h-8 rounded-xl border border-slate-200 flex items-center justify-center hover:bg-slate-50 text-slate-700">
                    13
                  </button>

                  <button className="w-8 h-8 rounded-xl border border-slate-200 flex items-center justify-center hover:bg-slate-50 text-slate-700">
                    <ChevronRight className="w-4 h-4" />
                  </button>
                </div>

                {/* Rows Per Page Dropdown */}
                <div className="flex items-center gap-1 bg-white border border-slate-200 rounded-xl px-3 py-1.5 text-xs font-bold text-slate-700 cursor-pointer shadow-xs">
                  <span>10 / page</span>
                  <ChevronDown className="w-3.5 h-3.5 text-slate-400" />
                </div>
              </div>

            </div>

          </div>

    </div>
  );
};
