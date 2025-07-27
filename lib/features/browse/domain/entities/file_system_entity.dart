import 'dart:io';

class FileSystemEntity {
  final String path;
  final String name;
  final bool isDirectory;
  final int size;
  final DateTime modified;

  FileSystemEntity({
    required this.path,
    required this.name,
    required this.isDirectory,
    required this.size,
    required this.modified,
  });

  // Corrected the method call by removing the 'followLinks' parameter
  static Future<FileSystemEntityType> type(String path) {
    // This calls the static method from dart:io's FileSystemEntity
    return FileSystemEntity.type(path);
  }
}