# Cosmyra Backblaze B2 Complete Backup & Disaster Recovery Guide

This guide explains how to automatically back up your entire platform (**Codebase, Question Bank, Postgres Database, Users, and APIs**) to **Backblaze B2** cloud storage.

---

## 🛠️ Step 1: Create Your Backblaze B2 Credentials

1. **Sign up / Log in** to [Backblaze B2 Cloud Storage](https://www.backblaze.com/b2/cloud-storage.html).
2. **Create a Bucket**:
   * Go to **B2 Cloud Storage → Buckets**.
   * Click **Create a Bucket**.
   * Bucket Name: e.g., `cosmyra-platform-backups` (must be unique).
   * Bucket Privacy: **Private**.
3. **Generate Application Keys**:
   * Go to **Account → Application Keys**.
   * Click **Add a New Application Key**.
   * Name: `cosmyra-backup-key`.
   * Allow access to Bucket: Select `cosmyra-platform-backups`.
   * Type of Access: **Read and Write**.
   * Click **Create New Key**.
4. **Copy Credentials**:
   * `keyID` (Application Key ID)
   * `applicationKey` (Secret Application Key)
   * `S3 Endpoint` (e.g. `s3.us-west-004.backblazeb2.com` found in Bucket details).

---

## 🔑 Step 2: Add Credentials to Local Environment or GitHub Secrets

### Option A: Running Backups Locally
Add the following keys to your project's `.env` file (or export them in terminal):

```env
# Backblaze B2 Configuration
B2_KEY_ID=your_key_id_here
B2_APPLICATION_KEY=your_application_key_here
B2_BUCKET_NAME=cosmyra-platform-backups
B2_ENDPOINT=s3.us-west-004.backblazeb2.com

# Supabase Postgres Connection (Found under Supabase Dashboard -> Database -> Connection String -> URI)
SUPABASE_DB_URL=postgresql://postgres:[YOUR-PASSWORD]@db.[YOUR-PROJECT-REF].supabase.co:5432/postgres
```

### Option B: Automated Daily Backups on GitHub Actions
Go to your GitHub Repository **Settings → Secrets and variables → Actions** and add:

| Secret Name | Value |
| :--- | :--- |
| `B2_KEY_ID` | Your Backblaze Key ID |
| `B2_APPLICATION_KEY` | Your Backblaze Secret Application Key |
| `B2_BUCKET_NAME` | Your Backblaze Bucket Name |
| `B2_ENDPOINT` | `s3.us-west-004.backblazeb2.com` |
| `SUPABASE_DB_URL` | Your Supabase Postgres URI |

---

## 🚀 Step 3: Running a Backup

### Local Execution (Manual)
Make sure Python 3 and `awscli` are available (`pip install awscli`):

```bash
python3 scripts/backup_to_backblaze.py
```

**What this script does:**
1. Packages the codebase into `cosmyra_codebase_YYYYMMDD_HHMMSS.tar.gz`.
2. Dumps the complete database & schema into `cosmyra_db_YYYYMMDD_HHMMSS.sql`.
3. Exports core Question Bank tables.
4. Uploads all files directly to your private Backblaze B2 bucket under `/backups/YYYY-MM/`.
5. Cleans up temporary local archive files.

### Automated Daily Execution (GitHub Actions)
The workflow `.github/workflows/daily_backblaze_backup.yml` runs automatically **every night at 2:00 AM UTC (7:30 AM IST)**.

You can also trigger it manually at any time:
1. Go to **GitHub Repo → Actions**.
2. Select **Daily Backblaze B2 Backup**.
3. Click **Run workflow**.

---

## 🔄 Step 4: How to Restore System From Backblaze B2

If your system is completely deleted or lost, restore in 4 steps:

### 1. Download Backup Files from Backblaze B2
Using AWS CLI or Backblaze Web Console, download the latest `cosmyra_codebase_*.tar.gz` and `cosmyra_db_*.sql`.

```bash
aws s3 cp s3://cosmyra-platform-backups/backups/2026-09/cosmyra_codebase_20260902_090000.tar.gz . --endpoint-url https://s3.us-west-004.backblazeb2.com
aws s3 cp s3://cosmyra-platform-backups/backups/2026-09/cosmyra_db_20260902_090000.sql . --endpoint-url https://s3.us-west-004.backblazeb2.com
```

### 2. Extract Codebase
```bash
tar -xzf cosmyra_codebase_20260902_090000.tar.gz
cd cosmyra
```

### 3. Restore Database to New Supabase Project
Spin up a new Supabase project and restore your database:
```bash
psql -h db.[NEW-PROJECT-REF].supabase.co -U postgres -d postgres -f cosmyra_db_20260902_090000.sql
```

### 4. Re-deploy Edge Functions & Web App
```bash
# Deploy edge functions to new Supabase project
supabase link --project-ref <NEW-PROJECT-REF>
supabase functions deploy

# Update Vercel env vars with new SUPABASE_URL and SUPABASE_ANON_KEY and re-deploy web
```
