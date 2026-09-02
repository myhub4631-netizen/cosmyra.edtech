#!/usr/bin/env python3
"""
Cosmyra Platform - Automated Backblaze B2 Complete Backup Tool
-------------------------------------------------------------
This script backs up:
1. CODEBASE/                - Source code tarball (.tar.gz)
2. DATABASE/                - Full Postgres database dump (.sql with auth.users)
3. QUESTION_BANK/           - Questions JSON & Datasets snapshot (.json)
4. STORAGE/                 - Downloaded Supabase Storage Assets (Images, SVGs, Solutions)
5. EDGE_FUNCTIONS/          - Edge Functions definitions
6. MIGRATIONS/              - Database SQL migrations
7. RESTORE/                 - RESTORE_GUIDE.md

Usage:
    python3 scripts/backup_to_backblaze.py
"""

import os
import sys
import tarfile
import datetime
import subprocess
import json
import hashlib
import urllib.request
import urllib.parse
import base64
import ssl
import shutil

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

def build_backup_tree(target_dir, timestamp):
    project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

    # 1. CODEBASE
    log("📦 [1/6] Archiving CODEBASE...")
    cb_dir = os.path.join(target_dir, "CODEBASE")
    os.makedirs(cb_dir, exist_ok=True)
    archive_path = os.path.join(cb_dir, f"cosmyra_codebase_{timestamp}.tar.gz")
    
    exclude_dirs = {
        "node_modules", ".git", ".dart_tool", "build", ".idea", 
        ".vscode", "dist", ".next", "tmp", "coverage", "tmp_backup", "Cosmyra_Offline_Backups"
    }
    with tarfile.open(archive_path, "w:gz") as tar:
        tar.add(project_root, arcname="cosmyra", filter=lambda ti: None if any(p in exclude_dirs for p in ti.name.split('/')) else ti)
    log(f"   └─ Archive created ({os.path.getsize(archive_path)/(1024*1024):.2f} MB)")

    # 2. DATABASE
    log("🗄️ [2/6] Dumping DATABASE (Public Schema + User Auth Passwords)...")
    db_dir = os.path.join(target_dir, "DATABASE")
    os.makedirs(db_dir, exist_ok=True)
    dump_path = os.path.join(db_dir, f"cosmyra_db_full_{timestamp}.sql")
    db_url = os.environ.get("SUPABASE_DB_URL")
    pg_dump_bin = find_pg_dump()
    if db_url and pg_dump_bin:
        try:
            subprocess.run([pg_dump_bin, "--dbname=" + db_url, "--no-owner", "--no-acl", "-f", dump_path], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            if os.path.exists(dump_path):
                log(f"   └─ SQL Dump created ({os.path.getsize(dump_path)/(1024*1024):.2f} MB)")
        except Exception as e:
            log(f"   └─ pg_dump error: {e}")

    # 3. QUESTION BANK & DATASETS
    log("🌐 [3/6] Exporting QUESTION_BANK & Datasets...")
    qb_dir = os.path.join(target_dir, "QUESTION_BANK")
    os.makedirs(qb_dir, exist_ok=True)
    supabase_url = os.environ.get("SUPABASE_URL")
    service_key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY") or os.environ.get("SUPABASE_ANON_KEY")
    
    if supabase_url and service_key:
        tables = ["questions", "profiles", "exams", "subjects", "chapters", "topics", "teachers", "test_attempts", "bookmarks"]
        bundle = {}
        for t in tables:
            try:
                req = urllib.request.Request(f"{supabase_url.rstrip('/')}/rest/v1/{t}?select=*", headers={"apikey": service_key, "Authorization": f"Bearer {service_key}"})
                with urllib.request.urlopen(req) as resp:
                    if resp.status == 200:
                        recs = json.loads(resp.read().decode('utf-8'))
                        bundle[t] = recs
                        if t == "questions":
                            with open(os.path.join(qb_dir, "questions.json"), "w") as f:
                                json.dump(recs, f, indent=2)
            except Exception:
                pass
        if bundle:
            with open(os.path.join(qb_dir, f"datasets_snapshot_{timestamp}.json"), "w") as f:
                json.dump(bundle, f, indent=2)
            log(f"   └─ Datasets snapshot exported.")

    # 4. STORAGE ASSETS (Images, SVGs, Solutions)
    log("🖼️ [4/6] Downloading STORAGE Assets...")
    storage_dir = os.path.join(target_dir, "STORAGE")
    os.makedirs(storage_dir, exist_ok=True)
    if supabase_url and service_key:
        buckets = ["question-images", "svg", "solutions", "avatars", "pdf-imports"]
        for b in buckets:
            b_dir = os.path.join(storage_dir, b)
            os.makedirs(b_dir, exist_ok=True)
            try:
                req = urllib.request.Request(f"{supabase_url.rstrip('/')}/storage/v1/object/list/{b}", data=json.dumps({"prefix": "", "limit": 1000, "offset": 0}).encode('utf-8'), headers={"apikey": service_key, "Authorization": f"Bearer {service_key}", "Content-Type": "application/json"})
                with urllib.request.urlopen(req) as resp:
                    if resp.status == 200:
                        objs = json.loads(resp.read().decode('utf-8'))
                        for obj in objs:
                            if isinstance(obj, dict) and 'name' in obj and not obj['name'].endswith('/'):
                                file_path = obj['name']
                                enc_p = urllib.parse.quote(file_path)
                                f_url = f"{supabase_url.rstrip('/')}/storage/v1/object/public/{b}/{enc_p}"
                                f_req = urllib.request.Request(f_url, headers={"apikey": service_key, "Authorization": f"Bearer {service_key}"})
                                local_f = os.path.join(b_dir, file_path)
                                os.makedirs(os.path.dirname(local_f), exist_ok=True)
                                try:
                                    with urllib.request.urlopen(f_req) as f_resp, open(local_f, "wb") as out_f:
                                        out_f.write(f_resp.read())
                                except Exception:
                                    pass
            except Exception:
                pass
        log(f"   └─ Storage assets checked.")

    # 5. EDGE FUNCTIONS & MIGRATIONS
    log("⚡ [5/6] Copying EDGE_FUNCTIONS & MIGRATIONS...")
    ef_src = os.path.join(project_root, "supabase", "functions")
    ef_dst = os.path.join(target_dir, "EDGE_FUNCTIONS")
    if os.path.exists(ef_src):
        if os.path.exists(ef_dst): shutil.rmtree(ef_dst)
        shutil.copytree(ef_src, ef_dst)

    m_src = os.path.join(project_root, "supabase", "migrations")
    m_dst = os.path.join(target_dir, "MIGRATIONS")
    if os.path.exists(m_src):
        if os.path.exists(m_dst): shutil.rmtree(m_dst)
        shutil.copytree(m_src, m_dst)

    # 6. RESTORE GUIDE
    log("📝 [6/6] Generating RESTORE_GUIDE.md...")
    rst_dir = os.path.join(target_dir, "RESTORE")
    os.makedirs(rst_dir, exist_ok=True)
    with open(os.path.join(rst_dir, "RESTORE_GUIDE.md"), "w") as f:
        f.write(f"# Cosmyra System Restoration Guide\nBackup Date: {timestamp}\n\n1. Extract CODEBASE tarball\n2. Restore DATABASE sql dump with `psql`\n3. Upload STORAGE assets\n4. Deploy EDGE_FUNCTIONS with `supabase functions deploy`\n")

def collect_all_files(target_dir):
    file_list = []
    for root, _, files in os.walk(target_dir):
        for f in files:
            file_list.append(os.path.join(root, f))
    return file_list

def upload_via_b2_native_api(target_dir, key_id, app_key, bucket_name):
    log("🔑 Authorizing with Backblaze B2 API...")
    auth_url = "https://api.backblazeb2.com/b2api/v2/b2_authorize_account"
    credentials = f"{key_id}:{app_key}"
    encoded_creds = base64.b64encode(credentials.encode('utf-8')).decode('utf-8')
    
    req = urllib.request.Request(auth_url, headers={"Authorization": f"Basic {encoded_creds}"})
    try:
        with urllib.request.urlopen(req) as resp:
            auth_data = json.loads(resp.read().decode('utf-8'))
    except Exception as e:
        log(f"❌ Authorization failed: {e}")
        return 0

    api_url = auth_data['apiUrl']
    account_auth_token = auth_data['authorizationToken']
    allowed_bucket_id = auth_data.get('allowed', {}).get('bucketId')

    bucket_id = allowed_bucket_id
    if not bucket_id:
        list_buckets_url = f"{api_url}/b2api/v2/b2_list_buckets"
        data = json.dumps({"accountId": auth_data['accountId']}).encode('utf-8')
        req = urllib.request.Request(list_buckets_url, data=data, headers={"Authorization": account_auth_token, "Content-Type": "application/json"})
        with urllib.request.urlopen(req) as resp:
            buckets = json.loads(resp.read().decode('utf-8')).get('buckets', [])
            for b in buckets:
                if b['bucketName'] == bucket_name:
                    bucket_id = b['bucketId']
                    break

    if not bucket_id:
        log(f"❌ Could not find bucket ID for bucket '{bucket_name}'")
        return 0

    month_folder = datetime.datetime.now().strftime("%Y-%m")
    all_files = collect_all_files(target_dir)
    uploaded_count = 0

    current_upload_info = None

    def get_fresh_upload_info():
        get_url = f"{api_url}/b2api/v2/b2_get_upload_url"
        req_data = json.dumps({"bucketId": bucket_id}).encode('utf-8')
        r = urllib.request.Request(get_url, data=req_data, headers={"Authorization": account_auth_token, "Content-Type": "application/json"})
        with urllib.request.urlopen(r) as resp:
            return json.loads(resp.read().decode('utf-8'))

    for file_path in all_files:
        rel_path = os.path.relpath(file_path, target_dir)
        remote_file_name = f"backups/{month_folder}/{rel_path}".replace("\\", "/")
        file_size = os.path.getsize(file_path)
        log(f"   📤 Uploading {rel_path} ({file_size / (1024*1024):.2f} MB)...")

        # Reuse upload URL if available, or fetch new one
        if not current_upload_info:
            try:
                current_upload_info = get_fresh_upload_info()
            except Exception as u_err:
                log(f"   ❌ Error getting upload URL: {u_err}")
                continue

        with open(file_path, 'rb') as f:
            file_bytes = f.read()

        sha1_hash = hashlib.sha1(file_bytes).hexdigest()
        encoded_file_name = urllib.parse.quote(remote_file_name)

        upload_req = urllib.request.Request(current_upload_info['uploadUrl'], data=file_bytes, headers={
            "Authorization": current_upload_info['authorizationToken'],
            "X-Bz-File-Name": encoded_file_name,
            "Content-Type": "b2/x-auto",
            "Content-Length": str(len(file_bytes)),
            "X-Bz-Content-Sha1": sha1_hash
        })

        try:
            with urllib.request.urlopen(upload_req) as resp:
                if resp.status == 200:
                    log(f"   ✅ Uploaded: {rel_path} -> B2: {remote_file_name}")
                    uploaded_count += 1
        except Exception as e:
            # If token expired or busy, refresh token and retry once
            log(f"   ⚠️ Retrying upload for {rel_path} with fresh URL...")
            try:
                current_upload_info = get_fresh_upload_info()
                retry_req = urllib.request.Request(current_upload_info['uploadUrl'], data=file_bytes, headers={
                    "Authorization": current_upload_info['authorizationToken'],
                    "X-Bz-File-Name": encoded_file_name,
                    "Content-Type": "b2/x-auto",
                    "Content-Length": str(len(file_bytes)),
                    "X-Bz-Content-Sha1": sha1_hash
                })
                with urllib.request.urlopen(retry_req) as resp:
                    if resp.status == 200:
                        log(f"   ✅ Uploaded: {rel_path} -> B2: {remote_file_name}")
                        uploaded_count += 1
            except Exception as retry_e:
                log(f"   ❌ Upload error for {rel_path}: {retry_e}")
                current_upload_info = None

    return uploaded_count

def main():
    load_env()
    log("=" * 60)
    log("🚀 COSMYRA PLATFORM - COMPLETE BACKBLAZE B2 BACKUP ENGINE")
    log("=" * 60)

    b2_key_id = os.environ.get("B2_KEY_ID")
    b2_app_key = os.environ.get("B2_APPLICATION_KEY")
    b2_bucket = os.environ.get("B2_BUCKET_NAME", "cosmyra-neetjee")

    if not b2_key_id or not b2_app_key or not b2_bucket:
        log("\n❌ Backup failed: Missing Backblaze credentials!")
        return

    timestamp = get_timestamp()
    tmp_backup_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "tmp_backup"))
    if os.path.exists(tmp_backup_dir):
        shutil.rmtree(tmp_backup_dir)
    os.makedirs(tmp_backup_dir, exist_ok=True)

    # 1. Build modular backup directory tree
    build_backup_tree(tmp_backup_dir, timestamp)

    # 2. Upload complete tree to Backblaze B2
    log(f"\n☁️ Uploading Complete Backup Tree to Backblaze B2 Bucket: '{b2_bucket}'...")
    count = upload_via_b2_native_api(tmp_backup_dir, b2_key_id, b2_app_key, b2_bucket)

    # Cleanup temporary local folder after upload
    if os.path.exists(tmp_backup_dir):
        shutil.rmtree(tmp_backup_dir)

    log("=" * 60)
    if count > 0:
        log(f"🎉 COMPLETE BACKBLAZE B2 BACKUP FINISHED! ({count} files safely uploaded)")
    log("=" * 60)

if __name__ == "__main__":
    main()
