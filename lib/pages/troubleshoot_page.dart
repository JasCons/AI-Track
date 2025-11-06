import 'package:flutter/material.dart';
import '../services/debug_logger.dart';

class TroubleshootPage extends StatelessWidget {
  const TroubleshootPage({super.key});

  @override
  Widget build(BuildContext context) {
    final logs = DebugLogger().entries.reversed.toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Troubleshoot & Logs')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            const Text(
              'Onboarding / Steps to check',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '1) Make sure Firebase config files are added to platform folders.',
            ),
            const Text(
              '2) For Android: google-services.json in android/app. For iOS: GoogleService-Info.plist in Runner.',
            ),
            const Text(
              '3) For physical devices, ensure device and host are on same network.',
            ),
            const SizedBox(height: 12),
            const Text(
              'Recent logs',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                ),
                child: logs.isEmpty
                    ? const Text('No logs yet')
                    : ListView.builder(
                        itemCount: logs.length,
                        itemBuilder: (context, i) => Text(logs[i]),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                DebugLogger().clear();
                Navigator.of(context).pop();
              },
              child: const Text('Clear logs & back'),
            ),
          ],
        ),
      ),
    );
  }
}
