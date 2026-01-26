import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import '../models/document.dart';
import 'auth_service.dart';

class BlockchainService {
  static const String _rpcUrl = "http://10.0.2.2:8545"; // Local Ganache/Hardhat
  static const String _contractAddress = "0x0000000000000000000000000000000000000000"; // Placeholder

  final Web3Client _client = Web3Client(_rpcUrl, Client());
  
  // Simulated blockchain storage for when Web3 is not available
  static final Map<String, Document> _mockBlockchain = {};
  static int _blockCount = 0;

  /// Store document metadata on blockchain
  static Future<Document> storeDocument({
    required String fileName,
    required String fileType,
    required String originalHash,
    required String encryptedHash,
    required String storageUrl,
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

    // Step 2: Simulate transaction
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
      encryptedDataHash: encryptedHash,
      storageUrl: storageUrl,
      blockNumber: ++_blockCount,
      fileSize: fileSize,
    );

    _mockBlockchain[docId] = document;
    return document;
  }

  /// Verify document by ID
  static Future<Map<String, dynamic>> verifyDocument(String docId) async {
    await Future.delayed(const Duration(seconds: 1));
    final document = _mockBlockchain[docId];

    if (document == null) {
      return {'verified': false, 'message': 'Document not found on blockchain'};
    }

    return {
      'verified': true,
      'document': document,
      'message': 'Document metadata verified on blockchain',
    };
  }

  /// Get all documents for current user
  static Future<List<Document>> getUserDocuments() async {
    final email = AuthService.getCurrentUserEmail();
    if (email == null) return [];
    
    await Future.delayed(const Duration(milliseconds: 500));
    final docs = _mockBlockchain.values
        .where((doc) => doc.ownerEmail == email)
        .toList();
      
    docs.sort((a, b) => b.uploadDate.compareTo(a.uploadDate));
    return docs;
  }
}
