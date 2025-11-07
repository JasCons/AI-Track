# Get Firebase Web Configuration

## Quick Fix - Get Your Web App Config

Your Firebase project: **ai-track-42cce**

### Step 1: Get Web App ID

1. Go to: https://console.firebase.google.com/project/ai-track-42cce/settings/general
2. Scroll to "Your apps" section
3. Look for the **Web app** (globe icon)
4. If no web app exists, click "Add app" → Web (</>) icon
5. Register app name: "AI-Track Web"
6. Copy the config object that looks like:

```javascript
const firebaseConfig = {
  apiKey: "AIza...",
  authDomain: "ai-track-42cce.firebaseapp.com",
  projectId: "ai-track-42cce",
  storageBucket: "ai-track-42cce.firebasestorage.app",
  messagingSenderId: "370121170127",
  appId: "1:370121170127:web:XXXXX"  // <-- This is what we need
};
```

### Step 2: Update firebase_options.dart

Replace the web section in `lib/firebase_options.dart` with your actual values.

### Alternative: Use FlutterFire CLI (Recommended)

```powershell
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase (auto-generates correct config)
flutterfire configure --project=ai-track-42cce

# This will update lib/firebase_options.dart automatically
```

This is the fastest way to get the correct configuration!
