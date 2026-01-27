import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../services/auth_service.dart';
import '../services/blockchain_service.dart';
import '../services/local_storage_service.dart';
import '../services/encryption_service.dart';
import '../models/document.dart';
import '../utils/helpers.dart';

/// Dashboard Page - Local-First with Sharing
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<List<Document>> _documentsFuture;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _refreshDocuments();
  }

  void _refreshDocuments() {
    setState(() {
      _documentsFuture = BlockchainService.getUserDocuments();
    });
  }

  Future<void> _openDocument(Document doc) async {
    setState(() => _isProcessing = true);
    try {
      final encryptedBytes = await LocalStorageService.readFile(doc.localPath);
      final decryptedBytes = await EncryptionService.decryptData(encryptedBytes);

      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${doc.name}');
      await tempFile.writeAsBytes(decryptedBytes);

      await OpenFile.open(tempFile.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue[900]!, Colors.blue[50]!],
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
              ),
              child: Stack(
                children: [
                   FutureBuilder<List<Document>>(
                    future: _documentsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      final documents = snapshot.data ?? [];
                      return documents.isEmpty ? _buildEmptyState() : _buildDocumentList(documents);
                    },
                  ),
                  if (_isProcessing)
                    Container(
                      color: Colors.black.withAlpha(66),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Column(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white,
            child: Text(
              (AuthService.getCurrentUser() ?? "U")[0].toUpperCase(),
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue[900]),
            ),
          ),
          const SizedBox(height: 12),
          Text(
             AuthService.getCurrentUser() ?? "User",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const Text('Local-First Documents', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 20),
          FutureBuilder<List<Document>>(
            future: _documentsFuture,
            builder: (context, snapshot) {
              final count = snapshot.hasData ? snapshot.data!.length : 0;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                   _statTile('Files', count.toString(), Icons.folder_shared),
                   _statTile('Verified', count.toString(), Icons.security),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _statTile(String label, String value, IconData icon) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)]),
      child: Column(
        children: [
          Icon(icon, size: 20, color: Colors.blue[900]),
          const SizedBox(height: 5),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[900])),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildDocumentList(List<Document> documents) {
    return RefreshIndicator(
      onRefresh: () async => _refreshDocuments(),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: documents.length,
        itemBuilder: (context, index) => _docCard(documents[index]),
      ),
    );
  }

  Widget _docCard(Document doc) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(Helpers.getFileIcon(doc.type), color: Colors.blue[900], size: 30),
        title: Text(doc.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text('${Helpers.formatFileSize(doc.fileSize)} • ${Helpers.formatDate(doc.uploadDate)}', style: const TextStyle(fontSize: 11)),
        trailing: IconButton(
          icon: const Icon(Icons.qr_code_2, color: Colors.blue),
          onPressed: () => _showQR(doc),
        ),
        onTap: () => _details(doc),
      ),
    );
  }

  void _showQR(Document doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Verification QR'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(data: doc.id, size: 180),
            const SizedBox(height: 15),
            Text('Document ID: ${doc.id}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => Share.share("Verify my document on Blockchain. ID: ${doc.id}"),
            icon: const Icon(Icons.share, color: Colors.blue),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _details(Document doc) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(doc.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            _infoLine('ID', doc.id),
            _infoLine('Original Hash', doc.originalHash.substring(0, 20) + "..."),
            _infoLine('Status', 'Immutable proof on-chain'),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _openDocument(doc);
              },
              icon: const Icon(Icons.file_open),
              label: const Text('Decrypt & View Document'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[900],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () => Share.share("Blockchain Proof for ${doc.name}\nID: ${doc.id}\nHash: ${doc.originalHash}"),
              icon: const Icon(Icons.share),
              label: const Text('Share Proof Metadata'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.folder_off, size: 60, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No documents found', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
