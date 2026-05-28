import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:blinking/core/services/storage_service.dart';
import 'package:blinking/core/services/database_service.dart';
import 'package:blinking/providers/card_provider.dart';
import 'package:blinking/models/note_card.dart';

class _TestPathProvider extends FakePathProvider {
  final String appDocsPath;
  _TestPathProvider(this.appDocsPath);
  @override
  Future<String?> getApplicationDocumentsPath() async => appDocsPath;
  @override
  Future<String?> getTemporaryPath() async => appDocsPath;
}

class FakePathProvider extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async => throw UnimplementedError();
  @override
  Future<String?> getApplicationCachePath() async => throw UnimplementedError();
  @override
  Future<String?> getApplicationSupportPath() async => throw UnimplementedError();
  @override
  Future<String?> getTemporaryPath() async => throw UnimplementedError();
  @override
  Future<String?> getExternalStoragePath() async => throw UnimplementedError();
  @override
  Future<List<String>?> getExternalCachePaths() async => throw UnimplementedError();
  @override
  Future<List<String>?> getExternalStoragePaths({StorageDirectory? type}) async =>
      throw UnimplementedError();
  @override
  Future<String?> getDownloadsPath() async => throw UnimplementedError();
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Keepsake — full flow integration', () {
    late Directory tempDir;
    late StorageService storageService;
    late CardProvider cardProvider;

    Future<StorageService> _setupStorage() async {
      SharedPreferences.setMockInitialValues({});
      tempDir = Directory.systemTemp.createTempSync('keepsake_integration_');
      final appDocDir = Directory('${tempDir.path}/app_docs')..createSync(recursive: true);
      PathProviderPlatform.instance = _TestPathProvider(appDocDir.path);

      final db = await DatabaseService.createTestDatabase('${tempDir.path}/test.db');
      DatabaseService.setTestDatabase(db);

      final svc = StorageService();
      await svc.init();
      return svc;
    }

    setUp(() async {
      storageService = await _setupStorage();
      cardProvider = CardProvider(storageService);
      await cardProvider.load();
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    String _dummyPngPath() {
      final dir = Directory('${tempDir.path}/cards')..createSync(recursive: true);
      final path = '${dir.path}/dummy.png';
      File(path).writeAsBytesSync(List.filled(100, 0));
      return path;
    }

    test('IT-1: Entry → Save → Card in DB → getCardByEntryId finds it', () async {
      final card = await cardProvider.addCard(
        entryIds: ['entry_1'],
        templateId: 'tpl_ink_rhythm',
        folderId: 'folder_default',
        cardContent: 'Integration test content',
        emotion: '😊',
        displayTags: ['journal'],
        showMood: true,
        showDate: true,
        showTags: true,
        showFooter: true,
        renderedImagePath: _dummyPngPath(),
      );

      // Card exists in provider
      expect(cardProvider.cards.length, 1);
      expect(cardProvider.cards.first.id, card.id);

      // getCardByEntryId returns the card
      final found = cardProvider.getCardByEntryId('entry_1');
      expect(found, isNotNull);
      expect(found!.id, card.id);
      expect(found.cardContent, 'Integration test content');
      expect(found.emotion, '😊');
      expect(found.templateId, 'tpl_ink_rhythm');
    });

    test('IT-2: Re-render on restore — card survives without rendered PNG', () async {
      // Save card without renderedImagePath (simulating restore)
      final card = await cardProvider.addCard(
        entryIds: ['entry_1'],
        templateId: 'tpl_moonlight',
        folderId: 'folder_default',
        cardContent: 'Restored content',
        emotion: '😊',
        renderedImagePath: null, // No PNG cached
      );

      expect(card.renderedImagePath, isNull);

      // Card should still be findable
      final found = cardProvider.getCardByEntryId('entry_1');
      expect(found, isNotNull);
      expect(found!.cardContent, 'Restored content');
      // Template should still be resolvable
      expect(cardProvider.getTemplateById(found.templateId), isNotNull);
    });

    test('IT-3: Edit keepsake — updateCard persists changes', () async {
      final card = await cardProvider.addCard(
        entryIds: ['entry_1'],
        templateId: 'tpl_ink_rhythm',
        folderId: 'folder_default',
        cardContent: 'Original',
        emotion: '😊',
      );

      // Simulate edit: change template and content
      final updated = card.copyWith(
        templateId: 'tpl_moonlight',
        cardContent: 'Edited content',
        emotion: '😢',
        showMood: false,
      );
      await cardProvider.updateCard(updated);

      // Reload to verify persistence
      final reloaded = cardProvider.cards.firstWhere((c) => c.id == card.id);
      expect(reloaded.templateId, 'tpl_moonlight');
      expect(reloaded.cardContent, 'Edited content');
      expect(reloaded.emotion, '😢');
      expect(reloaded.showMood, isFalse);
    });

    test('IT-4: All toggles OFF — persisted correctly', () async {
      final card = await cardProvider.addCard(
        entryIds: ['entry_1'],
        templateId: 'tpl_seal',
        folderId: 'folder_default',
        cardContent: 'Minimal',
        showMood: false,
        showDate: false,
        showTags: false,
        showFooter: false,
      );

      final saved = cardProvider.cards.first;
      expect(saved.showMood, isFalse);
      expect(saved.showDate, isFalse);
      expect(saved.showTags, isFalse);
      expect(saved.showFooter, isFalse);
    });

    test('IT-5: All toggles ON — full card persisted', () async {
      final card = await cardProvider.addCard(
        entryIds: ['entry_1'],
        templateId: 'tpl_ink_rhythm',
        folderId: 'folder_default',
        cardContent: 'Full',
        emotion: '😊',
        displayTags: ['journal', 'daily', 'morning'],
        showMood: true,
        showDate: true,
        showTags: true,
        showFooter: true,
      );

      final saved = cardProvider.cards.first;
      expect(saved.showMood, isTrue);
      expect(saved.showDate, isTrue);
      expect(saved.showTags, isTrue);
      expect(saved.showFooter, isTrue);
      expect(saved.emotion, '😊');
      expect(saved.displayTags, ['journal', 'daily', 'morning']);
    });

    test('IT-6: Multiple cards — correct entry-to-card mapping', () async {
      final card1 = await cardProvider.addCard(
        entryIds: ['entry_a'],
        templateId: 'tpl_ink_rhythm',
        folderId: 'folder_default',
        cardContent: 'Card A',
      );
      final card2 = await cardProvider.addCard(
        entryIds: ['entry_b'],
        templateId: 'tpl_moonlight',
        folderId: 'folder_default',
        cardContent: 'Card B',
      );

      expect(cardProvider.cards.length, 2);

      // Each entry maps to the correct card
      final foundA = cardProvider.getCardByEntryId('entry_a');
      expect(foundA!.id, card1.id);
      expect(foundA.cardContent, 'Card A');

      final foundB = cardProvider.getCardByEntryId('entry_b');
      expect(foundB!.id, card2.id);
      expect(foundB.cardContent, 'Card B');
    });

    test('IT-7: Deleted card — getCardByEntryId returns null', () async {
      await cardProvider.addCard(
        entryIds: ['entry_1'],
        templateId: 'tpl_ink_rhythm',
        folderId: 'folder_default',
        cardContent: 'To be deleted',
      );

      final card = cardProvider.cards.first;
      await cardProvider.deleteCard(card.id);

      expect(cardProvider.cards.length, 0);
      expect(cardProvider.getCardByEntryId('entry_1'), isNull);
    });

    test('IT-8: Template lookup — all 8 templates resolvable by ID', () async {
      final ids = [
        'tpl_ink_rhythm', 'tpl_plain_paper', 'tpl_bamboo', 'tpl_moonlight',
        'tpl_porcelain', 'tpl_tea', 'tpl_seal', 'tpl_landscape',
      ];
      for (final id in ids) {
        final tpl = cardProvider.getTemplateById(id);
        expect(tpl, isNotNull, reason: 'Template $id should be seeded');
        expect(tpl!.name, isNotEmpty);
        expect(tpl.nameEn, isNotEmpty);
      }
    });

    test('IT-9: Cards survive provider reload', () async {
      await cardProvider.addCard(
        entryIds: ['entry_1'],
        templateId: 'tpl_ink_rhythm',
        folderId: 'folder_default',
        cardContent: 'Persistent',
      );
      expect(cardProvider.cards.length, 1);

      // Simulate provider reload (fresh load from DB)
      await cardProvider.load();
      expect(cardProvider.cards.length, 1);
      expect(cardProvider.cards.first.cardContent, 'Persistent');
      expect(cardProvider.getCardByEntryId('entry_1'), isNotNull);
    });
  });
}
