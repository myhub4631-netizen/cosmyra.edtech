import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  ArrowLeft,
  ShieldCheck,
  Star,
  Rocket,
  Crown,
  Gem,
  ChevronRight,
  Lock,
  RotateCcw,
  Headphones,
  Check,
} from 'lucide-react';

interface MobilePricingScreenProps {
  onBack?: () => void;
  onSelectPlan?: (planId: string) => void;
  isMobileFrame?: boolean;
}

export const MobilePricingScreen: React.FC<MobilePricingScreenProps> = ({
  onBack,
  onSelectPlan,
  isMobileFrame = false,
}) => {
  const navigate = useNavigate();
  const [selectedPlan, setSelectedPlan] = useState<string>('pro');

  const handleBack = () => {
    if (onBack) onBack();
    else navigate(-1);
  };

  const handleChoosePlan = (planId: string) => {
    if (onSelectPlan) {
      onSelectPlan(planId);
    } else {
      navigate('/app/payment');
    }
  };

  return (
    <div className={`w-full font-sans bg-[#FDFDFF] text-slate-900 select-none pb-12 ${isMobileFrame ? 'px-0 py-0' : 'max-w-md mx-auto min-h-screen shadow-xl rounded-3xl pb-16'}`}>
      
      {/* ========================================================================= */}
      {/* 1. TOP HEADER BAR */}
      {/* ========================================================================= */}
      <div className="bg-white px-4 py-3 border-b border-slate-100 flex items-center justify-between sticky top-0 z-30 shadow-xs">
        <button
          onClick={handleBack}
          className="p-1 text-slate-800 hover:text-indigo-600 transition-colors"
        >
          <ArrowLeft className="w-5 h-5 stroke-[2.5]" />
        </button>

        <h1 className="text-base font-extrabold text-slate-900 tracking-tight">
          Pricing Plans
        </h1>

        <div className="flex items-center gap-1 text-[#4F46E5] text-xs font-bold">
          <ShieldCheck className="w-4 h-4 text-[#4F46E5]" />
          <span>100% Secure</span>
        </div>
      </div>

      {/* ========================================================================= */}
      {/* 2. HERO TITLE SECTION */}
      {/* ========================================================================= */}
      <div className="pt-6 pb-4 px-4 text-center space-y-2">
        <h2 className="text-xl sm:text-2xl font-black text-slate-900 tracking-tight leading-tight">
          Choose the plan that <br />
          matches <span className="text-[#4F46E5]">your preparation</span>
        </h2>

        <p className="text-xs text-slate-500 font-medium max-w-xs mx-auto">
          Practice more, analyze better and improve faster with Cosmyra.
        </p>

        {/* Access Badge */}
        <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-[#F1F5F9] border border-slate-200 text-[#475569] text-[11px] font-extrabold mt-1">
          <div className="w-3.5 h-3.5 rounded-full bg-[#4F46E5] text-white flex items-center justify-center text-[9px] font-bold">
            ✓
          </div>
          <span>All plans include Web + Mobile Access</span>
        </div>
      </div>

      {/* ========================================================================= */}
      {/* 3. 4 STACKED PRICING CARDS */}
      {/* ========================================================================= */}
      <div className="p-4 space-y-4">
        
        {/* Card 1: Trial Pass */}
        <div className="bg-[#FFFDF5] border border-[#FDE68A] rounded-2xl p-4 space-y-3 shadow-xs">
          {/* Header Row */}
          <div className="flex items-start justify-between">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-[#FEF3C7] text-[#D97706] flex items-center justify-center flex-shrink-0">
                <Star className="w-5 h-5 fill-amber-500 text-amber-500" />
              </div>
              <div>
                <div className="flex items-center gap-2">
                  <h3 className="text-base font-extrabold text-slate-900">Trial Pass</h3>
                  <span className="px-2 py-0.5 rounded-lg bg-amber-100 text-amber-800 text-[10px] font-bold">
                    30 Days
                  </span>
                </div>
                <p className="text-[11px] text-slate-500 font-medium">Try Cosmyra for 30 days</p>
              </div>
            </div>
            <ChevronRight className="w-5 h-5 text-slate-400 mt-1" />
          </div>

          {/* Grid Content: Price + Features List + CTA */}
          <div className="grid grid-cols-12 gap-2 items-center pt-1">
            {/* Price */}
            <div className="col-span-3">
              <span className="text-2xl font-black text-[#D97706] block">₹99</span>
              <span className="text-[10px] font-bold text-slate-500 block">1 Month</span>
            </div>

            {/* 2-Column Feature List */}
            <div className="col-span-6 grid grid-cols-2 gap-x-2 gap-y-1 text-[10px] font-bold text-slate-700">
              <div className="flex items-center gap-1">
                <span className="text-[#D97706]">✓</span>
                <span className="truncate">Core question practice</span>
              </div>
              <div className="flex items-center gap-1">
                <span className="text-[#D97706]">✓</span>
                <span className="truncate">Instant feedback</span>
              </div>
              <div className="flex items-center gap-1">
                <span className="text-[#D97706]">✓</span>
                <span className="truncate">PYQs, NCERT & NTA</span>
              </div>
              <div className="flex items-center gap-1">
                <span className="text-[#D97706]">✓</span>
                <span className="truncate">Detailed solutions</span>
              </div>
              <div className="flex items-center gap-1">
                <span className="text-[#D97706]">✓</span>
                <span className="truncate">5 Mock Tests</span>
              </div>
              <div className="flex items-center gap-1">
                <span className="text-[#D97706]">✓</span>
                <span className="truncate">Paper prediction</span>
              </div>
            </div>

            {/* Action Button */}
            <div className="col-span-3 text-right">
              <button
                onClick={() => handleChoosePlan('trial')}
                className="px-3 py-2 rounded-xl border border-[#FCD34D] text-[#D97706] bg-white font-extrabold text-xs hover:bg-amber-50 transition-colors shadow-xs"
              >
                Start Trial
              </button>
            </div>
          </div>
        </div>

        {/* Card 2: Starter */}
        <div className="bg-white border border-[#A7F3D0] rounded-2xl p-4 space-y-3 shadow-xs">
          {/* Header Row */}
          <div className="flex items-start justify-between">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-[#D1FAE5] text-[#059669] flex items-center justify-center flex-shrink-0">
                <Rocket className="w-5 h-5 text-emerald-600" />
              </div>
              <div>
                <div className="flex items-center gap-2">
                  <h3 className="text-base font-extrabold text-slate-900">Starter</h3>
                  <span className="px-2 py-0.5 rounded-lg bg-emerald-100 text-emerald-800 text-[10px] font-bold">
                    4 Months
                  </span>
                </div>
                <p className="text-[11px] text-slate-500 font-medium">Short-term plan for focused preparation.</p>
              </div>
            </div>
            <ChevronRight className="w-5 h-5 text-slate-400 mt-1" />
          </div>

          {/* Grid Content: Price + Features List + CTA */}
          <div className="grid grid-cols-12 gap-2 items-center pt-1">
            {/* Price */}
            <div className="col-span-3">
              <span className="text-2xl font-black text-[#059669] block">₹249</span>
              <span className="text-[10px] font-bold text-slate-500 block">4 Months</span>
            </div>

            {/* 2-Column Feature List */}
            <div className="col-span-6 grid grid-cols-2 gap-x-2 gap-y-1 text-[10px] font-bold text-slate-700">
              <div className="flex items-center gap-1">
                <span className="text-[#059669]">✓</span>
                <span className="truncate">Unlimited question practice</span>
              </div>
              <div className="flex items-center gap-1">
                <span className="text-[#059669]">✓</span>
                <span className="truncate">Basic analytics</span>
              </div>
              <div className="flex items-center gap-1">
                <span className="text-[#059669]">✓</span>
                <span className="truncate">NCERT + NTA + PYQs</span>
              </div>
              <div className="flex items-center gap-1">
                <span className="text-[#059669]">✓</span>
                <span className="truncate">Mistake book</span>
              </div>
              <div className="flex items-center gap-1">
                <span className="text-[#059669]">✓</span>
                <span className="truncate">Custom practice</span>
              </div>
              <div className="flex items-center gap-1">
                <span className="text-[#059669]">✓</span>
                <span className="truncate">Paper prediction</span>
              </div>
              <div className="flex items-center gap-1">
                <span className="text-[#059669]">✓</span>
                <span className="truncate">10 Mock Tests / Month</span>
              </div>
              <div className="flex items-center gap-1">
                <span className="text-[#059669]">✓</span>
                <span className="truncate">Streaks & Achievements</span>
              </div>
            </div>

            {/* Action Button */}
            <div className="col-span-3 text-right">
              <button
                onClick={() => handleChoosePlan('starter')}
                className="px-3 py-2 rounded-xl border border-[#34D399] text-[#059669] bg-white font-extrabold text-xs hover:bg-emerald-50 transition-colors shadow-xs"
              >
                Choose Plan
              </button>
            </div>
          </div>
        </div>

        {/* Card 3: Pro (HIGHLIGHTED MOST POPULAR) */}
        <div className="bg-white border-2 border-[#4F46E5] rounded-2xl p-4 space-y-3 shadow-md relative overflow-hidden">
          {/* Top Right Ribbon */}
          <div className="absolute top-0 right-0 bg-[#4F46E5] text-white text-[9px] font-black uppercase px-2.5 py-0.5 rounded-bl-xl shadow-xs">
            MOST POPULAR
          </div>

          {/* Header Row */}
          <div className="flex items-start justify-between">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-[#EDE9FE] text-[#4F46E5] flex items-center justify-center flex-shrink-0">
                <Crown className="w-5 h-5 text-[#4F46E5]" />
              </div>
              <div>
                <div className="flex items-center gap-2">
                  <h3 className="text-base font-extrabold text-slate-900">Pro</h3>
                  <span className="px-2 py-0.5 rounded-lg bg-purple-100 text-purple-800 text-[10px] font-bold">
                    8 Months
                  </span>
                </div>
                <p className="text-[11px] text-slate-500 font-medium">Best for serious NEET & JEE preparation.</p>
              </div>
            </div>
            <ChevronRight className="w-5 h-5 text-slate-400 mt-1" />
          </div>

          {/* Grid Content: Price + Features List + CTA */}
          <div className="grid grid-cols-12 gap-2 items-center pt-1">
            {/* Price */}
            <div className="col-span-3">
              <span className="text-2xl font-black text-[#4F46E5] block">₹449</span>
              <span className="text-[10px] font-bold text-slate-500 block">8 Months</span>
            </div>

            {/* 2-Column Feature List */}
            <div className="col-span-6 grid grid-cols-2 gap-x-2 gap-y-1 text-[10px] font-bold text-slate-700">
              <div className="flex items-center gap-1">
                <span className="text-[#4F46E5]">✓</span>
                <span className="truncate">Everything in Starter</span>
              </div>
              <div className="flex items-center gap-1">
                <span className="text-[#4F46E5]">✓</span>
                <span className="truncate">Paper prediction (Advanced)</span>
              </div>
              <div className="flex items-center gap-1">
                <span className="text-[#4F46E5]">✓</span>
                <span className="truncate">Unlimited mock tests</span>
              </div>
              <div className="flex items-center gap-1">
                <span className="text-[#4F46E5]">✓</span>
                <span className="truncate">Performance insights</span>
              </div>
              <div className="flex items-center gap-1">
                <span className="text-[#4F46E5]">✓</span>
                <span className="truncate">Advanced analytics</span>
              </div>
              <div className="flex items-center gap-1">
                <span className="text-[#4F46E5]">✓</span>
                <span className="truncate">Ad-free experience</span>
              </div>
              <div className="flex items-center gap-1">
                <span className="text-[#4F46E5]">✓</span>
                <span className="truncate">Weak topic detection</span>
              </div>
              <div className="flex items-center gap-1">
                <span className="text-[#4F46E5]">✓</span>
                <span className="truncate">Advanced leaderboard</span>
              </div>
              <div className="flex items-center gap-1">
                <span className="text-[#4F46E5]">✓</span>
                <span className="truncate">Personalized practice</span>
              </div>
            </div>

            {/* Action Button */}
            <div className="col-span-3 text-right">
              <button
                onClick={() => handleChoosePlan('pro')}
                className="px-3 py-2 rounded-xl bg-[#4F46E5] hover:bg-[#4338CA] text-white font-extrabold text-xs shadow-md shadow-indigo-600/30 transition-colors"
              >
                Choose Plan
              </button>
            </div>
          </div>
        </div>

        {/* Card 4: Ultimate */}
        <div className="bg-white border border-[#BFDBFE] rounded-2xl p-4 space-y-3 shadow-xs">
          {/* Header Row */}
          <div className="flex items-start justify-between">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-[#DBEAFE] text-[#2563EB] flex items-center justify-center flex-shrink-0">
                <Gem className="w-5 h-5 text-blue-600" />
              </div>
              <div>
                <div className="flex items-center gap-2">
                  <h3 className="text-base font-extrabold text-slate-900">Ultimate</h3>
                  <span className="px-2 py-0.5 rounded-lg bg-blue-100 text-blue-800 text-[10px] font-bold">
                    1 Year
                  </span>
                </div>
                <p className="text-[11px] text-slate-500 font-medium">Complete preparation with AI-powered features.</p>
              </div>
            </div>
            <ChevronRight className="w-5 h-5 text-slate-400 mt-1" />
          </div>

          {/* Grid Content: Price + Features List + CTA */}
          <div className="grid grid-cols-12 gap-2 items-center pt-1">
            {/* Price */}
            <div className="col-span-3">
              <span className="text-2xl font-black text-[#2563EB] block">₹689</span>
              <span className="text-[10px] font-bold text-slate-500 block">1 Year</span>
            </div>

            {/* 2-Column Feature List */}
            <div className="col-span-6 grid grid-cols-2 gap-x-2 gap-y-1 text-[10px] font-bold text-slate-700">
              <div className="flex items-center gap-1">
                <span className="text-[#2563EB]">✓</span>
                <span className="truncate">Everything in Pro</span>
              </div>
              <div className="flex items-center gap-1">
                <span className="text-[#2563EB]">✓</span>
                <span className="truncate">Advanced paper prediction</span>
              </div>
              <div className="flex items-center gap-1">
                <span className="text-[#2563EB]">✓</span>
                <span className="truncate">AI Tutor & Explanations</span>
              </div>
              <div className="flex items-center gap-1">
                <span className="text-[#2563EB]">✓</span>
                <span className="truncate">Complete analytics</span>
              </div>
              <div className="flex items-center gap-1">
                <span className="text-[#2563EB]">✓</span>
                <span className="truncate">Adaptive practice</span>
              </div>
              <div className="flex items-center gap-1">
                <span className="text-[#2563EB]">✓</span>
                <span className="truncate">Priority support</span>
              </div>
              <div className="flex items-center gap-1">
                <span className="text-[#2563EB]">✓</span>
                <span className="truncate">AI weakness analysis</span>
              </div>
              <div className="flex items-center gap-1">
                <span className="text-[#2563EB]">✓</span>
                <span className="truncate">Early access to new features</span>
              </div>
              <div className="flex items-center gap-1">
                <span className="text-[#2563EB]">✓</span>
                <span className="truncate">Smart revision</span>
              </div>
            </div>

            {/* Action Button */}
            <div className="col-span-3 text-right">
              <button
                onClick={() => handleChoosePlan('ultimate')}
                className="px-3 py-2 rounded-xl border border-[#60A5FA] text-[#2563EB] bg-white font-extrabold text-xs hover:bg-blue-50 transition-colors shadow-xs"
              >
                Choose Plan
              </button>
            </div>
          </div>
        </div>

      </div>

      {/* ========================================================================= */}
      {/* 4. BOTTOM TRUST & SECURITY FOOTER BAR */}
      {/* ========================================================================= */}
      <div className="px-4 space-y-3">
        <div className="bg-white border border-slate-200/80 rounded-2xl p-3 shadow-xs grid grid-cols-4 gap-1 text-center">
          
          <div className="flex flex-col items-center space-y-1">
            <div className="w-8 h-8 rounded-xl bg-indigo-50 text-[#4F46E5] flex items-center justify-center">
              <ShieldCheck className="w-4 h-4" />
            </div>
            <span className="text-[9px] font-extrabold text-slate-700 leading-tight">
              Trusted by<br /><span className="text-[8px] text-slate-500 font-semibold">1M+ Students</span>
            </span>
          </div>

          <div className="flex flex-col items-center space-y-1 border-l border-slate-100">
            <div className="w-8 h-8 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center">
              <Lock className="w-4 h-4" />
            </div>
            <span className="text-[9px] font-extrabold text-slate-700 leading-tight">
              100% Secure<br /><span className="text-[8px] text-slate-500 font-semibold">Payments</span>
            </span>
          </div>

          <div className="flex flex-col items-center space-y-1 border-l border-slate-100">
            <div className="w-8 h-8 rounded-xl bg-rose-50 text-rose-500 flex items-center justify-center">
              <RotateCcw className="w-4 h-4" />
            </div>
            <span className="text-[9px] font-extrabold text-slate-700 leading-tight">
              Cancel Anytime<br /><span className="text-[8px] text-slate-500 font-semibold">No Questions Asked</span>
            </span>
          </div>

          <div className="flex flex-col items-center space-y-1 border-l border-slate-100">
            <div className="w-8 h-8 rounded-xl bg-amber-50 text-amber-600 flex items-center justify-center">
              <Headphones className="w-4 h-4" />
            </div>
            <span className="text-[9px] font-extrabold text-slate-700 leading-tight">
              24/7 Support<br /><span className="text-[8px] text-slate-500 font-semibold">We're here to help</span>
            </span>
          </div>

        </div>

        {/* Security Sub-text */}
        <div className="flex items-center justify-center gap-1.5 text-[10px] text-slate-500 font-semibold text-center">
          <ShieldCheck className="w-3.5 h-3.5 text-[#4F46E5]" />
          <span>Your progress & data is always safe with us.</span>
        </div>
      </div>

    </div>
  );
};
