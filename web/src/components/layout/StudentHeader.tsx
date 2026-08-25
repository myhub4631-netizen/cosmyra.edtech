import React from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { Search, Bell, Calendar, ChevronDown, Sparkles, Crown } from 'lucide-react';

interface StudentHeaderProps {
  selectedExam: string;
  setSelectedExam: (exam: string) => void;
  userName?: string;
}

export const StudentHeader: React.FC<StudentHeaderProps> = ({
  selectedExam,
  setSelectedExam,
  userName = 'Arjun',
}) => {
  const navigate = useNavigate();

  return (
    <header className="h-16 bg-white border-b border-gray-200 px-4 lg:px-6 flex items-center justify-between sticky top-0 z-30 font-sans text-gray-800">
      {/* Left: Brand Logo & Exam Selector */}
      <div className="flex items-center gap-6">
        <div
          onClick={() => navigate('/student')}
          className="flex items-center gap-3 cursor-pointer group"
        >
          <div className="w-9 h-9 rounded-xl bg-gradient-to-tr from-indigo-600 to-purple-600 flex items-center justify-center text-white shadow-md shadow-indigo-500/20 group-hover:scale-105 transition-transform">
            <Sparkles className="w-5 h-5 fill-white" />
          </div>
          <div>
            <h1 className="text-lg font-bold text-gray-900 leading-tight">ExamPrep</h1>
            <span className="text-[10px] text-gray-400 font-medium block">
              Practice | Analyze | Succeed
            </span>
          </div>
        </div>

        {/* Exam Dropdown */}
        <div className="relative hidden sm:block">
          <select
            value={selectedExam}
            onChange={(e) => setSelectedExam(e.target.value)}
            className="bg-gray-50 border border-gray-200 text-gray-800 text-xs font-bold px-3 py-2 pr-8 rounded-xl focus:outline-none focus:border-indigo-500 appearance-none cursor-pointer"
          >
            <option value="NEET">NEET</option>
            <option value="JEE Main">JEE Main</option>
            <option value="JEE Advanced">JEE Advanced</option>
            <option value="CUET">CUET</option>
          </select>
          <ChevronDown className="w-3.5 h-3.5 text-gray-400 absolute right-2.5 top-3 pointer-events-none" />
        </div>

        {/* Global Search Bar */}
        <div className="relative hidden md:block w-72 lg:w-96">
          <Search className="w-4 h-4 text-gray-400 absolute left-3.5 top-2.5 pointer-events-none" />
          <input
            type="text"
            placeholder="Search for questions, topics, tests..."
            className="w-full bg-gray-50 border border-gray-200 rounded-xl pl-10 pr-8 py-2 text-xs text-gray-700 placeholder-gray-400 focus:outline-none focus:border-indigo-500 focus:bg-white transition-colors"
          />
          <span className="absolute right-3 top-2.5 text-[11px] font-medium text-gray-400">/</span>
        </div>
      </div>

      {/* Right Actions & Profile */}
      <div className="flex items-center gap-3 lg:gap-4">
        {/* Upgrade to Premium Button */}
        <button className="hidden sm:flex items-center gap-2 px-4 py-2 bg-gradient-to-r from-indigo-600 via-purple-600 to-indigo-700 hover:opacity-95 text-white rounded-xl text-xs font-bold shadow-md shadow-purple-500/20 transition-all">
          <Crown className="w-3.5 h-3.5 fill-amber-300 text-amber-300" />
          <span>Upgrade to Premium</span>
        </button>

        {/* Calendar Icon */}
        <button className="p-2 text-gray-500 hover:text-gray-800 hover:bg-gray-100 rounded-xl transition-colors">
          <Calendar className="w-4 h-4" />
        </button>

        {/* Notification Bell */}
        <button className="p-2 text-gray-500 hover:text-gray-800 hover:bg-gray-100 rounded-xl relative transition-colors">
          <Bell className="w-4 h-4" />
          <span className="absolute top-1.5 right-1.5 bg-rose-500 text-white text-[10px] font-bold w-4 h-4 rounded-full flex items-center justify-center border-2 border-white">
            8
          </span>
        </button>

        {/* User Profile Pill */}
        <div className="flex items-center gap-2.5 pl-2 border-l border-gray-200 cursor-pointer">
          <div className="text-right hidden md:block leading-none">
            <span className="text-xs font-bold text-gray-900 block">Hi, {userName} 👋</span>
            <span className="text-[10px] text-gray-400 font-medium block mt-0.5">12th Pass Student</span>
          </div>
          <img
            src="https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&auto=format&fit=crop&q=80"
            alt="Student Avatar"
            className="w-9 h-9 rounded-full object-cover border border-gray-200"
          />
        </div>
      </div>
    </header>
  );
};
