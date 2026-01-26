import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Authentication Service - Handles user login, registration, and session using Firebase Auth
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Login user with email and password
  static Future<bool> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Login Error: $e');
      }
      return false;
    }
  }

  /// Register new user
  static Future<bool> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update display name
      await userCredential.user?.updateDisplayName(name);
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Registration Error: $e');
      }
      return false;
    }
  }

  /// Logout current user
  static Future<void> logout() async {
    await _auth.signOut();
  }

  /// Get current logged-in user name
  static String? getCurrentUser() {
    return _auth.currentUser?.displayName ?? _auth.currentUser?.email?.split('@')[0];
  }

  /// Get current logged-in user email
  static String? getCurrentUserEmail() {
    return _auth.currentUser?.email;
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
     // Reload user to get latest status (e.g. if disabled)
    await _auth.currentUser?.reload();
    return _auth.currentUser != null;
  }

  /// Get current user object
  static User? get user => _auth.currentUser;
}
