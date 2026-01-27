import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/blockchain_service.dart';
import '../services/encryption_service.dart';
import '../models/document.dart';

/// Verify Document Page - Local-First with Hash Search
class VerifyDocumentPage extends StatefulWidget {
  const VerifyDocumentPage({super.key});

  @override
  State<VerifyDocumentPage> createState() => _VerifyDocumentPageState();
}

class _VerifyDocumentPageState extends State<VerifyDocumentPage> {
  final _docIdController = TextEditingController();
  bool _isVerifying = false;
  Map<String, dynamic>? _verificationResult;
  PlatformFile? _fileToVerify;

  @override
  void dispose() {
    _docIdController.dispose();
    super.dispose();
  }

  Future<void> _pickFileToVerify() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'txt', 'doc', 'docx'],
        withData: true,
      );

      if (result != null) {
        setState(() {
          _fileToVerify = result.files.first;
          _verificationResult = null;
        });
      }
    } catch (e) {
      _showSnackBar('Error picking file: $e');
    }
  }

  Future<void> _verifyDocument() async {
    if (_fileToVerify == null || _fileToVerify!.bytes == null) {
      _showSnackBar('Please select the document file to verify');
      return;
    }

    setState(() {
      _isVerifying = true;
      _verificationResult = null;
    });

    try {
      // Step 1: Generate Hash of provided file
      final providedHash = EncryptionService.generateHash(_fileToVerify!.bytes!);
      Document? document;

      // Step 2: Determine lookup method
      final idInput = _docIdController.text.trim();
      if (idInput.isNotEmpty) {
        // Method A: Lookup by ID and compare hash
        final chainResult = await BlockchainService.verifyDocument(idInput);
        if (chainResult['verified']) {
          document = chainResult['document'] as Document;
        }
      } else {
        // Method B: Search for any document matching this hash
        document = await BlockchainService.findByHash(providedHash);
      }

      // Step 3: Final Result Construction
      bool isAuthentic = false;
      String message = "";

      if (document != null) {
        isAuthentic = providedHash == document.originalHash;
        message = isAuthentic 
            ? 'Document is AUTHENTIC! Record found on blockchain.' 
            : 'VERIFICATION FAILED! Record found but hash mismatch.';
      } else {
        message = 'NO RECORD FOUND! This document is not registered on the blockchain.';
      }

      setState(() {
        _isVerifying = false;
        _verificationResult = {
          'verified': isAuthentic,
          'document': document,
          'message': message,
        };
      });
    } catch (e) {
      setState(() => _isVerifying = false);
      _showSnackBar('Verification error: $e');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.verified, size: 80, color: Colors.blue),
          const SizedBox(height: 20),
          const Text(
            'Blockchain Verification',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Pick a file to verify. You can optionally enter the ID if you have it.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 40),

          // File Picker for verification
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: _fileToVerify != null ? Colors.blue : Colors.grey[300]!, width: 2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: InkWell(
              onTap: _pickFileToVerify,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(_fileToVerify != null ? Icons.file_present : Icons.add_circle_outline, 
                      size: 40, color: _fileToVerify != null ? Colors.blue : Colors.grey),
                    const SizedBox(height: 10),
                    Text(
                      _fileToVerify != null ? _fileToVerify!.name : 'Select Document to Verify',
                      style: TextStyle(fontWeight: FontWeight.bold, color: _fileToVerify != null ? Colors.black : Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Optional ID Input
          TextField(
            controller: _docIdController,
            decoration: const InputDecoration(
              labelText: 'Document ID (Optional)',
              hintText: 'Enter if you want specific ID verification',
              prefixIcon: Icon(Icons.fingerprint),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),

          // Verify Button
          ElevatedButton.icon(
            onPressed: (_isVerifying || _fileToVerify == null) ? null : _verifyDocument,
            icon: _isVerifying 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check_circle),
            label: Text(_isVerifying ? 'Verifying...' : 'Verify Authenticity'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

          const SizedBox(height: 30),

          if (_verificationResult != null) _buildResult()
          else if (!_isVerifying) const Center(child: Text('Pick a file to start', style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }

  Widget _buildResult() {
    final success = _verificationResult!['verified'] as bool;
    final doc = _verificationResult!['document'] as Document?;

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: success ? Colors.green[50] : Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(success ? Icons.verified : Icons.error_outline, size: 60, color: success ? Colors.green : Colors.red),
            const SizedBox(height: 15),
            Text(
              success ? 'VERIFIED' : 'NOT VERIFIED',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: success ? Colors.green[700] : Colors.red[700]),
            ),
            const SizedBox(height: 10),
            Text(_verificationResult!['message'], textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w500)),
            
            if (success && doc != null) ...[
              const Divider(height: 30),
              _row('Document Name', doc.name),
              _row('Owner', doc.owner),
              _row('ID', doc.id),
              const SizedBox(height: 10),
              const Text('Verified Hash Record:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              SelectableText(doc.originalHash, style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.blue)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}
