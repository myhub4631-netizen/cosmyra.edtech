import React, { useState } from 'react';
import { MOCK_QUESTIONS, MOCK_SUBJECTS, MOCK_CHAPTERS } from '../../lib/mockData';
import { MathText } from '../../components/common/MathText';
import { PlusCircle, CheckCircle2, Trash2, Link, Sparkles, Filter, Eye } from 'lucide-react';

export const CreateTestWizard: React.FC<{ onComplete: () => void }> = ({ onComplete }) => {
  const [step, setStep] = useState<number>(1);
  const [testTitle, setTestTitle] = useState<string>('NEET 2026 Physics Friction Sprint Test');
  const [testDesc, setTestDesc] = useState<string>('Chapterwise mock test focusing on Laws of motion and limiting friction.');
  const [durationMinutes, setDurationMinutes] = useState<number>(45);
  const [selectedQuestionIds, setSelectedQuestionIds] = useState<string[]>(['q1111111-1111-1111-1111-111111111111']);
  const [generatedCode, setGeneratedCode] = useState<string>('');

  const toggleQuestionSelection = (qId: string) => {
    setSelectedQuestionIds((prev) =>
      prev.includes(qId) ? prev.filter((id) => id !== qId) : [...prev, qId]
    );
  };

  const handlePublish = () => {
    const code = 'TEST' + Math.random().toString(36).substring(2, 8).toUpperCase();
    setGeneratedCode(code);
    setStep(3);
  };

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      {/* Wizard Step Indicator */}
      <div className="flex items-center justify-between bg-slate-900/90 border border-slate-800 rounded-2xl p-4">
        <div className="flex items-center gap-3">
          <div
            className={`w-8 h-8 rounded-full font-bold text-xs flex items-center justify-center ${
              step >= 1 ? 'bg-purple-600 text-white' : 'bg-slate-800 text-slate-400'
            }`}
          >
            1
          </div>
          <span className="text-xs font-semibold text-slate-200">1. Test Settings</span>
        </div>

        <div className="w-12 h-0.5 bg-slate-800" />

        <div className="flex items-center gap-3">
          <div
            className={`w-8 h-8 rounded-full font-bold text-xs flex items-center justify-center ${
              step >= 2 ? 'bg-purple-600 text-white' : 'bg-slate-800 text-slate-400'
            }`}
          >
            2
          </div>
          <span className="text-xs font-semibold text-slate-200">2. Select Questions</span>
        </div>

        <div className="w-12 h-0.5 bg-slate-800" />

        <div className="flex items-center gap-3">
          <div
            className={`w-8 h-8 rounded-full font-bold text-xs flex items-center justify-center ${
              step === 3 ? 'bg-emerald-600 text-white' : 'bg-slate-800 text-slate-400'
            }`}
          >
            3
          </div>
          <span className="text-xs font-semibold text-slate-200">3. Publish & Invite</span>
        </div>
      </div>

      {/* Step 1: Test Details */}
      {step === 1 && (
        <div className="bg-slate-900/90 border border-slate-800 rounded-2xl p-6 space-y-4">
          <h3 className="text-base font-bold text-white">Test Configuration</h3>

          <div className="space-y-1">
            <label className="text-xs font-bold text-slate-300">Test Title</label>
            <input
              type="text"
              value={testTitle}
              onChange={(e) => setTestTitle(e.target.value)}
              className="w-full bg-slate-950 border border-slate-800 rounded-xl p-3 text-xs text-slate-100 focus:border-purple-500 focus:outline-none"
            />
          </div>

          <div className="space-y-1">
            <label className="text-xs font-bold text-slate-300">Test Instructions / Description</label>
            <textarea
              value={testDesc}
              onChange={(e) => setTestDesc(e.target.value)}
              className="w-full bg-slate-950 border border-slate-800 rounded-xl p-3 text-xs text-slate-100 focus:border-purple-500 focus:outline-none h-20"
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-1">
              <label className="text-xs font-bold text-slate-300">Duration (Minutes)</label>
              <input
                type="number"
                value={durationMinutes}
                onChange={(e) => setDurationMinutes(Number(e.target.value))}
                className="w-full bg-slate-950 border border-slate-800 rounded-xl p-3 text-xs text-slate-100 focus:border-purple-500 focus:outline-none"
              />
            </div>

            <div className="space-y-1">
              <label className="text-xs font-bold text-slate-300">Negative Marking</label>
              <select className="w-full bg-slate-950 border border-slate-800 rounded-xl p-3 text-xs text-slate-100 focus:border-purple-500 focus:outline-none">
                <option value="1">-1 Mark per incorrect answer</option>
                <option value="0">No negative marking</option>
              </select>
            </div>
          </div>

          <button
            onClick={() => setStep(2)}
            className="w-full py-3 rounded-xl bg-purple-600 text-white font-bold text-xs hover:bg-purple-500 transition-all"
          >
            Next: Select Questions from Bank
          </button>
        </div>
      )}

      {/* Step 2: Question Selector */}
      {step === 2 && (
        <div className="bg-slate-900/90 border border-slate-800 rounded-2xl p-6 space-y-4">
          <div className="flex items-center justify-between">
            <h3 className="text-base font-bold text-white">Select Questions from Centralized Bank</h3>
            <span className="text-xs font-bold text-purple-400">
              {selectedQuestionIds.length} Questions Selected
            </span>
          </div>

          <div className="space-y-3">
            {MOCK_QUESTIONS.map((q) => {
              const isSelected = selectedQuestionIds.includes(q.id);
              return (
                <div
                  key={q.id}
                  onClick={() => toggleQuestionSelection(q.id)}
                  className={`p-4 rounded-xl border cursor-pointer transition-all ${
                    isSelected
                      ? 'bg-purple-600/10 border-purple-500 text-white'
                      : 'bg-slate-950 border-slate-800 text-slate-300 hover:border-slate-700'
                  }`}
                >
                  <div className="flex items-start justify-between gap-3">
                    <div className="space-y-2">
                      <div className="flex items-center gap-2 text-[10px] font-bold uppercase">
                        <span className="px-2 py-0.5 rounded bg-slate-800 text-slate-300">{q.source}</span>
                        <span className="text-purple-400">{q.difficulty}</span>
                      </div>
                      <div className="text-xs font-medium">
                        <MathText text={q.question_text} />
                      </div>
                    </div>

                    <div
                      className={`w-6 h-6 rounded-lg border flex items-center justify-center ${
                        isSelected ? 'bg-purple-600 border-purple-500 text-white' : 'border-slate-800'
                      }`}
                    >
                      {isSelected && <CheckCircle2 className="w-4 h-4" />}
                    </div>
                  </div>
                </div>
              );
            })}
          </div>

          <div className="flex justify-between pt-4 border-t border-slate-800">
            <button
              onClick={() => setStep(1)}
              className="px-4 py-2 rounded-xl bg-slate-800 text-xs font-semibold text-slate-300"
            >
              Back
            </button>
            <button
              disabled={selectedQuestionIds.length === 0}
              onClick={handlePublish}
              className="px-6 py-2.5 rounded-xl bg-emerald-600 disabled:opacity-40 hover:bg-emerald-500 text-white font-bold text-xs shadow-md shadow-emerald-600/20"
            >
              Publish Test & Generate Link
            </button>
          </div>
        </div>
      )}

      {/* Step 3: Success Screen */}
      {step === 3 && (
        <div className="bg-slate-900/90 border border-slate-800 rounded-2xl p-8 text-center space-y-4">
          <div className="w-16 h-16 rounded-full bg-emerald-500/10 text-emerald-400 mx-auto flex items-center justify-center">
            <CheckCircle2 className="w-8 h-8" />
          </div>
          <h3 className="text-xl font-bold text-white">Test Published Successfully!</h3>
          <p className="text-xs text-slate-400">Share the invitation code or link below with your students.</p>

          <div className="max-w-md mx-auto bg-slate-950 p-4 rounded-xl border border-slate-800 flex items-center justify-between">
            <span className="font-mono font-bold text-base text-purple-400">{generatedCode}</span>
            <button
              onClick={() => {
                navigator.clipboard.writeText(`https://cosmyra.ai/invite/test/${generatedCode}`);
                alert('Copied invite link to clipboard!');
              }}
              className="px-3 py-1.5 rounded-lg bg-purple-600 text-white text-xs font-bold flex items-center gap-1.5"
            >
              <Link className="w-3.5 h-3.5" /> Copy Invite Link
            </button>
          </div>

          <button
            onClick={onComplete}
            className="mt-4 px-6 py-2.5 rounded-xl bg-slate-800 text-white font-bold text-xs hover:bg-slate-700"
          >
            Return to Teacher Dashboard
          </button>
        </div>
      )}
    </div>
  );
};
