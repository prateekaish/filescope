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
}