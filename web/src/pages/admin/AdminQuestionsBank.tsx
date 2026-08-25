import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Search,
  Plus,
  ChevronDown,
  Filter,
  RotateCcw,
  Eye,
  Edit3,
  MoreVertical,
  Mail,
  CheckCircle2,
  Clock,
  Trash2,
  ChevronLeft,
  ChevronRight,
  Upload,
  FileSpreadsheet,
  Layers,
  Lightbulb,
  ArrowRight,
  X,
  FileText,
  HelpCircle,
} from 'lucide-react';

interface QuestionItem {
  id: string;
  question: string;
  category: string;
  subject: string;
  topic: string;
  difficulty: 'Easy' | 'Medium' | 'Hard';
  type: 'MCQ' | 'Numerical' | 'Match';
  status: 'Published' | 'Draft' | 'Archived';
}

export const AdminQuestionsBank: React.FC = () => {
  const navigate = useNavigate();

  // State
  const [activeCategoryTab, setActiveCategoryTab] = useState<string>('NTA');
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [selectedSubject, setSelectedSubject] = useState<string>('Physics');
  const [selectedStatus, setSelectedStatus] = useState<string>('Published');

  const questionsList: QuestionItem[] = [
    {
      id: '#782345',
      question: 'What is the SI unit of force?',
      category: 'NTA',
      subject: 'Physics',
      topic: 'Units & Measurements',
      difficulty: 'Easy',
      type: 'MCQ',
      status: 'Published',
    },
    {
      id: '#782346',
      question: 'Which law explains the motion of planets?',
      category: 'NTA',
      subject: 'Physics',
      topic: 'Gravitation',
      difficulty: 'Medium',
      type: 'MCQ',
      status: 'Published',
    },
    {
      id: '#782347',
      question: 'Solve for x: 2x + 5 = 15',
      category: 'NTA',
      subject: 'Mathematics',
      topic: 'Linear Equations',
      difficulty: 'Easy',
      type: 'Numerical',
      status: 'Published',
    },
    {
      id: '#782348',
      question: 'The process of photosynthesis occurs in?',
      category: 'NTA',
      subject: 'Biology',
      topic: 'Plant Physiology',
      difficulty: 'Easy',
      type: 'MCQ',
      status: 'Draft',
    },
    {
      id: '#782349',
      question: 'If sin θ = 1/2, then θ = ?',
      category: 'NTA',
      subject: 'Mathematics',
      topic: 'Trigonometry',
      difficulty: 'Medium',
      type: 'MCQ',
      status: 'Published',
    },
    {
      id: '#782350',
      question: 'Which gas is known as laughing gas?',
      category: 'NTA',
      subject: 'Chemistry',
      topic: 'Gases',
      difficulty: 'Easy',
      type: 'MCQ',
      status: 'Published',
    },
    {
      id: '#782351',
      question: 'Match the following columns.',
      category: 'NTA',
      subject: 'Biology',
      topic: 'Human Anatomy',
      difficulty: 'Hard',
      type: 'Match',
      status: 'Published',
    },
    {
      id: '#782352',
      question: 'The speed of light is approximately?',
      category: 'NTA',
      subject: 'Physics',
      topic: 'Wave Optics',
      difficulty: 'Medium',
      type: 'MCQ',
      status: 'Archived',
    },
  ];

  return (
    <div className="space-y-6 text-slate-900 select-none">
      
      {/* Top Header Card */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 bg-white p-4 rounded-3xl border border-slate-200/80 shadow-xs">
        <div>
          <h1 className="text-xl font-black text-slate-900 tracking-tight">Questions</h1>
          <p className="text-xs text-slate-400 font-semibold flex items-center gap-1 mt-0.5">
            <span>Dashboard</span>
            <span>›</span>
            <span>Question Bank</span>
            <span>›</span>
            <span className="text-[#5D3EED] font-bold">Questions</span>
          </p>
        </div>

        <div className="flex items-center gap-3">
          <button className="px-4 py-2.5 rounded-xl border border-slate-200 hover:bg-slate-50 text-slate-700 font-extrabold text-xs flex items-center gap-1.5 transition-colors shadow-xs">
            <Upload className="w-4 h-4 text-slate-500" />
            <span>Import Questions</span>
          </button>

          <button className="px-4 py-2.5 rounded-xl bg-[#5D3EED] hover:bg-[#4F46E5] text-white font-extrabold text-xs shadow-md shadow-indigo-600/20 flex items-center gap-1.5 transition-all">
            <Plus className="w-4 h-4 stroke-[3]" />
            <span>Add New Question</span>
            <ChevronDown className="w-3.5 h-3.5 text-indigo-200 ml-1" />
          </button>
        </div>
      </div>

      {/* ========================================================================= */}
      {/* 1. 4 KPI METRIC SUMMARY CARDS ROW */}
      {/* ========================================================================= */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        
        {/* Card 1: Total Questions */}
        <div className="bg-white border border-slate-200/80 rounded-2xl p-4 flex items-center gap-3.5 shadow-xs">
          <div className="w-12 h-12 rounded-2xl bg-purple-50 text-[#5D3EED] border border-purple-100 flex items-center justify-center flex-shrink-0">
            <Mail className="w-6 h-6 stroke-[2]" />
          </div>
          <div>
            <span className="text-[11px] font-bold text-slate-400 block">Total Questions</span>
            <span className="text-xl font-black text-slate-900 block leading-tight">84,320</span>
            <span className="text-[10px] text-slate-400 font-semibold block mt-0.5">All time questions</span>
          </div>
        </div>

        {/* Card 2: Published */}
        <div className="bg-white border border-slate-200/80 rounded-2xl p-4 flex items-center gap-3.5 shadow-xs">
          <div className="w-12 h-12 rounded-2xl bg-emerald-50 text-emerald-500 border border-emerald-100 flex items-center justify-center flex-shrink-0">
            <CheckCircle2 className="w-6 h-6 stroke-[2]" />
          </div>
          <div>
            <span className="text-[11px] font-bold text-slate-400 block">Published</span>
            <span className="text-xl font-black text-slate-900 block leading-tight">72,456</span>
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
            <span className="text-xl font-black text-slate-900 block leading-tight">8,764</span>
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
            <span className="text-xl font-black text-slate-900 block leading-tight">3,100</span>
            <span className="text-[10px] text-slate-400 font-semibold block mt-0.5">Not in use</span>
          </div>
        </div>

      </div>

      {/* ========================================================================= */}
      {/* 2. QUESTION CATEGORIES SELECTOR TABS */}
      {/* ========================================================================= */}
      <div className="bg-white border border-slate-200/80 rounded-3xl p-5 space-y-3 shadow-xs">
        <div className="flex flex-col sm:flex-row sm:items-center gap-4">
          <span className="text-xs font-extrabold text-slate-900 uppercase tracking-wider">
            Question Categories
          </span>

          <div className="flex items-center gap-2 overflow-x-auto custom-scrollbar">
            {/* NTA Tab (Active) */}
            <button
              onClick={() => setActiveCategoryTab('NTA')}
              className={`px-4 py-2 rounded-xl text-xs font-extrabold flex items-center gap-2 transition-all shadow-xs ${
                activeCategoryTab === 'NTA'
                  ? 'bg-[#5D3EED] text-white shadow-indigo-600/30'
                  : 'bg-slate-100 text-slate-700 hover:bg-slate-200'
              }`}
            >
              <span>NTA</span>
              <span className={`px-2 py-0.5 rounded-lg text-[10px] font-bold ${
                activeCategoryTab === 'NTA' ? 'bg-purple-900/40 text-purple-200' : 'bg-slate-200 text-slate-600'
              }`}>
                42,350
              </span>
            </button>

            {/* PYQs Tab */}
            <button
              onClick={() => setActiveCategoryTab('PYQs')}
              className={`px-4 py-2 rounded-xl text-xs font-bold flex items-center gap-2 transition-all ${
                activeCategoryTab === 'PYQs'
                  ? 'bg-[#5D3EED] text-white shadow-indigo-600/30'
                  : 'bg-slate-100 text-slate-700 hover:bg-slate-200'
              }`}
            >
              <span>PYQs</span>
              <span className="px-2 py-0.5 rounded-lg bg-slate-200 text-slate-600 text-[10px] font-bold">
                28,450
              </span>
            </button>

            {/* NCERT Tab */}
            <button
              onClick={() => setActiveCategoryTab('NCERT')}
              className={`px-4 py-2 rounded-xl text-xs font-bold flex items-center gap-2 transition-all ${
                activeCategoryTab === 'NCERT'
                  ? 'bg-[#5D3EED] text-white shadow-indigo-600/30'
                  : 'bg-slate-100 text-slate-700 hover:bg-slate-200'
              }`}
            >
              <span>NCERT</span>
              <span className="px-2 py-0.5 rounded-lg bg-slate-200 text-slate-600 text-[10px] font-bold">
                9,620
              </span>
            </button>

            {/* Others Tab */}
            <button
              onClick={() => setActiveCategoryTab('Others')}
              className={`px-4 py-2 rounded-xl text-xs font-bold flex items-center gap-2 transition-all ${
                activeCategoryTab === 'Others'
                  ? 'bg-[#5D3EED] text-white shadow-indigo-600/30'
                  : 'bg-slate-100 text-slate-700 hover:bg-slate-200'
              }`}
            >
              <span>Others</span>
              <span className="px-2 py-0.5 rounded-lg bg-slate-200 text-slate-600 text-[10px] font-bold">
                3,900
              </span>
            </button>
          </div>
        </div>

        <p className="text-xs text-slate-400 font-medium pt-1">
          Questions created by NTA from official sources and pattern.
        </p>
      </div>

      {/* ========================================================================= */}
      {/* 3. SEARCH & FILTERS BAR WITH APPLIED FILTER PILLS */}
      {/* ========================================================================= */}
      <div className="bg-white border border-slate-200/80 rounded-2xl p-4 space-y-3 shadow-xs">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div className="flex flex-wrap items-center gap-3">
            
            {/* Search Input */}
            <div className="relative">
              <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
              <input
                type="text"
                placeholder="Search by question, keyword or ID..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-72 pl-10 pr-4 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold text-slate-800 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:bg-white"
              />
            </div>

            {/* Select Subject */}
            <div className="flex items-center gap-1.5 bg-slate-50 border border-slate-200 rounded-xl px-3.5 py-2 text-xs font-bold text-slate-700 cursor-pointer">
              <span>Select Subject</span>
              <ChevronDown className="w-3.5 h-3.5 text-slate-400" />
            </div>

            {/* Select Chapter */}
            <div className="flex items-center gap-1.5 bg-slate-50 border border-slate-200 rounded-xl px-3.5 py-2 text-xs font-bold text-slate-700 cursor-pointer">
              <span>Select Chapter</span>
              <ChevronDown className="w-3.5 h-3.5 text-slate-400" />
            </div>

            {/* Select Topic */}
            <div className="flex items-center gap-1.5 bg-slate-50 border border-slate-200 rounded-xl px-3.5 py-2 text-xs font-bold text-slate-700 cursor-pointer">
              <span>Select Topic</span>
              <ChevronDown className="w-3.5 h-3.5 text-slate-400" />
            </div>

            {/* Select Difficulty */}
            <div className="flex items-center gap-1.5 bg-slate-50 border border-slate-200 rounded-xl px-3.5 py-2 text-xs font-bold text-slate-700 cursor-pointer">
              <span>Select Difficulty</span>
              <ChevronDown className="w-3.5 h-3.5 text-slate-400" />
            </div>

            {/* Select Status */}
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

        {/* Applied Filters Strip */}
        <div className="flex items-center gap-2 text-xs font-bold text-slate-500 pt-1 border-t border-slate-100">
          <span>Applied Filters:</span>

          <span className="px-2.5 py-0.5 rounded-lg bg-slate-100 border border-slate-200 text-slate-700 text-[10px] flex items-center gap-1 font-bold">
            Category: NTA
            <X className="w-3 h-3 text-slate-400 hover:text-slate-600 cursor-pointer" />
          </span>

          <span className="px-2.5 py-0.5 rounded-lg bg-slate-100 border border-slate-200 text-slate-700 text-[10px] flex items-center gap-1 font-bold">
            Subject: Physics
            <X className="w-3 h-3 text-slate-400 hover:text-slate-600 cursor-pointer" />
          </span>

          <span className="px-2.5 py-0.5 rounded-lg bg-slate-100 border border-slate-200 text-slate-700 text-[10px] flex items-center gap-1 font-bold">
            Status: Published
            <X className="w-3 h-3 text-slate-400 hover:text-slate-600 cursor-pointer" />
          </span>

          <button className="text-[#5D3EED] font-extrabold text-[11px] hover:underline ml-1">
            Clear All
          </button>
        </div>
      </div>

      {/* ========================================================================= */}
      {/* 4. MAIN LAYOUT: DATA TABLE (8 COLS) VS ANALYTICS SIDEBAR (4 COLS) */}
      {/* ========================================================================= */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        
        {/* Left 8 Cols: Questions Table */}
        <div className="lg:col-span-8 bg-white border border-slate-200/80 rounded-3xl p-5 space-y-4 shadow-xs">
          <h3 className="text-sm font-extrabold text-slate-900">All Questions (42,350)</h3>

          <div className="overflow-x-auto custom-scrollbar">
            <table className="w-full text-left text-xs font-semibold text-slate-700">
              <thead>
                <tr className="border-b border-slate-200/80 text-slate-400 uppercase text-[10px] tracking-wider font-extrabold">
                  <th className="pb-3 pr-2 w-8">
                    <input type="checkbox" className="rounded border-slate-300 text-[#5D3EED]" />
                  </th>
                  <th className="pb-3 px-3">Question</th>
                  <th className="pb-3 px-3">Category</th>
                  <th className="pb-3 px-3">Subject</th>
                  <th className="pb-3 px-3">Topic</th>
                  <th className="pb-3 px-3">Difficulty</th>
                  <th className="pb-3 px-3">Type</th>
                  <th className="pb-3 px-3">Status</th>
                  <th className="pb-3 pl-3 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {questionsList.map((item, index) => (
                  <tr key={index} className="hover:bg-slate-50/80 transition-colors">
                    <td className="py-3.5 pr-2">
                      <input type="checkbox" className="rounded border-slate-300 text-[#5D3EED]" />
                    </td>

                    <td className="py-3.5 px-3 max-w-xs">
                      <div>
                        <span className="font-extrabold text-slate-400 block text-[10px]">
                          {item.id}
                        </span>
                        <span className="font-extrabold text-slate-900 block text-xs truncate">
                          {item.question}
                        </span>
                      </div>
                    </td>

                    <td className="py-3.5 px-3">
                      <span className="px-2 py-0.5 rounded bg-purple-50 text-purple-600 font-extrabold text-[10px]">
                        {item.category}
                      </span>
                    </td>

                    <td className="py-3.5 px-3 font-bold text-slate-800">{item.subject}</td>
                    <td className="py-3.5 px-3 font-bold text-slate-600 text-[11px] truncate max-w-[120px]">
                      {item.topic}
                    </td>

                    <td className="py-3.5 px-3">
                      <span
                        className={`px-2 py-0.5 rounded font-bold text-[10px] ${
                          item.difficulty === 'Easy'
                            ? 'bg-emerald-50 text-emerald-600'
                            : item.difficulty === 'Medium'
                            ? 'bg-amber-50 text-amber-600'
                            : 'bg-rose-50 text-rose-600'
                        }`}
                      >
                        {item.difficulty}
                      </span>
                    </td>

                    <td className="py-3.5 px-3 font-bold text-slate-700 text-[11px]">{item.type}</td>

                    <td className="py-3.5 px-3">
                      <span
                        className={`px-2.5 py-1 rounded-full font-extrabold text-[10px] ${
                          item.status === 'Published'
                            ? 'bg-emerald-50 text-emerald-600'
                            : item.status === 'Draft'
                            ? 'bg-amber-50 text-amber-600'
                            : 'bg-rose-50 text-rose-600'
                        }`}
                      >
                        {item.status}
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
            <span>Showing 1 to 10 of 42,350 entries</span>

            <div className="flex items-center gap-3">
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
                <button className="w-7 h-7 rounded-lg border border-slate-200 flex items-center justify-center hover:bg-slate-50 text-slate-700">
                  4
                </button>
                <button className="w-7 h-7 rounded-lg border border-slate-200 flex items-center justify-center hover:bg-slate-50 text-slate-700">
                  5
                </button>
                <span className="px-1 text-slate-400 font-bold">...</span>
                <button className="w-7 h-7 rounded-lg border border-slate-200 flex items-center justify-center hover:bg-slate-50 text-slate-700">
                  4235
                </button>
                <button className="w-7 h-7 rounded-lg border border-slate-200 flex items-center justify-center hover:bg-slate-50 text-slate-700">
                  <ChevronRight className="w-4 h-4" />
                </button>
              </div>

              <div className="flex items-center gap-1 border border-slate-200 rounded-lg px-2.5 py-1 bg-white">
                <span>10 / page</span>
                <ChevronDown className="w-3.5 h-3.5 text-slate-400" />
              </div>
            </div>
          </div>
        </div>

        {/* Right 4 Cols: Analytics & Quick Actions Widgets */}
        <div className="lg:col-span-4 space-y-4">
          
          {/* 1. Overview (NTA) Widget */}
          <div className="bg-white border border-slate-200/80 rounded-3xl p-5 space-y-3 shadow-xs">
            <div className="flex items-center justify-between">
              <h3 className="text-xs font-extrabold text-slate-900">Overview (NTA)</h3>
            </div>

            <div className="space-y-2 text-xs font-semibold text-slate-700">
              <div className="flex items-center justify-between">
                <span className="text-slate-400">Total Questions</span>
                <span className="font-extrabold text-slate-900">42,350</span>
              </div>

              <div className="flex items-center justify-between">
                <span className="flex items-center gap-1.5">
                  <span className="w-2 h-2 rounded-full bg-emerald-500" />
                  <span>Published</span>
                </span>
                <span className="font-extrabold text-slate-900">
                  36,920 <span className="text-[10px] text-slate-400 font-normal">(87.2%)</span>
                </span>
              </div>

              <div className="flex items-center justify-between">
                <span className="flex items-center gap-1.5">
                  <span className="w-2 h-2 rounded-full bg-amber-500" />
                  <span>Draft</span>
                </span>
                <span className="font-extrabold text-slate-900">
                  3,450 <span className="text-[10px] text-slate-400 font-normal">(8.1%)</span>
                </span>
              </div>

              <div className="flex items-center justify-between">
                <span className="flex items-center gap-1.5">
                  <span className="w-2 h-2 rounded-full bg-rose-500" />
                  <span>Archived</span>
                </span>
                <span className="font-extrabold text-slate-900">
                  1,980 <span className="text-[10px] text-slate-400 font-normal">(4.7%)</span>
                </span>
              </div>
            </div>
          </div>

          {/* 2. By Difficulty Donut Chart Widget */}
          <div className="bg-white border border-slate-200/80 rounded-3xl p-5 space-y-3 shadow-xs">
            <h3 className="text-xs font-extrabold text-slate-900">By Difficulty</h3>

            <div className="flex items-center justify-between gap-4">
              {/* Donut Chart Ring */}
              <div className="relative w-24 h-24 flex-shrink-0 flex items-center justify-center">
                <svg viewBox="0 0 36 36" className="w-full h-full transform -rotate-90">
                  <path
                    d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                    fill="none"
                    stroke="#10B981"
                    strokeWidth="4"
                    strokeDasharray="38, 100"
                  />
                  <path
                    d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                    fill="none"
                    stroke="#F59E0B"
                    strokeWidth="4"
                    strokeDasharray="37, 100"
                    strokeDashoffset="-38"
                  />
                  <path
                    d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                    fill="none"
                    stroke="#EF4444"
                    strokeWidth="4"
                    strokeDasharray="25, 100"
                    strokeDashoffset="-75"
                  />
                </svg>
              </div>

              {/* Breakdown Legend */}
              <div className="space-y-1.5 text-xs font-semibold text-slate-700 flex-1">
                <div className="flex items-center justify-between">
                  <span className="flex items-center gap-1.5">
                    <span className="w-2 h-2 rounded-full bg-emerald-500" />
                    <span>Easy</span>
                  </span>
                  <span className="font-extrabold text-slate-900">
                    16,250 <span className="text-[10px] text-slate-400 font-normal">(38.3%)</span>
                  </span>
                </div>

                <div className="flex items-center justify-between">
                  <span className="flex items-center gap-1.5">
                    <span className="w-2 h-2 rounded-full bg-amber-500" />
                    <span>Medium</span>
                  </span>
                  <span className="font-extrabold text-slate-900">
                    15,820 <span className="text-[10px] text-slate-400 font-normal">(37.3%)</span>
                  </span>
                </div>

                <div className="flex items-center justify-between">
                  <span className="flex items-center gap-1.5">
                    <span className="w-2 h-2 rounded-full bg-rose-500" />
                    <span>Hard</span>
                  </span>
                  <span className="font-extrabold text-slate-900">
                    10,280 <span className="text-[10px] text-slate-400 font-normal">(24.2%)</span>
                  </span>
                </div>
              </div>
            </div>
          </div>

          {/* 3. Quick Actions Widget */}
          <div className="bg-white border border-slate-200/80 rounded-3xl p-5 space-y-3 shadow-xs">
            <h3 className="text-xs font-extrabold text-slate-900">Quick Actions</h3>

            <div className="space-y-2">
              {/* Action 1 */}
              <div className="p-3 bg-slate-50 border border-slate-200/80 rounded-2xl flex items-center justify-between cursor-pointer hover:bg-slate-100 transition-colors">
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 rounded-xl bg-purple-100 text-[#5D3EED] flex items-center justify-center">
                    <Plus className="w-4 h-4" />
                  </div>
                  <div>
                    <h4 className="text-xs font-extrabold text-slate-900">Add New Question</h4>
                    <p className="text-[10px] text-slate-400 font-medium">Create a new question manually</p>
                  </div>
                </div>
                <button className="p-1 rounded-lg bg-white border border-slate-200 text-slate-600">
                  <Plus className="w-3.5 h-3.5" />
                </button>
              </div>

              {/* Action 2 */}
              <div className="p-3 bg-slate-50 border border-slate-200/80 rounded-2xl flex items-center justify-between cursor-pointer hover:bg-slate-100 transition-colors">
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 rounded-xl bg-blue-100 text-blue-600 flex items-center justify-center">
                    <Upload className="w-4 h-4" />
                  </div>
                  <div>
                    <h4 className="text-xs font-extrabold text-slate-900">Import Questions</h4>
                    <p className="text-[10px] text-slate-400 font-medium">Import from Excel / CSV</p>
                  </div>
                </div>
                <button className="p-1 rounded-lg bg-white border border-slate-200 text-slate-600">
                  <Upload className="w-3.5 h-3.5" />
                </button>
              </div>

              {/* Action 3 */}
              <div className="p-3 bg-slate-50 border border-slate-200/80 rounded-2xl flex items-center justify-between cursor-pointer hover:bg-slate-100 transition-colors">
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 rounded-xl bg-cyan-100 text-cyan-600 flex items-center justify-center">
                    <FileSpreadsheet className="w-4 h-4" />
                  </div>
                  <div>
                    <h4 className="text-xs font-extrabold text-slate-900">Bulk Upload</h4>
                    <p className="text-[10px] text-slate-400 font-medium">Upload multiple questions</p>
                  </div>
                </div>
                <button className="p-1 rounded-lg bg-white border border-slate-200 text-slate-600">
                  <Upload className="w-3.5 h-3.5" />
                </button>
              </div>

              {/* Action 4 */}
              <div className="p-3 bg-slate-50 border border-slate-200/80 rounded-2xl flex items-center justify-between cursor-pointer hover:bg-slate-100 transition-colors">
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 rounded-xl bg-purple-100 text-purple-600 flex items-center justify-center">
                    <Layers className="w-4 h-4" />
                  </div>
                  <div>
                    <h4 className="text-xs font-extrabold text-slate-900">Question Sets</h4>
                    <p className="text-[10px] text-slate-400 font-medium">Manage question sets</p>
                  </div>
                </div>
                <button className="p-1 rounded-lg bg-white border border-slate-200 text-slate-600">
                  <Layers className="w-3.5 h-3.5" />
                </button>
              </div>
            </div>
          </div>

          {/* 4. Tips Box Widget */}
          <div className="bg-[#FFFBF5] border border-[#FDE68A] rounded-3xl p-4 space-y-2 shadow-xs">
            <div className="flex items-center gap-2">
              <Lightbulb className="w-4 h-4 text-amber-500 fill-amber-400" />
              <h4 className="text-xs font-extrabold text-slate-900">Tips</h4>
            </div>
            <p className="text-[11px] text-slate-600 font-medium leading-relaxed">
              Use filters and tags to organize questions better and improve searchability.
            </p>
            <button className="text-[#5D3EED] font-extrabold text-xs flex items-center gap-1 hover:underline pt-1">
              <span>Learn more</span>
              <ArrowRight className="w-3.5 h-3.5" />
            </button>
          </div>

        </div>

      </div>

    </div>
  );
};
