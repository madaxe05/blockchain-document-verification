import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class EncryptionService {
  static const _storage = FlutterSecureStorage();
  static const _keyAlias = 'doc_encryption_key';

  /// Get or create a 32-byte encryption key
  static Future<encrypt.Key> _getEncryptionKey() async {
    String? storedKey = await _storage.read(key: _keyAlias);
    if (storedKey == null) {
      final newKey = encrypt.Key.fromSecureRandom(32);
      await _storage.write(key: _keyAlias, value: base64Encode(newKey.bytes));
      return newKey;
    }
    return encrypt.Key.fromBase64(storedKey);
  }

  /// Encrypt data using AES-256-CBC
  static Future<Uint8List> encryptData(Uint8List data) async {
    final key = await _getEncryptionKey();
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final encrypted = encrypter.encryptBytes(data, iv: iv);
    
    // Combine IV and Encrypted Data: [16 bytes IV][encrypted bytes]
    final result = BytesBuilder();
    result.add(iv.bytes);
    result.add(encrypted.bytes);
    return result.toBytes();
  }

  /// Decrypt data using AES-256-CBC
  static Future<Uint8List> decryptData(Uint8List encryptedWithIv) async {
    final key = await _getEncryptionKey();
    
    // Extract IV (first 16 bytes)
    final iv = encrypt.IV(encryptedWithIv.sublist(0, 16));
    final encryptedData = encryptedWithIv.sublist(16);
    
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final decrypted = encrypter.decryptBytes(encrypt.Encrypted(encryptedData), iv: iv);
    
    return Uint8List.fromList(decrypted);
  }

  /// Generate SHA-256 hash
  static String generateHash(Uint8List data) {
    return sha256.convert(data).toString();
  }
}
