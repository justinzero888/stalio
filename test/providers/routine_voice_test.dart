import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:blinking/core/services/storage_service.dart';
import 'package:blinking/core/services/database_service.dart';
import 'package:blinking/models/routine.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _MockPathProvider extends PathProviderPlatform {
  final String path;
  _MockPathProvider(this.path);

  @override
  Future<String?> getApplicationDocumentsPath() async => path;
  @override
  Future<String?> getApplicationCachePath() async => path;
  @override
  Future<String?> getApplicationSupportPath() async => path;
  @override
  Future<String?> getTemporaryPath() async => path;
  @override
  Future<String?> getExternalStoragePath() async => path;
  @override
  Future<List<String>?> getExternalCachePaths() async => [path];
  @override
  Future<List<String>?> getExternalStoragePaths({StorageDirectory? type}) async => [path];
  @override
  Future<String?> getDownloadsPath() async => path;
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Voice notification — DB persistence', () {
    late StorageService storage;
    late Directory tempDir;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      tempDir = Directory.systemTemp.createTempSync('voice_db_test_');
      final appDocDir = Directory('${tempDir.path}/app_docs')..createSync(recursive: true);
      PathProviderPlatform.instance = _MockPathProvider(appDocDir.path);

      final db = await DatabaseService.createTestDatabase('${tempDir.path}/test.db');
      DatabaseService.setTestDatabase(db);

      storage = StorageService();
      await storage.init();
    });

    tearDown(() async {
      await DatabaseService.resetForTesting();
      tempDir.deleteSync(recursive: true);
    });

    test('routine with voiceEnabled=true persists and reads back', () async {
      final routine = Routine(
        id: 'voice_test_1',
        name: 'Voice Test',
        nameEn: 'Voice Test',
        frequency: RoutineFrequency.daily,
        reminderTime: '08:00',
        voiceEnabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await storage.addRoutine(routine);

      final routines = await storage.getRoutines();
      final persisted = routines.firstWhere((r) => r.id == 'voice_test_1');
      expect(persisted.voiceEnabled, isTrue);
    });

    test('routine with voiceEnabled=false persists and reads back', () async {
      final routine = Routine(
        id: 'voice_test_2',
        name: 'Silent Test',
        nameEn: 'Silent Test',
        frequency: RoutineFrequency.daily,
        reminderTime: '21:00',
        voiceEnabled: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await storage.addRoutine(routine);

      final routines = await storage.getRoutines();
      final persisted = routines.firstWhere((r) => r.id == 'voice_test_2');
      expect(persisted.voiceEnabled, isFalse);
    });

    test('updating routine preserves voiceEnabled', () async {
      final routine = Routine(
        id: 'voice_test_3',
        name: 'Update Test',
        nameEn: 'Update Test',
        frequency: RoutineFrequency.daily,
        reminderTime: '10:00',
        voiceEnabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await storage.addRoutine(routine);

      final updated = routine.copyWith(
        name: 'Updated Name',
        nameEn: 'Updated Name',
        updatedAt: DateTime.now(),
      );
      await storage.addRoutine(updated);

      final routines = await storage.getRoutines();
      final persisted = routines.firstWhere((r) => r.id == 'voice_test_3');
      expect(persisted.voiceEnabled, isTrue);
      expect(persisted.name, 'Updated Name');
    });

    test('routine defaults voiceEnabled to false', () async {
      final routine = Routine(
        id: 'voice_test_4',
        name: 'Default Test',
        nameEn: 'Default Test',
        frequency: RoutineFrequency.daily,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await storage.addRoutine(routine);

      final routines = await storage.getRoutines();
      final persisted = routines.firstWhere((r) => r.id == 'voice_test_4');
      expect(persisted.voiceEnabled, isFalse);
    });
  });
}
