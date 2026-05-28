import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:blinking/core/services/storage_service.dart';
import 'package:blinking/core/services/database_service.dart';
import 'package:blinking/providers/card_provider.dart';
import 'package:blinking/models/card_template.dart';
import 'package:blinking/models/card_enums.dart';

class _MockPathProvider extends FakePathProvider {
  final String appDocsPath;
  _MockPathProvider(this.appDocsPath);

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

  group('StorageService — card seed data', () {
    late Directory tempDir;
    late StorageService storageService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      tempDir = Directory.systemTemp.createTempSync('card_seed_test_');
      final appDocDir = Directory('${tempDir.path}/app_docs')..createSync(recursive: true);
      PathProviderPlatform.instance = _MockPathProvider(appDocDir.path);

      final db = await DatabaseService.createTestDatabase('${tempDir.path}/test.db');
      DatabaseService.setTestDatabase(db);

      storageService = StorageService();
      await storageService.init();
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('seeds 8 templates on fresh install', () async {
      final templates = storageService.getDefaultTemplatesForTest();
      expect(templates.length, 8);
      final ids = templates.map((t) => t.id).toSet();
      expect(ids.length, 8);
    });

    test('seed templates all have locale-aware display names', () async {
      final templates = storageService.getDefaultTemplatesForTest();
      for (final t in templates) {
        expect(t.name, isNotEmpty);
        expect(t.nameEn, isNotEmpty);
        expect(t.displayNameFor(true), t.name);
        expect(t.displayNameFor(false), t.nameEn);
      }
    });

    test('seed templates have valid layout and decoration', () async {
      final templates = storageService.getDefaultTemplatesForTest();
      for (final t in templates) {
        expect(t.layout.value, isNotEmpty);
      }
      final hasInkWash = templates.any((t) => t.decorationStyle == 'ink_wash');
      final hasSeal = templates.any((t) => t.decorationStyle == 'seal');
      final hasLandscape = templates.any((t) => t.decorationStyle == 'landscape');
      expect(hasInkWash, isTrue);
      expect(hasSeal, isTrue);
      expect(hasLandscape, isTrue);
    });
  });

  group('CardProvider — CRUD with new fields', () {
    late Directory tempDir;
    late StorageService storageService;
    late CardProvider provider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      tempDir = Directory.systemTemp.createTempSync('card_provider_crud_');
      final appDocDir = Directory('${tempDir.path}/app_docs')..createSync(recursive: true);
      PathProviderPlatform.instance = _MockPathProvider(appDocDir.path);

      final db = await DatabaseService.createTestDatabase('${tempDir.path}/test.db');
      DatabaseService.setTestDatabase(db);

      storageService = StorageService();
      await storageService.init();
      provider = CardProvider(storageService);
      await provider.load();
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('addCard persists all new fields', () async {
      final card = await provider.addCard(
        entryIds: ['entry_1'],
        templateId: 'tpl_ink_rhythm',
        folderId: 'folder_default',
        cardContent: 'Test keepsake content',
        emotion: '😊',
        displayTags: ['journal', 'morning'],
        showMood: false,
        showDate: true,
        showTags: false,
        showFooter: true,
        templateOverrides: '{"font_color":"#FF0000"}',
      );

      expect(card.cardContent, 'Test keepsake content');
      expect(card.emotion, '😊');
      expect(card.displayTags, ['journal', 'morning']);
      expect(card.showMood, isFalse);
      expect(card.showDate, isTrue);
      expect(card.showTags, isFalse);
      expect(card.showFooter, isTrue);
      expect(card.templateOverrides, '{"font_color":"#FF0000"}');
    });

    test('addCard with minimum fields uses defaults', () async {
      final card = await provider.addCard(
        entryIds: ['entry_1'],
        templateId: 'tpl_ink_rhythm',
        folderId: 'folder_default',
      );

      expect(card.cardContent, isNull);
      expect(card.emotion, isNull);
      expect(card.showMood, isTrue);
      expect(card.showDate, isTrue);
      expect(card.showTags, isTrue);
      expect(card.showFooter, isTrue);
    });

    test('getCardByEntryId finds card linked to entry', () async {
      final card = await provider.addCard(
        entryIds: ['entry_1', 'entry_2'],
        templateId: 'tpl_ink_rhythm',
        folderId: 'folder_default',
      );

      final found = provider.getCardByEntryId('entry_1');
      expect(found, isNotNull);
      expect(found!.id, card.id);

      final found2 = provider.getCardByEntryId('entry_2');
      expect(found2, isNotNull);
      expect(found2!.id, card.id);
    });

    test('getCardByEntryId returns null for no match', () async {
      await provider.addCard(
        entryIds: ['entry_1'],
        templateId: 'tpl_ink_rhythm',
        folderId: 'folder_default',
      );

      expect(provider.getCardByEntryId('nonexistent'), isNull);
    });

    test('load seeds 8 templates', () async {
      expect(provider.templates.length, 8);
      expect(provider.templates.every((t) => t.isBuiltIn), isTrue);
    });

    test('getTemplateById resolves built-in template', () async {
      final tpl = provider.getTemplateById('tpl_bamboo');
      expect(tpl, isNotNull);
      expect(tpl!.name, '竹影');
      expect(tpl.nameEn, 'Bamboo Shadow');
      expect(tpl.layout.value, 'hero_image');
      expect(tpl.decorationStyle, 'bamboo');
    });

    test('getTemplateById returns null for unknown', () async {
      expect(provider.getTemplateById('nonexistent'), isNull);
    });

    test('updateCard persists field changes', () async {
      final card = await provider.addCard(
        entryIds: ['entry_1'],
        templateId: 'tpl_ink_rhythm',
        folderId: 'folder_default',
        cardContent: 'Original',
        emotion: '😊',
      );

      final updated = card.copyWith(
        cardContent: 'Updated',
        emotion: '😢',
        showMood: false,
        templateOverrides: '{"font_color":"#0000FF"}',
      );
      await provider.updateCard(updated);

      final loaded = provider.cards.firstWhere((c) => c.id == card.id);
      expect(loaded.cardContent, 'Updated');
      expect(loaded.emotion, '😢');
      expect(loaded.showMood, isFalse);
      expect(loaded.templateOverrides, '{"font_color":"#0000FF"}');
    });

    test('deleteCard removes from list and getCardByEntryId', () async {
      final card = await provider.addCard(
        entryIds: ['entry_1'],
        templateId: 'tpl_ink_rhythm',
        folderId: 'folder_default',
      );
      expect(provider.cards.length, 1);

      await provider.deleteCard(card.id);
      expect(provider.cards.length, 0);
      expect(provider.getCardByEntryId('entry_1'), isNull);
    });
  });
}
