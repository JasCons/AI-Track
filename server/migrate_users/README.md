Migration tool: migrate_users

This folder contains a Node.js script to migrate existing user documents in Firestore
(which may have stored plaintext passwords) into Firebase Authentication users using the
Firebase Admin SDK.

WARNING: Storing plaintext passwords in Firestore is insecure. Use this script only to
migrate to Firebase Auth, then remove plaintext passwords and mark documents as migrated.

Setup
1. Install dependencies:
   npm install firebase-admin

2. Provide a service account JSON for a Firebase project with Admin privileges. Either:
   - Set environment variable GOOGLE_APPLICATION_CREDENTIALS to the path of the JSON, or
   - Place the JSON file next to the script named `serviceAccountKey.json`.

Run
   node migrate_users.js

What it does
- Scans the `users` collection.
- For each document with `email` and `password` fields (and not marked `migrated`),
  it creates a Firebase Auth user with that email/password.
- It updates the Firestore doc with `authUid`, `migrated: true`, `migratedAt`, and removes
  the `password` field.

Rollback / Verification
- The script reports created/skipped/failed counts.
- Verify created users in Firebase Console -> Authentication -> Users.
- If something goes wrong, you can re-run the script (it skips docs with `migrated: true`).

Security
- Do NOT commit service account JSON to source control.
- Rotate any credentials and inform users if passwords may have been exposed.

Notes
- This script assumes the plaintext passwords are valid and meet Firebase password strength requirements.
- If passwords are too weak, the admin.createUser call may fail — handle those users manually.
