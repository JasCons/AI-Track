import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Firestore access is routed through `FirestoreService` helper.

import '../services/firestore_service.dart';
import '../services/prediction_service.dart';
import '../services/vehicle_simulator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TransitTrackPage extends StatefulWidget {
  const TransitTrackPage({super.key});

  @override
  State<TransitTrackPage> createState() => _TransitTrackPageState();
}

class _TransitTrackPageState extends State<TransitTrackPage> {
  String _selectedType = "rail";
  String? _selectedVehicle;
  String? _selectedRouteId;

  List<String> _vehiclesForType(String type) {
    if (type == "rail") {
      return ["lrt-1", "lrt-2", "mrt-3"];
    }
    return ["bus", "jeep", "uv express"];
  }

  List<Map<String, dynamic>> _availableRoutes = [];
  bool _loadingRoutes = false;
  String? _error;
  StreamSubscription? _routesSubscription;
  StreamSubscription? _transitSubscription;
  StreamSubscription? _vehicleSubscription;
  final Map<String, Map<String, dynamic>> _routesById = {};
  GoogleMapController? _mapController;
  final Set<Marker> _mapMarkers = {};
  final Set<Polyline> _polylines = {};
  int? _predictedArrivalMinutes;
  bool _loadingPrediction = false;
  bool _isSimulating = false;

  @override
  void initState() {
    super.initState();
    _selectedVehicle = _vehiclesForType(_selectedType).first;
    _fetchRoutes();
  }

  Future<void> _fetchRoutes() async {
    if (_selectedVehicle == null) return;

    setState(() {
      _loadingRoutes = true;
      _error = null;
    });

    try {
      // Skip API server, go directly to Firestore for faster loading
      final serverRoutes = <Map<String, dynamic>>[];

      if (serverRoutes.isNotEmpty) {
        setState(() {
          _availableRoutes = serverRoutes
              .map(
                (r) => {
                  'id':
                      r['id']?.toString() ??
                      r['routeId']?.toString() ??
                      r['name']?.toString(),
                  'name': r['name']?.toString() ?? r['id']?.toString(),
                },
              )
              .toList(growable: false);
          _selectedRouteId = _availableRoutes.isNotEmpty
              ? _availableRoutes.first['id'] as String
              : null;
        });
      } else {
        // Fallback to Firestore (route_register's database). We seed an
        // in-memory map with the one-off result from `routes` or the
        // transit-derived fallback and then subscribe to both `routes`
        // and `transit` collections so the UI shows entries from either
        // source in real time.
        final routes = await FirestoreService.instance
            .getRoutesOrTransitFallback(
              vehicle: _selectedVehicle!,
              type: _selectedType,
            );

        // Seed the merged map with the one-off result from routes or the
        // transit fallback we received above.
        _routesById.clear();
        for (final r in routes) {
          _routesById[r['id'] as String] = Map<String, dynamic>.from(r);
        }

        // If we have a selected id, ensure the selected route exists in the
        // merged results and update the map view.
        setState(() {
          _availableRoutes = _routesById.values.toList(growable: false);
          _selectedRouteId = _availableRoutes.isNotEmpty
              ? _availableRoutes.first['id'] as String
              : null;
        });
        if (_selectedRouteId != null) {
          final match = _availableRoutes.firstWhere(
            (r) => r['id'] == _selectedRouteId,
            orElse: () => _availableRoutes.first,
          );
          _updateMapFromRoute(match);
          _startVehicleTracking();
        }

        // Subscribe to `routes` collection for live updates and merge into
        // the in-memory map.
        _routesSubscription?.cancel();
        _routesSubscription = FirestoreService.instance
            .routesStream(vehicle: _selectedVehicle!, type: _selectedType)
            .listen((snap) {
              try {
                for (final d in snap.docs) {
                  final data = d.data();
                  _routesById[d.id] = {
                    'id': d.id,
                    'name': data['name'] ?? d.id,
                    ...data,
                  };
                }
                if (!mounted) return;
                setState(() {
                  _availableRoutes = _routesById.values.toList(growable: false);
                  if (_selectedRouteId == null && _availableRoutes.isNotEmpty) {
                    _selectedRouteId = _availableRoutes.first['id'] as String;
                  }
                });
              } catch (e, st) {
                // Log and surface a non-fatal error instead of crashing the app.
                // ignore: avoid_print
                print('TransitTrack routesStream handler error: $e\n$st');
                if (!mounted) return;
                setState(() => _error = e.toString());
              }
            }, onError: (e) => setState(() => _error = e.toString()));

        // Also subscribe to recent transit docs so entries written only
        // into `transit` appear live. Filter client-side for best-effort
        // matches.
        _transitSubscription?.cancel();
        _transitSubscription = FirestoreService.instance.transitStream().listen((
          snap,
        ) {
          try {
            final vehicleLower = _selectedVehicle!.toLowerCase();
            final typeLower = _selectedType.toLowerCase();
            for (final d in snap.docs) {
              final data = d.data();
              final transitType = (data['transitType'] ?? '')
                  .toString()
                  .toLowerCase();
              if (transitType.contains(vehicleLower) ||
                  transitType.contains(typeLower)) {
                _routesById[d.id] = {
                  'id': d.id,
                  'name': data['transitName'] ?? d.id,
                  'vehicle': _selectedVehicle,
                  'type': _selectedType,
                  ...data,
                };
              }
            }
            if (!mounted) return;
            setState(() {
              _availableRoutes = _routesById.values.toList(growable: false);
              if (_selectedRouteId == null && _availableRoutes.isNotEmpty) {
                _selectedRouteId = _availableRoutes.first['id'] as String;
              }
            });
          } catch (e, st) {
            // ignore malformed transit docs; surface error instead of crashing
            // ignore: avoid_print
            print('TransitTrack transitStream handler error: $e\n$st');
            if (!mounted) return;
            setState(() => _error = e.toString());
          }
        }, onError: (e) => setState(() => _error = e.toString()));
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _availableRoutes = [];
        _selectedRouteId = null;
      });
    } finally {
      if (mounted) setState(() => _loadingRoutes = false);
    }
  }

  void _startVehicleTracking() {
    _vehicleSubscription?.cancel();
    if (_selectedRouteId == null) return;

    _vehicleSubscription = FirebaseFirestore.instance
        .collection('vehicles')
        .where('route', isEqualTo: _selectedRouteId)
        .snapshots()
        .listen((snapshot) {
      _mapMarkers.removeWhere((m) => m.markerId.value.startsWith('vehicle_'));
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final lat = data['lat'] as double?;
        final lng = data['lng'] as double?;
        final plateNumber = data['plateNumber'] as String?;
        
        if (lat != null && lng != null) {
          _mapMarkers.add(Marker(
            markerId: MarkerId('vehicle_${doc.id}'),
            position: LatLng(lat, lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
            infoWindow: InfoWindow(
              title: plateNumber ?? 'Vehicle',
              snippet: data['eta'] != null ? 'ETA: ${data['eta']} min' : 'In transit',
            ),
          ));
          
          if (data['eta'] != null && mounted) {
            setState(() => _predictedArrivalMinutes = data['eta'] as int);
          }
        }
      }
      
      if (mounted) setState(() {});
    });
  }

  void _updateMapFromRoute(Map<String, dynamic> route) {
    try {
      _mapMarkers.removeWhere((m) => !m.markerId.value.startsWith('vehicle_'));
      _polylines.clear();

      double? parseDouble(dynamic v) {
        if (v == null) return null;
        if (v is num) return v.toDouble();
        if (v is String) return double.tryParse(v);
        return null;
      }

      // Common shapes: 'coordinates' as List of {lat: ..., lng: ...}
      final coords = route['coordinates'];
      if (coords is List && coords.isNotEmpty) {
        final points = <LatLng>[];
        for (final item in coords) {
          try {
            if (item is Map) {
              final lat = parseDouble(item['lat']);
              final lng = parseDouble(item['lng']);
              if (lat != null && lng != null) points.add(LatLng(lat, lng));
            } else if (item is List && item.length >= 2) {
              final lat = parseDouble(item[0]);
              final lng = parseDouble(item[1]);
              if (lat != null && lng != null) points.add(LatLng(lat, lng));
            }
          } catch (_) {
            // ignore malformed coordinate entries
            continue;
          }
        }
        if (points.isNotEmpty) {
          // Remove duplicate consecutive points
          final uniquePoints = <LatLng>[points.first];
          for (int i = 1; i < points.length; i++) {
            if (points[i].latitude != uniquePoints.last.latitude ||
                points[i].longitude != uniquePoints.last.longitude) {
              uniquePoints.add(points[i]);
            }
          }
          
          // Add markers for endpoints and a polyline for the route
          _mapMarkers.add(
            Marker(
              markerId: const MarkerId('start'),
              position: uniquePoints.first,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
              infoWindow: InfoWindow(title: route['name']?.toString() ?? 'Start'),
            ),
          );
          _mapMarkers.add(
            Marker(
              markerId: const MarkerId('end'),
              position: uniquePoints.last,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              infoWindow: const InfoWindow(title: 'Destination'),
            ),
          );
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              points: uniquePoints,
              color: Colors.blue,
              width: 4,
            ),
          );
          // Move camera to first point
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(points.first, 13),
          );
          if (mounted) setState(() {});
          return;
        }
      }

      // Fallback: single coordinate fields
      final lat = parseDouble(route['lat']);
      final lng = parseDouble(route['lng']);
      if (lat != null && lng != null) {
        final p = LatLng(lat, lng);
        _mapMarkers.add(Marker(markerId: const MarkerId('pt'), position: p));
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(p, 13));
        if (mounted) setState(() {});
      }
    } catch (e, st) {
      // Avoid crashing the UI due to malformed route data; log and continue.
      // ignore: avoid_print
      print('TransitTrack _updateMapFromRoute error: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicles = _vehiclesForType(_selectedType);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Transit Track"),
        actions: [
          if (_isSimulating)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Chip(
                avatar: const Icon(Icons.circle, color: Colors.green, size: 12),
                label: const Text('Live', style: TextStyle(fontSize: 12)),
                backgroundColor: Colors.green.shade100,
              ),
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 32.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Select Transit",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedType,
                                items: const [
                                  DropdownMenuItem(
                                    value: "rail",
                                    child: Text("Rail"),
                                  ),
                                  DropdownMenuItem(
                                    value: "road",
                                    child: Text("Road"),
                                  ),
                                ],
                                onChanged: (v) {
                                  if (v == null) return;
                                  setState(() {
                                    _selectedType = v;
                                    _selectedVehicle = _vehiclesForType(
                                      v,
                                    ).first;
                                  });
                                  _fetchRoutes();
                                },
                                decoration: const InputDecoration(
                                  labelText: "Transit Type",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedVehicle,
                                items: vehicles
                                    .map(
                                      (v) => DropdownMenuItem(
                                        value: v,
                                        child: Text(v.toUpperCase()),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  if (v == null) return;
                                  setState(() {
                                    _selectedVehicle = v;
                                  });
                                  _fetchRoutes();
                                },
                                decoration: const InputDecoration(
                                  labelText: "Vehicle",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _loadingRoutes ? null : _fetchRoutes,
                                icon: const Icon(Icons.refresh),
                                label: Text(
                                  _loadingRoutes
                                      ? 'Refreshing...'
                                      : 'Refresh routes',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: _debugShowRawRoutes,
                              child: const Text('Show raw routes (debug)'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Select Route",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_loadingRoutes)
                          const Center(child: CircularProgressIndicator())
                        else if (_error != null)
                          Text(
                            'Error: $_error',
                            style: const TextStyle(color: Colors.red),
                          )
                        else if (_availableRoutes.isEmpty)
                          const Text(
                            "No routes found for selected vehicle.",
                            style: TextStyle(fontStyle: FontStyle.italic),
                          )
                        else
                          DropdownButtonFormField<String>(
                            initialValue:
                                _availableRoutes.any(
                                  (r) => r['id'] == _selectedRouteId,
                                )
                                ? _selectedRouteId
                                : null,
                            items: _availableRoutes
                                .map(
                                  (r) => DropdownMenuItem(
                                    value: r["id"] as String,
                                    child: Text(r["name"] as String),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() {
                                _selectedRouteId = v;
                                _isSimulating = false;
                              });
                              VehicleSimulator.instance.stopSimulation(v);
                              // Update map for selected route
                              final match = _availableRoutes.firstWhere(
                                (r) => r['id'] == v,
                                orElse: () => {} as Map<String, dynamic>,
                              );
                              if (match.isNotEmpty) {
                                _updateMapFromRoute(match);
                                _startVehicleTracking();
                              }
                            },
                            decoration: const InputDecoration(
                              labelText: "Route",
                              border: OutlineInputBorder(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (_selectedRouteId != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Route Details",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Vehicle: ${_selectedVehicle?.toUpperCase()}",
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Route ID: $_selectedRouteId",
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 12),
                          if (_predictedArrivalMinutes != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Estimated arrival: $_predictedArrivalMinutes min',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (_loadingPrediction)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: LinearProgressIndicator(),
                            ),
                          SizedBox(
                            height: 400,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: GoogleMap(
                                initialCameraPosition: const CameraPosition(
                                  target: LatLng(14.5995, 120.9842),
                                  zoom: 12,
                                ),
                                markers: _mapMarkers,
                                polylines: _polylines,
                                onMapCreated: (c) => _mapController = c,
                                myLocationEnabled: true,
                                myLocationButtonEnabled: true,
                                zoomControlsEnabled: true,
                                mapType: MapType.normal,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isSimulating ? null : _startSimulation,
                                  icon: const Icon(Icons.play_arrow),
                                  label: Text(_isSimulating ? 'Tracking...' : 'Start Live Track'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: !_isSimulating ? null : _stopSimulation,
                                  icon: const Icon(Icons.stop),
                                  label: const Text('Stop'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _debugShowRawRoutes() async {
    try {
      // Dev: allow reading routes without sign-in (firestore.rules set to
      // public read for /routes in dev). This helps debugging when testing
      // on different devices or emulators.
      if (_selectedVehicle == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Select a vehicle first')));
        return;
      }
      final routes = await FirestoreService.instance.getRoutesForVehicleAndType(
        vehicle: _selectedVehicle!,
        type: _selectedType,
      );
      // Also fetch recent `transit` docs as a debugging aid so you can
      // inspect the original documents that may have been written instead
      // of `routes` entries.
      final transitDocs = await FirestoreService.instance
          .transitStream()
          .first
          .then(
            (snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
          );

      final routesBody = routes.map((r) => r.toString()).join('\n---\n');
      final transitBody = transitDocs.map((t) => t.toString()).join('\n---\n');
      final body =
          'ROUTES:\n${routesBody.isEmpty ? 'No routes' : routesBody}\n\nTRANSIT (recent):\n${transitBody.isEmpty ? 'No transit docs' : transitBody}';
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dctx) => AlertDialog(
          title: const Text('Raw routes'),
          content: SingleChildScrollView(
            child: Text(body.isEmpty ? 'No routes' : body),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dctx).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error reading routes: $e')));
    }
  }

  Future<void> _predictArrival() async {
    if (_selectedRouteId == null) return;

    final route = _availableRoutes.firstWhere(
      (r) => r['id'] == _selectedRouteId,
      orElse: () => {},
    );
    if (route.isEmpty) return;

    setState(() {
      _loadingPrediction = true;
      _predictedArrivalMinutes = null;
    });

    try {
      final coords = route['coordinates'];
      if (coords is List && coords.length >= 2) {
        final start = coords.first;
        final end = coords.last;

        double? lat1, lng1, lat2, lng2;
        if (start is Map) {
          lat1 = _toDouble(start['lat']);
          lng1 = _toDouble(start['lng']);
        }
        if (end is Map) {
          lat2 = _toDouble(end['lat']);
          lng2 = _toDouble(end['lng']);
        }

        if (lat1 != null && lng1 != null && lat2 != null && lng2 != null) {
          final result = await PredictionService.instance.predictArrival(
            routeId: _selectedRouteId!,
            currentLat: lat1,
            currentLng: lng1,
            destLat: lat2,
            destLng: lng2,
          );

          if (result.success && result.estimatedMinutes != null) {
            setState(() => _predictedArrivalMinutes = result.estimatedMinutes);
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Prediction failed: ${result.error}')),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loadingPrediction = false);
    }
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  void _startSimulation() {
    if (_selectedRouteId == null) return;
    
    final route = _availableRoutes.firstWhere(
      (r) => r['id'] == _selectedRouteId,
      orElse: () => {},
    );
    
    if (route.isEmpty) return;
    
    final coords = route['coordinates'];
    if (coords is List && coords.isNotEmpty) {
      final points = <LatLng>[];
      for (final item in coords) {
        try {
          if (item is Map) {
            final lat = _toDouble(item['lat']);
            final lng = _toDouble(item['lng']);
            if (lat != null && lng != null) points.add(LatLng(lat, lng));
          } else if (item is List && item.length >= 2) {
            final lat = _toDouble(item[0]);
            final lng = _toDouble(item[1]);
            if (lat != null && lng != null) points.add(LatLng(lat, lng));
          }
        } catch (_) {
          continue;
        }
      }
      
      if (points.isNotEmpty) {
        VehicleSimulator.instance.startSimulation(
          _selectedRouteId!,
          points,
          route['transitName']?.toString() ?? 'Vehicle',
        );
        setState(() => _isSimulating = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Live tracking started')),
          );
        }
      }
    }
  }

  void _stopSimulation() {
    if (_selectedRouteId != null) {
      VehicleSimulator.instance.stopSimulation(_selectedRouteId!);
      setState(() => _isSimulating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Live tracking stopped')),
        );
      }
    }
  }

  @override
  void dispose() {
    _routesSubscription?.cancel();
    _transitSubscription?.cancel();
    _vehicleSubscription?.cancel();
    if (_selectedRouteId != null) {
      VehicleSimulator.instance.stopSimulation(_selectedRouteId!);
    }
    super.dispose();
  }
}
