import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  ArrowLeft,
  Atom,
  FlaskConical,
  Leaf,
  Zap,
  ClipboardList,
  ArrowRight,
  Check,
  Sparkles,
} from 'lucide-react';

interface NewPracticeWizardProps {
  onBack?: () => void;
  onStartSession?: (config: any) => void;
  isMobileFrame?: boolean;
}

export const NewPracticeWizard: React.FC<NewPracticeWizardProps> = ({
  onBack,
  onStartSession,
  isMobileFrame = false,
}) => {
  const navigate = useNavigate();
  const [currentStep, setCurrentStep] = useState<1 | 2 | 3>(1);

  // Step 1 State: Subjects, Exam, Mode
  const [selectedSubjects, setSelectedSubjects] = useState<string[]>(['physics', 'chemistry', 'biology']);
  const [selectedExam, setSelectedExam] = useState<string>('neet');
  const [selectedMode, setSelectedMode] = useState<'practice' | 'test'>('practice');

  // Step 2 State: Preferences
  const [difficulty, setDifficulty] = useState<'all' | 'easy' | 'medium' | 'hard'>('medium');
  const [questionCount, setQuestionCount] = useState<number>(20);
  const [questionSource, setQuestionSource] = useState<'all' | 'unattempted' | 'incorrect'>('all');

  const subjects = [
    {
      id: 'physics',
      name: 'Physics',
      icon: Atom,
      badgeBg: 'bg-[#10B981]',
      cardBorder: 'border border-emerald-300 bg-[#F0FDF4]',
    },
    {
      id: 'chemistry',
      name: 'Chemistry',
      icon: FlaskConical,
      badgeBg: 'bg-[#3B82F6]',
      cardBorder: 'border border-blue-200 bg-[#EFF6FF]',
    },
    {
      id: 'mathematics',
      name: 'Mathematics',
      customMathIcon: true,
      badgeBg: 'bg-[#F97316]',
      cardBorder: 'border border-orange-200 bg-[#FFF7ED]',
    },
    {
      id: 'biology',
      name: 'Biology',
      icon: Leaf,
      badgeBg: 'bg-[#8B5CF6]',
      cardBorder: 'border border-purple-200 bg-[#FAF5FF]',
    },
  ];

  const exams = [
    { id: 'neet', label: 'NEET UG 2026' },
    { id: 'jee_main', label: 'JEE Main 2026' },
    { id: 'jee_advanced', label: 'JEE Advanced' },
    { id: 'other', label: 'Other Exams' },
  ];

  const toggleSubject = (id: string) => {
    setSelectedSubjects((prev) =>
      prev.includes(id) ? prev.filter((s) => s !== id) : [...prev, id]
    );
  };

  const toggleSelectAllSubjects = () => {
    if (selectedSubjects.length === subjects.length) {
      setSelectedSubjects([]);
    } else {
      setSelectedSubjects(subjects.map((s) => s.id));
    }
  };

  const handleBack = () => {
    if (currentStep > 1) {
      setCurrentStep((prev) => (prev - 1) as any);
    } else if (onBack) {
      onBack();
    } else {
      navigate(-1);
    }
  };

  const handleNext = () => {
    if (currentStep === 1) {
      setCurrentStep(2);
    } else if (currentStep === 2) {
      setCurrentStep(3);
    } else {
      if (onStartSession) {
        onStartSession({
          sessionId: `session_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
          isNewSession: true,
          subjects: selectedSubjects,
          exam: selectedExam,
          mode: selectedMode,
          difficulty,
          questionCount,
          questionSource,
        });
      } else {
        navigate('/student/practice');
      }
    }
  };

  return (
    <div className={`w-full font-sans text-slate-900 bg-white select-none pb-8 ${isMobileFrame ? 'px-0 py-0' : 'max-w-md mx-auto p-4 md:p-6'}`}>
      
      {/* 1. TOP HEADER WITH ARROW BACK & TITLE */}
      <div className="flex items-center gap-3 p-4 pb-2 border-b border-slate-100 sticky top-0 bg-white z-20">
        <button
          onClick={handleBack}
          className="p-1 text-slate-900 hover:text-[#5D3EED] transition-colors"
        >
          <ArrowLeft className="w-5.5 h-5.5 stroke-[2.5]" />
        </button>
        <h1 className="text-xl font-black text-slate-900 tracking-tight">New Practice</h1>
      </div>

      <div className="p-4 space-y-6">

        {/* 2. STEPPER PROGRESS BAR (1 -> 2 -> 3) */}
        <div className="px-2 pt-1">
          <div className="flex items-center justify-between relative max-w-xs mx-auto">
            {/* Step 1 */}
            <div className="flex flex-col items-center gap-1.5 z-10">
              <div
                className={`w-9 h-9 rounded-full flex items-center justify-center font-black text-sm transition-all ${
                  currentStep >= 1 ? 'bg-[#5D3EED] text-white shadow-md shadow-purple-600/30' : 'bg-slate-100 text-slate-400 border border-slate-200'
                }`}
              >
                1
              </div>
              <span className={`text-xs font-extrabold ${currentStep === 1 ? 'text-[#5D3EED]' : 'text-slate-400'}`}>
                Select
              </span>
            </div>

            {/* Line 1 -> 2 */}
            <div className="flex-1 h-[2px] mx-2 bg-slate-200 relative -top-3">
              <div
                className="h-full bg-[#5D3EED] transition-all duration-300"
                style={{ width: currentStep >= 2 ? '100%' : '0%' }}
              />
            </div>

            {/* Step 2 */}
            <div className="flex flex-col items-center gap-1.5 z-10">
              <div
                className={`w-9 h-9 rounded-full flex items-center justify-center font-black text-sm transition-all ${
                  currentStep >= 2 ? 'bg-[#5D3EED] text-white shadow-md shadow-purple-600/30' : 'bg-white text-slate-400 border-2 border-slate-200'
                }`}
              >
                2
              </div>
              <span className={`text-xs font-extrabold ${currentStep === 2 ? 'text-[#5D3EED]' : 'text-slate-400'}`}>
                Preferences
              </span>
            </div>

            {/* Line 2 -> 3 */}
            <div className="flex-1 h-[2px] mx-2 bg-slate-200 relative -top-3">
              <div
                className="h-full bg-[#5D3EED] transition-all duration-300"
                style={{ width: currentStep >= 3 ? '100%' : '0%' }}
              />
            </div>

            {/* Step 3 */}
            <div className="flex flex-col items-center gap-1.5 z-10">
              <div
                className={`w-9 h-9 rounded-full flex items-center justify-center font-black text-sm transition-all ${
                  currentStep >= 3 ? 'bg-[#5D3EED] text-white shadow-md shadow-purple-600/30' : 'bg-white text-slate-400 border-2 border-slate-200'
                }`}
              >
                3
              </div>
              <span className={`text-xs font-extrabold ${currentStep === 3 ? 'text-[#5D3EED]' : 'text-slate-400'}`}>
                Start
              </span>
            </div>
          </div>
        </div>

        {/* ========================================================================= */}
        {/* STEP 1: SELECT SUBJECTS, EXAM & MODE */}
        {/* ========================================================================= */}
        {currentStep === 1 && (
          <div className="space-y-6">
            
            {/* Section 1: Select Subjects */}
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <div>
                  <h2 className="text-base font-black text-slate-900">Select Subjects</h2>
                  <p className="text-xs text-slate-400 font-bold">You can select multiple subjects</p>
                </div>
                <button
                  onClick={toggleSelectAllSubjects}
                  className="text-xs font-extrabold text-[#5D3EED] hover:underline transition-colors"
                >
                  {selectedSubjects.length === subjects.length ? 'Deselect All' : 'Select All'}
                </button>
              </div>

              <div className="grid grid-cols-2 gap-3">
                {subjects.map((item) => {
                  const Icon = item.icon;
                  const isSelected = selectedSubjects.includes(item.id);

                  return (
                    <div
                      key={item.id}
                      onClick={() => toggleSubject(item.id)}
                      className={`p-3.5 rounded-2xl border transition-all cursor-pointer flex items-center justify-between gap-2 shadow-2xs ${
                        isSelected
                          ? item.cardBorder
                          : 'border-slate-200 bg-white hover:border-slate-300'
                      }`}
                    >
                      <div className="flex items-center gap-2.5">
                        <div className={`w-9 h-9 rounded-full flex items-center justify-center text-white ${item.badgeBg} shadow-2xs`}>
                          {item.customMathIcon ? (
                            <span className="font-black text-[10px] leading-tight font-mono text-center">+-<br />x÷</span>
                          ) : (
                            Icon && <Icon className="w-5 h-5 text-white" />
                          )}
                        </div>
                        <span className="text-sm font-extrabold text-slate-900">{item.name}</span>
                      </div>

                      <div className="flex-shrink-0">
                        {isSelected ? (
                          <div className="w-5 h-5 rounded-full bg-[#5D3EED] text-white flex items-center justify-center shadow-2xs">
                            <Check className="w-3.5 h-3.5 stroke-[3]" />
                          </div>
                        ) : (
                          <div className="w-5 h-5 rounded-full border-2 border-slate-300 bg-white" />
                        )}
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>

            {/* Section 2: Select Exam */}
            <div className="space-y-3 pt-1">
              <h2 className="text-base font-black text-slate-900">Select Exam</h2>

              <div className="space-y-2.5">
                {exams.map((exam) => {
                  const isSelected = selectedExam === exam.id;

                  return (
                    <div
                      key={exam.id}
                      onClick={() => setSelectedExam(exam.id)}
                      className={`p-3.5 rounded-2xl border transition-all cursor-pointer flex items-center justify-between ${
                        isSelected
                          ? 'border-2 border-[#5D3EED] bg-[#F5F3FF]'
                          : 'border border-slate-200 bg-white hover:border-slate-300'
                      }`}
                    >
                      <span className={`text-sm font-extrabold ${isSelected ? 'text-[#5D3EED]' : 'text-slate-800'}`}>
                        {exam.label}
                      </span>

                      {isSelected ? (
                        <div className="w-5.5 h-5.5 rounded-full bg-[#5D3EED] text-white flex items-center justify-center shadow-2xs">
                          <Check className="w-3.5 h-3.5 stroke-[3]" />
                        </div>
                      ) : (
                        <div className="w-2.5 h-2.5 rounded-full bg-slate-300 mr-1.5" />
                      )}
                    </div>
                  );
                })}
              </div>
            </div>

            {/* Section 3: Select Mode */}
            <div className="space-y-3 pt-1">
              <h2 className="text-base font-black text-slate-900">Select Mode</h2>

              <div className="space-y-3">
                {/* Practice Mode Option */}
                <div
                  onClick={() => setSelectedMode('practice')}
                  className={`p-4 rounded-3xl border transition-all cursor-pointer flex items-start gap-3.5 ${
                    selectedMode === 'practice'
                      ? 'border-2 border-[#5D3EED] bg-[#F5F3FF]'
                      : 'border border-slate-200 bg-white hover:border-slate-300'
                  }`}
                >
                  <div className="w-11 h-11 rounded-2xl bg-[#EDE9FE] text-[#5D3EED] flex items-center justify-center flex-shrink-0">
                    <Zap className="w-5.5 h-5.5 fill-[#5D3EED] text-[#5D3EED]" />
                  </div>
                  <div className="space-y-0.5">
                    <h4 className="text-sm font-black text-[#5D3EED]">Practice Mode</h4>
                    <p className="text-xs text-slate-500 font-bold leading-relaxed">
                      Learn and improve with instant explanations
                    </p>
                  </div>
                </div>

                {/* Test Mode Option */}
                <div
                  onClick={() => setSelectedMode('test')}
                  className={`p-4 rounded-3xl border transition-all cursor-pointer flex items-start gap-3.5 ${
                    selectedMode === 'test'
                      ? 'border-2 border-[#5D3EED] bg-[#F5F3FF]'
                      : 'border border-slate-200 bg-white hover:border-slate-300'
                  }`}
                >
                  <div className="w-11 h-11 rounded-2xl bg-[#FFF7ED] text-[#F97316] flex items-center justify-center flex-shrink-0">
                    <ClipboardList className="w-5.5 h-5.5 text-[#F97316]" />
                  </div>
                  <div className="space-y-0.5">
                    <h4 className="text-sm font-black text-slate-900">Test Mode</h4>
                    <p className="text-xs text-slate-500 font-bold leading-relaxed">
                      Attempt like real exam, no instant results
                    </p>
                  </div>
                </div>
              </div>
            </div>

            {/* Primary Action Button */}
            <div className="pt-2">
              <button
                onClick={handleNext}
                disabled={selectedSubjects.length === 0}
                className="w-full py-4 bg-[#5D3EED] hover:bg-[#4F46E5] disabled:opacity-50 text-white font-extrabold rounded-2xl shadow-lg shadow-indigo-600/30 flex items-center justify-center gap-2 text-base transition-all active:scale-98"
              >
                <span>Next: Preferences</span>
                <ArrowRight className="w-5 h-5 stroke-[2.5]" />
              </button>
            </div>
          </div>
        )}

        {/* ========================================================================= */}
        {/* STEP 2: PREFERENCES */}
        {/* ========================================================================= */}
        {currentStep === 2 && (
          <div className="space-y-6">
            {/* Question Count Selection */}
            <div className="space-y-3">
              <h2 className="text-base font-black text-slate-900">Number of Questions</h2>
              <div className="grid grid-cols-4 gap-2">
                {[10, 20, 30, 50].map((count) => (
                  <button
                    key={count}
                    onClick={() => setQuestionCount(count)}
                    className={`py-3 rounded-2xl border font-extrabold text-xs transition-all ${
                      questionCount === count
                        ? 'bg-[#5D3EED] text-white border-[#5D3EED] shadow-md shadow-purple-600/30'
                        : 'bg-white text-slate-700 border-slate-200 hover:border-slate-300'
                    }`}
                  >
                    {count} Qs
                  </button>
                ))}
              </div>
            </div>

            {/* Difficulty Level */}
            <div className="space-y-3">
              <h2 className="text-base font-black text-slate-900">Difficulty Level</h2>
              <div className="grid grid-cols-3 gap-2">
                {[
                  { id: 'easy', label: 'Easy' },
                  { id: 'medium', label: 'Medium' },
                  { id: 'hard', label: 'Hard' },
                ].map((item) => (
                  <button
                    key={item.id}
                    onClick={() => setDifficulty(item.id as any)}
                    className={`py-3 rounded-2xl border font-extrabold text-xs transition-all ${
                      difficulty === item.id
                        ? 'bg-[#5D3EED] text-white border-[#5D3EED] shadow-md shadow-purple-600/30'
                        : 'bg-white text-slate-700 border-slate-200 hover:border-slate-300'
                    }`}
                  >
                    {item.label}
                  </button>
                ))}
              </div>
            </div>

            {/* Question Source Filter */}
            <div className="space-y-3">
              <h2 className="text-base font-black text-slate-900">Question Source</h2>
              <div className="space-y-2.5">
                {[
                  { id: 'all', label: 'All Available Questions', desc: 'Mix of new and previously attempted questions' },
                  { id: 'unattempted', label: 'Unattempted Only', desc: 'Fresh questions you have never seen before' },
                  { id: 'incorrect', label: 'Past Mistakes', desc: 'Questions you got wrong in previous tests' },
                ].map((item) => (
                  <div
                    key={item.id}
                    onClick={() => setQuestionSource(item.id as any)}
                    className={`p-3.5 rounded-2xl border transition-all cursor-pointer flex items-center justify-between ${
                      questionSource === item.id
                        ? 'border-2 border-[#5D3EED] bg-[#F5F3FF]'
                        : 'border border-slate-200 bg-white hover:border-slate-300'
                    }`}
                  >
                    <div>
                      <h4 className="text-xs font-extrabold text-slate-900">{item.label}</h4>
                      <p className="text-[10px] text-slate-500 font-bold mt-0.5">{item.desc}</p>
                    </div>
                    {questionSource === item.id ? (
                      <div className="w-5 h-5 rounded-full bg-[#5D3EED] text-white flex items-center justify-center shadow-2xs">
                        <Check className="w-3.5 h-3.5 stroke-[3]" />
                      </div>
                    ) : (
                      <div className="w-5 h-5 rounded-full border-2 border-slate-300 bg-white" />
                    )}
                  </div>
                ))}
              </div>
            </div>

            {/* Action Button */}
            <button
              onClick={handleNext}
              className="w-full py-4 bg-[#5D3EED] hover:bg-[#4F46E5] text-white font-extrabold rounded-2xl shadow-lg shadow-purple-600/30 flex items-center justify-center gap-2 text-base transition-all active:scale-98"
            >
              <span>Next: Start Session</span>
              <ArrowRight className="w-5 h-5 stroke-[2.5]" />
            </button>
          </div>
        )}

        {/* ========================================================================= */}
        {/* STEP 3: START SUMMARY */}
        {/* ========================================================================= */}
        {currentStep === 3 && (
          <div className="space-y-6">
            <div className="bg-gradient-to-r from-[#4F46E5] to-[#5D3EED] text-white p-5 rounded-3xl shadow-xl space-y-4">
              <div className="flex items-center gap-2">
                <Sparkles className="w-5 h-5 text-amber-300 fill-amber-300" />
                <h2 className="text-base font-black">Ready to Begin Practice!</h2>
              </div>

              <div className="space-y-2 text-xs divide-y divide-purple-400/30">
                <div className="flex justify-between py-1.5">
                  <span className="text-indigo-200 font-bold">Selected Subjects</span>
                  <span className="font-extrabold capitalize">{selectedSubjects.join(', ')}</span>
                </div>

                <div className="flex justify-between py-1.5">
                  <span className="text-indigo-200 font-bold">Target Exam</span>
                  <span className="font-extrabold uppercase">{selectedExam}</span>
                </div>

                <div className="flex justify-between py-1.5">
                  <span className="text-indigo-200 font-bold">Practice Mode</span>
                  <span className="font-extrabold capitalize">{selectedMode} Mode</span>
                </div>

                <div className="flex justify-between py-1.5">
                  <span className="text-indigo-200 font-bold">Questions Count</span>
                  <span className="font-extrabold text-amber-300">{questionCount} Questions</span>
                </div>

                <div className="flex justify-between py-1.5">
                  <span className="text-indigo-200 font-bold">Difficulty</span>
                  <span className="font-extrabold capitalize">{difficulty}</span>
                </div>
              </div>
            </div>

            <button
              onClick={handleNext}
              className="w-full py-4 bg-[#5D3EED] hover:bg-[#4F46E5] text-white font-extrabold rounded-2xl shadow-xl shadow-purple-600/30 flex items-center justify-center gap-2 text-base transition-all active:scale-95"
            >
              <span>Start Practice Session 🚀</span>
            </button>
          </div>
        )}

      </div>
    </div>
  );
};
