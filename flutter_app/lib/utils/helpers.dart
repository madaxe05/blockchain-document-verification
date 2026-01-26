import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Helpers {
  /// Format file size to human readable string
  static String formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = (bytes > 0) ? (bytes.bitLength - 1) ~/ 10 : 0; // approximate log1024
    if (i >= suffixes.length) i = suffixes.length - 1;
    // 1024 is 2^10
    // each increment in i represents multiplication by 1024
    double size = bytes / (1 << (i * 10)); 
    return '${size.toStringAsFixed(2)} ${suffixes[i]}';
  }

  /// Format date to string
  static String formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy HH:mm').format(date);
  }

  /// Get icon based on file extension
  static IconData getFileIcon(String extension) {
    switch (extension.toLowerCase().replaceAll('.', '')) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.grid_on;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }
}
