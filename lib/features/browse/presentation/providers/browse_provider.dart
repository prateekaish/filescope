import 'dart:io';

import 'package:filescope/features/browse/data/repositories/file_system_repository_impl.dart';
import 'package:filescope/features/browse/domain/entities/file_system_entity.dart';
import 'package:filescope/features/browse/domain/repositories/file_system_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

// ... (Existing code for provider and BrowseState class)
// 1. Provider for the repository implementation
final fileSystemRepoProvider = Provider<FileSystemRepository>((ref) {
  return FileSystemRepositoryImpl();
});

// 2. The State class
class BrowseState {
  final bool isLoading;
  final String currentPath;
  final List<FileSystemEntity> entities;
  final String? error;
  final List<String> history; // For back navigation

  BrowseState({
    this.isLoading = true,
    this.currentPath = '',
    this.entities = const [],
    this.error,
    this.history = const [],
  });

  BrowseState copyWith({
    bool? isLoading,
    String? currentPath,
    List<FileSystemEntity>? entities,
    String? error,
    List<String>? history,
    bool clearError = false,
  }) {
    return BrowseState(
      isLoading: isLoading ?? this.isLoading,
      currentPath: currentPath ?? this.currentPath,
      entities: entities ?? this.entities,
      error: clearError ? null : error ?? this.error,
      history: history ?? this.history,
    );
  }
}

// 3. The StateNotifier (Controller)
class BrowseController extends StateNotifier<BrowseState> {
  final FileSystemRepository _repository;

  BrowseController(this._repository) : super(BrowseState()) {
    _init();
  }
  
  // ... (Existing _init, loadDirectory, deleteEntity, renameEntity, navigateTo, canNavigateBack, navigateBack methods)
  
  Future<void> _init() async {
    try {
      await _repository.requestPermissions();
      final Directory? initialDir = await getExternalStorageDirectory();
      if (initialDir != null) {
        loadDirectory(initialDir.path);
      } else {
        throw Exception("Could not determine initial directory.");
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> loadDirectory(String path) async {
    // Keep existing data while loading for a smoother experience
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final entities = await _repository.getEntities(path);
      // Only update history when navigating forward successfully
      if (state.currentPath.isEmpty || path != state.currentPath) {
        final newHistory = List<String>.from(state.history)..add(state.currentPath);
        state = state.copyWith(history: newHistory);
      }
      state = state.copyWith(
        isLoading: false,
        currentPath: path,
        entities: entities,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteEntity(FileSystemEntity entity) async {
    try {
      await _repository.deleteEntity(entity);
      await loadDirectory(state.currentPath); // Refresh list
    } catch (e) {
      // Propagate error to be shown in a SnackBar or Dialog
      state = state.copyWith(error: e.toString());
    }
  }
  
  Future<void> renameEntity(FileSystemEntity entity, String newName) async {
    try {
      await _repository.renameEntity(entity, newName);
      await loadDirectory(state.currentPath); // Refresh list
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
  
  // New method for this commit
  Future<void> createDirectory(String folderName) async {
    if (state.currentPath.isEmpty) return;
    try {
      await _repository.createDirectory(state.currentPath, folderName);
      await loadDirectory(state.currentPath); // Refresh list
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void navigateTo(FileSystemEntity entity) {
    if (entity.isDirectory) {
      loadDirectory(entity.path);
    } else {
      // TODO: Implement file open logic (e.g., using open_file package)
      print("Tapped on file: ${entity.name}");
    }
  }

  bool canNavigateBack() {
    return state.history.length > 1;
  }

  void navigateBack() {
    if (!canNavigateBack()) return;
    
    final lastPath = state.history.last;
    final newHistory = List<String>.from(state.history)..removeLast();
    
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      _repository.getEntities(lastPath).then((entities) {
          state = state.copyWith(
            isLoading: false,
            currentPath: lastPath,
            entities: entities,
            history: newHistory
          );
      });
    } catch (e) {
         state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// 4. The final provider that the UI will use
final browseProvider = StateNotifierProvider<BrowseController, BrowseState>((ref) {
  final repository = ref.watch(fileSystemRepoProvider);
  return BrowseController(repository);
});