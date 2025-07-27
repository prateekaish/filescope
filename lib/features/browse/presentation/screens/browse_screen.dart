import 'package:filescope/core/utils/file_helpers.dart';
import 'package:filescope/features/browse/domain/entities/file_system_entity.dart';
import 'package:filescope/features/browse/domain/repositories/file_system_repository.dart';
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
      appBar: _buildAppBar(context, state, controller),
      body: _buildBody(context, state, controller, ref),
      floatingActionButton:
          _buildFloatingActionButton(context, state, controller),
    );
  }

  AppBar _buildAppBar(
      BuildContext context, BrowseState state, BrowseController controller) {
    if (state.isSelectionMode) {
      final allSelected = state.selectedPaths.length == state.entities.length && state.entities.isNotEmpty;
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => controller.clearSelection(),
        ),
        title: Text('${state.selectedPaths.length} selected'),
        actions: [
          IconButton(
            icon: Icon(allSelected ? Icons.deselect_outlined : Icons.select_all),
            tooltip: allSelected ? 'Deselect All' : 'Select All',
            onPressed: () => controller.toggleSelectAll(),
          ),
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            tooltip: 'Copy',
            onPressed: () => controller.copyToClipboard(isCopy: true),
          ),
          IconButton(
            icon: const Icon(Icons.drive_file_move_outlined),
            tooltip: 'Move',
            onPressed: () => controller.copyToClipboard(isCopy: false),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
            onPressed: () => _showBatchDeleteConfirmationDialog(context, controller, state.selectedPaths.length),
          ),
        ],
      );
    } else if (state.isPasting) {
      return AppBar(
        title: Text('Pasting ${state.clipboardPaths.length} items'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Cancel Paste',
          onPressed: () => controller.clearClipboard(),
        ),
      );
    } else {
      // MODIFIED: The title is now the breadcrumbs widget
      return AppBar(
        title: _buildBreadcrumbs(context, state, controller),
        leading: controller.canNavigateBack()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => controller.navigateBack(),
              )
            : null,
        titleSpacing: 0, // Remove default spacing
      );
    }
  }

  // New breadcrumbs widget
  Widget _buildBreadcrumbs(BuildContext context, BrowseState state, BrowseController controller) {
    if (state.currentPath.isEmpty) {
      return const Text("FileScope", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
    }
    
    // Split the path into segments
    List<String> segments = state.currentPath.split('/').where((s) => s.isNotEmpty).toList();
    // For root path "/storage/emulated/0", ensure "0" is not lost
    if (state.currentPath == '/storage/emulated/0') {
      segments = ['storage', 'emulated', '0'];
    }

    // Scrollable container for the breadcrumbs
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true, // Start from the end
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: List.generate(segments.length, (index) {
          // Reconstruct the path for each segment
          String path = '/' + segments.sublist(0, index + 1).join('/');

          // Special case for the root directory path
          if (index == 2 && segments.sublist(0,3).join('/') == 'storage/emulated/0') {
            path = '/storage/emulated/0';
          }

          return Row(
            children: [
              // Separator
              const Icon(Icons.chevron_right, size: 18),
              // Tappable breadcrumb
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
                ),
                child: Text(
                  segments[index],
                  style: TextStyle(
                    fontSize: 18,
                    // The last item (current folder) is bold
                    fontWeight: index == segments.length - 1 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                onPressed: () {
                  // Don't navigate if it's the last item (current folder)
                  if (index < segments.length - 1) {
                    controller.loadDirectory(path);
                  }
                },
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget? _buildFloatingActionButton(
      BuildContext context, BrowseState state, BrowseController controller) {
    if (state.isPasting) {
      return FloatingActionButton.extended(
        onPressed: () => controller.pasteFromClipboard(),
        label: const Text('Paste Here'),
        icon: const Icon(Icons.content_paste_go),
      );
    } else if (!state.isSelectionMode) {
      return FloatingActionButton(
        onPressed: () => _showCreateFolderDialog(context, controller),
        child: const Icon(Icons.create_new_folder_outlined),
      );
    }
    return null;
  }

  Widget _buildBody(
      BuildContext context, BrowseState state, BrowseController controller, WidgetRef ref) {
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

    if (state.entities.isEmpty && !state.isLoading) {
      return const Center(child: Text('This folder is empty.'));
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (!state.isSelectionMode) {
          await controller.loadDirectory(state.currentPath);
        }
      },
      child: Stack(
        children: [
          ListView.builder(
            itemCount: state.entities.length,
            itemBuilder: (context, index) {
              final entity = state.entities[index];
              final isSelected = state.selectedPaths.contains(entity.path);

              void handleTap() {
                if (state.isSelectionMode) {
                  controller.toggleSelection(entity.path);
                } else {
                  controller.navigateTo(entity);
                }
              }

              void handleOptionsLongPress() {
                if (!state.isSelectionMode) {
                  _showOptionsSheet(context, entity, controller, ref);
                } else {
                  controller.toggleSelection(entity.path);
                }
              }

              if (entity.isDirectory) {
                return FolderListItem(
                  folder: entity,
                  isSelected: isSelected,
                  onTap: handleTap,
                  onLongPress: handleOptionsLongPress,
                );
              } else {
                return FileListItem(
                  file: entity,
                  isSelected: isSelected,
                  onTap: handleTap,
                  onLongPress: handleOptionsLongPress,
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

  void _showOptionsSheet(BuildContext context, FileSystemEntity entity,
      BrowseController controller, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Details'),
              onTap: () {
                Navigator.pop(context);
                _showDetailsDialog(context, entity, ref.read(fileSystemRepoProvider));
              },
            ),
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(context, entity, controller);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmationDialog(context, entity, controller);
              },
            ),
          ],
        );
      },
    );
  }

  void _showDetailsDialog(BuildContext context, FileSystemEntity entity, FileSystemRepository repo) async {
    int? itemCount;
    if (entity.isDirectory) {
      itemCount = await repo.getDirectorySize(entity.path);
    }

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
              if (entity.isDirectory)
                Text('Items: ${itemCount ?? "..."}')
              else
                Text('Size: ${formatBytes(entity.size, 2)}'),
              const SizedBox(height: 8),
              Text(
                  'Modified: ${DateFormat.yMMMd().add_jm().format(entity.modified)}'),
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

  void _showRenameDialog(BuildContext context, FileSystemEntity entity,
      BrowseController controller) {
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

  void _showDeleteConfirmationDialog(BuildContext context,
      FileSystemEntity entity, BrowseController controller) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Confirmation'),
          content: Text(
              'Are you sure you want to delete "${entity.name}"? This action cannot be undone.'),
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
  
  void _showBatchDeleteConfirmationDialog(BuildContext context, BrowseController controller, int count) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Confirmation'),
          content: Text(
              'Are you sure you want to delete $count items? This action cannot be undone.'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                controller.deleteSelectedItems();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showCreateFolderDialog(
      BuildContext context, BrowseController controller) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create New Folder'),
          content: TextField(
            controller: textController,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Folder name'),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Create'),
              onPressed: () {
                final folderName = textController.text.trim();
                if (folderName.isNotEmpty) {
                  controller.createDirectory(folderName);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
}