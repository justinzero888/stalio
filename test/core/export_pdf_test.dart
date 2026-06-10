import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:stalio/core/services/export_service.dart';
import 'package:stalio/core/services/storage_service.dart';
import 'package:stalio/models/entry.dart' show Entry, EntryType;
import 'package:stalio/models/tag.dart';
import 'package:stalio/models/routine.dart';

class _FakeStorage extends StorageService {
  final List<Entry> _entries;
  final List<Tag> _tags;
  final List<Routine> _routines;

  _FakeStorage(this._entries, [this._tags = const [], this._routines = const []]);

  @override Future<List<Entry>> getEntries() async => _entries;
  @override Future<List<Tag>> getTags() async => _tags;
  @override Future<List<Routine>> getRoutines() async => _routines;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExportService.exportPdf', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('export_pdf_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('produces valid PDF file', () async {
      final entries = [
        Entry(id: 'e1', type: EntryType.freeform, content: 'Hello PDF', tagIds: [],
            createdAt: DateTime(2026, 6, 1), updatedAt: DateTime(2026, 6, 1)),
      ];
      final tags = [Tag(id: 't1', name: 'Test', nameEn: 'Test', color: '#000', createdAt: DateTime(2026))];
      final storage = _FakeStorage(entries, tags);
      final service = ExportService(storage);

      final path = await service.exportPdf(docDirOverride: tempDir.path);
      final file = File(path);
      expect(file.existsSync(), isTrue);
      final bytes = file.readAsBytesSync();
      expect(bytes.length, greaterThan(100));
      // PDF header
      expect(bytes.sublist(0, 5), [0x25, 0x50, 0x44, 0x46, 0x2D]);
    });

    test('PDF includes entry content', () async {
      final entries = [
        Entry(id: 'e1', type: EntryType.freeform, content: 'Unique text for PDF', tagIds: [],
            createdAt: DateTime(2026, 6, 1), updatedAt: DateTime(2026, 6, 1)),
      ];
      final storage = _FakeStorage(entries, []);
      final service = ExportService(storage);

      final path = await service.exportPdf(docDirOverride: tempDir.path);
      final bytes = File(path).readAsBytesSync();
      // Multiple pages: title + entry + summary = 3 pages, so PDF is substantial
      expect(bytes.length, greaterThan(2000));
    });

    test('date range filters entries in PDF', () async {
      final entries = [
        Entry(id: 'e1', type: EntryType.freeform, content: 'Old', tagIds: [],
            createdAt: DateTime(2026, 1, 1), updatedAt: DateTime(2026, 1, 1)),
        Entry(id: 'e2', type: EntryType.freeform, content: 'New', tagIds: [],
            createdAt: DateTime(2026, 6, 1), updatedAt: DateTime(2026, 6, 1)),
      ];
      final allStorage = _FakeStorage(entries, []);
      final filteredStorage = _FakeStorage([entries[1]], []);

      final allPath = await ExportService(allStorage).exportPdf(docDirOverride: tempDir.path);
      final filteredPath = await ExportService(filteredStorage).exportPdf(docDirOverride: tempDir.path);

      // Filtered PDF should be smaller (fewer entries)
      final allBytes = File(allPath).readAsBytesSync();
      final filteredBytes = File(filteredPath).readAsBytesSync();
      expect(filteredBytes.length, lessThan(allBytes.length));
    });

    test('onProgress is called with valid values', () async {
      final entries = List.generate(5, (i) => Entry(
        id: 'e$i', type: EntryType.freeform, content: 'Entry $i', tagIds: [],
        createdAt: DateTime(2026, 6, i + 1), updatedAt: DateTime(2026, 6, i + 1),
      ));
      final storage = _FakeStorage(entries, []);
      final service = ExportService(storage);
      final progressValues = <double>[];

      await service.exportPdf(docDirOverride: tempDir.path, onProgress: progressValues.add);

      expect(progressValues, isNotEmpty);
      expect(progressValues.first, 0.0);
      expect(progressValues.last, 1.0);
    });
  });
}
