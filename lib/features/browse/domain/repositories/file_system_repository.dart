import '../entities/file_system_entity.dart';

abstract class FileSystemRepository {
  Future<List<FileSystemEntity>> getEntities(String path);
  Future<void> requestPermissions();
  Future<void> deleteEntity(FileSystemEntity entity);
  Future<void> renameEntity(FileSystemEntity entity, String newName);
  Future<void> createDirectory(String currentPath, String folderName);
  Future<void> copyEntity(String sourcePath, String destinationPath);
  Future<void> moveEntity(String sourcePath, String destinationPath);
  Future<int> getDirectorySize(String path);
}