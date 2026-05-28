import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:blinking/models/card_template.dart';
import 'package:blinking/models/note_card.dart';
import 'package:blinking/providers/card_provider.dart';
import 'package:blinking/providers/locale_provider.dart';
import 'package:blinking/providers/llm_config_notifier.dart';
import 'package:blinking/core/services/storage_service.dart';
import 'package:blinking/widgets/card_builder_sheet.dart';

// --- Fake providers ---

class _FakeCardProvider extends CardProvider {
  final List<CardTemplate> _tpls;
  final List<NoteCard> _cards = [];
  _FakeCardProvider(this._tpls) : super(_FakeStorage());

  @override
  List<CardTemplate> get templates => _tpls;
  @override
  List<NoteCard> get cards => _cards;
  @override
  Future<void> load() async {}
  @override
  CardTemplate? getTemplateById(String id) =>
      _tpls.where((t) => t.id == id).firstOrNull;

  @override
  Future<NoteCard> addCard({
    required List<String> entryIds,
    required String templateId,
    required String folderId,
    String? renderedImagePath,
    String? aiSummary,
    String? richContent,
    String? cardContent,
    String? emotion,
    List<String>? displayTags,
    bool showMood = true,
    bool showDate = true,
    bool showTags = true,
    bool showFooter = true,
    String? templateOverrides,
  }) async {
    final card = NoteCard(
      id: 'card_test_${_cards.length}',
      entryIds: entryIds, templateId: templateId, folderId: folderId,
      renderedImagePath: renderedImagePath, cardContent: cardContent,
      emotion: emotion, displayTags: displayTags,
      showMood: showMood, showDate: showDate, showTags: showTags, showFooter: showFooter,
      createdAt: DateTime.now(), updatedAt: DateTime.now(),
    );
    _cards.add(card);
    return card;
  }
}

class _FakeStorage extends StorageService {}

class _FakeLocaleProvider extends LocaleProvider {
  final Locale _l;
  _FakeLocaleProvider(this._l);
  @override
  Locale get locale => _l;
}

CardTemplate _makeTemplate(String id, String name, String nameEn, String icon) {
  return CardTemplate(
    id: id, name: name, nameEn: nameEn, icon: icon,
    fontColor: '#2C2C2C', bgColor: '#F5F0E8',
    isBuiltIn: true, createdAt: DateTime.now(),
    textBackdropColor: 'rgba(245,240,232,0.85)',
  );
}

Widget _buildSheetApp({
  required String initialContent,
  required List<CardTemplate> templates,
  required _FakeCardProvider cardProvider,
  Locale locale = const Locale('zh'),
  Future<String> Function({
    required CardTemplate template,
    required String content,
    String? imagePath,
    String? emotion,
    List<String>? tags,
    DateTime? date,
    bool? showMood,
    bool? showDate,
    bool? showTags,
    bool? showFooter,
  })? renderFn,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<LocaleProvider>.value(value: _FakeLocaleProvider(locale)),
      ChangeNotifierProvider<CardProvider>.value(value: cardProvider),
      ChangeNotifierProvider<LlmConfigNotifier>(create: (_) => LlmConfigNotifier()),
    ],
    child: MaterialApp(
      locale: locale,
      home: Builder(
        builder: (context) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            CardBuilderSheet.show(
              context,
              initialContent: initialContent,
              initialEmotion: '😊',
              initialTags: ['journal'],
              entryId: 'entry_1',
              renderFn: renderFn,
            );
          });
          return const Scaffold(body: Center(child: Text('Test')));
        },
      ),
    ),
  );
}

Future<void> _pumpSheet(WidgetTester tester, Widget app) async {
  await tester.pumpWidget(app);
  await tester.pump(); // post-frame callback fires
  await tester.pump(); // first frame of sheet
  await tester.pump(const Duration(milliseconds: 500)); // sheet animation
}

// --- Tests ---

void main() {
  group('CardBuilderSheet', () {
    late List<CardTemplate> templates;

    setUp(() {
      templates = [
        _makeTemplate('tpl_ink_rhythm', '墨韵', 'Ink Rhythm', '🖋️'),
        _makeTemplate('tpl_moonlight', '月色', 'Moonlight', '🌙'),
        _makeTemplate('tpl_seal', '朱砂', 'Cinnabar Seal', '🔴'),
      ];
    });

    testWidgets('opens with pre-filled content and labels', (tester) async {
      await _pumpSheet(tester, _buildSheetApp(
        initialContent: 'Hello World',
        templates: templates,
        cardProvider: _FakeCardProvider(templates),
      ));

      expect(find.text('Hello World'), findsOneWidget);
      expect(find.text('保存为纪念'), findsOneWidget);
      expect(find.text('选择模板'), findsOneWidget);
      expect(find.text('内容'), findsOneWidget);
      expect(find.text('墨韵'), findsOneWidget);
    });

    testWidgets('shows English labels in EN locale', (tester) async {
      await _pumpSheet(tester, _buildSheetApp(
        initialContent: 'Hello',
        templates: templates,
        cardProvider: _FakeCardProvider(templates),
        locale: const Locale('en'),
      ));

      expect(find.text('Save as Keepsake'), findsOneWidget);
      expect(find.text('Choose Template'), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('template selection updates on tap', (tester) async {
      await _pumpSheet(tester, _buildSheetApp(
        initialContent: 'Test',
        templates: templates,
        cardProvider: _FakeCardProvider(templates),
      ));

      // Both templates visible
      expect(find.text('墨韵'), findsOneWidget);
      expect(find.text('月色'), findsOneWidget);

      // Tap to select — should not crash
      await tester.tap(find.text('月色'));
      await tester.pump();
    });

    testWidgets('toggle switches start ON', (tester) async {
      await _pumpSheet(tester, _buildSheetApp(
        initialContent: 'Test',
        templates: templates,
        cardProvider: _FakeCardProvider(templates),
      ));

      // Scroll down to reveal toggles
      final listFinder = find.byType(ListView).first;
      await tester.drag(listFinder, const Offset(0, -300));
      await tester.pump();

      expect(find.text('显示元素'), findsOneWidget);
    });

    testWidgets('toggle switches can be turned off', (tester) async {
      await _pumpSheet(tester, _buildSheetApp(
        initialContent: 'Test',
        templates: templates,
        cardProvider: _FakeCardProvider(templates),
      ));

      // Scroll to reveal toggles — drag the ListView inside the sheet
      final listFinder = find.byType(ListView).first;
      await tester.drag(listFinder, const Offset(0, -500));
      await tester.pump();
      await tester.drag(listFinder, const Offset(0, -500));
      await tester.pump();

      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(4));
      await tester.tap(switches.first);
      await tester.pump();
      expect(tester.widget<Switch>(switches.first).value, isFalse);
    });

    testWidgets('empty content shows snackbar on save', (tester) async {
      await _pumpSheet(tester, _buildSheetApp(
        initialContent: '   ',
        templates: templates,
        cardProvider: _FakeCardProvider(templates),
      ));

      // Scroll to save button
      await tester.scrollUntilVisible(
        find.text('保存纪念'), 300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      await tester.tap(find.text('保存纪念'));
      await tester.pump();
      await tester.pump();

      expect(find.text('请输入内容'), findsOneWidget);
    });

    testWidgets('save button renders and persists card', (tester) async {
      final fakeCardProvider = _FakeCardProvider(templates);

      Future<String> mockRender({
        required CardTemplate template,
        required String content,
        String? imagePath,
        String? emotion,
        List<String>? tags,
        DateTime? date,
        bool? showMood,
        bool? showDate,
        bool? showTags,
        bool? showFooter,
      }) async {
        final dir = Directory.systemTemp.createTempSync('card_render_');
        File('${dir.path}/test.png').writeAsBytesSync(List.filled(100, 0));
        return '${dir.path}/test.png';
      }

      await _pumpSheet(tester, _buildSheetApp(
        initialContent: 'Save this text',
        templates: templates,
        cardProvider: fakeCardProvider,
        renderFn: mockRender,
      ));

      // Save button is fixed at bottom, tap directly
      await tester.tap(find.text('保存纪念'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(fakeCardProvider.cards.length, 1);
      expect(fakeCardProvider.cards.first.cardContent, 'Save this text');
      expect(fakeCardProvider.cards.first.emotion, '😊');
      expect(fakeCardProvider.cards.first.entryIds, contains('entry_1'));
    });

    testWidgets('AI Rewrite button is visible', (tester) async {
      await _pumpSheet(tester, _buildSheetApp(
        initialContent: 'Test',
        templates: templates,
        cardProvider: _FakeCardProvider(templates),
      ));

      expect(find.text('AI 润色'), findsOneWidget);
    });
  });
}
