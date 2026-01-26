import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload encrypted file to Firebase Storage
  static Future<String> uploadEncryptedFile({
    required String fileName,
    required Uint8List encryptedData,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not authenticated");

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'documents/${user.uid}/$timestamp\_$fileName.enc';
    final ref = _storage.ref().child(path);

    final uploadTask = ref.putData(
      encryptedData,
      SettableMetadata(contentType: 'application/octet-stream'),
    );

    final snapshot = await uploadTask;
    
    // Add a small retry loop for getDownloadURL as Firebase Storage can sometimes 
    // have propagation lag, causing object-not-found errors right after upload.
    for (int i = 0; i < 3; i++) {
        try {
            return await snapshot.ref.getDownloadURL();
        } catch (e) {
            if (i == 2) rethrow;
            await Future.delayed(Duration(seconds: 1));
        }
    }
    throw Exception("Could not retrieve download URL");
  }

  /// Download file from Firebase Storage
  static Future<Uint8List> downloadFile(String url) async {
    final ref = _storage.refFromURL(url);
    final data = await ref.getData();
    if (data == null) throw Exception("Failed to download file");
    return data;
  }
}
