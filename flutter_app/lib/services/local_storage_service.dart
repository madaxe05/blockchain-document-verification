import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

class LocalStorageService {
  /// Save encrypted file to the device's local documents directory
  static Future<String> saveEncryptedFile({
    required String fileName,
    required Uint8List encryptedData,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${directory.path}/${timestamp}_$fileName.enc';
    
    final file = File(filePath);
    await file.writeAsBytes(encryptedData);
    
    return filePath;
  }

  /// Read file from local storage
  static Future<Uint8List> readFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception("File not found at $filePath");
    }
    return await file.readAsBytes();
  }

  /// Delete a file
  /// Get path for ledger file
  static Future<String> getLedgerPath(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$fileName';
  }
}
