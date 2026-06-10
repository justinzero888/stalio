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
import 'package:stalio/core/services/export_service.dart';
import 'package:stalio/core/services/database_service.dart';
import 'package:stalio/models/entry.dart';
import 'package:stalio/models/tag.dart';
import 'package:stalio/models/routine.dart';

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

  group('Phase 2: Backup Round-Trip', () {
    late Directory tempDir;
    late StorageService storage;
    late ExportService exportService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      tempDir = Directory.systemTemp.createTempSync('p2_backup_roundtrip_');
      final appDocDir = Directory('${tempDir.path}/docs')..createSync(recursive: true);
      PathProviderPlatform.instance = MockPathProvider(appDocDir.path);

      final db = await DatabaseService.createTestDatabase('${tempDir.path}/test.db');
      DatabaseService.setTestDatabase(db);

      storage = StorageService();
      await storage.init();
      exportService = ExportService(storage);
    });

    tearDown(() async {
      await DatabaseService.resetForTesting();
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('Create data → export ZIP → verify ZIP contents', () async {
      final tag = Tag(
        id: 't1', name: 'Test', nameEn: 'Test',
        color: '#FF0000', category: 'custom', createdAt: DateTime.now(),
      );
      await storage.addTag(tag);

      final routine = Routine(
        id: 'r1', name: 'Habit', nameEn: 'Habit', frequency: RoutineFrequency.daily,
        isActive: true, createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      await storage.addRoutine(routine);

      final entry = Entry(
        id: 'e1', type: EntryType.freeform, content: 'Hello world',
        emotion: '😊', tagIds: ['t1'],
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      await storage.addEntry(entry);

      final zipPath = await exportService.exportAll(
        docDirOverride: tempDir.path,
      );

      expect(File(zipPath).existsSync(), isTrue);
      expect(File(zipPath).lengthSync(), greaterThan(0));

      final bytes = File(zipPath).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);
      final fileNames = archive.map((f) => f.name).toList();

      expect(fileNames, contains('data.json'));
      expect(fileNames, contains('manifest.json'));

      final dataFile = archive.findFile('data.json')!;
      final dataStr = utf8.decode(dataFile.content as List<int>);
      final data = json.decode(dataStr) as Map<String, dynamic>;

      expect(data['entries'], isNotEmpty);
      expect(data['tags'], isNotEmpty);
      expect(data['routines'], isNotEmpty);
    });

    test('Export empty storage produces valid ZIP', () async {
      final zipPath = await exportService.exportAll(
        docDirOverride: tempDir.path,
      );

      expect(File(zipPath).existsSync(), isTrue);

      final bytes = File(zipPath).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      final dataFile = archive.findFile('data.json')!;
      final dataStr = utf8.decode(dataFile.content as List<int>);
      final data = json.decode(dataStr) as Map<String, dynamic>;

      expect(data['entries'], isNotEmpty); // seed entries exist
    });

    test('Restore ZIP imports data correctly', () async {
      final tag = Tag(
        id: 't_restore', name: 'RestoreTag', nameEn: 'RestoreTag',
        color: '#0000FF', category: 'custom', createdAt: DateTime.now(),
      );
      await storage.addTag(tag);

      final entry = Entry(
        id: 'e_restore', type: EntryType.freeform, content: 'Restored content',
        emotion: '😌', tagIds: ['t_restore'],
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      await storage.addEntry(entry);

      final zipPath = await exportService.exportAll(
        docDirOverride: tempDir.path,
      );

      await storage.deleteEntry('e_restore');
      await storage.deleteTag('t_restore');

      await storage.restoreFromBackup(File(zipPath));

      final restoredEntries = await storage.getEntries();
      final restoredTags = await storage.getTags();

      expect(restoredEntries.any((e) => e.id == 'e_restore'), isTrue);
      expect(restoredTags.any((t) => t.id == 't_restore'), isTrue);

      final restoredEntry = restoredEntries.firstWhere((e) => e.id == 'e_restore');
      expect(restoredEntry.content, 'Restored content');
      expect(restoredEntry.emotion, '😌');
    });

    test('Restore JSON file imports data correctly', () async {
      final tag = Tag(
        id: 't_json', name: 'JSON', nameEn: 'JSON',
        color: '#00FF00', category: 'custom', createdAt: DateTime.now(),
      );

      final jsonData = jsonEncode({
        'entries': [],
        'tags': [tag.toJson()],
        'routines': [],
      });

      final jsonPath = '${tempDir.path}/test_restore.json';
      File(jsonPath).writeAsStringSync(jsonData);

      await storage.restoreFromBackup(File(jsonPath));

      final restoredTags = await storage.getTags();
      expect(restoredTags.any((t) => t.id == 't_json'), isTrue);
    });
  });
}
