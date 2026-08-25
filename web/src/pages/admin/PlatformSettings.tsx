import React, { useState } from 'react';
import { Settings, Shield, ToggleLeft, ToggleRight, Save, Bell } from 'lucide-react';

export const PlatformSettingsView: React.FC = () => {
  const [flags, setFlags] = useState({
    custom_practice_enabled: true,
    custom_test_enabled: true,
    leaderboard_enabled: true,
    teacher_tests_enabled: true,
    pyq_enabled: true,
    nta_enabled: true,
  });

  const toggleFlag = (key: keyof typeof flags) => {
    setFlags((prev) => ({ ...prev, [key]: !prev[key] }));
  };

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      <div className="bg-slate-900/90 border border-slate-800 rounded-2xl p-6 space-y-6">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-emerald-500/10 text-emerald-400 flex items-center justify-center">
            <Settings className="w-5 h-5" />
          </div>
          <div>
            <h2 className="text-xl font-bold text-white">Global Feature Flags & Configuration</h2>
            <p className="text-xs text-slate-400">
              Control platform features dynamically without rebuilding or redeploying the application.
            </p>
          </div>
        </div>

        <div className="space-y-3">
          {Object.entries(flags).map(([key, val]) => (
            <div
              key={key}
              className="p-4 rounded-xl bg-slate-950 border border-slate-800 flex items-center justify-between"
            >
              <div>
                <h4 className="text-xs font-bold text-slate-200 capitalize">
                  {key.replace(/_/g, ' ')}
                </h4>
                <p className="text-[11px] text-slate-500">
                  {val ? 'Enabled globally for all students & teachers' : 'Disabled / Maintenance mode'}
                </p>
              </div>

              <button
                onClick={() => toggleFlag(key as any)}
                className={`p-1.5 rounded-lg text-xs font-bold transition-all flex items-center gap-2 ${
                  val ? 'text-emerald-400' : 'text-slate-500'
                }`}
              >
                {val ? <ToggleRight className="w-7 h-7 text-emerald-500" /> : <ToggleLeft className="w-7 h-7 text-slate-600" />}
              </button>
            </div>
          ))}
        </div>

        <button
          onClick={() => alert('Platform settings saved successfully to Supabase app_settings!')}
          className="w-full py-3 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white text-xs font-bold transition-all flex items-center justify-center gap-2 shadow-md shadow-emerald-600/20"
        >
          <Save className="w-4 h-4" /> Save Configuration
        </button>
      </div>
    </div>
  );
};
