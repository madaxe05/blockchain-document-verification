import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isLogin = true;
  bool _isLoading = false;

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showSnackBar('Please fill in all fields');
      return;
    }

    setState(() => _isLoading = true);

    bool success;
    if (_isLogin) {
      success = await AuthService.login(username, password);
    } else {
      success = await AuthService.register(username, password);
      if (success) {
        _isLogin = true;
        _showSnackBar('Registration successful! Please login.', isError: false);
      }
    }

    setState(() => _isLoading = false);

    if (success && _isLogin && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else if (!success && mounted) {
      _showSnackBar(_isLogin ? 'Login failed: Invalid credentials' : 'Registration failed: User may already exist');
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue[900]!, Colors.blue[700]!],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 10,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_person, size: 70, color: Colors.blue),
                      const SizedBox(height: 20),
                      Text(
                        _isLogin ? 'Welcome Back' : 'Create Local Account',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'Secure local-only authentication',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 30),

                      TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.password_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleAuth,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[900],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading 
                              ? const CircularProgressIndicator(color: Colors.white) 
                              : Text(_isLogin ? 'Login' : 'Register'),
                        ),
                      ),
                      
                      TextButton(
                        onPressed: () => setState(() => _isLogin = !_isLogin),
                        child: Text(_isLogin ? 'New user? Register locally' : 'Already have an account? Login'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
