import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/api_service.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  String? _reportType;
  bool _loading = false;
  String? _error;
  bool _writeToFirestore = true;
  String? _transitId;

  static const List<String> _reportTypes = [
    'Route Change',
    'Traffic Issue',
    'Vehicle Issue',
    'Safety Concern',
    'Service Delay',
    'Other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
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

    final String title = _titleController.text.trim();
    final String description = _descriptionController.text.trim();
    final String location = _locationController.text.trim();

    try {
      String? token;
      User? currentUser;
      try {
        currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          token = await currentUser.getIdToken();
        }
      } catch (_) {}

      if (_writeToFirestore && currentUser == null) {
        setState(() {
          _error = 'Please sign in before writing reports to Firestore.';
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
            _error = 'Please sign in to submit reports to Firestore.';
            _loading = false;
          });
          return;
        }
        try {
          final db = FirebaseFirestore.instance;
          final docRef = await db.collection('reports').add({
            'title': title,
            'description': description,
            'location': location,
            'reportType': _reportType,
            'transitId': _transitId,
            'reporterUid': currentUser.uid,
            'status': 'pending',
            'createdAt': FieldValue.serverTimestamp(),
          });
          firestoreId = docRef.id;
          print('Report saved to Firestore: $firestoreId');
        } catch (e) {
          firestoreError = e.toString();
          print('Firestore error: $e');
        }
      }

      if (firestoreId != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report submitted to Firestore: $firestoreId')),
        );
        Navigator.of(context).pop();
        return;
      }

      if (!_writeToFirestore) {
        final payload = {
          'title': title,
          'description': description,
          'location': location,
          'reportType': _reportType,
          'transitId': _transitId,
          'token': token,
        };

        final result = await ApiService.instance.submitReport(payload);
        if (result.success) {
          serverId = result.id;
        } else {
          serverError = result.error ?? 'Server error';
        }
      }

      if (firestoreId != null || serverId != null) {
        final parts = <String>[];
        if (firestoreId != null) parts.add('Firestore id: $firestoreId');
        if (serverId != null) parts.add('Server id: $serverId');
        final message = 'Report submitted (${parts.join(', ')})';
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
      appBar: AppBar(title: const Text('Submit Report')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Report an Issue',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Report Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter report title'
                      : null,
                ),

                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  initialValue: _reportType,
                  items: _reportTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  decoration: const InputDecoration(
                    labelText: 'Report Type',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _reportType = v),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Select report type'
                      : null,
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                    hintText: 'Enter location or route affected',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter location'
                      : null,
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    hintText: 'Provide details about the issue',
                  ),
                  maxLines: 4,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter description'
                      : null,
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
                          : const Text('Submit Report'),
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
