import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class AddTestRoutePage extends StatelessWidget {
  const AddTestRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Test Routes')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Add sample routes to test Transit Track features',
                style: TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _addLRT1Route(context),
              child: const Text('Add LRT-1 Route'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _addBusRoute(context),
              child: const Text('Add Bus Route'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addLRT1Route(BuildContext context) async {
    try {
      await FirestoreService.instance.addRoute(
        name: 'North Avenue to Baclaran',
        vehicle: 'lrt-1',
        type: 'rail',
        coordinates: [
          {'lat': 14.6564, 'lng': 121.0320},
          {'lat': 14.6500, 'lng': 121.0250},
          {'lat': 14.5350, 'lng': 120.9980},
        ],
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('LRT-1 route added!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _addBusRoute(BuildContext context) async {
    try {
      await FirestoreService.instance.addRoute(
        name: 'EDSA Carousel',
        vehicle: 'bus',
        type: 'road',
        coordinates: [
          {'lat': 14.6760, 'lng': 121.0437},
          {'lat': 14.5547, 'lng': 121.0244},
        ],
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bus route added!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
