import 'dart:async';
import 'dart:io';

import 'package:filescope/core/utils/file_helpers.dart';
import 'package:filescope/features/browse/domain/entities/file_system_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;

// --- Search Provider and State ---
class SearchState {
  final bool isLoading;
  final List<FileSystemEntity> results;
  final String? error;

  SearchState({
    this.isLoading = false,
    this.results = const [],
    this.error,
  });

  SearchState copyWith({
    bool? isLoading,
    List<FileSystemEntity>? results,
    String? error,
  }) {
    return SearchState(
      isLoading: isLoading ?? this.isLoading,
      results: results ?? this.results,
      error: error ?? this.error,
    );
  }
}

class SearchController extends StateNotifier<SearchState> {
  SearchController() : super(SearchState());

  StreamSubscription? _searchSubscription;

  void searchFiles(String query) {
    _searchSubscription?.cancel();
    if (query.isEmpty) {
      state = state.copyWith(results: [], isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, results: []);
    
    final root = Directory('/storage/emulated/0/');
    final List<FileSystemEntity> foundFiles = [];

    _searchSubscription = root.list(recursive: true, followLinks: false).listen(
      (entity) {
        if (p.basename(entity.path).toLowerCase().contains(query.toLowerCase())) {
          try {
            final stat = entity.statSync();
            foundFiles.add(FileSystemEntity(
              path: entity.path,
              name: p.basename(entity.path),
              isDirectory: stat.type == FileSystemEntityType.directory,
              size: stat.size,
              modified: stat.modified,
            ));
            // Update the state with intermediate results for a responsive feel
            state = state.copyWith(results: List.from(foundFiles));
          } catch (e) {
            // In case statSync fails for some reason, just skip the file
          }
        }
      },
      onDone: () {
        state = state.copyWith(isLoading: false);
      },
      // MODIFIED BLOCK
      onError: (e) {
        // If it's a permission error on a specific directory, just ignore it and continue searching.
        if (e is PathAccessException) {
          // This is expected for protected directories, so we do nothing and let the stream continue.
        } else {
          // For other, unexpected errors, update the state.
          state = state.copyWith(error: e.toString(), isLoading: false);
        }
      },
      // The default for cancelOnError is false, so the stream will continue after an error is handled.
    );
  }

  @override
  void dispose() {
    _searchSubscription?.cancel();
    super.dispose();
  }
}

final searchProvider = StateNotifierProvider.autoDispose<SearchController, SearchState>((ref) {
  return SearchController();
});

// --- Search Screen UI ---
class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchProvider);
    final controller = ref.read(searchProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Files'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor.withAlpha(200),
              ),
              onChanged: (query) => controller.searchFiles(query),
            ),
          ),
          if (state.isLoading) const LinearProgressIndicator(),
          Expanded(
            child: _buildResults(context, state),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context, SearchState state) {
    if (state.error != null) {
      return Center(child: Text('Error: ${state.error}'));
    }

    if (state.results.isEmpty && !state.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Type to start searching.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: state.results.length,
      itemBuilder: (context, index) {
        final entity = state.results[index];
        return ListTile(
          leading: Icon(entity.isDirectory ? Icons.folder : getIconForFile(entity.name)),
          title: Text(entity.name),
          subtitle: Text(entity.path),
          onTap: () => OpenFile.open(entity.path),
        );
      },
    );
  }
}