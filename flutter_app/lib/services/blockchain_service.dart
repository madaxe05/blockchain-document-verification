import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import '../models/document.dart';
import 'auth_service.dart';

/// Blockchain Service - Simulates blockchain storage and verification
class BlockchainService {
  // Simulated blockchain storage (in-memory)
  static final Map<String, Document> _blockchain = {};
  static int _blockCount = 0;

  /// Encrypt document using XOR encryption (simple demo encryption)
  static Uint8List _encryptDocument(Uint8List data) {
    // In a real app, use proper encryption (AES, etc.)
    final key = 'SecureKey123'.codeUnits;
    final encrypted = Uint8List(data.length);

    for (int i = 0; i < data.length; i++) {
      encrypted[i] = data[i] ^ key[i % key.length];
    }

    return encrypted;
  }

  /// Generate SHA-256 hash of document
  static String _generateHash(Uint8List data) {
    final digest = sha256.convert(data);
    return digest.toString();
  }

  /// Store document on blockchain
  /// Returns the stored Document object with blockchain details
  static Future<Document> storeDocument({
    required String fileName,
    required String fileType,
    required Uint8List fileData,
  }) async {
    // Simulate network delay (blockchain transaction time)
    await Future.delayed(const Duration(seconds: 2));

    // Step 1: Encrypt the document
    final encryptedData = _encryptDocument(fileData);

    // Step 2: Generate hash of original document (for verification)
    final hash = _generateHash(fileData);

    // Step 3: Generate unique document ID
    final docId = 'DOC-${DateTime.now().millisecondsSinceEpoch}';

    // Step 4: Create document record
    final document = Document(
      id: docId,
      name: fileName,
      type: fileType,
      owner: AuthService.getCurrentUser() ?? 'Unknown User',
      ownerEmail: AuthService.getCurrentUserEmail() ?? 'unknown@email.com',
      uploadDate: DateTime.now(),
      hash: hash,
      blockNumber: ++_blockCount,
      encryptedData: encryptedData,
      fileSize: fileData.length,
    );

    // Step 5: Store on "blockchain"
    _blockchain[docId] = document;

    return document;
  }

  /// Verify document by Document ID
  /// Returns verification result with document details
  static Future<Map<String, dynamic>> verifyDocument(String docId) async {
    // Simulate blockchain query delay
    await Future.delayed(const Duration(seconds: 1));

    final document = _blockchain[docId];

    if (document == null) {
      return {'verified': false, 'message': 'Document not found in blockchain'};
    }

    return {
      'verified': true,
      'document': document,
      'message': 'Document verified successfully',
    };
  }

  /// Get all documents for current user
  static Future<List<Document>> getUserDocuments() async { // Changed to Future
    final currentUserEmail = AuthService.getCurrentUserEmail();
    if (currentUserEmail == null) return [];
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    final docs = _blockchain.values
        .where((doc) => doc.ownerEmail == currentUserEmail)
        .toList();
      
    docs.sort((a, b) => b.uploadDate.compareTo(a.uploadDate));
    return docs;
  }

  /// Get specific document by ID
  static Document? getDocument(String docId) {
    return _blockchain[docId];
  }
}
