import React, { useState, useEffect } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
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
  questionId?: string;
  text: string;
  questionImage?: string;
  options: string[];
  optionImages?: (string | null)[];
  correctOptionIndex: number;
  explanation: string;
  difficulty: string;
  positiveMarks: string;
  negativeMarks: string;
  questionType: string;
  chapterTopic: string;
  subject?: string;
  chapter?: string;
  topic?: string;
  isMarkedForReview: boolean;
  isCollapsed: boolean;
  isSaved?: boolean;
}

export const AdminBulkUploadStep2: React.FC = () => {
  const navigate = useNavigate();
  const location = useLocation();

  const [paperData, setPaperData] = useState<any>(null);
  const [paperId, setPaperId] = useState<string>('');
  const totalQuestionsCount = paperData?.questionCount || 200;

  const [addedCount, setAddedCount] = useState<number>(0);
  const [currentPage, setCurrentPage] = useState<number>(1);
  const [itemsPerPage, setItemsPerPage] = useState<number>(10);
  const [jumpToNumber, setJumpToNumber] = useState<number>(1);
  const [isSaving, setIsSaving] = useState<boolean>(false);

  // Initialize questions
  const [questions, setQuestions] = useState<QuestionItem[]>(
    Array.from({ length: 200 }, (_, i) => ({
      id: i + 1,
      text: '',
      options: ['', '', '', ''],
      correctOptionIndex: -1,
      explanation: '',
      difficulty: 'Medium',
      positiveMarks: '4',
      negativeMarks: '-1',
      questionType: 'MCQ (Single Correct)',
      chapterTopic: '',
      isMarkedForReview: false,
      isCollapsed: false,
      isSaved: false,
    }))
  );

  // Recovery & Session Load on Mount
  useEffect(() => {
    try {
      const activePaper = location.state?.paper || JSON.parse(localStorage.getItem('cosmyra_active_upload_paper_session') || 'null');
      if (activePaper) {
        setPaperData(activePaper);
        const pId = activePaper.id || `paper_${Date.now()}`;
        setPaperId(pId);

        const count = activePaper.questionCount || 200;
        const savedQListRaw = localStorage.getItem(`cosmyra_paper_questions_${pId}`) || '[]';
        const savedQList = JSON.parse(savedQListRaw);

        let savedCount = 0;
        let firstUnsavedIdx = -1;

        const updated = Array.from({ length: count }, (_, i) => {
          const qNum = i + 1;
          const match = savedQList.find((sq: any) => sq.questionNumber === qNum || sq.question_number === qNum);

          if (match) {
            savedCount++;
            return {
              id: qNum,
              questionId: match.id,
              text: match.questionText || match.question_text || '',
              questionImage: match.questionImage || match.question_image || '',
              options: match.options || ['', '', '', ''],
              optionImages: match.optionImages || match.option_images || [null, null, null, null],
              correctOptionIndex: match.options ? match.options.indexOf(match.correctAnswer || match.correct_answer) : 0,
              explanation: match.explanation || '',
              difficulty: match.difficulty || 'Medium',
              positiveMarks: (match.marks || 4).toString(),
              negativeMarks: (match.negativeMarks || match.negative_marks || -1).toString(),
              questionType: match.qType || match.question_type || 'MCQ (Single Correct)',
              chapterTopic: `${match.subject || 'Physics'} > ${match.chapter || 'General'}`,
              subject: match.subject || 'Physics',
              chapter: match.chapter || 'General',
              topic: match.topic || 'General',
              isMarkedForReview: false,
              isCollapsed: false,
              isSaved: true,
            };
          } else {
            if (firstUnsavedIdx === -1) firstUnsavedIdx = i;
            return {
              id: qNum,
              text: '',
              questionImage: '',
              options: ['', '', '', ''],
              optionImages: [null, null, null, null],
              correctOptionIndex: -1,
              explanation: '',
              difficulty: 'Medium',
              positiveMarks: '4',
              negativeMarks: '-1',
              questionType: 'MCQ (Single Correct)',
              chapterTopic: '',
              isMarkedForReview: false,
              isCollapsed: false,
              isSaved: false,
            };
          }
        });

        setQuestions(updated);
        setAddedCount(savedCount);

        if (firstUnsavedIdx !== -1) {
          setCurrentPage(Math.floor(firstUnsavedIdx / itemsPerPage) + 1);
        }
      }
    } catch (e) {
      console.warn('Error recovering paper session in React Step 2:', e);
    }
  }, []);

  // Save current batch incrementally
  const saveBatch = (showToast = true) => {
    setIsSaving(true);
    const start = (currentPage - 1) * itemsPerPage;
    const end = Math.min(start + itemsPerPage, questions.length);

    const currentBatch = questions.slice(start, end);
    const batchToSave = currentBatch.filter((q) => 
      q.text.trim().length > 0 || 
      Boolean(q.questionImage && q.questionImage.length > 0) ||
      Boolean(q.optionImages && q.optionImages.some((img) => img && img.length > 0))
    );

    if (batchToSave.length > 0) {
      const pId = paperId || `paper_${Date.now()}`;
      const existingPaperStr = localStorage.getItem(`cosmyra_paper_questions_${pId}`) || '[]';
      const paperQuestions = JSON.parse(existingPaperStr);

      const existingGlobalStr = localStorage.getItem('cosmyra_saved_custom_questions') || '[]';
      const globalQuestions = JSON.parse(existingGlobalStr);

      let newlySavedCount = 0;

      const rawCat = paperData?.sourceCategory || paperData?.source_category || 'PYQ';
      let canonicalCat = 'pyq_practice';
      let canonicalSourceType = 'pyq';
      let canonicalSource = 'pyq';

      const catUpper = rawCat.trim().toUpperCase();
      if (catUpper === 'NTA' || catUpper === 'NTA_QUESTION' || catUpper === 'NTA QUESTIONS') {
        canonicalCat = 'nta_question';
        canonicalSourceType = 'nta';
        canonicalSource = 'nta';
      } else if (catUpper === 'TEST SERIES' || catUpper === 'MOCK TEST' || catUpper === 'TEST_SERIES' || catUpper === 'MOCK_TEST') {
        canonicalCat = 'mock_test';
        canonicalSourceType = 'test_series';
        canonicalSource = 'mock_test';
      } else if (catUpper === 'CUSTOM TEST' || catUpper === 'CUSTOM_TEST') {
        canonicalCat = 'custom_test';
        canonicalSourceType = 'custom_test';
        canonicalSource = 'custom_test';
      } else if (catUpper === 'QUESTIONS' || catUpper === 'CUSTOM_PRACTICE') {
        canonicalCat = 'custom_practice';
        canonicalSourceType = 'practice';
        canonicalSource = 'practice';
      }

      batchToSave.forEach((q) => {
        const qId = `q_${pId}_${q.id}`;
        let correctAnsText = 'Option A';
        if (q.correctOptionIndex >= 0 && q.correctOptionIndex < q.options.length) {
          correctAnsText = q.options[q.correctOptionIndex] || `Option ${String.fromCharCode(65 + q.correctOptionIndex)}`;
        }

        const payload = {
          id: qId,
          paper_id: pId,
          questionNumber: q.id,
          question_number: q.id,
          questionText: q.text,
          question_text: q.text,
          questionImage: q.questionImage || '',
          question_image: q.questionImage || '',
          options: q.options,
          optionImages: q.optionImages || [null, null, null, null],
          option_images: q.optionImages || [null, null, null, null],
          correctAnswer: correctAnsText,
          correct_answer: correctAnsText,
          explanation: q.explanation,
          difficulty: q.difficulty || 'Medium',
          marks: parseFloat(q.positiveMarks) || 4,
          negativeMarks: parseFloat(q.negativeMarks) || -1,
          negative_marks: parseFloat(q.negativeMarks) || -1,
          qType: q.questionType,
          question_type: q.questionType,
          subject: q.subject || 'Physics',
          chapter: q.chapter || 'General',
          topic: q.topic || 'General',
          category: canonicalCat,
          sourceType: canonicalSourceType,
          source_type: canonicalSourceType,
          source: canonicalSource,
          exam: paperData?.examName || paperData?.exam || 'NEET',
          year: parseInt(paperData?.year || '2026', 10),
          paperName: paperData?.paperName || paperData?.paper_name || 'NEET 2026 Phase 1',
          status: 'Active',
          created_at: new Date().toISOString(),
        };

        const pIdx = paperQuestions.findIndex(
          (pq: any) => pq.id === qId || (pq.paper_id === pId && (pq.questionNumber === q.id || pq.question_number === q.id))
        );
        if (pIdx !== -1) {
          paperQuestions[pIdx] = payload;
        } else {
          paperQuestions.push(payload);
        }

        const gIdx = globalQuestions.findIndex(
          (gq: any) => gq.id === qId || (gq.paper_id === pId && (gq.questionNumber === q.id || gq.question_number === q.id))
        );
        if (gIdx !== -1) {
          globalQuestions[gIdx] = payload;
        } else {
          globalQuestions.unshift(payload);
        }
      });

      localStorage.setItem(`cosmyra_paper_questions_${pId}`, JSON.stringify(paperQuestions));
      localStorage.setItem('cosmyra_saved_custom_questions', JSON.stringify(globalQuestions));

      // Update isSaved state and compute unique saved count dynamically
      setQuestions((prev) => {
        const nextQ = prev.map((qItem) => {
          if (batchToSave.some((b) => b.id === qItem.id)) {
            return { ...qItem, isSaved: true, questionId: `q_${pId}_${qItem.id}` };
          }
          return qItem;
        });

        const uniqueSavedCount = nextQ.filter((qItem) => qItem.isSaved).length;
        setAddedCount(uniqueSavedCount);

        return nextQ;
      });

      if (showToast) {
        alert(`✓ Persisted ${batchToSave.length} question(s) to Question Bank!`);
      }
    }
    setIsSaving(false);
  };

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
            onClick={() => saveBatch(true)}
            className="px-5 py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg text-xs font-bold shadow-md shadow-indigo-600/30 transition-all flex items-center gap-2"
          >
            {isSaving && <span className="w-3 h-3 border-2 border-white border-t-transparent rounded-full animate-spin"></span>}
            <span>{isSaving ? 'Saving...' : 'Save All Questions'}</span>
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
              <div className="flex items-center gap-3">
                <h2 className="text-base font-bold text-indigo-600">Question {q.id}</h2>
                {q.isSaved && (
                  <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full bg-emerald-50 border border-emerald-200 text-emerald-700 text-[10px] font-bold">
                    <Check className="w-3 h-3 text-emerald-600" />
                    Saved to Question Bank
                  </span>
                )}
              </div>

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

                        <label className="inline-flex items-center gap-1.5 px-2.5 py-1 bg-white border border-slate-300 rounded text-xs font-semibold text-slate-700 hover:bg-slate-50 cursor-pointer">
                          <ImageIcon className="w-3.5 h-3.5 text-slate-500" />
                          <span>{q.questionImage ? 'Change Image' : 'Add Image'}</span>
                          <input
                            type="file"
                            accept="image/png,image/jpeg,image/jpg,image/webp"
                            className="hidden"
                            onChange={(e) => {
                              const file = e.target.files?.[0];
                              if (file) {
                                const reader = new FileReader();
                                reader.onload = (evt) => {
                                  const url = evt.target?.result as string;
                                  setQuestions((prev) =>
                                    prev.map((item) => (item.id === q.id ? { ...item, questionImage: url } : item))
                                  );
                                };
                                reader.readAsDataURL(file);
                              }
                            }}
                          />
                        </label>
                      </div>

                      {/* Question Image Preview */}
                      {q.questionImage && (
                        <div className="bg-slate-50 p-2.5 border-b border-slate-200 flex items-center justify-between">
                          <div className="flex items-center gap-3">
                            <img src={q.questionImage} alt="Question preview" className="h-16 w-24 object-contain rounded border border-slate-200 bg-white" />
                            <span className="text-xs font-semibold text-slate-700">Question Image Attached</span>
                          </div>
                          <button
                            onClick={() => setQuestions((prev) => prev.map((item) => (item.id === q.id ? { ...item, questionImage: '' } : item)))}
                            className="text-xs font-bold text-red-600 hover:text-red-700 px-2 py-1 bg-red-50 rounded"
                          >
                            Remove
                          </button>
                        </div>
                      )}

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
                        const optionImages = q.optionImages || [null, null, null, null];
                        const optImg = optionImages[optIdx];

                        return (
                          <div key={optIdx} className="space-y-1.5">
                            <div className="flex items-center gap-3">
                              <div className="flex-1 flex items-center border border-slate-300 rounded-lg overflow-hidden focus-within:ring-2 focus-within:ring-indigo-500">
                                <span className="w-9 h-9 bg-slate-50 border-r border-slate-300 flex items-center justify-center text-xs font-bold text-slate-700 flex-shrink-0">
                                  {letter}
                                </span>
                                <input
                                  type="text"
                                  value={optVal}
                                  onChange={(e) => handleOptionChange(q.id, optIdx, e.target.value)}
                                  placeholder={`Enter option ${letter} (or add image)`}
                                  className="w-full text-xs font-medium px-3 py-2 text-slate-900 focus:outline-none"
                                />
                                <label className="p-2 text-slate-500 hover:text-indigo-600 hover:bg-slate-100 cursor-pointer flex-shrink-0" title={`Add Image for Option ${letter}`}>
                                  <ImageIcon className="w-4 h-4" />
                                  <input
                                    type="file"
                                    accept="image/png,image/jpeg,image/jpg,image/webp"
                                    className="hidden"
                                    onChange={(e) => {
                                      const file = e.target.files?.[0];
                                      if (file) {
                                        const reader = new FileReader();
                                        reader.onload = (evt) => {
                                          const url = evt.target?.result as string;
                                          setQuestions((prev) =>
                                            prev.map((item) => {
                                              if (item.id === q.id) {
                                                const newOptImgs = [...(item.optionImages || [null, null, null, null])];
                                                newOptImgs[optIdx] = url;
                                                return { ...item, optionImages: newOptImgs };
                                              }
                                              return item;
                                            })
                                          );
                                        };
                                        reader.readAsDataURL(file);
                                      }
                                    }}
                                  />
                                </label>
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
                                className="w-4 h-4 text-indigo-600 focus:ring-indigo-500 cursor-pointer"
                              />
                            </div>

                            {/* Option Image Thumbnail Preview */}
                            {optImg && (
                              <div className="ml-10 flex items-center gap-2 bg-slate-50 p-1.5 rounded-lg border border-slate-200 inline-flex">
                                <img src={optImg} alt={`Option ${letter} preview`} className="h-10 w-14 object-contain rounded border border-slate-200 bg-white" />
                                <span className="text-[11px] font-semibold text-slate-600">Option {letter} Image</span>
                                <button
                                  onClick={() =>
                                    setQuestions((prev) =>
                                      prev.map((item) => {
                                        if (item.id === q.id) {
                                          const newOptImgs = [...(item.optionImages || [null, null, null, null])];
                                          newOptImgs[optIdx] = null;
                                          return { ...item, optionImages: newOptImgs };
                                        }
                                        return item;
                                      })
                                    )
                                  }
                                  className="text-[11px] font-bold text-red-600 hover:text-red-700 ml-1 px-1.5 py-0.5 bg-red-50 rounded"
                                >
                                  Remove
                                </button>
                              </div>
                            )}
                          </div>
                        );
                      })}
                    </div>
                  </div>
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
                {q.isSaved && (
                  <span className="text-[10px] font-bold text-emerald-600 bg-emerald-50 px-2 py-1 rounded flex items-center gap-1">
                    Saved
                  </span>
                )}
                <button
                  onClick={() => {
                    saveBatch(false);
                    const nextQ = q.id + 1;
                    if (nextQ <= questions.length) {
                      const nextP = Math.floor((nextQ - 1) / itemsPerPage) + 1;
                      setCurrentPage(nextP);
                    }
                  }}
                  className="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white text-xs font-bold rounded-lg transition-colors inline-flex items-center gap-1.5 shadow-sm"
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
          onClick={() => {
            saveBatch(false);
            setCurrentPage((prev) => Math.max(prev - 1, 1));
          }}
          className="p-2 border border-slate-300 rounded-lg text-slate-600 disabled:opacity-40 disabled:cursor-not-allowed hover:bg-slate-100"
        >
          <ChevronRight className="w-4 h-4 rotate-180" />
        </button>

        {Array.from({ length: 5 }, (_, i) => i + 1).map((pageNum) => (
          <button
            key={pageNum}
            onClick={() => {
              saveBatch(false);
              setCurrentPage(pageNum);
            }}
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
          onClick={() => {
            saveBatch(false);
            setCurrentPage(totalPages);
          }}
          className={`w-9 h-9 rounded-lg text-xs font-bold bg-white border border-slate-300 text-slate-700 hover:bg-slate-50`}
        >
          {totalPages}
        </button>

        <button
          disabled={currentPage === totalPages}
          onClick={() => {
            saveBatch(false);
            setCurrentPage((prev) => Math.min(prev + 1, totalPages));
          }}
          className="p-2 border border-slate-300 rounded-lg text-slate-600 disabled:opacity-40 disabled:cursor-not-allowed hover:bg-slate-100"
        >
          <ChevronRight className="w-4 h-4" />
        </button>
      </div>
    </div>
  );
};
