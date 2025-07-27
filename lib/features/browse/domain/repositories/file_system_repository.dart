import '../entities/file_system_entity.dart';

abstract class FileSystemRepository {
  Future<List<FileSystemEntity>> getEntities(String path);
  Future<void> requestPermissions();
}