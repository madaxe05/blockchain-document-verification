import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../services/auth_service.dart';
import '../services/blockchain_service.dart';
import '../services/storage_service.dart';
import '../services/encryption_service.dart';
import '../models/document.dart';
import '../utils/helpers.dart';

/// Dashboard Page - Production Realistic
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
      final encryptedBytes = await StorageService.downloadFile(doc.storageUrl);
      final decryptedBytes = await EncryptionService.decryptData(encryptedBytes);

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/${doc.name}');
      await file.writeAsBytes(decryptedBytes);

      await OpenFile.open(file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening document: $e'), backgroundColor: Colors.red),
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
          colors: [Colors.blue[700]!, Colors.blue[50]!],
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
                      color: Colors.black26,
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
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: Text(
              (AuthService.getCurrentUser() ?? "U")[0].toUpperCase(),
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue[700]),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Welcome, ${AuthService.getCurrentUser() ?? "User"}!',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 20),
          FutureBuilder<List<Document>>(
            future: _documentsFuture,
            builder: (context, snapshot) {
              final count = snapshot.hasData ? snapshot.data!.length : 0;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatCard('Stored', count.toString(), Icons.storage),
                  _buildStatCard('Verified', count.toString(), Icons.verified),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 5))]),
      child: Column(
        children: [
          Icon(icon, size: 24, color: Colors.blue[700]),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue[700])),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
        itemBuilder: (context, index) => _buildDocumentCard(documents[index]),
      ),
    );
  }

  Widget _buildDocumentCard(Document doc) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: Colors.blue[50],
          child: Icon(Helpers.getFileIcon(doc.type), color: Colors.blue[700]),
        ),
        title: Text(doc.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Size: ${Helpers.formatFileSize(doc.fileSize)} • ${Helpers.formatDate(doc.uploadDate)}', style: const TextStyle(fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.qr_code, size: 20), onPressed: () => _showQRCode(doc)),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
        onTap: () => _showDocumentDetails(doc),
      ),
    );
  }

  void _showQRCode(Document doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Verification ID'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(data: doc.id, size: 180),
            const SizedBox(height: 10),
            SelectableText(doc.id, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            const Text('Scan to verify this document on blockchain', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  void _showDocumentDetails(Document doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(doc.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Owner', doc.owner),
              _buildDetailRow('ID', doc.id),
              _buildDetailRow('Block', doc.blockNumber.toString()),
              _buildDetailRow('Date', Helpers.formatDate(doc.uploadDate)),
              const Divider(),
              const Text('Original Hash (SHA-256):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              SelectableText(doc.originalHash, style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.blue)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _openDocument(doc);
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Decrypt & Open'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700], foregroundColor: Colors.white),
                ),
              ),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 13)),
      ]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 80, color: Colors.grey[200]),
          const SizedBox(height: 16),
          const Text('No documents secured yet', style: TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }
}
