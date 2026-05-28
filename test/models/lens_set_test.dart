import 'package:flutter_test/flutter_test.dart';
import 'package:blinking/models/lens_set.dart';

void main() {
  group('LensSet', () {
    test('creates lens sets for all 4 personas', () {
      final sets = DefaultLensSets.defaults(true);
      expect(sets.length, 4);

      final kael = sets.firstWhere((s) => s.id == 'lens_style_kael');
      expect(kael.label, contains('楷迩'));
      expect(kael.lenses.length, 3);
      expect(kael.isBuiltin, true);
    });

    test('default active set is Kael', () {
      expect(DefaultLensSets.defaultActiveSetId, 'lens_style_kael');
    });

    test('each persona has unique lenses', () {
      final enSets = DefaultLensSets.defaults(false);
      final ids = enSets.map((s) => s.id).toSet();
      expect(ids, containsAll(['lens_style_kael', 'lens_style_elara', 'lens_style_rush', 'lens_style_marcus']));
    });

    test('toJson and fromJson round-trip', () {
      final set = LensSet(
        id: 'test_id',
        label: 'Test',
        lens1: 'Lens 1',
        lens2: 'Lens 2',
        lens3: 'Lens 3',
        isBuiltin: false,
        sortOrder: 5,
        createdAt: DateTime(2026, 5, 8),
      );
      final json = set.toJson();
      final restored = LensSet.fromJson(json);
      expect(restored.id, set.id);
      expect(restored.label, set.label);
      expect(restored.lenses, set.lenses);
      expect(restored.isBuiltin, set.isBuiltin);
      expect(restored.sortOrder, set.sortOrder);
    });
  });
}
