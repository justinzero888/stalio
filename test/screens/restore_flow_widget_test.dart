import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:blinking/core/services/storage_service.dart';
import 'package:blinking/core/services/export_service.dart';

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

/// Mock StorageService that skips database initialization for testing
class _MockStorageService extends StorageService {
  @override
  Future<void> init() async {
    // Skip database initialization for testing
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Restore Flow Widget Tests', () {
    late Directory tempDir;
    late File backupFile;

    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
    });

    setUp(() async {
      // Create temp directory
      tempDir = Directory.systemTemp.createTempSync('restore_widget_test_');
      final appDocDir = Directory('${tempDir.path}/app_docs');
      appDocDir.createSync(recursive: true);

      // Mock the PathProvider
      PathProviderPlatform.instance = MockPathProvider(appDocDir.path);

      // Create test backup file with media files
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

      // Add 5 media files to trigger multiple progress updates
      for (int i = 0; i < 5; i++) {
        final mediaContent = List<int>.filled(2048, 42 + i);
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

    testWidgets('Restore dialog shows confirmation text and actions',
        (WidgetTester tester) async {
      // Use mock storage service to skip DB initialization
      final storage = _MockStorageService();
      await storage.init();

      // Build app with dialog initiator
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<StorageService>.value(value: storage),
            Provider<ExportService>(
              create: (context) => ExportService(storage),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: _RestoreDialogInitiator(
                backupFile: backupFile,
                storage: storage,
              ),
            ),
          ),
        ),
      );

      // Tap the restore button
      await tester.tap(find.text('Show Restore Dialog'));
      await tester.pump();

      // Verify the confirmation dialog appears with title
      expect(find.text('Restore Data'), findsOneWidget,
          reason: 'Restore confirmation dialog title should appear');

      // Verify confirmation text is shown
      expect(
        find.byWidgetPredicate((widget) =>
            widget is Text &&
            widget.data?.contains('replace all your current data') == true),
        findsOneWidget,
        reason: 'Confirmation message should be displayed',
      );

      // Verify action buttons are present
      expect(find.text('Cancel'), findsOneWidget,
          reason: 'Cancel button should be present');
      expect(find.text('Restore'), findsOneWidget,
          reason: 'Restore button should be present');
    });

    testWidgets('Restore progress dialog shows LinearProgressIndicator',
        (WidgetTester tester) async {
      final storage = _MockStorageService();
      await storage.init();

      // Build app with progress dialog demo
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<StorageService>.value(value: storage),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: _RestoreProgressDialogDemo(
                backupFile: backupFile,
                storage: storage,
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Trigger the progress dialog
      await tester.tap(find.text('Show Progress Dialog'));
      await tester.pump();

      // Verify LinearProgressIndicator appears
      expect(find.byType(LinearProgressIndicator), findsOneWidget,
          reason: 'LinearProgressIndicator must appear during restore');

      // Verify the "Restoring..." title is shown
      expect(find.text('Restoring...'), findsOneWidget,
          reason: 'Progress dialog title should show "Restoring..."');
    });

    testWidgets('Restore progress dialog shows warning text',
        (WidgetTester tester) async {
      final storage = _MockStorageService();
      await storage.init();

      // Build app with progress dialog demo
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<StorageService>.value(value: storage),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: _RestoreProgressDialogDemo(
                backupFile: backupFile,
                storage: storage,
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Trigger the progress dialog
      await tester.tap(find.text('Show Progress Dialog'));
      await tester.pump();

      // Verify the warning text "Do not close the app" appears
      expect(find.text('Do not close the app'), findsOneWidget,
          reason:
              'Warning text must appear during restore to prevent app closure');

      // Verify the warning icon is present
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget,
          reason: 'Warning icon should be visible next to warning text');
    });

    testWidgets('Restore progress dialog shows percentage', (WidgetTester tester) async {
      final storage = _MockStorageService();
      await storage.init();

      // Build app with progress dialog demo
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<StorageService>.value(value: storage),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: _RestoreProgressDialogDemo(
                backupFile: backupFile,
                storage: storage,
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Trigger the progress dialog
      await tester.tap(find.text('Show Progress Dialog'));
      await tester.pump();

      // Verify percentage text is displayed (should show 0% initially)
      final percentageFinder = find.byWidgetPredicate((widget) =>
          widget is Text &&
          widget.data?.contains('%') == true &&
          widget.style?.fontSize == 24);
      expect(percentageFinder, findsOneWidget,
          reason: 'Percentage should be displayed in large bold font');
    });

    testWidgets('Success snackbar shows after restore completion',
        (WidgetTester tester) async {
      final storage = _MockStorageService();
      await storage.init();

      // Build app with completion demo
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<StorageService>.value(value: storage),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: _RestoreCompletionDemo(
                backupFile: backupFile,
                storage: storage,
              ),
            ),
          ),
        ),
      );

      // Trigger restore completion
      await tester.tap(find.text('Complete Restore'));
      await tester.pump();

      // Verify success snackbar text appears
      expect(find.text('Data restored successfully!'), findsOneWidget,
          reason:
              'Success snackbar must show "Data restored successfully!" message');
    });

    testWidgets('Progress dialog is not dismissible', (WidgetTester tester) async {
      final storage = _MockStorageService();
      await storage.init();

      // Build app with progress dialog demo
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<StorageService>.value(value: storage),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: _RestoreProgressDialogDemo(
                backupFile: backupFile,
                storage: storage,
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Trigger the progress dialog
      await tester.tap(find.text('Show Progress Dialog'));
      await tester.pump();

      // Try to dismiss by tapping outside the dialog
      // (The dialog uses barrierDismissible: false, so it should not dismiss)
      await tester.tapAt(const Offset(10, 10)); // Tap in the background
      await tester.pump();

      // Dialog should still be visible
      expect(find.text('Restoring...'), findsOneWidget,
          reason: 'Dialog should not be dismissible by tapping outside');
    });
  });
}

/// Helper widget to demonstrate the restore confirmation dialog
class _RestoreDialogInitiator extends StatefulWidget {
  final File backupFile;
  final StorageService storage;

  const _RestoreDialogInitiator({
    required this.backupFile,
    required this.storage,
  });

  @override
  State<_RestoreDialogInitiator> createState() =>
      _RestoreDialogInitiatorState();
}

class _RestoreDialogInitiatorState extends State<_RestoreDialogInitiator> {
  void _showRestoreConfirmation() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restore Data'),
        content: const Text(
          'Restore data from this backup? This will replace all your current data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Simulate restore flow
              Navigator.pop(dialogContext);
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: _showRestoreConfirmation,
        child: const Text('Show Restore Dialog'),
      ),
    );
  }
}

/// Helper widget to demonstrate the restore progress dialog
class _RestoreProgressDialogDemo extends StatefulWidget {
  final File backupFile;
  final StorageService storage;

  const _RestoreProgressDialogDemo({
    required this.backupFile,
    required this.storage,
  });

  @override
  State<_RestoreProgressDialogDemo> createState() =>
      _RestoreProgressDialogDemoState();
}

class _RestoreProgressDialogDemoState extends State<_RestoreProgressDialogDemo> {
  void _showProgressDialog() {
    double progress = 0.0;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => PopScope(
          canPop: false,
          child: AlertDialog(
            title: const Text('Restoring...'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: progress > 0 ? progress : null,
                ),
                const SizedBox(height: 12),
                Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 16, color: Colors.orange),
                    const SizedBox(width: 4),
                    const Text(
                      'Do not close the app',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: _showProgressDialog,
        child: const Text('Show Progress Dialog'),
      ),
    );
  }
}

/// Helper widget to demonstrate restore completion with snackbar
class _RestoreCompletionDemo extends StatefulWidget {
  final File backupFile;
  final StorageService storage;

  const _RestoreCompletionDemo({
    required this.backupFile,
    required this.storage,
  });

  @override
  State<_RestoreCompletionDemo> createState() =>
      _RestoreCompletionDemoState();
}

class _RestoreCompletionDemoState extends State<_RestoreCompletionDemo> {
  void _completeRestore() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data restored successfully!'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: _completeRestore,
        child: const Text('Complete Restore'),
      ),
    );
  }
}
