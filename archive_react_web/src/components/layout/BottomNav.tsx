import React from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { Home, FileSpreadsheet, Target, BarChart3, User } from 'lucide-react';

interface BottomNavProps {
  activeTab?: string;
  onTabChange?: (tab: string) => void;
  isMobileFrame?: boolean;
}

export const BottomNav: React.FC<BottomNavProps> = ({
  activeTab,
  onTabChange,
  isMobileFrame = false,
}) => {
  const location = useLocation();
  const navigate = useNavigate();

  const navItems = [
    {
      id: 'home',
      label: 'Home',
      icon: Home,
      path: '/student',
      mobileAppPath: '/app',
    },
    {
      id: 'test',
      label: 'Tests',
      icon: FileSpreadsheet,
      path: '/student/test',
      mobileAppPath: '/app/test',
    },
    {
      id: 'practice',
      label: 'Practice',
      icon: Target,
      path: '/student/practice',
      mobileAppPath: '/app/practice',
    },
    {
      id: 'analytics',
      label: 'Analytics',
      icon: BarChart3,
      path: '/student/analytics',
      mobileAppPath: '/app/analytics',
    },
    {
      id: 'profile',
      label: 'Profile',
      icon: User,
      path: '/student/profile',
      mobileAppPath: '/app/profile',
    },
  ];

  const getIsActive = (item: (typeof navItems)[0]) => {
    if (activeTab) {
      return activeTab === item.id || (activeTab === 'tests' && item.id === 'test');
    }
    if (item.id === 'home') {
      return (
        location.pathname === '/student' ||
        location.pathname === '/dashboard' ||
        location.pathname === '/app' ||
        location.pathname === '/'
      );
    }
    return location.pathname.startsWith(item.path) || location.pathname.startsWith(item.mobileAppPath);
  };

  const handleClick = (item: (typeof navItems)[0]) => {
    if (onTabChange) {
      onTabChange(item.id);
    } else {
      const isAppRoute = location.pathname.startsWith('/app');
      navigate(isAppRoute ? item.mobileAppPath : item.path);
    }
  };

  return (
    <nav
      aria-label="Bottom Navigation Menu"
      className={`${
        isMobileFrame
          ? 'bg-white border-t border-slate-200 px-3 py-2 flex items-center justify-between text-xs font-bold text-slate-400'
          : 'fixed bottom-0 left-0 right-0 z-40 bg-white/95 backdrop-blur-md border-t border-slate-200 px-2 py-1.5 flex items-center justify-around text-xs font-bold text-slate-400 md:hidden shadow-lg'
      }`}
    >
      {navItems.map((item) => {
        const Icon = item.icon;
        const isActive = getIsActive(item);

        return (
          <button
            key={item.id}
            id={`bottom-nav-${item.id}`}
            onClick={() => handleClick(item)}
            className={`flex flex-col items-center gap-0.5 px-2 py-1 rounded-xl transition-all ${
              isActive
                ? 'text-indigo-600 font-bold scale-105'
                : 'text-slate-500 hover:text-slate-800'
            }`}
          >
            <div className={`p-1 rounded-xl transition-colors ${isActive ? 'bg-indigo-50 text-indigo-600' : ''}`}>
              <Icon className="w-5 h-5" />
            </div>
            <span className="text-[10px] tracking-tight capitalize">{item.label}</span>
          </button>
        );
      })}
    </nav>
  );
};
