import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../services/debug_logger.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final DebugLogger _log = DebugLogger();

  /// LOGIN with email and password
  Future<Map<String, dynamic>> login(
    String usernameOrEmail,
    String password,
  ) async {
    try {
      _log.log('Attempting login for: $usernameOrEmail');
      _log.log('Firebase Auth emulator: ${_auth.app.options.projectId}');
      
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: usernameOrEmail,
        password: password,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _log.log('Login timeout after 30 seconds');
          throw FirebaseAuthException(
            code: 'network-request-failed',
            message: 'Login timed out. Check your internet connection.',
          );
        },
      );
      _log.log('Login successful for: ${userCredential.user?.email}');
      final user = userCredential.user;
      if (user != null) {
        final docRef = _db.collection('users').doc(user.uid);
        try {
          final snapshot = await docRef.get();
          if (!snapshot.exists) {
            await docRef.set({
              'email': user.email,
              'displayName': user.displayName ?? '',
              'role': 'passenger',
              'createdAt': FieldValue.serverTimestamp(),
            });
            _log.log('Created users/${user.uid} document in Firestore');
          } else {
            _log.log('users/${user.uid} document already exists');
          }
        } catch (e, st) {
          _log.log('Error writing/reading users/${user.uid} doc: $e');
          // Attempt to capture token and project info to aid debugging
          try {
            final token = await user.getIdToken();
            if (token != null && token.length > 50) {
              _log.log(
                'Current user idToken (truncated): ${token.substring(0, 50)}...',
              );
            } else {
              _log.log('Current user idToken (full or null): $token');
            }
          } catch (tokEx) {
            _log.log('Failed to get idToken: $tokEx');
          }
          try {
            final projectId = Firebase.app().options.projectId;
            _log.log('Firebase projectId from options: $projectId');
          } catch (projEx) {
            _log.log('Failed to read Firebase projectId: $projEx');
          }
          _log.log('Stacktrace: $st');
          rethrow;
        }
      }
      return {'success': true, 'user': user};
    } on FirebaseAuthException catch (e) {
      _log.log(
        'FirebaseAuthException during login: code=${e.code}, message=${e.message}',
      );

      // No username lookup here: return user-not-found to the caller.
      String message;
      switch (e.code) {
        case 'invalid-email':
          message = 'Invalid email format.';
          break;
        case 'user-disabled':
          message = 'This user account has been disabled.';
          break;
        case 'user-not-found':
          message = 'No user found with this email.';
          break;
        case 'wrong-password':
          message = 'Incorrect password.';
          break;
        case 'network-request-failed':
          message = 'Network error. Try: 1) Check internet 2) Restart emulator 3) Use real device';
          break;
        default:
          message = e.message ?? 'An unknown error occurred.';
      }
      return {'success': false, 'error': message};
    } catch (e, st) {
      // Some plugin/pigeon mismatches surface as cast/type errors even though
      // the native side completed sign-in and the Firebase SDK updated the
      // current user (we saw id token listeners notified). As a pragmatic
      // workaround, if a currentUser exists treat this as a success and
      // return that user. Log the original error for later investigation.
      _log.log('Exception during login: $e');
      _log.log('Stacktrace: $st');
      final current = _auth.currentUser;
      if (current != null) {
        // ignore: avoid_print
        print(
          'AuthService.login: caught exception but currentUser != null; '
          'treating login as success. error: $e\n$st',
        );
        return {'success': true, 'user': current};
      }
      return {'success': false, 'error': e.toString()};
    }
  }

  /// SIGNUP (Register new user)
  Future<Map<String, dynamic>> register(
    String email,
    String password, {
    String role = 'passenger',
  }) async {
    try {
      _log.log('Starting registration for $email with role: $role');
      final userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              _log.log('Firebase Auth createUser timed out');
              throw Exception(
                'Registration timed out. Please check your internet connection.',
              );
            },
          );
      final user = userCredential.user;
      _log.log('Firebase Auth account created: ${user?.uid}');
      if (user != null) {
        final docRef = _db.collection('users').doc(user.uid);
        _log.log('Writing to Firestore users/${user.uid}...');
        await docRef
            .set({
              'email': user.email,
              'displayName': user.displayName ?? '',
              'role': role,
              'createdAt': FieldValue.serverTimestamp(),
            })
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                _log.log('Firestore write timed out');
                throw Exception(
                  'Failed to save user data. Please try logging in.',
                );
              },
            );
        _log.log(
          'Created users/${user.uid} document after register with role: $role',
        );
      }
      return {'success': true, 'user': userCredential.user};
    } on FirebaseAuthException catch (e) {
      _log.log('FirebaseAuthException: ${e.code} - ${e.message}');
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'Email already in use.';
          break;
        case 'invalid-email':
          message = 'Invalid email.';
          break;
        case 'weak-password':
          message = 'Password is too weak.';
          break;
        default:
          message = e.message ?? 'Registration failed.';
      }
      return {'success': false, 'error': message};
    } catch (e, st) {
      _log.log('Failed to create user document: $e');
      _log.log('Stacktrace: $st');
      return {'success': false, 'error': 'Failed to save user data: $e'};
    }
  }

  /// LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// CURRENT USER
  User? get currentUser => _auth.currentUser;

  /// AUTH STATE STREAM
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
