import 'package:filescope/features/browse/domain/entities/file_system_entity.dart';
import 'package:flutter/material.dart';

class FolderListItem extends StatelessWidget {
  final FileSystemEntity folder;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const FolderListItem({
    super.key,
    required this.folder,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.folder, color: Theme.of(context).colorScheme.primary),
      title: Text(folder.name),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}