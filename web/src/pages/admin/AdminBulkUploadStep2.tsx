import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  ChevronRight,
  ArrowLeft,
  Check,
  ChevronUp,
  ChevronDown,
  Copy,
  Trash2,
  Bold,
  Italic,
  Underline,
  List,
  ListOrdered,
  Image as ImageIcon,
  Plus,
  ArrowRight,
} from 'lucide-react';

interface QuestionItem {
  id: number;
  text: string;
  options: string[];
  correctOptionIndex: number;
  explanation: string;
  difficulty: string;
  positiveMarks: string;
  negativeMarks: string;
  questionType: string;
  chapterTopic: string;
  isMarkedForReview: boolean;
  isCollapsed: boolean;
}

export const AdminBulkUploadStep2: React.FC = () => {
  const navigate = useNavigate();

  const totalQuestionsCount = 200;
  const [addedCount, setAddedCount] = useState<number>(0);
  const [currentPage, setCurrentPage] = useState<number>(1);
  const [itemsPerPage, setItemsPerPage] = useState<number>(10);
  const [jumpToNumber, setJumpToNumber] = useState<number>(1);

  // Initialize questions
  const [questions, setQuestions] = useState<QuestionItem[]>(
    Array.from({ length: totalQuestionsCount }, (_, i) => ({
      id: i + 1,
      text: '',
      options: ['', '', '', ''],
      correctOptionIndex: -1,
      explanation: '',
      difficulty: '',
      positiveMarks: '4',
      negativeMarks: '-1',
      questionType: 'MCQ (Single Correct)',
      chapterTopic: '',
      isMarkedForReview: false,
      isCollapsed: false,
    }))
  );

  const remainingCount = questions.length - addedCount;
  const progressPercent = Math.round((addedCount / questions.length) * 100);

  const handleAddOption = (qId: number) => {
    setQuestions((prev) =>
      prev.map((q) => {
        if (q.id === qId && q.options.length < 6) {
          return { ...q, options: [...q.options, ''] };
        }
        return q;
      })
    );
  };

  const handleOptionChange = (qId: number, optIdx: number, value: string) => {
    setQuestions((prev) =>
      prev.map((q) => {
        if (q.id === qId) {
          const newOpts = [...q.options];
          newOpts[optIdx] = value;
          return { ...q, options: newOpts };
        }
        return q;
      })
    );
  };

  const handleDuplicate = (qId: number) => {
    const targetIdx = questions.findIndex((q) => q.id === qId);
    if (targetIdx !== -1) {
      const source = questions[targetIdx];
      const newQuestion: QuestionItem = {
        ...source,
        id: questions.length + 1,
        options: [...source.options],
      };
      const updated = [...questions];
      updated.splice(targetIdx + 1, 0, newQuestion);
      // Re-index
      const reindexed = updated.map((q, idx) => ({ ...q, id: idx + 1 }));
      setQuestions(reindexed);
    }
  };

  const handleDelete = (qId: number) => {
    if (questions.length > 1) {
      const filtered = questions.filter((q) => q.id !== qId);
      const reindexed = filtered.map((q, idx) => ({ ...q, id: idx + 1 }));
      setQuestions(reindexed);
    }
  };

  const toggleCollapse = (qId: number) => {
    setQuestions((prev) =>
      prev.map((q) => (q.id === qId ? { ...q, isCollapsed: !q.isCollapsed } : q))
    );
  };

  const toggleReview = (qId: number) => {
    setQuestions((prev) =>
      prev.map((q) => (q.id === qId ? { ...q, isMarkedForReview: !q.isMarkedForReview } : q))
    );
  };

  const handleSaveQuestion = (qId: number) => {
    setAddedCount((prev) => Math.min(prev + 1, questions.length));
  };

  const handleJump = () => {
    const targetPage = Math.floor((jumpToNumber - 1) / itemsPerPage) + 1;
    setCurrentPage(targetPage);
  };

  const startIndex = (currentPage - 1) * itemsPerPage;
  const visibleQuestions = questions.slice(startIndex, startIndex + itemsPerPage);
  const totalPages = Math.ceil(questions.length / itemsPerPage);

  return (
    <div className="space-y-6 pb-16 font-sans bg-slate-50 min-h-screen text-slate-800">
      {/* Breadcrumb Header */}
      <div className="flex items-center gap-2 text-xs text-slate-500 font-medium">
        <span>Question & Paper Bank</span>
        <ChevronRight className="w-3.5 h-3.5 text-slate-400" />
        <span className="text-slate-700 font-semibold">Upload Questions</span>
      </div>

      {/* Page Title & Action Buttons Row */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 tracking-tight">
            Upload Questions in Bulk - Step 2 of 2
          </h1>
          <p className="text-xs text-slate-500 mt-1">
            Add all questions for NEET 2026 Phase 1. Total 200 questions.
          </p>
        </div>

        <div className="flex items-center gap-3">
          <button
            onClick={() => navigate('/admin/bulk-upload')}
            className="inline-flex items-center gap-2 px-4 py-2.5 bg-white border border-slate-300 text-slate-700 rounded-lg text-xs font-bold hover:bg-slate-50 transition-colors shadow-xs"
          >
            <ArrowLeft className="w-4 h-4 text-slate-600" />
            <span>Back to Step 1</span>
          </button>

          <button
            onClick={() => alert(`Saved all ${questions.length} questions successfully!`)}
            className="px-5 py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg text-xs font-bold shadow-md shadow-indigo-600/30 transition-all"
          >
            Save All Questions
          </button>
        </div>
      </div>

      {/* Stepper Indicator */}
      <div className="flex items-center justify-center my-6 max-w-lg mx-auto">
        {/* Step 1: Checkmark */}
        <div className="flex flex-col items-center gap-1.5">
          <div className="w-9 h-9 rounded-full bg-white border-2 border-indigo-600 text-indigo-600 font-bold text-sm flex items-center justify-center shadow-xs">
            <Check className="w-5 h-5 text-indigo-600 stroke-[3]" />
          </div>
          <span className="text-xs font-semibold text-indigo-600">Paper Details</span>
        </div>

        {/* Dashed Connecting Line */}
        <div className="flex-1 mx-4 mb-5 border-t-2 border-dashed border-indigo-500"></div>

        {/* Step 2: Active Solid 2 */}
        <div className="flex flex-col items-center gap-1.5">
          <div className="w-9 h-9 rounded-full bg-indigo-600 text-white font-bold text-sm flex items-center justify-center shadow-md shadow-indigo-500/20">
            2
          </div>
          <span className="text-xs font-bold text-indigo-600">Add Questions</span>
        </div>
      </div>

      {/* KPI Summary Metric Card */}
      <div className="bg-white rounded-xl border border-slate-200 p-5 shadow-xs grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 divide-y sm:divide-y-0 sm:divide-x divide-slate-100">
        <div className="pt-2 sm:pt-0">
          <span className="text-xs font-semibold text-slate-500 block">Total Questions</span>
          <span className="text-2xl font-black text-slate-900 block mt-1">{totalQuestionsCount}</span>
        </div>

        <div className="pt-4 sm:pt-0 sm:pl-6">
          <span className="text-xs font-semibold text-slate-500 block">Added</span>
          <span className="text-2xl font-black text-slate-900 block mt-1">{addedCount}</span>
        </div>

        <div className="pt-4 sm:pt-0 sm:pl-6">
          <span className="text-xs font-semibold text-slate-500 block">Remaining</span>
          <span className="text-2xl font-black text-slate-900 block mt-1">{remainingCount}</span>
        </div>

        <div className="pt-4 sm:pt-0 sm:pl-6">
          <span className="text-xs font-semibold text-slate-500 block">Progress</span>
          <div className="flex items-center gap-3 mt-1">
            <span className="text-base font-bold text-slate-900">{progressPercent}%</span>
            <div className="flex-1 h-2 bg-slate-100 rounded-full overflow-hidden">
              <div
                className="h-full bg-indigo-600 rounded-full transition-all duration-300"
                style={{ width: `${progressPercent}%` }}
              ></div>
            </div>
          </div>
        </div>
      </div>

      {/* Filter / Jump Toolbar Bar */}
      <div className="bg-white rounded-xl border border-slate-200 p-4 shadow-xs flex flex-wrap items-center justify-between gap-4">
        {/* Jump to Question */}
        <div className="flex items-center gap-3">
          <span className="text-xs font-semibold text-slate-700">Jump to Question</span>
          <select
            value={jumpToNumber}
            onChange={(e) => setJumpToNumber(Number(e.target.value))}
            className="text-xs font-medium border border-slate-300 rounded-lg px-3 py-1.5 bg-white text-slate-800 focus:outline-none focus:ring-2 focus:ring-indigo-500"
          >
            {questions.map((q) => (
              <option key={q.id} value={q.id}>
                {q.id}
              </option>
            ))}
          </select>
          <button
            onClick={handleJump}
            className="px-3.5 py-1.5 bg-indigo-50 text-indigo-600 rounded-lg text-xs font-bold hover:bg-indigo-100 transition-colors"
          >
            Go to
          </button>
        </div>

        {/* Show X per page, Bulk Actions, Auto Save ON */}
        <div className="flex items-center gap-4 flex-wrap">
          <div className="flex items-center gap-2">
            <span className="text-xs font-semibold text-slate-700">Show</span>
            <select
              value={itemsPerPage}
              onChange={(e) => setItemsPerPage(Number(e.target.value))}
              className="text-xs font-medium border border-slate-300 rounded-lg px-3 py-1.5 bg-white text-slate-800 focus:outline-none focus:ring-2 focus:ring-indigo-500"
            >
              <option value={5}>5 per page</option>
              <option value={10}>10 per page</option>
              <option value={20}>20 per page</option>
            </select>
          </div>

          <select className="text-xs font-medium border border-slate-300 rounded-lg px-3 py-1.5 bg-white text-slate-800 focus:outline-none focus:ring-2 focus:ring-indigo-500">
            <option value="bulk">Bulk Actions</option>
            <option value="clear">Clear All</option>
            <option value="delete">Delete Selected</option>
          </select>

          <div className="inline-flex items-center gap-1.5 px-3 py-1 bg-emerald-50 border border-emerald-200 text-emerald-700 rounded-full text-xs font-semibold">
            <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
            <span>Auto Save</span>
            <span className="font-bold text-emerald-800">ON</span>
          </div>
        </div>
      </div>

      {/* QUESTION CARDS LIST */}
      <div className="space-y-6">
        {visibleQuestions.map((q) => (
          <div key={q.id} className="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden">
            {/* Header Bar of Question Card */}
            <div className="bg-slate-50 px-6 py-3.5 border-b border-slate-200 flex items-center justify-between">
              <h2 className="text-base font-bold text-indigo-600">Question {q.id}</h2>

              <div className="flex items-center gap-1 text-slate-400">
                <button
                  onClick={() => toggleCollapse(q.id)}
                  className="p-1.5 hover:bg-slate-200 rounded-lg text-slate-600 transition-colors"
                  title="Collapse"
                >
                  {q.isCollapsed ? <ChevronDown className="w-4 h-4" /> : <ChevronUp className="w-4 h-4" />}
                </button>

                <button
                  onClick={() => handleDuplicate(q.id)}
                  className="p-1.5 hover:bg-slate-200 rounded-lg text-slate-600 transition-colors"
                  title="Duplicate Question"
                >
                  <Copy className="w-4 h-4" />
                </button>

                <button
                  onClick={() => handleDelete(q.id)}
                  className="p-1.5 hover:bg-red-50 text-red-500 rounded-lg transition-colors"
                  title="Delete Question"
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>
            </div>

            {/* Content Body of Question Card */}
            {!q.isCollapsed && (
              <div className="p-6 grid grid-cols-1 lg:grid-cols-12 gap-8">
                {/* Left Column (~7/12 = ~60%) */}
                <div className="lg:col-span-7 space-y-6">
                  {/* 1. Question Rich Text Editor */}
                  <div>
                    <label className="block text-xs font-bold text-slate-900 mb-2">1. Question</label>
                    <div className="border border-slate-300 rounded-lg overflow-hidden focus-within:ring-2 focus-within:ring-indigo-500">
                      {/* Editor Toolbar */}
                      <div className="bg-slate-50 px-3 py-2 border-b border-slate-200 flex items-center justify-between flex-wrap gap-2 text-slate-600">
                        <div className="flex items-center gap-3">
                          <button className="hover:text-slate-900 font-bold"><Bold className="w-3.5 h-3.5" /></button>
                          <button className="hover:text-slate-900 italic"><Italic className="w-3.5 h-3.5" /></button>
                          <button className="hover:text-slate-900 underline"><Underline className="w-3.5 h-3.5" /></button>
                          <span className="w-px h-4 bg-slate-300"></span>
                          <button className="hover:text-slate-900"><List className="w-3.5 h-3.5" /></button>
                          <button className="hover:text-slate-900"><ListOrdered className="w-3.5 h-3.5" /></button>
                          <span className="w-px h-4 bg-slate-300"></span>
                          <button className="text-xs font-bold hover:text-slate-900">x₂</button>
                          <button className="text-xs font-bold hover:text-slate-900">x²</button>
                          <span className="w-px h-4 bg-slate-300"></span>
                          <button className="hover:text-slate-900"><ImageIcon className="w-3.5 h-3.5" /></button>
                        </div>

                        <button className="inline-flex items-center gap-1.5 px-2.5 py-1 bg-white border border-slate-300 rounded text-xs font-semibold text-slate-700 hover:bg-slate-50">
                          <ImageIcon className="w-3.5 h-3.5 text-slate-500" />
                          <span>Add Image</span>
                        </button>
                      </div>

                      {/* Textarea */}
                      <textarea
                        rows={4}
                        value={q.text}
                        onChange={(e) =>
                          setQuestions((prev) =>
                            prev.map((item) => (item.id === q.id ? { ...item, text: e.target.value } : item))
                          )
                        }
                        placeholder="Type or paste your question here..."
                        className="w-full text-xs font-medium p-3 text-slate-900 border-none focus:outline-none resize-y"
                      ></textarea>
                    </div>
                  </div>

                  {/* 2. Options List */}
                  <div>
                    <div className="flex items-center justify-between mb-2">
                      <label className="text-xs font-bold text-slate-900">2. Options</label>
                      <span className="text-[11px] font-semibold text-slate-500">Is Correct?</span>
                    </div>

                    <div className="space-y-3">
                      {q.options.map((optVal, optIdx) => {
                        const letter = ['A', 'B', 'C', 'D', 'E', 'F'][optIdx];
                        return (
                          <div key={optIdx} className="flex items-center gap-3">
                            <div className="flex-1 flex items-center border border-slate-300 rounded-lg overflow-hidden focus-within:ring-2 focus-within:ring-indigo-500">
                              <span className="w-9 h-9 bg-slate-50 border-r border-slate-300 flex items-center justify-center text-xs font-bold text-slate-700 flex-shrink-0">
                                {letter}
                              </span>
                              <input
                                type="text"
                                value={optVal}
                                onChange={(e) => handleOptionChange(q.id, optIdx, e.target.value)}
                                placeholder={`Enter option ${letter}`}
                                className="w-full text-xs font-medium px-3 py-2 text-slate-900 focus:outline-none"
                              />
                            </div>

                            <input
                              type="radio"
                              name={`correct-opt-${q.id}`}
                              checked={q.correctOptionIndex === optIdx}
                              onChange={() =>
                                setQuestions((prev) =>
                                  prev.map((item) => (item.id === q.id ? { ...item, correctOptionIndex: optIdx } : item))
                                )
                              }
                              className="w-4 h-4 text-indigo-600 border-slate-300 focus:ring-indigo-500 cursor-pointer"
                            />
                          </div>
                        );
                      })}
                    </div>

                    <button
                      onClick={() => handleAddOption(q.id)}
                      className="mt-3 inline-flex items-center gap-1.5 px-3 py-1.5 bg-indigo-50 text-indigo-600 rounded-lg text-xs font-bold hover:bg-indigo-100 transition-colors"
                    >
                      <Plus className="w-4 h-4" />
                      <span>Add Option</span>
                    </button>
                  </div>
                </div>

                {/* Vertical Separator line on desktop */}
                <div className="hidden lg:block lg:col-span-1 border-r border-slate-100 my-2"></div>

                {/* Right Column (~4/12 = ~40%) */}
                <div className="lg:col-span-4 space-y-4">
                  {/* 3. Correct Answer */}
                  <div>
                    <label className="block text-xs font-bold text-slate-900 mb-1.5">3. Correct Answer</label>
                    <select
                      value={q.correctOptionIndex === -1 ? '' : q.correctOptionIndex}
                      onChange={(e) =>
                        setQuestions((prev) =>
                          prev.map((item) =>
                            item.id === q.id ? { ...item, correctOptionIndex: Number(e.target.value) } : item
                          )
                        )
                      }
                      className="w-full text-xs font-medium border border-slate-300 rounded-lg px-3 py-2 bg-white text-slate-800 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                    >
                      <option value="">Select Correct Option</option>
                      {q.options.map((_, idx) => (
                        <option key={idx} value={idx}>
                          Option {['A', 'B', 'C', 'D', 'E', 'F'][idx]}
                        </option>
                      ))}
                    </select>
                  </div>

                  {/* 4. Explanation */}
                  <div>
                    <label className="block text-xs font-bold text-slate-900 mb-1.5">
                      4. Explanation <span className="text-slate-500 font-normal">(Optional)</span>
                    </label>
                    <textarea
                      rows={3}
                      value={q.explanation}
                      onChange={(e) =>
                        setQuestions((prev) =>
                          prev.map((item) => (item.id === q.id ? { ...item, explanation: e.target.value } : item))
                        )
                      }
                      placeholder="Explain why this is the correct answer..."
                      className="w-full text-xs font-medium border border-slate-300 rounded-lg p-3 text-slate-900 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                    ></textarea>
                  </div>

                  {/* 5. Difficulty / Toughness */}
                  <div>
                    <label className="block text-xs font-bold text-slate-900 mb-1.5">5. Difficulty / Toughness</label>
                    <select
                      value={q.difficulty}
                      onChange={(e) =>
                        setQuestions((prev) =>
                          prev.map((item) => (item.id === q.id ? { ...item, difficulty: e.target.value } : item))
                        )
                      }
                      className="w-full text-xs font-medium border border-slate-300 rounded-lg px-3 py-2 bg-white text-slate-800 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                    >
                      <option value="">Select Difficulty</option>
                      <option value="Easy">Easy</option>
                      <option value="Medium">Medium</option>
                      <option value="Hard">Hard</option>
                    </select>
                  </div>

                  {/* 6. Marks */}
                  <div>
                    <label className="block text-xs font-bold text-slate-900 mb-1.5">6. Marks</label>
                    <div className="grid grid-cols-2 gap-3">
                      <div>
                        <span className="block text-[10px] font-semibold text-slate-500 mb-1">Positive Marks</span>
                        <input
                          type="text"
                          value={q.positiveMarks}
                          onChange={(e) =>
                            setQuestions((prev) =>
                              prev.map((item) => (item.id === q.id ? { ...item, positiveMarks: e.target.value } : item))
                            )
                          }
                          className="w-full text-xs font-bold border border-slate-300 rounded-lg px-3 py-2 text-slate-900 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                        />
                      </div>

                      <div>
                        <span className="block text-[10px] font-semibold text-slate-500 mb-1">Negative Marks</span>
                        <input
                          type="text"
                          value={q.negativeMarks}
                          onChange={(e) =>
                            setQuestions((prev) =>
                              prev.map((item) => (item.id === q.id ? { ...item, negativeMarks: e.target.value } : item))
                            )
                          }
                          className="w-full text-xs font-bold border border-slate-300 rounded-lg px-3 py-2 text-slate-900 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                        />
                      </div>
                    </div>
                  </div>

                  {/* 7. Question Type */}
                  <div>
                    <label className="block text-xs font-bold text-slate-900 mb-1.5">7. Question Type</label>
                    <select
                      value={q.questionType}
                      onChange={(e) =>
                        setQuestions((prev) =>
                          prev.map((item) => (item.id === q.id ? { ...item, questionType: e.target.value } : item))
                        )
                      }
                      className="w-full text-xs font-medium border border-slate-300 rounded-lg px-3 py-2 bg-white text-slate-800 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                    >
                      <option value="MCQ (Single Correct)">MCQ (Single Correct)</option>
                      <option value="Multiple Correct">Multiple Correct</option>
                      <option value="Numerical">Numerical</option>
                      <option value="Match the Following">Match the Following</option>
                    </select>
                  </div>

                  {/* 8. Topic / Chapter */}
                  <div>
                    <label className="block text-xs font-bold text-slate-900 mb-1.5">8. Topic / Chapter</label>
                    <select
                      value={q.chapterTopic}
                      onChange={(e) =>
                        setQuestions((prev) =>
                          prev.map((item) => (item.id === q.id ? { ...item, chapterTopic: e.target.value } : item))
                        )
                      }
                      className="w-full text-xs font-medium border border-slate-300 rounded-lg px-3 py-2 bg-white text-slate-800 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                    >
                      <option value="">Select Chapter / Topic</option>
                      <option value="Physics - Kinematics">Physics - Kinematics</option>
                      <option value="Physics - Laws of Motion">Physics - Laws of Motion</option>
                      <option value="Chemistry - Organic">Chemistry - Organic</option>
                      <option value="Biology - Cell Structure">Biology - Cell Structure</option>
                    </select>
                  </div>
                </div>
              </div>
            )}

            {/* Footer Bar of Question Card */}
            <div className="bg-slate-50 px-6 py-3 border-t border-slate-200 flex items-center justify-between">
              <label className="flex items-center gap-2 cursor-pointer text-xs font-semibold text-slate-700">
                <input
                  type="checkbox"
                  checked={q.isMarkedForReview}
                  onChange={() => toggleReview(q.id)}
                  className="w-4 h-4 text-indigo-600 rounded border-slate-300 focus:ring-indigo-500"
                />
                <span>Mark for Review</span>
              </label>

              <div className="flex items-center gap-3">
                <button
                  onClick={() => handleSaveQuestion(q.id)}
                  className="px-4 py-2 bg-white border border-slate-300 text-slate-700 rounded-lg text-xs font-bold hover:bg-slate-100 transition-colors shadow-xs"
                >
                  Save & Next
                </button>

                <button
                  onClick={() => handleSaveQuestion(q.id)}
                  className="inline-flex items-center gap-1.5 px-5 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg text-xs font-bold shadow-md shadow-indigo-600/20 transition-colors"
                >
                  <span>Save & Next</span>
                  <ArrowRight className="w-3.5 h-3.5" />
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* PAGINATION FOOTER */}
      <div className="flex items-center justify-center gap-2 pt-6">
        <button
          disabled={currentPage === 1}
          onClick={() => setCurrentPage((prev) => Math.max(prev - 1, 1))}
          className="p-2 border border-slate-300 rounded-lg text-slate-600 disabled:opacity-40 disabled:cursor-not-allowed hover:bg-slate-100"
        >
          <ChevronRight className="w-4 h-4 rotate-180" />
        </button>

        {Array.from({ length: 5 }, (_, i) => i + 1).map((pageNum) => (
          <button
            key={pageNum}
            onClick={() => setCurrentPage(pageNum)}
            className={`w-9 h-9 rounded-lg text-xs font-bold transition-all ${
              currentPage === pageNum
                ? 'bg-indigo-600 text-white shadow-md shadow-indigo-600/30'
                : 'bg-white border border-slate-300 text-slate-700 hover:bg-slate-50'
            }`}
          >
            {pageNum}
          </button>
        ))}

        <span className="text-slate-400 font-bold px-1">...</span>

        <button
          onClick={() => setCurrentPage(totalPages)}
          className={`w-9 h-9 rounded-lg text-xs font-bold bg-white border border-slate-300 text-slate-700 hover:bg-slate-50`}
        >
          {totalPages}
        </button>

        <button
          disabled={currentPage === totalPages}
          onClick={() => setCurrentPage((prev) => Math.min(prev + 1, totalPages))}
          className="p-2 border border-slate-300 rounded-lg text-slate-600 disabled:opacity-40 disabled:cursor-not-allowed hover:bg-slate-100"
        >
          <ChevronRight className="w-4 h-4" />
        </button>
      </div>
    </div>
  );
};
