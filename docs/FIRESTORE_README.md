# Firestore setup (AI-Track)

This file explains how to apply the provided `firestore.rules` and test Firestore writes.

1. Apply the rules to your Firebase project

   - Open the Firebase Console → Firestore Database → Rules and paste the contents of `firestore.rules`.
   - Alternatively, you can deploy rules using the Firebase CLI:

```bash
# from project root
firebase deploy --only firestore:rules
```

2. Test by creating a transit document

   - Use the app's Transit Register form (set the toggle to "Write directly to Firestore") to create a document.
   - Or use the Firestore emulator/local SDK to write test documents.

4. Quick examples (Dart)

Use the `FirestoreService` helper in `lib/services/firestore_service.dart`.

Add a new operator:

```dart
final id = await FirestoreService.instance.addOperator(
   email: 'dallas@payday2.com',
   operatorName: 'Dallas Payday2',
   password: 'medicbag01',
);
print('Operator doc id: $id');
```

Query operator by email:

```dart
final doc = await FirestoreService.instance.getOperatorByEmail('dallas@payday2.com');
if (doc != null && doc.exists) {
   final data = doc.data();
   print('Found operator: ${data?['operatorName']}');
}
```

Stream operators for an admin view:

```dart
FirestoreService.instance.operatorsStream().listen((snapshot) {
   for (final d in snapshot.docs) {
      print('operator: ${d.data()}');
   }
});
```

3. Security notes

   - These rules are intentionally simple. Review and harden them before production.
   - Consider role-based claims (custom claims) or Firestore 'operators' collection to manage permissions.
