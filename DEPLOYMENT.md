# Deployment Guide — AI-Track

This guide shows how to produce a signed Android AAB and distribute it using GitHub Releases and Firebase App Distribution. The repository includes a GitHub Actions workflow (`.github/workflows/ci-distribute.yml`) that builds the AAB and uploads it to a GitHub Release; it can also upload to Firebase App Distribution when a `FIREBASE_TOKEN` secret is provided.

## Recommended distribution flow
- For internal testers: Firebase App Distribution (easy, integrates with your Firebase project).
- For simple artifact hosting: GitHub Releases (automatic when pushing `main`).

## Local steps (PowerShell)
1. Generate a release keystore (if you don't have one):

```powershell
$keyPath = "$env:USERPROFILE\keystores\ai_track_release.jks"
mkdir (Split-Path $keyPath) -Force
keytool -genkeypair -v -keystore $keyPath -alias ai_track_key -keyalg RSA -keysize 2048 -validity 9125
```

2. Create `android/key.properties` (DO NOT commit this file):

```text
storePassword=<your-keystore-password>
keyPassword=<your-key-password>
keyAlias=ai_track_key
storeFile=C:\Users\<yourusername>\keystores\ai_track_release.jks
```

3. Build signed AAB locally:

```powershell
flutter clean
flutter pub get
flutter build appbundle --release
```

4. Upload to Firebase App Distribution (optional):

```powershell
firebase appdistribution:distribute .\build\app\outputs\bundle\release\app-release.aab --app <FIREBASE_APP_ID> --groups "internal-testers"
```

### Creating Firebase CI token and adding GitHub Secrets (PowerShell)

1. Create a Firebase CI token (interactive):

```powershell
# Install firebase-tools if you haven't already
npm install -g firebase-tools
# Login and generate a CI token. This will open a browser to authenticate and then print a token.
firebase login:ci
# Copy the printed token value.
```

2. Add secrets to GitHub (recommended: use GitHub CLI `gh`). First install `gh` and authenticate:

```powershell
# Install GitHub CLI (Windows) if not installed
# See https://cli.github.com/manual/installation for options
gh auth login
# Then set secrets (replace placeholders)
gh secret set FIREBASE_TOKEN --body "<PASTE_FIREBASE_TOKEN>"
gh secret set FIREBASE_PROJECT_ID --body "<YOUR_FIREBASE_PROJECT_ID>"
# For keystore: create keystore.b64 using the script and then set it
.\scripts\encode-keystore.ps1 -KeystorePath C:\path\to\ai_track.jks -OutFile keystore.b64
gh secret set AI_TRACK_KEYSTORE_BASE64 --body (Get-Content -Raw .\keystore.b64)
gh secret set AI_TRACK_KEYSTORE_PASSWORD --body "<KEYSTORE_PASSWORD>"
gh secret set AI_TRACK_KEY_PASSWORD --body "<KEY_PASSWORD>"
gh secret set AI_TRACK_KEY_ALIAS --body "ai_track_key"
```

3. If you prefer the GitHub web UI:

- Go to your repository → Settings → Secrets and variables → Actions → New repository secret.
- Add each secret name and paste the value.

Notes:
- Keep your keystore and passwords secure. Do not commit them to the repository.
- If you do not want CI to manage keystore, you can omit `AI_TRACK_KEYSTORE_BASE64` and the workflow will build with debug signing (not recommended for release).

## GitHub Actions (automated)
The workflow will run on pushes to `main`.

Required repository secrets (if you want automatic signing and Firebase upload):
- `AI_TRACK_KEYSTORE_BASE64` — Base64 of the keystore (`cat ai_track.jks | base64`). Optional; if not provided, the build will use debug signing.
- `AI_TRACK_KEYSTORE_PASSWORD` — Keystore password.
- `AI_TRACK_KEY_PASSWORD` — Key password.
- `AI_TRACK_KEY_ALIAS` — Key alias (e.g., `ai_track_key`).
- `FIREBASE_TOKEN` — CI token from `firebase login:ci` to allow `firebase appdistribution:distribute`.
- `FIREBASE_APP_ID` — Firebase Android app id (from `google-services.json`, looks like `1:1234567890:android:abcdef123456`).

To set up the keystore for CI:
- Encode your keystore to base64 and add it to `AI_TRACK_KEYSTORE_BASE64`.

```powershell
# PowerShell: base64 encode
[Convert]::ToBase64String([IO.File]::ReadAllBytes('C:\path\to\ai_track.jks')) | Out-File -Encoding ascii keystore.b64
# Copy keystore.b64 contents into GitHub secret
```

### Helpers: encode the keystore (recommended)

The repository includes helper scripts to create the base64 string needed for the `AI_TRACK_KEYSTORE_BASE64` secret.

PowerShell (Windows):

```powershell
# Run from repo root (PowerShell)
.\scripts\encode-keystore.ps1 -KeystorePath C:\path\to\ai_track.jks -OutFile keystore.b64
# Then copy the contents of keystore.b64 into the GitHub secret value.
```

Bash (macOS / Linux):

```bash
# Make the script executable once: chmod +x ./scripts/encode-keystore.sh
./scripts/encode-keystore.sh /path/to/ai_track.jks keystore.b64
# Then copy keystore.b64 contents into the GitHub secret value.
```

Notes:
- The CI workflow (GitHub Actions) will decode the base64 secret into `android/keystore/ai_track.jks` and write a `android/key.properties` file.
- Keep `key.properties` and the raw keystore out of version control. The template `key.properties.template` is included in the repo to help developers prepare their local file.

## Security notes
- `key.properties` and keystore files are ignored by `.gitignore`.
- Keep keystore backups in a secure location.
- Revert any development-only `firestore.rules` changes before public release.
- Restrict Google Maps API keys to the app package name and SHA fingerprints in Google Cloud Console.

## Next steps I can do for you
- Add `key.properties` template and automate secret creation steps.
- Add a Firebase App Distribution group and invite testers (requires access to your Firebase project).
- Prepare instructions for iOS (TestFlight) if you want to distribute there as well.

## Web hosting (GitHub Pages + Firebase Hosting)

This project can build a Flutter web bundle and host it either on GitHub Pages or Firebase Hosting (or both). The repository includes a workflow `.github/workflows/deploy_web.yml` which:

- builds the web app (`flutter build web`) and publishes the output in `build/web` to the `gh-pages` branch using `peaceiris/actions-gh-pages`.
- optionally deploys to Firebase Hosting when `FIREBASE_TOKEN` and `FIREBASE_PROJECT_ID` repository secrets are set.

Placeholders / Live link
- After the first successful deployment you can set a canonical link for your hosted app. Add the live URL here after you confirm it:

Live site: https://jascons.github.io/AI-Track/  (Link for the live domain hosting of web/mobile apps)

To configure a custom domain on Firebase Hosting follow the Firebase console instructions (Ownership verification + DNS records). For GitHub Pages you can configure a custom domain in the repository settings and point a CNAME/A record to GitHub Pages IPs.

Required repository secrets for web hosting (optional):
- `FIREBASE_TOKEN` — created with `firebase login:ci` (for CI deploy)
- `FIREBASE_PROJECT_ID` — your Firebase project id

Local test of the web build:

```powershell
flutter build web --release
# Serve locally to check
python -m http.server 8000 -d build/web
# then open http://localhost:8000
```

Notes:
- If you want the same domain for the native Android/iOS apps (e.g. deep links), configure the domain and verify ownership in Firebase and in the app manifest (Android) or associated domains (iOS).
