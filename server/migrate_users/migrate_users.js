const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

async function main() {
  // Load service account path from env or default file name
  const saPath = process.env.GOOGLE_APPLICATION_CREDENTIALS || path.join(__dirname, 'serviceAccountKey.json');
  if (!fs.existsSync(saPath)) {
    console.error('Service account JSON not found. Set GOOGLE_APPLICATION_CREDENTIALS or place serviceAccountKey.json next to this script.');
    process.exit(1);
  }

  admin.initializeApp({
    credential: admin.credential.cert(require(saPath)),
  });

  const db = admin.firestore();
  const auth = admin.auth();

  console.log('Starting migration: scanning users collection for documents with email+password...');

  const usersRef = db.collection('users');
  const snapshot = await usersRef.get();
  console.log(`Found ${snapshot.size} user docs to inspect.`);

  let created = 0;
  let skipped = 0;
  let failed = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();
    // Skip if already migrated marker exists
    if (data.migrated === true || data.authUid) {
      skipped++;
      console.log(`Skipping ${doc.id} (already migrated)`);
      continue;
    }

    const email = data.email;
    const password = data.password; // plaintext stored previously

    if (!email || !password) {
      console.log(`Skipping ${doc.id} (missing email or password)`);
      skipped++;
      continue;
    }

    try {
      // Create Firebase Auth user
      const userRecord = await auth.createUser({
        email: email,
        password: String(password),
        emailVerified: false,
        disabled: false,
      });

      // Update Firestore doc: remove password, add authUid and migrated marker
      const updates = {
        authUid: userRecord.uid,
        migrated: true,
        migratedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      // Remove password: set to FieldValue.delete()
      updates.password = admin.firestore.FieldValue.delete();

      await doc.ref.update(updates);

      console.log(`Migrated ${doc.id}: created auth uid ${userRecord.uid}`);
      created++;
    } catch (err) {
      console.error(`Failed to migrate ${doc.id}:`, err);
      failed++;
    }
  }

  console.log('Migration complete. Summary:');
  console.log(`  created: ${created}`);
  console.log(`  skipped: ${skipped}`);
  console.log(`  failed:  ${failed}`);
  process.exit(failed > 0 ? 2 : 0);
}

main().catch(err => {
  console.error('Fatal error running migration:', err);
  process.exit(1);
});
