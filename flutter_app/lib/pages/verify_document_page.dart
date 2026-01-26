import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/blockchain_service.dart';
import '../services/encryption_service.dart';
import '../models/document.dart';
import '../utils/helpers.dart';

/// Verify Document Page - Local-First
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
    if (_docIdController.text.trim().isEmpty) {
      _showSnackBar('Please enter Document ID');
      return;
    }
    if (_fileToVerify == null || _fileToVerify!.bytes == null) {
      _showSnackBar('Please select the document file to verify');
      return;
    }

    setState(() {
      _isVerifying = true;
      _verificationResult = null;
    });

    try {
      // 1. Get Metadata from Blockchain
      final chainResult = await BlockchainService.verifyDocument(_docIdController.text.trim());
      
      if (!chainResult['verified']) {
        setState(() {
          _isVerifying = false;
          _verificationResult = chainResult;
        });
        return;
      }

      final document = chainResult['document'] as Document;

      // 2. Generate Hash of provided file
      final providedHash = EncryptionService.generateHash(_fileToVerify!.bytes!);

      // 3. Compare with Blockchain Hash
      final isAuthentic = providedHash == document.originalHash;

      setState(() {
        _isVerifying = false;
        _verificationResult = {
          'verified': isAuthentic,
          'document': document,
          'message': isAuthentic 
              ? 'Document is AUTHENTIC! Hashes match with blockchain record.' 
              : 'VERIFICATION FAILED! Document has been tampered with or is incorrect.',
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
            'Instant Verification',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Upload a document to verify its authenticity against blockchain.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 40),

          // ID Input
          TextField(
            controller: _docIdController,
            decoration: const InputDecoration(
              labelText: 'Enter Document ID',
              prefixIcon: Icon(Icons.fingerprint),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 15),

          // File Picker for verification
          OutlinedButton.icon(
            onPressed: _pickFileToVerify,
            icon: const Icon(Icons.attach_file),
            label: Text(_fileToVerify != null ? 'File: ${_fileToVerify!.name}' : 'Select Document File'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 20),

          // Verify Button
          ElevatedButton.icon(
            onPressed: (_isVerifying || _fileToVerify == null) ? null : _verifyDocument,
            icon: _isVerifying 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.check_circle_outline),
            label: Text(_isVerifying ? 'Checking Blockchain...' : 'Verify Authenticity'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),

          const SizedBox(height: 30),

          if (_verificationResult != null) _buildResult()
          else if (!_isVerifying) const Center(child: Text('Provide ID and File to verify', style: TextStyle(color: Colors.grey))),
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
            Icon(success ? Icons.verified : Icons.error, size: 60, color: success ? Colors.green : Colors.red),
            const SizedBox(height: 15),
            Text(
              success ? 'VERIFIED' : 'FAILED',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: success ? Colors.green[700] : Colors.red[700]),
            ),
            const SizedBox(height: 10),
            Text(_verificationResult!['message'], textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w500)),
            
            if (success && doc != null) ...[
              const Divider(height: 30),
              _row('Document Name', doc.name),
              _row('Owner', doc.owner),
              _row('Block No', doc.blockNumber.toString()),
              const SizedBox(height: 10),
              const Text('Blockchain Hash Record:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
          Flexible(child: Text(value, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}
