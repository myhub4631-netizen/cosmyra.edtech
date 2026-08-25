import React from 'react';
import { MOCK_TEACHER_TESTS } from '../../lib/mockData';
import { LayoutDashboard, Users, FileSpreadsheet, PlusCircle, Link, BarChart3, ArrowRight, CheckCircle2 } from 'lucide-react';

interface TeacherDashboardProps {
  onNavigate: (tab: string) => void;
}

export const TeacherDashboardView: React.FC<TeacherDashboardProps> = ({ onNavigate }) => {
  return (
    <div className="space-y-6">
      {/* Header Banner */}
      <div className="bg-gradient-to-r from-purple-900/60 via-indigo-900/40 to-slate-900 border border-purple-500/20 rounded-2xl p-6 lg:p-8 flex flex-col md:flex-row md:items-center justify-between gap-6">
        <div>
          <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-purple-500/10 text-purple-400 border border-purple-500/30 text-xs font-semibold mb-2">
            <CheckCircle2 className="w-3.5 h-3.5" /> Verified Educator Portal
          </span>
          <h2 className="text-2xl font-black text-white">Teacher Command Center</h2>
          <p className="text-xs text-slate-300">
            Create educational assessments from the centralized question bank & invite students instantly.
          </p>
        </div>

        <button
          onClick={() => onNavigate('create_test')}
          className="px-5 py-3 rounded-xl bg-purple-600 hover:bg-purple-500 text-white font-bold text-xs flex items-center gap-2 shadow-lg shadow-purple-600/30 transition-all"
        >
          <PlusCircle className="w-4 h-4" /> Create New Test
        </button>
      </div>

      {/* Metrics Row */}
      <div className="grid grid-cols-1 sm:grid-cols-4 gap-4">
        <div className="bg-slate-900/90 border border-slate-800 p-5 rounded-2xl">
          <p className="text-xs font-bold text-slate-400 uppercase">Active Tests</p>
          <p className="text-2xl font-black text-purple-400 mt-1">3</p>
        </div>
        <div className="bg-slate-900/90 border border-slate-800 p-5 rounded-2xl">
          <p className="text-xs font-bold text-slate-400 uppercase">Total Student Attempts</p>
          <p className="text-2xl font-black text-blue-400 mt-1">142</p>
        </div>
        <div className="bg-slate-900/90 border border-slate-800 p-5 rounded-2xl">
          <p className="text-xs font-bold text-slate-400 uppercase">Average Score</p>
          <p className="text-2xl font-black text-emerald-400 mt-1">128 / 180</p>
        </div>
        <div className="bg-slate-900/90 border border-slate-800 p-5 rounded-2xl">
          <p className="text-xs font-bold text-slate-400 uppercase">Average Accuracy</p>
          <p className="text-2xl font-black text-amber-400 mt-1">78.5%</p>
        </div>
      </div>

      {/* Created Tests List */}
      <div className="bg-slate-900/90 border border-slate-800 rounded-2xl p-6 space-y-4">
        <div className="flex items-center justify-between">
          <h3 className="text-sm font-bold text-white flex items-center gap-2">
            <FileSpreadsheet className="w-4 h-4 text-purple-400" /> My Published Tests & Invitations
          </h3>
          <button
            onClick={() => onNavigate('invitations')}
            className="text-xs text-purple-400 font-semibold hover:underline"
          >
            Manage Links
          </button>
        </div>

        <div className="space-y-3">
          {MOCK_TEACHER_TESTS.map((t) => (
            <div
              key={t.id}
              className="p-4 rounded-xl bg-slate-950 border border-slate-800 flex flex-col md:flex-row md:items-center justify-between gap-4"
            >
              <div>
                <h4 className="text-sm font-bold text-white">{t.title}</h4>
                <p className="text-xs text-slate-400 mt-0.5">
                  {t.question_count} Questions • {t.duration_minutes} Mins • Code:{' '}
                  <span className="font-mono text-purple-400 font-bold">{t.invitation_code}</span>
                </p>
              </div>

              <div className="flex items-center gap-3">
                <button
                  onClick={() => {
                    navigator.clipboard.writeText(`https://cosmyra.ai/invite/test/${t.invitation_code}`);
                    alert('Invitation link copied to clipboard!');
                  }}
                  className="px-3 py-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-xs font-semibold text-slate-200 flex items-center gap-1.5"
                >
                  <Link className="w-3.5 h-3.5" /> Copy Invite Link
                </button>
                <button
                  onClick={() => onNavigate('student_analytics')}
                  className="px-3 py-1.5 rounded-lg bg-purple-600/20 text-purple-300 border border-purple-500/30 text-xs font-semibold hover:bg-purple-600/30"
                >
                  View Attempts
                </button>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};
