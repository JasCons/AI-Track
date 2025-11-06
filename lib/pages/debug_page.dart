import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  User? _user;
  String? _token;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final user = FirebaseAuth.instance.currentUser;
    String? token;
    if (user != null) token = await user.getIdToken();
    setState(() {
      _user = user;
      _token = token;
      _loading = false;
    });
  }

  Future<void> _refreshToken() async {
    setState(() => _loading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final token = await user.getIdToken(true);
      setState(() => _token = token);
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Firebase user: ${_user?.uid ?? 'null'}'),
                  const SizedBox(height: 8),
                  Text('Email: ${_user?.email ?? 'null'}'),
                  const SizedBox(height: 8),
                  Text(
                    'Token (first 200 chars): ${_token == null ? 'null' : (_token!.length > 200 ? '${_token!.substring(0, 200)}...' : _token)}',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _load,
                        child: const Text('Refresh'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _refreshToken,
                        child: const Text('Force refresh token'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          await AuthService().logout();
                          await _load();
                        },
                        child: const Text('Sign out'),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
