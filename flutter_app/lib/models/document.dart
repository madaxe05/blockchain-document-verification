import 'dart:typed_data';

/// Document Model - Represents a document stored on blockchain
class Document {
  final String id; // Unique document ID
  final String name; // Document file name
  final String type; // File type/extension
  final String owner; // Owner name
  final String ownerEmail; // Owner email
  final DateTime uploadDate; // When document was uploaded
  final String hash; // SHA-256 hash for verification
  final int blockNumber; // Blockchain block number
  final Uint8List encryptedData; // Encrypted document data
  final int fileSize; // File size in bytes

  Document({
    required this.id,
    required this.name,
    required this.type,
    required this.owner,
    required this.ownerEmail,
    required this.uploadDate,
    required this.hash,
    required this.blockNumber,
    required this.encryptedData,
    required this.fileSize,
  });
}
