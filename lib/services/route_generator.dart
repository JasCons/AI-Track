import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteGenerator {
  static final Map<String, LatLng> _philippineLocations = {
    // Metro Manila
    'makati': LatLng(14.5547, 121.0244),
    'bel-air': LatLng(14.5631, 121.0167),
    'washington': LatLng(14.5500, 121.0100),
    'bgc': LatLng(14.5515, 121.0473),
    'taguig': LatLng(14.5176, 121.0509),
    'manila': LatLng(14.5995, 121.0000),
    'quezon city': LatLng(14.6760, 121.0437),
    'cubao': LatLng(14.6231, 121.0539),
    'pasig': LatLng(14.5764, 121.0851),
    'mandaluyong': LatLng(14.5794, 121.0359),
    'san juan': LatLng(14.6019, 121.0355),
    'pasay': LatLng(14.5378, 121.0014),
    'paranaque': LatLng(14.4793, 121.0198),
    'las pinas': LatLng(14.4453, 120.9820),
    'muntinlupa': LatLng(14.4083, 121.0390),
    'alabang': LatLng(14.4167, 120.9833),
    'pitx': LatLng(14.4167, 120.9833),
    'edsa': LatLng(14.5547, 121.0244),
    'ortigas': LatLng(14.5865, 121.0560),
    'shaw': LatLng(14.5820, 121.0530),
    'guadalupe': LatLng(14.5600, 121.0400),
    'ayala': LatLng(14.5547, 121.0244),
    'buendia': LatLng(14.5630, 121.0200),
    
    // North
    'caloocan': LatLng(14.6488, 120.9830),
    'valenzuela': LatLng(14.7000, 120.9833),
    'malabon': LatLng(14.6620, 120.9570),
    'navotas': LatLng(14.6667, 120.9417),
    'marikina': LatLng(14.6507, 121.1029),
    'antipolo': LatLng(14.5863, 121.1755),
    'cainta': LatLng(14.5778, 121.1222),
    'taytay': LatLng(14.5667, 121.1333),
    'montalban': LatLng(14.7333, 121.1500),
    'san mateo': LatLng(14.6972, 121.1214),
    'novaliches': LatLng(14.7272, 121.0333),
    'fairview': LatLng(14.7333, 121.0667),
    'commonwealth': LatLng(14.6833, 121.0833),
    'sapang palay': LatLng(14.8167, 121.0500),
    
    // South
    'cavite': LatLng(14.4791, 120.8970),
    'bacoor': LatLng(14.4590, 120.9450),
    'imus': LatLng(14.4297, 120.9367),
    'dasmarinas': LatLng(14.3294, 120.9367),
    'tagaytay': LatLng(14.1153, 120.9621),
    'laguna': LatLng(14.2691, 121.4113),
    'sta rosa': LatLng(14.3123, 121.1114),
    'binan': LatLng(14.3333, 121.0833),
    'calamba': LatLng(14.2117, 121.1653),
    'san pedro': LatLng(14.3583, 121.0167),
    
    // East
    'rizal': LatLng(14.6037, 121.3084),
    'tanay': LatLng(14.4983, 121.2867),
    'morong': LatLng(14.5167, 121.2333),
    'teresa': LatLng(14.5600, 121.2100),
    'angono': LatLng(14.5267, 121.1533),
    'binangonan': LatLng(14.4647, 121.1928),
    
    // Bulacan
    'bulacan': LatLng(14.7942, 120.8794),
    'malolos': LatLng(14.8433, 120.8114),
    'meycauayan': LatLng(14.7333, 120.9500),
    'marilao': LatLng(14.7583, 120.9472),
    'bocaue': LatLng(14.7989, 120.9261),
    'balagtas': LatLng(14.8167, 120.8833),
    'san jose del monte': LatLng(14.8139, 121.0453),
  };

  static List<LatLng> generateRoute(String routeName) {
    final parts = routeName.toLowerCase().split('-').map((s) => s.trim()).toList();
    if (parts.length < 2) return [];

    final start = _findLocation(parts[0]);
    final end = _findLocation(parts[parts.length - 1]);
    
    if (start == null || end == null) return [];

    final waypoints = <LatLng>[start];
    
    // Generate intermediate points
    final steps = 8;
    for (int i = 1; i < steps; i++) {
      final lat = start.latitude + (end.latitude - start.latitude) * i / steps;
      final lng = start.longitude + (end.longitude - start.longitude) * i / steps;
      waypoints.add(LatLng(lat, lng));
    }
    
    waypoints.add(end);
    return waypoints;
  }

  static LatLng? _findLocation(String name) {
    final normalized = name.toLowerCase().trim();
    
    // Exact match
    if (_philippineLocations.containsKey(normalized)) {
      return _philippineLocations[normalized];
    }
    
    // Partial match
    for (var entry in _philippineLocations.entries) {
      if (entry.key.contains(normalized) || normalized.contains(entry.key)) {
        return entry.value;
      }
    }
    
    return null;
  }
}
