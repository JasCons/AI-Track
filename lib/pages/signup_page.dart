import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _isSignUpMode = true;
  String _role = 'passenger';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
    });

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
    });

    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    try {
      print('SignUpPage: Submitting with role: $_role, isSignUpMode: $_isSignUpMode');
      final result = _isSignUpMode
          ? await AuthService().register(email, password, role: _role)
          : await AuthService().login(email, password);
      print('SignUpPage: Result: $result');
      
      if (result['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isSignUpMode ? 'Account created successfully' : 'Login successful')),
        );
        Navigator.of(context).pop();
      } else {
        setState(() {
          _error = result['error'] ?? (_isSignUpMode ? 'Registration failed' : 'Login failed');
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isSignUpMode ? 'Sign Up' : 'Log In')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isSignUpMode ? 'Create Account' : 'Welcome Back',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter email'
                      : null,
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter password'
                      : null,
                ),

                if (_isSignUpMode) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _role,
                    items: const [
                      DropdownMenuItem(value: 'passenger', child: Text('Passenger')),
                      DropdownMenuItem(value: 'operator', child: Text('Operator')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      print('SignUpPage: Role changed to: $v');
                      setState(() => _role = v ?? 'passenger');
                    },
                  ),
                ],

                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      child: _loading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_isSignUpMode ? 'Sign Up' : 'Log In'),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Center(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _isSignUpMode = !_isSignUpMode;
                        _error = null;
                      });
                    },
                    child: Text(
                      _isSignUpMode
                          ? 'Already have an account? Log In'
                          : 'Don\'t have an account? Sign Up',
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
