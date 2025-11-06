import 'dart:convert';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class PredictionService {
  final String baseUrl;
  final http.Client client;

  PredictionService({String? baseUrl, http.Client? client})
    : baseUrl = baseUrl ?? 'http://10.0.2.2:3333',
      client = client ?? http.Client();

  static final PredictionService instance = PredictionService();

  /// Predict arrival time based on route features
  /// Returns estimated minutes until arrival
  Future<PredictionResult> predictArrival({
    required String routeId,
    required double currentLat,
    required double currentLng,
    required double destLat,
    required double destLng,
  }) async {
    final uri = Uri.parse('$baseUrl/predict');

    // Feature vector: [distance, time_of_day, day_of_week, traffic_factor]
    final now = DateTime.now();
    final distance = _calculateDistance(
      currentLat,
      currentLng,
      destLat,
      destLng,
    );
    final features = [
      distance,
      now.hour.toDouble(),
      now.weekday.toDouble(),
      _getTrafficFactor(now),
    ];

    String? idToken;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) idToken = await user.getIdToken();
    } catch (_) {}

    try {
      final resp = await client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'features': features, 'token': idToken}),
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final score = (data['score'] ?? 0.5) as num;
        // Convert score to estimated minutes (0-60 range)
        final minutes = (score * 60).round();
        return PredictionResult(success: true, estimatedMinutes: minutes);
      }
      return PredictionResult(success: false, error: 'Server error');
    } catch (e) {
      return PredictionResult(success: false, error: e.toString());
    }
  }

  double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    // Haversine formula for distance in km
    const r = 6371;
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.pow(math.sin(dLng / 2), 2);
    final c = 2 * math.asin(math.sqrt(a));
    return r * c;
  }

  double _toRadians(double degrees) => degrees * 3.14159265359 / 180;

  double _getTrafficFactor(DateTime time) {
    final hour = time.hour;
    // Peak hours: 7-9 AM and 5-7 PM
    if ((hour >= 7 && hour <= 9) || (hour >= 17 && hour <= 19)) return 1.5;
    return 1.0;
  }
}

class PredictionResult {
  final bool success;
  final int? estimatedMinutes;
  final String? error;

  PredictionResult({required this.success, this.estimatedMinutes, this.error});
}
