import React from 'react';
import { Search, Bell, Shield, Maximize2, ChevronDown, Menu } from 'lucide-react';

interface AdminHeaderProps {
  onToggleSidebar?: () => void;
}

export const AdminHeader: React.FC<AdminHeaderProps> = ({ onToggleSidebar }) => {
  return (
    <header className="h-14 bg-white border-b border-gray-200 px-4 flex items-center justify-between sticky top-0 z-30 font-sans text-gray-800">
      {/* Left: Hamburger & Search */}
      <div className="flex items-center gap-3">
        <button
          onClick={onToggleSidebar}
          className="p-1.5 text-gray-500 hover:text-gray-800 hover:bg-gray-100 rounded-lg transition-colors"
        >
          <Menu className="w-5 h-5" />
        </button>

        {/* Global Search Bar */}
        <div className="relative hidden sm:block w-72 lg:w-96">
          <Search className="w-4 h-4 text-gray-400 absolute left-3 top-2.5 pointer-events-none" />
          <input
            type="text"
            placeholder="Search anything..."
            className="w-full bg-gray-50 border border-gray-200 rounded-lg pl-9 pr-16 py-1.5 text-xs text-gray-700 placeholder-gray-400 focus:outline-none focus:border-indigo-500 focus:bg-white transition-colors"
          />
          <kbd className="absolute right-2.5 top-2 px-1.5 py-0.5 text-[10px] font-semibold text-gray-400 bg-gray-100 border border-gray-200 rounded">
            CTRL + K
          </kbd>
        </div>
      </div>

      {/* Right: Actions & User Profile */}
      <div className="flex items-center gap-2 lg:gap-3">
        {/* Notification Bell with Badge */}
        <button className="p-2 text-gray-500 hover:text-gray-800 hover:bg-gray-100 rounded-lg relative transition-colors">
          <Bell className="w-4 h-4" />
          <span className="absolute top-1 right-1 bg-rose-500 text-white text-[10px] font-bold w-4 h-4 rounded-full flex items-center justify-center border-2 border-white">
            12
          </span>
        </button>

        {/* Security Shield */}
        <button className="p-2 text-gray-500 hover:text-gray-800 hover:bg-gray-100 rounded-lg transition-colors">
          <Shield className="w-4 h-4" />
        </button>

        {/* Fullscreen Toggle */}
        <button className="p-2 text-gray-500 hover:text-gray-800 hover:bg-gray-100 rounded-lg transition-colors">
          <Maximize2 className="w-4 h-4" />
        </button>

        {/* User Profile Pill */}
        <div className="flex items-center gap-2 pl-2 border-l border-gray-200 cursor-pointer group">
          <img
            src="https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&auto=format&fit=crop&q=80"
            alt="Super Admin Avatar"
            className="w-8 h-8 rounded-full object-cover border border-gray-200"
          />
          <div className="hidden md:block text-left leading-none">
            <span className="text-xs font-bold text-gray-900 block">Super Admin</span>
            <span className="text-[10px] text-gray-400 block mt-0.5">superadmin@examprep.com</span>
          </div>
          <ChevronDown className="w-3.5 h-3.5 text-gray-400 group-hover:text-gray-600 transition-colors" />
        </div>
      </div>
    </header>
  );
};
