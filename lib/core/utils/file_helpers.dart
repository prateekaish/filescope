import 'dart:math';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

String formatBytes(int bytes, int decimals) {
  if (bytes <= 0) return "0 B";
  const suffixes = ["B", "KB", "MB", "GB", "TB", "PB"];
  var i = (log(bytes) / log(1024)).floor();
  return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
}

// New helper function for file icons
IconData getIconForFile(String fileName) {
  final extension = p.extension(fileName).toLowerCase();
  switch (extension) {
    case '.jpg':
    case '.jpeg':
    case '.png':
    case '.gif':
    case '.bmp':
      return Icons.image_outlined;
    case '.mp4':
    case '.avi':
    case '.mov':
    case '.mkv':
      return Icons.movie_outlined;
    case '.mp3':
    case '.wav':
    case '.aac':
      return Icons.music_note_outlined;
    case '.pdf':
      return Icons.picture_as_pdf_outlined;
    case '.doc':
    case '.docx':
      return Icons.description_outlined;
    case '.xls':
    case '.xlsx':
      return Icons.table_chart_outlined;
    case '.ppt':
    case '.pptx':
      return Icons.slideshow_outlined;
    case '.zip':
    case '.rar':
    case '.7z':
      return Icons.archive_outlined;
    case '.txt':
      return Icons.text_snippet_outlined;
    case '.apk':
      return Icons.android_outlined;
    default:
      return Icons.insert_drive_file_outlined;
  }
}