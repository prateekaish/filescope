import 'dart:io';
import 'package:filescope/features/browse/domain/entities/file_system_entity.dart';
import 'package:filescope/features/browse/domain/repositories/file_system_repository.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

class FileSystemRepositoryImpl implements FileSystemRepository {
  // ... (existing code for requestPermissions, getEntities, deleteEntity, renameEntity)

  @override
  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.request().isGranted) {
        return;
      }
    }
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
    
    entities.sort((a, b) {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return entities;
  }

  @override
  Future<void> deleteEntity(FileSystemEntity entity) async {
    try {
      if (entity.isDirectory) {
        final dir = Directory(entity.path);
        await dir.delete(recursive: true);
      } else {
        final file = File(entity.path);
        await file.delete();
      }
    } catch (e) {
      // Re-throw with a more user-friendly message
      throw Exception('Failed to delete ${entity.name}. Error: $e');
    }
  }

  @override
  Future<void> renameEntity(FileSystemEntity entity, String newName) async {
    try {
      final newPath = p.join(p.dirname(entity.path), newName);
      if (entity.isDirectory) {
        final dir = Directory(entity.path);
        await dir.rename(newPath);
      } else {
        final file = File(entity.path);
        await file.rename(newPath);
      }
    } catch (e) {
      throw Exception('Failed to rename ${entity.name}. Error: $e');
    }
  }
  
  // New implementation for this commit
  @override
  Future<void> createDirectory(String currentPath, String folderName) async {
    try {
      final newDirPath = p.join(currentPath, folderName);
      final newDir = Directory(newDirPath);

      if (await newDir.exists()) {
        throw Exception('A folder with this name already exists.');
      }
      
      await newDir.create();
    } catch (e) {
      throw Exception('Failed to create folder. Error: $e');
    }
  }
}