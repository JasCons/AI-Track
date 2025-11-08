import 'dart:async';
// removed unused import 'dart:math'
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class VehicleSimulator {
  static final VehicleSimulator instance = VehicleSimulator._();
  VehicleSimulator._();

  final Map<String, Timer> _activeSimulations = {};

  void startSimulation(
    String route,
    List<LatLng> routePoints,
    String plateNumber,
  ) {
    stopSimulation(route);

    int currentIndex = 0;
    _activeSimulations[route] = Timer.periodic(const Duration(seconds: 5), (
      timer,
    ) async {
      if (currentIndex >= routePoints.length) {
        currentIndex = 0;
      }

      final position = routePoints[currentIndex];
      final remainingPoints = routePoints.length - currentIndex;
      final eta = (remainingPoints * 2).clamp(1, 120);

      try {
        await FirebaseFirestore.instance.collection('vehicles').doc(route).set({
          'route': route,
          'lat': position.latitude,
          'lng': position.longitude,
          'plateNumber': plateNumber,
          'eta': eta,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('Error updating vehicle position: $e');
      }

      currentIndex++;
    });
  }

  void stopSimulation(String route) {
    _activeSimulations[route]?.cancel();
    _activeSimulations.remove(route);
  }

  void stopAllSimulations() {
    for (var timer in _activeSimulations.values) {
      timer.cancel();
    }
    _activeSimulations.clear();
  }
}
