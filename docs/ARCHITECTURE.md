# Cosmyra Platform Architecture & Technical Design

## System Architecture

```
[Flutter Mobile / Web] <---> [REST / Edge Functions] <---> [Supabase PostgreSQL + RLS]
[React Web Application] <---> [Supabase Auth]         <---> [Supabase Storage]
```

## Security & Data Isolation Model

1. **Role-Based Access Control (RBAC)**: Enforced using PostgreSQL Row Level Security policies (`user_roles`).
   - `Student`: Accesses practice questions, submits test attempts, views own performance & leaderboards.
   - `Teacher`: Creates tests from centralized bank, views attempt statistics of invited students, generates invitation codes.
   - `Admin / Super Admin`: Full platform control, taxonomy editor, bulk CSV importer, teacher verification, global settings.

2. **Test & Answer Security**: During active test mode (`attempt_status = 'in_progress'`), options returned to client payloads explicitly exclude `is_correct` flags, and question solutions are stripped by Supabase Edge Functions. Final test scoring is computed server-authoritatively via stored RPC procedures.

3. **Server-Authoritative Timers**: Test start timestamps and expiration times are governed by PostgreSQL `NOW()` timestamps rather than client device clocks.
