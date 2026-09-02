import React, { useState } from 'react';
import { MOCK_EXAMS, MOCK_SUBJECTS, MOCK_CHAPTERS } from '../../lib/mockData';
import { Layers, Plus, Trash2, Edit2, ChevronRight, Check } from 'lucide-react';

export const TaxonomyManagerView: React.FC = () => {
  const [exams, setExams] = useState(MOCK_EXAMS);
  const [selectedExamId, setSelectedExamId] = useState(MOCK_EXAMS[0].id);
  const [newExamName, setNewExamName] = useState('');
  const [showAddExamModal, setShowAddExamModal] = useState(false);

  const handleAddExam = () => {
    if (!newExamName.trim()) return;
    const newExam = {
      id: 'e_' + Date.now(),
      name: newExamName,
      code: newExamName.toUpperCase().replace(/\s+/g, '_'),
      description: 'Newly added competitive examination',
      is_active: true,
      display_order: exams.length + 1,
    };
    setExams([...exams, newExam]);
    setNewExamName('');
    setShowAddExamModal(false);
  };

  const filteredSubjects = MOCK_SUBJECTS.filter((s) => s.exam_id === selectedExamId);

  return (
    <div className="space-y-6">
      <div className="bg-slate-900/90 border border-slate-800 rounded-2xl p-6 flex items-center justify-between">
        <div>
          <h2 className="text-xl font-bold text-white flex items-center gap-2">
            <Layers className="w-5 h-5 text-emerald-400" /> Dynamic Exam Hierarchy Taxonomy
          </h2>
          <p className="text-xs text-slate-400">
            Structure: <span className="text-slate-200 font-semibold">Exam → Subject → Chapter → Topic → Subtopic</span>
          </p>
        </div>

        <button
          onClick={() => setShowAddExamModal(true)}
          className="px-4 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white text-xs font-bold flex items-center gap-1.5 shadow-md shadow-emerald-600/20"
        >
          <Plus className="w-4 h-4" /> Add New Exam
        </button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Exams List (Col 1) */}
        <div className="bg-slate-900/90 border border-slate-800 rounded-2xl p-4 space-y-3">
          <h3 className="text-xs font-bold text-slate-400 uppercase tracking-wider px-2">Exams</h3>
          <div className="space-y-1">
            {exams.map((ex) => {
              const isSelected = ex.id === selectedExamId;
              return (
                <button
                  key={ex.id}
                  onClick={() => setSelectedExamId(ex.id)}
                  className={`w-full text-left p-3 rounded-xl border text-xs font-bold flex items-center justify-between transition-all ${
                    isSelected
                      ? 'bg-emerald-600/10 border-emerald-500 text-emerald-400'
                      : 'bg-slate-950 border-slate-800 text-slate-300 hover:border-slate-700'
                  }`}
                >
                  <span>{ex.name}</span>
                  <ChevronRight className="w-4 h-4" />
                </button>
              );
            })}
          </div>
        </div>

        {/* Subjects & Chapters Tree (Col 2 & 3) */}
        <div className="lg:col-span-2 bg-slate-900/90 border border-slate-800 rounded-2xl p-6 space-y-4">
          <div className="flex items-center justify-between border-b border-slate-800 pb-3">
            <h3 className="text-sm font-bold text-white">
              Subjects for {exams.find((e) => e.id === selectedExamId)?.name}
            </h3>
            <button className="px-3 py-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-xs font-semibold text-slate-200 flex items-center gap-1">
              <Plus className="w-3.5 h-3.5" /> Add Subject
            </button>
          </div>

          <div className="space-y-3">
            {filteredSubjects.length > 0 ? (
              filteredSubjects.map((sub) => (
                <div key={sub.id} className="bg-slate-950 p-4 rounded-xl border border-slate-800 space-y-3">
                  <div className="flex items-center justify-between">
                    <span className="text-xs font-bold text-slate-200 flex items-center gap-2">
                      <span
                        className="w-2.5 h-2.5 rounded-full"
                        style={{ backgroundColor: sub.color_hex }}
                      />
                      {sub.name}
                    </span>
                    <button className="text-[11px] text-blue-400 font-semibold hover:underline">
                      + Add Chapter
                    </button>
                  </div>

                  {/* Chapters List */}
                  <div className="pl-4 border-l border-slate-800 space-y-1">
                    {MOCK_CHAPTERS.filter((c) => c.subject_id === sub.id).map((chap) => (
                      <div
                        key={chap.id}
                        className="p-2 rounded-lg bg-slate-900/80 text-xs text-slate-300 flex justify-between items-center"
                      >
                        <span>{chap.name} (Class {chap.class_level})</span>
                        <div className="flex gap-2">
                          <button className="text-[10px] text-slate-400 hover:text-slate-200">Edit</button>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              ))
            ) : (
              <p className="text-xs text-slate-500 py-4 text-center">No subjects defined for this exam yet.</p>
            )}
          </div>
        </div>
      </div>

      {/* Add Exam Modal */}
      {showAddExamModal && (
        <div className="fixed inset-0 bg-slate-950/80 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl max-w-md w-full p-6 space-y-4">
            <h3 className="text-base font-bold text-white">Add New Competitive Exam</h3>
            <div className="space-y-1">
              <label className="text-xs font-bold text-slate-300">Exam Name</label>
              <input
                type="text"
                value={newExamName}
                onChange={(e) => setNewExamName(e.target.value)}
                placeholder="e.g. UPSC CSE, SSC CGL, Banking PO"
                className="w-full bg-slate-950 border border-slate-800 rounded-xl p-3 text-xs text-slate-100 focus:border-emerald-500 focus:outline-none"
              />
            </div>

            <div className="flex justify-end gap-2">
              <button
                onClick={() => setShowAddExamModal(false)}
                className="px-4 py-2 rounded-xl bg-slate-800 text-xs font-semibold text-slate-300"
              >
                Cancel
              </button>
              <button
                onClick={handleAddExam}
                className="px-4 py-2 rounded-xl bg-emerald-600 text-xs font-bold text-white"
              >
                Save Exam
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
