import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LogoutPage extends StatefulWidget {
  const LogoutPage({super.key});

  @override
  State<LogoutPage> createState() => _LogoutPageState();
}

class _LogoutPageState extends State<LogoutPage> {
  bool _loading = false;

  Future<void> _doLogout() async {
    setState(() => _loading = true);
    final auth = AuthService();
    await auth.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF98FB98),
      appBar: AppBar(
        title: const Text('Log Out'),
        backgroundColor: const Color(0xFF98FB98),
        elevation: 0,
      ),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _doLogout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Log Out and Exit'),
              ),
      ),
    );
  }
}
