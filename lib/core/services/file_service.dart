import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path_pkg;
import 'package:uuid/uuid.dart';

/// Service to handle persistent file storage in the app's internal directory.
class FileService {
  static final FileService _instance = FileService._internal();
  factory FileService() => _instance;
  FileService._internal();

  final _uuid = const Uuid();

  static const _maxDimension = 1920;
  static const _jpegQuality = 85;

  static Future<File?> compressImage(String sourcePath) async {
    try {
      final result = await FlutterImageCompress.compressAndGetFile(
        sourcePath,
        '$sourcePath._compressed.jpg',
        quality: _jpegQuality,
        format: CompressFormat.jpeg,
        minWidth: _maxDimension,
        minHeight: _maxDimension,
      );
      if (result != null) {
        return File(result.path);
      }
    } catch (_) {}
    return null;
  }

  /// Save a file to the app's internal documents directory.
  /// Images are compressed to max 1920px, JPEG quality 85.
  /// Returns the relative path (usually just the filename) within the documents directory.
  Future<String> saveFile(String sourcePath) async {
    final File sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw Exception('Source file does not exist: $sourcePath');
    }

    final directory = await getApplicationDocumentsDirectory();
    final mediaDir = Directory(path_pkg.join(directory.path, 'media'));
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }

    final String extension = path_pkg.extension(sourcePath).toLowerCase();
    final bool isImage = ['.jpg', '.jpeg', '.png', '.heic', '.heif', '.webp', '.bmp']
        .contains(extension);

    final String fileName = '${_uuid.v4()}.jpg';
    final String targetPath = path_pkg.join(mediaDir.path, fileName);

    if (isImage) {
      final compressed = await compressImage(sourcePath);
      if (compressed != null) {
        await compressed.copy(targetPath);
        try { await compressed.delete(); } catch (_) {}
        return path_pkg.join('media', fileName);
      }
    }

    final String fallbackName = '${_uuid.v4()}$extension';
    final String fallbackPath = path_pkg.join(mediaDir.path, fallbackName);
    await sourceFile.copy(fallbackPath);
    return path_pkg.join('media', fallbackName);
  }

  /// Get the full absolute path from a relative path.
  Future<String> getFullPath(String relativePath) async {
    final directory = await getApplicationDocumentsDirectory();
    return path_pkg.join(directory.path, relativePath);
  }

  /// Delete a file given its relative path.
  Future<void> deleteFile(String relativePath) async {
    final fullPath = await getFullPath(relativePath);
    final file = File(fullPath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Check if a relative path points to a file that exists.
  Future<bool> fileExists(String relativePath) async {
    final fullPath = await getFullPath(relativePath);
    return await File(fullPath).exists();
  }
}
