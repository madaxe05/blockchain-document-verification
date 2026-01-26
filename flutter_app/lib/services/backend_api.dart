import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class BackendApi {
  // Use 10.0.2.2 for Android emulator, localhost for iOS simulator
  // Note: For real device, use your machine's local IP address
  static const String baseUrl = 'http://10.0.2.2:3001/api'; 

  /// Upload document
  static Future<Map<String, dynamic>> uploadDocument({
    required Uint8List fileBytes,
    required String fileName,
    required String ownerId,
    required String ownerName,
    required String documentType,
    required String issuerOrganization,
    required DateTime issueDate,
  }) async {
    final uri = Uri.parse('$baseUrl/upload');

    final request = http.MultipartRequest('POST', uri);

    // FILE (must be named "document")
    request.files.add(
      http.MultipartFile.fromBytes('document', fileBytes, filename: fileName),
    );

    // FORM FIELDS (must match backend)
    request.fields.addAll({
      'ownerId': ownerId,
      'ownerName': ownerName,
      'documentType': documentType,
      'issuerOrganization': issuerOrganization,
      'issueDate': (issueDate.millisecondsSinceEpoch ~/ 1000).toString(),
    });

    try {
        final response = await request.send();
        final body = await response.stream.bytesToString();

        if (response.statusCode != 200) {
        // Try to parse error message
        try {
            final errorJson = jsonDecode(body);
            throw Exception(errorJson['error'] ?? 'Upload failed');
        } catch (_) {
            throw Exception('Upload failed with status ${response.statusCode}');
        }
        }

        return jsonDecode(body);
    } catch (e) {
        throw Exception('Connection error: $e');
    }
  }

  /// Verify by document ID
  static Future<Map<String, dynamic>> verifyById(String documentId) async {
    try {
        final res = await http.get(Uri.parse('$baseUrl/verify/$documentId'));

        if (res.statusCode != 200) {
             try {
                final errorJson = jsonDecode(res.body);
                throw Exception(errorJson['error'] ?? 'Verification failed');
            } catch (_) {
                throw Exception('Verification failed with status ${res.statusCode}');
            }
        }

        return jsonDecode(res.body);
    } catch (e) {
        throw Exception('Connection error: $e');
    }
  }

  /// Verify by uploading file
  static Future<Map<String, dynamic>> verifyByFile({
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    final uri = Uri.parse('$baseUrl/verify-file');

    final request = http.MultipartRequest('POST', uri);
    request.files.add(
      http.MultipartFile.fromBytes('document', fileBytes, filename: fileName),
    );

    try {
        final response = await request.send();
        final body = await response.stream.bytesToString();

        if (response.statusCode != 200) {
            try {
                final errorJson = jsonDecode(body);
                throw Exception(errorJson['error'] ?? 'Verification failed');
            } catch (_) {
                throw Exception('Verification failed with status ${response.statusCode}');
            }
        }

        return jsonDecode(body);
    } catch (e) {
        throw Exception('Connection error: $e');
    }
  }
}
