# Supabase Migration & Setup Guide (New Account)

Follow these steps to deploy the database schema, security policies, stored procedures, and starter question banks onto a **NEW Supabase Account & Project**.

---

## Step 1: Create New Supabase Project

1. Go to [https://supabase.com](https://supabase.com) and create/login to your **New Supabase Account**.
2. Click **New Project** and configure:
   - **Project Name**: `Cosmyra NEET JEE Platform`
   - **Database Password**: Choose a strong password.
   - **Region**: Choose the region closest to your primary target audience (e.g. `ap-south-1` South Asia / Mumbai for India).
3. Copy your project credentials from **Project Settings → API**:
   - `Project URL` (e.g., `https://xyz...supabase.co`)
   - `anon / public` API Key
   - `service_role` Secret Key

---

## Step 2: Execute SQL Migrations (In Sequential Order)

In your Supabase Dashboard, open **SQL Editor → New Query** and execute the migration files located in `supabase/migrations/` in exact order:

### 1. Execute `01_schema.sql`
Copy the contents of [supabase/migrations/01_schema.sql](file:///Users/mahboobhasan/Desktop/Cosmyra%20Edu%20Flutter/supabase/migrations/01_schema.sql) into the SQL Editor and click **Run**.
> **Result**: Creates tables for `profiles`, `exams`, `subjects`, `chapters`, `topics`, `questions`, `question_options`, `test_templates`, `test_attempts`, `practice_sessions`, `bookmarks`, `mistake_questions`, `leaderboards`, `reports`, and `admin_logs`.

### 2. Execute `02_rls.sql`
Copy the contents of [supabase/migrations/02_rls.sql](file:///Users/mahboobhasan/Desktop/Cosmyra%20Edu%20Flutter/supabase/migrations/02_rls.sql) into the SQL Editor and click **Run**.
> **Result**: Applies Row Level Security policies protecting student profiles, attempt results, and granting question authoring rights to `admin` users.

### 3. Execute `03_functions.sql`
Copy the contents of [supabase/migrations/03_functions.sql](file:///Users/mahboobhasan/Desktop/Cosmyra%20Edu%20Flutter/supabase/migrations/03_functions.sql) into the SQL Editor and click **Run**.
> **Result**: Creates stored functions for score calculations, streak updates, and anti-cheat leaderboard calculation.

### 4. Execute `04_seed.sql`
Copy the contents of [supabase/migrations/04_seed.sql](file:///Users/mahboobhasan/Desktop/Cosmyra%20Edu%20Flutter/supabase/migrations/04_seed.sql) into the SQL Editor and click **Run**.
> **Result**: Seeds default NEET UG & JEE Main/Advanced hierarchy, subjects (Physics, Chemistry, Biology, Mathematics), chapters, and sample LaTeX MCQs.

---

## Step 3: Configure Storage Buckets (Optional for Images)

In Supabase Dashboard → **Storage → Buckets**:
1. Create a public bucket named `question-images`.
2. Create a public bucket named `user-avatars`.

---

## Step 4: Configure Authentication

In Supabase Dashboard → **Authentication → Providers**:
1. Enable **Email** authentication.
2. (Optional) Enable **Google Sign-In** by adding your Client ID and Client Secret.
