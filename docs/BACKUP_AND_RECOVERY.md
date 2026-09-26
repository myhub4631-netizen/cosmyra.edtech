# COSMYRA NEET/JEE PLATFORM - DISASTER RECOVERY & BACKUP MANUAL

## 1. Executive Summary
This document provides the authoritative disaster recovery (DR) procedures, database backup strategy, and point-in-time recovery instructions for the Cosmyra EdTech Platform.

---

## 2. Backup Components & Frequency

| Data Component | Provider / Location | Frequency | Automation Tool |
| :--- | :--- | :--- | :--- |
| **PostgreSQL Database** | Supabase Cloud (ap-south-1) | Daily automated snapshots | Supabase Automated Backups |
| **Offsite Database Dump** | Backblaze B2 / AWS S3 | Nightly (02:00 UTC) | `scripts/backup_to_backblaze.py` |
| **SQL Migrations & Schema** | Repository `/supabase/migrations` | Every commit | Git / GitHub Versioning |
| **Question Bank Artifacts** | Storage Bucket `question-imports` | Real-time replication | Supabase Storage Backups |
| **Flutter / Web Build Bundles** | Vercel Edge / GitHub Releases | Per deployment | Vercel CI/CD Pipeline |

---

## 3. Automated Offsite Backup Procedure

The script `scripts/backup_to_backblaze.py` extracts a full PostgreSQL dump of all public schemas (`profiles`, `orders`, `entitlements`, `questions`, `test_attempts`, `leaderboard_entries`) and encrypts the output before uploading to Backblaze B2.

### Command Execution:
```bash
python3 scripts/backup_to_backblaze.py \
  --db-url "$SUPABASE_DB_URL" \
  --b2-key-id "$B2_KEY_ID" \
  --b2-application-key "$B2_APPLICATION_KEY" \
  --b2-bucket "cosmyra-production-backups"
```

---

## 4. Disaster Recovery & Restoration Walkthrough

In the event of database corruption, regional outage, or accidental data loss, execute the following step-by-step restoration workflow:

### Step 1: Provision Clean Database Instance
1. Initialize a new Supabase project or PostgreSQL instance.
2. Obtain the database connection string: `postgresql://postgres.[REF]:[PASSWORD]@aws-0-ap-south-1.pooler.supabase.com:6543/postgres`.

### Step 2: Apply Database Schema & Security Migrations
Execute all ordered migrations from `supabase/migrations/`:
```bash
# Apply migrations sequentially
node scratch/run_migration_15.js
```
This applies table definitions, triggers (`trg_prevent_role_escalation`, `trg_protect_test_attempt_integrity`), RLS policies, indexes, and RPC functions (`approve_and_fulfill_order`, `get_public_leaderboard`).

### Step 3: Restore Data Dump
```bash
pg_restore --clean --if-exists --no-owner --no-privileges \
  -d "$NEW_SUPABASE_DB_URL" \
  /path/to/latest_backup_dump.tar
```

### Step 4: Verify System Integrity & RLS Security
Run adversarial verification checks:
```bash
# Verify RLS policies are enabled and enforcing access
psql "$NEW_SUPABASE_DB_URL" -c "SELECT tablename, rowsecurity FROM pg_tables WHERE schemaname = 'public';"
```

---

## 5. Emergency Contacts & Escalation Matrix

- **System Administrator**: Mahboob Hasan (`1mdollar2027@gmail.com`)
- **Infrastructure Escalation**: Cosmyra DevOps Team
- **Production Endpoint**: `https://neet-jee.in`
- **Database Ref**: `kxlseyibgwpfthpryrgn.supabase.co`
