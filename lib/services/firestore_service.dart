import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  FirestoreService._();
  static final instance = FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _transitCol =>
      _db.collection('transit');

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

  Future<DocumentSnapshot<Map<String, dynamic>>> getTransitById(String id) {
    return _transitCol.doc(id).get();
  }

  Future<void> updateTransit(String id, Map<String, Object?> data) async {
    await _transitCol.doc(id).update(data);
  }

  Future<void> deleteTransit(String id) async {
    await _transitCol.doc(id).delete();
  }

  CollectionReference<Map<String, dynamic>> get _operatorsCol =>
      _db.collection('operators');

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

  Stream<QuerySnapshot<Map<String, dynamic>>> operatorsStream() {
    return _operatorsCol.orderBy('createdAt', descending: true).snapshots();
  }

  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _db.collection('users');

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserById(String uid) {
    return _usersCol.doc(uid).get();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> userStream(String uid) {
    return _usersCol.doc(uid).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> usersStream() {
    return _usersCol.orderBy('createdAt', descending: true).snapshots();
  }

  CollectionReference<Map<String, dynamic>> get _routesCol =>
      _db.collection('routes');

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

  Stream<QuerySnapshot<Map<String, dynamic>>> routesStream({
    required String vehicle,
    required String type,
  }) {
    return _routesCol
        .where('vehicle', isEqualTo: vehicle)
        .where('type', isEqualTo: type)
        .snapshots();
  }

  Future<List<Map<String, dynamic>>> getRoutesOrTransitFallback({
    required String vehicle,
    required String type,
  }) async {
    final routes = await getRoutesForVehicleAndType(
      vehicle: vehicle,
      type: type,
    );
    if (routes.isNotEmpty) return routes;

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
