import 'package:filescope/features/browse/domain/entities/file_system_entity.dart';
import 'package:flutter/material.dart';

class FolderListItem extends StatelessWidget {
  final FileSystemEntity folder;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool isSelected;

  const FolderListItem({
    super.key,
    required this.folder,
    required this.onTap,
    required this.onLongPress,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: isSelected ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3) : null,
      leading: isSelected
          ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
          : Icon(Icons.folder, color: Theme.of(context).colorScheme.primary),
      title: Text(folder.name),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}