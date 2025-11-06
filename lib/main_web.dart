import 'package:flutter/material.dart';

void main() {
  runApp(const AITrackWebApp());
}

class AITrackWebApp extends StatelessWidget {
  const AITrackWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI-Track - Smart Transit Tracking',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const WebHomePage(),
    );
  }
}

class WebHomePage extends StatelessWidget {
  const WebHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI-Track'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_bus,
              size: 100,
              color: Colors.blue,
            ),
            SizedBox(height: 20),
            Text(
              'AI-Track',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Smart Transit Tracking System',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 40),
            Card(
              margin: EdgeInsets.all(20),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Features',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    ListTile(
                      leading: Icon(Icons.location_on, color: Colors.green),
                      title: Text('Real-time GPS Tracking'),
                      subtitle: Text('Track vehicles in real-time'),
                    ),
                    ListTile(
                      leading: Icon(Icons.route, color: Colors.orange),
                      title: Text('Route Optimization'),
                      subtitle: Text('AI-powered route planning'),
                    ),
                    ListTile(
                      leading: Icon(Icons.notifications, color: Colors.red),
                      title: Text('Smart Notifications'),
                      subtitle: Text('Arrival predictions and alerts'),
                    ),
                    ListTile(
                      leading: Icon(Icons.analytics, color: Colors.purple),
                      title: Text('Analytics Dashboard'),
                      subtitle: Text('Performance insights and reports'),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Download the mobile app for full functionality',
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}