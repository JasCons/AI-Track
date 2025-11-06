import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      print('MenuPage: Current user: ${user?.uid} / ${user?.email}');
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        print('MenuPage: Document exists: ${doc.exists}');
        if (doc.exists) {
          final data = doc.data();
          print('MenuPage: Document data: $data');
          final role = data?['role'] as String?;
          print('MenuPage: Loaded user role: $role for uid: ${user.uid}');
          if (mounted) {
            setState(() {
              _userRole = role ?? 'passenger';
            });
          }
        } else {
          print('MenuPage: User document does not exist for uid: ${user.uid}');
          if (mounted) {
            setState(() {
              _userRole = 'passenger';
            });
          }
        }
      }
    } catch (e, st) {
      print('MenuPage: Error loading role: $e');
      print('MenuPage: Stack trace: $st');
      if (mounted) {
        setState(() {
          _userRole = 'passenger';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF98FB98),
      appBar: AppBar(
        title: const Text('Menu'),
        backgroundColor: const Color(0xFF98FB98),
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black87),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
          ),
        ),
      ),
      drawer: Drawer(
        child: Container(
          color: const Color(0xFF98FB98),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 16,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: const Color(0xFF98FB98),
                      child: const Icon(
                        Icons.account_circle,
                        size: 56,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'AI-TRACK',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userRole != null ? 'Role: $_userRole' : 'Loading...',
                      style: const TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _loadUserRole,
                      child: const Text('Refresh Role', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const Divider(),
              _MenuDrawerItem(
                icon: Icons.map,
                label: 'Transit Track',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/transit-track');
                },
              ),
              _MenuDrawerItem(
                icon: Icons.app_registration,
                label: 'Transit Register',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/transit-register');
                },
              ),
              _MenuDrawerItem(
                icon: Icons.report,
                label: 'Report',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/report');
                },
              ),
              _MenuDrawerItem(
                icon: Icons.add_location,
                label: 'Add Test Routes',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/add-test-route');
                },
              ),
              _MenuDrawerItem(
                icon: Icons.bug_report,
                label: 'Debug Routes',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/debug-routes');
                },
              ),
              _MenuDrawerItem(
                icon: Icons.flash_on,
                label: 'Quick Add Route',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/quick-add');
                },
              ),
              _MenuDrawerItem(
                icon: Icons.logout,
                label: 'Log Out',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/logout');
                },
              ),
            ],
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.menu, size: 80, color: Colors.green),
            SizedBox(height: 24),
            Text(
              'Select an option from the menu',
              style: TextStyle(fontSize: 20, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}

// Modern menu drawer item widget
class _MenuDrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuDrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ListTile(
          leading: Icon(icon, color: Colors.green, size: 28),
          title: Text(
            label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          onTap: onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios,
            size: 18,
            color: Colors.black26,
          ),
        ),
      ),
    );
  }
}
