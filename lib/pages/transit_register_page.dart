import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../services/api_service.dart';
import '../services/route_generator.dart';

class TransitRegisterPage extends StatefulWidget {
  const TransitRegisterPage({super.key});

  @override
  State<TransitRegisterPage> createState() => _TransitRegisterPageState();
}

class _TransitRegisterPageState extends State<TransitRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _coordsController = TextEditingController();
  String? _transitType;
  bool _loading = false;
  String? _error;
  bool _writeToFirestore = true;

  static const List<String> _transitTypes = [
    'Bus',
    'Jeepney',
    'Taxi',
    'Tricycle',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _licenseController.dispose();
    _plateController.dispose();
    _coordsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
    });

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
    });

    final String transitName = _nameController.text.trim();
    final String licenseId = _licenseController.text.trim();
    final String plateNumber = _plateController.text.trim();

    try {
      String? token;
      User? currentUser;
      try {
        currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) token = await currentUser.getIdToken();
      } catch (_) {}

      if (_writeToFirestore && currentUser == null) {
        setState(() {
          _error = 'Please sign in before writing to Firestore.';
          _loading = false;
        });
        return;
      }

      String? firestoreId;
      String? firestoreError;
      String? serverId;
      String? serverError;

      if (_writeToFirestore) {
        if (currentUser == null) {
          setState(() {
            _error = 'Please sign in to register transit to Firestore.';
            _loading = false;
          });
          return;
        }
        try {
          final id = await FirestoreService.instance.addTransit(
            transitName: transitName,
            transitType: _transitType ?? 'Other',
            licenseId: licenseId,
            plateNumber: plateNumber,
            operatorUid: currentUser.uid,
          );
          firestoreId = id;
          print('Transit saved to Firestore: $firestoreId');
        } catch (e) {
          firestoreError = e.toString();
          print('Firestore error: $e');
        }
      }

      String vehicleCode = 'other';
      final t = (_transitType ?? '').toLowerCase();
      if (t.contains('bus')) {
        vehicleCode = 'bus';
      } else if (t.contains('jeep')) {
        vehicleCode = 'jeep';
      } else if (t.contains('lrt') || t.contains('mrt') || t.contains('rail')) {
        vehicleCode = 'rail';
      }

      final routeType = vehicleCode == 'rail' ? 'rail' : 'road';

      List<dynamic>? coords;
      final coordsText = _coordsController.text.trim();
      
      if (coordsText.isEmpty) {
        final generated = RouteGenerator.generateRoute(transitName);
        if (generated.isNotEmpty) {
          coords = generated.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList();
        }
      } else {
        try {
          final parsed = jsonDecode(coordsText);
          if (parsed is List) {
            coords = parsed;
          } else if (parsed is Map) {
            coords = [parsed];
          }
        } catch (_) {
          final parts = coordsText.split(',').map((s) => s.trim()).toList();
          if (parts.length >= 2) {
            final lat = double.tryParse(parts[0]);
            final lng = double.tryParse(parts[1]);
            if (lat != null && lng != null) {
              coords = [{'lat': lat, 'lng': lng}];
            }
          }
        }
      }

      if (_writeToFirestore && currentUser != null) {
        try {
          final routeId = await FirestoreService.instance.addRoute(
            name: transitName,
            vehicle: vehicleCode,
            type: routeType,
            coordinates: coords,
            createdByUid: currentUser.uid,
          );
          print('Route saved to Firestore: $routeId');
          
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Transit registered: Transit ID: $firestoreId, Route ID: $routeId')),
          );
          Navigator.of(context).pop();
          return;
        } catch (e) {
          firestoreError = (firestoreError == null)
              ? e.toString()
              : '$firestoreError; route: $e';
          print('Route creation error: $e');
        }
      }

      if (!_writeToFirestore) {
        final payload = {
          'transitName': transitName,
          'transitType': _transitType,
          'licenseId': licenseId,
          'plateNumber': plateNumber,
          'token': token,
        };

        final result = await ApiService.instance.registerTransit(payload);
        if (result.success) {
          serverId = result.id;
        } else {
          serverError = result.error ?? 'Server error';
        }
      }

      if (serverId != null && firestoreId == null) {
        try {
          final id = await FirestoreService.instance.addRoute(
            name: transitName,
            vehicle: vehicleCode,
            type: routeType,
            coordinates: coords,
            createdByUid: null,
          );
          firestoreId = id;
        } catch (e) {
          firestoreError = (firestoreError == null)
              ? e.toString()
              : '$firestoreError; route: $e';
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Could not create route in Firestore: $e'),
              ),
            );
          }
        }
      }

      if (firestoreId != null || serverId != null) {
        final parts = <String>[];
        if (firestoreId != null) parts.add('Firestore id: $firestoreId');
        if (serverId != null) parts.add('Server id: $serverId');
        final message = 'Transit registered (${parts.join(', ')})';
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        Navigator.of(context).pop();
      } else {
        final errors = <String>[];
        if (firestoreError != null) errors.add('Firestore: $firestoreError');
        if (serverError != null) errors.add('Server: $serverError');
        setState(() {
          _error = errors.join('\n');
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transit Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Register Transit',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Route names like "Cubao - Alabang" or "Bel-Air - Washington" will auto-generate map routes',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Switch(
                      value: _writeToFirestore,
                      onChanged: (v) => setState(() => _writeToFirestore = v),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Write directly to Firestore (dev only)'),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Transit Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter transit name'
                      : null,
                ),

                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  initialValue: _transitType,
                  items: _transitTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  decoration: const InputDecoration(
                    labelText: 'Transit Type',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _transitType = v),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Select transit type'
                      : null,
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _licenseController,
                  decoration: const InputDecoration(
                    labelText: 'License ID',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter license ID'
                      : null,
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _plateController,
                  decoration: const InputDecoration(
                    labelText: 'Plate Number',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter plate number'
                      : null,
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _coordsController,
                  decoration: const InputDecoration(
                    labelText: 'Coordinates (auto-generated if empty)',
                    border: OutlineInputBorder(),
                    hintText: 'Leave empty to auto-generate from route name',
                    helperText: 'Route names like "Bel-Air - Washington" auto-generate coordinates',
                  ),
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                ),

                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      child: _loading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Register Transit'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
