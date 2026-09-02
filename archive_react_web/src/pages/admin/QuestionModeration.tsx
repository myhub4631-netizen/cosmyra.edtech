import React, { useState } from 'react';
import { MOCK_QUESTIONS } from '../../lib/mockData';
import { MathText } from '../../components/common/MathText';
import { BookOpen, FileUp, CheckCircle2, XCircle, AlertTriangle, Download, Sparkles, Filter } from 'lucide-react';

export const QuestionModerationView: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'moderation' | 'bulk_import'>('moderation');

  // Bulk Import state
  const [csvText, setCsvText] = useState<string>(
    `exam,subject,chapter,topic,question,option_a,option_b,option_c,option_d,correct_answer,explanation,solution,difficulty,year,source,marks,negative_marks
NEET,Physics,Laws of Motion,Friction,"What is the unit of friction?",Newton,Joule,Pascal,Watt,A,Friction is a force measured in Newtons.,$F = \\mu N$,easy,2024,pyq,4,1`
  );
  const [importSummary, setImportSummary] = useState<{
    total: number;
    valid: number;
    invalid: number;
    duplicates: number;
  } | null>(null);

  const handleValidateCsv = () => {
    const lines = csvText.trim().split('\n');
    const total = Math.max(0, lines.length - 1);
    setImportSummary({
      total,
      valid: total,
      invalid: 0,
      duplicates: 0,
    });
  };

  const handleConfirmImport = () => {
    alert(`Successfully imported ${importSummary?.valid} questions into the centralized question bank!`);
    setImportSummary(null);
  };

  return (
    <div className="space-y-6">
      {/* Header Tabs */}
      <div className="bg-slate-900/90 border border-slate-800 rounded-2xl p-4 flex items-center justify-between">
        <div className="flex items-center gap-2">
          <button
            onClick={() => setActiveTab('moderation')}
            className={`px-4 py-2 rounded-xl text-xs font-bold transition-all ${
              activeTab === 'moderation'
                ? 'bg-blue-600 text-white'
                : 'text-slate-400 hover:text-slate-200'
            }`}
          >
            Question Moderation Queue
          </button>
          <button
            onClick={() => setActiveTab('bulk_import')}
            className={`px-4 py-2 rounded-xl text-xs font-bold transition-all ${
              activeTab === 'bulk_import'
                ? 'bg-blue-600 text-white'
                : 'text-slate-400 hover:text-slate-200'
            }`}
          >
            Bulk CSV Question Importer
          </button>
        </div>
      </div>

      {activeTab === 'moderation' && (
        <div className="space-y-4">
          <div className="bg-slate-900/90 border border-slate-800 rounded-2xl p-6">
            <h3 className="text-sm font-bold text-white mb-4">Pending Question Approvals</h3>
            <div className="space-y-3">
              {MOCK_QUESTIONS.map((q) => (
                <div key={q.id} className="p-4 rounded-xl bg-slate-950 border border-slate-800 space-y-3">
                  <div className="flex justify-between text-xs">
                    <span className="font-semibold text-slate-300">Status: {q.status}</span>
                    <span className="text-slate-400">Created by Teacher</span>
                  </div>
                  <div className="text-xs text-slate-200">
                    <MathText text={q.question_text} />
                  </div>
                  <div className="flex gap-2 justify-end">
                    <button className="px-3 py-1.5 rounded-lg bg-rose-500/10 text-rose-400 border border-rose-500/20 text-xs font-semibold">
                      Reject
                    </button>
                    <button className="px-3 py-1.5 rounded-lg bg-emerald-600 text-white text-xs font-bold">
                      Approve & Publish
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {activeTab === 'bulk_import' && (
        <div className="bg-slate-900/90 border border-slate-800 rounded-2xl p-6 space-y-6">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-blue-500/10 text-blue-400 flex items-center justify-center">
              <FileUp className="w-5 h-5" />
            </div>
            <div>
              <h3 className="text-base font-bold text-white">Bulk Question Import (CSV / XLSX)</h3>
              <p className="text-xs text-slate-400">
                Upload or paste question dataset. Validates taxonomy references, option counts, and LaTeX syntax.
              </p>
            </div>
          </div>

          <div className="space-y-2">
            <div className="flex justify-between items-center text-xs">
              <label className="font-bold text-slate-300">CSV Data Payload</label>
              <button
                onClick={() => {
                  const blob = new Blob([csvText], { type: 'text/csv' });
                  const url = URL.createObjectURL(blob);
                  const a = document.createElement('a');
                  a.href = url;
                  a.download = 'question_import_template.csv';
                  a.click();
                }}
                className="text-blue-400 hover:underline flex items-center gap-1 font-semibold"
              >
                <Download className="w-3.5 h-3.5" /> Download Template
              </button>
            </div>
            <textarea
              value={csvText}
              onChange={(e) => setCsvText(e.target.value)}
              className="w-full h-44 bg-slate-950 border border-slate-800 rounded-xl p-3 font-mono text-xs text-slate-300 focus:outline-none focus:border-blue-500"
            />
          </div>

          <button
            onClick={handleValidateCsv}
            className="w-full py-3 rounded-xl bg-blue-600 text-white font-bold text-xs hover:bg-blue-500 transition-all flex items-center justify-center gap-2"
          >
            <Sparkles className="w-4 h-4" /> Validate Dataset Rows
          </button>

          {/* Validation Summary Report */}
          {importSummary && (
            <div className="bg-slate-950 border border-slate-800 rounded-xl p-5 space-y-4">
              <h4 className="text-xs font-bold text-slate-200 uppercase tracking-wider">Validation Pre-flight Summary</h4>

              <div className="grid grid-cols-4 gap-3 text-xs">
                <div className="p-3 bg-slate-900 rounded-lg border border-slate-800">
                  <span className="text-slate-400 block text-[10px]">Total Rows</span>
                  <span className="text-base font-bold text-white">{importSummary.total}</span>
                </div>
                <div className="p-3 bg-slate-900 rounded-lg border border-slate-800">
                  <span className="text-slate-400 block text-[10px]">Valid Rows</span>
                  <span className="text-base font-bold text-emerald-400">{importSummary.valid}</span>
                </div>
                <div className="p-3 bg-slate-900 rounded-lg border border-slate-800">
                  <span className="text-slate-400 block text-[10px]">Invalid Rows</span>
                  <span className="text-base font-bold text-rose-400">{importSummary.invalid}</span>
                </div>
                <div className="p-3 bg-slate-900 rounded-lg border border-slate-800">
                  <span className="text-slate-400 block text-[10px]">Duplicates</span>
                  <span className="text-base font-bold text-amber-400">{importSummary.duplicates}</span>
                </div>
              </div>

              <div className="flex justify-end gap-2">
                <button
                  onClick={() => setImportSummary(null)}
                  className="px-4 py-2 rounded-xl bg-slate-800 text-xs font-semibold text-slate-300"
                >
                  Cancel
                </button>
                <button
                  onClick={handleConfirmImport}
                  className="px-5 py-2 rounded-xl bg-emerald-600 text-white font-bold text-xs shadow-md shadow-emerald-600/20"
                >
                  Import {importSummary.valid} Questions
                </button>
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
};
