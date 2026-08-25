# Supabase Backend Setup & Migration Guide

## 1. Create Supabase Project
1. Log into [Supabase Dashboard](https://supabase.com).
2. Click **New Project** and name it `cosmyra-exam-platform`.

## 2. Execute SQL Migrations
In the Supabase **SQL Editor**, run the migration scripts in the following exact sequence:

1. [`01_schema.sql`](file:///Users/mahboobhasan/Desktop/Cosmyra%20Neet%20Jee%20v2/supabase/migrations/01_schema.sql): Table definitions, foreign keys, enums, indexes.
2. [`02_rls.sql`](file:///Users/mahboobhasan/Desktop/Cosmyra%20Neet%20Jee%20v2/supabase/migrations/02_rls.sql): Row Level Security policies for all roles.
3. [`03_functions.sql`](file:///Users/mahboobhasan/Desktop/Cosmyra%20Neet%20Jee%20v2/supabase/migrations/03_functions.sql): RPC functions for score calculation & attempts.
4. [`04_seed.sql`](file:///Users/mahboobhasan/Desktop/Cosmyra%20Neet%20Jee%20v2/supabase/migrations/04_seed.sql): Seed data for NEET & JEE physics, chemistry, biology, mathematics, and test invites.

## 3. Deploy Edge Functions
```bash
supabase functions deploy create-test-attempt
supabase functions deploy submit-test
supabase functions deploy join-teacher-test
```
