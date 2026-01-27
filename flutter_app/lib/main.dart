import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'pages/auth_page.dart';
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Check local auth status (Login Persistence)
  final isLoggedIn = await AuthService.checkAuthStatus();

  runApp(BlockchainDocumentApp(isLoggedIn: isLoggedIn));
}

class BlockchainDocumentApp extends StatelessWidget {
  final bool isLoggedIn;
  const BlockchainDocumentApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blockchain Document Verification',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          primary: Colors.blue[900],
          secondary: Colors.blue[700],
        ),
        useMaterial3: true,
      ),
      // Use local session for home screen
      home: isLoggedIn ? const HomePage() : const AuthPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
