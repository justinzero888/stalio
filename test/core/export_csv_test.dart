import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stalio/core/services/export_service.dart';
import 'package:stalio/core/services/storage_service.dart';
import 'package:stalio/models/entry.dart' show Entry, EntryType;
import 'package:stalio/models/tag.dart';
import 'package:stalio/models/routine.dart';

class _FakeStorage extends StorageService {
  final List<Entry> _entries;
  final List<Routine> _routines;

  _FakeStorage(this._entries, [this._routines = const []]);

  @override Future<List<Entry>> getEntries() async => _entries;
  @override Future<List<Tag>> getTags() async => [];
  @override Future<List<Routine>> getRoutines() async => _routines;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExportService.exportCsv', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('export_csv_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('produces valid ZIP with entries.csv', () async {
      final entries = [
        Entry(id: 'e1', type: EntryType.freeform, content: 'Hello world', tagIds: ['t1'],
            createdAt: DateTime(2026, 6, 1), updatedAt: DateTime(2026, 6, 1)),
        Entry(id: 'e2', type: EntryType.freeform, content: 'Test entry, with commas', tagIds: [],
            createdAt: DateTime(2026, 6, 2), updatedAt: DateTime(2026, 6, 2)),
      ];
      final storage = _FakeStorage(entries);
      final service = ExportService(storage);

      final path = await service.exportCsv(
        exportRoutines: false,
        docDirOverride: tempDir.path,
      );
      final file = File(path);
      expect(file.existsSync(), isTrue);

      final zipBytes = file.readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(zipBytes);
      expect(archive.length, 1);

      final csvFile = archive.first;
      expect(csvFile.name, 'entries.csv');
      final csvContent = utf8.decode(csvFile.content as List<int>);
      expect(csvContent, contains('Hello world'));
      expect(csvContent, contains('Test entry, with commas'));
    });

    test('date range filters entries', () async {
      final entries = [
        Entry(id: 'e1', type: EntryType.freeform, content: 'Old entry',
            createdAt: DateTime(2026, 1, 1), updatedAt: DateTime(2026, 1, 1)),
        Entry(id: 'e2', type: EntryType.freeform, content: 'Recent entry',
            createdAt: DateTime(2026, 6, 1), updatedAt: DateTime(2026, 6, 1)),
      ];
      final storage = _FakeStorage(entries);
      final service = ExportService(storage);

      final path = await service.exportCsv(
        startDate: DateTime(2026, 3, 1),
        exportRoutines: false,
        docDirOverride: tempDir.path,
      );
      final file = File(path);
      final zipBytes = file.readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(zipBytes);
      final csvContent = utf8.decode(archive.first.content as List<int>);

      expect(csvContent, isNot(contains('Old entry')));
      expect(csvContent, contains('Recent entry'));
    });

    test('includes routines.csv when exportRoutines is true', () async {
      final entries = [
        Entry(id: 'e1', type: EntryType.freeform, content: 'Test',
            createdAt: DateTime(2026, 6, 1), updatedAt: DateTime(2026, 6, 1)),
      ];
      final routines = [
        Routine(id: 'r1', name: '喝水', nameEn: 'Drink water', frequency: RoutineFrequency.daily,
            createdAt: DateTime(2026, 6, 1), updatedAt: DateTime(2026, 6, 1)),
      ];
      final storage = _FakeStorage(entries, routines);
      final service = ExportService(storage);

      final path = await service.exportCsv(docDirOverride: tempDir.path);
      final file = File(path);
      final zipBytes = file.readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(zipBytes);
      expect(archive.length, 2);

      final names = archive.map((f) => f.name).toSet();
      expect(names, contains('entries.csv'));
      expect(names, contains('routines.csv'));
    });
  });
}
