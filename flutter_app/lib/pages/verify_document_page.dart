import 'package:flutter/material.dart';
import '../services/blockchain_service.dart';
import '../models/document.dart';
import '../utils/helpers.dart';

/// Verify Document Page - Verify document authenticity
class VerifyDocumentPage extends StatefulWidget {
  const VerifyDocumentPage({super.key});

  @override
  State<VerifyDocumentPage> createState() => _VerifyDocumentPageState();
}

class _VerifyDocumentPageState extends State<VerifyDocumentPage> {
  final _docIdController = TextEditingController();
  bool _isVerifying = false;
  Map<String, dynamic>? _verificationResult;

  @override
  void dispose() {
    _docIdController.dispose();
    super.dispose();
  }

  /// Verify document by ID
  Future<void> _verifyDocument() async {
    if (_docIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a document ID')),
      );
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Verification error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          const Icon(Icons.verified_user, size: 80, color: Colors.blue),
          const SizedBox(height: 20),
          const Text(
            'Verify Document',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Check document authenticity on the blockchain',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 40),

          // Document ID input field
          TextField(
            controller: _docIdController,
            decoration: const InputDecoration(
              labelText: 'Document ID',
              hintText: 'Enter document ID (e.g., DOC-1234567890)',
              prefixIcon: Icon(Icons.fingerprint),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),

          // Verify button
          ElevatedButton.icon(
            onPressed: _isVerifying ? null : _verifyDocument,
            icon:
                _isVerifying
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Icon(Icons.search),
            label: Text(_isVerifying ? 'Verifying...' : 'Verify on Blockchain'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 30),

          // Verification result
          if (_verificationResult != null)
            _buildVerificationResult()
          else if (!_isVerifying)
            const Center(
              child: Text(
                'Enter a document ID to verify',
                style: TextStyle(color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  /// Build verification result widget
  Widget _buildVerificationResult() {
    final isValid = _verificationResult!['verified'] as bool;
    final document = _verificationResult!['document'] as Document?;

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Verification icon
            Icon(
              isValid ? Icons.check_circle : Icons.cancel,
              size: 60,
              color: isValid ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 15),

            // Verification status
            Text(
              isValid ? 'Document Verified!' : 'Document Not Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isValid ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 10),

            // Verification message
            Text(
              _verificationResult!['message'],
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),

            // Document details (if verified)
            if (isValid && document != null) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              _buildResultRow('Document Name', document.name),
              _buildResultRow('File Type', document.type),
              _buildResultRow('Owner', document.owner),
              _buildResultRow(
                'Upload Date',
                Helpers.formatDate(document.uploadDate),
              ),
              _buildResultRow('Block Number', document.blockNumber.toString()),
              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 10),
              const Text(
                'Blockchain Hash:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(
                document.hash,
                style: const TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build result row widget
  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
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
