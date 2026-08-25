# Vercel Web Deployment Guide

## 1. Import Repository
1. Log into [Vercel](https://vercel.com).
2. Import the `Cosmyra Neet Jee v2` GitHub repository.
3. Set **Root Directory** to `web`.

## 2. Framework Preset & Build Settings
* **Framework Preset**: Vite
* **Build Command**: `npm run build`
* **Output Directory**: `dist`

## 3. Environment Variables
Add the following in Vercel project settings:
```env
VITE_SUPABASE_URL=https://your-supabase-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key-here
```

## 4. Single Page Application Rewrites
Ensure SPA fallback rewrite exists for Vercel:
```json
{
  "rewrites": [{ "source": "/(.*)", "destination": "/index.html" }]
}
```
