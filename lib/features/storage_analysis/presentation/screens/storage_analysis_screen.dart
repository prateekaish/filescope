import 'package:filescope/core/utils/file_helpers.dart';
import 'package:filescope/features/storage_analysis/presentation/providers/analysis_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StorageAnalysisScreen extends ConsumerWidget {
  const StorageAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analysisProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage Analysis'),
      ),
      body: state.isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Analyzing storage... This may take a while.'),
                ],
              ),
            )
          : state.error != null
              ? Center(child: Text('Error: ${state.error}'))
              : _buildResults(context, state),
    );
  }

  Widget _buildResults(BuildContext context, AnalysisState state) {
    final double systemAndOther = state.usedSpace - state.categories.fold(0.0, (sum, cat) => sum + cat.sizeInBytes);
    final totalCategorized = state.usedSpace - systemAndOther;
    
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // --- Overall Storage Section ---
        Text('Total Storage', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: state.totalSpace > 0 ? state.usedSpace / state.totalSpace : 0,
          minHeight: 12,
          borderRadius: BorderRadius.circular(6),
        ),
        const SizedBox(height: 8),
        Text(
          '${formatBytes(state.usedSpace.toInt(), 2)} used of ${formatBytes(state.totalSpace.toInt(), 2)}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),

        // --- Pie Chart Section ---
        Text('Categorized Files', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: state.categories.map((cat) {
                return PieChartSectionData(
                  color: cat.color,
                  value: cat.sizeInBytes,
                  title: formatBytes(cat.sizeInBytes.toInt(), 1),
                  radius: 80,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
              centerSpaceRadius: 20,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // --- Category List Section ---
        ...state.categories.map((cat) {
          final percentage = totalCategorized > 0 ? cat.sizeInBytes / totalCategorized * 100 : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Icon(cat.icon, color: cat.color),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cat.name, style: Theme.of(context).textTheme.bodyLarge),
                    Text(
                      '${formatBytes(cat.sizeInBytes.toInt(), 2)} (${percentage.toStringAsFixed(1)}%)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}