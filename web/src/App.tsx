import React, { useState } from 'react';
import { BrowserRouter, Routes, Route, Navigate, useNavigate, useLocation } from 'react-router-dom';

// Localhost Environment Switcher Bar
import { LocalhostEnvironmentBar } from './components/layout/LocalhostEnvironmentBar';

// Layout Components
import { LandingNavbar } from './components/layout/LandingNavbar';
import { StudentHeader } from './components/layout/StudentHeader';
import { StudentSidebar } from './components/layout/StudentSidebar';
import { AdminHeader } from './components/layout/AdminHeader';
import { AdminSidebar } from './components/layout/AdminSidebar';
import { BottomNav } from './components/layout/BottomNav';

// Public Landing Page
import { LandingPage } from './pages/public/LandingPage';
import { PricingPage } from './pages/public/PricingPage';
import { SignUpPage } from './pages/public/SignUpPage';

// Mobile App Dashboard Screens
import { MobileAppDashboard } from './pages/student/MobileAppDashboard';
import { TeacherMobileAppDashboard } from './pages/teacher/TeacherMobileAppDashboard';

// Student Pages
import { StudentDashboard } from './pages/student/Dashboard';
import { CustomPractice } from './pages/student/CustomPractice';
import { CustomTestEngine } from './pages/student/CustomTest';
import { PYQSection } from './pages/student/PYQSection';
import { LeaderboardView } from './pages/student/Leaderboard';
import { TestInviteView } from './pages/student/TestInviteView';
import { StudentProfile } from './pages/student/StudentProfile';
import { NewPracticeWizard } from './pages/student/NewPracticeWizard';
import { ActivePracticeInterface } from './pages/student/ActivePracticeInterface';
import { InstantFeedbackInterface } from './pages/student/InstantFeedbackInterface';
import { DetailedSolutionView } from './pages/student/DetailedSolutionView';
import { MobilePricingScreen } from './pages/student/MobilePricingScreen';

// Teacher Pages
import { TeacherDashboardView } from './pages/teacher/TeacherDashboard';
import { CreateTestWizard } from './pages/teacher/CreateTestWizard';

// Admin Pages
import { AdminDashboardView } from './pages/admin/AdminDashboard';
import { TaxonomyManagerView } from './pages/admin/TaxonomyManager';
import { QuestionModerationView } from './pages/admin/QuestionModeration';
import { PlatformSettingsView } from './pages/admin/PlatformSettings';
import { AdminPricingPlans } from './pages/admin/AdminPricingPlans';
import { AdminOffersCoupons } from './pages/admin/AdminOffersCoupons';
import { AdminPaperPrediction } from './pages/admin/AdminPaperPrediction';
import { AdminQuestionsBank } from './pages/admin/AdminQuestionsBank';

function Layout({ children }: { children: React.ReactNode }) {
  const location = useLocation();
  const [selectedExam, setSelectedExam] = useState<string>('NEET');
  const [isAdminCollapsed, setIsAdminCollapsed] = useState<boolean>(false);

  const isLandingPage = location.pathname === '/';
  const isUserMobileApp = location.pathname.startsWith('/app') || location.pathname.startsWith('/mobile-app');
  const isTeacherMobileApp = location.pathname.startsWith('/teacher-app') || location.pathname.startsWith('/teacher-mobile');
  const isTeacherWebsite = location.pathname.startsWith('/teacher');
  const isAdmin = location.pathname.startsWith('/admin');

  // 1. USER MOBILE APP LAYOUT (PORT 3001 OR /app)
  if (isUserMobileApp) {
    return (
      <div className="min-h-screen bg-slate-900 flex flex-col">
        <div className="flex-1">{children}</div>
      </div>
    );
  }

  // 2. TEACHER MOBILE APP LAYOUT (PORT 3003 OR /teacher-app)
  if (isTeacherMobileApp) {
    return (
      <div className="min-h-screen bg-slate-950 flex flex-col">
        <div className="flex-1">{children}</div>
      </div>
    );
  }

  // 3. PUBLIC LANDING PAGE LAYOUT
  if (isLandingPage) {
    return (
      <div className="min-h-screen bg-slate-50 text-gray-900 font-sans flex flex-col">
        <LandingNavbar />
        <main className="flex-1 w-full">{children}</main>
      </div>
    );
  }

  // 4. ADMIN DASHBOARD CONSOLE LAYOUT (PORT 3004 OR /admin)
  if (isAdmin) {
    return (
      <div className="min-h-screen bg-slate-50 text-gray-900 font-sans flex flex-col">
        <div className="flex flex-1">
          <AdminSidebar
            isCollapsed={isAdminCollapsed}
            onToggleCollapse={() => setIsAdminCollapsed(!isAdminCollapsed)}
          />
          <div className="flex-1 flex flex-col min-w-0">
            <AdminHeader onToggleSidebar={() => setIsAdminCollapsed(!isAdminCollapsed)} />
            <main className="flex-1 p-4 lg:p-6 max-w-[1600px] w-full mx-auto overflow-y-auto">
              {children}
            </main>
          </div>
        </div>
      </div>
    );
  }

  // 5. USER WEBSITE & TEACHER WEBSITE LAYOUT (PORT 3000 & 3002)
  return (
    <div className="min-h-screen bg-[#F8FAFC] text-gray-900 font-sans flex flex-col pb-16 md:pb-0">
      <StudentHeader selectedExam={selectedExam} setSelectedExam={setSelectedExam} />

      <div className="flex-1 flex">
        <StudentSidebar />
        <main className="flex-1 p-4 lg:p-6 max-w-[1600px] w-full mx-auto overflow-y-auto">
          {children}
        </main>
      </div>

      <BottomNav />
    </div>
  );
}

export function App() {
  return (
    <BrowserRouter>
      <Layout>
        <Routes>
          {/* ============================================================ */}
          {/* 1. PUBLIC LANDING PAGE (PORT 3000 ROOT /) */}
          {/* ============================================================ */}
          <Route path="/" element={<LandingPage />} />
          <Route path="/pricing" element={<PricingPage />} />
          <Route path="/signup" element={<SignUpPage />} />
          <Route path="/register" element={<SignUpPage />} />

          {/* ============================================================ */}
          {/* 2. USER WEBSITE PAGES (PORT 3000 SLUG URLS) */}
          {/* ============================================================ */}
          <Route path="/dashboard" element={<StudentDashboardWrapper />} />
          <Route path="/student" element={<StudentDashboardWrapper />} />
          <Route path="/student/pricing" element={<PricingPage />} />
          <Route path="/practice" element={<CustomPractice />} />
          <Route path="/student/practice" element={<CustomPractice />} />
          <Route path="/student/practice/new" element={<NewPracticeWizard />} />
          <Route path="/student/practice/active" element={<ActivePracticeInterface />} />
          <Route path="/student/practice/feedback" element={<InstantFeedbackInterface />} />
          <Route path="/student/practice/solution" element={<DetailedSolutionView />} />
          <Route path="/student/app-pricing" element={<MobilePricingScreen />} />
          <Route path="/test" element={<CustomTestEngine />} />
          <Route path="/student/test" element={<CustomTestEngine />} />
          <Route path="/pyq" element={<PYQSection />} />
          <Route path="/student/pyq" element={<PYQSection />} />
          <Route path="/nta" element={<PYQSection />} />
          <Route path="/student/nta" element={<PYQSection />} />
          <Route path="/teacher-tests" element={<TestInviteViewWrapper />} />
          <Route path="/student/teacher-tests" element={<TestInviteViewWrapper />} />
          <Route path="/leaderboard" element={<LeaderboardView />} />
          <Route path="/student/leaderboard" element={<LeaderboardView />} />
          <Route path="/analytics" element={<StudentDashboardWrapper />} />
          <Route path="/bookmarks" element={<StudentDashboardWrapper />} />
          <Route path="/mistakes" element={<StudentDashboardWrapper />} />
          <Route path="/history" element={<StudentDashboardWrapper />} />
          <Route path="/profile" element={<StudentProfile />} />
          <Route path="/student/profile" element={<StudentProfile />} />

          {/* INVITATION LINK ROUTE */}
          <Route path="/invite/test/:code" element={<TestInviteViewWrapper />} />

          {/* ============================================================ */}
          {/* 3. USER MOBILE APP PAGES (PORT 3001 OR /app) */}
          {/* ============================================================ */}
          <Route path="/app" element={<MobileAppDashboard />} />
          <Route path="/app/dashboard" element={<MobileAppDashboard />} />
          <Route path="/app/practice" element={<CustomPractice />} />
          <Route path="/app/new-practice" element={<MobileAppDashboard initialTab="practice" initialWizard={true} />} />
          <Route path="/app/active-practice" element={<MobileAppDashboard initialTab="practice" initialActivePractice={true} />} />
          <Route path="/app/feedback" element={<MobileAppDashboard initialTab="practice" initialFeedback={true} />} />
          <Route path="/app/solution" element={<MobileAppDashboard initialTab="practice" initialSolution={true} />} />
          <Route path="/app/pricing-plans" element={<MobileAppDashboard initialTab="practice" initialMobilePricing={true} />} />
          <Route path="/app/payment" element={<MobileAppDashboard initialTab="practice" initialPayment={true} />} />
          <Route path="/app/paper-prediction" element={<MobileAppDashboard initialTab="practice" initialPrediction={true} />} />
          <Route path="/app/prediction" element={<MobileAppDashboard initialTab="practice" initialPrediction={true} />} />
          <Route path="/app/mock-tests" element={<MobileAppDashboard initialTab="test" />} />
          <Route path="/app/tests" element={<MobileAppDashboard initialTab="test" />} />
          <Route path="/app/analytics" element={<MobileAppDashboard initialTab="analytics" />} />
          <Route path="/app/test" element={<CustomTestEngine />} />
          <Route path="/app/profile" element={<MobileAppDashboard initialTab="profile" />} />
          <Route path="/mobile" element={<MobileAppDashboard />} />
          <Route path="/mobile-app" element={<MobileAppDashboard />} />

          {/* ============================================================ */}
          {/* 4. TEACHER WEBSITE PAGES (PORT 3002 OR /teacher) */}
          {/* ============================================================ */}
          <Route path="/teacher" element={<TeacherDashboardWrapper />} />
          <Route path="/teacher/dashboard" element={<TeacherDashboardWrapper />} />
          <Route path="/teacher/create-test" element={<CreateTestWizardWrapper />} />
          <Route path="/teacher/invitations" element={<TeacherDashboardWrapper />} />
          <Route path="/teacher/analytics" element={<TeacherDashboardWrapper />} />
          <Route path="/teacher/questions" element={<TeacherDashboardWrapper />} />

          {/* ============================================================ */}
          {/* 5. TEACHER MOBILE APP PAGES (PORT 3003 OR /teacher-app) */}
          {/* ============================================================ */}
          <Route path="/teacher-app" element={<TeacherMobileAppDashboard />} />
          <Route path="/teacher-app/dashboard" element={<TeacherMobileAppDashboard />} />
          <Route path="/teacher-app/create-test" element={<CreateTestWizardWrapper />} />

          {/* ============================================================ */}
          {/* 6. ADMIN DASHBOARD PAGES (PORT 3004 OR /admin) */}
          {/* ============================================================ */}
          <Route path="/admin" element={<AdminDashboardWrapper />} />
          <Route path="/admin/dashboard" element={<AdminDashboardWrapper />} />
          <Route path="/admin/pricing" element={<AdminPricingPlans />} />
          <Route path="/admin/pricing-plans" element={<AdminPricingPlans />} />
          <Route path="/admin/offers" element={<AdminOffersCoupons />} />
          <Route path="/admin/offers-coupons" element={<AdminOffersCoupons />} />
          <Route path="/admin/coupons" element={<AdminOffersCoupons />} />
          <Route path="/admin/paper-prediction" element={<AdminPaperPrediction />} />
          <Route path="/admin/prediction-papers" element={<AdminPaperPrediction />} />
          <Route path="/admin/questions" element={<AdminQuestionsBank />} />
          <Route path="/admin/question-bank" element={<AdminQuestionsBank />} />
          <Route path="/admin/questions-bank" element={<AdminQuestionsBank />} />
          <Route path="/admin/taxonomy" element={<TaxonomyManagerView />} />
          <Route path="/admin/moderation" element={<QuestionModerationView />} />
          <Route path="/admin/bulk-import" element={<QuestionModerationView />} />
          <Route path="/admin/teachers" element={<AdminDashboardWrapper />} />
          <Route path="/admin/students" element={<AdminDashboardWrapper />} />
          <Route path="/admin/audit-logs" element={<AdminDashboardWrapper />} />
          <Route path="/admin/settings" element={<PlatformSettingsView />} />

          {/* Fallback Catch-all Route */}
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </Layout>
    </BrowserRouter>
  );
}

// Helper Wrappers for Navigating Routes
function StudentDashboardWrapper() {
  const navigate = useNavigate();
  return (
    <StudentDashboard
      selectedExam="NEET"
      onNavigate={(tab) => {
        if (tab === 'custom_practice') navigate('/practice');
        else if (tab === 'custom_test') navigate('/test');
        else if (tab === 'pyq') navigate('/pyq');
        else if (tab === 'mistakes') navigate('/mistakes');
        else if (tab === 'analytics') navigate('/analytics');
        else navigate('/dashboard');
      }}
    />
  );
}

function TestInviteViewWrapper() {
  const navigate = useNavigate();
  return <TestInviteView onJoinTest={() => navigate('/test')} />;
}

function TeacherDashboardWrapper() {
  const navigate = useNavigate();
  return (
    <TeacherDashboardView
      onNavigate={(tab) => {
        if (tab === 'create_test') navigate('/teacher/create-test');
        else navigate('/teacher/dashboard');
      }}
    />
  );
}

function CreateTestWizardWrapper() {
  const navigate = useNavigate();
  return <CreateTestWizard onComplete={() => navigate('/teacher/dashboard')} />;
}

function AdminDashboardWrapper() {
  return <AdminDashboardView />;
}

export default App;
