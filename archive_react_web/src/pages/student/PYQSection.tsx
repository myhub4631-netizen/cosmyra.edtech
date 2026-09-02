import React, { useState } from 'react';
import { MOCK_QUESTIONS, MOCK_SUBJECTS, MOCK_EXAMS } from '../../lib/mockData';
import { MathText } from '../../components/common/MathText';
import { BookOpen, Calendar, Filter, Sparkles, Bookmark } from 'lucide-react';

export const PYQSection: React.FC = () => {
  const [selectedYear, setSelectedYear] = useState<string>('all');
  const [selectedSubject, setSelectedSubject] = useState<string>('all');

  const pyqQuestions = MOCK_QUESTIONS.filter((q) => q.source === 'pyq');

  return (
    <div className="space-y-6">
      <div className="bg-slate-900/90 border border-slate-800 rounded-2xl p-6 flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 text-xs font-semibold mb-2">
            <BookOpen className="w-3.5 h-3.5" /> Official PYQ Question Bank
          </div>
          <h2 className="text-xl font-extrabold text-white">Previous Year Questions (2020–2025)</h2>
          <p className="text-xs text-slate-400">Authentic NTA NEET & JEE question paper solutions with explanations.</p>
        </div>

        {/* Filters */}
        <div className="flex flex-wrap items-center gap-3">
          <div className="flex items-center gap-2 bg-slate-950 px-3 py-1.5 rounded-xl border border-slate-800">
            <Calendar className="w-3.5 h-3.5 text-slate-400" />
            <select
              value={selectedYear}
              onChange={(e) => setSelectedYear(e.target.value)}
              className="bg-transparent text-xs font-semibold text-slate-200 focus:outline-none"
            >
              <option value="all">All Years (2020-2025)</option>
              <option value="2025">2025</option>
              <option value="2024">2024</option>
              <option value="2023">2023</option>
            </select>
          </div>
        </div>
      </div>

      {/* PYQ Question List */}
      <div className="space-y-4">
        {pyqQuestions.map((q, idx) => (
          <div key={q.id} className="bg-slate-900/90 border border-slate-800 rounded-2xl p-6 space-y-4">
            <div className="flex items-center justify-between pb-3 border-b border-slate-800">
              <span className="px-2.5 py-1 rounded-lg bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 text-xs font-bold">
                {q.year} {q.session}
              </span>
              <span className="text-xs text-slate-400 uppercase font-semibold">{q.difficulty}</span>
            </div>

            <div className="text-sm font-medium text-slate-100">
              <MathText text={q.question_text} />
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
              {q.options.map((opt, oIdx) => (
                <div
                  key={opt.id}
                  className={`p-3 rounded-xl border text-xs flex items-center gap-2 ${
                    opt.is_correct
                      ? 'bg-emerald-500/10 border-emerald-500/40 text-emerald-300 font-semibold'
                      : 'bg-slate-950 border-slate-800 text-slate-400'
                  }`}
                >
                  <span className="w-5 h-5 rounded bg-slate-800 text-slate-300 font-bold flex items-center justify-center text-[10px]">
                    {String.fromCharCode(65 + oIdx)}
                  </span>
                  <MathText text={opt.option_text} />
                </div>
              ))}
            </div>

            <div className="p-4 rounded-xl bg-slate-950 border border-slate-800 text-xs text-slate-300 space-y-2">
              <p className="font-bold text-slate-200">Solution:</p>
              <MathText text={q.solution || ''} />
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};
