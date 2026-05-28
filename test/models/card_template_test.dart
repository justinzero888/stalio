import 'package:flutter_test/flutter_test.dart';
import 'package:blinking/models/card_enums.dart';
import 'package:blinking/models/card_template.dart';

void main() {
  group('CardTemplate', () {
    test('seedDefaults returns 8 templates with unique IDs', () {
      final templates = _seedDefaults();
      expect(templates.length, 8);
      final ids = templates.map((t) => t.id).toSet();
      expect(ids.length, 8);
    });

    test('seedDefaults all templates are built-in', () {
      final templates = _seedDefaults();
      for (final t in templates) {
        expect(t.isBuiltIn, isTrue);
      }
    });

    test('seedDefaults each template has a locale-aware display name', () {
      final templates = _seedDefaults();
      for (final t in templates) {
        expect(t.name, isNotEmpty);
        expect(t.nameEn, isNotEmpty);
        expect(t.displayNameFor(true), equals(t.name));
        expect(t.displayNameFor(false), equals(t.nameEn));
      }
    });

    test('seedDefaults each template has valid layout', () {
      final templates = _seedDefaults();
      for (final t in templates) {
        expect(t.layout, isNotNull);
        expect(t.layout.value, isNotEmpty);
      }
    });

    test('seedDefaults each template has valid hex colors', () {
      final templates = _seedDefaults();
      for (final t in templates) {
        expect(t.fontColor, matches(RegExp(r'^#[0-9A-Fa-f]{6}$')));
        expect(t.bgColor, matches(RegExp(r'^#[0-9A-Fa-f]{6}$')));
      }
    });

    test('seedDefaults templates with decorationStyle have appropriate layout', () {
      final templates = _seedDefaults();
      final ink = templates.firstWhere((t) => t.id == 'tpl_ink_rhythm');
      expect(ink.decorationStyle, 'ink_wash');
      expect(ink.layout, CardLayout.heroImage);

      final seal = templates.firstWhere((t) => t.id == 'tpl_seal');
      expect(seal.decorationStyle, 'seal');
      expect(seal.layout, CardLayout.centered);

      final paper = templates.firstWhere((t) => t.id == 'tpl_plain_paper');
      expect(paper.decorationStyle, 'rice_paper');
      expect(paper.layout, CardLayout.leftAligned);
    });

    test('fromJson/toJson round-trip preserves all fields', () {
      final tpl = _seedDefaults().first;
      final json = tpl.toJson();
      final restored = CardTemplate.fromJson(json);
      expect(restored.id, tpl.id);
      expect(restored.name, tpl.name);
      expect(restored.nameEn, tpl.nameEn);
      expect(restored.icon, tpl.icon);
      expect(restored.fontFamily, tpl.fontFamily);
      expect(restored.fontColor, tpl.fontColor);
      expect(restored.bgColor, tpl.bgColor);
      expect(restored.isBuiltIn, tpl.isBuiltIn);
      expect(restored.layout, tpl.layout);
      expect(restored.accentColor, tpl.accentColor);
      expect(restored.textAreaOpacity, tpl.textAreaOpacity);
      expect(restored.textBackdropColor, tpl.textBackdropColor);
      expect(restored.footerText, tpl.footerText);
      expect(restored.showMood, tpl.showMood);
      expect(restored.showDate, tpl.showDate);
      expect(restored.showTags, tpl.showTags);
      expect(restored.showFooter, tpl.showFooter);
      expect(restored.cornerStyle, tpl.cornerStyle);
      expect(restored.decorationStyle, tpl.decorationStyle);
    });

    test('fromJson handles missing new fields with defaults', () {
      final json = {
        'id': 'test_id',
        'name': 'Test',
        'icon': '🧪',
        'font_family': 'default',
        'font_color': '#333333',
        'bg_color': '#FFFFFF',
        'is_built_in': 0,
        'created_at': DateTime.now().toIso8601String(),
        // New fields are missing
      };
      final tpl = CardTemplate.fromJson(json);
      expect(tpl.layout, CardLayout.heroImage);
      expect(tpl.textAreaOpacity, closeTo(0.85, 0.001));
      expect(tpl.showMood, isTrue);
      expect(tpl.showDate, isTrue);
      expect(tpl.showTags, isTrue);
      expect(tpl.showFooter, isTrue);
      expect(tpl.cornerStyle, CardCornerStyle.rounded);
      expect(tpl.accentColor, isNull);
      expect(tpl.decorationStyle, isNull);
    });

    test('toJson serializes booleans as integers', () {
      final json = _seedDefaults().first.toJson();
      expect(json['show_mood'], isA<int>());
      expect(json['show_date'], isA<int>());
      expect(json['show_tags'], isA<int>());
      expect(json['show_footer'], isA<int>());
    });

    test('toJson serializes layout as string', () {
      final json = _seedDefaults().first.toJson();
      expect(json['layout'], isA<String>());
      expect(json['layout'], isNotEmpty);
    });

    test('copyWith preserves new fields', () {
      final original = _seedDefaults().first;
      final copy = original.copyWith();
      expect(copy.layout, original.layout);
      expect(copy.accentColor, original.accentColor);
      expect(copy.textAreaOpacity, original.textAreaOpacity);
      expect(copy.decorationStyle, original.decorationStyle);
    });

    test('copyWith updates new fields', () {
      final original = _seedDefaults().first;
      final copy = original.copyWith(
        showMood: false,
        showDate: false,
        showTags: false,
        showFooter: false,
        layout: CardLayout.centered,
      );
      expect(copy.showMood, isFalse);
      expect(copy.showDate, isFalse);
      expect(copy.showTags, isFalse);
      expect(copy.showFooter, isFalse);
      expect(copy.layout, CardLayout.centered);
    });
  });

  group('CardLayout', () {
    test('all four variants have string values', () {
      expect(CardLayout.heroImage.value, 'hero_image');
      expect(CardLayout.centered.value, 'centered');
      expect(CardLayout.leftAligned.value, 'left_aligned');
      expect(CardLayout.twoColumn.value, 'two_column');
    });

    test('fromString returns correct layout', () {
      expect(CardLayoutExtension.fromString('hero_image'), CardLayout.heroImage);
      expect(CardLayoutExtension.fromString('centered'), CardLayout.centered);
      expect(CardLayoutExtension.fromString('left_aligned'), CardLayout.leftAligned);
      expect(CardLayoutExtension.fromString('two_column'), CardLayout.twoColumn);
    });

    test('fromString defaults to heroImage for unknown values', () {
      expect(CardLayoutExtension.fromString('unknown'), CardLayout.heroImage);
      expect(CardLayoutExtension.fromString(''), CardLayout.heroImage);
    });
  });

  group('CardCornerStyle', () {
    test('all three variants have string values', () {
      expect(CardCornerStyle.rounded.value, 'rounded');
      expect(CardCornerStyle.sharp.value, 'sharp');
      expect(CardCornerStyle.pill.value, 'pill');
    });

    test('fromString returns correct style', () {
      expect(CardCornerStyleExtension.fromString('rounded'), CardCornerStyle.rounded);
      expect(CardCornerStyleExtension.fromString('sharp'), CardCornerStyle.sharp);
      expect(CardCornerStyleExtension.fromString('pill'), CardCornerStyle.pill);
    });

    test('fromString defaults to rounded for unknown values', () {
      expect(CardCornerStyleExtension.fromString('unknown'), CardCornerStyle.rounded);
    });
  });
}

List<CardTemplate> _seedDefaults() => [
      CardTemplate(
          id: 'tpl_ink_rhythm',
          name: '墨韵',
          nameEn: 'Ink Rhythm',
          icon: '🖋️',
          fontColor: '#2C2C2C',
          bgColor: '#F5F0E8',
          isBuiltIn: true,
          createdAt: DateTime.now(),
          layout: CardLayout.heroImage,
          accentColor: '#C43A31',
          textAreaOpacity: 0.85,
          textBackdropColor: 'rgba(245,240,232,0.85)',
          decorationStyle: 'ink_wash'),
      CardTemplate(
          id: 'tpl_plain_paper',
          name: '素笺',
          nameEn: 'Plain Paper',
          icon: '📃',
          fontColor: '#2C2C2C',
          bgColor: '#F5F0E8',
          isBuiltIn: true,
          createdAt: DateTime.now(),
          layout: CardLayout.leftAligned,
          accentColor: '#C43A31',
          textAreaOpacity: 0.85,
          decorationStyle: 'rice_paper'),
      CardTemplate(
          id: 'tpl_bamboo',
          name: '竹影',
          nameEn: 'Bamboo Shadow',
          icon: '🎋',
          fontColor: '#2C2C2C',
          bgColor: '#EDF5EC',
          isBuiltIn: true,
          createdAt: DateTime.now(),
          layout: CardLayout.heroImage,
          accentColor: '#7A9A6D',
          textAreaOpacity: 0.85,
          textBackdropColor: 'rgba(237,245,236,0.85)',
          decorationStyle: 'bamboo'),
      CardTemplate(
          id: 'tpl_moonlight',
          name: '月色',
          nameEn: 'Moonlight',
          icon: '🌙',
          fontColor: '#E8E4DF',
          bgColor: '#1B2838',
          isBuiltIn: true,
          createdAt: DateTime.now(),
          layout: CardLayout.centered,
          textAreaOpacity: 0.80,
          decorationStyle: 'crescent'),
      CardTemplate(
          id: 'tpl_porcelain',
          name: '青花',
          nameEn: 'Blue Porcelain',
          icon: '🏺',
          fontColor: '#2B5F8A',
          bgColor: '#FAFAF6',
          isBuiltIn: true,
          createdAt: DateTime.now(),
          layout: CardLayout.centered,
          accentColor: '#2B5F8A',
          textAreaOpacity: 0.85,
          decorationStyle: 'porcelain'),
      CardTemplate(
          id: 'tpl_tea',
          name: '茶语',
          nameEn: 'Tea Whisper',
          icon: '🍵',
          fontColor: '#5C4033',
          bgColor: '#F5EDE3',
          isBuiltIn: true,
          createdAt: DateTime.now(),
          layout: CardLayout.heroImage,
          accentColor: '#D4A76A',
          textAreaOpacity: 0.85,
          textBackdropColor: 'rgba(245,237,227,0.85)',
          decorationStyle: 'tea'),
      CardTemplate(
          id: 'tpl_seal',
          name: '朱砂',
          nameEn: 'Cinnabar Seal',
          icon: '🔴',
          fontColor: '#2C2C2C',
          bgColor: '#F5F0E8',
          isBuiltIn: true,
          createdAt: DateTime.now(),
          layout: CardLayout.centered,
          accentColor: '#C43A31',
          textAreaOpacity: 0.85,
          decorationStyle: 'seal'),
      CardTemplate(
          id: 'tpl_landscape',
          name: '山水',
          nameEn: 'Landscape',
          icon: '🏔️',
          fontColor: '#2C2C2C',
          bgColor: '#D6E0E8',
          isBuiltIn: true,
          createdAt: DateTime.now(),
          layout: CardLayout.heroImage,
          accentColor: '#6B7B8D',
          textAreaOpacity: 0.85,
          textBackdropColor: 'rgba(214,224,232,0.85)',
          decorationStyle: 'landscape'),
    ];
