import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Search,
  Calendar,
  Plus,
  ChevronDown,
  Filter,
  RotateCcw,
  Eye,
  Edit3,
  MoreVertical,
  FileText,
  CheckCircle2,
  Clock,
  Trash2,
  ChevronLeft,
  ChevronRight,
  HelpCircle,
  Trophy,
  Sliders,
  Download,
  AlertCircle,
  FileCheck,
  Tag,
  Bell,
  BarChart2,
  Check,
} from 'lucide-react';

interface PredictionPaper {
  id: number;
  title: string;
  setNumber: string;
  subjects: string[];
  year: number;
  questions: number;
  marks: number;
  duration: string;
  status: 'Published' | 'Draft' | 'Archived';
}

export const AdminPaperPrediction: React.FC = () => {
  const navigate = useNavigate();

  // State
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [selectedYear, setSelectedYear] = useState<string>('all');
  const [selectedSubject, setSelectedSubject] = useState<string>('all');
  const [selectedStatus, setSelectedStatus] = useState<string>('all');
  const [selectedPaperId, setSelectedPaperId] = useState<number>(1);

  // Form State for Selected Paper Details
  const [paperTitle, setPaperTitle] = useState<string>('NEET 2024 Paper Prediction Set - 1');
  const [setNum, setSetNum] = useState<string>('1');
  const [yearVal, setYearVal] = useState<number>(2024);
  const [description, setDescription] = useState<string>(
    'This paper is based on latest pattern analysis and contains most important questions'
  );
  const [statusVal, setStatusVal] = useState<string>('Published');
  const [visibilityVal, setVisibilityVal] = useState<string>('all');
  const [publishDate, setPublishDate] = useState<string>('12/05/2024 10:30 AM');
  const [isFeatured, setIsFeatured] = useState<boolean>(true);
  const [sortOrder, setSortOrder] = useState<number>(1);

  // Toggle Switches State
  const [showSolutions, setShowSolutions] = useState<boolean>(true);
  const [showAnalysis, setShowAnalysis] = useState<boolean>(true);
  const [allowDownload, setAllowDownload] = useState<boolean>(true);
  const [negativeMarking, setNegativeMarking] = useState<boolean>(true);
  const [negativeMarksVal, setNegativeMarksVal] = useState<number>(1);
  const [shuffleQuestions, setShuffleQuestions] = useState<boolean>(false);
  const [shuffleOptions, setShuffleOptions] = useState<boolean>(false);

  // Data List
  const papersList: PredictionPaper[] = [
    {
      id: 1,
      title: 'NEET 2024 Paper Prediction',
      setNumber: 'Set - 1',
      subjects: ['Physics', 'Chemistry', 'Biology'],
      year: 2024,
      questions: 180,
      marks: 540,
      duration: '3:20 Hrs',
      status: 'Published',
    },
    {
      id: 2,
      title: 'NEET 2024 Paper Prediction',
      setNumber: 'Set - 2',
      subjects: ['Physics', 'Chemistry', 'Biology'],
      year: 2024,
      questions: 180,
      marks: 540,
      duration: '3:20 Hrs',
      status: 'Published',
    },
    {
      id: 3,
      title: 'NEET 2024 Paper Prediction',
      setNumber: 'Set - 3',
      subjects: ['Physics', 'Chemistry', 'Biology'],
      year: 2024,
      questions: 180,
      marks: 540,
      duration: '3:20 Hrs',
      status: 'Published',
    },
    {
      id: 4,
      title: 'NEET 2024 Paper Prediction',
      setNumber: 'Set - 4',
      subjects: ['Physics', 'Chemistry', 'Biology'],
      year: 2024,
      questions: 180,
      marks: 540,
      duration: '3:20 Hrs',
      status: 'Draft',
    },
    {
      id: 5,
      title: 'NEET 2023 Paper Prediction',
      setNumber: 'Set - 1',
      subjects: ['Physics', 'Chemistry', 'Biology'],
      year: 2023,
      questions: 180,
      marks: 540,
      duration: '3:20 Hrs',
      status: 'Published',
    },
    {
      id: 6,
      title: 'NEET 2023 Paper Prediction',
      setNumber: 'Set - 2',
      subjects: ['Physics', 'Chemistry', 'Biology'],
      year: 2023,
      questions: 180,
      marks: 540,
      duration: '3:20 Hrs',
      status: 'Archived',
    },
    {
      id: 7,
      title: 'NEET 2022 Paper Prediction',
      setNumber: 'Set - 1',
      subjects: ['Physics', 'Chemistry', 'Biology'],
      year: 2022,
      questions: 180,
      marks: 540,
      duration: '3:20 Hrs',
      status: 'Published',
    },
    {
      id: 8,
      title: 'NEET 2022 Paper Prediction',
      setNumber: 'Set - 2',
      subjects: ['Physics', 'Chemistry', 'Biology'],
      year: 2022,
      questions: 180,
      marks: 540,
      duration: '3:20 Hrs',
      status: 'Draft',
    },
    {
      id: 9,
      title: 'NEET 2021 Paper Prediction',
      setNumber: 'Set - 1',
      subjects: ['Physics', 'Chemistry', 'Biology'],
      year: 2022,
      questions: 180,
      marks: 540,
      duration: '3:20 Hrs',
      status: 'Published',
    },
    {
      id: 10,
      title: 'NEET 2021 Paper Prediction',
      setNumber: 'Set - 2',
      subjects: ['Physics', 'Chemistry', 'Biology'],
      year: 2022,
      questions: 180,
      marks: 540,
      duration: '3:20 Hrs',
      status: 'Archived',
    },
  ];

  return (
    <div className="space-y-6 text-slate-900 select-none">
      
      {/* Top Header Card */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 bg-white p-4 rounded-3xl border border-slate-200/80 shadow-xs">
        <div>
          <h1 className="text-xl font-black text-slate-900 tracking-tight">Paper Prediction</h1>
          <p className="text-xs text-slate-400 font-semibold flex items-center gap-1 mt-0.5">
            <span>Dashboard</span>
            <span>›</span>
            <span>Paper Prediction</span>
            <span>›</span>
            <span className="text-[#5D3EED] font-bold">All Papers</span>
          </p>
        </div>

        <button className="px-4 py-2.5 rounded-xl bg-[#5D3EED] hover:bg-[#4F46E5] text-white font-extrabold text-xs shadow-md shadow-indigo-600/20 flex items-center gap-1.5 transition-all">
          <Plus className="w-4 h-4 stroke-[3]" />
          <span>Add New Prediction Paper</span>
        </button>
      </div>

      {/* ========================================================================= */}
      {/* 1. 4 KPI METRIC SUMMARY CARDS ROW */}
      {/* ========================================================================= */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        
        {/* Card 1: Total Papers */}
        <div className="bg-white border border-slate-200/80 rounded-2xl p-4 flex items-center gap-3.5 shadow-xs">
          <div className="w-12 h-12 rounded-2xl bg-purple-50 text-[#5D3EED] border border-purple-100 flex items-center justify-center flex-shrink-0">
            <FileText className="w-6 h-6 stroke-[2]" />
          </div>
          <div>
            <span className="text-[11px] font-bold text-slate-400 block">Total Papers</span>
            <span className="text-xl font-black text-slate-900 block leading-tight">128</span>
            <span className="text-[10px] text-slate-400 font-semibold block mt-0.5">All Prediction Papers</span>
          </div>
        </div>

        {/* Card 2: Published */}
        <div className="bg-white border border-slate-200/80 rounded-2xl p-4 flex items-center gap-3.5 shadow-xs">
          <div className="w-12 h-12 rounded-2xl bg-emerald-50 text-emerald-500 border border-emerald-100 flex items-center justify-center flex-shrink-0">
            <CheckCircle2 className="w-6 h-6 stroke-[2]" />
          </div>
          <div>
            <span className="text-[11px] font-bold text-slate-400 block">Published</span>
            <span className="text-xl font-black text-slate-900 block leading-tight">96</span>
            <span className="text-[10px] text-slate-400 font-semibold block mt-0.5">Visible to students</span>
          </div>
        </div>

        {/* Card 3: Draft */}
        <div className="bg-white border border-slate-200/80 rounded-2xl p-4 flex items-center gap-3.5 shadow-xs">
          <div className="w-12 h-12 rounded-2xl bg-amber-50 text-amber-500 border border-amber-100 flex items-center justify-center flex-shrink-0">
            <Clock className="w-6 h-6 stroke-[2]" />
          </div>
          <div>
            <span className="text-[11px] font-bold text-slate-400 block">Draft</span>
            <span className="text-xl font-black text-slate-900 block leading-tight">22</span>
            <span className="text-[10px] text-slate-400 font-semibold block mt-0.5">Saved as draft</span>
          </div>
        </div>

        {/* Card 4: Archived */}
        <div className="bg-white border border-slate-200/80 rounded-2xl p-4 flex items-center gap-3.5 shadow-xs">
          <div className="w-12 h-12 rounded-2xl bg-rose-50 text-rose-500 border border-rose-100 flex items-center justify-center flex-shrink-0">
            <Trash2 className="w-6 h-6 stroke-[2]" />
          </div>
          <div>
            <span className="text-[11px] font-bold text-slate-400 block">Archived</span>
            <span className="text-xl font-black text-slate-900 block leading-tight">10</span>
            <span className="text-[10px] text-slate-400 font-semibold block mt-0.5">Not visible</span>
          </div>
        </div>

      </div>

      {/* ========================================================================= */}
      {/* 2. SEARCH & FILTERS BAR */}
      {/* ========================================================================= */}
      <div className="bg-white border border-slate-200/80 rounded-2xl p-3.5 flex flex-wrap items-center justify-between gap-3 shadow-xs">
        <div className="flex flex-wrap items-center gap-3">
          
          {/* Search Input */}
          <div className="relative">
            <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              placeholder="Search papers by title, set name..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-72 pl-10 pr-4 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold text-slate-800 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:bg-white"
            />
          </div>

          {/* Year Filter */}
          <div className="flex items-center gap-1.5 bg-slate-50 border border-slate-200 rounded-xl px-3.5 py-2 text-xs font-bold text-slate-700 cursor-pointer">
            <span>Select Year</span>
            <ChevronDown className="w-3.5 h-3.5 text-slate-400" />
          </div>

          {/* Subject Filter */}
          <div className="flex items-center gap-1.5 bg-slate-50 border border-slate-200 rounded-xl px-3.5 py-2 text-xs font-bold text-slate-700 cursor-pointer">
            <span>Select Subject</span>
            <ChevronDown className="w-3.5 h-3.5 text-slate-400" />
          </div>

          {/* Status Filter */}
          <div className="flex items-center gap-1.5 bg-slate-50 border border-slate-200 rounded-xl px-3.5 py-2 text-xs font-bold text-slate-700 cursor-pointer">
            <span>Select Status</span>
            <ChevronDown className="w-3.5 h-3.5 text-slate-400" />
          </div>

        </div>

        <div className="flex items-center gap-2">
          <button className="flex items-center gap-1.5 bg-indigo-50 border border-indigo-200 text-[#5D3EED] font-extrabold text-xs px-3.5 py-2 rounded-xl hover:bg-indigo-100 transition-colors">
            <Filter className="w-3.5 h-3.5" />
            <span>Filters</span>
          </button>

          <button className="flex items-center gap-1.5 bg-white border border-slate-200 text-slate-600 font-bold text-xs px-3.5 py-2 rounded-xl hover:bg-slate-50 transition-colors shadow-xs">
            <RotateCcw className="w-3.5 h-3.5" />
            <span>Reset</span>
          </button>
        </div>
      </div>

      {/* ========================================================================= */}
      {/* 3. PREDICTION PAPERS DATA TABLE */}
      {/* ========================================================================= */}
      <div className="bg-white border border-slate-200/80 rounded-3xl p-5 space-y-4 shadow-xs">
        <h3 className="text-sm font-extrabold text-slate-900">Prediction Papers (128)</h3>

        <div className="overflow-x-auto custom-scrollbar">
          <table className="w-full text-left text-xs font-semibold text-slate-700">
            <thead>
              <tr className="border-b border-slate-200/80 text-slate-400 uppercase text-[10px] tracking-wider font-extrabold">
                <th className="pb-3 pr-2 w-8">
                  <input type="checkbox" className="rounded border-slate-300 text-[#5D3EED]" />
                </th>
                <th className="pb-3 px-3">Title & Set</th>
                <th className="pb-3 px-3">Subjects</th>
                <th className="pb-3 px-3">Year</th>
                <th className="pb-3 px-3">Questions</th>
                <th className="pb-3 px-3">Marks</th>
                <th className="pb-3 px-3">Duration</th>
                <th className="pb-3 px-3">Status</th>
                <th className="pb-3 pl-3 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {papersList.map((paper) => (
                <tr
                  key={paper.id}
                  onClick={() => setSelectedPaperId(paper.id)}
                  className={`hover:bg-slate-50/80 transition-colors cursor-pointer ${
                    selectedPaperId === paper.id ? 'bg-indigo-50/40' : ''
                  }`}
                >
                  <td className="py-3.5 pr-2">
                    <input type="checkbox" className="rounded border-slate-300 text-[#5D3EED]" />
                  </td>

                  <td className="py-3.5 px-3">
                    <div>
                      <span className="font-extrabold text-slate-900 block text-xs">
                        {paper.title}
                      </span>
                      <span className="text-[11px] font-bold text-slate-700 block">
                        {paper.setNumber}
                      </span>
                    </div>
                  </td>

                  <td className="py-3.5 px-3">
                    <div className="flex items-center gap-1">
                      <span className="px-2 py-0.5 rounded bg-blue-50 text-blue-600 font-bold text-[10px]">
                        Physics
                      </span>
                      <span className="px-2 py-0.5 rounded bg-cyan-50 text-cyan-600 font-bold text-[10px]">
                        Chemistry
                      </span>
                      <span className="px-2 py-0.5 rounded bg-emerald-50 text-emerald-600 font-bold text-[10px]">
                        Biology
                      </span>
                    </div>
                  </td>

                  <td className="py-3.5 px-3 font-bold text-slate-800">{paper.year}</td>
                  <td className="py-3.5 px-3 font-bold text-slate-800">{paper.questions}</td>
                  <td className="py-3.5 px-3 font-bold text-slate-800">{paper.marks}</td>
                  <td className="py-3.5 px-3 font-bold text-slate-800">{paper.duration}</td>

                  <td className="py-3.5 px-3">
                    <span
                      className={`px-2.5 py-1 rounded-full font-extrabold text-[10px] ${
                        paper.status === 'Published'
                          ? 'bg-emerald-50 text-emerald-600'
                          : paper.status === 'Draft'
                          ? 'bg-amber-50 text-amber-600'
                          : 'bg-rose-50 text-rose-600'
                      }`}
                    >
                      {paper.status}
                    </span>
                  </td>

                  <td className="py-3.5 pl-3 text-right">
                    <div className="flex items-center justify-end gap-1.5 text-slate-400">
                      <button className="p-1 rounded-lg hover:bg-slate-100 hover:text-slate-600">
                        <Eye className="w-4 h-4" />
                      </button>
                      <button className="p-1 rounded-lg hover:bg-slate-100 hover:text-slate-600">
                        <Edit3 className="w-4 h-4" />
                      </button>
                      <button className="p-1 rounded-lg hover:bg-slate-100 hover:text-slate-600">
                        <MoreVertical className="w-4 h-4" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Pagination Footer */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pt-3 border-t border-slate-100 text-xs font-bold text-slate-500">
          <div className="flex items-center gap-2">
            <span>Show</span>
            <div className="flex items-center gap-1 border border-slate-200 rounded-lg px-2.5 py-1 bg-white">
              <span>10</span>
              <ChevronDown className="w-3.5 h-3.5 text-slate-400" />
            </div>
            <span>entries</span>
          </div>

          <div className="flex items-center gap-1">
            <button className="w-7 h-7 rounded-lg border border-slate-200 flex items-center justify-center hover:bg-slate-50 text-slate-400">
              <ChevronLeft className="w-4 h-4" />
            </button>
            <button className="w-7 h-7 rounded-lg bg-[#5D3EED] text-white flex items-center justify-center font-extrabold">
              1
            </button>
            <button className="w-7 h-7 rounded-lg border border-slate-200 flex items-center justify-center hover:bg-slate-50 text-slate-700">
              2
            </button>
            <button className="w-7 h-7 rounded-lg border border-slate-200 flex items-center justify-center hover:bg-slate-50 text-slate-700">
              3
            </button>
            <span className="px-1 text-slate-400 font-bold">...</span>
            <button className="w-7 h-7 rounded-lg border border-slate-200 flex items-center justify-center hover:bg-slate-50 text-slate-700">
              13
            </button>
            <button className="w-7 h-7 rounded-lg border border-slate-200 flex items-center justify-center hover:bg-slate-50 text-slate-700">
              <ChevronRight className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>

      {/* ========================================================================= */}
      {/* 4. DETAILED PAPER CONFIGURATION & ADVANCED OPTIONS PANEL */}
      {/* ========================================================================= */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        
        {/* Column 1: Paper Details */}
        <div className="lg:col-span-4 bg-white border border-slate-200/80 rounded-3xl p-5 space-y-4 shadow-xs">
          <h3 className="text-xs font-extrabold text-[#5D3EED] uppercase tracking-wider">Paper Details</h3>

          <div className="grid grid-cols-12 gap-3 text-xs font-bold text-slate-700">
            <div className="col-span-8 space-y-1">
              <span className="text-slate-400 text-[10px] uppercase font-bold block">Title</span>
              <span className="text-slate-900 font-extrabold block">{paperTitle}</span>
            </div>

            <div className="col-span-4 space-y-1 text-right">
              <span className="text-slate-400 text-[10px] uppercase font-bold block">Year</span>
              <span className="text-slate-900 font-extrabold block">{yearVal}</span>
            </div>

            <div className="col-span-12 space-y-1 pt-1">
              <span className="text-slate-400 text-[10px] uppercase font-bold block">Set Number</span>
              <span className="text-slate-900 font-extrabold block">{setNum}</span>
            </div>

            <div className="col-span-12 space-y-1 pt-1">
              <span className="text-slate-400 text-[10px] uppercase font-bold block">Description</span>
              <textarea
                rows={3}
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                className="w-full bg-slate-50 border border-slate-200 rounded-xl p-3 text-xs font-medium text-slate-800 focus:outline-none focus:ring-2 focus:ring-indigo-500"
              />
            </div>

            <div className="col-span-12 space-y-2 pt-1">
              <span className="text-slate-400 text-[10px] uppercase font-bold block">Subjects</span>
              <div className="flex items-center gap-4 text-xs font-bold text-slate-800">
                <label className="flex items-center gap-1.5 cursor-pointer">
                  <input type="checkbox" defaultChecked className="rounded border-slate-300 text-[#5D3EED]" />
                  <span>Physics</span>
                </label>

                <label className="flex items-center gap-1.5 cursor-pointer">
                  <input type="checkbox" defaultChecked className="rounded border-slate-300 text-[#5D3EED]" />
                  <span>Chemistry</span>
                </label>

                <label className="flex items-center gap-1.5 cursor-pointer">
                  <input type="checkbox" defaultChecked className="rounded border-slate-300 text-[#5D3EED]" />
                  <span>Biology</span>
                </label>
              </div>
            </div>

            {/* Metrics Pills */}
            <div className="col-span-12 grid grid-cols-3 gap-2 pt-3 border-t border-slate-100 text-center">
              <div className="bg-purple-50 border border-purple-100 p-2.5 rounded-2xl">
                <span className="text-[10px] text-purple-600 font-bold block">Total Questions</span>
                <span className="text-base font-black text-[#5D3EED]">180</span>
              </div>

              <div className="bg-amber-50 border border-amber-100 p-2.5 rounded-2xl">
                <span className="text-[10px] text-amber-600 font-bold block">Total Marks</span>
                <span className="text-base font-black text-amber-600">540</span>
              </div>

              <div className="bg-blue-50 border border-blue-100 p-2.5 rounded-2xl">
                <span className="text-[10px] text-blue-600 font-bold block">Duration</span>
                <span className="text-base font-black text-blue-600">3:20 Hrs</span>
              </div>
            </div>
          </div>
        </div>

        {/* Column 2: Paper Status & Visibility */}
        <div className="lg:col-span-4 bg-white border border-slate-200/80 rounded-3xl p-5 space-y-4 shadow-xs">
          <h3 className="text-xs font-extrabold text-[#5D3EED] uppercase tracking-wider">Paper Status & Visibility</h3>

          <div className="space-y-3.5 text-xs font-bold text-slate-700">
            {/* Status Dropdown */}
            <div className="space-y-1">
              <label className="text-slate-400 text-[10px] uppercase font-bold block">Status</label>
              <select
                value={statusVal}
                onChange={(e) => setStatusVal(e.target.value)}
                className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-xs font-bold text-slate-800 focus:outline-none focus:ring-2 focus:ring-indigo-500"
              >
                <option value="Published">Published</option>
                <option value="Draft">Draft</option>
                <option value="Archived">Archived</option>
              </select>
            </div>

            {/* Visibility Options */}
            <div className="space-y-2 pt-1">
              <label className="text-slate-400 text-[10px] uppercase font-bold block">Visibility</label>
              
              <label className="flex items-center gap-2 cursor-pointer text-xs font-bold text-slate-800">
                <input
                  type="radio"
                  name="visibility"
                  checked={visibilityVal === 'all'}
                  onChange={() => setVisibilityVal('all')}
                  className="text-[#5D3EED] focus:ring-[#5D3EED]"
                />
                <span>Visible to All Users</span>
              </label>

              <label className="flex items-center gap-2 cursor-pointer text-xs font-bold text-slate-800">
                <input
                  type="radio"
                  name="visibility"
                  checked={visibilityVal === 'specific'}
                  onChange={() => setVisibilityVal('specific')}
                  className="text-[#5D3EED] focus:ring-[#5D3EED]"
                />
                <span>Visible to Specific Users</span>
              </label>

              <label className="flex items-center gap-2 cursor-pointer text-xs font-bold text-slate-800">
                <input
                  type="radio"
                  name="visibility"
                  checked={visibilityVal === 'admin'}
                  onChange={() => setVisibilityVal('admin')}
                  className="text-[#5D3EED] focus:ring-[#5D3EED]"
                />
                <span>Hide (Admin Only)</span>
              </label>
            </div>

            {/* Publish Date Picker */}
            <div className="space-y-1 pt-1">
              <label className="text-slate-400 text-[10px] uppercase font-bold block">Publish Date</label>
              <div className="relative">
                <input
                  type="text"
                  value={publishDate}
                  onChange={(e) => setPublishDate(e.target.value)}
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl pl-3 pr-9 py-2 text-xs font-bold text-slate-800 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
                <Calendar className="w-4 h-4 text-slate-400 absolute right-3 top-1/2 -translate-y-1/2" />
              </div>
            </div>

            {/* Featured Paper Toggle */}
            <div className="flex items-center justify-between pt-2 border-t border-slate-100">
              <div>
                <span className="text-xs font-extrabold text-slate-900 block">Featured Paper</span>
                <span className="text-[10px] text-slate-400 font-medium">Highlight on mobile home screen</span>
              </div>
              <button
                onClick={() => setIsFeatured(!isFeatured)}
                className={`w-11 h-6 rounded-full transition-colors p-0.5 flex items-center ${
                  isFeatured ? 'bg-[#5D3EED] justify-end' : 'bg-slate-200 justify-start'
                }`}
              >
                <div className="w-5 h-5 rounded-full bg-white shadow-xs" />
              </button>
            </div>

            {/* Sort Order Input */}
            <div className="space-y-1 pt-1">
              <label className="text-slate-400 text-[10px] uppercase font-bold block">Sort Order</label>
              <input
                type="number"
                value={sortOrder}
                onChange={(e) => setSortOrder(Number(e.target.value))}
                className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-xs font-bold text-slate-800 focus:outline-none focus:ring-2 focus:ring-indigo-500"
              />
              <span className="text-[10px] text-slate-400 font-medium block">Lower numbers show first</span>
            </div>
          </div>
        </div>

        {/* Column 3: Paper Settings (Toggles) */}
        <div className="lg:col-span-4 bg-white border border-slate-200/80 rounded-3xl p-5 space-y-4 shadow-xs">
          <h3 className="text-xs font-extrabold text-[#5D3EED] uppercase tracking-wider">Paper Settings</h3>

          <div className="space-y-3.5 text-xs font-bold text-slate-800">
            {/* Toggle 1: Show Solutions */}
            <div className="flex items-center justify-between">
              <div>
                <span className="block font-extrabold">Show Solutions</span>
                <span className="text-[10px] text-slate-400 font-medium block">Allow students to view solutions after attempt</span>
              </div>
              <button
                onClick={() => setShowSolutions(!showSolutions)}
                className={`w-11 h-6 rounded-full transition-colors p-0.5 flex items-center ${
                  showSolutions ? 'bg-[#5D3EED] justify-end' : 'bg-slate-200 justify-start'
                }`}
              >
                <div className="w-5 h-5 rounded-full bg-white shadow-xs" />
              </button>
            </div>

            {/* Toggle 2: Show Analysis */}
            <div className="flex items-center justify-between">
              <div>
                <span className="block font-extrabold">Show Analysis</span>
                <span className="text-[10px] text-slate-400 font-medium block">Show detailed performance analysis</span>
              </div>
              <button
                onClick={() => setShowAnalysis(!showAnalysis)}
                className={`w-11 h-6 rounded-full transition-colors p-0.5 flex items-center ${
                  showAnalysis ? 'bg-[#5D3EED] justify-end' : 'bg-slate-200 justify-start'
                }`}
              >
                <div className="w-5 h-5 rounded-full bg-white shadow-xs" />
              </button>
            </div>

            {/* Toggle 3: Allow Download */}
            <div className="flex items-center justify-between">
              <div>
                <span className="block font-extrabold">Allow Download</span>
                <span className="text-[10px] text-slate-400 font-medium block">Allow students to download PDF</span>
              </div>
              <button
                onClick={() => setAllowDownload(!allowDownload)}
                className={`w-11 h-6 rounded-full transition-colors p-0.5 flex items-center ${
                  allowDownload ? 'bg-[#5D3EED] justify-end' : 'bg-slate-200 justify-start'
                }`}
              >
                <div className="w-5 h-5 rounded-full bg-white shadow-xs" />
              </button>
            </div>

            {/* Toggle 4: Negative Marking */}
            <div className="space-y-2 pt-1 border-t border-slate-100">
              <div className="flex items-center justify-between">
                <span className="block font-extrabold">Negative Marking</span>
                <button
                  onClick={() => setNegativeMarking(!negativeMarking)}
                  className={`w-11 h-6 rounded-full transition-colors p-0.5 flex items-center ${
                    negativeMarking ? 'bg-[#5D3EED] justify-end' : 'bg-slate-200 justify-start'
                  }`}
                >
                  <div className="w-5 h-5 rounded-full bg-white shadow-xs" />
                </button>
              </div>

              {negativeMarking && (
                <div className="space-y-1">
                  <span className="text-[10px] text-slate-400 uppercase font-bold block">Negative Marks</span>
                  <input
                    type="number"
                    value={negativeMarksVal}
                    onChange={(e) => setNegativeMarksVal(Number(e.target.value))}
                    className="w-full bg-slate-50 border border-slate-200 rounded-xl px-3 py-1.5 text-xs font-bold text-slate-800"
                  />
                  <span className="text-[10px] text-slate-400 font-medium block">Marks deducted for wrong answer</span>
                </div>
              )}
            </div>

            {/* Toggle 5: Shuffle Questions */}
            <div className="flex items-center justify-between pt-1">
              <div>
                <span className="block font-extrabold">Shuffle Questions</span>
                <span className="text-[10px] text-slate-400 font-medium block">Questions will be shuffled for each user</span>
              </div>
              <button
                onClick={() => setShuffleQuestions(!shuffleQuestions)}
                className={`w-11 h-6 rounded-full transition-colors p-0.5 flex items-center ${
                  shuffleQuestions ? 'bg-[#5D3EED] justify-end' : 'bg-slate-200 justify-start'
                }`}
              >
                <div className="w-5 h-5 rounded-full bg-white shadow-xs" />
              </button>
            </div>

            {/* Toggle 6: Shuffle Options */}
            <div className="flex items-center justify-between pt-1">
              <div>
                <span className="block font-extrabold">Shuffle Options</span>
                <span className="text-[10px] text-slate-400 font-medium block">Options will be shuffled for each user</span>
              </div>
              <button
                onClick={() => setShuffleOptions(!shuffleOptions)}
                className={`w-11 h-6 rounded-full transition-colors p-0.5 flex items-center ${
                  shuffleOptions ? 'bg-[#5D3EED] justify-end' : 'bg-slate-200 justify-start'
                }`}
              >
                <div className="w-5 h-5 rounded-full bg-white shadow-xs" />
              </button>
            </div>

          </div>
        </div>

      </div>

      {/* ========================================================================= */}
      {/* 5. ADVANCED OPTIONS TOOLBAR & ACTION FOOTER */}
      {/* ========================================================================= */}
      <div className="bg-white border border-slate-200/80 rounded-3xl p-5 space-y-5 shadow-xs">
        <h3 className="text-xs font-extrabold text-slate-900 uppercase tracking-wider">Advanced Options</h3>

        <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-3">
          {/* Action 1 */}
          <div className="bg-slate-50 border border-slate-200 rounded-2xl p-3 flex items-center gap-3 cursor-pointer hover:bg-slate-100 transition-colors">
            <div className="w-9 h-9 rounded-xl bg-purple-100 text-[#5D3EED] flex items-center justify-center flex-shrink-0">
              <FileText className="w-4 h-4" />
            </div>
            <div>
              <span className="text-xs font-extrabold text-slate-900 block leading-tight">Add Instructions</span>
              <span className="text-[10px] text-slate-400 font-medium block">Set paper instructions</span>
            </div>
          </div>

          {/* Action 2 */}
          <div className="bg-slate-50 border border-slate-200 rounded-2xl p-3 flex items-center gap-3 cursor-pointer hover:bg-slate-100 transition-colors">
            <div className="w-9 h-9 rounded-xl bg-blue-100 text-blue-600 flex items-center justify-center flex-shrink-0">
              <Tag className="w-4 h-4" />
            </div>
            <div>
              <span className="text-xs font-extrabold text-slate-900 block leading-tight">Add Tags</span>
              <span className="text-[10px] text-slate-400 font-medium block">Add relevant tags</span>
            </div>
          </div>

          {/* Action 3 */}
          <div className="bg-slate-50 border border-slate-200 rounded-2xl p-3 flex items-center gap-3 cursor-pointer hover:bg-slate-100 transition-colors">
            <div className="w-9 h-9 rounded-xl bg-emerald-100 text-emerald-600 flex items-center justify-center flex-shrink-0">
              <FileCheck className="w-4 h-4" />
            </div>
            <div>
              <span className="text-xs font-extrabold text-slate-900 block leading-tight">Attach Solutions</span>
              <span className="text-[10px] text-slate-400 font-medium block">Upload solution PDF</span>
            </div>
          </div>

          {/* Action 4 */}
          <div className="bg-slate-50 border border-slate-200 rounded-2xl p-3 flex items-center gap-3 cursor-pointer hover:bg-slate-100 transition-colors">
            <div className="w-9 h-9 rounded-xl bg-cyan-100 text-cyan-600 flex items-center justify-center flex-shrink-0">
              <Sliders className="w-4 h-4" />
            </div>
            <div>
              <span className="text-xs font-extrabold text-slate-900 block leading-tight">SEO Settings</span>
              <span className="text-[10px] text-slate-400 font-medium block">Meta title & description</span>
            </div>
          </div>

          {/* Action 5 */}
          <div className="bg-slate-50 border border-slate-200 rounded-2xl p-3 flex items-center gap-3 cursor-pointer hover:bg-slate-100 transition-colors">
            <div className="w-9 h-9 rounded-xl bg-amber-100 text-amber-600 flex items-center justify-center flex-shrink-0">
              <Bell className="w-4 h-4" />
            </div>
            <div>
              <span className="text-xs font-extrabold text-slate-900 block leading-tight">Set Reminder</span>
              <span className="text-[10px] text-slate-400 font-medium block">Notify users</span>
            </div>
          </div>

          {/* Action 6 */}
          <div className="bg-slate-50 border border-slate-200 rounded-2xl p-3 flex items-center gap-3 cursor-pointer hover:bg-slate-100 transition-colors">
            <div className="w-9 h-9 rounded-xl bg-indigo-100 text-indigo-600 flex items-center justify-center flex-shrink-0">
              <BarChart2 className="w-4 h-4" />
            </div>
            <div>
              <span className="text-xs font-extrabold text-slate-900 block leading-tight">View Analytics</span>
              <span className="text-[10px] text-slate-400 font-medium block">Paper performance</span>
            </div>
          </div>
        </div>

        {/* Footer Action Buttons */}
        <div className="flex items-center justify-end gap-3 pt-4 border-t border-slate-100">
          <button className="px-5 py-2.5 rounded-xl border border-slate-200 text-slate-600 font-bold text-xs hover:bg-slate-50 transition-colors">
            Cancel
          </button>

          <button className="px-5 py-2.5 rounded-xl border border-[#5D3EED] text-[#5D3EED] bg-white font-extrabold text-xs hover:bg-purple-50 transition-colors">
            Save as Draft
          </button>

          <button className="px-6 py-2.5 rounded-xl bg-[#5D3EED] hover:bg-[#4F46E5] text-white font-extrabold text-xs shadow-md shadow-indigo-600/20 transition-all">
            Update Paper
          </button>
        </div>

      </div>

    </div>
  );
};
