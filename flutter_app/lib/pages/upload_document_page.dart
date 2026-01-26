import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../utils/helpers.dart';
import '../services/encryption_service.dart';
import '../services/storage_service.dart';
import '../services/blockchain_service.dart';

/// Upload Document Page - Production Realistic Flow
class UploadDocumentPage extends StatefulWidget {
  const UploadDocumentPage({super.key});

  @override
  State<UploadDocumentPage> createState() => _UploadDocumentPageState();
}

class _UploadDocumentPageState extends State<UploadDocumentPage> {
  bool _isUploading = false;
  PlatformFile? _selectedFile;
  String _statusMessage = "";

  /// Pick file from device
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
      _statusMessage = "Starting upload process...";
    });

    try {
      final originalBytes = _selectedFile!.bytes!;
      
      // Step 1: Generate Original Hash
      setState(() => _statusMessage = "Generating original hash...");
      final originalHash = EncryptionService.generateHash(originalBytes);

      // Step 2: Encrypt File
      setState(() => _statusMessage = "Encrypting file (AES-256)...");
      final encryptedBytes = await EncryptionService.encryptData(originalBytes);

      // Step 3: Generate Encrypted Hash
      final encryptedHash = EncryptionService.generateHash(encryptedBytes);

      // Step 4: Upload to Firebase Storage
      setState(() => _statusMessage = "Uploading encrypted file to Firebase...");
      final storageUrl = await StorageService.uploadEncryptedFile(
        fileName: _selectedFile!.name,
        encryptedData: encryptedBytes,
      );

      // Step 5: Store on Blockchain
      setState(() => _statusMessage = "Storing metadata on blockchain...");
      final doc = await BlockchainService.storeDocument(
        fileName: _selectedFile!.name,
        fileType: _selectedFile!.extension ?? 'unknown',
        originalHash: originalHash,
        encryptedHash: encryptedHash,
        storageUrl: storageUrl,
        fileSize: originalBytes.length,
      );

      if (!mounted) return;

      setState(() {
        _isUploading = false;
        _selectedFile = null;
        _statusMessage = "";
      });

      _showSuccessDialog(doc.id);
    } catch (e) {
      setState(() {
        _isUploading = false;
        _statusMessage = "Error occurred: $e";
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload error: $e')),
        );
      }
    }
  }

  void _showSuccessDialog(String docId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Production Upload Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: Icon(Icons.verified, color: Colors.green, size: 60)),
            const SizedBox(height: 15),
            const Text('✔ Document encrypted locally'),
            const Text('✔ Uploaded to secure storage'),
            const Text('✔ Hash stored on blockchain'),
            const Divider(),
            Text('Document ID: $docId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Great!'),
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
          const Icon(Icons.security, size: 80, color: Colors.blue),
          const SizedBox(height: 20),
          const Text(
            'Production Upload',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'AES-256 Encrypted & Blockchain Verified',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 40),

          if (_selectedFile != null) _buildFilePreview() else _buildFilePlaceholder(),

          if (_statusMessage.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.blue[700], fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],

          const SizedBox(height: 30),

          ElevatedButton.icon(
            onPressed: _isUploading ? null : _pickFile,
            icon: const Icon(Icons.folder_open),
            label: const Text('Select Document'),
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
                : const Icon(Icons.cloud_done),
            label: Text(_isUploading ? 'Securing Document...' : 'Upload to Production'),
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
        border: Border.all(color: Colors.blue.withOpacity(0.3), width: 2, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          Icon(Icons.file_present, size: 60, color: Colors.grey),
          SizedBox(height: 15),
          Text('No file selected', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
