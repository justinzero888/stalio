import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blinking/models/card_enums.dart';
import 'package:blinking/models/card_template.dart';
import 'package:blinking/core/services/card_render_service.dart';

CardTemplate _makeTemplate({
  String id = 'tpl_test',
  String name = 'Test',
  CardLayout layout = CardLayout.heroImage,
  String bgColor = '#F5F0E8',
  String fontColor = '#2C2C2C',
  String? accentColor,
  String? textBackdropColor,
  String? decorationStyle,
}) {
  return CardTemplate(
    id: id, name: name, nameEn: 'Test', icon: '🧪',
    fontColor: fontColor, bgColor: bgColor,
    isBuiltIn: true, createdAt: DateTime.now(),
    layout: layout, accentColor: accentColor,
    textBackdropColor: textBackdropColor,
    decorationStyle: decorationStyle,
    showMood: true, showDate: true, showTags: true, showFooter: true,
  );
}

void main() {
  group('CardRenderService.buildPreviewWidget', () {
    test('hero_image layout returns widget', () {
      final w = CardRenderService.buildPreviewWidget(
        template: _makeTemplate(), content: 'Test',
      );
      expect(w, isNotNull);
    });

    test('centered layout returns widget', () {
      final w = CardRenderService.buildPreviewWidget(
        template: _makeTemplate(layout: CardLayout.centered), content: 'Test',
      );
      expect(w, isNotNull);
    });

    test('left_aligned layout returns widget', () {
      final w = CardRenderService.buildPreviewWidget(
        template: _makeTemplate(layout: CardLayout.leftAligned), content: 'Test',
      );
      expect(w, isNotNull);
    });

    test('two_column layout returns widget', () {
      final w = CardRenderService.buildPreviewWidget(
        template: _makeTemplate(layout: CardLayout.twoColumn), content: 'Test',
      );
      expect(w, isNotNull);
    });

    test('with all overlay options returns widget', () {
      final w = CardRenderService.buildPreviewWidget(
        template: _makeTemplate(),
        content: 'Test',
        emotion: '😊',
        tags: ['journal', 'morning'],
        date: DateTime(2026, 6, 1),
        showMood: true, showDate: true, showTags: true, showFooter: true,
      );
      expect(w, isNotNull);
    });

    test('with all toggles off returns widget', () {
      final w = CardRenderService.buildPreviewWidget(
        template: _makeTemplate(),
        content: 'Test',
        showMood: false, showDate: false, showTags: false, showFooter: false,
      );
      expect(w, isNotNull);
    });

    test('with style overrides returns widget', () {
      final w = CardRenderService.buildPreviewWidget(
        template: _makeTemplate(),
        content: 'Test',
        styleOverrides: {'font_color': '#FF0000', 'accent_color': '#0000FF'},
      );
      expect(w, isNotNull);
    });
  });

  group('CardRenderService renders without crash', () {
    testWidgets('hero layout renders', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: CardRenderService.buildPreviewWidget(
            template: _makeTemplate(), content: 'Hello World',
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Hello World'), findsOneWidget);
    });

    testWidgets('centered layout renders', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: CardRenderService.buildPreviewWidget(
            template: _makeTemplate(layout: CardLayout.centered), content: 'Centered',
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Centered'), findsOneWidget);
    });

    testWidgets('left_aligned layout renders', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: CardRenderService.buildPreviewWidget(
            template: _makeTemplate(layout: CardLayout.leftAligned), content: 'Left',
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Left'), findsOneWidget);
    });

    testWidgets('two_column layout renders', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: CardRenderService.buildPreviewWidget(
            template: _makeTemplate(layout: CardLayout.twoColumn), content: 'Two',
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Two'), findsOneWidget);
    });

    testWidgets('each of 8 templates renders without crash', (tester) async {
      final templates = [
        _makeTemplate(id: 'tpl_ink_rhythm', decorationStyle: 'ink_wash'),
        _makeTemplate(id: 'tpl_bamboo', decorationStyle: 'bamboo', accentColor: '#7A9A6D'),
        _makeTemplate(id: 'tpl_moonlight', decorationStyle: 'crescent', bgColor: '#1B2838', fontColor: '#E8E4DF'),
        _makeTemplate(id: 'tpl_porcelain', decorationStyle: 'porcelain', accentColor: '#2B5F8A', layout: CardLayout.centered),
        _makeTemplate(id: 'tpl_tea', decorationStyle: 'tea'),
        _makeTemplate(id: 'tpl_seal', decorationStyle: 'seal', layout: CardLayout.centered),
        _makeTemplate(id: 'tpl_landscape', decorationStyle: 'landscape'),
        _makeTemplate(id: 'tpl_plain_paper', decorationStyle: 'rice_paper', layout: CardLayout.leftAligned),
      ];
      for (final tpl in templates) {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: CardRenderService.buildPreviewWidget(
              template: tpl, content: 'Template test',
            ),
          ),
        );
        await tester.pump();
      }
    });

    testWidgets('renders long text with auto-font sizing', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: CardRenderService.buildPreviewWidget(
            template: _makeTemplate(), content: 'A' * 2000,
          ),
        ),
      );
      await tester.pump();
    });

    testWidgets('renders short text', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: CardRenderService.buildPreviewWidget(
            template: _makeTemplate(), content: 'Hi',
          ),
        ),
      );
      await tester.pump();
    });

    testWidgets('renders CJK text', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: CardRenderService.buildPreviewWidget(
            template: _makeTemplate(), content: '今天天气很好，我去公园散步了。',
          ),
        ),
      );
      await tester.pump();
    });

    testWidgets('renders mixed CJK and English', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: CardRenderService.buildPreviewWidget(
            template: _makeTemplate(), content: 'Hello 世界! Today 天气 is 很好.',
          ),
        ),
      );
      await tester.pump();
    });

    testWidgets('renders emoji in text', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: CardRenderService.buildPreviewWidget(
            template: _makeTemplate(), content: 'Feeling happy 😊 today! 🌞',
          ),
        ),
      );
      await tester.pump();
    });

    testWidgets('renders with all toggles off', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: CardRenderService.buildPreviewWidget(
            template: _makeTemplate(),
            content: 'Minimal',
            showMood: false, showDate: false, showTags: false, showFooter: false,
          ),
        ),
      );
      await tester.pump();
    });

    testWidgets('renders with overlay elements', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: CardRenderService.buildPreviewWidget(
            template: _makeTemplate(),
            content: 'Full',
            emotion: '😊',
            tags: ['journal'],
            date: DateTime(2026, 6, 1),
          ),
        ),
      );
      await tester.pump();
    });

    testWidgets('renders empty content gracefully', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: CardRenderService.buildPreviewWidget(
            template: _makeTemplate(), content: '  ',
          ),
        ),
      );
      await tester.pump();
    });
  });

  group('CardRenderService.captureFromKey', () {
    test('captureFromKey returns null for unmounted key', () async {
      final key = GlobalKey();
      final path = await CardRenderService.captureFromKey(key);
      expect(path, isNull);
    });
  });
}
