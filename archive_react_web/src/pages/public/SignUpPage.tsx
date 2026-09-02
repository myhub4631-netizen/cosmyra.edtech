import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  GraduationCap,
  ChevronDown,
  User,
  Mail,
  Lock,
  Eye,
  EyeOff,
  Phone,
  BookOpen,
  BarChart3,
  FileText,
  Target,
  Users,
  ShieldCheck,
  Star,
  Headphones,
  Youtube,
  Send,
  Instagram,
  X,
  Check,
} from 'lucide-react';

export const SignUpPage: React.FC = () => {
  const navigate = useNavigate();

  // Form State
  const [fullName, setFullName] = useState<string>('');
  const [email, setEmail] = useState<string>('');
  const [mobile, setMobile] = useState<string>('');
  const [password, setPassword] = useState<string>('');
  const [confirmPassword, setConfirmPassword] = useState<string>('');
  const [showPassword, setShowPassword] = useState<boolean>(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState<boolean>(false);
  const [agreeTerms, setAgreeTerms] = useState<boolean>(true);
  const [selectedExamDropdown, setSelectedExamDropdown] = useState<boolean>(false);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    // Navigate to student dashboard on successful registration demo
    navigate('/app');
  };

  return (
    <div className="min-h-screen bg-[#FDFDFF] text-slate-900 font-sans select-none flex flex-col justify-between">
      
      <div>
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
            
            <button onClick={() => navigate('/pricing')} className="hover:text-[#5D3EED] transition-colors">
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
              onClick={() => navigate('/signup')}
              className="px-5 py-2 rounded-xl bg-[#5D3EED] hover:bg-[#4F46E5] text-white font-extrabold text-xs shadow-md shadow-indigo-600/20 transition-all"
            >
              Sign Up
            </button>
          </div>
        </header>

        {/* ========================================================================= */}
        {/* 2. MAIN HERO SIGNUP SECTION (2-COLUMN GRID) */}
        {/* ========================================================================= */}
        <section className="max-w-7xl mx-auto px-4 lg:px-8 py-10 lg:py-14">
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-10 lg:gap-12 items-center">
            
            {/* Left Column: Value Propositions & Vector Illustration */}
            <div className="lg:col-span-6 space-y-6">
              
              {/* Main Headline */}
              <div className="space-y-3">
                <h1 className="text-3xl sm:text-4xl lg:text-5xl font-black text-[#0F172A] tracking-tight leading-[1.15]">
                  Create your account <br />
                  and start your <br />
                  <span className="text-[#5D3EED]">preparation</span> journey
                </h1>
                <p className="text-slate-500 text-sm font-medium">
                  Join 1M+ students who trust Cosmyra to crack NEET & JEE with confidence.
                </p>
              </div>

              {/* 4 Value Proposition Items */}
              <div className="space-y-4 pt-2">
                
                {/* Item 1 */}
                <div className="flex items-start gap-3.5">
                  <div className="w-10 h-10 rounded-2xl bg-purple-50 text-[#5D3EED] border border-purple-100 flex items-center justify-center flex-shrink-0 mt-0.5">
                    <BookOpen className="w-5 h-5" />
                  </div>
                  <div>
                    <h3 className="text-sm font-extrabold text-[#0F172A]">Unlimited Practice</h3>
                    <p className="text-xs text-slate-500 font-medium leading-relaxed">
                      Practice unlimited questions with instant feedback and detailed solutions.
                    </p>
                  </div>
                </div>

                {/* Item 2 */}
                <div className="flex items-start gap-3.5">
                  <div className="w-10 h-10 rounded-2xl bg-purple-50 text-[#5D3EED] border border-purple-100 flex items-center justify-center flex-shrink-0 mt-0.5">
                    <BarChart3 className="w-5 h-5" />
                  </div>
                  <div>
                    <h3 className="text-sm font-extrabold text-[#0F172A]">Smart Analytics</h3>
                    <p className="text-xs text-slate-500 font-medium leading-relaxed">
                      Analyze your performance and improve your weak areas with advanced insights.
                    </p>
                  </div>
                </div>

                {/* Item 3 */}
                <div className="flex items-start gap-3.5">
                  <div className="w-10 h-10 rounded-2xl bg-purple-50 text-[#5D3EED] border border-purple-100 flex items-center justify-center flex-shrink-0 mt-0.5">
                    <FileText className="w-5 h-5" />
                  </div>
                  <div>
                    <h3 className="text-sm font-extrabold text-[#0F172A]">Paper Prediction</h3>
                    <p className="text-xs text-slate-500 font-medium leading-relaxed">
                      Get daily paper predictions and stay ahead in your preparation.
                    </p>
                  </div>
                </div>

                {/* Item 4 */}
                <div className="flex items-start gap-3.5">
                  <div className="w-10 h-10 rounded-2xl bg-purple-50 text-[#5D3EED] border border-purple-100 flex items-center justify-center flex-shrink-0 mt-0.5">
                    <Target className="w-5 h-5" />
                  </div>
                  <div>
                    <h3 className="text-sm font-extrabold text-[#0F172A]">Achieve Your Goals</h3>
                    <p className="text-xs text-slate-500 font-medium leading-relaxed">
                      Track your progress and achieve your dream rank with Cosmyra.
                    </p>
                  </div>
                </div>

              </div>

              {/* Student Laptop Vector Graphic */}
              <div className="pt-4 flex justify-center">
                <div className="relative max-w-sm w-full">
                  <svg viewBox="0 0 400 240" className="w-full h-auto">
                    {/* Background Soft Glow */}
                    <circle cx="200" cy="120" r="90" fill="#F5F3FF" />
                    
                    {/* Desk Surface */}
                    <ellipse cx="200" cy="210" rx="180" ry="12" fill="#EEF2FF" />

                    {/* Student Avatar Illustration */}
                    {/* Body/Shirt */}
                    <path d="M 90 210 Q 90 160 120 150 L 150 150 Q 180 160 180 210 Z" fill="#4338CA" />
                    {/* Hoodie Details */}
                    <path d="M 120 150 Q 135 170 150 150" fill="none" stroke="#6366F1" strokeWidth="3" />
                    {/* Neck & Head */}
                    <circle cx="135" cy="125" r="20" fill="#FCA5A5" />
                    {/* Hair */}
                    <path d="M 115 125 C 115 105 155 105 155 125 C 145 110 125 110 115 125 Z" fill="#1E1B4B" />

                    {/* Laptop Computer */}
                    {/* Screen Outer */}
                    <rect x="180" y="120" width="130" height="85" rx="8" fill="#1E1B4B" />
                    {/* Display Inner */}
                    <rect x="186" y="126" width="118" height="73" rx="4" fill="#FFFFFF" />
                    {/* Screen Dashboard UI Elements */}
                    <rect x="192" y="132" width="50" height="25" rx="3" fill="#EEF2FF" />
                    <rect x="248" y="132" width="50" height="25" rx="3" fill="#F5F3FF" />
                    <rect x="192" y="162" width="106" height="30" rx="3" fill="#4F46E5" />
                    <circle cx="275" cy="177" r="8" fill="#FFFFFF" opacity="0.3" />
                    {/* Laptop Base */}
                    <polygon points="160,205 330,205 320,212 170,212" fill="#94A3B8" />

                    {/* Plant Pot */}
                    <path d="M 335 210 L 345 185 L 360 185 L 370 210 Z" fill="#818CF8" />
                    <circle cx="352.5" cy="175" r="10" fill="#A7F3D0" />
                    <circle cx="357.5" cy="170" r="8" fill="#34D399" />

                    {/* Floating Feature Badges */}
                    <g transform="translate(110, 80)">
                      <rect x="0" y="0" width="36" height="36" rx="10" fill="#FFFFFF" stroke="#E0E7FF" strokeWidth="2" />
                      <path d="M 12 14 L 24 14 M 12 18 L 24 18 M 12 22 L 18 22" stroke="#4F46E5" strokeWidth="2" strokeLinecap="round" />
                    </g>

                    <g transform="translate(200, 60)">
                      <rect x="0" y="0" width="36" height="36" rx="10" fill="#FFFFFF" stroke="#E0E7FF" strokeWidth="2" />
                      <rect x="8" y="18" width="4" height="10" fill="#818CF8" />
                      <rect x="16" y="12" width="4" height="16" fill="#4F46E5" />
                      <rect x="24" y="8" width="4" height="20" fill="#3730A3" />
                    </g>

                    <g transform="translate(290, 85)">
                      <rect x="0" y="0" width="36" height="36" rx="10" fill="#FFFFFF" stroke="#E0E7FF" strokeWidth="2" />
                      <circle cx="18" cy="18" r="8" fill="none" stroke="#4F46E5" strokeWidth="2" />
                      <circle cx="18" cy="18" r="3" fill="#4F46E5" />
                    </g>
                  </svg>
                </div>
              </div>

            </div>

            {/* Right Column: White Sign Up Form Card */}
            <div className="lg:col-span-6 flex justify-center">
              <div className="bg-white rounded-3xl p-6 sm:p-8 border border-slate-200/80 shadow-2xl max-w-md w-full space-y-5">
                
                {/* Form Title & Subtitle */}
                <div className="text-center space-y-1">
                  <h2 className="text-2xl font-black text-[#0F172A]">Sign Up</h2>
                  <p className="text-xs text-slate-500 font-medium">
                    Already have an account?{' '}
                    <span
                      onClick={() => navigate('/student')}
                      className="text-[#5D3EED] font-extrabold cursor-pointer hover:underline"
                    >
                      Login
                    </span>
                  </p>
                </div>

                {/* Social Login Buttons */}
                <div className="space-y-2.5">
                  <button
                    type="button"
                    onClick={() => navigate('/app')}
                    className="w-full border border-slate-200 rounded-xl py-2.5 px-4 flex items-center justify-center gap-2.5 font-bold text-xs text-slate-700 hover:bg-slate-50 transition-colors shadow-xs"
                  >
                    <svg className="w-4 h-4" viewBox="0 0 24 24">
                      <path
                        fill="#4285F4"
                        d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
                      />
                      <path
                        fill="#34A853"
                        d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                      />
                      <path
                        fill="#FBBC05"
                        d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l2.85-2.22.81-.63z"
                      />
                      <path
                        fill="#EA4335"
                        d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84c.87-2.6 3.3-4.52 6.16-4.52z"
                      />
                    </svg>
                    <span>Continue with Google</span>
                  </button>

                  <button
                    type="button"
                    onClick={() => navigate('/app')}
                    className="w-full border border-slate-200 rounded-xl py-2.5 px-4 flex items-center justify-center gap-2.5 font-bold text-xs text-slate-700 hover:bg-slate-50 transition-colors shadow-xs"
                  >
                    <svg className="w-4 h-4 fill-[#1877F2]" viewBox="0 0 24 24">
                      <path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z" />
                    </svg>
                    <span>Continue with Facebook</span>
                  </button>
                </div>

                {/* Divider Line */}
                <div className="flex items-center gap-3 py-1">
                  <div className="h-px bg-slate-200 flex-1" />
                  <span className="text-[11px] font-semibold text-slate-400">or</span>
                  <div className="h-px bg-slate-200 flex-1" />
                </div>

                {/* Registration Form */}
                <form onSubmit={handleSubmit} className="space-y-3.5">
                  
                  {/* Full Name */}
                  <div className="space-y-1">
                    <label className="text-xs font-extrabold text-slate-700 block">Full Name</label>
                    <div className="relative">
                      <User className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
                      <input
                        type="text"
                        required
                        placeholder="Enter your full name"
                        value={fullName}
                        onChange={(e) => setFullName(e.target.value)}
                        className="w-full pl-10 pr-4 py-2.5 bg-white border border-slate-200 rounded-xl text-xs font-semibold text-slate-800 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                      />
                    </div>
                  </div>

                  {/* Email Address */}
                  <div className="space-y-1">
                    <label className="text-xs font-extrabold text-slate-700 block">Email Address</label>
                    <div className="relative">
                      <Mail className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
                      <input
                        type="email"
                        required
                        placeholder="Enter your email address"
                        value={email}
                        onChange={(e) => setEmail(e.target.value)}
                        className="w-full pl-10 pr-4 py-2.5 bg-white border border-slate-200 rounded-xl text-xs font-semibold text-slate-800 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                      />
                    </div>
                  </div>

                  {/* Mobile Number */}
                  <div className="space-y-1">
                    <label className="text-xs font-extrabold text-slate-700 block">Mobile Number</label>
                    <div className="flex items-center gap-2">
                      <div className="flex items-center gap-1 bg-slate-50 border border-slate-200 rounded-xl px-3 py-2.5 text-xs font-bold text-slate-700 flex-shrink-0">
                        <span>🇮🇳</span>
                        <ChevronDown className="w-3 h-3 text-slate-400" />
                        <span className="ml-1 text-slate-900">+91</span>
                      </div>
                      <input
                        type="tel"
                        required
                        placeholder="Enter your mobile number"
                        value={mobile}
                        onChange={(e) => setMobile(e.target.value)}
                        className="w-full px-4 py-2.5 bg-white border border-slate-200 rounded-xl text-xs font-semibold text-slate-800 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                      />
                    </div>
                  </div>

                  {/* Password */}
                  <div className="space-y-1">
                    <label className="text-xs font-extrabold text-slate-700 block">Password</label>
                    <div className="relative">
                      <Lock className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
                      <input
                        type={showPassword ? 'text' : 'password'}
                        required
                        placeholder="Create a strong password"
                        value={password}
                        onChange={(e) => setPassword(e.target.value)}
                        className="w-full pl-10 pr-10 py-2.5 bg-white border border-slate-200 rounded-xl text-xs font-semibold text-slate-800 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                      />
                      <button
                        type="button"
                        onClick={() => setShowPassword(!showPassword)}
                        className="absolute right-3.5 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600"
                      >
                        {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                      </button>
                    </div>
                  </div>

                  {/* Confirm Password */}
                  <div className="space-y-1">
                    <label className="text-xs font-extrabold text-slate-700 block">Confirm Password</label>
                    <div className="relative">
                      <Lock className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
                      <input
                        type={showConfirmPassword ? 'text' : 'password'}
                        required
                        placeholder="Confirm your password"
                        value={confirmPassword}
                        onChange={(e) => setConfirmPassword(e.target.value)}
                        className="w-full pl-10 pr-10 py-2.5 bg-white border border-slate-200 rounded-xl text-xs font-semibold text-slate-800 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                      />
                      <button
                        type="button"
                        onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                        className="absolute right-3.5 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600"
                      >
                        {showConfirmPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                      </button>
                    </div>
                  </div>

                  {/* Terms Checkbox */}
                  <div className="flex items-center gap-2 pt-1">
                    <input
                      type="checkbox"
                      id="terms"
                      checked={agreeTerms}
                      onChange={(e) => setAgreeTerms(e.target.checked)}
                      className="w-4 h-4 rounded border-slate-300 text-[#5D3EED] focus:ring-[#5D3EED]"
                    />
                    <label htmlFor="terms" className="text-[11px] font-medium text-slate-600 cursor-pointer">
                      I agree to the <span className="text-[#5D3EED] font-bold">Terms of Service</span> and <span className="text-[#5D3EED] font-bold">Privacy Policy</span>
                    </label>
                  </div>

                  {/* Primary Submit Button */}
                  <button
                    type="submit"
                    className="w-full py-3.5 rounded-2xl bg-[#5D3EED] hover:bg-[#4F46E5] text-white font-extrabold text-xs shadow-lg shadow-indigo-600/30 transition-all mt-2"
                  >
                    Create Account
                  </button>

                  {/* Fine Print */}
                  <p className="text-[10px] text-slate-400 text-center font-medium leading-normal pt-1">
                    By signing up, you agree to our{' '}
                    <span className="text-[#5D3EED] font-bold">Terms of Service</span> and{' '}
                    <span className="text-[#5D3EED] font-bold">Privacy Policy</span>.
                  </p>

                </form>

              </div>
            </div>

          </div>
        </section>

        {/* ========================================================================= */}
        {/* 3. MIDDLE TRUST & RATINGS BANNER */}
        {/* ========================================================================= */}
        <section className="max-w-6xl mx-auto px-4 lg:px-8 py-6">
          <div className="bg-white border border-slate-200/80 rounded-3xl p-6 shadow-xs grid grid-cols-2 md:grid-cols-4 gap-6 divide-y md:divide-y-0 md:divide-x divide-slate-100">
            
            {/* Item 1 */}
            <div className="flex items-center gap-3.5 pt-4 md:pt-0">
              <div className="w-11 h-11 rounded-2xl bg-purple-50 text-[#5D3EED] border border-purple-100 flex items-center justify-center flex-shrink-0">
                <Users className="w-6 h-6 stroke-[2]" />
              </div>
              <div>
                <span className="text-sm font-black text-[#0F172A] block leading-tight">1M+</span>
                <span className="text-xs font-extrabold text-slate-800 block">Students</span>
                <span className="text-[10px] text-slate-400 font-semibold block">Trust Cosmyra</span>
              </div>
            </div>

            {/* Item 2 */}
            <div className="flex items-center gap-3.5 pt-4 md:pt-0 md:pl-6">
              <div className="w-11 h-11 rounded-2xl bg-emerald-50 text-emerald-600 border border-emerald-100 flex items-center justify-center flex-shrink-0">
                <ShieldCheck className="w-6 h-6 stroke-[2]" />
              </div>
              <div>
                <span className="text-sm font-black text-[#0F172A] block leading-tight">100%</span>
                <span className="text-xs font-extrabold text-slate-800 block">Safe & Secure</span>
                <span className="text-[10px] text-slate-400 font-semibold block">Your data is protected</span>
              </div>
            </div>

            {/* Item 3 */}
            <div className="flex items-center gap-3.5 pt-4 md:pt-0 md:pl-6">
              <div className="w-11 h-11 rounded-2xl bg-amber-50 text-amber-600 border border-amber-100 flex items-center justify-center flex-shrink-0">
                <Star className="w-6 h-6 stroke-[2] fill-amber-400 text-amber-400" />
              </div>
              <div>
                <span className="text-sm font-black text-[#0F172A] block leading-tight">4.8★</span>
                <span className="text-xs font-extrabold text-slate-800 block">Ratings</span>
                <span className="text-[10px] text-slate-400 font-semibold block">By students</span>
              </div>
            </div>

            {/* Item 4 */}
            <div className="flex items-center gap-3.5 pt-4 md:pt-0 md:pl-6">
              <div className="w-11 h-11 rounded-2xl bg-blue-50 text-blue-600 border border-blue-100 flex items-center justify-center flex-shrink-0">
                <Headphones className="w-6 h-6 stroke-[2]" />
              </div>
              <div>
                <span className="text-sm font-black text-[#0F172A] block leading-tight">24/7</span>
                <span className="text-xs font-extrabold text-slate-800 block">Support</span>
                <span className="text-[10px] text-slate-400 font-semibold block">We're here to help</span>
              </div>
            </div>

          </div>
        </section>
      </div>

      {/* ========================================================================= */}
      {/* 4. FULL WEBSITE FOOTER */}
      {/* ========================================================================= */}
      <footer className="bg-white border-t border-slate-200 mt-16 pt-12 pb-6 px-4 lg:px-12 text-slate-600 text-xs">
        <div className="max-w-7xl mx-auto grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-8 pb-10 border-b border-slate-100">
          
          {/* Brand Info */}
          <div className="space-y-4 lg:col-span-1">
            <div className="flex items-center gap-2.5">
              <div className="w-8 h-8 rounded-xl bg-indigo-50 border border-indigo-200 flex items-center justify-center text-[#5D3EED]">
                <GraduationCap className="w-5 h-5 stroke-[2]" />
              </div>
              <div>
                <h3 className="text-lg font-black text-[#5D3EED] leading-none">Cosmyra</h3>
                <span className="text-[9px] font-bold text-slate-400 block tracking-wider uppercase mt-0.5">NEET • JEE • Foundation</span>
              </div>
            </div>
            <p className="text-slate-500 font-medium leading-relaxed text-[11px]">
              India's most trusted platform for NEET, JEE and other competitive exam preparation.
            </p>

            {/* Social Icons */}
            <div className="flex items-center gap-3 pt-1">
              <button className="w-8 h-8 rounded-full bg-rose-50 text-rose-600 flex items-center justify-center hover:scale-110 transition-transform">
                <Youtube className="w-4 h-4" />
              </button>
              <button className="w-8 h-8 rounded-full bg-blue-50 text-blue-600 flex items-center justify-center hover:scale-110 transition-transform">
                <Send className="w-4 h-4" />
              </button>
              <button className="w-8 h-8 rounded-full bg-pink-50 text-pink-600 flex items-center justify-center hover:scale-110 transition-transform">
                <Instagram className="w-4 h-4" />
              </button>
              <button className="w-8 h-8 rounded-full bg-slate-100 text-slate-800 flex items-center justify-center hover:scale-110 transition-transform">
                <X className="w-4 h-4" />
              </button>
            </div>
          </div>

          {/* Platform Column */}
          <div className="space-y-2">
            <h4 className="font-extrabold text-slate-900 text-xs uppercase tracking-wider">Platform</h4>
            <ul className="space-y-2 text-slate-600 font-medium text-xs">
              <li><button onClick={() => navigate('/')} className="hover:text-[#5D3EED] transition-colors">Home</button></li>
              <li><button onClick={() => navigate('/')} className="hover:text-[#5D3EED] transition-colors">Features</button></li>
              <li><button onClick={() => navigate('/')} className="hover:text-[#5D3EED] transition-colors">Exams</button></li>
              <li><button onClick={() => navigate('/pyq')} className="hover:text-[#5D3EED] transition-colors">Paper Prediction</button></li>
              <li><button onClick={() => navigate('/pricing')} className="hover:text-[#5D3EED] transition-colors">Pricing</button></li>
            </ul>
          </div>

          {/* Company Column */}
          <div className="space-y-2">
            <h4 className="font-extrabold text-slate-900 text-xs uppercase tracking-wider">Company</h4>
            <ul className="space-y-2 text-slate-600 font-medium text-xs">
              <li><button onClick={() => navigate('/')} className="hover:text-[#5D3EED] transition-colors">About Us</button></li>
              <li><button onClick={() => navigate('/')} className="hover:text-[#5D3EED] transition-colors">Blog</button></li>
              <li><button onClick={() => navigate('/')} className="hover:text-[#5D3EED] transition-colors">Careers</button></li>
              <li><button onClick={() => navigate('/')} className="hover:text-[#5D3EED] transition-colors">Contact Us</button></li>
              <li><button onClick={() => navigate('/')} className="hover:text-[#5D3EED] transition-colors">Privacy Policy</button></li>
            </ul>
          </div>

          {/* Support Column */}
          <div className="space-y-2">
            <h4 className="font-extrabold text-slate-900 text-xs uppercase tracking-wider">Support</h4>
            <ul className="space-y-2 text-slate-600 font-medium text-xs">
              <li><button onClick={() => navigate('/')} className="hover:text-[#5D3EED] transition-colors">Help Center</button></li>
              <li><button onClick={() => navigate('/')} className="hover:text-[#5D3EED] transition-colors">Terms of Service</button></li>
              <li><button onClick={() => navigate('/')} className="hover:text-[#5D3EED] transition-colors">Refund Policy</button></li>
              <li><button onClick={() => navigate('/')} className="hover:text-[#5D3EED] transition-colors">FAQ</button></li>
            </ul>
          </div>

          {/* Download App Column */}
          <div className="space-y-3">
            <h4 className="font-extrabold text-slate-900 text-xs uppercase tracking-wider">Download App</h4>
            <p className="text-slate-500 text-[11px] font-medium leading-normal">
              Practice on the go with our mobile app.
            </p>

            <div className="space-y-2 pt-1">
              <button className="w-full bg-slate-900 text-white rounded-xl p-2.5 flex items-center justify-center gap-2 hover:bg-slate-800 transition-colors shadow-sm">
                <span className="text-lg">▶</span>
                <div className="text-left leading-none">
                  <span className="text-[8px] text-slate-300 font-semibold block uppercase">GET IT ON</span>
                  <span className="text-xs font-black block">Google Play</span>
                </div>
              </button>

              <button className="w-full bg-slate-900 text-white rounded-xl p-2.5 flex items-center justify-center gap-2 hover:bg-slate-800 transition-colors shadow-sm">
                <span className="text-lg"></span>
                <div className="text-left leading-none">
                  <span className="text-[8px] text-slate-300 font-semibold block uppercase">Download on the</span>
                  <span className="text-xs font-black block">App Store</span>
                </div>
              </button>
            </div>
          </div>

        </div>

        {/* Bottom Copyright */}
        <div className="max-w-7xl mx-auto pt-6 text-center text-[11px] font-bold text-slate-400">
          © 2025 Cosmyra. All rights reserved.
        </div>
      </footer>

    </div>
  );
};
