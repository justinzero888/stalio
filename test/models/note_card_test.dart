import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:blinking/models/note_card.dart';

void main() {
  group('NoteCard', () {
    test('fromJson/toJson round-trip preserves all fields', () {
      final card = NoteCard(
        id: 'card_1',
        entryIds: ['entry_1', 'entry_2'],
        templateId: 'tpl_ink_rhythm',
        folderId: 'folder_default',
        renderedImagePath: '/path/to/image.png',
        aiSummary: 'AI summary',
        richContent: 'Rich content',
        cardContent: 'Card content',
        emotion: '😊',
        displayTags: ['journal', 'morning'],
        showMood: true,
        showDate: false,
        showTags: true,
        showFooter: false,
        templateOverrides: '{"font_color":"#FF0000"}',
        createdAt: DateTime(2026, 5, 23),
        updatedAt: DateTime(2026, 5, 23),
      );

      final json = card.toJson();
      final restored = NoteCard.fromJson(json);

      expect(restored.id, card.id);
      expect(restored.entryIds, card.entryIds);
      expect(restored.templateId, card.templateId);
      expect(restored.folderId, card.folderId);
      expect(restored.renderedImagePath, card.renderedImagePath);
      expect(restored.aiSummary, card.aiSummary);
      expect(restored.richContent, card.richContent);
      expect(restored.cardContent, card.cardContent);
      expect(restored.emotion, card.emotion);
      expect(restored.displayTags, card.displayTags);
      expect(restored.showMood, card.showMood);
      expect(restored.showDate, card.showDate);
      expect(restored.showTags, card.showTags);
      expect(restored.showFooter, card.showFooter);
      expect(restored.templateOverrides, card.templateOverrides);
      expect(restored.createdAt, card.createdAt);
      expect(restored.updatedAt, card.updatedAt);
    });

    test('fromJson handles missing new fields with defaults', () {
      final json = {
        'id': 'card_1',
        'entry_ids': ['entry_1'],
        'template_id': 'tpl_ink_rhythm',
        'folder_id': 'folder_default',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        // New fields are missing
      };
      final card = NoteCard.fromJson(json);
      expect(card.cardContent, isNull);
      expect(card.emotion, isNull);
      expect(card.displayTags, isNull);
      expect(card.showMood, isTrue);
      expect(card.showDate, isTrue);
      expect(card.showTags, isTrue);
      expect(card.showFooter, isTrue);
      expect(card.templateOverrides, isNull);
    });

    test('fromJson handles display_tags as JSON list', () {
      final json = {
        'id': 'card_1',
        'entry_ids': ['entry_1'],
        'template_id': 'tpl_ink_rhythm',
        'folder_id': 'folder_default',
        'display_tags': ['journal', 'morning'],
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      final card = NoteCard.fromJson(json);
      expect(card.displayTags, ['journal', 'morning']);
    });

    test('toJson serializes booleans as integers', () {
      final card = NoteCard(
        id: 'card_1',
        entryIds: ['entry_1'],
        templateId: 'tpl_ink_rhythm',
        folderId: 'folder_default',
        showMood: true,
        showDate: false,
        showTags: true,
        showFooter: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final json = card.toJson();
      expect(json['show_mood'], 1);
      expect(json['show_date'], 0);
      expect(json['show_tags'], 1);
      expect(json['show_footer'], 0);
    });

    test('toJson excludes null optional fields', () {
      final card = NoteCard(
        id: 'card_1',
        entryIds: ['entry_1'],
        templateId: 'tpl_ink_rhythm',
        folderId: 'folder_default',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final json = card.toJson();
      expect(json['card_content'], isNull);
      expect(json['emotion'], isNull);
      expect(json['display_tags'], isNull);
      expect(json['template_overrides'], isNull);
    });

    test('copyWith preserves new fields', () {
      final card = NoteCard(
        id: 'card_1',
        entryIds: ['entry_1'],
        templateId: 'tpl_ink_rhythm',
        folderId: 'folder_default',
        cardContent: 'Hello',
        emotion: '😊',
        displayTags: ['journal'],
        showMood: true,
        showDate: true,
        showTags: true,
        showFooter: true,
        templateOverrides: '{}',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final copy = card.copyWith();
      expect(copy.cardContent, card.cardContent);
      expect(copy.emotion, card.emotion);
      expect(copy.displayTags, card.displayTags);
      expect(copy.showMood, card.showMood);
      expect(copy.templateOverrides, card.templateOverrides);
    });

    test('copyWith updates new fields', () {
      final card = NoteCard(
        id: 'card_1',
        entryIds: ['entry_1'],
        templateId: 'tpl_ink_rhythm',
        folderId: 'folder_default',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final copy = card.copyWith(
        cardContent: 'Updated',
        emotion: '😢',
        displayTags: ['evening'],
        showMood: false,
        showDate: false,
        showTags: false,
        showFooter: false,
        templateOverrides: '{"font_color":"#0000FF"}',
      );
      expect(copy.cardContent, 'Updated');
      expect(copy.emotion, '😢');
      expect(copy.displayTags, ['evening']);
      expect(copy.showMood, isFalse);
      expect(copy.showDate, isFalse);
      expect(copy.showTags, isFalse);
      expect(copy.showFooter, isFalse);
      expect(copy.templateOverrides, '{"font_color":"#0000FF"}');
    });

    test('copyWith clears optional fields with clear flags', () {
      final card = NoteCard(
        id: 'card_1',
        entryIds: ['entry_1'],
        templateId: 'tpl_ink_rhythm',
        folderId: 'folder_default',
        cardContent: 'Hello',
        emotion: '😊',
        displayTags: ['journal'],
        templateOverrides: '{}',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final copy = card.copyWith(
        clearCardContent: true,
        clearEmotion: true,
        clearDisplayTags: true,
        clearTemplateOverrides: true,
      );
      expect(copy.cardContent, isNull);
      expect(copy.emotion, isNull);
      expect(copy.displayTags, isNull);
      expect(copy.templateOverrides, isNull);
    });
  });
}
