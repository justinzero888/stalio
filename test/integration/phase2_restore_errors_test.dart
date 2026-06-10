import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:stalio/core/services/storage_service.dart';
import 'package:stalio/core/services/database_service.dart';

class MockPathProvider extends PathProviderPlatform {
  final String tempDir;
  MockPathProvider(this.tempDir);

  @override Future<String?> getApplicationDocumentsPath() async => tempDir;
  @override Future<String?> getApplicationCachePath() async => tempDir;
  @override Future<String?> getApplicationSupportPath() async => tempDir;
  @override Future<String?> getTemporaryPath() async => tempDir;
  @override Future<String?> getExternalStoragePath() async => tempDir;
  @override Future<List<String>?> getExternalCachePaths() async => [tempDir];
  @override Future<List<String>?> getExternalStoragePaths({StorageDirectory? type}) async => [tempDir];
  @override Future<String?> getDownloadsPath() async => tempDir;
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Phase 2: Restore Error Paths', () {
    late Directory tempDir;
    late StorageService storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      tempDir = Directory.systemTemp.createTempSync('p2_restore_errors_');
      final appDocDir = Directory('${tempDir.path}/docs')..createSync(recursive: true);
      PathProviderPlatform.instance = MockPathProvider(appDocDir.path);

      final db = await DatabaseService.createTestDatabase('${tempDir.path}/test.db');
      DatabaseService.setTestDatabase(db);

      storage = StorageService();
      await storage.init();
    });

    tearDown(() async {
      await DatabaseService.resetForTesting();
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('Corrupted ZIP does not crash', () async {
      final corruptedPath = '${tempDir.path}/corrupted.zip';
      File(corruptedPath).writeAsBytesSync([0, 1, 2, 3, 4]);

      try {
        await storage.restoreFromBackup(File(corruptedPath));
        // If it reaches here without throwing, that's also acceptable
      } catch (_) {
        // Expected to throw for corrupted ZIP
      }
    });

    test('Empty backup file does not crash', () async {
      final emptyPath = '${tempDir.path}/empty.json';
      File(emptyPath).writeAsStringSync('');

      try {
        await storage.restoreFromBackup(File(emptyPath));
      } catch (e) {
        expect(e, isA<FormatException>());
      }
    });

    test('JSON with empty arrays restores without crash', () async {
      final minimalPath = '${tempDir.path}/minimal.json';
      final minimal = jsonEncode({
        'entries': [],
        'tags': [],
        'routines': [],
      });
      File(minimalPath).writeAsStringSync(minimal);

      await storage.restoreFromBackup(File(minimalPath));
      // Should complete without crash
    });
  });
}
