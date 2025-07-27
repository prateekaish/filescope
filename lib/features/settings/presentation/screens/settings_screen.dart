import 'package:filescope/core/theme/app_theme.dart';
import 'package:filescope/features/storage_analysis/presentation/screens/storage_analysis_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Theme'),
            subtitle: Text('Change the app appearance'),
            trailing: DropdownButton<ThemeMode>(
              value: ref.watch(themeProvider),
              items: const [
                DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeProvider.notifier).state = value;
                }
              },
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Storage Analysis'),
            subtitle: const Text('Visualize what\'s taking up space'),
            leading: const Icon(Icons.pie_chart_outline),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const StorageAnalysisScreen(),
                ),
              );
            },
          ),
          const ListTile(
            title: Text('Cloud Accounts'),
            subtitle: Text('Coming Soon'),
            leading: Icon(Icons.cloud_outlined),
          )
        ],
      ),
    );
  }
}