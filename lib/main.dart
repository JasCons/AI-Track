import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'pages/logout_page.dart';
import 'pages/passenger_login_page.dart';
import 'pages/operator_login_page.dart';
import 'pages/signup_page.dart';
import 'pages/troubleshoot_page.dart';
import 'pages/debug_page.dart';
import 'pages/transit_register_page.dart';
import 'pages/transit_track.dart';
import 'pages/users_page.dart';
import 'pages/users_list_page.dart';
import 'pages/menu_page.dart';
import 'pages/report.dart';
import 'pages/add_test_route_page.dart';
import 'pages/debug_routes_page.dart';
import 'pages/quick_add_route.dart';
import 'pages/add_sample_routes_page.dart';
import 'services/debug_logger.dart';
import 'dart:async';
import 'package:flutter/scheduler.dart';

void main() {
  final start = DateTime.now();
  DebugLogger().log('main() start');
  WidgetsFlutterBinding.ensureInitialized();
  DebugLogger().log(
    'ensureInitialized done (${DateTime.now().difference(start).inMilliseconds} ms)',
  );
  runApp(const AppInit(startupTimeMillis: 0));
}

class AppInit extends StatefulWidget {
  final int startupTimeMillis;
  const AppInit({super.key, required this.startupTimeMillis});

  @override
  State<AppInit> createState() => _AppInitState();
}

class _AppInitState extends State<AppInit> {
  bool _initializing = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initFirebase();
  }

  Future<void> _initFirebase() async {
    setState(() {
      _initializing = true;
      _error = null;
    });
    try {
      DebugLogger().log('Inspecting Firebase options before initialize');
      FirebaseOptions options = DefaultFirebaseOptions.currentPlatform;

      // Quick sanity check for common placeholder values generated in templates
      bool isPlaceholderKey(String apiKey) {
        final apiKeyLower = apiKey.toLowerCase();
        return apiKey.isEmpty ||
            apiKey.contains('REPLACE') ||
            apiKey.startsWith('YOUR_') ||
            apiKeyLower.contains('example') ||
            apiKey.contains('EXAMPLE');
      }

      // If current platform options look like placeholders, attempt safe fallbacks
      if (isPlaceholderKey(options.apiKey)) {
        DebugLogger().log(
          'Detected placeholder API key for current platform. Attempting fallback options.',
        );
        final androidOptions = DefaultFirebaseOptions.android;
        final webOptions = DefaultFirebaseOptions.web;
        if (!isPlaceholderKey(androidOptions.apiKey)) {
          DebugLogger().log(
            'Falling back to Android FirebaseOptions on this platform',
          );
          options = androidOptions;
        } else if (!isPlaceholderKey(webOptions.apiKey)) {
          DebugLogger().log(
            'Falling back to Web FirebaseOptions on this platform',
          );
          options = webOptions;
        } else {
          final msg =
              'Firebase configuration appears to contain placeholder values.\n'
              'Please run `flutterfire configure` or paste the values from your Firebase console into `lib/firebase_options.dart`.\n'
              'Also ensure platform files `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist` are present for the respective platforms.';
          DebugLogger().log(
            'Aborting Firebase.initializeApp(): placeholder options detected',
          );
          setState(() {
            _initializing = false;
            _error = msg;
          });
          return;
        }
      }

      DebugLogger().log('Starting Firebase.initializeApp()');
      final t0 = DateTime.now();
      await Firebase.initializeApp(
        options: options,
      ).timeout(const Duration(seconds: 8));
      final took = DateTime.now().difference(t0).inMilliseconds;
      DebugLogger().log('Firebase.initializeApp() completed in $took ms');
      setState(() {
        _initializing = false;
      });
    } catch (e) {
      DebugLogger().log('Firebase.initializeApp() failed: $e');
      setState(() {
        _initializing = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    if (_error != null) {
      return MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Initialization error')),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Failed to initialize Firebase.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(_error ?? '', style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _initFirebase,
                      child: const Text('Retry'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const TroubleshootPage(),
                          ),
                        );
                      },
                      child: const Text('Troubleshoot'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const TransitTrackerApp();
  }
}

class TransitTrackerApp extends StatelessWidget {
  const TransitTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const _TransitTrackerAppStateful();
  }
}

class _TransitTrackerAppStateful extends StatefulWidget {
  const _TransitTrackerAppStateful();

  @override
  State<_TransitTrackerAppStateful> createState() =>
      _TransitTrackerAppStatefulState();
}

class _TransitTrackerAppStatefulState
    extends State<_TransitTrackerAppStateful> {
  @override
  void initState() {
    super.initState();
    // Log first frame timing
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final t = DateTime.now();
      DebugLogger().log('First frame rendered at ${t.toIso8601String()}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI-TRACK: Transit Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: '/home',
      routes: {
        '/home': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/passenger-login': (context) => const PassengerLoginPage(),
        '/operator-login': (context) => const OperatorLoginPage(),
        '/debug': (context) => const DebugPage(),
        '/menu': (context) => const MenuPage(),
        '/transit-track': (context) => const TransitTrackPage(),
        '/transit-register': (context) => const TransitRegisterPage(),
        '/users': (context) => const UsersPage(),
        '/users-list': (context) => const UsersListPage(),
        '/report': (context) => const ReportPage(),
        '/logout': (context) => const LogoutPage(),
        '/add-test-route': (context) => const AddTestRoutePage(),
        '/debug-routes': (context) => const DebugRoutesPage(),
        '/quick-add': (context) => const QuickAddRoutePage(),
        '/add-sample-routes': (context) => const AddSampleRoutesPage(),
      },
    );
  }
}

// Placeholder pages
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF98FB98),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Placeholder for logo
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.directions_bus,
                    size: 64,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'AI-TRACK: Transit Tracker',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Welcome! Track and manage your transit with ease.',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: 220,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Log In', style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 220,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/signup'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Sign Up', style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 220,
                  child: OutlinedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('About AI-TRACK'),
                          content: const Text(
                            'AI-TRACK: Transit Tracker\n\n'
                            'Smart transit tracking system with real-time GPS tracking, '
                            'route optimization, and analytics.'
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: const BorderSide(color: Colors.green, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'About Us',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 220,
                  child: OutlinedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Contact Us'),
                          content: const Text(
                            'For support and inquiries about AI-TRACK Transit Tracker.'
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: const BorderSide(color: Colors.green, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Contact Us',
                      style: TextStyle(fontSize: 18),
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

// LoginPage is now imported from pages/login_page.dart

// Replace the LoginPage route with a selector page
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF98FB98),
      appBar: AppBar(
        title: const Text('Select Login Type'),
        backgroundColor: const Color(0xFF98FB98),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/passenger-login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Passenger Login'),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/operator-login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Operator Login'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// MenuPage is provided by pages/menu_page.dart

// `ReportPage` is provided by `lib/pages/report.dart`.
