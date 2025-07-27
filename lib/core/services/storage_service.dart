import 'package:flutter/services.dart';

class StorageService {
  static const _channel = MethodChannel('com.filescope/storage');

  Future<double> getTotalDiskSpace() async {
    try {
      final double totalSpace = await _channel.invokeMethod('getTotalDiskSpace');
      return totalSpace;
    } on PlatformException catch (e) {
      print("Failed to get total disk space: '${e.message}'.");
      return 0.0;
    }
  }

  Future<double> getFreeDiskSpace() async {
    try {
      final double freeSpace = await _channel.invokeMethod('getFreeDiskSpace');
      return freeSpace;
    } on PlatformException catch (e) {
      print("Failed to get free disk space: '${e.message}'.");
      return 0.0;
    }
  }
}