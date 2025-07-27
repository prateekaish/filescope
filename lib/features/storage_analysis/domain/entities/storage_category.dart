import 'package:flutter/material.dart';

class StorageCategory {
  final String name;
  final IconData icon;
  final Color color;
  final double sizeInBytes;

  StorageCategory({
    required this.name,
    required this.icon,
    required this.color,
    this.sizeInBytes = 0.0,
  });

  StorageCategory copyWith({
    double? sizeInBytes,
  }) {
    return StorageCategory(
      name: name,
      icon: icon,
      color: color,
      sizeInBytes: sizeInBytes ?? this.sizeInBytes,
    );
  }
}