#!/usr/bin/env python3
"""
Cosmyra Platform - Complete Offline Backup & Storage Asset Extractor
---------------------------------------------------------------------
This script creates a comprehensive, self-contained offline backup directory:

Cosmyra_Offline_Backups/
└── YYYY-MM/
    ├── CODEBASE/
    │   └── cosmyra_codebase.tar.gz
    ├── DATABASE/
    │   └── cosmyra_db_full.sql
    ├── QUESTION_BANK/
    │   ├── questions.json
    │   └── datasets_snapshot.json
    ├── STORAGE/                  <-- Downloads all Supabase Storage Buckets (Images, SVGs, Solutions)
    │   ├── question-images/
    │   ├── svg/
    │   └── solutions/
    ├── EDGE_FUNCTIONS/           <-- Copies all Edge Functions
    ├── MIGRATIONS/                <-- Copies all Database Migrations
    └── RESTORE/
        └── RESTORE_GUIDE.md       <-- Detailed step-by-step restoration instructions

Usage:
    python3 scripts/backup_offline.py [--destination /path/to/folder]
"""

import os
import sys
import tarfile
import datetime
import subprocess
import json
import urllib.request
import urllib.parse
import ssl
import shutil
import argparse

# Fix macOS Python SSL certificate verification error
try:
    ssl._create_default_https_context = ssl._create_unverified_context
except AttributeError:
    pass

def log(msg):
    print(msg, flush=True)

def load_env():
    """Load environment variables from .env file if available."""
    env_file = os.path.join(os.path.dirname(__file__), "..", ".env")
    if os.path.exists(env_file):
        with open(env_file, "r") as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#") and "=" in line:
                    key, val = line.split("=", 1)
                    os.environ.setdefault(key.strip(), val.strip().strip('"').strip("'"))

def get_timestamp():
    return datetime.datetime.now().strftime("%Y%m%d_%H%M%S")

def find_pg_dump():
    """Locate pg_dump binary across system PATH and common macOS install locations."""
    pg_dump_bin = shutil.which("pg_dump")
    if pg_dump_bin:
        return pg_dump_bin

    common_paths = [
        "/usr/local/Cellar/libpq/18.6/bin/pg_dump",
        "/usr/local/opt/libpq/bin/pg_dump",
        "/usr/local/bin/pg_dump",
        "/opt/homebrew/bin/pg_dump",
        "/opt/homebrew/opt/libpq/bin/pg_dump",
        "/Applications/Postgres.app/Contents/Versions/latest/bin/pg_dump"
    ]
    for path in common_paths:
        if os.path.exists(path) and os.access(path, os.X_OK):
            return path

    return None

# 1. CODEBASE
def backup_codebase(target_dir, timestamp):
    log("📦 [1/6] Archiving CODEBASE...")
    codebase_dir = os.path.join(target_dir, "CODEBASE")
    os.makedirs(codebase_dir, exist_ok=True)
    archive_path = os.path.join(codebase_dir, f"cosmyra_codebase_{timestamp}.tar.gz")

    project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    
    exclude_dirs = {
        "node_modules", ".git", ".dart_tool", "build", ".idea", 
        ".vscode", "dist", ".next", "tmp", "coverage", "tmp_backup", "Cosmyra_Offline_Backups"
    }

    def filter_func(tarinfo):
        for part in tarinfo.name.split('/'):
            if part in exclude_dirs:
                return None
        return tarinfo

    with tarfile.open(archive_path, "w:gz") as tar:
        tar.add(project_root, arcname="cosmyra", filter=filter_func)

    size_mb = os.path.getsize(archive_path) / (1024 * 1024)
    log(f"   └─ Archive created: cosmyra_codebase_{timestamp}.tar.gz ({size_mb:.2f} MB)")
    return archive_path

# 2. DATABASE
def backup_database(target_dir, timestamp):
    log("🗄️ [2/6] Dumping DATABASE (Public Schema + User Auth Passwords)...")
    database_dir = os.path.join(target_dir, "DATABASE")
    os.makedirs(database_dir, exist_ok=True)
    dump_path = os.path.join(database_dir, f"cosmyra_db_full_{timestamp}.sql")

    db_url = os.environ.get("SUPABASE_DB_URL")
    if not db_url:
        log("   ⚠️ Skipping pg_dump: SUPABASE_DB_URL not set.")
        return None

    pg_dump_bin = find_pg_dump()
    if not pg_dump_bin:
        log("   ⚠️ pg_dump binary not found. Skipping SQL dump.")
        return None

    try:
        cmd = [
            pg_dump_bin,
            "--dbname=" + db_url,
            "--no-owner",
            "--no-acl",
            "-f", dump_path
        ]
        result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        if result.returncode == 0 and os.path.exists(dump_path):
            size_mb = os.path.getsize(dump_path) / (1024 * 1024)
            log(f"   └─ SQL Dump created: cosmyra_db_full_{timestamp}.sql ({size_mb:.2f} MB)")
            return dump_path
        else:
            log(f"   └─ ❌ pg_dump error: {result.stderr.strip()}")
            return None
    except Exception as e:
        log(f"   └─ ❌ pg_dump exception: {e}")
        return None

# 3. QUESTION BANK & DATASETS
def fetch_table_json(supabase_url, service_key, table_name):
    try:
        url = f"{supabase_url.rstrip('/')}/rest/v1/{table_name}?select=*"
        req = urllib.request.Request(url, headers={
            "apikey": service_key,
            "Authorization": f"Bearer {service_key}"
        })
        with urllib.request.urlopen(req) as resp:
            if resp.status == 200:
                return json.loads(resp.read().decode('utf-8'))
    except Exception:
        pass
    return None

def backup_question_bank(target_dir, timestamp):
    log("🌐 [3/6] Exporting QUESTION_BANK & Datasets...")
    qb_dir = os.path.join(target_dir, "QUESTION_BANK")
    os.makedirs(qb_dir, exist_ok=True)

    supabase_url = os.environ.get("SUPABASE_URL")
    service_key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY") or os.environ.get("SUPABASE_ANON_KEY")

    if not supabase_url or not service_key:
        log("   ⚠️ Skipping REST export: SUPABASE_URL or API Key missing.")
        return

    # Questions JSON
    questions = fetch_table_json(supabase_url, service_key, "questions")
    if questions is not None:
        q_path = os.path.join(qb_dir, "questions.json")
        with open(q_path, "w") as f:
            json.dump(questions, f, indent=2)
        log(f"   ├─ Saved: questions.json ({len(questions)} questions)")

    # Complete Datasets Snapshot
    tables = ["questions", "profiles", "exams", "subjects", "chapters", "topics", "teachers", "test_attempts", "bookmarks"]
    bundle = {}
    total_count = 0
    for t in tables:
        recs = fetch_table_json(supabase_url, service_key, t)
        if recs is not None:
            bundle[t] = recs
            total_count += len(recs)

    if bundle:
        b_path = os.path.join(qb_dir, f"datasets_snapshot_{timestamp}.json")
        with open(b_path, "w") as f:
            json.dump(bundle, f, indent=2)
        log(f"   └─ Saved: datasets_snapshot_{timestamp}.json ({total_count} records)")

# 4. STORAGE ASSETS (Images, SVGs, Diagrams, Solutions)
def list_storage_buckets(supabase_url, service_key):
    """Fetch list of all storage buckets from Supabase Storage API."""
    try:
        url = f"{supabase_url.rstrip('/')}/storage/v1/bucket"
        req = urllib.request.Request(url, headers={
            "apikey": service_key,
            "Authorization": f"Bearer {service_key}"
        })
        with urllib.request.urlopen(req) as resp:
            if resp.status == 200:
                return json.loads(resp.read().decode('utf-8'))
    except Exception as e:
        log(f"   ⚠️ Storage bucket listing error: {e}")
    return []

def list_storage_objects(supabase_url, service_key, bucket_id, prefix=""):
    """Recursively list all file objects inside a bucket."""
    try:
        url = f"{supabase_url.rstrip('/')}/storage/v1/object/list/{bucket_id}"
        payload = json.dumps({"prefix": prefix, "limit": 1000, "offset": 0}).encode('utf-8')
        req = urllib.request.Request(url, data=payload, headers={
            "apikey": service_key,
            "Authorization": f"Bearer {service_key}",
            "Content-Type": "application/json"
        })
        with urllib.request.urlopen(req) as resp:
            if resp.status == 200:
                return json.loads(resp.read().decode('utf-8'))
    except Exception as e:
        log(f"   ⚠️ Could not list objects in bucket '{bucket_id}': {e}")
    return []

def download_storage_file(supabase_url, service_key, bucket_id, file_path, local_target_path):
    """Download a single storage file."""
    try:
        encoded_path = urllib.parse.quote(file_path)
        url = f"{supabase_url.rstrip('/')}/storage/v1/object/public/{bucket_id}/{encoded_path}"
        req = urllib.request.Request(url, headers={
            "apikey": service_key,
            "Authorization": f"Bearer {service_key}"
        })
        os.makedirs(os.path.dirname(local_target_path), exist_ok=True)
        with urllib.request.urlopen(req) as resp, open(local_target_path, "wb") as f:
            f.write(resp.read())
        return True
    except Exception:
        # Fallback to authenticated endpoint if bucket is private
        try:
            url = f"{supabase_url.rstrip('/')}/storage/v1/object/authenticated/{bucket_id}/{encoded_path}"
            req = urllib.request.Request(url, headers={
                "apikey": service_key,
                "Authorization": f"Bearer {service_key}"
            })
            with urllib.request.urlopen(req) as resp, open(local_target_path, "wb") as f:
                f.write(resp.read())
            return True
        except Exception as err:
            log(f"   ❌ Failed downloading asset '{file_path}': {err}")
    return False

def backup_storage_assets(target_dir):
    log("🖼️ [4/6] Downloading STORAGE Assets (Images, SVGs, Diagrams, Solutions)...")
    storage_dir = os.path.join(target_dir, "STORAGE")
    os.makedirs(storage_dir, exist_ok=True)

    supabase_url = os.environ.get("SUPABASE_URL")
    service_key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY") or os.environ.get("SUPABASE_ANON_KEY")

    if not supabase_url or not service_key:
        log("   ⚠️ Skipping Storage download: Credentials missing.")
        return

    buckets = list_storage_buckets(supabase_url, service_key)
    
    # Standard bucket names for Cosmyra if listing API returns empty
    default_bucket_names = ["question-images", "svg", "solutions", "avatars", "pdf-imports"]
    
    bucket_ids = [b['id'] for b in buckets if isinstance(b, dict) and 'id' in b]
    for d_name in default_bucket_names:
        if d_name not in bucket_ids:
            bucket_ids.append(d_name)

    total_downloaded = 0
    for b_id in bucket_ids:
        b_target_dir = os.path.join(storage_dir, b_id)
        os.makedirs(b_target_dir, exist_ok=True)
        
        objects = list_storage_objects(supabase_url, service_key, b_id)
        downloaded_in_bucket = 0

        for obj in objects:
            if isinstance(obj, dict) and 'name' in obj and obj['name']:
                obj_name = obj['name']
                # Skip subfolder placeholders
                if obj_name.endswith('/'):
                    continue
                local_file = os.path.join(b_target_dir, obj_name)
                if download_storage_file(supabase_url, service_key, b_id, obj_name, local_file):
                    downloaded_in_bucket += 1

        log(f"   ├─ Bucket '{b_id}': {downloaded_in_bucket} files downloaded to STORAGE/{b_id}/")
        total_downloaded += downloaded_in_bucket

    log(f"   └─ Total Storage Assets downloaded: {total_downloaded} files")

# 5. EDGE FUNCTIONS & MIGRATIONS
def backup_functions_and_migrations(target_dir):
    log("⚡ [5/6] Copying EDGE_FUNCTIONS & MIGRATIONS...")
    project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

    # Edge Functions
    ef_src = os.path.join(project_root, "supabase", "functions")
    ef_dst = os.path.join(target_dir, "EDGE_FUNCTIONS")
    if os.path.exists(ef_src):
        if os.path.exists(ef_dst):
            shutil.rmtree(ef_dst)
        shutil.copytree(ef_src, ef_dst)
        count_ef = len([d for d in os.listdir(ef_dst) if os.path.isdir(os.path.join(ef_dst, d))])
        log(f"   ├─ Copied {count_ef} Edge Functions to EDGE_FUNCTIONS/")

    # Migrations
    m_src = os.path.join(project_root, "supabase", "migrations")
    m_dst = os.path.join(target_dir, "MIGRATIONS")
    if os.path.exists(m_src):
        if os.path.exists(m_dst):
            shutil.rmtree(m_dst)
        shutil.copytree(m_src, m_dst)
        count_m = len([f for f in os.listdir(m_dst) if f.endswith('.sql')])
        log(f"   └─ Copied {count_m} Migration SQL files to MIGRATIONS/")

# 6. RESTORE GUIDE
def create_restore_guide(target_dir, timestamp):
    log("📝 [6/6] Generating RESTORE_GUIDE.md...")
    restore_dir = os.path.join(target_dir, "RESTORE")
    os.makedirs(restore_dir, exist_ok=True)
    guide_path = os.path.join(restore_dir, "RESTORE_GUIDE.md")

    content = f"""# Cosmyra Platform - Complete System Restoration Guide
Backup Created: {datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")}

This directory contains a complete, 100% self-contained offline backup of the **Cosmyra Exam Preparation Platform**.

---

## 📁 Backup Structure
```text
Cosmyra_Offline_Backups/
└── {os.path.basename(target_dir)}/
    ├── CODEBASE/
    │   └── cosmyra_codebase_{timestamp}.tar.gz
    ├── DATABASE/
    │   └── cosmyra_db_full_{timestamp}.sql
    ├── QUESTION_BANK/
    │   ├── questions.json
    │   └── datasets_snapshot_{timestamp}.json
    ├── STORAGE/
    │   ├── question-images/
    │   ├── svg/
    │   └── solutions/
    ├── EDGE_FUNCTIONS/
    │   ├── create-test-attempt/
    │   ├── join-teacher-test/
    │   ├── pdf-question-parser/
    │   └── submit-test/
    ├── MIGRATIONS/
    └── RESTORE/
        └── RESTORE_GUIDE.md
```

---

## 🔄 Step-by-Step Restoration Instructions

### Step 1: Restore Codebase
Extract the codebase archive to your workspace:
```bash
tar -xzf CODEBASE/cosmyra_codebase_{timestamp}.tar.gz -C ./
```

### Step 2: Restore Database & User Accounts (Passes, Emails, Profiles)
Run the SQL dump into your fresh Postgres / Supabase database:
```bash
psql -h db.[NEW-PROJECT-REF].supabase.co -U postgres -d postgres -f DATABASE/cosmyra_db_full_{timestamp}.sql
```

### Step 3: Upload Storage Assets (Images, SVGs, Solutions)
Sync your downloaded local `STORAGE/` files back to your new Supabase Storage buckets using `rclone` or Supabase CLI:
```bash
# Upload question-images
supabase storage cp -r STORAGE/question-images/ ss://question-images/
```

### Step 4: Re-deploy Edge Functions
```bash
cd cosmyra
supabase link --project-ref <NEW-PROJECT-REF>
supabase functions deploy
```

### Step 5: Update Web Platform & Mobile App Environment
1. Update `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` in `web/.env`.
2. Deploy Web frontend to Vercel.
3. Update Flutter `audio_feedback_service.dart` / environment keys and build APK / iOS release.
"""
    with open(guide_path, "w") as f:
        f.write(content)
    log(f"   └─ Restore Guide created: RESTORE/RESTORE_GUIDE.md")

def main():
    load_env()

    parser = argparse.ArgumentParser(description="Cosmyra Platform Offline Local Backup Engine")
    parser.add_argument("--destination", help="Target folder to save offline backups", default=None)
    args = parser.parse_args()

    log("=" * 60)
    log("💾 COSMYRA PLATFORM - COMPLETE OFFLINE BACKUP ENGINE")
    log("=" * 60)

    timestamp = get_timestamp()
    month_folder = datetime.datetime.now().strftime("%Y-%m")
    
    if args.destination:
        target_dir = os.path.abspath(args.destination)
    else:
        home_dir = os.path.expanduser("~")
        target_dir = os.path.join(home_dir, "Desktop", "Cosmyra_Offline_Backups", month_folder)

    os.makedirs(target_dir, exist_ok=True)
    log(f"📁 Saving modular offline backups to: {target_dir}\n")

    # 1. Codebase
    backup_codebase(target_dir, timestamp)

    # 2. Database
    backup_database(target_dir, timestamp)

    # 3. Question Bank
    backup_question_bank(target_dir, timestamp)

    # 4. Storage Assets (Images, SVGs, Diagrams, Solutions)
    backup_storage_assets(target_dir)

    # 5. Edge Functions & Migrations
    backup_functions_and_migrations(target_dir)

    # 6. Restore Guide
    create_restore_guide(target_dir, timestamp)

    log("=" * 60)
    log(f"🎉 COMPLETE MODULAR OFFLINE BACKUP FINISHED!")
    log(f"👉 Location: {target_dir}")
    log("=" * 60)

if __name__ == "__main__":
    main()
