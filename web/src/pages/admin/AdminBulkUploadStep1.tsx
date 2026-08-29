import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  FileText,
  Download,
  ArrowRight,
  HelpCircle,
  ChevronRight,
  Check,
} from 'lucide-react';

export const AdminBulkUploadStep1: React.FC = () => {
  const navigate = useNavigate();

  // Form State
  const [sourceCategory, setSourceCategory] = useState<string>('PYQ');
  const [examName, setExamName] = useState<string>('NEET');
  const [year, setYear] = useState<string>('2026');
  const [phaseSession, setPhaseSession] = useState<string>('Phase 1');
  const [paperType, setPaperType] = useState<string>('Medical (UG)');

  const [testSeriesOption, setTestSeriesOption] = useState<'existing' | 'new'>('existing');
  const [existingTestSeries, setExistingTestSeries] = useState<string>('NEET 2026 Full Syllabus Test Series');
  const [newTestSeriesName, setNewTestSeriesName] = useState<string>('');

  const [paperName, setPaperName] = useState<string>('NEET 2026 Phase 1');
  const [paperCode, setPaperCode] = useState<string>('N26P1');
  const [language, setLanguage] = useState<string>('English');
  const [conductingBody, setConductingBody] = useState<string>('NTA');
  const [questionCount, setQuestionCount] = useState<string>('200');

  const [totalMarks, setTotalMarks] = useState<string>('720');
  const [duration, setDuration] = useState<string>('180');
  const [negativeMarking, setNegativeMarking] = useState<string>('Yes');
  const [negativeMarks, setNegativeMarks] = useState<string>('-4');
  const [positiveMarks, setPositiveMarks] = useState<string>('+4');

  const [subjects, setSubjects] = useState<{ [key: string]: boolean }>({
    Physics: true,
    Chemistry: true,
    Botany: true,
    Zoology: true,
  });

  const [paperShift, setPaperShift] = useState<string>('');
  const [instructions, setInstructions] = useState<string>('');

  const [uploadMethod, setUploadMethod] = useState<string>('manual');
  const [difficultyDistribution, setDifficultyDistribution] = useState<string>('');
  const [questionOrdering, setQuestionOrdering] = useState<string>('Subject-wise');
  const [showSectionBreaks, setShowSectionBreaks] = useState<boolean>(true);

  const toggleSubject = (key: string) => {
    setSubjects((prev) => ({ ...prev, [key]: !prev[key] }));
  };

  const handleProceed = () => {
    const paperId = `paper_${Date.now()}`;
    const paperData = {
      id: paperId,
      sourceCategory,
      examName,
      year,
      phaseSession,
      paperType,
      paperName: paperName || 'NEET 2026 Phase 1',
      paperCode,
      language,
      conductingBody,
      questionCount: parseInt(questionCount, 10) || 200,
      totalMarks: parseFloat(totalMarks) || 720,
      durationMinutes: parseInt(duration, 10) || 180,
      negativeMarking,
      negativeMarks: parseFloat(negativeMarks) || -4,
      positiveMarks: parseFloat(positiveMarks) || 4,
      subjects: Object.keys(subjects).filter((s) => subjects[s]),
      shift: paperShift,
      instructions,
      testSeriesOption,
      existingTestSeries,
      newTestSeriesName,
      status: 'Draft',
      savedQuestionsCount: 0,
      createdAt: new Date().toISOString(),
    };

    try {
      localStorage.setItem('cosmyra_active_upload_paper_session', JSON.stringify(paperData));
      const rawPapers = localStorage.getItem('cosmyra_saved_papers') || '[]';
      const papers = JSON.parse(rawPapers);
      papers.unshift(paperData);
      localStorage.setItem('cosmyra_saved_papers', JSON.stringify(papers));
    } catch (e) {
      console.warn('Error saving paper session to localStorage', e);
    }

    navigate('/admin/upload-step2', { state: { paper: paperData } });
  };

  return (
    <div className="space-y-6 pb-12 font-sans bg-slate-50 min-h-screen text-slate-800">
      {/* Breadcrumb Header */}
      <div className="flex items-center gap-2 text-xs text-slate-500 font-medium">
        <span>Question & Paper Bank</span>
        <ChevronRight className="w-3.5 h-3.5 text-slate-400" />
        <span className="text-slate-700 font-semibold">Upload Questions</span>
      </div>

      {/* Page Title & Subtitle */}
      <div>
        <h1 className="text-2xl font-bold text-slate-900 tracking-tight">
          Upload Questions in Bulk - Step 1 of 2
        </h1>
        <p className="text-xs text-slate-500 mt-1">
          Enter paper details and settings. You will add questions in the next step.
        </p>
      </div>

      {/* Stepper Indicator */}
      <div className="flex items-center justify-center my-6 max-w-lg mx-auto">
        {/* Step 1 */}
        <div className="flex flex-col items-center gap-1.5">
          <div className="w-9 h-9 rounded-full bg-indigo-600 text-white font-bold text-sm flex items-center justify-center shadow-md shadow-indigo-500/20">
            1
          </div>
          <span className="text-xs font-bold text-indigo-600">Paper Details</span>
        </div>

        {/* Dashed Connecting Line */}
        <div className="flex-1 mx-4 mb-5 border-t-2 border-dashed border-slate-300"></div>

        {/* Step 2 */}
        <div className="flex flex-col items-center gap-1.5">
          <div className="w-9 h-9 rounded-full bg-white border-2 border-slate-300 text-slate-400 font-bold text-sm flex items-center justify-center">
            2
          </div>
          <span className="text-xs font-medium text-slate-500">Add Questions</span>
        </div>
      </div>

      {/* CARD 1: Paper / Exam Details */}
      <div className="bg-white rounded-xl border border-slate-200 p-6 shadow-sm space-y-6">
        <h2 className="text-base font-bold text-slate-900 border-b border-slate-100 pb-3">
          Paper / Exam Details
        </h2>

        {/* Row 1 (5 Columns) */}
        <div className="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-5 gap-4">
          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1.5">
              Source Category <span className="text-red-500">*</span>
            </label>
            <select
              value={sourceCategory}
              onChange={(e) => {
                const val = e.target.value;
                setSourceCategory(val);
                if (val === 'PYQ' && !['NEET', 'JEE Main', 'JEE Advanced', 'AIIMS'].includes(examName)) {
                  setExamName('NEET');
                }
              }}
              className="w-full text-xs font-medium border border-slate-300 rounded-lg px-3 py-2 bg-white text-slate-800 focus:outline-none focus:ring-2 focus:ring-indigo-500"
            >
              <option value="PYQ">PYQ</option>
              <option value="NTA">NTA</option>
              <option value="Questions">Questions</option>
              <option value="Test Series">Test Series</option>
            </select>
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1.5">
              Exam Name <span className="text-red-500">*</span>
            </label>
            <select
              value={examName}
              onChange={(e) => setExamName(e.target.value)}
              className="w-full text-xs font-medium border border-slate-300 rounded-lg px-3 py-2 bg-white text-slate-800 focus:outline-none focus:ring-2 focus:ring-indigo-500"
            >
              {sourceCategory === 'PYQ' ? (
                <>
                  <option value="NEET">NEET</option>
                  <option value="JEE Main">JEE Main</option>
                  <option value="JEE Advanced">JEE Advanced</option>
                  <option value="AIIMS">AIIMS</option>
                </>
              ) : (
                <>
                  <option value="NEET">NEET</option>
                  <option value="JEE Main">JEE Main</option>
                  <option value="JEE Advanced">JEE Advanced</option>
                  <option value="AIIMS">AIIMS</option>
                  <option value="CUET">CUET</option>
                  <option value="CBSE 12">CBSE 12</option>
                </>
              )}
            </select>
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1.5">
              Year <span className="text-red-500">*</span>
            </label>
            <select
              value={year}
              onChange={(e) => setYear(e.target.value)}
              className="w-full text-xs font-medium border border-slate-300 rounded-lg px-3 py-2 bg-white text-slate-800 focus:outline-none focus:ring-2 focus:ring-indigo-500"
            >
              <option value="2026">2026</option>
              <option value="2025">2025</option>
              <option value="2024">2024</option>
              <option value="2023">2023</option>
            </select>
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1.5">
              Phase / Session <span className="text-red-500">*</span>
            </label>
            <select
              value={phaseSession}
              onChange={(e) => setPhaseSession(e.target.value)}
              className="w-full text-xs font-medium border border-slate-300 rounded-lg px-3 py-2 bg-white text-slate-800 focus:outline-none focus:ring-2 focus:ring-indigo-500"
            >
              <option value="Phase 1">Phase 1</option>
              <option value="Phase 2">Phase 2</option>
              <option value="Session 1">Session 1</option>
              <option value="Full Paper">Full Paper</option>
            </select>
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1.5">
              Paper Type <span className="text-red-500">*</span>
            </label>
            <select
              value={paperType}
              onChange={(e) => setPaperType(e.target.value)}
              className="w-full text-xs font-medium border border-slate-300 rounded-lg px-3 py-2 bg-white text-slate-800 focus:outline-none focus:ring-2 focus:ring-indigo-500"
            >
              <option value="Medical (UG)">Medical (UG)</option>
              <option value="Engineering">Engineering</option>
              <option value="Foundation">Foundation</option>
            </select>
          </div>
        </div>

        {/* Conditional Block when Source Category is Test Series */}
        {sourceCategory === 'Test Series' && (
          <div className="bg-indigo-50/70 border border-indigo-200 rounded-xl p-4 space-y-3 my-2">
            <h3 className="text-xs font-bold text-indigo-900">Test Series Option *</h3>
            <div className="flex flex-wrap items-center gap-6">
              <label className="flex items-center gap-2 cursor-pointer text-xs font-semibold text-slate-900">
                <input
                  type="radio"
                  name="testSeriesOpt"
                  value="existing"
                  checked={testSeriesOption === 'existing'}
                  onChange={() => setTestSeriesOption('existing')}
                  className="w-4 h-4 text-indigo-600 border-slate-300 focus:ring-indigo-500"
                />
                <span>Select Existing Test Series</span>
              </label>

              <label className="flex items-center gap-2 cursor-pointer text-xs font-semibold text-slate-900">
                <input
                  type="radio"
                  name="testSeriesOpt"
                  value="new"
                  checked={testSeriesOption === 'new'}
                  onChange={() => setTestSeriesOption('new')}
                  className="w-4 h-4 text-indigo-600 border-slate-300 focus:ring-indigo-500"
                />
                <span>Create New Test Series</span>
              </label>
            </div>

            {testSeriesOption === 'existing' ? (
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">Select Test Series *</label>
                <select
                  value={existingTestSeries}
                  onChange={(e) => setExistingTestSeries(e.target.value)}
                  className="w-full text-xs font-medium border border-slate-300 rounded-lg px-3 py-2 bg-white text-slate-800 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                >
                  <option value="NEET 2026 Full Syllabus Test Series">NEET 2026 Full Syllabus Test Series</option>
                  <option value="NEET 2026 Chapter Wise Test Series">NEET 2026 Chapter Wise Test Series</option>
                  <option value="NEET 2026 Topic Wise Test Series">NEET 2026 Topic Wise Test Series</option>
                  <option value="NEET 2026 Previous Year Papers">NEET 2026 Previous Year Papers</option>
                </select>
              </div>
            ) : (
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">New Test Series Title *</label>
                <input
                  type="text"
                  value={newTestSeriesName}
                  onChange={(e) => setNewTestSeriesName(e.target.value)}
                  placeholder="Enter title for new test series..."
                  className="w-full text-xs font-medium border border-slate-300 rounded-lg px-3 py-2 bg-white text-slate-900 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
              </div>
            )}
          </div>
        )}

        {/* Row 2 (5 Columns) */}
        <div className="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-5 gap-4">
          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1.5">
              Paper Name <span className="text-red-500">*</span>
            </label>
            <input
              type="text"
              value={paperName}
              onChange={(e) => setPaperName(e.target.value)}
              className="w-full text-xs font-medium border border-slate-300 rounded-lg px-3 py-2 text-slate-900 focus:outline-none focus:ring-2 focus:ring-indigo-500"
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1.5">
              Paper Code (Optional)
            </label>
            <input
              type="text"
              value={paperCode}
              onChange={(e) => setPaperCode(e.target.value)}
              className="w-full text-xs font-medium border border-slate-300 rounded-lg px-3 py-2 text-slate-900 focus:outline-none focus:ring-2 focus:ring-indigo-500"
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1.5">
              Language <span className="text-red-500">*</span>
            </label>
            <select
              value={language}
              onChange={(e) => setLanguage(e.target.value)}
              className="w-full text-xs font-medium border border-slate-300 rounded-lg px-3 py-2 bg-white text-slate-800 focus:outline-none focus:ring-2 focus:ring-indigo-500"
            >
              <option value="English">English</option>
              <option value="Hindi">Hindi</option>
              <option value="Bilingual">Bilingual</option>
            </select>
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1.5">
              Conducting Body <span className="text-red-500">*</span>
            </label>
            <select
              value={conductingBody}
              onChange={(e) => setConductingBody(e.target.value)}
              className="w-full text-xs font-medium border border-slate-300 rounded-lg px-3 py-2 bg-white text-slate-800 focus:outline-none focus:ring-2 focus:ring-indigo-500"
            >
              <option value="NTA">NTA</option>
              <option value="CBSE">CBSE</option>
              <option value="Cosmyra">Cosmyra</option>
            </select>
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1.5">
              Question Count <span className="text-red-500">*</span>
            </label>
            <input
              type="number"
              value={questionCount}
              onChange={(e) => setQuestionCount(e.target.value)}
              className="w-full text-xs font-medium border border-slate-300 rounded-lg px-3 py-2 text-slate-900 focus:outline-none focus:ring-2 focus:ring-indigo-500"
            />
          </div>
        </div>

        {/* Row 3 (5 Columns) */}
        <div className="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-5 gap-4">
          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1.5">
              Total Marks <span className="text-red-500">*</span>
            </label>
            <input
              type="number"
              value={totalMarks}
              onChange={(e) => setTotalMarks(e.target.value)}
              className="w-full text-xs font-medium border border-slate-300 rounded-lg px-3 py-2 text-slate-900 focus:outline-none focus:ring-2 focus:ring-indigo-500"
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1.5">
              Duration (Minutes) <span className="text-red-500">*</span>
            </label>
            <input
              type="number"
              value={duration}
              onChange={(e) => setDuration(e.target.value)}
              className="w-full text-xs font-medium border border-slate-300 rounded-lg px-3 py-2 text-slate-900 focus:outline-none focus:ring-2 focus:ring-indigo-500"
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1.5">
              Negative Marking <span className="text-red-500">*</span>
            </label>
            <select
              value={negativeMarking}
              onChange={(e) => setNegativeMarking(e.target.value)}
              className="w-full text-xs font-medium border border-slate-300 rounded-lg px-3 py-2 bg-white text-slate-800 focus:outline-none focus:ring-2 focus:ring-indigo-500"
            >
              <option value="Yes">Yes</option>
              <option value="No">No</option>
            </select>
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1.5">
              Negative Marks
            </label>
            <input
              type="text"
              value={negativeMarks}
              onChange={(e) => setNegativeMarks(e.target.value)}
              className="w-full text-xs font-medium border border-slate-300 rounded-lg px-3 py-2 text-slate-900 focus:outline-none focus:ring-2 focus:ring-indigo-500"
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1.5">
              Positive Marks
            </label>
            <input
              type="text"
              value={positiveMarks}
              onChange={(e) => setPositiveMarks(e.target.value)}
              className="w-full text-xs font-medium border border-slate-300 rounded-lg px-3 py-2 text-slate-900 focus:outline-none focus:ring-2 focus:ring-indigo-500"
            />
          </div>
        </div>

        {/* Row 4: Subjects Checkboxes + Paper Shift */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 pt-2">
          <div className="lg:col-span-7">
            <label className="block text-xs font-semibold text-slate-700 mb-2">
              Subjects In This Paper (Select all that apply) <span className="text-red-500">*</span>
            </label>
            <div className="flex flex-wrap items-center gap-4">
              {['Physics', 'Chemistry', 'Botany', 'Zoology'].map((sub) => (
                <label key={sub} className="flex items-center gap-2 cursor-pointer text-xs font-semibold text-slate-800">
                  <input
                    type="checkbox"
                    checked={!!subjects[sub]}
                    onChange={() => toggleSubject(sub)}
                    className="w-4 h-4 rounded text-indigo-600 focus:ring-indigo-500 border-slate-300"
                  />
                  <span>{sub}</span>
                </label>
              ))}
            </div>
          </div>

          <div className="lg:col-span-5">
            <label className="block text-xs font-semibold text-slate-700 mb-1.5">
              Paper Shift (If Applicable)
            </label>
            <select
              value={paperShift}
              onChange={(e) => setPaperShift(e.target.value)}
              className="w-full text-xs font-medium border border-slate-300 rounded-lg px-3 py-2 bg-white text-slate-800 focus:outline-none focus:ring-2 focus:ring-indigo-500"
            >
              <option value="">Select Shift</option>
              <option value="Shift 1 (Morning)">Shift 1 (Morning)</option>
              <option value="Shift 2 (Afternoon)">Shift 2 (Afternoon)</option>
            </select>
          </div>
        </div>

        {/* Row 5: Instructions */}
        <div>
          <label className="block text-xs font-semibold text-slate-700 mb-1.5">
            Instructions (Optional)
          </label>
          <textarea
            rows={3}
            value={instructions}
            onChange={(e) => setInstructions(e.target.value)}
            placeholder="Enter paper instructions or notes..."
            className="w-full text-xs font-medium border border-slate-300 rounded-lg p-3 text-slate-900 focus:outline-none focus:ring-2 focus:ring-indigo-500"
          ></textarea>
        </div>
      </div>

      {/* CARD 2: Upload Options */}
      <div className="bg-white rounded-xl border border-slate-200 p-6 shadow-sm space-y-6">
        <h2 className="text-base font-bold text-slate-900 border-b border-slate-100 pb-3">
          Upload Options
        </h2>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Left Column: Radio Methods */}
          <div className="space-y-3">
            <span className="block text-xs font-medium text-slate-500">Upload Method</span>
            <label className="flex items-center gap-3 text-xs font-semibold text-slate-900 cursor-pointer">
              <input
                type="radio"
                name="uploadMethod"
                value="manual"
                checked={uploadMethod === 'manual'}
                onChange={(e) => setUploadMethod(e.target.value)}
                className="w-4 h-4 text-indigo-600 border-slate-300 focus:ring-indigo-500"
              />
              <span>Enter Questions Manually</span>
            </label>

            <label className="flex items-center gap-3 text-xs font-medium text-slate-700 cursor-pointer">
              <input
                type="radio"
                name="uploadMethod"
                value="excel"
                checked={uploadMethod === 'excel'}
                onChange={(e) => setUploadMethod(e.target.value)}
                className="w-4 h-4 text-indigo-600 border-slate-300 focus:ring-indigo-500"
              />
              <span>Upload from Excel / CSV</span>
            </label>

            <label className="flex items-center gap-3 text-xs font-medium text-slate-700 cursor-pointer">
              <input
                type="radio"
                name="uploadMethod"
                value="paste"
                checked={uploadMethod === 'paste'}
                onChange={(e) => setUploadMethod(e.target.value)}
                className="w-4 h-4 text-indigo-600 border-slate-300 focus:ring-indigo-500"
              />
              <span>Copy & Paste</span>
            </label>
          </div>

          {/* Right Column: Excel Banner Box */}
          <div className="bg-indigo-50/60 border border-indigo-100 rounded-xl p-5 flex items-start gap-4">
            <div className="w-10 h-10 rounded-lg bg-indigo-100 border border-indigo-200 flex items-center justify-center text-indigo-600 flex-shrink-0">
              <FileText className="w-5 h-5" />
            </div>
            <div className="space-y-1.5 flex-1">
              <h3 className="text-xs font-bold text-indigo-700">Recommended Excel Format</h3>
              <p className="text-xs text-slate-500">
                Download our sample Excel file and fill your questions.
              </p>
              <button
                onClick={() => alert('Downloading sample Excel template...')}
                className="mt-2 inline-flex items-center gap-2 px-3 py-1.5 bg-white border border-indigo-600 text-indigo-600 rounded-lg text-xs font-bold hover:bg-indigo-50 transition-colors"
              >
                <Download className="w-3.5 h-3.5" />
                <span>Download Sample File</span>
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* CARD 3: Other Settings & Action Buttons */}
      <div className="bg-white rounded-xl border border-slate-200 p-6 shadow-sm space-y-6">
        <h2 className="text-base font-bold text-slate-900 border-b border-slate-100 pb-3">
          Other Settings
        </h2>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1.5">
              Difficulty Distribution (Optional)
            </label>
            <select
              value={difficultyDistribution}
              onChange={(e) => setDifficultyDistribution(e.target.value)}
              className="w-full text-xs font-medium border border-slate-300 rounded-lg px-3 py-2 bg-white text-slate-800 focus:outline-none focus:ring-2 focus:ring-indigo-500"
            >
              <option value="">Select Difficulty Distribution</option>
              <option value="Standard">Standard (30% Easy, 50% Medium, 20% Hard)</option>
              <option value="Balanced">Balanced (33% Each)</option>
            </select>
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1.5">
              Question Ordering
            </label>
            <select
              value={questionOrdering}
              onChange={(e) => setQuestionOrdering(e.target.value)}
              className="w-full text-xs font-medium border border-slate-300 rounded-lg px-3 py-2 bg-white text-slate-800 focus:outline-none focus:ring-2 focus:ring-indigo-500"
            >
              <option value="Subject-wise">Subject-wise</option>
              <option value="Randomized">Randomized</option>
              <option value="Sequential">Sequential</option>
            </select>
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1.5">
              Show Section / Subject Breaks
            </label>
            <div className="flex items-center gap-3 pt-1">
              <button
                type="button"
                onClick={() => setShowSectionBreaks(!showSectionBreaks)}
                className={`w-11 h-6 flex items-center rounded-full p-1 transition-colors ${
                  showSectionBreaks ? 'bg-indigo-600 justify-end' : 'bg-slate-300 justify-start'
                }`}
              >
                <span className="w-4 h-4 rounded-full bg-white shadow-md"></span>
              </button>
              <span className="text-xs font-semibold text-slate-700">
                {showSectionBreaks ? 'Yes' : 'No'}
              </span>
            </div>
          </div>
        </div>

        {/* Action Buttons Row */}
        <div className="flex items-center justify-between pt-4 border-t border-slate-100">
          <button
            onClick={() => navigate('/admin/questions')}
            className="px-5 py-2.5 bg-white border border-slate-300 text-slate-700 rounded-lg text-xs font-bold hover:bg-slate-50 transition-colors"
          >
            Cancel
          </button>

          <button
            onClick={handleProceed}
            className="inline-flex items-center gap-2 px-6 py-2.5 bg-indigo-600 text-white rounded-lg text-xs font-bold shadow-md shadow-indigo-600/30 hover:bg-indigo-700 transition-colors"
          >
            <span>Proceed to Add Questions</span>
            <ArrowRight className="w-4 h-4" />
          </button>
        </div>
      </div>

      {/* Tip Banner */}
      <div className="bg-indigo-50/60 border border-indigo-100 rounded-xl p-4 flex items-center gap-3">
        <div className="w-7 h-7 rounded-lg bg-indigo-100 border border-indigo-200 flex items-center justify-center text-indigo-600 flex-shrink-0">
          <HelpCircle className="w-4 h-4" />
        </div>
        <p className="text-xs font-semibold text-indigo-700">
          Tip: After clicking "Proceed to Add Questions", you will be able to add 200 questions one by one.
        </p>
      </div>
    </div>
  );
};
