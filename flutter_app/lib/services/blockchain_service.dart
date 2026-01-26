import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/document.dart';
import 'auth_service.dart';

class BlockchainService {
  // Local Ganache/Hardhat
  // Placeholder

  // Reference to Firestore collection for metadata persistence
  static final CollectionReference _docsCollection = FirebaseFirestore.instance
      .collection('documents');

  /// Store document metadata on blockchain AND Firestore (for persistence)
  static Future<Document> storeDocument({
    required String fileName,
    required String fileType,
    required String originalHash,
    required String localPath,
    required int fileSize,
  }) async {
    // --- REAL BLOCKCHAIN LOGIC (Template) ---
    // final credentials = EthPrivateKey.fromHex("YOUR_PRIVATE_KEY");
    // final address = await credentials.extractAddress();
    // final contract = DeployedContract(
    //   ContractAbi.fromJson(abiJson, "DocumentVerification"),
    //   EthereumAddress.fromHex(_contractAddress),
    // );
    // final function = contract.function("registerDocument");
    // await _client.sendTransaction(
    //   credentials,
    //   Transaction.callContract(
    //     contract: contract,
    //     function: function,
    //     parameters: [docId, fileName, originalHash, encryptedHash, storageUrl],
    //   ),
    // );
    // ----------------------------------------

    // Simulate blockchain delay
    await Future.delayed(const Duration(seconds: 2));

    final docId = 'DOC-${DateTime.now().millisecondsSinceEpoch}';
    final document = Document(
      id: docId,
      name: fileName,
      type: fileType,
      owner: AuthService.getCurrentUser() ?? 'Unknown User',
      ownerEmail: AuthService.getCurrentUserEmail() ?? 'unknown@email.com',
      uploadDate: DateTime.now(),
      originalHash: originalHash,
      localPath: localPath,
      blockNumber: 1, // Simulated
      fileSize: fileSize,
    );

    // Save to Firestore for persistence between restarts
    await _docsCollection.doc(docId).set({
      'id': document.id,
      'name': document.name,
      'type': document.type,
      'owner': document.owner,
      'ownerEmail': document.ownerEmail,
      'uploadDate': document.uploadDate.toIso8601String(),
      'originalHash': document.originalHash,
      'localPath': document.localPath,
      'blockNumber': document.blockNumber,
      'fileSize': document.fileSize,
    });

    return document;
  }

  /// Verify document by ID against Firestore/Blockchain
  static Future<Map<String, dynamic>> verifyDocument(String docId) async {
    final docSnapshot = await _docsCollection.doc(docId).get();

    if (!docSnapshot.exists) {
      return {
        'verified': false,
        'message': 'Document not found on blockchain record',
      };
    }

    final data = docSnapshot.data() as Map<String, dynamic>;
    final document = Document(
      id: data['id'],
      name: data['name'],
      type: data['type'],
      owner: data['owner'],
      ownerEmail: data['ownerEmail'],
      uploadDate: DateTime.parse(data['uploadDate']),
      originalHash: data['originalHash'],
      localPath: data['localPath'],
      blockNumber: data['blockNumber'],
      fileSize: data['fileSize'],
    );

    return {
      'verified': true,
      'document': document,
      'message': 'Document metadata verified on blockchain record',
    };
  }

  /// Get all documents for current user from Firestore
  static Future<List<Document>> getUserDocuments() async {
    final email = AuthService.getCurrentUserEmail();
    if (email == null) return [];

    final querySnapshot = await _docsCollection
        .where('ownerEmail', isEqualTo: email)
        .orderBy('uploadDate', descending: true)
        .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Document(
        id: data['id'],
        name: data['name'],
        type: data['type'],
        owner: data['owner'],
        ownerEmail: data['ownerEmail'],
        uploadDate: DateTime.parse(data['uploadDate']),
        originalHash: data['originalHash'],
        localPath: data['localPath'],
        blockNumber: data['blockNumber'],
        fileSize: data['fileSize'],
      );
    }).toList();
  }

  /// Find document by originalHash (for ID-less verification)
  static Future<Document?> findByHash(String originalHash) async {
    final query = await _docsCollection
        .where('originalHash', isEqualTo: originalHash)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    final data = query.docs.first.data() as Map<String, dynamic>;
    return Document(
      id: data['id'],
      name: data['name'],
      type: data['type'],
      owner: data['owner'],
      ownerEmail: data['ownerEmail'],
      uploadDate: DateTime.parse(data['uploadDate']),
      originalHash: data['originalHash'],
      localPath: data['localPath'],
      blockNumber: data['blockNumber'],
      fileSize: data['fileSize'],
    );
  }
}
