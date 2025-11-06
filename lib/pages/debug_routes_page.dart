import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DebugRoutesPage extends StatelessWidget {
  const DebugRoutesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug Routes')),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('routes').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No routes in Firestore'));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data();
              return Card(
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ID: ${doc.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('vehicle: ${data['vehicle']}'),
                      Text('type: ${data['type']}'),
                      Text('name: ${data['name']}'),
                      Text('coordinates: ${data['coordinates']}'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
