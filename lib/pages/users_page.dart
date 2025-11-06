import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Profile')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Not signed in. Please log in to view profile.'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: StreamBuilder(
        stream: FirestoreService.instance.userStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final doc = snapshot.data;
          if (doc == null || !doc.exists) {
            return const Center(child: Text('Profile not found in Firestore.'));
          }

          final data = doc.data() ?? <String, dynamic>{};

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('UID: ${doc.id}', style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 12),
                  for (final entry in data.entries)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 120,
                            child: Text(
                              '${entry.key}:',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text('${entry.value}')),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
