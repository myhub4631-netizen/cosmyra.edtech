import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Sparkles,
  ChevronDown,
  Check,
  Star,
  Rocket,
  Crown,
  Gem,
  ShieldCheck,
  CheckCircle2,
  RotateCcw,
  Award,
  Lock,
  ArrowRight,
  GraduationCap,
} from 'lucide-react';

export const PricingPage: React.FC = () => {
  const navigate = useNavigate();
  const [selectedExamDropdown, setSelectedExamDropdown] = useState<boolean>(false);

  const pricingPlans = [
    {
      id: 'trial',
      name: 'Trial Pass',
      subtitle: 'Try Cosmyra for 30 days',
      price: '99',
      duration: '1 Month',
      theme: 'amber',
      icon: Star,
      iconBg: 'bg-[#FEF3C7] text-[#D97706]',
      cardBg: 'bg-[#FFFDF5] border-[#FDE68A]',
      buttonStyle: 'border border-[#FCD34D] text-[#D97706] bg-white hover:bg-amber-50',
      buttonText: 'Start 30-Day Trial',
      checkColor: 'text-[#D97706] bg-amber-100',
      features: [
        'Core Question Practice',
        'Instant Feedback',
        'Detailed Solutions',
        '5 Mock Tests',
        'Paper Prediction',
      ],
    },
    {
      id: 'starter',
      name: 'Starter',
      subtitle: 'Short-term preparation',
      price: '249',
      duration: '4 Months',
      theme: 'emerald',
      icon: Rocket,
      iconBg: 'bg-[#D1FAE5] text-[#059669]',
      cardBg: 'bg-white border-[#A7F3D0]',
      buttonStyle: 'border border-[#34D399] text-[#059669] bg-white hover:bg-emerald-50',
      buttonText: 'Get Starter',
      checkColor: 'text-[#059669] bg-emerald-100',
      features: [
        'Unlimited Question Practice',
        'NCERT + NTA + PYQs',
        'Custom Practice',
        '10 Mock Tests / Month',
        'Basic Analytics',
        'Paper Prediction',
      ],
    },
    {
      id: 'pro',
      name: 'Pro',
      subtitle: 'Serious preparation',
      price: '449',
      duration: '8 Months',
      isPopular: true,
      popularTag: 'MOST POPULAR',
      theme: 'purple',
      icon: Crown,
      iconBg: 'bg-[#EDE9FE] text-[#5D3EED]',
      cardBg: 'bg-white border-2 border-[#5D3EED] shadow-2xl shadow-indigo-500/20 relative scale-[1.02]',
      buttonStyle: 'bg-[#5D3EED] text-white hover:bg-[#4F46E5] shadow-lg shadow-indigo-500/30',
      buttonText: 'Get Pro',
      checkColor: 'text-[#5D3EED] bg-purple-100',
      features: [
        'Everything in Starter',
        'Unlimited Mock Tests',
        'Advanced Analytics',
        'Weak Topic Detection',
        'Personalized Practice',
        'Paper Prediction (Advanced)',
        'Ad-free Experience',
      ],
    },
    {
      id: 'ultimate',
      name: 'Ultimate',
      subtitle: 'Complete-year preparation',
      price: '689',
      duration: '1 Year',
      theme: 'blue',
      icon: Gem,
      iconBg: 'bg-[#DBEAFE] text-[#2563EB]',
      cardBg: 'bg-white border-[#BFDBFE]',
      buttonStyle: 'border border-[#60A5FA] text-[#2563EB] bg-white hover:bg-blue-50',
      buttonText: 'Go Ultimate',
      checkColor: 'text-[#2563EB] bg-blue-100',
      features: [
        'Everything in Pro',
        'AI Tutor & AI Explanations',
        'Adaptive Practice',
        'Advanced Paper Prediction',
        'Complete Analytics',
        'Smart Revision',
        'Priority Support',
        'Ad-free Experience',
      ],
    },
  ];

  return (
    <div className="min-h-screen bg-[#FDFDFF] text-slate-900 font-sans select-none pb-20">
      
      {/* ========================================================================= */}
      {/* 1. TOP NAVBAR */}
      {/* ========================================================================= */}
      <header className="sticky top-0 z-40 bg-white/90 backdrop-blur-md border-b border-slate-100 px-4 lg:px-12 py-3.5 flex items-center justify-between">
        {/* Brand Logo */}
        <div
          onClick={() => navigate('/')}
          className="flex items-center gap-3 cursor-pointer group"
        >
          <div className="w-10 h-10 rounded-2xl bg-indigo-50 border border-indigo-200 flex items-center justify-center text-[#5D3EED] shadow-sm group-hover:scale-105 transition-transform">
            <GraduationCap className="w-6 h-6 stroke-[2]" />
          </div>
          <div>
            <h1 className="text-xl font-extrabold text-[#5D3EED] tracking-tight leading-none">
              Cosmyra
            </h1>
            <span className="text-[9px] tracking-wider text-slate-400 font-bold uppercase block mt-0.5">
              NEET • JEE • Foundation
            </span>
          </div>
        </div>

        {/* Center Navigation Links */}
        <nav className="hidden md:flex items-center gap-6 lg:gap-8 text-xs font-bold text-slate-600">
          <button onClick={() => navigate('/')} className="hover:text-[#5D3EED] transition-colors">
            Home
          </button>
          <button onClick={() => navigate('/')} className="hover:text-[#5D3EED] transition-colors">
            Features
          </button>
          
          {/* Exams Dropdown */}
          <div className="relative">
            <button
              onClick={() => setSelectedExamDropdown(!selectedExamDropdown)}
              className="flex items-center gap-1 hover:text-[#5D3EED] transition-colors"
            >
              <span>Exams</span>
              <ChevronDown className="w-3.5 h-3.5 stroke-[2.5]" />
            </button>
          </div>

          <button onClick={() => navigate('/pyq')} className="hover:text-[#5D3EED] transition-colors">
            Paper Prediction
          </button>
          
          <button className="text-[#5D3EED] font-extrabold border-b-2 border-[#5D3EED] pb-0.5">
            Pricing
          </button>

          <button onClick={() => navigate('/')} className="hover:text-[#5D3EED] transition-colors">
            Blog
          </button>

          <button onClick={() => navigate('/')} className="hover:text-[#5D3EED] transition-colors">
            About Us
          </button>
        </nav>

        {/* Right Action Buttons */}
        <div className="flex items-center gap-3">
          <button
            onClick={() => navigate('/student')}
            className="px-4 py-2 rounded-xl border border-slate-200 text-slate-800 font-bold text-xs hover:bg-slate-50 transition-colors"
          >
            Login
          </button>
          <button
            onClick={() => navigate('/student')}
            className="px-5 py-2 rounded-xl bg-[#5D3EED] hover:bg-[#4F46E5] text-white font-extrabold text-xs shadow-md shadow-indigo-600/20 transition-all"
          >
            Sign Up
          </button>
        </div>
      </header>

      {/* ========================================================================= */}
      {/* 2. HERO HEADER SECTION */}
      {/* ========================================================================= */}
      <section className="pt-12 pb-8 px-4 text-center max-w-4xl mx-auto space-y-4">
        {/* Top Tagline Pill */}
        <div className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-[#F3F0FF] border border-purple-200/60 text-[#5D3EED] text-xs font-extrabold shadow-sm">
          <span>Simple Plans. Powerful Preparation.</span>
        </div>

        {/* Main Headline */}
        <h1 className="text-3xl sm:text-4xl lg:text-5xl font-black text-[#0F172A] tracking-tight leading-tight">
          Choose the Plan That <br className="hidden sm:block" />
          Matches <span className="text-[#5D3EED]">Your Preparation</span>
        </h1>

        {/* Subtitle */}
        <p className="text-slate-500 text-sm sm:text-base font-medium max-w-xl mx-auto">
          Practice more, analyze better and improve faster with Cosmyra.
        </p>

        {/* Access Badge */}
        <div className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-[#F1F5F9] border border-slate-200 text-[#475569] text-xs font-extrabold mt-2">
          <div className="w-4 h-4 rounded-full bg-[#5D3EED] text-white flex items-center justify-center text-[10px]">
            ✓
          </div>
          <span>All plans include Web + Mobile Access</span>
        </div>
      </section>

      {/* ========================================================================= */}
      {/* 3. 4 PRICING CARDS GRID */}
      {/* ========================================================================= */}
      <section className="max-w-7xl mx-auto px-4 lg:px-8 py-6">
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 items-stretch">
          {pricingPlans.map((plan) => {
            const Icon = plan.icon;

            return (
              <div
                key={plan.id}
                className={`rounded-3xl p-6 flex flex-col justify-between transition-all duration-200 ${plan.cardBg}`}
              >
                {/* Popular Tag Ribbon */}
                {plan.isPopular && (
                  <div className="absolute -top-3.5 left-1/2 -translate-x-1/2 bg-[#5D3EED] text-white text-[11px] font-black uppercase px-3.5 py-1 rounded-full shadow-md flex items-center gap-1 tracking-wider">
                    <span>★</span>
                    <span>{plan.popularTag}</span>
                  </div>
                )}

                <div className="space-y-5">
                  {/* Icon & Title */}
                  <div className="flex items-center gap-3">
                    <div className={`w-12 h-12 rounded-2xl flex items-center justify-center flex-shrink-0 ${plan.iconBg}`}>
                      <Icon className="w-6 h-6 stroke-[2]" />
                    </div>
                    <div>
                      <h3 className="text-lg font-extrabold text-[#0F172A]">{plan.name}</h3>
                      <p className="text-xs text-slate-500 font-medium">{plan.subtitle}</p>
                    </div>
                  </div>

                  {/* Price */}
                  <div>
                    <div className="flex items-baseline gap-1">
                      <span className="text-4xl font-black text-[#0F172A]">₹{plan.price}</span>
                    </div>
                    <span className="text-xs font-semibold text-slate-500 block mt-0.5">{plan.duration}</span>
                  </div>

                  <div className="border-b border-slate-100" />

                  {/* Features List */}
                  <ul className="space-y-3 text-xs font-bold text-slate-700">
                    {plan.features.map((feature, idx) => (
                      <li key={idx} className="flex items-center gap-2.5">
                        <div className={`w-4 h-4 rounded-full flex items-center justify-center text-[10px] font-extrabold flex-shrink-0 ${plan.checkColor}`}>
                          ✓
                        </div>
                        <span>{feature}</span>
                      </li>
                    ))}
                  </ul>
                </div>

                {/* Bottom CTA Button */}
                <div className="pt-6">
                  <button
                    onClick={() => navigate('/student')}
                    className={`w-full py-3.5 rounded-2xl font-extrabold text-xs transition-all ${plan.buttonStyle}`}
                  >
                    {plan.buttonText}
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      </section>

      {/* ========================================================================= */}
      {/* 4. TRUST & SECURITY FOOTER STRIP */}
      {/* ========================================================================= */}
      <section className="max-w-6xl mx-auto px-4 lg:px-8 pt-8">
        <div className="bg-white border border-slate-200/80 rounded-3xl p-6 shadow-sm grid grid-cols-2 md:grid-cols-4 gap-6 divide-y md:divide-y-0 md:divide-x divide-slate-100">
          
          {/* Item 1 */}
          <div className="flex items-center gap-3.5 pt-4 md:pt-0">
            <div className="w-11 h-11 rounded-2xl bg-indigo-50 text-[#5D3EED] border border-indigo-100 flex items-center justify-center flex-shrink-0">
              <ShieldCheck className="w-6 h-6 stroke-[2]" />
            </div>
            <div>
              <span className="text-[11px] text-slate-500 font-bold block leading-tight">Trusted by</span>
              <span className="text-xs font-black text-[#0F172A] block mt-0.5">1M+ Students</span>
            </div>
          </div>

          {/* Item 2 */}
          <div className="flex items-center gap-3.5 pt-4 md:pt-0 md:pl-6">
            <div className="w-11 h-11 rounded-2xl bg-emerald-50 text-emerald-600 border border-emerald-100 flex items-center justify-center flex-shrink-0">
              <CheckCircle2 className="w-6 h-6 stroke-[2]" />
            </div>
            <div>
              <span className="text-[11px] text-slate-500 font-bold block leading-tight">100% Secure</span>
              <span className="text-xs font-black text-[#0F172A] block mt-0.5">Payments</span>
            </div>
          </div>

          {/* Item 3 */}
          <div className="flex items-center gap-3.5 pt-4 md:pt-0 md:pl-6">
            <div className="w-11 h-11 rounded-2xl bg-purple-50 text-purple-600 border border-purple-100 flex items-center justify-center flex-shrink-0">
              <RotateCcw className="w-6 h-6 stroke-[2]" />
            </div>
            <div>
              <span className="text-[11px] text-slate-500 font-bold block leading-tight">Cancel Anytime</span>
              <span className="text-xs font-black text-[#0F172A] block mt-0.5">No Questions Asked</span>
            </div>
          </div>

          {/* Item 4 */}
          <div className="flex items-center gap-3.5 pt-4 md:pt-0 md:pl-6">
            <div className="w-11 h-11 rounded-2xl bg-amber-50 text-amber-600 border border-amber-100 flex items-center justify-center flex-shrink-0">
              <Award className="w-6 h-6 stroke-[2]" />
            </div>
            <div>
              <span className="text-[11px] text-slate-500 font-bold block leading-tight">Used by Top Rankers</span>
              <span className="text-xs font-black text-[#0F172A] block mt-0.5">Across India</span>
            </div>
          </div>

        </div>
      </section>

    </div>
  );
};
