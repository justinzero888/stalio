import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as path_pkg;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../../models/entry.dart';
import '../../models/tag.dart';
import '../../models/routine.dart';
import '../utils/csv_utils.dart';
import 'file_service.dart';
import 'storage_service.dart';

class ExportData {
  // ... (ExportData class remains mostly the same, but let's ensure we have full content)
  final String version;
  final DateTime exportedAt;
  final String? userId;
  final List<Map<String, dynamic>> entries;
  final List<Map<String, dynamic>> tags;
  final List<Map<String, dynamic>> routines;

  ExportData({
    required this.version,
    required this.exportedAt,
    this.userId,
    required this.entries,
    required this.tags,
    required this.routines,
  });

  factory ExportData.fromEntriesAndTagsAndRoutines({
    required List<Entry> entries,
    required List<Tag> tags,
    required List<Routine> routines,
    String? userId,
  }) {
    return ExportData(
      version: AppConstants.exportVersion,
      exportedAt: DateTime.now(),
      userId: userId,
      entries: entries.map((e) => e.toJson()).toList(),
      tags: tags.map((t) => t.toJson()).toList(),
      routines: routines.map((r) => r.toJson()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'exportedAt': exportedAt.toIso8601String(),
      'userId': userId,
      'entries': entries,
      'tags': tags,
      'routines': routines,
    };
  }

  factory ExportData.fromJson(Map<String, dynamic> json) {
    return ExportData(
      version: (json['version'] ?? '1.0') as String,
      exportedAt: DateTime.parse((json['exportedAt'] ?? DateTime.now().toIso8601String()) as String),
      userId: json['userId'] as String?,
      entries: (json['entries'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>(),
      tags: (json['tags'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>(),
      routines: (json['routines'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>(),
    );
  }
}

class ExportService {
  final StorageService _storage;

  ExportService(this._storage);

  /// Export all data (JSON + Media) to a ZIP file.
  /// Set [excludeMedia] to true for a text-only backup (no photos/avatars).
  Future<String> exportAll({
    DateTime? startDate,
    DateTime? endDate,
    bool excludeMedia = false,
    void Function(double progress)? onProgress,
    /// [docDirOverride] is for testing only — overrides [getApplicationDocumentsDirectory].
    String? docDirOverride,
  }) async {
    final entries = await _storage.getEntries();
    final tags = await _storage.getTags();
    final routines = await _storage.getRoutines();

    List<Entry> filteredEntries = entries;
    if (startDate != null || endDate != null) {
      filteredEntries = entries.where((e) {
        if (startDate != null && e.createdAt.isBefore(startDate)) return false;
        if (endDate != null && e.createdAt.isAfter(endDate)) return false;
        return true;
      }).toList();
    }

    final exportData = ExportData.fromEntriesAndTagsAndRoutines(
      entries: filteredEntries,
      tags: tags,
      routines: routines,
    );

    final docDir = docDirOverride != null
        ? Directory(docDirOverride)
        : await getApplicationDocumentsDirectory();
    // Delete any leftover backup ZIPs from previous runs to prevent storage bloat
    await for (final entity in docDir.list()) {
      if (entity is File &&
          path_pkg.basename(entity.path).startsWith('blinking_backup_') &&
          entity.path.endsWith('.zip')) {
        try { await entity.delete(); } catch (_) {}
      }
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = path_pkg.join(docDir.path, 'blinking_backup_$timestamp.zip');

    final zipEncoder = ZipFileEncoder();
    zipEncoder.create(filePath);
    try {
      // 1. Add data.json (small — kept in memory)
      final jsonStr = const JsonEncoder.withIndent('  ').convert(exportData.toJson());
      final jsonBytes = utf8.encode(jsonStr);
      zipEncoder.addArchiveFile(ArchiveFile('data.json', jsonBytes.length, jsonBytes));

      // 2. Add manifest.json (small — kept in memory)
      final manifest = {
        'exportedAt': exportData.exportedAt.toIso8601String(),
        'version': exportData.version,
        'entriesCount': filteredEntries.length,
        'tagsCount': tags.length,
        'routinesCount': routines.length,
        'hasMedia': !excludeMedia,
        'hasPersona': true,
      };
      final manifestBytes = utf8.encode(jsonEncode(manifest));
      zipEncoder.addArchiveFile(ArchiveFile('manifest.json', manifestBytes.length, manifestBytes));

      // 3. Add AI persona settings
      final prefs = await SharedPreferences.getInstance();
      final personaName = prefs.getString('ai_assistant_name');
      final personaPersonality = prefs.getString('ai_assistant_personality');
      final avatarPath = prefs.getString('ai_avatar_path');
      final personaMap = <String, dynamic>{};
      if (personaName != null) personaMap['ai_assistant_name'] = personaName;
      if (personaPersonality != null) personaMap['ai_assistant_personality'] = personaPersonality;
      if (avatarPath != null) {
        final avatarFile = File(avatarPath);
        if (await avatarFile.exists()) {
          final avatarBasename = path_pkg.basename(avatarPath);
          personaMap['ai_avatar_zip_path'] = 'avatar/$avatarBasename';
          await zipEncoder.addFile(avatarFile, 'avatar/$avatarBasename');
        }
      }
      if (personaMap.isNotEmpty) {
        final personaBytes = utf8.encode(jsonEncode(personaMap));
        zipEncoder.addArchiveFile(ArchiveFile('persona.json', personaBytes.length, personaBytes));
      }

      // 4. Add media files — pre-scan sizes, compress, stream one at a time, report progress
      if (!excludeMedia) {
        int totalBytes = 0;
        final mediaDir = Directory(path_pkg.join(docDir.path, 'media'));
        if (await mediaDir.exists()) {
          // Collect media URLs from filtered entries when date range is active
          final referencedMediaUrls = <String>{};
          if (startDate != null || endDate != null) {
            for (final entry in filteredEntries) {
              referencedMediaUrls.addAll(entry.mediaUrls);
            }
          }

          final entities = await mediaDir.list(recursive: true).toList();
          final mediaFiles = entities.whereType<File>().toList();

          // Pre-scan: collect files and their sizes (use original size for progress)
          final fileSizes = <String, int>{};
          for (final f in mediaFiles) {
            final relativePath = path_pkg.relative(f.path, from: docDir.path);
            if (startDate != null || endDate != null) {
              if (!referencedMediaUrls.contains(relativePath)) continue;
            }
            fileSizes[f.path] = await f.length();
            totalBytes += fileSizes[f.path]!;
          }

          int bytesProcessed = 0;
          for (final file in mediaFiles) {
            final relativePath = path_pkg.relative(file.path, from: docDir.path);
            if (startDate != null || endDate != null) {
              if (!referencedMediaUrls.contains(relativePath)) continue;
            }
            final fileSize = fileSizes[file.path] ?? 0;
            final ext = path_pkg.extension(file.path).toLowerCase();
            final isImage = [
              '.jpg', '.jpeg', '.png', '.heic', '.heif', '.webp', '.bmp'
            ].contains(ext);

            if (isImage) {
              final compressed = await FileService.compressImage(file.path);
              if (compressed != null) {
                await zipEncoder.addFile(compressed, relativePath);
                try { await compressed.delete(); } catch (_) {}
              } else {
                await zipEncoder.addFile(file, relativePath);
              }
            } else {
              await zipEncoder.addFile(file, relativePath);
            }
            bytesProcessed += fileSize;
            if (totalBytes > 0) {
              onProgress?.call(bytesProcessed / totalBytes);
            }
          }
        }

        // Signal 100% only when no media was present (loop already emitted 1.0 otherwise)
        if (totalBytes == 0) onProgress?.call(1.0);
      } else {
        onProgress?.call(1.0);
      }

      await zipEncoder.close();
      return filePath;
    } catch (e) {
      try { await zipEncoder.close(); } catch (_) {}
      final partial = File(filePath);
      if (await partial.exists()) await partial.delete();
      rethrow;
    }
  }

  /// Export data as CSV (returns file path)
  Future<String> exportCsv({bool exportEntries = true, bool exportRoutines = true}) async {
    final docDir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final archive = Archive();

    if (exportEntries) {
      final entries = await _storage.getEntries();
      final csvData = entries.map((e) {
        final map = e.toJson();
        // Flatten simple fields for CSV readability
        map['tagIds'] = e.tagIds.join('|');
        map['mediaUrls'] = e.mediaUrls.join('|');
        return map;
      }).toList();
      final csvString = CsvUtils.mapListToCsv(csvData);
      final csvBytes = utf8.encode(csvString);
      archive.addFile(ArchiveFile('entries.csv', csvBytes.length, csvBytes));
    }

    if (exportRoutines) {
      final routines = await _storage.getRoutines();
      final csvData = routines.map((r) {
        final map = r.toJson();
        // Skip completionLog for flat routine CSV, maybe add separate one?
        map.remove('completionLog');
        return map;
      }).toList();
      final csvString = CsvUtils.mapListToCsv(csvData);
      final csvBytes = utf8.encode(csvString);
      archive.addFile(ArchiveFile('routines.csv', csvBytes.length, csvBytes));
    }

    final zipData = ZipEncoder().encode(archive);
    final filePath = path_pkg.join(docDir.path, 'blinking_export_csv_$timestamp.zip');
    final file = File(filePath);
    await file.writeAsBytes(zipData);
    
    return filePath;
  }

  /// Export only JSON data as a file
  Future<String> exportJsonFile() async {
    final entries = await _storage.getEntries();
    final tags = await _storage.getTags();
    final routines = await _storage.getRoutines();

    final exportData = ExportData.fromEntriesAndTagsAndRoutines(
      entries: entries,
      tags: tags,
      routines: routines,
    );

    final jsonStr = const JsonEncoder.withIndent('  ').convert(exportData.toJson());
    final docDir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = path_pkg.join(docDir.path, 'blinking_data_$timestamp.json');
    final file = File(filePath);
    await file.writeAsString(jsonStr);

    return filePath;
  }

  /// Share a file using the system share sheet
  Future<void> shareFile(String filePath, {String? subject, String? text}) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath)],
        subject: subject,
        text: text,
        sharePositionOrigin: const Rect.fromLTWH(0, 0, 1, 1),
      ),
    );
  }

  /// Import data from JSON
  Future<void> importFromJson(String jsonStr) async {
    final Map<String, dynamic> data = jsonDecode(jsonStr);
    final exportData = ExportData.fromJson(data);

    // Filter out duplicates if needed, but saveData usually handles conflict replace
    final tags = exportData.tags.map((t) => Tag.fromJson(t)).toList();
    for (final tag in tags) {
      await _storage.addTag(tag);
    }

    final routines = exportData.routines.map((r) => Routine.fromJson(r)).toList();
    for (final routine in routines) {
      await _storage.addRoutine(routine);
    }

    final entries = exportData.entries.map((e) => Entry.fromJson(e)).toList();
    for (final entry in entries) {
      await _storage.addEntry(entry);
    }
  }
}