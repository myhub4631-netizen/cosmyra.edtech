import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  ArrowLeft,
  ShieldCheck,
  Crown,
  Check,
  Ticket,
  Lock,
  ArrowRight,
  Wallet,
  Banknote,
  CreditCard,
  GraduationCap,
} from 'lucide-react';

interface MobilePaymentScreenProps {
  onBack?: () => void;
  isMobileFrame?: boolean;
}

export const MobilePaymentScreen: React.FC<MobilePaymentScreenProps> = ({
  onBack,
  isMobileFrame = false,
}) => {
  const navigate = useNavigate();

  // Payment Selection State
  const [selectedMethod, setSelectedMethod] = useState<string>('upi');
  const [couponCode, setCouponCode] = useState<string>('');
  const [isCouponApplied, setIsCouponApplied] = useState<boolean>(false);
  const [isProcessing, setIsProcessing] = useState<boolean>(false);
  const [isSuccess, setIsSuccess] = useState<boolean>(false);

  const handleBack = () => {
    if (onBack) onBack();
    else navigate(-1);
  };

  const handlePayment = () => {
    setIsProcessing(true);
    setTimeout(() => {
      setIsProcessing(false);
      setIsSuccess(true);
    }, 1500);
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

        {/* Brand Logo & Tagline */}
        <div className="flex items-center gap-2">
          <div className="w-7 h-7 rounded-xl bg-[#5D3EED] flex items-center justify-center text-white shadow-sm">
            <GraduationCap className="w-4 h-4 stroke-[2]" />
          </div>
          <div className="leading-tight">
            <h1 className="text-xs font-extrabold text-slate-900 leading-none">ExamPrep</h1>
            <span className="text-[8px] text-slate-400 font-semibold block mt-0.5">Practice • Analyze • Succeed</span>
          </div>
        </div>

        {/* 100% Secure Badge */}
        <div className="flex items-center gap-1 text-[#5D3EED] text-[10px] font-extrabold">
          <ShieldCheck className="w-3.5 h-3.5 text-[#5D3EED]" />
          <div className="leading-tight">
            <span className="block">100% Secure</span>
            <span className="block text-[8px] text-slate-400">Payment</span>
          </div>
        </div>
      </div>

      {/* ========================================================================= */}
      {/* 2. HEADLINE & SUBTITLE */}
      {/* ========================================================================= */}
      <div className="pt-4 pb-2 px-4 space-y-1">
        <h2 className="text-xl font-extrabold text-slate-900 tracking-tight">
          Complete Your Purchase
        </h2>
        <p className="text-xs text-slate-500 font-medium">
          Unlock premium features and take your preparation to the next level
        </p>
      </div>

      {/* ========================================================================= */}
      {/* 3. SELECTED PLAN SUMMARY CARD (PRO PLAN) */}
      {/* ========================================================================= */}
      <div className="p-4 space-y-4">
        <div className="bg-[#F8F7FF] border border-purple-200/80 rounded-3xl p-4 space-y-3 shadow-xs">
          
          {/* Header Row */}
          <div className="flex items-start justify-between">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-purple-100 text-[#5D3EED] flex items-center justify-center flex-shrink-0">
                <Crown className="w-5 h-5 text-[#5D3EED]" />
              </div>
              <div>
                <div className="flex items-center gap-2">
                  <h3 className="text-base font-extrabold text-slate-900">Pro Plan</h3>
                  <span className="px-2 py-0.5 rounded-lg bg-purple-100 text-purple-800 text-[10px] font-bold">
                    8 Months
                  </span>
                </div>
                <p className="text-xs text-slate-500 font-medium">Best for serious NEET & JEE preparation</p>
              </div>
            </div>

            <div className="text-right">
              <div className="flex items-baseline justify-end gap-1">
                <span className="text-xl font-black text-[#5D3EED]">₹449</span>
                <span className="text-xs text-slate-400 line-through font-semibold">₹799</span>
              </div>
              <span className="px-2 py-0.5 rounded-full bg-[#5D3EED] text-white font-extrabold text-[10px] inline-block mt-0.5">
                44% OFF
              </span>
            </div>
          </div>

          {/* Included Features 2-Column Grid */}
          <div className="grid grid-cols-2 gap-x-2 gap-y-1.5 pt-1 text-[11px] font-bold text-slate-700">
            <div className="flex items-center gap-1.5">
              <span className="text-[#5D3EED]">✓</span>
              <span className="truncate">Everything in Starter</span>
            </div>
            <div className="flex items-center gap-1.5">
              <span className="text-[#5D3EED]">✓</span>
              <span className="truncate">Paper Predictions</span>
            </div>

            <div className="flex items-center gap-1.5">
              <span className="text-[#5D3EED]">✓</span>
              <span className="truncate">Unlimited Practice Questions</span>
            </div>
            <div className="flex items-center gap-1.5">
              <span className="text-[#5D3EED]">✓</span>
              <span className="truncate">Previous Year Questions (All Years)</span>
            </div>

            <div className="flex items-center gap-1.5">
              <span className="text-[#5D3EED]">✓</span>
              <span className="truncate">Advanced Performance Analytics</span>
            </div>
            <div className="flex items-center gap-1.5">
              <span className="text-[#5D3EED]">✓</span>
              <span className="truncate">Ad-free Experience</span>
            </div>

            <div className="flex items-center gap-1.5">
              <span className="text-[#5D3EED]">✓</span>
              <span className="truncate">Weak Topic Finder</span>
            </div>
            <div className="flex items-center gap-1.5">
              <span className="text-[#5D3EED]">✓</span>
              <span className="truncate">Priority Customer Support</span>
            </div>

            <div className="flex items-center gap-1.5">
              <span className="text-[#5D3EED]">✓</span>
              <span className="truncate">Personalized Study Plan</span>
            </div>
            <div className="flex items-center gap-1.5">
              <span className="text-[#5D3EED]">✓</span>
              <span className="truncate">Access on All Your Devices</span>
            </div>
          </div>
        </div>

        {/* ========================================================================= */}
        {/* 4. SELECT PAYMENT METHOD */}
        {/* ========================================================================= */}
        <div className="space-y-2.5">
          <div className="flex items-center justify-between">
            <h3 className="text-sm font-extrabold text-slate-900">Select Payment Method</h3>
            <span className="text-[11px] text-slate-500 font-medium">Choose your preferred payment option</span>
          </div>

          <div className="space-y-2">
            {/* 1. UPI */}
            <div
              onClick={() => setSelectedMethod('upi')}
              className={`p-3.5 rounded-2xl border transition-all cursor-pointer flex items-center justify-between ${
                selectedMethod === 'upi'
                  ? 'bg-[#F5F3FF] border-2 border-[#5D3EED] shadow-xs'
                  : 'bg-white border-slate-200 hover:border-slate-300'
              }`}
            >
              <div className="flex items-center gap-3">
                <div className="w-9 h-9 rounded-xl bg-slate-50 border border-slate-200 flex items-center justify-center font-bold text-xs">
                  <span className="text-emerald-600 font-black">▲</span>
                  <span className="text-orange-500 font-black">▼</span>
                </div>
                <div>
                  <h4 className="text-xs font-extrabold text-slate-900">UPI</h4>
                  <p className="text-[11px] text-slate-500 font-medium">Pay instantly with any UPI app</p>
                </div>
              </div>

              <div
                className={`w-5 h-5 rounded-full border-2 flex items-center justify-center ${
                  selectedMethod === 'upi' ? 'border-[#5D3EED] bg-[#5D3EED]' : 'border-slate-300'
                }`}
              >
                {selectedMethod === 'upi' && <div className="w-2 h-2 rounded-full bg-white" />}
              </div>
            </div>

            {/* 2. Cashfree PG */}
            <div
              onClick={() => setSelectedMethod('cashfree')}
              className={`p-3.5 rounded-2xl border transition-all cursor-pointer flex items-center justify-between ${
                selectedMethod === 'cashfree'
                  ? 'bg-[#F5F3FF] border-2 border-[#5D3EED] shadow-xs'
                  : 'bg-white border-slate-200 hover:border-slate-300'
              }`}
            >
              <div className="flex items-center gap-3">
                <div className="w-9 h-9 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center font-black text-sm">
                  CF
                </div>
                <div>
                  <h4 className="text-xs font-extrabold text-slate-900">Cashfree PG</h4>
                  <p className="text-[11px] text-slate-500 font-medium">Secure payment via Cashfree</p>
                </div>
              </div>

              <div
                className={`w-5 h-5 rounded-full border-2 flex items-center justify-center ${
                  selectedMethod === 'cashfree' ? 'border-[#5D3EED] bg-[#5D3EED]' : 'border-slate-300'
                }`}
              >
                {selectedMethod === 'cashfree' && <div className="w-2 h-2 rounded-full bg-white" />}
              </div>
            </div>

            {/* 3. Razorpay PG */}
            <div
              onClick={() => setSelectedMethod('razorpay')}
              className={`p-3.5 rounded-2xl border transition-all cursor-pointer flex items-center justify-between ${
                selectedMethod === 'razorpay'
                  ? 'bg-[#F5F3FF] border-2 border-[#5D3EED] shadow-xs'
                  : 'bg-white border-slate-200 hover:border-slate-300'
              }`}
            >
              <div className="flex items-center gap-3">
                <div className="w-9 h-9 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center font-black text-sm">
                  R
                </div>
                <div>
                  <h4 className="text-xs font-extrabold text-slate-900">Razorpay PG</h4>
                  <p className="text-[11px] text-slate-500 font-medium">Secure payment via Razorpay</p>
                </div>
              </div>

              <div
                className={`w-5 h-5 rounded-full border-2 flex items-center justify-center ${
                  selectedMethod === 'razorpay' ? 'border-[#5D3EED] bg-[#5D3EED]' : 'border-slate-300'
                }`}
              >
                {selectedMethod === 'razorpay' && <div className="w-2 h-2 rounded-full bg-white" />}
              </div>
            </div>

            {/* 4. Wallet */}
            <div
              onClick={() => setSelectedMethod('wallet')}
              className={`p-3.5 rounded-2xl border transition-all cursor-pointer flex items-center justify-between ${
                selectedMethod === 'wallet'
                  ? 'bg-[#F5F3FF] border-2 border-[#5D3EED] shadow-xs'
                  : 'bg-white border-slate-200 hover:border-slate-300'
              }`}
            >
              <div className="flex items-center gap-3">
                <div className="w-9 h-9 rounded-xl bg-purple-50 text-purple-600 flex items-center justify-center">
                  <Wallet className="w-5 h-5" />
                </div>
                <div>
                  <h4 className="text-xs font-extrabold text-slate-900">Wallet</h4>
                  <p className="text-[11px] text-slate-500 font-medium">Pay using your wallet balance</p>
                </div>
              </div>

              <div
                className={`w-5 h-5 rounded-full border-2 flex items-center justify-center ${
                  selectedMethod === 'wallet' ? 'border-[#5D3EED] bg-[#5D3EED]' : 'border-slate-300'
                }`}
              >
                {selectedMethod === 'wallet' && <div className="w-2 h-2 rounded-full bg-white" />}
              </div>
            </div>

            {/* 5. COD */}
            <div
              onClick={() => setSelectedMethod('cod')}
              className={`p-3.5 rounded-2xl border transition-all cursor-pointer flex items-center justify-between ${
                selectedMethod === 'cod'
                  ? 'bg-[#F5F3FF] border-2 border-[#5D3EED] shadow-xs'
                  : 'bg-white border-slate-200 hover:border-slate-300'
              }`}
            >
              <div className="flex items-center gap-3">
                <div className="w-9 h-9 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center">
                  <Banknote className="w-5 h-5" />
                </div>
                <div>
                  <h4 className="text-xs font-extrabold text-slate-900">COD (Cash on Delivery)</h4>
                  <p className="text-[11px] text-slate-500 font-medium">Pay when you receive the order</p>
                </div>
              </div>

              <div
                className={`w-5 h-5 rounded-full border-2 flex items-center justify-center ${
                  selectedMethod === 'cod' ? 'border-[#5D3EED] bg-[#5D3EED]' : 'border-slate-300'
                }`}
              >
                {selectedMethod === 'cod' && <div className="w-2 h-2 rounded-full bg-white" />}
              </div>
            </div>
          </div>
        </div>

        {/* ========================================================================= */}
        {/* 5. APPLY COUPON CARD */}
        {/* ========================================================================= */}
        <div className="bg-[#FFFBF5] border border-[#FDE68A] rounded-2xl p-3.5 flex items-center justify-between shadow-xs">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-xl bg-amber-100 text-[#D97706] flex items-center justify-center flex-shrink-0">
              <Ticket className="w-5 h-5" />
            </div>
            <div>
              <h4 className="text-xs font-extrabold text-slate-900">Apply Coupon</h4>
              <p className="text-[11px] text-slate-500 font-medium">Get extra discount on this plan</p>
            </div>
          </div>

          <button
            onClick={() => setIsCouponApplied(!isCouponApplied)}
            className={`px-3.5 py-1.5 rounded-xl font-extrabold text-xs transition-colors ${
              isCouponApplied
                ? 'bg-amber-500 text-white'
                : 'border border-[#FCD34D] text-[#D97706] bg-white hover:bg-amber-50'
            }`}
          >
            {isCouponApplied ? 'Applied ✓' : 'Apply'}
          </button>
        </div>

        {/* ========================================================================= */}
        {/* 6. ORDER SUMMARY CARD */}
        {/* ========================================================================= */}
        <div className="bg-white border border-slate-200/80 rounded-2xl p-4 space-y-2.5 shadow-xs">
          <div className="flex items-center justify-between">
            <h3 className="text-xs font-extrabold text-slate-900">Order Summary</h3>
            <span className="text-[10px] text-slate-400 font-bold flex items-center gap-1">
              <Lock className="w-3 h-3" />
              <span>Secure Payment</span>
            </span>
          </div>

          <div className="space-y-1.5 text-xs font-semibold text-slate-600">
            <div className="flex items-center justify-between">
              <span>Pro Plan (8 Months)</span>
              <span className="font-extrabold text-slate-900">₹799</span>
            </div>

            <div className="flex items-center justify-between">
              <span className="text-emerald-600 font-bold">Discount (44% OFF)</span>
              <span className="font-extrabold text-emerald-600">- ₹350</span>
            </div>
          </div>

          <div className="border-b border-slate-100" />

          <div className="flex items-center justify-between pt-0.5">
            <span className="text-xs font-extrabold text-slate-900">Total Amount</span>
            <span className="text-lg font-black text-slate-900">₹449</span>
          </div>
        </div>

        {/* ========================================================================= */}
        {/* 7. PRIMARY ACTION BUTTON */}
        {/* ========================================================================= */}
        {isSuccess ? (
          <div className="p-4 rounded-2xl bg-emerald-50 border border-emerald-200 text-center space-y-2">
            <div className="w-10 h-10 rounded-full bg-emerald-500 text-white flex items-center justify-center mx-auto">
              <Check className="w-6 h-6 stroke-[3]" />
            </div>
            <h4 className="text-sm font-extrabold text-emerald-800">Payment Successful!</h4>
            <p className="text-xs text-emerald-700 font-medium">Pro Plan has been activated on your account.</p>
            <button
              onClick={handleBack}
              className="mt-2 px-4 py-2 bg-emerald-600 text-white font-extrabold text-xs rounded-xl"
            >
              Back to Dashboard
            </button>
          </div>
        ) : (
          <button
            onClick={handlePayment}
            disabled={isProcessing}
            className="w-full py-4 rounded-2xl bg-[#5D3EED] hover:bg-[#4338CA] text-white font-black text-sm shadow-xl shadow-indigo-600/30 flex items-center justify-center gap-2 transition-all disabled:opacity-75"
          >
            <Lock className="w-4 h-4 stroke-[2.5]" />
            <span>{isProcessing ? 'Processing Payment...' : 'Pay ₹449 Now'}</span>
            <ArrowRight className="w-4 h-4 stroke-[3]" />
          </button>
        )}

      </div>

    </div>
  );
};
