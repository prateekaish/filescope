import 'package:filescope/core/utils/file_helpers.dart';
import 'package:filescope/features/browse/domain/entities/file_system_entity.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FileListItem extends StatelessWidget {
  final FileSystemEntity file;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const FileListItem({
    super.key,
    required this.file,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.description_outlined),
      title: Text(file.name),
      subtitle: Text(
        '${formatBytes(file.size, 2)} • ${DateFormat.yMMMd().format(file.modified)}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}