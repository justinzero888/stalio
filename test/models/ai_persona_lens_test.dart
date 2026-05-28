import 'package:flutter_test/flutter_test.dart';
import 'package:blinking/models/reflection_style.dart';
import 'package:blinking/models/lens_set.dart';

void main() {
  group('Persona → Lens mapping', () {
    test('each preset has its own unique lens questions', () {
      final ids = ReflectionStyle.presets.map((s) => s.id).toSet();
      final lensSets = <String, List<String>>{};
      for (final s in ReflectionStyle.presets) {
        final lenses = s.lenses(false);
        lensSets[s.id] = lenses;
        expect(lenses.length, 3);
        expect(lenses.every((l) => l.isNotEmpty), true);
      }
      // Each persona has DIFFERENT lens questions
      expect(lensSets['kael'], isNot(lensSets['elara']));
      expect(lensSets['elara'], isNot(lensSets['rush']));
      expect(lensSets['rush'], isNot(lensSets['marcus']));
    });

    test('each preset has localized lenses', () {
      for (final s in ReflectionStyle.presets) {
        final en = s.lenses(false);
        final zh = s.lenses(true);
        expect(en.length, 3);
        expect(zh.length, 3);
        // Localized versions differ
        expect(en[0], isNot(zh[0]));
        expect(en[1], isNot(zh[1]));
        expect(en[2], isNot(zh[2]));
      }
    });

    test('lens style ID format is correct', () {
      for (final s in ReflectionStyle.presets) {
        final lensId = 'lens_style_${s.id}';
        expect(lensId, startsWith('lens_style_'));
        expect(lensId, contains(s.id));
      }
    });

    test('custom persona lens IDs are indexed', () {
      expect('lens_style_custom_0', startsWith('lens_style_custom_'));
      expect('lens_style_custom_5', startsWith('lens_style_custom_'));
      expect('lens_style_custom_10', startsWith('lens_style_custom_'));
    });

    test('custom persona from existing JSON has correct lenses', () {
      final json = {
        'name': 'Vesper',
        'emoji': '🌙',
        'vibe': 'Slow & Meditative',
        'persona': 'You are Vesper.',
        'lens1': 'What settled?',
        'lens2': 'What resisted?',
        'lens3': 'What carry?',
      };
      final style = ReflectionStyle.fromJson(json, id: 'custom_3');
      expect(style.id, 'custom_3');
      expect(style.lenses(false), ['What settled?', 'What resisted?', 'What carry?']);
      expect(style.lenses(true), ['What settled?', 'What resisted?', 'What carry?']);
    });
  });

  group('ReflectionStyle defaults', () {
    test('default style is Kael', () {
      expect(ReflectionStyle.defaultStyleId, 'kael');
      final d = ReflectionStyle.byId('kael');
      expect(d.name, 'Kael');
      expect(d.nameZh, '楷迩');
    });

    test('presets have correct count', () {
      expect(ReflectionStyle.presets.length, 4);
    });

    test('each preset has avatarAsset set', () {
      for (final s in ReflectionStyle.presets) {
        expect(s.avatarAsset, isNotNull);
        expect(s.avatarAsset, startsWith('assets/avatars/'));
      }
    });

    test('each preset has CN avatar', () {
      for (final s in ReflectionStyle.presets) {
        expect(s.avatarAssetCn, isNotNull);
        expect(s.avatarAssetCn, endsWith('_cn.png'));
      }
    });

    test('CN avatar switches with locale', () {
      final style = ReflectionStyle.byId('kael');
      expect(style.avatarAssetFor(false), 'assets/avatars/kael.png');
      expect(style.avatarAssetFor(true), 'assets/avatars/kael_cn.png');
    });
  });

  group('Multi-custom persona cache', () {
    test('registerCustomStyles creates correct IDs', () {
      final styles = [
        {'name': 'A', 'emoji': '1', 'vibe': 'a', 'persona': '', 'lens1': '', 'lens2': '', 'lens3': ''},
        {'name': 'B', 'emoji': '2', 'vibe': 'b', 'persona': '', 'lens1': '', 'lens2': '', 'lens3': ''},
        {'name': 'C', 'emoji': '3', 'vibe': 'c', 'persona': '', 'lens1': '', 'lens2': '', 'lens3': ''},
      ];
      ReflectionStyle.registerCustomStyles(styles);
      expect(ReflectionStyle.customCache.length, 3);
      expect(ReflectionStyle.byId('custom_0').name, 'A');
      expect(ReflectionStyle.byId('custom_1').name, 'B');
      expect(ReflectionStyle.byId('custom_2').name, 'C');
    });

    test('custom styles coexist with presets in byId', () {
      ReflectionStyle.registerCustomStyles([
        {'name': 'X', 'emoji': 'x', 'vibe': 'x', 'persona': '', 'lens1': '', 'lens2': '', 'lens3': ''},
      ]);
      expect(ReflectionStyle.byId('custom_0').name, 'X');
      expect(ReflectionStyle.byId('kael').name, 'Kael');
      expect(ReflectionStyle.byId('rush').name, 'Rush');
    });

    test('unknown custom ID falls back to default', () {
      ReflectionStyle.registerCustomStyles([]);
      final s = ReflectionStyle.byId('custom_999');
      expect(s.id, 'kael');
    });
  });
}
