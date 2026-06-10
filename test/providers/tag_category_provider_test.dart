import 'package:flutter_test/flutter_test.dart';
import 'package:stalio/models/tag.dart';
import 'package:stalio/models/tag_category.dart';
import 'package:stalio/providers/tag_category_provider.dart';
import 'package:stalio/repositories/tag_category_repository.dart';
import 'package:stalio/core/services/storage_service.dart';

class _MockStorageService extends StorageService {
  final List<TagCategory> _categories = [];
  final List<Tag> _tags = [];

  @override
  Future<void> init() async {}

  @override
  Future<List<TagCategory>> getTagCategories() async => List.of(_categories);

  @override
  Future<void> addTagCategory(TagCategory category) async {
    _categories.add(category);
  }

  @override
  Future<void> updateTagCategory(TagCategory category) async {
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index != -1) _categories[index] = category;
  }

  @override
  Future<void> deleteTagCategory(String id) async {
    _categories.removeWhere((c) => c.id == id);
  }

  @override
  Future<void> reorderTagCategories(List<TagCategory> categories) async {
    for (int i = 0; i < categories.length; i++) {
      final index = _categories.indexWhere((c) => c.id == categories[i].id);
      if (index != -1) {
        _categories[index] = _categories[index].copyWith(sortOrder: i);
      }
    }
  }

  @override
  Future<List<Tag>> getTagsByCategoryId(String categoryId) async {
    return _tags.where((t) => t.categoryId == categoryId).toList();
  }

  @override
  Future<void> updateTag(Tag tag) async {
    final index = _tags.indexWhere((t) => t.id == tag.id);
    if (index != -1) _tags[index] = tag;
  }

  void addMockTag(Tag tag) => _tags.add(tag);
}

void main() {
  late _MockStorageService storage;
  late TagCategoryRepository repository;
  late TagCategoryProvider provider;

  final testCategory = TagCategory(
    id: 'cat_test_1',
    name: '健康',
    nameEn: 'Health',
    color: '#34C759',
    icon: '💚',
    sortOrder: 0,
    createdAt: DateTime(2026, 6, 1),
  );

  setUp(() {
    storage = _MockStorageService();
    repository = TagCategoryRepository(storage);
    provider = TagCategoryProvider(repository);
  });

  group('TagCategoryProvider', () {
    group('initial state', () {
      test('has empty categories and no error initially', () {
        expect(provider.categories, isEmpty);
        expect(provider.isLoading, false);
        expect(provider.error, isNull);
      });

      test('getCategoryById returns null for unknown id', () {
        expect(provider.getCategoryById('nonexistent'), isNull);
      });
    });

    group('loadCategoriesForTest', () {
      test('loads provided categories into the list', () {
        provider.loadCategoriesForTest([testCategory]);
        expect(provider.categories.length, 1);
        expect(provider.categories.first.id, 'cat_test_1');
      });

      test('replaces existing categories', () {
        provider.loadCategoriesForTest([testCategory]);
        provider.loadCategoriesForTest([testCategory.copyWith(id: 'cat_test_2', name: '运动')]);
        expect(provider.categories.length, 1);
        expect(provider.categories.first.id, 'cat_test_2');
      });
    });

    group('addCategory', () {
      test('adds a category and notifies listeners', () async {
        int notifyCount = 0;
        provider.addListener(() => notifyCount++);

        await provider.addCategory(
          name: '运动',
          nameEn: 'Exercise',
          color: '#FF9500',
          icon: '🏃',
        );

        expect(provider.categories.length, 1);
        expect(provider.categories.first.name, '运动');
        expect(provider.categories.first.nameEn, 'Exercise');
        expect(provider.error, isNull);
        expect(notifyCount, greaterThan(0));
      });

      test('sorts categories by sortOrder then name', () async {
        await provider.addCategory(name: 'B', nameEn: 'B', color: '#000', sortOrder: 0);
        await provider.addCategory(name: 'A', nameEn: 'A', color: '#000', sortOrder: 0);
        await provider.addCategory(name: 'C', nameEn: 'C', color: '#000', sortOrder: -1);

        expect(provider.categories.map((c) => c.name), ['C', 'A', 'B']);
      });
    });

    group('updateCategory', () {
      test('updates existing category in list', () async {
        provider.loadCategoriesForTest([testCategory]);

        final updated = testCategory.copyWith(name: '已更新', nameEn: 'Updated');
        await provider.updateCategory(updated);

        expect(provider.categories.first.name, '已更新');
        expect(provider.categories.first.nameEn, 'Updated');
        expect(provider.error, isNull);
      });

      test('does nothing for nonexistent category', () async {
        provider.loadCategoriesForTest([testCategory]);

        await provider.updateCategory(
          TagCategory(
            id: 'nonexistent', name: 'X', nameEn: 'X',
            color: '#000', createdAt: DateTime(2026),
          ),
        );

        expect(provider.categories.length, 1);
        expect(provider.categories.first.name, '健康');
      });
    });

    group('deleteCategory', () {
      test('removes category from list', () async {
        provider.loadCategoriesForTest([testCategory]);

        await provider.deleteCategory('cat_test_1');

        expect(provider.categories, isEmpty);
        expect(provider.error, isNull);
      });

      test('does nothing for nonexistent id', () async {
        provider.loadCategoriesForTest([testCategory]);

        await provider.deleteCategory('nonexistent');

        expect(provider.categories.length, 1);
      });
    });

    group('reorder', () {
      test('updates sort orders of all categories', () async {
        final catA = testCategory.copyWith(id: 'a', name: 'A', sortOrder: 0);
        final catB = testCategory.copyWith(id: 'b', name: 'B', sortOrder: 1);
        final catC = testCategory.copyWith(id: 'c', name: 'C', sortOrder: 2);
        provider.loadCategoriesForTest([catA, catB, catC]);

        int notifyCount = 0;
        provider.addListener(() => notifyCount++);

        await provider.reorder([catC, catA, catB]);

        expect(provider.categories.map((c) => c.name), ['A', 'B', 'C']);
        expect(notifyCount, greaterThan(0));
      });
    });
  });
}
