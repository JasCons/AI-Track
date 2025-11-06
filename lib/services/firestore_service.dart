import 'package:cloud_firestore/cloud_firestore.dart';

/// Lightweight Firestore helper for common operations used by the app.
///
/// This file provides simple wrappers around `FirebaseFirestore.instance` for
/// creating, reading, updating, and deleting transit documents. Keep it small
/// and testable; expand as your data model becomes more complex.
class FirestoreService {
  FirestoreService._();
  static final instance = FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _transitCol =>
      _db.collection('transit');

  /// Adds a transit document and returns the new document id.
  Future<String> addTransit({
    required String transitName,
    required String transitType,
    required String licenseId,
    required String plateNumber,
    String? operatorUid,
  }) async {
    final docRef = await _transitCol.add({
      'transitName': transitName,
      'transitType': transitType,
      'licenseId': licenseId,
      'plateNumber': plateNumber,
      'operatorUid': operatorUid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  /// Returns a stream of transit documents (useful for real-time lists).
  Stream<QuerySnapshot<Map<String, dynamic>>> transitStream({
    String? operatorUid,
  }) {
    Query<Map<String, dynamic>> q = _transitCol.orderBy(
      'createdAt',
      descending: true,
    );
    if (operatorUid != null) {
      q = q.where('operatorUid', isEqualTo: operatorUid);
    }
    return q.snapshots();
  }

  /// Get a single transit document by id.
  Future<DocumentSnapshot<Map<String, dynamic>>> getTransitById(String id) {
    return _transitCol.doc(id).get();
  }

  /// Update fields for a transit document.
  Future<void> updateTransit(String id, Map<String, Object?> data) async {
    await _transitCol.doc(id).update(data);
  }

  /// Delete a transit document.
  Future<void> deleteTransit(String id) async {
    await _transitCol.doc(id).delete();
  }

  // ---- Operator helpers -------------------------------------------------

  CollectionReference<Map<String, dynamic>> get _operatorsCol =>
      _db.collection('operators');

  /// Add an operator document (id optional). Returns the new doc id.
  Future<String> addOperator({
    required String email,
    required String operatorName,
    required String password,
    String? uid,
  }) async {
    final data = <String, dynamic>{
      'email': email,
      'operatorName': operatorName,
      'password': password,
      if (uid != null) 'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    };

    final docRef = await _operatorsCol.add(data);
    return docRef.id;
  }

  /// Query operator by email. Returns the first matching document or null.
  Future<DocumentSnapshot<Map<String, dynamic>>?> getOperatorByEmail(
    String email,
  ) async {
    final q = await _operatorsCol
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    return q.docs.first;
  }

  /// Stream all operators (for admin views) - be careful with large datasets.
  Stream<QuerySnapshot<Map<String, dynamic>>> operatorsStream() {
    return _operatorsCol.orderBy('createdAt', descending: true).snapshots();
  }

  // ---- Users helpers ---------------------------------------------------

  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _db.collection('users');

  /// Get a single user document by uid.
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserById(String uid) {
    return _usersCol.doc(uid).get();
  }

  /// Stream a single user's document (useful for profile pages).
  Stream<DocumentSnapshot<Map<String, dynamic>>> userStream(String uid) {
    return _usersCol.doc(uid).snapshots();
  }

  /// Stream all users (admin use only). Be careful with large collections.
  Stream<QuerySnapshot<Map<String, dynamic>>> usersStream() {
    return _usersCol.orderBy('createdAt', descending: true).snapshots();
  }

  // ---- Routes helpers --------------------------------------------------

  CollectionReference<Map<String, dynamic>> get _routesCol =>
      _db.collection('routes');

  /// Get routes for a vehicle/type combination.
  Future<List<Map<String, dynamic>>> getRoutesForVehicleAndType({
    required String vehicle,
    required String type,
  }) async {
    final q = await _routesCol
        .where('vehicle', isEqualTo: vehicle)
        .where('type', isEqualTo: type)
        .get();
    return q.docs
        .map((d) {
          final data = d.data();
          return {'id': d.id, 'name': data['name'] ?? d.id, ...data};
        })
        .toList(growable: false);
  }

  /// Stream routes for a vehicle/type combination for real-time updates.
  Stream<QuerySnapshot<Map<String, dynamic>>> routesStream({
    required String vehicle,
    required String type,
  }) {
    return _routesCol
        .where('vehicle', isEqualTo: vehicle)
        .where('type', isEqualTo: type)
        .snapshots();
  }

  /// Try to get routes for the given vehicle/type. If none exist in the
  /// `routes` collection, attempt a best-effort client-side scan of the
  /// `transit` collection and return matching docs converted into the
  /// route-shaped map so the UI can display them. This is a helpful dev
  /// fallback when some entries were written only into `transit`.
  Future<List<Map<String, dynamic>>> getRoutesOrTransitFallback({
    required String vehicle,
    required String type,
  }) async {
    final routes = await getRoutesForVehicleAndType(
      vehicle: vehicle,
      type: type,
    );
    if (routes.isNotEmpty) return routes;

    // Firestore doesn't support substring queries, so fetch a limited
    // recent set of transit docs and filter client-side for best-effort
    // matches. Keep the limit modest to avoid scanning a very large
    // collection in production; this is intended as a helpful fallback.
    final q = await _transitCol
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();
    final List<Map<String, dynamic>> matches = [];
    final vehicleLower = vehicle.toLowerCase();
    final typeLower = type.toLowerCase();
    for (final d in q.docs) {
      final data = d.data();
      final transitType = (data['transitType'] ?? '').toString().toLowerCase();
      final transitName = data['transitName'] ?? d.id;
      // Match if transitType contains vehicle or matches the requested type.
      if (transitType.contains(vehicleLower) ||
          transitType.contains(typeLower)) {
        matches.add({
          'id': d.id,
          'name': transitName,
          'vehicle': vehicle,
          'type': type,
          ...data,
        });
      }
    }
    return matches;
  }

  /// Add a route document to the `routes` collection.
  ///
  /// `name` is a human-friendly route name (e.g., "Sapang Palay - Pedro Gil").
  /// `vehicle` should be a normalized short id like 'bus', 'jeep', 'uv express',
  /// and `type` is typically 'road' or 'rail'. Optionally include `coordinates`
  /// as a List of objects {lat, lng} or list pairs [lat, lng]. Returns the new
  /// document id.
  Future<String> addRoute({
    required String name,
    required String vehicle,
    required String type,
    List<dynamic>? coordinates,
    String? createdByUid,
  }) async {
    final data = <String, dynamic>{
      'name': name,
      'vehicle': vehicle,
      'type': type,
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (coordinates != null) data['coordinates'] = coordinates;
    if (createdByUid != null) data['createdBy'] = createdByUid;

    final ref = await _routesCol.add(data);
    return ref.id;
  }
}
