import '../entities/file_system_entity.dart';

abstract class FileSystemRepository {
  Future<List<FileSystemEntity>> getEntities(String path);
  Future<void> requestPermissions();
  // New methods for this commit
  Future<void> deleteEntity(FileSystemEntity entity);
  Future<void> renameEntity(FileSystemEntity entity, String newName);
}