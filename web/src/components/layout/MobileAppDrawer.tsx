import React from 'react';
import { useNavigate } from 'react-router-dom';
import {
  X,
  Edit3,
  Crown,
  ChevronRight,
  Home,
  Target,
  Edit,
  ClipboardCheck,
  History,
  BarChart3,
  PieChart,
  Bookmark,
  FileText,
  Layers,
  BookOpen,
  User,
  Wallet,
  Receipt,
  Gift,
  HelpCircle,
  Headphones,
  MessageCircle,
  Info,
  Settings,
  LogOut,
} from 'lucide-react';

interface MobileAppDrawerProps {
  isOpen: boolean;
  onClose: () => void;
  onNavigateTab: (tab: string, extraState?: Record<string, boolean>) => void;
}

export const MobileAppDrawer: React.FC<MobileAppDrawerProps> = ({
  isOpen,
  onClose,
  onNavigateTab,
}) => {
  const navigate = useNavigate();

  if (!isOpen) return null;

  const handleItemClick = (action: () => void) => {
    action();
    onClose();
  };

  return (
    <div className="absolute inset-0 z-50 flex">
      {/* Dark Backdrop Overlay */}
      <div
        onClick={onClose}
        className="absolute inset-0 bg-slate-950/60 backdrop-blur-xs transition-opacity duration-300 animate-fadeIn"
      />

      {/* Drawer Container (Sliding from Left) */}
      <div className="relative w-[85%] max-w-[340px] bg-white h-full shadow-2xl flex flex-col justify-between overflow-y-auto custom-scrollbar select-none z-10 animate-slideRight font-sans">
        
        <div className="p-4 space-y-4">
          
          {/* Top Status & Close Row */}
          <div className="flex items-center justify-between pt-2">
            <span className="text-xs font-extrabold text-slate-400">9:41</span>
            <button
              onClick={onClose}
              className="p-1.5 rounded-full text-slate-400 hover:text-slate-700 hover:bg-slate-100 transition-colors"
            >
              <X className="w-5 h-5 stroke-[2.5]" />
            </button>
          </div>

          {/* User Profile Header */}
          <div className="flex items-center justify-between pt-1">
            <div className="flex items-center gap-3">
              <img
                src="https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&auto=format&fit=crop&q=80"
                alt="Arjun Kumar"
                className="w-13 h-13 rounded-full object-cover border-2 border-indigo-100 p-0.5 shadow-sm"
              />
              <div>
                <h3 className="text-base font-black text-slate-900 leading-tight">Arjun Kumar</h3>
                <span className="text-xs text-slate-400 font-medium block mt-0.5">arjun@example.com</span>
              </div>
            </div>

            <button
              onClick={() => handleItemClick(() => onNavigateTab('profile'))}
              className="p-1.5 rounded-xl bg-purple-50 text-[#5D3EED] hover:bg-purple-100 transition-colors"
            >
              <Edit3 className="w-4 h-4" />
            </button>
          </div>

          {/* Active Plan Card (Pro Plan) */}
          <div
            onClick={() => handleItemClick(() => onNavigateTab('practice', { initialMobilePricing: true }))}
            className="bg-[#F8F7FF] border border-purple-200/80 rounded-2xl p-3 flex items-center justify-between shadow-xs cursor-pointer hover:bg-purple-100/40 transition-colors"
          >
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 rounded-xl bg-purple-100 text-[#5D3EED] flex items-center justify-center">
                <Crown className="w-5 h-5 text-[#5D3EED]" />
              </div>
              <div>
                <h4 className="text-xs font-bold text-slate-800">
                  You're on <span className="text-[#5D3EED] font-extrabold">Pro Plan</span>
                </h4>
                <span className="text-[10px] text-slate-400 font-medium block">Valid till 20 May 2025</span>
              </div>
            </div>

            <ChevronRight className="w-4 h-4 text-slate-400" />
          </div>

          {/* ========================================================================= */}
          {/* SECTION 1: STUDY */}
          {/* ========================================================================= */}
          <div className="space-y-1 pt-1">
            <span className="text-[10px] font-extrabold uppercase text-slate-400 tracking-wider block px-2 mb-1">
              STUDY
            </span>

            {/* Home (Active Selected Item) */}
            <button
              onClick={() => handleItemClick(() => onNavigateTab('home'))}
              className="w-full bg-[#F5F3FF] text-[#5D3EED] font-extrabold text-xs py-2.5 px-3 rounded-xl flex items-center gap-3 border-l-4 border-[#5D3EED] shadow-xs"
            >
              <Home className="w-4 h-4" />
              <span>Home</span>
            </button>

            {/* Paper Prediction */}
            <button
              onClick={() => handleItemClick(() => onNavigateTab('practice', { initialPrediction: true }))}
              className="w-full text-slate-700 font-bold text-xs py-2.5 px-3 rounded-xl flex items-center gap-3 hover:bg-slate-50 transition-colors"
            >
              <Target className="w-4 h-4 text-slate-500" />
              <span>Paper Prediction</span>
            </button>

            {/* Practice */}
            <button
              onClick={() => handleItemClick(() => onNavigateTab('practice'))}
              className="w-full text-slate-700 font-bold text-xs py-2.5 px-3 rounded-xl flex items-center gap-3 hover:bg-slate-50 transition-colors"
            >
              <Edit className="w-4 h-4 text-slate-500" />
              <span>Practice</span>
            </button>

            {/* Tests */}
            <button
              onClick={() => handleItemClick(() => onNavigateTab('test'))}
              className="w-full text-slate-700 font-bold text-xs py-2.5 px-3 rounded-xl flex items-center gap-3 hover:bg-slate-50 transition-colors"
            >
              <ClipboardCheck className="w-4 h-4 text-slate-500" />
              <span>Tests</span>
            </button>

            {/* Previous Attempts */}
            <button
              onClick={() => handleItemClick(() => onNavigateTab('analytics'))}
              className="w-full text-slate-700 font-bold text-xs py-2.5 px-3 rounded-xl flex items-center gap-3 hover:bg-slate-50 transition-colors"
            >
              <History className="w-4 h-4 text-slate-500" />
              <span>Previous Attempts</span>
            </button>

            {/* Performance */}
            <button
              onClick={() => handleItemClick(() => onNavigateTab('analytics'))}
              className="w-full text-slate-700 font-bold text-xs py-2.5 px-3 rounded-xl flex items-center gap-3 hover:bg-slate-50 transition-colors"
            >
              <BarChart3 className="w-4 h-4 text-slate-500" />
              <span>Performance</span>
            </button>

            {/* Analytics */}
            <button
              onClick={() => handleItemClick(() => onNavigateTab('analytics'))}
              className="w-full text-slate-700 font-bold text-xs py-2.5 px-3 rounded-xl flex items-center gap-3 hover:bg-slate-50 transition-colors"
            >
              <PieChart className="w-4 h-4 text-slate-500" />
              <span>Analytics</span>
            </button>

            {/* Bookmarks */}
            <button
              onClick={() => handleItemClick(() => navigate('/bookmarks'))}
              className="w-full text-slate-700 font-bold text-xs py-2.5 px-3 rounded-xl flex items-center gap-3 hover:bg-slate-50 transition-colors"
            >
              <Bookmark className="w-4 h-4 text-slate-500" />
              <span>Bookmarks</span>
            </button>

            {/* Notes */}
            <button
              onClick={() => handleItemClick(() => navigate('/practice'))}
              className="w-full text-slate-700 font-bold text-xs py-2.5 px-3 rounded-xl flex items-center gap-3 hover:bg-slate-50 transition-colors"
            >
              <FileText className="w-4 h-4 text-slate-500" />
              <span>Notes</span>
            </button>

            {/* Flashcards */}
            <button
              onClick={() => handleItemClick(() => navigate('/practice'))}
              className="w-full text-slate-700 font-bold text-xs py-2.5 px-3 rounded-xl flex items-center gap-3 hover:bg-slate-50 transition-colors"
            >
              <Layers className="w-4 h-4 text-slate-500" />
              <span>Flashcards</span>
            </button>

            {/* NCERT Solutions */}
            <button
              onClick={() => handleItemClick(() => onNavigateTab('practice'))}
              className="w-full text-slate-700 font-bold text-xs py-2.5 px-3 rounded-xl flex items-center gap-3 hover:bg-slate-50 transition-colors"
            >
              <BookOpen className="w-4 h-4 text-slate-500" />
              <span>NCERT Solutions</span>
            </button>
          </div>

          {/* ========================================================================= */}
          {/* SECTION 2: ACCOUNT */}
          {/* ========================================================================= */}
          <div className="space-y-1 pt-3 border-t border-slate-100">
            <span className="text-[10px] font-extrabold uppercase text-slate-400 tracking-wider block px-2 mb-1">
              ACCOUNT
            </span>

            {/* My Profile */}
            <button
              onClick={() => handleItemClick(() => onNavigateTab('profile'))}
              className="w-full text-slate-700 font-bold text-xs py-2.5 px-3 rounded-xl flex items-center gap-3 hover:bg-slate-50 transition-colors"
            >
              <User className="w-4 h-4 text-slate-500" />
              <span>My Profile</span>
            </button>

            {/* My Plan */}
            <button
              onClick={() => handleItemClick(() => onNavigateTab('practice', { initialMobilePricing: true }))}
              className="w-full text-slate-700 font-bold text-xs py-2.5 px-3 rounded-xl flex items-center gap-3 hover:bg-slate-50 transition-colors"
            >
              <Crown className="w-4 h-4 text-slate-500" />
              <span>My Plan</span>
            </button>

            {/* Wallet */}
            <button
              onClick={() => handleItemClick(() => onNavigateTab('practice', { initialPayment: true }))}
              className="w-full text-slate-700 font-bold text-xs py-2.5 px-3 rounded-xl flex items-center gap-3 hover:bg-slate-50 transition-colors"
            >
              <Wallet className="w-4 h-4 text-slate-500" />
              <span>Wallet</span>
            </button>

            {/* Transactions */}
            <button
              onClick={() => handleItemClick(() => onNavigateTab('practice', { initialPayment: true }))}
              className="w-full text-slate-700 font-bold text-xs py-2.5 px-3 rounded-xl flex items-center gap-3 hover:bg-slate-50 transition-colors"
            >
              <Receipt className="w-4 h-4 text-slate-500" />
              <span>Transactions</span>
            </button>

            {/* Refer & Earn */}
            <button
              onClick={() => handleItemClick(() => navigate('/pricing'))}
              className="w-full text-slate-700 font-bold text-xs py-2.5 px-3 rounded-xl flex items-center gap-3 hover:bg-slate-50 transition-colors"
            >
              <Gift className="w-4 h-4 text-slate-500" />
              <span>Refer & Earn</span>
            </button>
          </div>

          {/* ========================================================================= */}
          {/* SECTION 3: SUPPORT */}
          {/* ========================================================================= */}
          <div className="space-y-1 pt-3 border-t border-slate-100">
            <span className="text-[10px] font-extrabold uppercase text-slate-400 tracking-wider block px-2 mb-1">
              SUPPORT
            </span>

            {/* Help Center */}
            <button
              onClick={() => handleItemClick(() => navigate('/pricing'))}
              className="w-full text-slate-700 font-bold text-xs py-2.5 px-3 rounded-xl flex items-center gap-3 hover:bg-slate-50 transition-colors"
            >
              <HelpCircle className="w-4 h-4 text-slate-500" />
              <span>Help Center</span>
            </button>

            {/* Contact Us */}
            <button
              onClick={() => handleItemClick(() => navigate('/pricing'))}
              className="w-full text-slate-700 font-bold text-xs py-2.5 px-3 rounded-xl flex items-center gap-3 hover:bg-slate-50 transition-colors"
            >
              <Headphones className="w-4 h-4 text-slate-500" />
              <span>Contact Us</span>
            </button>

            {/* FAQ */}
            <button
              onClick={() => handleItemClick(() => navigate('/pricing'))}
              className="w-full text-slate-700 font-bold text-xs py-2.5 px-3 rounded-xl flex items-center gap-3 hover:bg-slate-50 transition-colors"
            >
              <MessageCircle className="w-4 h-4 text-slate-500" />
              <span>FAQ</span>
            </button>

            {/* About Us */}
            <button
              onClick={() => handleItemClick(() => navigate('/'))}
              className="w-full text-slate-700 font-bold text-xs py-2.5 px-3 rounded-xl flex items-center gap-3 hover:bg-slate-50 transition-colors"
            >
              <Info className="w-4 h-4 text-slate-500" />
              <span>About Us</span>
            </button>
          </div>

          {/* ========================================================================= */}
          {/* SECTION 4: SYSTEM & LOGOUT */}
          {/* ========================================================================= */}
          <div className="space-y-1 pt-3 border-t border-slate-100">
            {/* Settings */}
            <button
              onClick={() => handleItemClick(() => onNavigateTab('profile'))}
              className="w-full text-slate-700 font-bold text-xs py-2.5 px-3 rounded-xl flex items-center gap-3 hover:bg-slate-50 transition-colors"
            >
              <Settings className="w-4 h-4 text-slate-500" />
              <span>Settings</span>
            </button>

            {/* Logout */}
            <button
              onClick={() => handleItemClick(() => navigate('/signup'))}
              className="w-full text-slate-700 font-bold text-xs py-2.5 px-3 rounded-xl flex items-center gap-3 hover:bg-rose-50 hover:text-rose-600 transition-colors"
            >
              <LogOut className="w-4 h-4 text-slate-500 hover:text-rose-600" />
              <span>Logout</span>
            </button>

            {/* App Version Info */}
            <div className="pt-3 px-2 text-[10px] font-bold text-slate-400 text-left">
              App Version 2.4.1
            </div>
          </div>

        </div>

      </div>
    </div>
  );
};
