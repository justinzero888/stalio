import 'package:uuid/uuid.dart';
import '../models/tag_category.dart';
import '../core/services/storage_service.dart';

/// Repository for TagCategory data access
class TagCategoryRepository {
  final StorageService _storage;
  final _uuid = const Uuid();

  TagCategoryRepository(this._storage);

  Future<List<TagCategory>> getAll() async {
    final categories = await _storage.getTagCategories();
    categories.sort((a, b) {
      final orderCompare = a.sortOrder.compareTo(b.sortOrder);
      if (orderCompare != 0) return orderCompare;
      return a.name.compareTo(b.name);
    });
    return categories;
  }

  Future<TagCategory?> getById(String id) async {
    final categories = await getAll();
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<int> getUsageCount(String categoryId) async {
    return _storage.getTagCategoryUsageCount(categoryId);
  }

  Future<TagCategory> create({
    required String name,
    required String nameEn,
    required String color,
    String icon = '📁',
    int sortOrder = 0,
  }) async {
    final category = TagCategory(
      id: _uuid.v4(),
      name: name,
      nameEn: nameEn,
      color: color,
      icon: icon,
      sortOrder: sortOrder,
      createdAt: DateTime.now(),
    );
    await _storage.addTagCategory(category);
    return category;
  }

  Future<TagCategory?> update(TagCategory category) async {
    await _storage.updateTagCategory(category);
    return category;
  }

  Future<void> delete(String id) async {
    final tags = await _storage.getTagsByCategoryId(id);
    for (final tag in tags) {
      await _storage.updateTag(tag.copyWith(categoryId: null));
    }
    await _storage.deleteTagCategory(id);
  }

  Future<void> reorder(List<TagCategory> categories) async {
    await _storage.reorderTagCategories(categories);
  }

  Future<bool> nameExists(String name, {String? excludeId}) async {
    final categories = await getAll();
    return categories.any((c) => c.name == name && c.id != excludeId);
  }
}
