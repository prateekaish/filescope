import 'dart:io';
import 'package:filescope/features/browse/domain/entities/file_system_entity.dart';
import 'package:filescope/features/browse/domain/repositories/file_system_repository.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

class FileSystemRepositoryImpl implements FileSystemRepository {

  @override
  Future<void> requestPermissions() async {
    // On modern Android, MANAGE_EXTERNAL_STORAGE is required for broad access.
    // This will open system settings for the user to grant the permission.
    if (Platform.isAndroid) {
        if (await Permission.manageExternalStorage.request().isGranted) {
            return;
        }
    }
    // For other platforms or if the above fails, check standard storage perm.
    if (await Permission.storage.request().isDenied) {
        throw Exception('Storage permissions are required to browse files.');
    }
  }

  @override
  Future<List<FileSystemEntity>> getEntities(String path) async {
    final directory = Directory(path);
    final List<FileSystemEntity> entities = [];

    if (!await directory.exists()) {
      throw Exception('Directory not found: $path');
    }
    
    final items = await directory.list().toList();

    for (var item in items) {
      final stat = await item.stat();
      entities.add(
        FileSystemEntity(
          path: item.path,
          name: p.basename(item.path),
          isDirectory: stat.type == FileSystemEntityType.directory,
          size: stat.size,
          modified: stat.modified,
        ),
      );
    }
    
    // Sort directories first, then by name
    entities.sort((a, b) {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return entities;
  }
}