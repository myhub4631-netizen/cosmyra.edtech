# Vercel Deployment & GitHub Setup Guide (New Accounts)

Follow these steps to push your repository to a **NEW GitHub Repository** and deploy to a **NEW Vercel Account**.

---

## Step 1: Push to NEW GitHub Repository

1. Create a new repository on your GitHub account:
   - Name: `cosmyra-edu-platform`
   - Set visibility to **Public** or **Private**.
2. Open terminal in the project directory `/Users/mahboobhasan/Desktop/Cosmyra Edu Flutter/`:
   ```bash
   git init
   git add .
   git commit -m "Initial commit of NEET & JEE Question Practice Platform"
   git branch -M main
   git remote add origin https://github.com/YOUR_GITHUB_USERNAME/cosmyra-edu-platform.git
   git push -u origin main
   ```

---

## Step 2: Deploy on NEW Vercel Account

1. Go to [https://vercel.com](https://vercel.com) and create/login to your **New Vercel Account**.
2. Click **Add New... → Project**.
3. Import your new GitHub repository: `cosmyra-edu-platform`.

### Project Build Settings:
- **Framework Preset**: Other
- **Root Directory**: `.`
- **Build Command**:
  ```bash
  cd flutter_app && flutter build web --release --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
  ```
- **Output Directory**: `flutter_app/build/web`

---

## Step 3: Configure Environment Variables in Vercel

In the Vercel project deployment settings, add the following **Environment Variables**:

| Key | Value |
| --- | --- |
| `SUPABASE_URL` | Your New Supabase Project URL (`https://xyz...supabase.co`) |
| `SUPABASE_ANON_KEY` | Your New Supabase `anon` API Key |

Click **Deploy**. Vercel will compile the Flutter Web release bundle and host it on your custom `.vercel.app` URL with SPA routing enabled via `vercel.json`!
