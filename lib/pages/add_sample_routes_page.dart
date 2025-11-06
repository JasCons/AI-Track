import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class AddSampleRoutesPage extends StatefulWidget {
  const AddSampleRoutesPage({super.key});

  @override
  State<AddSampleRoutesPage> createState() => _AddSampleRoutesPageState();
}

class _AddSampleRoutesPageState extends State<AddSampleRoutesPage> {
  bool _loading = false;
  String _status = '';

  Future<void> _addEdsaCarousel() async {
    setState(() {
      _loading = true;
      _status = 'Adding EDSA Carousel route...';
    });

    try {
      await FirestoreService.instance.addRoute(
        name: 'EDSA Carousel',
        vehicle: 'bus',
        type: 'road',
        coordinates: [
          {'lat': 14.5378, 'lng': 121.0196}, // Monumento
          {'lat': 14.5450, 'lng': 121.0180}, // 5th Avenue
          {'lat': 14.5550, 'lng': 121.0160}, // Balintawak
          {'lat': 14.5650, 'lng': 121.0140}, // Roosevelt
          {'lat': 14.5800, 'lng': 121.0100}, // Munoz
          {'lat': 14.5950, 'lng': 121.0050}, // Bansalangin
          {'lat': 14.6100, 'lng': 121.0000}, // Quezon Avenue
          {'lat': 14.6200, 'lng': 120.9950}, // Kamuning
          {'lat': 14.6300, 'lng': 120.9900}, // Cubao
          {'lat': 14.6100, 'lng': 120.9850}, // Santolan
          {'lat': 14.5900, 'lng': 120.9800}, // Ortigas
          {'lat': 14.5700, 'lng': 120.9850}, // Shaw Boulevard
          {'lat': 14.5500, 'lng': 120.9900}, // Guadalupe
          {'lat': 14.5300, 'lng': 120.9950}, // Buendia
          {'lat': 14.5100, 'lng': 121.0000}, // Ayala
          {'lat': 14.4900, 'lng': 121.0050}, // Magallanes
          {'lat': 14.4700, 'lng': 121.0100}, // Taft Avenue
        ],
      );

      setState(() {
        _status = 'EDSA Carousel added successfully!';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error adding EDSA Carousel: $e';
        _loading = false;
      });
    }
  }

  Future<void> _addSapangPalayPedroGil() async {
    setState(() {
      _loading = true;
      _status = 'Adding Sapang Palay - Pedro Gil route...';
    });

    try {
      await FirestoreService.instance.addRoute(
        name: 'Sapang Palay - Pedro Gil',
        vehicle: 'bus',
        type: 'road',
        coordinates: [
          {'lat': 14.7500, 'lng': 121.0500}, // Sapang Palay
          {'lat': 14.7300, 'lng': 121.0400}, // San Jose del Monte
          {'lat': 14.7000, 'lng': 121.0300}, // Muzon
          {'lat': 14.6700, 'lng': 121.0200}, // Tungkong Mangga
          {'lat': 14.6500, 'lng': 121.0100}, // Fairview
          {'lat': 14.6300, 'lng': 121.0000}, // Commonwealth
          {'lat': 14.6100, 'lng': 120.9900}, // Quezon Avenue
          {'lat': 14.5900, 'lng': 120.9850}, // España
          {'lat': 14.5800, 'lng': 120.9900}, // Legarda
          {'lat': 14.5750, 'lng': 120.9920}, // Recto
          {'lat': 14.5700, 'lng': 120.9900}, // Pedro Gil
        ],
      );

      setState(() {
        _status = 'Sapang Palay - Pedro Gil added successfully!';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error adding Sapang Palay - Pedro Gil: $e';
        _loading = false;
      });
    }
  }

  Future<void> _addBothRoutes() async {
    await _addEdsaCarousel();
    await Future.delayed(const Duration(seconds: 1));
    await _addSapangPalayPedroGil();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Sample Routes')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Add sample routes with proper Google Maps coordinates',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loading ? null : _addEdsaCarousel,
              icon: const Icon(Icons.directions_bus),
              label: const Text('Add EDSA Carousel'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loading ? null : _addSapangPalayPedroGil,
              icon: const Icon(Icons.directions_bus),
              label: const Text('Add Sapang Palay - Pedro Gil'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loading ? null : _addBothRoutes,
              icon: const Icon(Icons.add_circle),
              label: const Text('Add Both Routes'),
            ),
            const SizedBox(height: 24),
            if (_loading) const LinearProgressIndicator(),
            if (_status.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _status.contains('Error')
                      ? Colors.red.shade50
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _status,
                  style: TextStyle(
                    color: _status.contains('Error') ? Colors.red : Colors.green,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            const Text(
              'After adding routes, go to:\nTransit Track > Road > Bus\nto view them on the map.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
