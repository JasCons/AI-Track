# Firebase Connection Test

## What Was Fixed

### 1. ✅ Google Maps API Key
- Updated `web/index.html` with your API key
- Maps will now load on Transit Track page

### 2. ✅ Firebase Web Configuration
- Updated `lib/firebase_options.dart` with correct web API key
- Web app can now connect to Firebase

### 3. ✅ Firestore Write Logic
- Fixed reports to write directly to Firestore when toggle is ON
- Fixed transit register to write directly to Firestore when toggle is ON
- Added debug logging to track writes

### 4. ✅ User Authentication Check
- Both pages now require sign-in before writing to Firestore
- Clear error messages if not signed in

## Testing Steps

### 1. Create Firebase Test Users

Go to [Firebase Console](https://console.firebase.google.com/project/ai-track-42cce/authentication/users)

Add these users:
- Email: `passenger@example.com` Password: `pass123`
- Email: `operator@example.com` Password: `op123`

### 2. Update Firestore Rules

Go to [Firestore Rules](https://console.firebase.google.com/project/ai-track-42cce/firestore/rules)

Use these rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /reports/{reportId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null;
    }
    
    match /transit/{transitId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null;
    }
    
    match /routes/{routeId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null;
    }
    
    match /vehicles/{vehicleId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

### 3. Test Locally

```powershell
flutter run -d chrome
```

1. Login with `passenger@example.com` / `pass123`
2. Go to Report page
3. Fill form and submit
4. Check browser console for "Report saved to Firestore: [ID]"
5. Check [Firestore Console](https://console.firebase.google.com/project/ai-track-42cce/firestore/data) for new report

### 4. Deploy and Test

```powershell
git add .
git commit -m "Fix Firebase web connection and Firestore writes"
git push origin main
```

Wait 2-5 minutes, then test at: https://jascons.github.io/AI-Track

## Verification Checklist

- [ ] Firebase users created (passenger@example.com, operator@example.com)
- [ ] Firestore rules updated
- [ ] Can login with Firebase credentials
- [ ] Reports save to Firestore (check console logs)
- [ ] Transit register saves to Firestore (check console logs)
- [ ] Google Maps loads on Transit Track page
- [ ] Data appears in Firestore console

## Troubleshooting

### "Please sign in to submit reports"
- You must be logged in with Firebase credentials
- Use passenger@example.com or operator@example.com

### Reports/Transit not appearing in Firestore
1. Check browser console (F12) for errors
2. Verify Firestore rules allow writes
3. Confirm you're logged in
4. Check toggle is ON (should be by default)

### Google Maps not loading
- Check browser console for API key errors
- Verify API key is enabled for Maps JavaScript API
- Add `https://jascons.github.io/*` to API key restrictions

## Quick Links

- [Firebase Console](https://console.firebase.google.com/project/ai-track-42cce)
- [Authentication Users](https://console.firebase.google.com/project/ai-track-42cce/authentication/users)
- [Firestore Database](https://console.firebase.google.com/project/ai-track-42cce/firestore/data)
- [Firestore Rules](https://console.firebase.google.com/project/ai-track-42cce/firestore/rules)
- [Live App](https://jascons.github.io/AI-Track)
