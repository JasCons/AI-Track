import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../firebase_options.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';

class PassengerLoginPage extends StatefulWidget {
  const PassengerLoginPage({super.key});

  @override
  State<PassengerLoginPage> createState() => _PassengerLoginPageState();
}

class _PassengerLoginPageState extends State<PassengerLoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool showPassword = false;
  String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF98FB98),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Placeholder for logo
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 56,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Passenger Login',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter your passenger credentials',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.person),
                      labelText: 'Passenger Email',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: !showPassword,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_outline),
                      labelText: 'Password',
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                      suffixIcon: IconButton(
                        icon: Icon(
                          showPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            showPassword = !showPassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          errorMessage = null;
                        });
                        final username = usernameController.text.trim();
                        final password = passwordController.text;
                        // validate email or username (allow demo usernames)
                        bool isValidLogin(String v) {
                          if (v.isEmpty) return false;
                          // permissive email check
                          final emailRe = RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+");
                          if (emailRe.hasMatch(v)) return true;
                          // username: 2+ chars, letters/numbers/._- allowed
                          final userRe = RegExp(r"^[A-Za-z0-9._-]{2,}");
                          return userRe.hasMatch(v);
                        }

                        if (!isValidLogin(username)) {
                          setState(() {
                            errorMessage = 'Please enter a valid email';
                          });
                          return;
                        }
                        final auth = AuthService();
                        final result = await auth.login(username, password);
                        // Debug: log the raw result so we can diagnose navigation failures
                        // ignore: avoid_print
                        print('Passenger login result: $result');
                        if (!mounted) return;
                        if (result['success'] == true) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            Navigator.of(context).pushReplacementNamed('/menu');
                          });
                        } else {
                          setState(() {
                            errorMessage = result['error'] ?? 'Login failed';
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Login',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Debug helpers
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            // Show configured Firebase options and runtime apps
                            String runtime = '';
                            try {
                              final apps = Firebase.apps
                                  .map((a) => a.name)
                                  .join(', ');
                              final options = Firebase.app().options;
                              runtime = 'Firebase apps: $apps\n';
                              runtime += 'projectId: ${options.projectId}\n';
                              runtime += 'apiKey: ${options.apiKey}\n';
                              runtime += 'appId: ${options.appId}\n';
                            } catch (e) {
                              runtime = 'Failed to read Firebase.app(): $e\n';
                            }
                            final staticOpts =
                                DefaultFirebaseOptions.currentPlatform;
                            runtime +=
                                '\nDefaultFirebaseOptions.currentPlatform:\n';
                            runtime += 'projectId: ${staticOpts.projectId}\n';
                            runtime += 'apiKey: ${staticOpts.apiKey}\n';

                            // Show dialog with the info
                            if (!mounted) return;
                            await showDialog<void>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Firebase Runtime / Config'),
                                content: SingleChildScrollView(
                                  child: Text(runtime),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: const Text('Show Firebase Config'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            // REST sign-in test using project's API key
                            final username = usernameController.text.trim();
                            final password = passwordController.text;
                            final emailRe = RegExp(
                              r"^[^@\s]+@[^@\s]+\.[^@\s]+$",
                            );
                            if (!emailRe.hasMatch(username)) {
                              if (!mounted) return;
                              setState(() {
                                errorMessage =
                                    'Enter a valid email to run REST sign-in test.';
                              });
                              return;
                            }

                            final apiKey =
                                DefaultFirebaseOptions.currentPlatform.apiKey;
                            final uri = Uri.parse(
                              'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey',
                            );
                            Map<String, dynamic> body = {
                              'email': username,
                              'password': password,
                              'returnSecureToken': true,
                            };
                            try {
                              final resp = await http
                                  .post(
                                    uri,
                                    headers: {
                                      'Content-Type': 'application/json',
                                    },
                                    body: jsonEncode(body),
                                  )
                                  .timeout(const Duration(seconds: 10));
                              if (!mounted) return;
                              await showDialog<void>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(
                                    'REST sign-in (${resp.statusCode})',
                                  ),
                                  content: SingleChildScrollView(
                                    child: Text(resp.body),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              await showDialog<void>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('REST sign-in failed'),
                                  content: Text('Error: $e'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                          child: const Text('Test REST Sign-in'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
