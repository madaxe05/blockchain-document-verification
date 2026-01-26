import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../services/blockchain_service.dart';
import '../services/storage_service.dart';
import '../services/encryption_service.dart';
import '../models/document.dart';

/// Verify Document Page - Production Realistic Flow
class VerifyDocumentPage extends StatefulWidget {
  const VerifyDocumentPage({super.key});

  @override
  State<VerifyDocumentPage> createState() => _VerifyDocumentPageState();
}

class _VerifyDocumentPageState extends State<VerifyDocumentPage> {
  final _docIdController = TextEditingController();
  bool _isVerifying = false;
  bool _isDownloading = false;
  Map<String, dynamic>? _verificationResult;

  @override
  void dispose() {
    _docIdController.dispose();
    super.dispose();
  }

  /// Verify document by ID against Blockchain
  Future<void> _verifyDocument() async {
    if (_docIdController.text.trim().isEmpty) {
      _showSnackBar('Please enter a document ID');
      return;
    }

    setState(() {
      _isVerifying = true;
      _verificationResult = null;
    });

    try {
      final result = await BlockchainService.verifyDocument(
        _docIdController.text.trim(),
      );

      setState(() {
        _isVerifying = false;
        _verificationResult = result;
      });
    } catch (e) {
      setState(() => _isVerifying = false);
      _showSnackBar('Verification error: $e');
    }
  }

  /// Download and Decrypt the document
  Future<void> _downloadAndDecrypt(Document doc) async {
    setState(() => _isDownloading = true);

    try {
      // 1. Download encrypted file from Firebase
      final encryptedBytes = await StorageService.downloadFile(doc.storageUrl);

      // 2. Verify Encrypted Hash
      final downloadedEncryptedHash = EncryptionService.generateHash(
        encryptedBytes,
      );
      if (downloadedEncryptedHash != doc.encryptedDataHash) {
        throw Exception(
          "Stored file integrity check failed! Encrypted hashes do not match.",
        );
      }

      // 3. Decrypt file
      final decryptedBytes = await EncryptionService.decryptData(
        encryptedBytes,
      );

      // 4. Verify Original Hash
      final decryptedHash = EncryptionService.generateHash(decryptedBytes);
      if (decryptedHash != doc.originalHash) {
        throw Exception(
          "Original document integrity check failed! Decrypted hashes do not match.",
        );
      }

      // 5. Save to temporary file and open
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/${doc.name}');
      await file.writeAsBytes(decryptedBytes);

      setState(() => _isDownloading = false);

      _showSnackBar(
        "Document decrypted and verified successfully!",
        isError: false,
      );

      // Open the file
      await OpenFile.open(file.path);
    } catch (e) {
      setState(() => _isDownloading = false);
      _showSnackBar("Download/Decryption failed: $e");
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.verified_user, size: 80, color: Colors.blue),
          const SizedBox(height: 20),
          const Text(
            'Production Verification',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Check authenticity and decrypt stored documents',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 40),

          TextField(
            controller: _docIdController,
            decoration: const InputDecoration(
              labelText: 'Document ID',
              hintText: 'e.g. DOC-1234567890',
              prefixIcon: Icon(Icons.fingerprint),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: _isVerifying ? null : _verifyDocument,
            icon: _isVerifying
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.search),
            label: Text(
              _isVerifying ? 'Querying Blockchain...' : 'Verify on Blockchain',
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 30),

          if (_verificationResult != null)
            _buildVerificationResult()
          else if (!_isVerifying)
            const Center(
              child: Text(
                'Enter a document ID to start',
                style: TextStyle(color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVerificationResult() {
    final isValid = _verificationResult!['verified'] as bool;
    final document = _verificationResult!['document'] as Document?;

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              isValid ? Icons.check_circle : Icons.cancel,
              size: 60,
              color: isValid ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 15),
            Text(
              isValid ? 'Document Verified' : 'No Record Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isValid ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _verificationResult!['message'],
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),

            if (isValid && document != null) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              _buildResultRow('Name', document.name),
              _buildResultRow('Type', document.type),
              _buildResultRow('Owner', document.owner),
              _buildResultRow('Block', document.blockNumber.toString()),
              const SizedBox(height: 20),

              const Text(
                'Original Hash:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 4),
              SelectableText(
                document.originalHash,
                style: const TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  color: Colors.blue,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isDownloading
                      ? null
                      : () => _downloadAndDecrypt(document),
                  icon: _isDownloading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download_for_offline),
                  label: Text(
                    _isDownloading
                        ? 'Decrypting...'
                        : 'Verify Content & Decrypt',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(12),
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
