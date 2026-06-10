import 'package:flutter_test/flutter_test.dart';
import 'package:stalio/models/tag_category.dart';

void main() {
  final testCategory = TagCategory(
    id: 'cat_test_1',
    name: '健康',
    nameEn: 'Health',
    color: '#34C759',
    icon: '💚',
    sortOrder: 0,
    createdAt: DateTime(2026, 6, 1),
  );

  group('TagCategory', () {
    group('toJson / fromJson round-trip', () {
      test('serializes and deserializes correctly', () {
        final json = testCategory.toJson();
        final restored = TagCategory.fromJson(json);
        expect(restored.id, 'cat_test_1');
        expect(restored.name, '健康');
        expect(restored.nameEn, 'Health');
        expect(restored.color, '#34C759');
        expect(restored.icon, '💚');
        expect(restored.sortOrder, 0);
        expect(restored.createdAt, DateTime(2026, 6, 1));
      });

      test('fromJson uses defaults for missing optional fields', () {
        final json = {
          'id': 'cat_min',
          'name': 'Min',
          'nameEn': 'Min',
          'color': '#000',
          'createdAt': '2026-06-01T00:00:00.000',
        };
        final cat = TagCategory.fromJson(json);
        expect(cat.icon, '📁');
        expect(cat.sortOrder, 0);
      });
    });

    group('copyWith', () {
      test('preserves unchanged fields', () {
        final copy = testCategory.copyWith();
        expect(copy.id, 'cat_test_1');
        expect(copy.name, '健康');
        expect(copy.nameEn, 'Health');
        expect(copy.color, '#34C759');
        expect(copy.icon, '💚');
        expect(copy.sortOrder, 0);
      });

      test('updates specified fields', () {
        final copy = testCategory.copyWith(
          name: '运动',
          nameEn: 'Exercise',
          color: '#FF9500',
          icon: '🏃',
          sortOrder: 5,
        );
        expect(copy.name, '运动');
        expect(copy.nameEn, 'Exercise');
        expect(copy.color, '#FF9500');
        expect(copy.icon, '🏃');
        expect(copy.sortOrder, 5);
        expect(copy.id, 'cat_test_1');
        expect(copy.createdAt, DateTime(2026, 6, 1));
      });
    });

    group('displayName', () {
      test('shows Chinese name when isZh is true', () {
        expect(testCategory.displayName(true), '健康');
      });

      test('shows English name when isZh is false', () {
        expect(testCategory.displayName(false), 'Health');
      });
    });
  });
}
