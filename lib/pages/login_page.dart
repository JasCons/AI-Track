// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
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
                      Icons.lock,
                      size: 56,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Welcome Back!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please log in to continue',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.person),
                      labelText: 'Username',
                      border: OutlineInputBorder(),
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
                            errorMessage =
                                'Please enter a valid email or username.';
                          });
                          return;
                        }

                        final auth = AuthService();
                        final result = await auth.login(username, password);
                        // Debug: log the raw result so we can diagnose navigation failures
                        // ignore: avoid_print
                        print('Login result: $result');
                        if (!mounted) return;
                        if (result['success'] == true) {
                          // Use post frame callback to ensure navigation runs after
                          // the current frame and build context is stable.
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
