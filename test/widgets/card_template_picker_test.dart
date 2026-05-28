import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:blinking/models/card_template.dart';
import 'package:blinking/providers/card_provider.dart';
import 'package:blinking/providers/locale_provider.dart';
import 'package:blinking/core/services/storage_service.dart';
import 'package:blinking/widgets/card_template_picker.dart';

CardTemplate _makeTemplate(String id, String name, String nameEn, String icon) {
  return CardTemplate(
    id: id, name: name, nameEn: nameEn, icon: icon,
    fontColor: '#2C2C2C', bgColor: '#F5F0E8',
    isBuiltIn: true, createdAt: DateTime.now(),
  );
}

class _FakeCardProvider extends CardProvider {
  final List<CardTemplate> _tpls;
  _FakeCardProvider(this._tpls) : super(_FakeStorage());

  @override
  List<CardTemplate> get templates => _tpls;

  @override
  Future<void> load() async {}

  @override
  CardTemplate? getTemplateById(String id) =>
      _tpls.where((t) => t.id == id).firstOrNull;
}

class _FakeStorage extends StorageService {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeLocaleProvider extends LocaleProvider {
  final Locale _l;
  _FakeLocaleProvider(this._l);

  @override
  Locale get locale => _l;
}

void main() {
  group('CardTemplatePicker', () {
    Widget _buildWidget({
      required List<CardTemplate> templates,
      CardTemplate? selected,
      required ValueChanged<CardTemplate> onSelected,
      Locale locale = const Locale('zh'),
    }) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<LocaleProvider>.value(
            value: _FakeLocaleProvider(locale),
          ),
          ChangeNotifierProvider<CardProvider>.value(
            value: _FakeCardProvider(templates),
          ),
        ],
        child: MaterialApp(
          locale: locale,
          home: Scaffold(
            body: CardTemplatePicker(
              selectedTemplate: selected,
              onTemplateSelected: onSelected,
            ),
          ),
        ),
      );
    }

    testWidgets('renders template thumbnails with Chinese names', (tester) async {
      final templates = [
        _makeTemplate('tpl_1', '墨韵', 'Ink Rhythm', '🖋️'),
        _makeTemplate('tpl_2', '素笺', 'Plain Paper', '📃'),
        _makeTemplate('tpl_3', '月色', 'Moonlight', '🌙'),
      ];

      await tester.pumpWidget(_buildWidget(
        templates: templates,
        onSelected: (_) {},
      ));
      await tester.pump();

      expect(find.text('墨韵'), findsOneWidget);
      expect(find.text('素笺'), findsOneWidget);
      expect(find.text('月色'), findsOneWidget);
    });

    testWidgets('shows English names in EN locale', (tester) async {
      final templates = [
        _makeTemplate('tpl_1', '墨韵', 'Ink Rhythm', '🖋️'),
      ];

      await tester.pumpWidget(_buildWidget(
        templates: templates,
        onSelected: (_) {},
        locale: const Locale('en'),
      ));
      await tester.pump();

      expect(find.text('Ink Rhythm'), findsOneWidget);
    });

    testWidgets('tap selects template and triggers callback', (tester) async {
      final templates = [
        _makeTemplate('tpl_1', '墨韵', 'Ink Rhythm', '🖋️'),
        _makeTemplate('tpl_3', '月色', 'Moonlight', '🌙'),
      ];
      CardTemplate? selected;

      await tester.pumpWidget(_buildWidget(
        templates: templates,
        onSelected: (t) => selected = t,
      ));
      await tester.pump();

      await tester.tap(find.text('月色'));
      await tester.pump();

      expect(selected, isNotNull);
      expect(selected!.id, 'tpl_3');
    });
  });
}
