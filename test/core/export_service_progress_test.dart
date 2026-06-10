import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stalio/core/services/export_service.dart';
import 'package:stalio/core/services/storage_service.dart';
import 'package:stalio/models/entry.dart' show Entry, EntryType;
import 'package:stalio/models/tag.dart';
import 'package:stalio/models/routine.dart';

class _FakeStorage extends StorageService {
  final List<Entry> _entries;

  _FakeStorage([this._entries = const []]);

  @override Future<List<Entry>> getEntries() async => _entries;
  @override Future<List<Tag>> getTags() async => [];
  @override Future<List<Routine>> getRoutines() async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExportService.exportAll — onProgress', () {
    late Directory tempDir;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      tempDir = Directory.systemTemp.createTempSync('export_progress_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('onProgress called with 1.0 when no media files', () async {
      final service = ExportService(_FakeStorage());
      final progressValues = <double>[];

      await service.exportAll(
        onProgress: progressValues.add,
        docDirOverride: tempDir.path,
      );

      expect(progressValues, isNotEmpty);
      expect(progressValues.last, 1.0);
    });

    test('onProgress values are monotonically increasing and end at 1.0', () async {
      final mediaDir = Directory('${tempDir.path}/media')..createSync();
      for (var i = 0; i < 3; i++) {
        File('${mediaDir.path}/photo_$i.jpg')
            .writeAsBytesSync(List.filled(1024, i));
      }

      final service = ExportService(_FakeStorage());
      final progressValues = <double>[];

      await service.exportAll(
        onProgress: progressValues.add,
        docDirOverride: tempDir.path,
      );

      expect(progressValues.last, 1.0);
      // All values except the terminal 1.0 must be strictly increasing
      for (var i = 1; i < progressValues.length - 1; i++) {
        expect(progressValues[i], greaterThan(progressValues[i - 1]),
            reason: 'progress values at index $i should be strictly increasing');
      }
    });

    test('exports only media files referenced by entries within date range', () async {
      // Create media directory and files
      final mediaDir = Directory('${tempDir.path}/media')..createSync();
      final oldPhotoPath = '${mediaDir.path}/old_photo.jpg';
      final recentPhotoPath = '${mediaDir.path}/recent_photo.jpg';
      File(oldPhotoPath).writeAsBytesSync(List.filled(1024, 1));
      File(recentPhotoPath).writeAsBytesSync(List.filled(1024, 2));

      // Create entries with different dates
      final now = DateTime.now();
      final oneMonthAgo = now.subtract(const Duration(days: 30));
      final oldEntry = Entry(
        id: '1',
        type: EntryType.freeform,
        content: 'old entry',
        emotion: '😊',
        createdAt: oneMonthAgo,
        updatedAt: oneMonthAgo,
        tagIds: [],
        mediaUrls: ['media/old_photo.jpg'],
      );
      final recentEntry = Entry(
        id: '2',
        type: EntryType.freeform,
        content: 'recent entry',
        emotion: '😊',
        createdAt: now,
        updatedAt: now,
        tagIds: [],
        mediaUrls: ['media/recent_photo.jpg'],
      );

      // Export with date range that only includes recent entry
      final service = ExportService(_FakeStorage([oldEntry, recentEntry]));
      final zipPath = await service.exportAll(
        startDate: oneMonthAgo.add(const Duration(days: 1)),
        endDate: now,
        docDirOverride: tempDir.path,
      );

      // Read ZIP and verify contents
      final bytes = File(zipPath).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);
      final filesInZip = archive.map((f) => f.name).toList();

      // Should have data.json and manifest.json
      expect(filesInZip, contains('data.json'));
      expect(filesInZip, contains('manifest.json'));

      // Should have recent_photo.jpg but NOT old_photo.jpg
      expect(filesInZip, contains('media/recent_photo.jpg'),
          reason: 'recent entry media should be included');
      expect(filesInZip, isNot(contains('media/old_photo.jpg')),
          reason: 'old entry media should be excluded when outside date range');
    });
  });
}
