/// Document Model - Represents a document stored on blockchain
class Document {
  final String id; // Unique document ID
  final String name; // Document file name
  final String type; // File type/extension
  final String owner; // Owner name
  final String ownerAddress; // Owner blockchain address
  final DateTime uploadDate; // When document was uploaded
  final String originalHash; // SHA-256 hash of original document
  final String localPath; // Local path to the encrypted file
  final int blockNumber; // Blockchain block number
  final int fileSize; // File size in bytes

  Document({
    required this.id,
    required this.name,
    required this.type,
    required this.owner,
    required this.ownerAddress,
    required this.uploadDate,
    required this.originalHash,
    required this.localPath,
    required this.blockNumber,
    required this.fileSize,
  });
}
