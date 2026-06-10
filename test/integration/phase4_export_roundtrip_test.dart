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

  group('Phase 4: Export round-trip', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('export_rnd_');
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('CSV export produces valid CSV content', () async {
      final entries = [
        Entry(id: 'e1', type: EntryType.freeform, content: 'Hello', tagIds: ['t1'],
            createdAt: DateTime(2026, 6, 1), updatedAt: DateTime(2026, 6, 1)),
      ];
      final tags = [Tag(id: 't1', name: 'Test', nameEn: 'Test', color: '#000', createdAt: DateTime(2026))];
      final storage = _FakeStorage(entries, tags);
      final service = ExportService(storage);

      final path = await service.exportCsv(exportRoutines: false, docDirOverride: tempDir.path);
      final file = File(path);
      expect(file.existsSync(), isTrue);

      // Verify it's a valid ZIP that can be decoded
      final bytes = file.readAsBytesSync();
      expect(bytes, isNotEmpty);
      // ZIP magic bytes
      expect(bytes.sublist(0, 2), [0x50, 0x4B]);
    });

    test('PDF export produces valid PDF document', () async {
      final entries = [
        Entry(id: 'e1', type: EntryType.freeform, content: 'Test PDF', tagIds: [],
            createdAt: DateTime(2026, 6, 1), updatedAt: DateTime(2026, 6, 1)),
      ];
      final storage = _FakeStorage(entries, []);
      final service = ExportService(storage);

      final path = await service.exportPdf(docDirOverride: tempDir.path);
      final file = File(path);
      expect(file.existsSync(), isTrue);
      final bytes = file.readAsBytesSync();
      expect(bytes.length, greaterThan(100));
      // PDF header
      expect(bytes.sublist(0, 5), [0x25, 0x50, 0x44, 0x46, 0x2D]);
      // PDF version
      final header = String.fromCharCodes(bytes.sublist(0, 10));
      expect(header, contains('PDF-1.'));
      // PDF ends with %%EOF
      final tail = String.fromCharCodes(bytes.sublist(bytes.length - 10));
      expect(tail, contains('%%EOF'));
    });
  });
}
