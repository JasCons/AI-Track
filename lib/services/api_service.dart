import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// Allows injecting a custom [http.Client] for testing. Defaults to
/// a real [http.Client] when not provided.

/// Simple wrapper for calling the local backend API used by the app.
///
/// - Uses `10.0.2.2:3333` by default (Android emulator -> host machine).
/// - Automatically includes a Firebase ID token in the Authorization header
///   when a user is signed-in.
class ApiService {
  final String baseUrl;
  final http.Client client;

  ApiService({String? baseUrl, http.Client? client})
    : baseUrl = baseUrl ?? 'http://10.0.2.2:3333',
      client = client ?? http.Client();

  static final ApiService instance = ApiService();

  Future<ApiResult> submitReport(Map<String, dynamic> payload) async {
    final uri = Uri.parse('$baseUrl/report/submit');
    return _postJson(uri, payload);
  }

  Future<ApiResult> registerTransit(Map<String, dynamic> payload) async {
    final uri = Uri.parse('$baseUrl/transit/register');
    return _postJson(uri, payload);
  }

  /// Fetch available routes from the backend API.
  /// Expects the server to return a JSON array of route objects, each with
  /// at least an `id` and `name` field. Returns an empty list on error.
  Future<List<Map<String, dynamic>>> fetchRoutes({
    required String vehicle,
    required String type,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/routes?vehicle=${Uri.encodeComponent(vehicle)}&type=${Uri.encodeComponent(type)}',
    );

    String? idToken;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) idToken = await user.getIdToken();
    } catch (_) {}

    final headers = <String, String>{'Content-Type': 'application/json'};
    if (idToken != null) headers['Authorization'] = 'Bearer $idToken';

    try {
      final resp = await client.get(uri, headers: headers);
      if (resp.statusCode != 200) return <Map<String, dynamic>>[];
      final body = resp.body;
      if (body.isEmpty) return <Map<String, dynamic>>[];
      final parsed = jsonDecode(body);
      if (parsed is List) {
        return parsed
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList(growable: false);
      }
      if (parsed is Map && parsed['routes'] is List) {
        return (parsed['routes'] as List)
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList(growable: false);
      }
      return <Map<String, dynamic>>[];
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  Future<ApiResult> _postJson(Uri uri, Map<String, dynamic> payload) async {
    String? idToken;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) idToken = await user.getIdToken();
    } catch (_) {
      // ignore token errors here; call will proceed without token
    }

    final headers = <String, String>{'Content-Type': 'application/json'};
    if (idToken != null) headers['Authorization'] = 'Bearer $idToken';

    try {
      final resp = await client.post(
        uri,
        headers: headers,
        body: jsonEncode(payload),
      );
      final body = resp.body.isNotEmpty ? resp.body : null;
      dynamic parsed;
      try {
        if (body != null) parsed = jsonDecode(body);
      } catch (_) {
        parsed = body;
      }

      if (resp.statusCode == 200) {
        // Expecting a JSON object with { success: true, id: ... }
        final success = parsed is Map && parsed['success'] == true;
        final id = parsed is Map ? parsed['id'] : null;
        return ApiResult(
          success: success,
          id: id?.toString(),
          statusCode: resp.statusCode,
          rawBody: body,
        );
      }

      return ApiResult(
        success: false,
        statusCode: resp.statusCode,
        rawBody: body,
        error: parsed is Map ? (parsed['error']?.toString() ?? body) : body,
      );
    } catch (e) {
      return ApiResult(success: false, error: e.toString());
    }
  }
}

/// Lightweight result object returned by [ApiService].
class ApiResult {
  final bool success;
  final String? id;
  final int? statusCode;
  final String? rawBody;
  final String? error;

  ApiResult({
    required this.success,
    this.id,
    this.statusCode,
    this.rawBody,
    this.error,
  });

  @override
  String toString() =>
      'ApiResult(success: $success, id: $id, status: $statusCode, error: $error)';
}
