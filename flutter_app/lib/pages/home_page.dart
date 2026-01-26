import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'auth_page.dart';
import 'dashboard_page.dart';
import 'upload_document_page.dart';
import 'verify_document_page.dart';

/// Home Page - Main navigation container
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // List of pages for bottom navigation
  final List<Widget> _pages = [
    const DashboardPage(),
    const UploadDocumentPage(),
    const VerifyDocumentPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Verification'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          // User account icon
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              _showAccountDialog(context);
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(icon: Icon(Icons.upload_file), label: 'Upload'),
          NavigationDestination(icon: Icon(Icons.verified), label: 'Verify'),
        ],
      ),
    );
  }

  /// Show account dialog with user info and logout option
  void _showAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Account'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: ${AuthService.getCurrentUser() ?? "User"}'),
                const SizedBox(height: 8),
                Text('Email: ${AuthService.getCurrentUserEmail() ?? "No Email"}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await AuthService.logout();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const AuthPage()),
                      (route) => false,
                    );
                  }
                },
                child: const Text('Logout'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }
}
