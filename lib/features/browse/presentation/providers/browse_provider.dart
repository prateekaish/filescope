import 'dart:async';
import 'dart:io';

import 'package:filescope/features/browse/data/repositories/file_system_repository_impl.dart';
import 'package:filescope/features/browse/domain/entities/file_system_entity.dart';
import 'package:filescope/features/browse/domain/repositories/file_system_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

final fileSystemRepoProvider = Provider<FileSystemRepository>((ref) {
  return FileSystemRepositoryImpl();
});

class BrowseState {
  final bool isLoading;
  final String currentPath;
  final List<FileSystemEntity> entities;
  final String? error;
  final List<String> history;
  final bool isSelectionMode;
  final Set<String> selectedPaths; // Use path as unique ID

  BrowseState({
    this.isLoading = true,
    this.currentPath = '',
    this.entities = const [],
    this.error,
    this.history = const [],
    this.isSelectionMode = false,
    this.selectedPaths = const {},
  });

  BrowseState copyWith({
    bool? isLoading,
    String? currentPath,
    List<FileSystemEntity>? entities,
    String? error,
    List<String>? history,
    bool? isSelectionMode,
    Set<String>? selectedPaths,
    bool clearError = false,
  }) {
    return BrowseState(
      isLoading: isLoading ?? this.isLoading,
      currentPath: currentPath ?? this.currentPath,
      entities: entities ?? this.entities,
      error: clearError ? null : error ?? this.error,
      history: history ?? this.history,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      selectedPaths: selectedPaths ?? this.selectedPaths,
    );
  }
}

class BrowseController extends StateNotifier<BrowseState> {
  final FileSystemRepository _repository;

  BrowseController(this._repository) : super(BrowseState()) {
    _init();
  }

  // UPDATED METHOD
  Future<void> _init() async {
    try {
      await _repository.requestPermissions();
      // Define the standard public storage directory for Android.
      const String rootPath = '/storage/emulated/0';
      final Directory initialDir = Directory(rootPath);

      if (await initialDir.exists()) {
        await loadDirectory(initialDir.path);
      } else {
        // Fallback in case the primary path doesn't exist on a specific device
        final Directory? fallbackDir = await getExternalStorageDirectory();
        if (fallbackDir != null) {
          await loadDirectory(fallbackDir.path);
        } else {
          throw Exception("Could not find a valid storage directory.");
        }
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> loadDirectory(String path) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final entities = await _repository.getEntities(path);
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
      await loadDirectory(state.currentPath);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> renameEntity(FileSystemEntity entity, String newName) async {
    try {
      await _repository.renameEntity(entity, newName);
      await loadDirectory(state.currentPath);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> createDirectory(String folderName) async {
    if (state.currentPath.isEmpty) return;
    try {
      await _repository.createDirectory(state.currentPath, folderName);
      await loadDirectory(state.currentPath);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void toggleSelection(String path) {
    final newSelectedPaths = Set<String>.from(state.selectedPaths);
    if (newSelectedPaths.contains(path)) {
      newSelectedPaths.remove(path);
    } else {
      newSelectedPaths.add(path);
    }

    state = state.copyWith(
      selectedPaths: newSelectedPaths,
      isSelectionMode: newSelectedPaths.isNotEmpty,
    );
  }

  void clearSelection() {
    state = state.copyWith(
      selectedPaths: {},
      isSelectionMode: false,
    );
  }

  Future<void> deleteSelectedItems() async {
    final pathsToDelete = List<FileSystemEntity>.from(
      state.entities.where((e) => state.selectedPaths.contains(e.path))
    );

    try {
      await Future.wait(pathsToDelete.map((entity) => _repository.deleteEntity(entity)));
      clearSelection();
      await loadDirectory(state.currentPath);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void navigateTo(FileSystemEntity entity) {
    if (entity.isDirectory) {
      loadDirectory(entity.path);
    } else {
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
          history: newHistory,
        );
      });
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final browseProvider = StateNotifierProvider<BrowseController, BrowseState>((ref) {
  final repository = ref.watch(fileSystemRepoProvider);
  return BrowseController(repository);
});