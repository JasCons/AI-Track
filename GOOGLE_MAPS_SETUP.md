# Google Maps API Setup Guide

## Quick Fix for Web Deployment

Your Google Maps is already configured for Android/iOS but needs web configuration.

### Step 1: Get Your API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project or create a new one
3. Enable **Maps JavaScript API**
4. Go to **Credentials** → **Create Credentials** → **API Key**
5. Copy your API key

### Step 2: Add API Key to Web

Edit `web/index.html` and add your API key:

```html
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_API_KEY_HERE"></script>
```

Add this line before the closing `</head>` tag.

### Step 3: Restrict Your API Key (Important!)

In Google Cloud Console:
1. Click on your API key
2. Under **Application restrictions**, select **HTTP referrers**
3. Add these referrers:
   - `https://jascons.github.io/*`
   - `http://localhost:*` (for local testing)
4. Under **API restrictions**, select **Restrict key**
5. Select only:
   - Maps JavaScript API
   - Maps SDK for Android
   - Maps SDK for iOS

### Step 4: Rebuild and Deploy

```powershell
flutter build web --release
git add web/index.html
git commit -m "Add Google Maps API key for web"
git push origin main
```

## Current Configuration Status

✅ **Android** - Configured in `android/app/src/main/AndroidManifest.xml`
✅ **iOS** - Configured in `ios/Runner/AppDelegate.swift`
❌ **Web** - Needs API key in `web/index.html`

## Testing Locally

```powershell
flutter run -d chrome
```

Navigate to Transit Track page and verify the map loads.

## Troubleshooting

### Map shows gray screen
- Check browser console for API key errors
- Verify API key is correct
- Ensure Maps JavaScript API is enabled

### "This page can't load Google Maps correctly"
- API key is missing or invalid
- Maps JavaScript API not enabled
- Billing not enabled on Google Cloud project

### Map works locally but not on GitHub Pages
- Add `https://jascons.github.io/*` to API key restrictions
- Clear browser cache
- Wait 5 minutes for API key changes to propagate

## Free Tier Limits

Google Maps offers $200 free credit per month:
- ~28,000 map loads per month
- Sufficient for development and small apps
- Enable billing to avoid service interruption
