import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/vehicle_simulator.dart';

class LiveTrackPage extends StatefulWidget {
  const LiveTrackPage({super.key});

  @override
  State<LiveTrackPage> createState() => _LiveTrackPageState();
}

class _LiveTrackPageState extends State<LiveTrackPage> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  StreamSubscription? _vehicleSubscription;
  String? _selectedRoute;
  int? _eta;

  final Map<String, List<LatLng>> _routes = {
    'Sapang Palay - PITX': [
      LatLng(14.8167, 121.0500), // Sapang Palay
      LatLng(14.7500, 121.0400),
      LatLng(14.6800, 121.0350),
      LatLng(14.6231, 121.0539), // Cubao
      LatLng(14.5995, 121.0300), // Manila
      LatLng(14.5547, 121.0244), // EDSA
      LatLng(14.5000, 121.0100),
      LatLng(14.4500, 121.0000),
      LatLng(14.4167, 120.9833), // PITX
    ],
    'Cubao - Alabang': [
      LatLng(14.6231, 121.0539), // Cubao
      LatLng(14.5995, 121.0300), // Manila
      LatLng(14.5547, 121.0244), // EDSA
      LatLng(14.5000, 121.0100),
      LatLng(14.4500, 121.0000),
      LatLng(14.4167, 120.9833), // Alabang
    ],
  };

  @override
  void initState() {
    super.initState();
    _selectedRoute = _routes.keys.first;
    _loadRoute();
    _startVehicleTracking();
  }

  void _loadRoute() {
    if (_selectedRoute == null) return;
    final points = _routes[_selectedRoute]!;
    
    _polylines.clear();
    _polylines.add(Polyline(
      polylineId: PolylineId(_selectedRoute!),
      points: points,
      color: Colors.blue,
      width: 5,
    ));

    _markers.clear();
    _markers.add(Marker(
      markerId: const MarkerId('start'),
      position: points.first,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: InfoWindow(
        title: _selectedRoute!.split(' - ')[0],
        snippet: 'Starting point',
      ),
    ));
    _markers.add(Marker(
      markerId: const MarkerId('end'),
      position: points.last,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: InfoWindow(
        title: _selectedRoute!.split(' - ')[1],
        snippet: 'Destination',
      ),
    ));

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        _boundsFromLatLngList(points),
        50,
      ),
    );
    setState(() {});
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double? x0, x1, y0, y1;
    for (LatLng latLng in list) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1!) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1!) y1 = latLng.longitude;
        if (latLng.longitude < y0!) y0 = latLng.longitude;
      }
    }
    return LatLngBounds(
      northeast: LatLng(x1!, y1!),
      southwest: LatLng(x0!, y0!),
    );
  }

  void _startVehicleTracking() {
    _vehicleSubscription?.cancel();
    _vehicleSubscription = FirebaseFirestore.instance
        .collection('vehicles')
        .where('route', isEqualTo: _selectedRoute)
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final lat = data['lat'] as double?;
        final lng = data['lng'] as double?;
        final plateNumber = data['plateNumber'] as String?;
        
        if (lat != null && lng != null) {
          _markers.removeWhere((m) => m.markerId.value.startsWith('vehicle_'));
          _markers.add(Marker(
            markerId: MarkerId('vehicle_${doc.id}'),
            position: LatLng(lat, lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
            infoWindow: InfoWindow(
              title: plateNumber ?? 'Vehicle',
              snippet: _eta != null ? 'ETA: $_eta min' : 'In transit',
            ),
            rotation: 0,
          ));
          
          if (data['eta'] != null) {
            setState(() => _eta = data['eta'] as int);
          }
          
          if (mounted) setState(() {});
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(14.5995, 120.9842),
              zoom: 11,
            ),
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (controller) {
              _mapController = controller;
              _loadRoute();
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
          ),
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<String>(
                      value: _selectedRoute,
                      isExpanded: true,
                      items: _routes.keys.map((route) {
                        return DropdownMenuItem(
                          value: route,
                          child: Text(route, style: const TextStyle(fontWeight: FontWeight.bold)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedRoute = value);
                        _loadRoute();
                        _startVehicleTracking();
                      },
                    ),
                    if (_eta != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 20, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text('ETA: $_eta min', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (_selectedRoute != null) {
                          VehicleSimulator.instance.startSimulation(
                            _selectedRoute!,
                            _routes[_selectedRoute]!,
                            'ABC-1234',
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vehicle simulation started')),
                          );
                        }
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start Simulation'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 50,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              onPressed: () => Navigator.pop(context),
              child: const Icon(Icons.close),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _vehicleSubscription?.cancel();
    super.dispose();
  }
}
