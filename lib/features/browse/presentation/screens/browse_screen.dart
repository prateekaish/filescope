import 'package:filescope/core/utils/file_helpers.dart';
import 'package:filescope/features/browse/domain/entities/file_system_entity.dart';
import 'package:filescope/features/browse/presentation/providers/browse_provider.dart';
import 'package:filescope/features/browse/presentation/widgets/file_list_item.dart';
import 'package:filescope/features/browse/presentation/widgets/folder_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class BrowseScreen extends ConsumerWidget {
  const BrowseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen for errors to show a SnackBar
    ref.listen<BrowseState>(browseProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
      }
    });

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
      ),
      body: _buildBody(context, state, controller),
    );
  }

  Widget _buildBody(BuildContext context, BrowseState state, BrowseController controller) {
    if (state.isLoading && state.entities.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!state.isLoading && state.error != null && state.entities.isEmpty) {
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
      child: Stack(
        children: [
          ListView.builder(
            itemCount: state.entities.length,
            itemBuilder: (context, index) {
              final entity = state.entities[index];
              if (entity.isDirectory) {
                return FolderListItem(
                  folder: entity,
                  onTap: () => controller.navigateTo(entity),
                  onLongPress: () => _showOptionsSheet(context, entity, controller),
                );
              } else {
                return FileListItem(
                  file: entity,
                  onTap: () => controller.navigateTo(entity),
                  onLongPress: () => _showOptionsSheet(context, entity, controller),
                );
              }
            },
          ),
          if (state.isLoading)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }

  void _showOptionsSheet(BuildContext context, FileSystemEntity entity, BrowseController controller) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Details'),
              onTap: () {
                Navigator.pop(context); // Close the sheet
                _showDetailsDialog(context, entity);
              },
            ),
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(context); // Close the sheet
                _showRenameDialog(context, entity, controller);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context); // Close the sheet
                _showDeleteConfirmationDialog(context, entity, controller);
              },
            ),
          ],
        );
      },
    );
  }

  void _showDetailsDialog(BuildContext context, FileSystemEntity entity) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Details'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Name: ${entity.name}', overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Text('Path: ${entity.path}'),
              const SizedBox(height: 8),
              Text('Type: ${entity.isDirectory ? 'Folder' : 'File'}'),
              const SizedBox(height: 8),
              if (!entity.isDirectory) Text('Size: ${formatBytes(entity.size, 2)}'),
              const SizedBox(height: 8),
              Text('Modified: ${DateFormat.yMMMd().add_jm().format(entity.modified)}'),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _showRenameDialog(BuildContext context, FileSystemEntity entity, BrowseController controller) {
    final textController = TextEditingController(text: entity.name);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Rename ${entity.isDirectory ? 'Folder' : 'File'}'),
          content: TextField(
            controller: textController,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'New name'),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Rename'),
              onPressed: () {
                controller.renameEntity(entity, textController.text.trim());
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, FileSystemEntity entity, BrowseController controller) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Confirmation'),
          content: Text('Are you sure you want to delete "${entity.name}"? This action cannot be undone.'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                controller.deleteEntity(entity);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}