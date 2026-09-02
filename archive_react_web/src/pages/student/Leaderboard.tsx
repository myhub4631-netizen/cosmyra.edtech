import React, { useState } from 'react';
import { MOCK_LEADERBOARD } from '../../lib/mockData';
import { Award, Trophy, Medal, Flame, Shield, User } from 'lucide-react';

export const LeaderboardView: React.FC = () => {
  const [period, setPeriod] = useState<'daily' | 'weekly' | 'monthly'>('weekly');
  const [isPrivate, setIsPrivate] = useState<boolean>(false);

  return (
    <div className="space-y-6 max-w-5xl mx-auto">
      {/* Header Banner */}
      <div className="bg-gradient-to-r from-amber-900/40 via-purple-900/30 to-slate-900 border border-amber-500/20 rounded-2xl p-6 lg:p-8 flex flex-col md:flex-row md:items-center justify-between gap-6">
        <div>
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-amber-500/10 text-amber-400 border border-amber-500/30 text-xs font-semibold mb-3">
            <Trophy className="w-3.5 h-3.5" /> All-India Student Rankings
          </div>
          <h2 className="text-2xl font-black text-white">Student Leaderboard</h2>
          <p className="text-xs text-slate-300">Fair rank calculation based on score, accuracy & verified practice.</p>
        </div>

        {/* Period Selector Tabs */}
        <div className="bg-slate-950 p-1 rounded-xl border border-slate-800 flex gap-1">
          {(['daily', 'weekly', 'monthly'] as const).map((t) => (
            <button
              key={t}
              onClick={() => setPeriod(t)}
              className={`px-4 py-2 rounded-lg text-xs font-bold capitalize transition-all ${
                period === t
                  ? 'bg-amber-500 text-slate-950 shadow-md shadow-amber-500/20'
                  : 'text-slate-400 hover:text-slate-200'
              }`}
            >
              {t}
            </button>
          ))}
        </div>
      </div>

      {/* Leaderboard Table */}
      <div className="bg-slate-900/90 border border-slate-800 rounded-2xl overflow-hidden shadow-xl">
        <div className="p-4 border-b border-slate-800 flex justify-between items-center text-xs">
          <span className="font-bold text-slate-300 uppercase tracking-wider">Top Performers</span>
          <button
            onClick={() => setIsPrivate(!isPrivate)}
            className="text-slate-400 hover:text-slate-200 flex items-center gap-1.5"
          >
            <Shield className="w-3.5 h-3.5" /> {isPrivate ? 'Private Mode Active' : 'Public Profile Active'}
          </button>
        </div>

        <div className="divide-y divide-slate-800/80">
          {MOCK_LEADERBOARD.map((entry) => {
            let rankBadge = (
              <span className="w-7 h-7 rounded-full bg-slate-800 text-slate-300 font-bold text-xs flex items-center justify-center">
                #{entry.rank}
              </span>
            );

            if (entry.rank === 1) {
              rankBadge = (
                <div className="w-8 h-8 rounded-full bg-amber-500 text-slate-950 font-black text-sm flex items-center justify-center shadow-lg shadow-amber-500/30">
                  <Medal className="w-4 h-4" />
                </div>
              );
            } else if (entry.rank === 2) {
              rankBadge = (
                <div className="w-8 h-8 rounded-full bg-slate-300 text-slate-950 font-black text-sm flex items-center justify-center shadow-lg shadow-slate-300/30">
                  <Medal className="w-4 h-4" />
                </div>
              );
            } else if (entry.rank === 3) {
              rankBadge = (
                <div className="w-8 h-8 rounded-full bg-amber-700 text-amber-100 font-black text-sm flex items-center justify-center shadow-lg shadow-amber-700/30">
                  <Medal className="w-4 h-4" />
                </div>
              );
            }

            return (
              <div key={entry.id} className="p-4 flex items-center justify-between hover:bg-slate-800/30 transition-colors">
                <div className="flex items-center gap-4">
                  {rankBadge}
                  <div className="w-10 h-10 rounded-full bg-gradient-to-tr from-blue-600 to-indigo-600 font-bold text-xs text-white flex items-center justify-center shadow-sm">
                    {entry.student_name.slice(0, 2).toUpperCase()}
                  </div>
                  <div>
                    <h4 className="text-sm font-bold text-white">{entry.student_name}</h4>
                    <p className="text-[11px] text-slate-400">{entry.questions_solved} Questions Solved</p>
                  </div>
                </div>

                <div className="text-right">
                  <span className="text-base font-black text-amber-400">{entry.score} pts</span>
                  <p className="text-[11px] font-semibold text-emerald-400">{entry.accuracy}% Accuracy</p>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};
