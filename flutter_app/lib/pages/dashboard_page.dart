import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/auth_service.dart';
import '../services/blockchain_service.dart';
import '../models/document.dart';
import '../utils/helpers.dart';

/// Dashboard Page - Shows all user's uploaded documents
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<List<Document>> _documentsFuture;

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
          // Header with user info
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Text(
                    (AuthService.getCurrentUser() ?? "U")[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Welcome, ${AuthService.getCurrentUser() ?? "User"}!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),

                // Statistics cards (FutureBuilder for stats)
                FutureBuilder<List<Document>>(
                  future: _documentsFuture,
                  builder: (context, snapshot) {
                      final count = snapshot.hasData ? snapshot.data!.length : 0;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                            _buildStatCard(
                            'Documents',
                            count.toString(),
                            Icons.description,
                            ),
                            _buildStatCard(
                            'Verified',
                            count.toString(), // All uploaded are verified/stored
                            Icons.verified,
                            ),
                        ],
                      );
                  }
                ),
              ],
            ),
          ),

          // Document list
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: FutureBuilder<List<Document>>(
                future: _documentsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final documents = snapshot.data ?? [];

                  return documents.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: () async => _refreshDocuments(),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: documents.length,
                            itemBuilder: (context, index) {
                              return _buildDocumentCard(context, documents[index]);
                            },
                          ),
                        );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build statistic card widget
  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 30, color: Colors.blue[700]),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          Text(label, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  /// Build empty state when no documents
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          const Text(
            'No documents uploaded yet',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          const Text(
            'Upload your first document to get started',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// Build document card widget
  Widget _buildDocumentCard(BuildContext context, Document doc) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: CircleAvatar(
          backgroundColor: Colors.blue[700],
          child: Icon(Helpers.getFileIcon(doc.type), color: Colors.white),
        ),
        title: Text(
          doc.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Text('Type: ${doc.type}'),
            Text('Size: ${Helpers.formatFileSize(doc.fileSize)}'),
            Text(
              'Uploaded: ${Helpers.formatDate(doc.uploadDate)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.qr_code),
          onPressed: () => _showQRCode(context, doc),
        ),
        onTap: () => _showDocumentDetails(context, doc),
      ),
    );
  }

  /// Show QR code dialog
  void _showQRCode(BuildContext context, Document doc) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Share Document'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                QrImageView(
                  data: doc.id,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
                const SizedBox(height: 20),
                Text(
                  'Document ID: ${doc.id}',
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Scan this QR code to verify the document',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  /// Show document details dialog
  void _showDocumentDetails(BuildContext context, Document doc) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Document Details'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow('Name', doc.name),
                  _buildDetailRow('Type', doc.type),
                  _buildDetailRow('Owner', doc.owner),
                  _buildDetailRow('Document ID', doc.id),
                  _buildDetailRow('Block Number', doc.blockNumber.toString()),
                  _buildDetailRow(
                    'File Size',
                    Helpers.formatFileSize(doc.fileSize),
                  ),
                  _buildDetailRow(
                    'Upload Date',
                    Helpers.formatDate(doc.uploadDate),
                  ),
                  const Divider(),
                  const Text(
                    'Blockchain Hash:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    doc.hash,
                    style: const TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  /// Build detail row widget
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
