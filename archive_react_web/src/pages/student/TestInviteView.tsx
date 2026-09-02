import React, { useState } from 'react';
import { MOCK_TEACHER_TESTS } from '../../lib/mockData';
import { Sparkles, GraduationCap, Clock, Award, CheckCircle2, AlertTriangle, ShieldCheck } from 'lucide-react';

interface TestInviteProps {
  inviteCode?: string;
  onJoinTest: () => void;
}

export const TestInviteView: React.FC<TestInviteProps> = ({ inviteCode = 'NEETPHYS2026', onJoinTest }) => {
  const test = MOCK_TEACHER_TESTS[0];

  return (
    <div className="max-w-3xl mx-auto space-y-6">
      <div className="bg-slate-900/90 border border-slate-800 rounded-2xl p-6 lg:p-8 space-y-6 shadow-2xl">
        {/* Header */}
        <div className="flex items-center gap-3 border-b border-slate-800 pb-6">
          <div className="w-12 h-12 rounded-2xl bg-gradient-to-tr from-purple-600 to-indigo-600 flex items-center justify-center text-white font-bold shadow-lg shadow-purple-600/30">
            <GraduationCap className="w-6 h-6" />
          </div>
          <div>
            <div className="inline-flex items-center gap-1.5 text-[10px] font-bold uppercase tracking-wider text-purple-400">
              <ShieldCheck className="w-3.5 h-3.5" /> Verified Teacher Invitation
            </div>
            <h2 className="text-xl font-extrabold text-white">{test.title}</h2>
            <p className="text-xs text-slate-400">Created by {test.teacher_name}</p>
          </div>
        </div>

        {/* Test Overview Grid */}
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
          <div className="bg-slate-950 p-4 rounded-xl border border-slate-800">
            <p className="text-[10px] font-bold text-slate-500 uppercase">Target Exam</p>
            <p className="text-sm font-bold text-white mt-1">NEET UG</p>
          </div>

          <div className="bg-slate-950 p-4 rounded-xl border border-slate-800">
            <p className="text-[10px] font-bold text-slate-500 uppercase">Questions</p>
            <p className="text-sm font-bold text-blue-400 mt-1">{test.question_count} MCQs</p>
          </div>

          <div className="bg-slate-950 p-4 rounded-xl border border-slate-800">
            <p className="text-[10px] font-bold text-slate-500 uppercase">Duration</p>
            <p className="text-sm font-bold text-indigo-400 mt-1">{test.duration_minutes} Mins</p>
          </div>

          <div className="bg-slate-950 p-4 rounded-xl border border-slate-800">
            <p className="text-[10px] font-bold text-slate-500 uppercase">Marking Scheme</p>
            <p className="text-sm font-bold text-emerald-400 mt-1">+4 / -1 Mark</p>
          </div>
        </div>

        {/* Description & Rules */}
        <div className="bg-slate-950 p-5 rounded-xl border border-slate-800 space-y-3 text-xs text-slate-300">
          <h4 className="font-bold text-slate-200 uppercase tracking-wider">Teacher Instructions</h4>
          <p className="leading-relaxed">{test.description}</p>
          <ul className="list-disc pl-4 space-y-1 text-slate-400">
            <li>Ensure stable internet connection before starting.</li>
            <li>Server timer begins immediately upon clicking "Join Test".</li>
            <li>Attempt limits: {test.attempt_limit === 0 ? 'Unlimited' : `${test.attempt_limit} Attempt allowed`}.</li>
          </ul>
        </div>

        {/* Action button */}
        <button
          onClick={onJoinTest}
          className="w-full py-4 rounded-xl bg-gradient-to-r from-purple-600 via-indigo-600 to-blue-600 text-white font-bold text-sm shadow-xl shadow-purple-600/30 hover:opacity-95 transition-all flex items-center justify-center gap-2"
        >
          <Sparkles className="w-4 h-4" /> Start Teacher Test Attempt
        </button>
      </div>
    </div>
  );
};
