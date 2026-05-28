import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:archive/archive_io.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:blinking/core/services/storage_service.dart';

/// Mock PathProvider for testing
class MockPathProvider extends PathProviderPlatform {
  final String tempDir;

  MockPathProvider(this.tempDir);

  @override
  Future<String?> getApplicationDocumentsPath() async => tempDir;

  @override
  Future<String?> getApplicationCachePath() async => tempDir;

  @override
  Future<String?> getApplicationSupportPath() async => tempDir;

  @override
  Future<String?> getTemporaryPath() async => tempDir;

  @override
  Future<String?> getExternalStoragePath() async => tempDir;

  @override
  Future<List<String>?> getExternalCachePaths() async => [tempDir];

  @override
  Future<List<String>?> getExternalStoragePaths({
    StorageDirectory? type,
  }) async => [tempDir];

  @override
  Future<String?> getDownloadsPath() async => tempDir;
}

/// Minimal test storage for testing restore without full platform initialization
class _TestableStorageService extends StorageService {
  @override
  Future<void> init() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Restore Progress Integration Tests', () {
    late Directory tempDir;
    late Directory appDocDir;
    late File backupFile;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      tempDir = Directory.systemTemp.createTempSync('restore_integration_test_');
      appDocDir = Directory('${tempDir.path}/app_docs');
      appDocDir.createSync(recursive: true);

      // Mock the PathProvider to return our temp directory
      PathProviderPlatform.instance = MockPathProvider(appDocDir.path);

      // Create a test backup ZIP file with media and data
      final archive = Archive();

      // Create minimal valid data.json
      final exportData = {
        'version': '1.0.0',
        'exportedAt': DateTime.now().toIso8601String(),
        'userId': null,
        'entries': [],
        'tags': [],
        'routines': [],
        'note_cards': [],
        'card_folders': [],
        'templates': [],
      };

      final dataJson = jsonEncode(exportData);
      archive.addFile(ArchiveFile(
        'data.json',
        dataJson.length,
        utf8.encode(dataJson),
      ));

      // Add 3 media files to trigger multiple progress updates
      for (int i = 0; i < 3; i++) {
        final mediaContent = List<int>.filled(1024, 42 + i);
        archive.addFile(ArchiveFile(
          'media/test_image_$i.jpg',
          mediaContent.length,
          mediaContent,
        ));
      }

      // Create the ZIP file
      backupFile = File('${tempDir.path}/test_backup.zip');
      final zipBytes = ZipEncoder().encode(archive);
      backupFile.writeAsBytesSync(zipBytes);
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('Restore progress callback is invoked with monotonic values',
        () async {
      final storage = _TestableStorageService();

      final progressValues = <double>[];
      await storage.restoreFromBackup(
        backupFile,
        onProgress: (progress) {
          progressValues.add(progress);
        },
      );

      // Verify progress was called at least once
      expect(progressValues, isNotEmpty,
          reason: 'Progress callback should be called for ZIP with media');

      // Verify final progress is exactly 1.0 (100% complete)
      expect(progressValues.last, equals(1.0),
          reason: 'Final progress should be 1.0');

      // Verify monotonic increase (progress never decreases)
      for (int i = 1; i < progressValues.length; i++) {
        expect(progressValues[i], greaterThanOrEqualTo(progressValues[i - 1]),
            reason: 'Progress values should be monotonically increasing');
      }
    });

    test('Restore extracts media files correctly during restore',
        () async {
      final storage = _TestableStorageService();

      final progressValues = <double>[];
      await storage.restoreFromBackup(
        backupFile,
        onProgress: (progress) {
          progressValues.add(progress);
        },
      );

      // With 3 media files, we should have 3 progress updates
      expect(progressValues.length, equals(3),
          reason: 'Should have progress update for each media file');

      // Progress should be: 1/3, 2/3, 3/3 (i.e., 1.0)
      expect(progressValues[0], closeTo(1.0 / 3.0, 0.01));
      expect(progressValues[1], closeTo(2.0 / 3.0, 0.01));
      expect(progressValues[2], 1.0);

      // Verify all media files were extracted
      for (int i = 0; i < 3; i++) {
        final extractedMedia =
            File('${appDocDir.path}/media/test_image_$i.jpg');
        expect(extractedMedia.existsSync(), isTrue,
            reason: 'Media file $i should be extracted from backup');
      }
    });

    test('Restore completes without crash when no callback provided',
        () async {
      final storage = _TestableStorageService();

      // Call without onProgress callback — should not crash
      expect(
        () => storage.restoreFromBackup(backupFile),
        returnsNormally,
      );

      // Restore should complete successfully
      // Note: Media extraction still happens, but progress is not tracked
    });

    test('Restore progress updates happen during file extraction',
        () async {
      final storage = _TestableStorageService();

      final updates = <DateTime>[];
      await storage.restoreFromBackup(
        backupFile,
        onProgress: (progress) {
          updates.add(DateTime.now());
        },
      );

      // We should have multiple progress updates (one per file)
      expect(updates.length, greaterThanOrEqualTo(1),
          reason: 'Should have at least one progress update');

      // Updates should happen in order
      for (int i = 1; i < updates.length; i++) {
        expect(
          updates[i].isAfter(updates[i - 1]) ||
              updates[i].isAtSameMomentAs(updates[i - 1]),
          isTrue,
          reason: 'Progress updates should be in chronological order',
        );
      }
    });

    test('Restore progress ends at exactly 100%', () async {
      final storage = _TestableStorageService();

      final progressValues = <double>[];
      await storage.restoreFromBackup(
        backupFile,
        onProgress: (progress) {
          progressValues.add(progress);
        },
      );

      // Final progress value must be exactly 1.0
      expect(progressValues.last, equals(1.0),
          reason: 'Restore must complete with 100% progress');

      // Percentage should never exceed 100%
      for (final p in progressValues) {
        expect(p, lessThanOrEqualTo(1.0),
            reason: 'Progress percentage should never exceed 100%');
      }
    });
  });
}
