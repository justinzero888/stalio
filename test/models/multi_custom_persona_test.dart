import 'package:flutter_test/flutter_test.dart';
import 'package:blinking/models/reflection_style.dart';

void main() {
  group('Multi-custom persona support', () {
    final custom1 = {
      'name': 'Vesper',
      'emoji': '🌙',
      'vibe': 'Slow & Meditative',
      'persona': 'You are Vesper, slow and meditative.',
      'lens1': 'What settled?',
      'lens2': 'What resisted?',
      'lens3': 'What carry forward?',
    };
    final custom2 = {
      'name': 'Nova',
      'emoji': '💫',
      'vibe': 'Energetic Coach',
      'persona': 'You are Nova, an energetic coach.',
      'lens1': 'What win?',
      'lens2': 'What fear?',
      'lens3': 'What bold move?',
    };

    test('registers single custom style at custom_0', () {
      ReflectionStyle.registerCustomStyles([custom1]);
      final style = ReflectionStyle.byId('custom_0');
      expect(style.id, 'custom_0');
      expect(style.name, 'Vesper');
      expect(style.emoji, '🌙');
    });

    test('registers multiple custom styles at sequential indices', () {
      ReflectionStyle.registerCustomStyles([custom1, custom2]);
      final s0 = ReflectionStyle.byId('custom_0');
      final s1 = ReflectionStyle.byId('custom_1');
      expect(s0.name, 'Vesper');
      expect(s1.name, 'Nova');
    });

    test('byId falls back to preset for unknown IDs', () {
      ReflectionStyle.registerCustomStyles([]);
      final style = ReflectionStyle.byId('custom_99');
      expect(style.id, 'kael'); // default
    });

    test('byId returns preset for built-in IDs', () {
      ReflectionStyle.registerCustomStyles([custom1]);
      final style = ReflectionStyle.byId('rush');
      expect(style.name, 'Rush');
    });

    test('custom styles coexist with presets', () {
      ReflectionStyle.registerCustomStyles([custom1, custom2]);
      expect(ReflectionStyle.byId('custom_0').name, 'Vesper');
      expect(ReflectionStyle.byId('kael').name, 'Kael');
      expect(ReflectionStyle.byId('custom_1').name, 'Nova');
      expect(ReflectionStyle.byId('elara').name, 'Elara');
    });

    test('registerCustomStyles clears previous cache', () {
      ReflectionStyle.registerCustomStyles([custom1, custom2]);
      expect(ReflectionStyle.customCache.length, 2);
      ReflectionStyle.registerCustomStyles([]);
      expect(ReflectionStyle.customCache.length, 0);
    });

    test('fromJson supports custom id parameter', () {
      final style = ReflectionStyle.fromJson(custom1, id: 'custom_5');
      expect(style.id, 'custom_5');
      expect(style.name, 'Vesper');
    });
  });
}
