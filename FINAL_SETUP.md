# Final Setup - 3 Steps Only

## Step 1: Create Firebase Users (2 minutes)

1. Go to: https://console.firebase.google.com/project/ai-track-42cce/authentication/users
2. Click "Add user"
3. Create:
   - Email: `passenger@example.com` Password: `pass123`
   - Email: `operator@example.com` Password: `op123`

## Step 2: Update Firestore Rules (1 minute)

1. Go to: https://console.firebase.google.com/project/ai-track-42cce/firestore/rules
2. Replace ALL content with:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

3. Click "Publish"

## Step 3: Test (2 minutes)

1. Go to: https://jascons.github.io/AI-Track
2. Login with `passenger@example.com` / `pass123`
3. Go to "Report" page
4. Fill form and submit
5. Check: https://console.firebase.google.com/project/ai-track-42cce/firestore/data
6. You should see `reports` collection with your data

## If Still Not Working

Open browser console (F12) and check for errors. Share the error message.

## Your Links

- Live App: https://jascons.github.io/AI-Track
- Firebase Console: https://console.firebase.google.com/project/ai-track-42cce
- Firestore Data: https://console.firebase.google.com/project/ai-track-42cce/firestore/data
