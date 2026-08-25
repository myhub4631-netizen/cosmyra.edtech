import React from 'react';
import { useNavigate } from 'react-router-dom';
import { Sparkles, Search, ChevronDown } from 'lucide-react';

export const LandingNavbar: React.FC = () => {
  const navigate = useNavigate();

  return (
    <header className="h-20 bg-white border-b border-gray-100 px-6 lg:px-12 flex items-center justify-between sticky top-0 z-50 font-sans text-gray-800 shadow-sm">
      {/* Left: Brand Logo & Tagline */}
      <div
        onClick={() => navigate('/')}
        className="flex items-center gap-3 cursor-pointer group"
      >
        <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-indigo-600 to-purple-600 flex items-center justify-center text-white shadow-md shadow-indigo-600/20 group-hover:scale-105 transition-transform">
          <Sparkles className="w-5 h-5 fill-white" />
        </div>
        <div>
          <h1 className="text-xl font-extrabold text-gray-900 leading-none">ExamPrep</h1>
          <span className="text-[10px] text-gray-400 font-semibold block mt-0.5">
            Practice | Analyze | Succeed
          </span>
        </div>
      </div>

      {/* Center: Navigation Links */}
      <nav className="hidden lg:flex items-center gap-7 text-xs font-bold text-gray-600">
        <button onClick={() => navigate('/')} className="text-indigo-600 font-extrabold hover:text-indigo-700">
          Home
        </button>

        <div className="flex items-center gap-1 cursor-pointer hover:text-indigo-600 transition-colors">
          <span>Practice</span>
          <ChevronDown className="w-3.5 h-3.5 text-gray-400" />
        </div>

        <div className="flex items-center gap-1 cursor-pointer hover:text-indigo-600 transition-colors">
          <span>Tests</span>
          <ChevronDown className="w-3.5 h-3.5 text-gray-400" />
        </div>

        <div className="flex items-center gap-1 cursor-pointer hover:text-indigo-600 transition-colors">
          <span>PYQ</span>
          <ChevronDown className="w-3.5 h-3.5 text-gray-400" />
        </div>

        <button onClick={() => navigate('/student')} className="hover:text-indigo-600 transition-colors">
          Study Material
        </button>

        <button onClick={() => navigate('/student/leaderboard')} className="hover:text-indigo-600 transition-colors">
          Leaderboard
        </button>

        <button onClick={() => navigate('/pricing')} className="hover:text-indigo-600 transition-colors">
          Pricing
        </button>

        <button className="hover:text-indigo-600 transition-colors">
          About Us
        </button>
      </nav>

      {/* Right: Search, Log In, Sign Up */}
      <div className="flex items-center gap-4">
        <button className="p-2 text-gray-500 hover:text-gray-900 hover:bg-gray-100 rounded-xl transition-colors">
          <Search className="w-4 h-4" />
        </button>

        <button
          onClick={() => navigate('/student')}
          className="px-5 py-2.5 border border-gray-200 hover:bg-gray-50 text-gray-800 text-xs font-bold rounded-xl transition-colors"
        >
          Log In
        </button>

        <button
          onClick={() => navigate('/signup')}
          className="px-5 py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white text-xs font-bold rounded-xl shadow-md shadow-indigo-600/30 transition-all"
        >
          Sign Up
        </button>
      </div>
    </header>
  );
};
