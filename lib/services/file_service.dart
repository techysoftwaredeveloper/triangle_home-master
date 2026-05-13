import 'dart:io';

class FileService {
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedExtensions = ['jpg', 'jpeg', 'png'];

  static Future<bool> validateImage(File file) async {
    // 1. Check size
    final size = await file.length();
    if (size > maxImageSize) {
      return false;
    }

    // 2. Check extension
    final path = file.path.toLowerCase();
    final extension = path.split('.').last;
    if (!allowedExtensions.contains(extension)) {
      return false;
    }

    return true;
  }

  static Future<List<File>> validateImages(List<File> files) async {
    final validFiles = <File>[];
    for (final file in files) {
      if (await validateImage(file)) {
        validFiles.add(file);
      }
    }
    return validFiles;
  }
}
