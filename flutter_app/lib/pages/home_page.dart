import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'auth_page.dart';
import 'dashboard_page.dart';
import 'upload_document_page.dart';
import 'verify_document_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const UploadDocumentPage(),
    const VerifyDocumentPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Blockchain Vault'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => _showAccountDialog(context),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.grid_view), label: 'Vault'),
          NavigationDestination(icon: Icon(Icons.add_moderator), label: 'Secure'),
          NavigationDestination(icon: Icon(Icons.verified_user_outlined), label: 'Verify'),
        ],
      ),
    );
  }

  void _showAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Local Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _item('Username', AuthService.getCurrentUser() ?? 'N/A'),
            const SizedBox(height: 15),
            _item('Blockchain Address', AuthService.getCurrentAddress() ?? 'N/A', isAddress: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await AuthService.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthPage()),
                  (route) => false,
                );
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _item(String label, String value, {bool isAddress = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        SelectableText(
          value,
          style: TextStyle(
            fontSize: isAddress ? 10 : 14,
            fontFamily: isAddress ? 'monospace' : null,
            color: isAddress ? Colors.blue[800] : Colors.black,
          ),
        ),
      ],
    );
  }
}
