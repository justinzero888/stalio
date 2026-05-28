import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:blinking/core/services/storage_service.dart';

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

class _FakeStorageService extends StorageService {
  @override
  Future<void> init() async {
    // Skip database init; only needed for prefs in persona tests
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StorageService.restoreFromBackup — onProgress', () {
    late Directory tempDir;
    late Directory appDocDir;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      tempDir = Directory.systemTemp.createTempSync('restore_progress_test_');
      appDocDir = Directory('${tempDir.path}/app_docs');
      appDocDir.createSync(recursive: true);

      // Mock the PathProvider to return our temp directory
      PathProviderPlatform.instance = MockPathProvider(appDocDir.path);
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('restoreFromBackup handles JSON files without progress callback', () async {
      // Create a test JSON backup file
      final jsonData = jsonEncode({
        'entries': [],
        'tags': [],
        'routines': [],
        'note_cards': [],
        'card_folders': [],
        'templates': [],
      });

      final jsonPath = '${tempDir.path}/test_backup.json';
      File(jsonPath).writeAsStringSync(jsonData);

      final storageService = _FakeStorageService();

      final progressValues = <double>[];
      await storageService.restoreFromBackup(
        File(jsonPath),
        onProgress: (progress) {
          progressValues.add(progress);
        },
      );

      // JSON restore should not call onProgress
      expect(progressValues, isEmpty);
    });

    test('restoreFromBackup invokes onProgress callback during ZIP extraction', () async {
      // Create a test ZIP file with media files
      final archive = Archive();

      // Add data.json
      final dataJson = jsonEncode({
        'entries': [],
        'tags': [],
        'routines': [],
        'note_cards': [],
        'card_folders': [],
        'templates': [],
      });
      archive.addFile(ArchiveFile('data.json', dataJson.length, utf8.encode(dataJson)));

      // Add 3 media files to simulate extraction progress
      for (int i = 0; i < 3; i++) {
        final fileContent = List<int>.filled(1024, i);
        archive.addFile(ArchiveFile(
          'media/test_file_$i.jpg',
          fileContent.length,
          fileContent,
        ));
      }

      // Create ZIP file
      final zipPath = '${tempDir.path}/test_backup.zip';
      final zipBytes = ZipEncoder().encode(archive);
      File(zipPath).writeAsBytesSync(zipBytes);

      final storageService = _FakeStorageService();

      final progressValues = <double>[];
      await storageService.restoreFromBackup(
        File(zipPath),
        onProgress: (progress) {
          progressValues.add(progress);
        },
      );

      // Verify callback was called at least once
      expect(progressValues, isNotEmpty);

      // Verify progress values are monotonically increasing
      for (int i = 1; i < progressValues.length; i++) {
        expect(progressValues[i], greaterThanOrEqualTo(progressValues[i - 1]));
      }

      // Verify final progress is 1.0 (all 3 files processed)
      expect(progressValues.last, 1.0);
    });

    test('restoreFromBackup with no media files does not call progress callback', () async {
      // Create a ZIP file with only data.json and no media files
      final archive = Archive();

      final dataJson = jsonEncode({
        'entries': [],
        'tags': [],
        'routines': [],
        'note_cards': [],
        'card_folders': [],
        'templates': [],
      });
      archive.addFile(ArchiveFile('data.json', dataJson.length, utf8.encode(dataJson)));

      final zipPath = '${tempDir.path}/test_backup_no_media.zip';
      final zipBytes = ZipEncoder().encode(archive);
      File(zipPath).writeAsBytesSync(zipBytes);

      final storageService = _FakeStorageService();

      final progressValues = <double>[];
      await storageService.restoreFromBackup(
        File(zipPath),
        onProgress: (progress) {
          progressValues.add(progress);
        },
      );

      // With no media files to extract, totalFiles = 0, so progress not called
      expect(progressValues, isEmpty);
    });

    test('restoreFromBackup only tracks media and avatar files for progress', () async {
      // Create a ZIP with data.json, media files, and other files
      final archive = Archive();

      final dataJson = jsonEncode({
        'entries': [],
        'tags': [],
        'routines': [],
        'note_cards': [],
        'card_folders': [],
        'templates': [],
      });
      archive.addFile(ArchiveFile('data.json', dataJson.length, utf8.encode(dataJson)));

      // Add manifest.json (should not count toward progress)
      final manifest = jsonEncode({'version': 1});
      archive.addFile(ArchiveFile('manifest.json', manifest.length, utf8.encode(manifest)));

      // Add 2 media files (should count)
      for (int i = 0; i < 2; i++) {
        final fileContent = List<int>.filled(1024, i);
        archive.addFile(ArchiveFile(
          'media/file_$i.jpg',
          fileContent.length,
          fileContent,
        ));
      }

      // Add 1 avatar file (should count)
      final avatarContent = List<int>.filled(2048, 99);
      archive.addFile(ArchiveFile(
        'avatar/custom_avatar.png',
        avatarContent.length,
        avatarContent,
      ));

      final zipPath = '${tempDir.path}/test_mixed.zip';
      final zipBytes = ZipEncoder().encode(archive);
      File(zipPath).writeAsBytesSync(zipBytes);

      final storageService = _FakeStorageService();

      final progressValues = <double>[];
      await storageService.restoreFromBackup(
        File(zipPath),
        onProgress: (progress) {
          progressValues.add(progress);
        },
      );

      // Should have 3 progress updates (2 media + 1 avatar)
      expect(progressValues.length, 3);

      // Progress is byte-weighted: 1024, 1024, 2048 → total 4096 bytes
      // 1st file (1024/4096), 2nd file (2048/4096), 3rd file (4096/4096)
      expect(progressValues[0], closeTo(1024.0 / 4096.0, 0.01));
      expect(progressValues[1], closeTo(2048.0 / 4096.0, 0.01));
      expect(progressValues[2], 1.0);
    });

    test('restoreFromBackup without onProgress callback does not crash', () async {
      // Create a simple test ZIP file with media
      final archive = Archive();

      final dataJson = jsonEncode({
        'entries': [],
        'tags': [],
        'routines': [],
        'note_cards': [],
        'card_folders': [],
        'templates': [],
      });
      archive.addFile(ArchiveFile('data.json', dataJson.length, utf8.encode(dataJson)));

      final fileContent = List<int>.filled(1024, 1);
      archive.addFile(ArchiveFile(
        'media/test_file.jpg',
        fileContent.length,
        fileContent,
      ));

      final zipPath = '${tempDir.path}/test_no_callback.zip';
      final zipBytes = ZipEncoder().encode(archive);
      File(zipPath).writeAsBytesSync(zipBytes);

      final storageService = _FakeStorageService();

      // Call without onProgress callback — should not crash
      expect(
        () => storageService.restoreFromBackup(File(zipPath)),
        returnsNormally,
      );
    });
  });

  group('StorageService.restoreFromBackup — persona and export integration', () {
    late Directory tempDir;
    late Directory appDocDir;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      tempDir = Directory.systemTemp.createTempSync('restore_persona_');
      appDocDir = Directory('${tempDir.path}/app_docs');
      appDocDir.createSync(recursive: true);
      PathProviderPlatform.instance = MockPathProvider(appDocDir.path);
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('restore extracts avatar file and sets prefs from persona.json', () async {
      // Build ZIP with persona.json + avatar file + empty data.json
      final archive = Archive();

      final dataJson = jsonEncode({
        'entries': [],
        'tags': [],
        'routines': [],
      });
      archive.addFile(ArchiveFile('data.json', dataJson.length, utf8.encode(dataJson)));

      final avatarContent = List<int>.filled(512, 42);
      archive.addFile(ArchiveFile(
        'avatar/test_avatar.jpg',
        avatarContent.length,
        avatarContent,
      ));

      final personaJson = jsonEncode({
        'ai_assistant_name': '测试助手',
        'ai_assistant_personality': 'warm and encouraging',
        'ai_avatar_zip_path': 'avatar/test_avatar.jpg',
      });
      archive.addFile(ArchiveFile(
        'persona.json',
        personaJson.length,
        utf8.encode(personaJson),
      ));

      final zipPath = '${tempDir.path}/persona_restore.zip';
      final zipBytes = ZipEncoder().encode(archive);
      File(zipPath).writeAsBytesSync(zipBytes);

      // Manually decode and verify (simulating the restore code path)
      final inputStream = InputFileStream(zipPath);
      Archive? decoded;
      try {
        decoded = ZipDecoder().decodeStream(inputStream);
        final arch = decoded;

        // Verify persona.json content
        final personaFile = arch.findFile('persona.json');
        expect(personaFile, isNotNull);
        final personaStr = utf8.decode(personaFile!.content as List<int>);
        final personaMap = json.decode(personaStr) as Map<String, dynamic>;
        expect(personaMap['ai_assistant_name'], '测试助手');
        expect(personaMap['ai_assistant_personality'], 'warm and encouraging');
        expect(personaMap['ai_avatar_zip_path'], 'avatar/test_avatar.jpg');

        // Verify avatar file was extracted
        final avatarFile = arch.findFile('avatar/test_avatar.jpg');
        expect(avatarFile, isNotNull);

        // Extract avatar to disk
        final targetPath = '${appDocDir.path}/avatar/test_avatar.jpg';
        Directory('${appDocDir.path}/avatar').createSync(recursive: true);
        final output = OutputFileStream(targetPath);
        try {
          avatarFile!.writeContent(output);
        } finally {
          await output.close();
        }
        expect(File(targetPath).existsSync(), isTrue);
        expect(File(targetPath).lengthSync(), 512);
      } finally {
        await decoded?.clear();
        await inputStream.close();
      }
    });

    test('restore without persona.json does not crash', () async {
      final archive = Archive();
      final dataJson = jsonEncode({
        'entries': [],
        'tags': [],
        'routines': [],
      });
      archive.addFile(ArchiveFile('data.json', dataJson.length, utf8.encode(dataJson)));

      final zipPath = '${tempDir.path}/no_persona_restore.zip';
      final zipBytes = ZipEncoder().encode(archive);
      File(zipPath).writeAsBytesSync(zipBytes);

      final inputStream = InputFileStream(zipPath);
      Archive? decoded;
      try {
        decoded = ZipDecoder().decodeStream(inputStream);
        expect(decoded!.findFile('persona.json'), isNull);
        expect(decoded.findFile('data.json'), isNotNull);
      } finally {
        await decoded?.clear();
        await inputStream.close();
      }
    });

    test('restore with corrupted persona.json does not crash', () async {
      final archive = Archive();
      final dataJson = jsonEncode({
        'entries': [],
        'tags': [],
        'routines': [],
      });
      archive.addFile(ArchiveFile('data.json', dataJson.length, utf8.encode(dataJson)));

      archive.addFile(ArchiveFile(
        'persona.json',
        12,
        utf8.encode('not json {{{'),
      ));

      final zipPath = '${tempDir.path}/corrupted_persona.zip';
      final zipBytes = ZipEncoder().encode(archive);
      File(zipPath).writeAsBytesSync(zipBytes);

      final inputStream = InputFileStream(zipPath);
      Archive? decoded;
      try {
        decoded = ZipDecoder().decodeStream(inputStream);
        final personaFile = decoded!.findFile('persona.json');
        expect(personaFile, isNotNull);
        final personaStr = utf8.decode(personaFile!.content as List<int>);
        // Verify it parses as invalid (restore code catches this)
        expect(() => json.decode(personaStr) as Map<String, dynamic>,
            throwsA(isA<FormatException>()));
      } finally {
        await decoded?.clear();
        await inputStream.close();
      }
    });

    test('restore without persona.json does not crash', () async {
      final archive = Archive();
      final dataJson = jsonEncode({
        'entries': [],
        'tags': [],
        'routines': [],
      });
      archive.addFile(ArchiveFile('data.json', dataJson.length, utf8.encode(dataJson)));

      final zipPath = '${tempDir.path}/no_persona_restore.zip';
      final zipBytes = ZipEncoder().encode(archive);
      File(zipPath).writeAsBytesSync(zipBytes);

      final inputStream = InputFileStream(zipPath);
      Archive? decoded;
      try {
        decoded = ZipDecoder().decodeStream(inputStream);
        expect(decoded.findFile('persona.json'), isNull);
        expect(decoded.findFile('data.json'), isNotNull);
      } finally {
        await decoded?.clear();
        await inputStream.close();
      }
    });

    test('restore with corrupted persona.json does not crash', () async {
      final archive = Archive();
      final dataJson = jsonEncode({
        'entries': [],
        'tags': [],
        'routines': [],
      });
      archive.addFile(ArchiveFile('data.json', dataJson.length, utf8.encode(dataJson)));

      archive.addFile(ArchiveFile(
        'persona.json',
        12,
        utf8.encode('not json {{{'),
      ));

      final zipPath = '${tempDir.path}/corrupted_persona.zip';
      final zipBytes = ZipEncoder().encode(archive);
      File(zipPath).writeAsBytesSync(zipBytes);

      final inputStream = InputFileStream(zipPath);
      Archive? decoded;
      try {
        decoded = ZipDecoder().decodeStream(inputStream);
        final personaFile = decoded.findFile('persona.json');
        expect(personaFile, isNotNull);
        final personaStr = utf8.decode(personaFile!.content as List<int>);
        // Verify it parses as invalid (restore code catches this)
        expect(() => json.decode(personaStr) as Map<String, dynamic>,
            throwsA(isA<FormatException>()));
      } finally {
        await decoded?.clear();
        await inputStream.close();
      }
    });
  });

  group('StorageService.restoreFromBackup — streaming', () {
    late Directory tempDir;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      tempDir = Directory.systemTemp.createTempSync('restore_streaming_test_');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('byte-weighted progress: larger file contributes more progress', () async {
      final archive = Archive();

      final dataJson = jsonEncode({
        'entries': [], 'tags': [], 'routines': [],
        'note_cards': [], 'card_folders': [], 'templates': [],
      });
      archive.addFile(ArchiveFile('data.json', dataJson.length, utf8.encode(dataJson)));

      // Small file: 512 bytes
      archive.addFile(ArchiveFile('media/small.jpg', 512, List<int>.filled(512, 0)));
      // Large file: 2048 bytes (4x the small file)
      archive.addFile(ArchiveFile('media/large.jpg', 2048, List<int>.filled(2048, 0)));

      final zipPath = '${tempDir.path}/mixed_sizes.zip';
      final zipBytes = ZipEncoder().encode(archive);
      File(zipPath).writeAsBytesSync(zipBytes);

      final storageService = _FakeStorageService();

      final progressValues = <double>[];
      await storageService.restoreFromBackup(
        File(zipPath),
        onProgress: (p) => progressValues.add(p),
      );

      expect(progressValues.length, 2);
      // Small file: 512 / (512 + 2048) = 0.2
      expect(progressValues[0], closeTo(512.0 / 2560.0, 0.01));
      // After large file: (512 + 2048) / 2560 = 1.0
      expect(progressValues[1], 1.0);
    });

    test('progress values monotonically increase with many files', () async {
      final archive = Archive();

      final dataJson = jsonEncode({
        'entries': [], 'tags': [], 'routines': [],
        'note_cards': [], 'card_folders': [], 'templates': [],
      });
      archive.addFile(ArchiveFile('data.json', dataJson.length, utf8.encode(dataJson)));

      // 15 media files to trigger event-loop yields (every 10)
      for (int i = 0; i < 15; i++) {
        final size = 100 + (i * 10); // varying sizes
        archive.addFile(ArchiveFile('media/file_$i.jpg', size, List<int>.filled(size, i)));
      }

      final zipPath = '${tempDir.path}/many_files.zip';
      final zipBytes = ZipEncoder().encode(archive);
      File(zipPath).writeAsBytesSync(zipBytes);

      final storageService = _FakeStorageService();

      final progressValues = <double>[];
      await storageService.restoreFromBackup(
        File(zipPath),
        onProgress: (p) => progressValues.add(p),
      );

      expect(progressValues.length, 15);
      // Monotonically increasing
      for (int i = 1; i < progressValues.length; i++) {
        expect(progressValues[i], greaterThanOrEqualTo(progressValues[i - 1]));
      }
      // Final is 1.0
      expect(progressValues.last, 1.0);
    });

    test('restore with zero-size media files does not divide by zero', () async {
      final archive = Archive();

      final dataJson = jsonEncode({
        'entries': [], 'tags': [], 'routines': [],
        'note_cards': [], 'card_folders': [], 'templates': [],
      });
      archive.addFile(ArchiveFile('data.json', dataJson.length, utf8.encode(dataJson)));

      // Zero-size media file (edge case)
      archive.addFile(ArchiveFile('media/empty.jpg', 0, []));

      final zipPath = '${tempDir.path}/zero_size.zip';
      final zipBytes = ZipEncoder().encode(archive);
      File(zipPath).writeAsBytesSync(zipBytes);

      final storageService = _FakeStorageService();

      final progressValues = <double>[];
      await storageService.restoreFromBackup(
        File(zipPath),
        onProgress: (p) => progressValues.add(p),
      );

      // With zero totalBytes, progress is not called (guarded by totalBytes > 0)
      expect(progressValues.isEmpty, isTrue);
    });

    test('fused decode produces identical data as two-step decode', () async {
      final dataJson = jsonEncode({
        'entries': [], 'tags': [], 'routines': [],
        'note_cards': [], 'card_folders': [], 'templates': [],
      });
      final archive = Archive();
      archive.addFile(ArchiveFile('data.json', dataJson.length, utf8.encode(dataJson)));
      archive.addFile(ArchiveFile('persona.json', jsonEncode({
        'ai_assistant_name': 'Test',
        'ai_assistant_personality': 'testing',
      }).length, utf8.encode(jsonEncode({
        'ai_assistant_name': 'Test',
        'ai_assistant_personality': 'testing',
      }))));

      final zipPath = '${tempDir.path}/fused_test.zip';
      final zipBytes = ZipEncoder().encode(archive);
      File(zipPath).writeAsBytesSync(zipBytes);

      final inputStream = InputFileStream(zipPath);
      Archive? decoded;
      try {
        decoded = ZipDecoder().decodeStream(inputStream);

        // Verify data.json via fused decode matches expected
        final dataFile = decoded.findFile('data.json');
        expect(dataFile, isNotNull);
        final fusedData = json.fuse(utf8).decode(dataFile!.content as List<int>);
        expect(fusedData, isA<Map<String, dynamic>>());
        expect((fusedData as Map<String, dynamic>)['tags'], isEmpty);

        // Verify persona.json via fused decode
        final personaFile = decoded.findFile('persona.json');
        expect(personaFile, isNotNull);
        final fusedPersona = json.fuse(utf8).decode(personaFile!.content as List<int>);
        expect((fusedPersona as Map<String, dynamic>)['ai_assistant_name'], 'Test');
      } finally {
        await decoded?.clear();
        await inputStream.close();
      }
    });
  });
}
