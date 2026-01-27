import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

class LocalUser {
  final String username;
  final String passwordHash;
  final String blockchainAddress;

  LocalUser({
    required this.username,
    required this.passwordHash,
    required this.blockchainAddress,
  });

  Map<String, dynamic> toJson() => {
    'username': username,
    'passwordHash': passwordHash,
    'blockchainAddress': blockchainAddress,
  };

  factory LocalUser.fromJson(Map<String, dynamic> json) => LocalUser(
    username: json['username'],
    passwordHash: json['passwordHash'],
    blockchainAddress: json['blockchainAddress'],
  );
}

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const _usersKey = 'local_users_db';
  static const _sessionKey = 'active_session_username';
  
  static LocalUser? _currentUser;

  /// Register a new user locally
  static Future<bool> register(String username, String password) async {
    final users = await _loadUsers();
    if (users.containsKey(username)) return false;

    // Password Hashing
    final passwordHash = sha256.convert(utf8.encode(password)).toString();
    
    // Assign a mock Blockchain Address (Ethereum style)
    final address = '0x${const Uuid().v4().replaceAll('-', '').substring(0, 40)}';

    final newUser = LocalUser(
      username: username,
      passwordHash: passwordHash,
      blockchainAddress: address,
    );

    users[username] = newUser.toJson();
    await _storage.write(key: _usersKey, value: jsonEncode(users));
    return true;
  }

  /// Login locally
  static Future<bool> login(String username, String password) async {
    final users = await _loadUsers();
    if (!users.containsKey(username)) return false;

    final user = LocalUser.fromJson(users[username]);
    final hashToCompare = sha256.convert(utf8.encode(password)).toString();

    if (user.passwordHash == hashToCompare) {
      _currentUser = user;
      await _storage.write(key: _sessionKey, value: username);
      return true;
    }
    return false;
  }

  /// Logout
  static Future<void> logout() async {
    _currentUser = null;
    await _storage.delete(key: _sessionKey);
  }

  /// Check for active session on app startup
  static Future<bool> checkAuthStatus() async {
    final username = await _storage.read(key: _sessionKey);
    if (username != null) {
      final users = await _loadUsers();
      if (users.containsKey(username)) {
        _currentUser = LocalUser.fromJson(users[username]);
        return true;
      }
    }
    return false;
  }

  static String? getCurrentUser() => _currentUser?.username;
  static String? getCurrentAddress() => _currentUser?.blockchainAddress;

  // Helper to load users from secure storage
  static Future<Map<String, dynamic>> _loadUsers() async {
    final data = await _storage.read(key: _usersKey);
    if (data == null) return {};
    return jsonDecode(data);
  }
}
