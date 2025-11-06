Firestore Java sample

This small sample shows how to initialize the Firestore client from a service account and perform basic CRUD and a snapshot listener.

Requirements
- Java 11+
- Gradle
- A Firebase / GCP service account JSON with Firestore permissions

Run
1. Place your service account JSON somewhere safe, e.g. `~/keys/serviceAccountKey.json`.
2. From this folder:

```powershell
cd server/firestore-java
gradle run --args "C:\path\to\serviceAccountKey.json ai-track-42cce"
```

Replace the path and project ID as appropriate.

Notes
- Do NOT commit your service account JSON to version control.
- This example uses the google-cloud-firestore Java client library.
