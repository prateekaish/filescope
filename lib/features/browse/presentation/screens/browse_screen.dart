import 'package:filescope/features/browse/presentation/providers/browse_provider.dart';
import 'package:filescope/features/browse/presentation/widgets/file_list_item.dart';
import 'package:filescope/features/browse/presentation/widgets/folder_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BrowseScreen extends ConsumerWidget {
  const BrowseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(browseProvider);
    final controller = ref.read(browseProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          state.currentPath.isEmpty ? 'FileScope' : state.currentPath.split('/').last,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        leading: controller.canNavigateBack()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => controller.navigateBack(),
              )
            : null,
        // TODO: Add contextual actions here (e.g., sort, create folder)
      ),
      body: _buildBody(context, state, controller),
    );
  }

  Widget _buildBody(BuildContext context, BrowseState state, BrowseController controller) {
    if (state.isLoading && state.entities.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Error: ${state.error}', textAlign: TextAlign.center),
        ),
      );
    }

    if (state.entities.isEmpty) {
      return const Center(child: Text('This folder is empty.'));
    }

    return RefreshIndicator(
      onRefresh: () => controller.loadDirectory(state.currentPath),
      child: ListView.builder(
        itemCount: state.entities.length,
        itemBuilder: (context, index) {
          final entity = state.entities[index];
          if (entity.isDirectory) {
            return FolderListItem(
              folder: entity,
              onTap: () => controller.navigateTo(entity),
            );
          } else {
            return FileListItem(
              file: entity,
              onTap: () => controller.navigateTo(entity),
            );
          }
        },
      ),
    );
  }
}