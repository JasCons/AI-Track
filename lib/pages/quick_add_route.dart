import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class QuickAddRoutePage extends StatelessWidget {
  const QuickAddRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quick Add Route')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            try {
              await FirestoreService.instance.addRoute(
                name: 'Sapang Palay - Pedro Gil',
                vehicle: 'bus',
                type: 'road',
                coordinates: [
                  {'lat': 14.7500, 'lng': 121.0500},
                  {'lat': 14.5700, 'lng': 120.9900},
                ],
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Route added! Go to Transit Track > Road > Bus')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            }
          },
          child: const Text('Add Bus Route Now'),
        ),
      ),
    );
  }
}
