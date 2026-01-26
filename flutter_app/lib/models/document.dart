/// Document Model - Represents a document stored on blockchain
class Document {
  final String id; // Unique document ID
  final String name; // Document file name
  final String type; // File type/extension
  final String owner; // Owner name
  final String ownerEmail; // Owner email
  final DateTime uploadDate; // When document was uploaded
  final String originalHash; // SHA-256 hash of original document
  final String encryptedDataHash; // SHA-256 hash of encrypted document
  final String storageUrl; // URL of encrypted file in Firebase Storage
  final int blockNumber; // Blockchain block number
  final int fileSize; // File size in bytes

  Document({
    required this.id,
    required this.name,
    required this.type,
    required this.owner,
    required this.ownerEmail,
    required this.uploadDate,
    required this.originalHash,
    required this.encryptedDataHash,
    required this.storageUrl,
    required this.blockNumber,
    required this.fileSize,
  });
}
