import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../utils/helpers.dart';
import '../services/encryption_service.dart';
import '../services/local_storage_service.dart';
import '../services/blockchain_service.dart';

/// Upload Document Page - Local-First Architecture
class UploadDocumentPage extends StatefulWidget {
  const UploadDocumentPage({super.key});

  @override
  State<UploadDocumentPage> createState() => _UploadDocumentPageState();
}

class _UploadDocumentPageState extends State<UploadDocumentPage> {
  bool _isUploading = false;
  PlatformFile? _selectedFile;
  String _statusMessage = "";

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'txt', 'doc', 'docx'],
        withData: true,
      );

      if (result != null) {
        setState(() {
          _selectedFile = result.files.first;
          _statusMessage = "File selected: ${_selectedFile!.name}";
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

  Future<void> _processUpload() async {
    if (_selectedFile == null || _selectedFile!.bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a valid file first')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _statusMessage = "Starting local-first process...";
    });

    try {
      final originalBytes = _selectedFile!.bytes!;
      
      // Step 1: Generate Original Hash (Authenticity Fingerprint)
      setState(() => _statusMessage = "Generating SHA-256 hash...");
      final originalHash = EncryptionService.generateHash(originalBytes);

      // Step 2: Encrypt File Locally (Privacy)
      setState(() => _statusMessage = "Encrypting file (AES-256)...");
      final encryptedBytes = await EncryptionService.encryptData(originalBytes);

      // Step 3: Save Encrypted File to Device
      setState(() => _statusMessage = "Saving secured file to device...");
      final localPath = await LocalStorageService.saveEncryptedFile(
        fileName: _selectedFile!.name,
        encryptedData: encryptedBytes,
      );

      // Step 4: Secure Metadata on Blockchain
      setState(() => _statusMessage = "Registering proof on blockchain...");
      final doc = await BlockchainService.storeDocument(
        fileName: _selectedFile!.name,
        fileType: _selectedFile!.extension ?? 'unknown',
        originalHash: originalHash,
        localPath: localPath,
        fileSize: originalBytes.length,
      );

      if (!mounted) return;

      setState(() {
        _isUploading = false;
        _selectedFile = null;
        _statusMessage = "";
      });

      _showSuccessDialog(doc.id, localPath);
    } catch (e) {
      setState(() {
        _isUploading = false;
        _statusMessage = "Error: $e";
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showSuccessDialog(String docId, String path) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Secured Locally'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: Icon(Icons.privacy_tip, color: Colors.green, size: 60)),
            const SizedBox(height: 15),
            const Text('✔ Encrypted on device'),
            const Text('✔ Saved to local storage'),
            const Text('✔ Hash stored on blockchain'),
            const Divider(),
            Text('Document ID: $docId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            const SizedBox(height: 5),
            Text('Saved at: $path', style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
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
          const Icon(Icons.home_max, size: 80, color: Colors.blue),
          const SizedBox(height: 20),
          const Text(
            'Local-First Upload',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Keep your files private. Only hashes go on blockchain.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 40),

          if (_selectedFile != null) _buildFilePreview() else _buildFilePlaceholder(),

          if (_statusMessage.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.blue[700], fontSize: 11),
            ),
          ],

          const SizedBox(height: 30),

          ElevatedButton.icon(
            onPressed: _isUploading ? null : _pickFile,
            icon: const Icon(Icons.file_upload),
            label: const Text('Pick Document'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: Colors.grey[800],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 15),

          ElevatedButton.icon(
            onPressed: (_isUploading || _selectedFile == null) ? null : _processUpload,
            icon: _isUploading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.lock),
            label: Text(_isUploading ? 'Securing...' : 'Secure & Register'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePreview() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Helpers.getFileIcon(_selectedFile!.extension ?? ''), size: 60, color: Colors.blue[700]),
            const SizedBox(height: 15),
            Text(_selectedFile!.name, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 5),
            Text(Helpers.formatFileSize(_selectedFile!.size), style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePlaceholder() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        border: Border.all(color: Colors.blue.withOpacity(0.2), width: 2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          Icon(Icons.add_to_home_screen, size: 60, color: Colors.grey),
          SizedBox(height: 15),
          Text('Select a document to secure', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
