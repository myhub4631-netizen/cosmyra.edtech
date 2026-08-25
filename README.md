# Cosmyra AI-Powered Competitive Exam Preparation Platform (NEET, JEE & More)

Cosmyra is a production-ready, multi-exam question practice and assessment platform designed for **NEET, JEE Main, JEE Advanced, CUET, UPSC, SSC, Banking, and future competitive examinations**.

---

## 🌟 Key Features

* **Hierarchical Exam Taxonomy**: Dynamic taxonomy (`Exam → Subject → Chapter → Topic → Subtopic → Question`). New exams can be added dynamically from the Admin Console without rebuilding code.
* **Centralized Question Bank**: Supports single-correct MCQs, numericals, assertion & reason, passage-based, and match the following questions with KaTeX formula rendering.
* **Interactive Custom Practice Engine**: Immediate answer verification, KaTeX math solutions, explanation drawers, bookmarks, and mistake reporting.
* **Exam Simulation Test Engine**: Server-authoritative timer, palette navigator (Answered, Unanswered, Marked for Review), withheld correct answer payloads during active attempts, and automated server scoring.
* **PYQ & NTA Question Banks**: Dedicated previous year papers (2020–2025) and NTA Abhyas question sets.
* **Teacher Assessment & Link Invitation System**: Teachers can pick questions from the centralized bank, set custom weightage & timers, publish tests, and generate unique invitation URLs (`/invite/test/ABC123XYZ`).
* **All-India Leaderboard & Streak System**: Daily, weekly, and monthly rank calculations based on score and accuracy.
* **Mistake Book & Bookmarks**: Auto-collected incorrect responses with "Practice My Mistakes" revision mode.
* **Admin Dashboard & Moderation**: Dynamic taxonomy editor, question review queue, teacher verification, global feature flags, and CSV bulk import with row validation reports.

---

## 🛠 Tech Stack

* **Backend**: Supabase (PostgreSQL Database, Row Level Security, Edge Functions, Auth, Storage)
* **Web App**: React 18, Vite, TypeScript, Tailwind CSS, Lucide Icons, KaTeX Math Engine
* **Mobile App**: Flutter Cross-Platform (Android, iOS & Web), Riverpod, Flutter Math
* **Hosting**: Vercel (Web Platform) & Supabase Cloud

---

## 🚀 Quickstart Guide

### 1. Database Setup (Supabase)
Apply migrations in order:
```bash
# 1. Run migrations
supabase migration up
# Or execute SQL files in Supabase SQL Editor:
# - supabase/migrations/01_schema.sql
# - supabase/migrations/02_rls.sql
# - supabase/migrations/03_functions.sql
# - supabase/migrations/04_seed.sql
```

### 2. Run Web Platform
```bash
cd web
npm install
npm run dev
# Opens at http://localhost:3000
```

### 3. Run Flutter App
```bash
cd flutter_app
flutter pub get
flutter run
```

---

## 📁 Repository Structure

```
├── supabase/
│   ├── migrations/
│   │   ├── 01_schema.sql
│   │   ├── 02_rls.sql
│   │   ├── 03_functions.sql
│   │   └── 04_seed.sql
│   └── functions/
│       ├── create-test-attempt/
│       ├── submit-test/
│       └── join-teacher-test/
├── web/
│   ├── src/
│   │   ├── components/
│   │   ├── pages/
│   │   │   ├── student/
│   │   │   ├── teacher/
│   │   │   └── admin/
│   │   └── types/
├── flutter_app/
│   └── lib/
└── docs/
    ├── ARCHITECTURE.md
    ├── DATABASE_SCHEMA.md
    ├── SUPABASE_SETUP.md
    ├── VERCEL_DEPLOYMENT.md
    ├── FLUTTER_BUILD_GUIDE.md
    └── question_import_template.csv
```
