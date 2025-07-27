import 'dart:io';
import 'package:filescope/core/services/storage_service.dart';
import 'package:filescope/features/storage_analysis/domain/entities/storage_category.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

// --- State Definition ---
class AnalysisState {
  final bool isLoading;
  final double totalSpace;
  final double freeSpace;
  final List<StorageCategory> categories;
  final String? currentScanPath;
  final String? error;

  double get usedSpace => totalSpace - freeSpace;

  AnalysisState({
    this.isLoading = true,
    this.totalSpace = 0.0,
    this.freeSpace = 0.0,
    this.categories = const [],
    this.currentScanPath,
    this.error,
  });

  AnalysisState copyWith({
    bool? isLoading,
    double? totalSpace,
    double? freeSpace,
    List<StorageCategory>? categories,
    String? currentScanPath,
    String? error,
  }) {
    return AnalysisState(
      isLoading: isLoading ?? this.isLoading,
      totalSpace: totalSpace ?? this.totalSpace,
      freeSpace: freeSpace ?? this.freeSpace,
      categories: categories ?? this.categories,
      currentScanPath: currentScanPath ?? this.currentScanPath,
      error: error ?? this.error,
    );
  }
}

// --- Background Isolate Function ---
Future<Map<String, double>> _analyzeStorageInBackground(String path) async {
  final categories = {
    'Images': 0.0,
    'Videos': 0.0,
    'Audio': 0.0,
    'Documents': 0.0,
    'Apps': 0.0,
    'Archives': 0.0,
    'Other': 0.0,
  };
  
  final dir = Directory(path);
  if (!await dir.exists()) return categories;

  await for (final entity in dir.list(recursive: true, followLinks: false)) {
    if (entity is File) {
      try {
        final size = (await entity.stat()).size.toDouble();
        final extension = p.extension(entity.path).toLowerCase();
        
        if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(extension)) {
          categories['Images'] = (categories['Images'] ?? 0) + size;
        } else if (['.mp4', '.mkv', '.avi', '.mov', '.wmv'].contains(extension)) {
          categories['Videos'] = (categories['Videos'] ?? 0) + size;
        } else if (['.mp3', '.wav', '.m4a', '.aac', '.ogg'].contains(extension)) {
          categories['Audio'] = (categories['Audio'] ?? 0) + size;
        } else if (['.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.txt'].contains(extension)) {
          categories['Documents'] = (categories['Documents'] ?? 0) + size;
        } else if (['.apk', '.aab'].contains(extension)) {
          categories['Apps'] = (categories['Apps'] ?? 0) + size;
        } else if (['.zip', '.rar', '.7z', '.tar', '.gz'].contains(extension)) {
          categories['Archives'] = (categories['Archives'] ?? 0) + size;
        } else {
          categories['Other'] = (categories['Other'] ?? 0) + size;
        }
      } catch (e) {
        // Ignore files that can't be accessed (e.g., permission errors on sub-dirs)
      }
    }
  }
  return categories;
}


// --- Controller ---
class AnalysisController extends StateNotifier<AnalysisState> {
  final StorageService _storageService = StorageService();

  AnalysisController() : super(AnalysisState()) {
    _startAnalysis();
  }

  Future<void> _startAnalysis() async {
    try {
      // 1. Get total and free space using our new service
      final total = await _storageService.getTotalDiskSpace();
      final free = await _storageService.getFreeDiskSpace();
      
      final initialCategories = _getInitialCategories();
      state = state.copyWith(
        isLoading: true, 
        totalSpace: total, // Already in Bytes
        freeSpace: free,   // Already in Bytes
        categories: initialCategories
      );

      // 2. Run heavy analysis in a background isolate
      const rootPath = '/storage/emulated/0';
      final categorySizes = await compute(_analyzeStorageInBackground, rootPath);
      
      // 3. Update state with final results
      final finalCategories = initialCategories.map((cat) {
        return cat.copyWith(sizeInBytes: categorySizes[cat.name] ?? 0.0);
      }).toList();

      finalCategories.sort((a, b) => b.sizeInBytes.compareTo(a.sizeInBytes));
      
      state = state.copyWith(isLoading: false, categories: finalCategories);

    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  List<StorageCategory> _getInitialCategories() {
    return [
      StorageCategory(name: 'Images', icon: Icons.image, color: Colors.blue),
      StorageCategory(name: 'Videos', icon: Icons.video_collection, color: Colors.red),
      StorageCategory(name: 'Audio', icon: Icons.audiotrack, color: Colors.orange),
      StorageCategory(name: 'Documents', icon: Icons.article, color: Colors.green),
      StorageCategory(name: 'Apps', icon: Icons.android, color: Colors.teal),
      StorageCategory(name: 'Archives', icon: Icons.archive, color: Colors.purple),
      StorageCategory(name: 'Other', icon: Icons.miscellaneous_services, color: Colors.grey),
    ];
  }
}

// --- Provider ---
final analysisProvider = StateNotifierProvider.autoDispose<AnalysisController, AnalysisState>((ref) {
  return AnalysisController();
});