# AI-Track (Demo)

This repository contains a simple Flutter app (AI-Track) and a minimal Dart backend used for demonstrating login flows.

This README explains what's been added, how to run the server and the app locally, and notes about development and security.

---

- A tiny Dart Shelf server at `server/bin/server.dart` exposing two endpoints:
  - `POST /auth/login` — expects JSON `{ "username": "...", "password": "..." }`. Returns `{ "token": "...", "username": "..." }` on success.
  - `GET /auth/verify` — expects header `Authorization: Bearer <token>`. Returns `{ "username": "..." }` on success.
  - Note: server uses an in-memory user store and a simple base64 token (username:timestamp) for demo purposes.

- App-side client `lib/services/auth_service.dart` that:
  - Calls `/auth/login` to authenticate and stores the token + username in `SharedPreferences`.
  - Calls `/auth/verify` to confirm a stored token is valid.
  - Clears stored auth data on logout.

- Login pages wired to `AuthService`:
  - `lib/pages/login_page.dart`
  - `lib/pages/passenger_login_page.dart`
  - `lib/pages/operator_login_page.dart`
  - `lib/pages/logout_page.dart` now calls `AuthService.logout()`.

- Dependencies added to the Flutter app: `http` and `shared_preferences` (top-level `pubspec.yaml`).
- Server dependencies in `server/pubspec.yaml`: `shelf`, `shelf_router`, `http` (for test helper).

---

## Quick start (Windows PowerShell)

Run these from your project root `c:\projects\flutter\AI-Track`.

1) Install app dependencies:

```powershell
cd c:\projects\flutter\AI-Track
flutter pub get
```

2) Install server dependencies:

```powershell
cd c:\projects\flutter\AI-Track\server
dart pub get
```

3) Start the server (default port 8080):

```powershell
cd c:\projects\flutter\AI-Track\server
dart run bin/server.dart
```

4) Test the login endpoint (PowerShell curl):

```powershell
curl -Method POST -Uri http://localhost:8080/auth/login -Body '{"username":"passenger","password":"pass123"}' -ContentType 'application/json'
```

You should receive JSON with `token` and `username` on valid credentials.

5) Run the Flutter app:

```powershell
cd c:\projects\flutter\AI-Track
flutter run
```

Note for emulator vs device:
- Android emulator: `AuthService` defaults to `http://10.0.2.2:8080` which maps emulator -> host machine.
- Real device: set `AuthService(baseUrl: 'http://<your-machine-ip>:8080')` so the device can reach your host.

---

## API Contract

- POST /auth/login
  - Request body: `{ "username": string, "password": string }`
  - Success response: 200 `{ "token": string, "username": string }`
  - Failure: 400/401 `{ "error": string }`

- GET /auth/verify
  - Header: `Authorization: Bearer <token>`
  - Success: 200 `{ "username": string }`
  - Failure: 401 `{ "error": string }`

---

## Security & production notes

This is a demo server. For production you must:
- Use HTTPS (TLS) for all network traffic.
- Replace the naive token with signed JWTs (with expiration) or secure opaque tokens validated server-side.
- Store secrets (signing keys) safely and rotate them.
- Store tokens with secure storage on client (e.g., `flutter_secure_storage`) for sensitive apps.
- Use hashed+salted passwords (bcrypt/argon2) in a real database instead of plain strings.
- Add rate-limiting, brute-force protections, and logging/monitoring.

---

## Next steps (I can help with any of these):
- Replace demo token with JWT signing and verification.
- Add a registration endpoint and UI.
- Add tests for server endpoints.
- Improve Flutter UX (loading spinner, error types, form validation).
- Move token storage to secure storage.

---

## How long does it take?

- Creation of the server & wiring the Flutter login pages (what I implemented) took about 30–90 minutes depending on environment and iteration. The changes here are intentionally minimal and safe for a demo.

- Typical times for the follow-ups:
  - Add README (done): ~10–20 minutes.
  - Add loading UI + form validation: 30–60 minutes.
  - Implement JWTs server+client: 1–2 hours (demo JWT, no DB). Adding secure storage & refreshing tokens adds another 1–2 hours.
  - Add tests for server endpoints: 30–60 minutes for basic tests.

Times above are rough and depend on polish, test coverage, and environment setup.

---

If you want, I can now:
- Expand the README with more examples (Postman collection, sample responses).
- Add server tests and a run script.
- Implement JWT support next.

Tell me which next step you'd like tomorrow, or I can add the Postman collection and basic tests next.

---

## Firebase setup (step-by-step)

If you want to use Firebase Authentication instead of the demo server (I already switched the app code to use Firebase Auth), follow these platform-specific steps.

Prerequisites:
- A Google account
- Flutter SDK and a working Flutter project (this repository)

1) Create a Firebase project
- Open https://console.firebase.google.com
- Click "Add project" and follow the prompts.

2) Add Android app to Firebase
- In the Firebase console, go to Project Settings > General, click "Add app" and choose Android.
- Enter your Android package name (example: `com.example.helloworld` — check `android/app/src/main/AndroidManifest.xml` for your actual package name).
- (Optional) Provide app nickname and SHA-1 if you plan to use Google Sign-In.
- Download `google-services.json` and place it in `android/app/`.

Android project configuration notes:
- In `android/build.gradle` ensure `classpath 'com.google.gms:google-services:4.3.14'` is present in `dependencies` block of `buildscript` (or use the new plugins DSL per Firebase docs).
- In `android/app/build.gradle` add `apply plugin: 'com.google.gms.google-services'` at the bottom.
- If you use the new Gradle settings, follow the latest Firebase docs for the Gradle plugin versions.

3) Add iOS app to Firebase
- In the Firebase console, click "Add app" and choose iOS.
- Enter your iOS bundle id (check `ios/Runner.xcodeproj` or `ios/Runner/Info.plist`).
- Download `GoogleService-Info.plist` and add it to `ios/Runner` in Xcode (drag into Runner target).

iOS project configuration notes:
- Open `ios/Runner.xcworkspace` in Xcode and ensure `GoogleService-Info.plist` is included in the Runner target.
- For newer Xcode/Flutter projects, follow Firebase iOS setup docs if you need extra steps.

4) (Optional) Use FlutterFire CLI to configure platforms automatically
- Install FlutterFire CLI:
  ```powershell
  dart pub global activate flutterfire_cli
  ```
- Run in repo root:
  ```powershell
  flutterfire configure
  ```
  This helps create `firebase_options.dart` and wires default options for your platforms.

5) Run `flutter pub get` and rebuild app
- In the project root:
  ```powershell
  flutter pub get
  flutter run
  ```

6) Testing sign-in
- Create a test user in Firebase Console > Authentication > Users > Add User (email + password).
- Use that email/password in the app login form (AuthService treats `username` as email). Example test users used during development:
  - passenger@example.com / pass123
  - operator@example.com  / op123

Notes and troubleshooting
- Emulator vs device: Android emulator -> use `10.0.2.2` for host addresses, but for Firebase you typically authenticate against Firebase servers so emulator host mapping isn't relevant.
- If you see errors like "Missing google-services.json" or platform-specific plugin errors, double-check that the config files are in the right platform folders and included in the target.
- For iOS, run `pod install` in `ios/` (Flutter tooling usually handles this):
  ```powershell
  cd ios; pod install; cd ..
  ```
- If Firebase initialization fails at app start, read the console/logcat output. Common fixes: add `firebase_options.dart` through `flutterfire configure`, ensure `GoogleService-Info.plist`/`google-services.json` are present, check package names / bundle IDs.

Security reminder
- Firebase Authentication stores credentials securely and provides session management; still follow good practices: enable email verification, use secure tokens, and follow role-based access rules on backend resources.

If you want, I can now add a small registration UI and a quick guide that creates the two test users in Firebase and demonstrates logging in from the app.
# helloworld

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
