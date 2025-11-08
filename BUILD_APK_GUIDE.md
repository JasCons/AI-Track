# Build APK Guide - AI-Track with Firebase & Google Maps

## ✅ Current Configuration Status

Your project is **already configured** with:
- ✅ Firebase (Auth, Firestore, Database)
- ✅ Google Maps API
- ✅ google-services.json file present
- ✅ All required permissions in AndroidManifest.xml

## 📋 Prerequisites

1. Flutter SDK installed
2. Android Studio or Android SDK installed
3. Java JDK 17 installed

## 🚀 Quick Build Steps

### Option 1: Build Release APK (Recommended)

```powershell
cd c:\projects\flutter\AI-Track
flutter clean
flutter pub get
flutter build apk --release
```

**Output location:** `build\app\outputs\flutter-apk\app-release.apk`

### Option 2: Build Debug APK (For Testing)

```powershell
flutter build apk --debug
```

**Output location:** `build\app\outputs\flutter-apk\app-debug.apk`

### Option 3: Build Split APKs (Smaller file size)

```powershell
flutter build apk --split-per-abi
```

**Output location:** `build\app\outputs\flutter-apk\`
- `app-armeabi-v7a-release.apk` (32-bit ARM)
- `app-arm64-v8a-release.apk` (64-bit ARM)
- `app-x86_64-release.apk` (64-bit Intel)

## 📱 What's Included in the APK

### Firebase Features:
- ✅ Firebase Authentication (Email/Password)
- ✅ Cloud Firestore (Database)
- ✅ Firebase Realtime Database
- ✅ Auto-configured with your project: `ai-track-42cce`

### Google Maps Features:
- ✅ Google Maps JavaScript API
- ✅ API Key: `AIzaSyBE-q3FMTPQ98p4S2NDUi-V6cDmHU_uJfQ`
- ✅ Location permissions (Fine & Coarse)

### App Permissions:
- ✅ Internet access
- ✅ Location access (GPS)

## 🔧 Configuration Files Already Set Up

1. **android/app/build.gradle.kts**
   - Firebase BOM 34.3.0
   - Google Play Services Maps 18.2.0
   - Google Services plugin configured

2. **android/app/google-services.json**
   - Firebase project configuration
   - Already present and configured

3. **android/app/src/main/AndroidManifest.xml**
   - Google Maps API key embedded
   - All required permissions added

4. **lib/firebase_options.dart**
   - Firebase configuration for Android
   - Project ID: ai-track-42cce

## 📦 Install APK on Device

### Via USB:
```powershell
adb install build\app\outputs\flutter-apk\app-release.apk
```

### Via File Transfer:
1. Copy APK to phone
2. Enable "Install from Unknown Sources" in phone settings
3. Tap APK file to install

## 🔍 Verify Firebase & Maps Work

After installing:

1. **Test Firebase Auth:**
   - Open app → Sign Up
   - Create account with email/password
   - Should successfully create Firebase user

2. **Test Firestore:**
   - Register a transit vehicle
   - Check Firebase Console → Firestore
   - Data should appear in collections

3. **Test Google Maps:**
   - Go to Transit Track page
   - Map should load with your API key
   - Location should be accessible

## ⚠️ Important Notes

### Firebase Security:
- Current Firestore rules allow authenticated read/write
- Update rules in Firebase Console for production

### Google Maps API:
- Current API key is active
- Monitor usage in Google Cloud Console
- Add restrictions for production (Android app signature)

### App Signing:
- Debug builds use debug keystore
- For production: Create release keystore
- Add to `android/key.properties`:
  ```
  storePassword=<password>
  keyPassword=<password>
  keyAlias=<alias>
  storeFile=<path-to-keystore>
  ```

## 🐛 Troubleshooting

### Build fails with "Flutter not found":
```powershell
flutter doctor
```
Fix any issues shown

### Build fails with Gradle errors:
```powershell
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

### Firebase not working in APK:
- Verify `google-services.json` is in `android/app/`
- Check package name matches: `com.example.helloworld`
- Verify SHA-1 fingerprint in Firebase Console (for Google Sign-In)

### Google Maps not showing:
- Verify API key in AndroidManifest.xml
- Enable Maps SDK for Android in Google Cloud Console
- Check location permissions granted on device

## 📊 APK Size Optimization

Current APK size: ~50-60 MB (with all dependencies)

To reduce size:
```powershell
# Build split APKs (recommended)
flutter build apk --split-per-abi --release

# Enable code shrinking (advanced)
# Edit android/app/build.gradle.kts:
# isMinifyEnabled = true
```

## ✅ Success Checklist

- [ ] APK builds without errors
- [ ] APK installs on device
- [ ] App opens successfully
- [ ] Sign up creates Firebase user
- [ ] Login works with Firebase Auth
- [ ] Transit registration saves to Firestore
- [ ] Google Maps loads on Transit Track page
- [ ] Location permission requested and works

## 🎯 Next Steps

1. Build APK using commands above
2. Install on test device
3. Test all Firebase features
4. Test Google Maps functionality
5. For production: Set up proper signing and security rules

---

**Your APK will have full Firebase and Google Maps functionality!**
