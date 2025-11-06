# Google Maps API Setup Guide

## Prerequisites
- Google Cloud Platform account
- Flutter project with `google_maps_flutter` dependency (already added)

## Steps to Enable Google Maps

### 1. Create/Select a Google Cloud Project
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project or select an existing one

### 2. Enable Required APIs
1. Navigate to **APIs & Services > Library**
2. Search and enable:
   - **Maps SDK for Android**
   - **Maps SDK for iOS** (if supporting iOS)
   - **Directions API** (for route calculations)
   - **Places API** (optional, for location search)

### 3. Create API Key
1. Go to **APIs & Services > Credentials**
2. Click **Create Credentials > API Key**
3. Copy the generated API key

### 4. Restrict API Key (Recommended)
1. Click on the created API key
2. Under **Application restrictions**, select **Android apps**
3. Add your package name: `com.example.helloworld` (check `android/app/src/main/AndroidManifest.xml`)
4. Add SHA-1 fingerprint (get it by running):
   ```powershell
   cd android
   ./gradlew signingReport
   ```
5. Under **API restrictions**, select **Restrict key** and choose the enabled APIs

### 5. Add API Key to Android
1. Open `android/app/src/main/AndroidManifest.xml`
2. Replace `YOUR_GOOGLE_MAPS_API_KEY` with your actual API key:
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="AIzaSy..." />
   ```

### 6. Add API Key to iOS (if needed)
1. Open `ios/Runner/AppDelegate.swift`
2. Add at the top:
   ```swift
   import GoogleMaps
   ```
3. In the `application` method, add:
   ```swift
   GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
   ```

### 7. Test the Integration
```powershell
flutter clean
flutter pub get
flutter run
```

## Troubleshooting

### Map shows blank/gray tiles
- Verify API key is correct
- Check that Maps SDK for Android is enabled
- Ensure billing is enabled on your Google Cloud project
- Check logcat for error messages: `flutter run -v`

### "API key not found" error
- Rebuild the app after adding the API key
- Run `flutter clean` and rebuild

### Permission errors
- Ensure location permissions are in AndroidManifest.xml (already added)
- Request runtime permissions in the app if needed

## Cost Considerations
- Google Maps offers $200 free credit per month
- Monitor usage in Google Cloud Console
- Set up billing alerts to avoid unexpected charges

## Security Best Practices
- Never commit API keys to version control
- Use environment variables or secure key management
- Restrict API keys to specific apps and APIs
- Rotate keys periodically
