import React from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Menu,
  Bell,
  Settings,
  Edit3,
  GraduationCap,
  Mail,
  Phone,
  MapPin,
  ChevronRight,
  ClipboardList,
  Target,
  TrendingUp,
  Clock,
  Crown,
  Gem,
  User,
  Sliders,
  Shield,
  Smartphone,
  HelpCircle,
  Headphones,
  Star,
  LogOut,
  Flame,
} from 'lucide-react';

interface MobileProfileScreenProps {
  onOpenDrawer?: () => void;
  onNavigatePlan?: () => void;
  onLogout?: () => void;
  isMobileFrame?: boolean;
}

export const MobileProfileScreen: React.FC<MobileProfileScreenProps> = ({
  onOpenDrawer,
  onNavigatePlan,
  onLogout,
  isMobileFrame = false,
}) => {
  const navigate = useNavigate();

  const handleLogout = () => {
    if (onLogout) onLogout();
    else navigate('/signup');
  };

  const handlePlanClick = () => {
    if (onNavigatePlan) onNavigatePlan();
    else navigate('/app/pricing-plans');
  };

  return (
    <div className={`w-full font-sans bg-[#FDFDFF] text-slate-900 select-none pb-20 ${isMobileFrame ? 'px-0 py-0' : 'max-w-md mx-auto min-h-screen shadow-xl rounded-3xl'}`}>
      
      {/* ========================================================================= */}
      {/* 1. TOP HEADER BAR */}
      {/* ========================================================================= */}
      <div className="bg-white px-4 py-3 border-b border-slate-100 flex items-center justify-between sticky top-0 z-30 shadow-xs">
        <button
          onClick={onOpenDrawer}
          className="p-1 text-slate-800 hover:text-[#5D3EED] transition-colors"
        >
          <Menu className="w-5 h-5 stroke-[2.5]" />
        </button>

        <h1 className="text-base font-black text-slate-900 text-center flex-1">
          Profile
        </h1>

        <div className="flex items-center gap-2">
          {/* Notification Bell */}
          <button className="relative p-1 text-slate-800 hover:text-[#5D3EED] transition-colors">
            <Bell className="w-5 h-5 stroke-[2]" />
            <span className="absolute -top-1 -right-1 bg-rose-500 text-white text-[9px] font-bold w-4 h-4 rounded-full flex items-center justify-center border border-white">
              3
            </span>
          </button>

          {/* Settings Gear */}
          <button className="p-1 text-slate-800 hover:text-[#5D3EED] transition-colors">
            <Settings className="w-5 h-5 stroke-[2]" />
          </button>
        </div>
      </div>

      <div className="p-4 space-y-4">
        
        {/* ========================================================================= */}
        {/* 2. HERO PROFILE GRADIENT CARD */}
        {/* ========================================================================= */}
        <div className="bg-gradient-to-r from-[#3B0764] via-[#4C1D95] to-[#5D3EED] text-white p-4.5 rounded-3xl relative overflow-hidden shadow-lg shadow-indigo-900/20 flex items-center justify-between">
          <div className="flex items-center gap-3.5">
            {/* Avatar with Edit Badge */}
            <div className="relative flex-shrink-0">
              <img
                src="https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=120&auto=format&fit=crop&q=80"
                alt="Rohit Sharma"
                className="w-16 h-16 rounded-full object-cover border-2 border-white/40 p-0.5 shadow-md"
              />
              <button className="absolute bottom-0 right-0 p-1 rounded-full bg-white text-[#5D3EED] shadow-md hover:bg-purple-50 transition-colors">
                <Edit3 className="w-3 h-3 stroke-[2.5]" />
              </button>
            </div>

            {/* Profile Info */}
            <div className="space-y-0.5">
              <div className="flex items-center gap-2">
                <h2 className="text-base font-black text-white leading-tight">Rohit Sharma</h2>
                <span className="bg-white/10 border border-white/20 text-indigo-100 text-[9px] font-extrabold px-2 py-0.5 rounded-full flex items-center gap-1">
                  <GraduationCap className="w-3 h-3 text-indigo-200" />
                  <span>NEET Aspirant</span>
                </span>
              </div>

              <div className="text-[11px] text-indigo-200 font-medium space-y-0.5 pt-0.5">
                <div className="flex items-center gap-1.5">
                  <Mail className="w-3 h-3 text-indigo-300" />
                  <span>rohitsharma22@gmail.com</span>
                </div>
                <div className="flex items-center gap-1.5">
                  <Phone className="w-3 h-3 text-indigo-300" />
                  <span>+91 98765 43210</span>
                </div>
                <div className="flex items-center gap-1.5">
                  <MapPin className="w-3 h-3 text-indigo-300" />
                  <span>New Delhi, India</span>
                </div>
              </div>
            </div>
          </div>

          <ChevronRight className="w-5 h-5 text-white/70 flex-shrink-0" />
        </div>

        {/* ========================================================================= */}
        {/* 3. 4 METRIC QUICK SUMMARY CARDS GRID */}
        {/* ========================================================================= */}
        <div className="grid grid-cols-4 gap-2.5">
          {/* Card 1: Tests Taken */}
          <div className="bg-white border border-slate-200/80 rounded-2xl p-2.5 text-center shadow-xs flex flex-col items-center justify-center">
            <div className="w-9 h-9 rounded-2xl bg-blue-50 text-blue-600 flex items-center justify-center">
              <ClipboardList className="w-4 h-4" />
            </div>
            <span className="text-sm font-black text-slate-900 mt-1.5 block">32</span>
            <span className="text-[9px] text-slate-400 font-bold block">Tests Taken</span>
          </div>

          {/* Card 2: Avg. Score */}
          <div className="bg-white border border-slate-200/80 rounded-2xl p-2.5 text-center shadow-xs flex flex-col items-center justify-center">
            <div className="w-9 h-9 rounded-2xl bg-orange-50 text-orange-600 flex items-center justify-center">
              <Target className="w-4 h-4" />
            </div>
            <span className="text-sm font-black text-slate-900 mt-1.5 block">78%</span>
            <span className="text-[9px] text-slate-400 font-bold block">Avg. Score</span>
          </div>

          {/* Card 3: Best Score */}
          <div className="bg-white border border-slate-200/80 rounded-2xl p-2.5 text-center shadow-xs flex flex-col items-center justify-center">
            <div className="w-9 h-9 rounded-2xl bg-emerald-50 text-emerald-600 flex items-center justify-center">
              <TrendingUp className="w-4 h-4" />
            </div>
            <span className="text-sm font-black text-slate-900 mt-1.5 block">1280</span>
            <span className="text-[9px] text-slate-400 font-bold block">Best Score</span>
          </div>

          {/* Card 4: Time Practiced */}
          <div className="bg-white border border-slate-200/80 rounded-2xl p-2.5 text-center shadow-xs flex flex-col items-center justify-center">
            <div className="w-9 h-9 rounded-2xl bg-purple-50 text-[#5D3EED] flex items-center justify-center">
              <Clock className="w-4 h-4 text-[#5D3EED]" />
            </div>
            <span className="text-sm font-black text-slate-900 mt-1.5 block">48h</span>
            <span className="text-[9px] text-slate-400 font-bold block">Time Practiced</span>
          </div>
        </div>

        {/* ========================================================================= */}
        {/* 4. STREAK BANNER CARD */}
        {/* ========================================================================= */}
        <div className="bg-[#F8F7FF] border border-purple-200/80 rounded-2xl p-3.5 flex items-center justify-between shadow-xs">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-2xl bg-gradient-to-tr from-indigo-500 to-purple-600 text-white flex items-center justify-center shadow-sm">
              <Crown className="w-5 h-5 fill-amber-300 text-amber-300" />
            </div>
            <div>
              <h4 className="text-xs font-bold text-slate-800">
                You're on a <span className="text-[#5D3EED] font-extrabold">7 day streak! 🔥</span>
              </h4>
              <span className="text-[10px] text-slate-500 font-medium block mt-0.5">
                Keep it up and reach your goals.
              </span>
            </div>
          </div>

          <button className="border border-purple-200 bg-white text-[#5D3EED] font-extrabold text-xs px-3.5 py-1.5 rounded-xl hover:bg-purple-50 flex items-center gap-1 shadow-xs transition-colors">
            <span>View Streak</span>
            <ChevronRight className="w-3.5 h-3.5" />
          </button>
        </div>

        {/* ========================================================================= */}
        {/* 5. GO PREMIUM PRO BANNER CARD */}
        {/* ========================================================================= */}
        <div className="bg-white border border-slate-200/80 rounded-2xl p-3.5 flex items-center justify-between shadow-xs">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-2xl bg-[#5D3EED] text-white flex items-center justify-center shadow-sm">
              <Gem className="w-5 h-5 text-white" />
            </div>
            <div>
              <div className="flex items-center gap-1.5">
                <h4 className="text-xs font-extrabold text-slate-900">Go Premium</h4>
                <span className="px-2 py-0.5 rounded-md bg-purple-100 text-[#5D3EED] text-[9px] font-extrabold uppercase">
                  Pro
                </span>
              </div>
              <span className="text-[10px] text-slate-500 font-medium block mt-0.5 max-w-[170px]">
                Unlock all premium features and boost your preparation.
              </span>
            </div>
          </div>

          <button
            onClick={handlePlanClick}
            className="border border-[#5D3EED] text-[#5D3EED] font-extrabold text-xs px-3.5 py-1.5 rounded-xl hover:bg-purple-50 flex items-center gap-1 shadow-xs transition-colors"
          >
            <span>Upgrade Now</span>
            <ChevronRight className="w-3.5 h-3.5" />
          </button>
        </div>

        {/* ========================================================================= */}
        {/* 6. ACCOUNT MENU SECTION CARD */}
        {/* ========================================================================= */}
        <div className="bg-white border border-slate-200/80 rounded-3xl p-4 space-y-3 shadow-xs">
          <h3 className="text-xs font-extrabold text-slate-900 uppercase tracking-wider">
            Account
          </h3>

          <div className="divide-y divide-slate-100 text-xs font-semibold">
            {/* Option 1: Edit Profile */}
            <div className="py-2.5 flex items-center justify-between hover:bg-slate-50 rounded-xl px-1 cursor-pointer transition-colors">
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-xl bg-purple-50 text-[#5D3EED] flex items-center justify-center">
                  <User className="w-4 h-4" />
                </div>
                <div>
                  <h4 className="font-extrabold text-slate-900">Edit Profile</h4>
                  <p className="text-[10px] text-slate-400 font-medium">Update your personal information</p>
                </div>
              </div>
              <ChevronRight className="w-4 h-4 text-slate-400" />
            </div>

            {/* Option 2: My Plan */}
            <div
              onClick={handlePlanClick}
              className="py-2.5 flex items-center justify-between hover:bg-slate-50 rounded-xl px-1 cursor-pointer transition-colors"
            >
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-xl bg-amber-50 text-amber-600 flex items-center justify-center">
                  <Crown className="w-4 h-4" />
                </div>
                <div>
                  <h4 className="font-extrabold text-slate-900">My Plan</h4>
                  <p className="text-[10px] text-slate-400 font-medium">View your current plan and status</p>
                </div>
              </div>

              <div className="flex items-center gap-2">
                <span className="px-2.5 py-0.5 rounded-full bg-emerald-50 text-emerald-600 font-extrabold text-[10px]">
                  Active
                </span>
                <ChevronRight className="w-4 h-4 text-slate-400" />
              </div>
            </div>

            {/* Option 3: Study Goal */}
            <div className="py-2.5 flex items-center justify-between hover:bg-slate-50 rounded-xl px-1 cursor-pointer transition-colors">
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-xl bg-rose-50 text-rose-500 flex items-center justify-center">
                  <Target className="w-4 h-4" />
                </div>
                <div>
                  <h4 className="font-extrabold text-slate-900">Study Goal</h4>
                  <p className="text-[10px] text-slate-400 font-medium">NEET 2024</p>
                </div>
              </div>

              <div className="flex items-center gap-2">
                <span className="text-[#5D3EED] font-extrabold text-[11px]">320 Days Left</span>
                <ChevronRight className="w-4 h-4 text-slate-400" />
              </div>
            </div>

            {/* Option 4: Preferences */}
            <div className="py-2.5 flex items-center justify-between hover:bg-slate-50 rounded-xl px-1 cursor-pointer transition-colors">
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center">
                  <Sliders className="w-4 h-4" />
                </div>
                <div>
                  <h4 className="font-extrabold text-slate-900">Preferences</h4>
                  <p className="text-[10px] text-slate-400 font-medium">Manage app preferences</p>
                </div>
              </div>
              <ChevronRight className="w-4 h-4 text-slate-400" />
            </div>

            {/* Option 5: Privacy & Security */}
            <div className="py-2.5 flex items-center justify-between hover:bg-slate-50 rounded-xl px-1 cursor-pointer transition-colors">
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-xl bg-purple-50 text-purple-600 flex items-center justify-center">
                  <Shield className="w-4 h-4" />
                </div>
                <div>
                  <h4 className="font-extrabold text-slate-900">Privacy & Security</h4>
                  <p className="text-[10px] text-slate-400 font-medium">Manage your privacy and security</p>
                </div>
              </div>
              <ChevronRight className="w-4 h-4 text-slate-400" />
            </div>

            {/* Option 6: Connected Devices */}
            <div className="py-2.5 flex items-center justify-between hover:bg-slate-50 rounded-xl px-1 cursor-pointer transition-colors">
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center">
                  <Smartphone className="w-4 h-4" />
                </div>
                <div>
                  <h4 className="font-extrabold text-slate-900">Connected Devices</h4>
                  <p className="text-[10px] text-slate-400 font-medium">Manage your active sessions</p>
                </div>
              </div>

              <div className="flex items-center gap-2">
                <span className="text-[#5D3EED] font-extrabold text-[11px]">2 Devices</span>
                <ChevronRight className="w-4 h-4 text-slate-400" />
              </div>
            </div>

          </div>
        </div>

        {/* ========================================================================= */}
        {/* 7. SUPPORT MENU SECTION CARD */}
        {/* ========================================================================= */}
        <div className="bg-white border border-slate-200/80 rounded-3xl p-4 space-y-3 shadow-xs">
          <h3 className="text-xs font-extrabold text-slate-900 uppercase tracking-wider">
            Support
          </h3>

          <div className="divide-y divide-slate-100 text-xs font-semibold">
            {/* Option 1: Help & FAQ */}
            <div className="py-2.5 flex items-center justify-between hover:bg-slate-50 rounded-xl px-1 cursor-pointer transition-colors">
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-xl bg-purple-50 text-[#5D3EED] flex items-center justify-center">
                  <HelpCircle className="w-4 h-4" />
                </div>
                <div>
                  <h4 className="font-extrabold text-slate-900">Help & FAQ</h4>
                  <p className="text-[10px] text-slate-400 font-medium">Get help and find answers</p>
                </div>
              </div>
              <ChevronRight className="w-4 h-4 text-slate-400" />
            </div>

            {/* Option 2: Contact Us */}
            <div className="py-2.5 flex items-center justify-between hover:bg-slate-50 rounded-xl px-1 cursor-pointer transition-colors">
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center">
                  <Headphones className="w-4 h-4" />
                </div>
                <div>
                  <h4 className="font-extrabold text-slate-900">Contact Us</h4>
                  <p className="text-[10px] text-slate-400 font-medium">We're here to help you</p>
                </div>
              </div>
              <ChevronRight className="w-4 h-4 text-slate-400" />
            </div>

            {/* Option 3: Rate Us */}
            <div className="py-2.5 flex items-center justify-between hover:bg-slate-50 rounded-xl px-1 cursor-pointer transition-colors">
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-xl bg-amber-50 text-amber-500 flex items-center justify-center">
                  <Star className="w-4 h-4 fill-amber-400" />
                </div>
                <div>
                  <h4 className="font-extrabold text-slate-900">Rate Us</h4>
                  <p className="text-[10px] text-slate-400 font-medium">Share your feedback</p>
                </div>
              </div>
              <ChevronRight className="w-4 h-4 text-slate-400" />
            </div>

          </div>
        </div>

        {/* ========================================================================= */}
        {/* 8. LOGOUT ACTION BUTTON */}
        {/* ========================================================================= */}
        <button
          onClick={handleLogout}
          className="w-full py-3.5 rounded-2xl bg-rose-50/70 border border-rose-100 text-rose-600 font-extrabold text-xs hover:bg-rose-100 transition-colors flex items-center justify-center gap-2 shadow-xs"
        >
          <LogOut className="w-4 h-4 text-rose-600" />
          <span>Log Out</span>
        </button>

      </div>

    </div>
  );
};
