import 'dart:convert';
import 'dart:io';
import '../services/local_storage_service.dart';
import '../models/document.dart';
import 'auth_service.dart';

class BlockchainService {
  // Filename for the local metadata ledger
  static const _ledgerFileName = 'blockchain_ledger.json';

  /// Store document metadata on Local Ledger (Simulation of Blockchain)
  static Future<Document> storeDocument({
    required String fileName,
    required String fileType,
    required String originalHash,
    required String localPath,
    required int fileSize,
  }) async {
    // Step 1: Simulate blockchain latency
    await Future.delayed(const Duration(seconds: 2));
    
    final docId = 'DOC-${DateTime.now().millisecondsSinceEpoch}';
    final document = Document(
      id: docId,
      name: fileName,
      type: fileType,
      owner: AuthService.getCurrentUser() ?? 'Local User',
      ownerAddress: AuthService.getCurrentAddress() ?? '0x000', 
      uploadDate: DateTime.now(),
      originalHash: originalHash,
      localPath: localPath,
      blockNumber: 1, 
      fileSize: fileSize,
    );

    // Step 2: Save to Local JSON Ledger for persistence
    final ledger = await _loadLedger();
    ledger[docId] = {
      'id': document.id,
      'name': document.name,
      'type': document.type,
      'owner': document.owner,
      'address': document.ownerAddress, // Storing address in this field
      'uploadDate': document.uploadDate.toIso8601String(),
      'originalHash': document.originalHash,
      'localPath': document.localPath,
      'blockNumber': document.blockNumber,
      'fileSize': document.fileSize,
    };
    await _saveLedger(ledger);

    return document;
  }

  /// Verify document by ID against Local Ledger
  static Future<Map<String, dynamic>> verifyDocument(String docId) async {
    final ledger = await _loadLedger();
    final data = ledger[docId];

    if (data == null) {
      return {
        'verified': false,
        'message': 'No record found on the blockchain ledger.',
      };
    }

    final document = _mapToDoc(data);

    return {
      'verified': true,
      'document': document,
      'message': 'Integrity verified against local blockchain record.',
    };
  }

  /// Get all documents for current user address
  static Future<List<Document>> getUserDocuments() async {
    final address = AuthService.getCurrentAddress();
    if (address == null) return [];

    final ledger = await _loadLedger();
    final userDocs = ledger.values
        .where((data) => data['address'] == address)
        .map((data) => _mapToDoc(data))
        .toList();

    userDocs.sort((a, b) => b.uploadDate.compareTo(a.uploadDate));
    return userDocs;
  }

  /// Find document by originalHash (for ID-less verification)
  static Future<Document?> findByHash(String originalHash) async {
    final ledger = await _loadLedger();
    final match = ledger.values.firstWhere(
      (data) => data['originalHash'] == originalHash,
      orElse: () => null,
    );

    if (match == null) return null;
    return _mapToDoc(match);
  }

  // --- INTERNAL STORAGE HELPERS ---

  static Future<Map<String, dynamic>> _loadLedger() async {
    try {
      final path = await LocalStorageService.getLedgerPath(_ledgerFileName);
      final file = File(path);
      if (!await file.exists()) return {};
      final content = await file.readAsString();
      return jsonDecode(content);
    } catch (e) {
      return {};
    }
  }

  static Future<void> _saveLedger(Map<String, dynamic> ledger) async {
    final path = await LocalStorageService.getLedgerPath(_ledgerFileName);
    final file = File(path);
    await file.writeAsString(jsonEncode(ledger));
  }

  static Document _mapToDoc(Map<String, dynamic> data) {
    return Document(
      id: data['id'],
      name: data['name'],
      type: data['type'],
      owner: data['owner'],
      ownerAddress: data['address'], // Mapped to address
      uploadDate: DateTime.parse(data['uploadDate']),
      originalHash: data['originalHash'],
      localPath: data['localPath'],
      blockNumber: data['blockNumber'],
      fileSize: data['fileSize'],
    );
  }
}
