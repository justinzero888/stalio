import 'package:flutter/foundation.dart';
import '../models/tag_category.dart';
import '../repositories/tag_category_repository.dart';

/// Provider for managing tag categories
class TagCategoryProvider extends ChangeNotifier {
  final TagCategoryRepository _repository;

  List<TagCategory> _categories = [];
  bool _isLoading = false;
  String? _error;

  TagCategoryProvider(this._repository);

  List<TagCategory> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categories = await _repository.getAll();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addCategory({
    required String name,
    required String nameEn,
    required String color,
    String icon = '📁',
    int sortOrder = 0,
  }) async {
    _error = null;

    try {
      final category = await _repository.create(
        name: name,
        nameEn: nameEn,
        color: color,
        icon: icon,
        sortOrder: sortOrder,
      );
      _categories.add(category);
      _categories.sort((a, b) {
        final orderCompare = a.sortOrder.compareTo(b.sortOrder);
        if (orderCompare != 0) return orderCompare;
        return a.name.compareTo(b.name);
      });
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateCategory(TagCategory category) async {
    _error = null;

    try {
      await _repository.update(category);
      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _categories[index] = category;
        _categories.sort((a, b) {
          final orderCompare = a.sortOrder.compareTo(b.sortOrder);
          if (orderCompare != 0) return orderCompare;
          return a.name.compareTo(b.name);
        });
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteCategory(String id) async {
    _error = null;

    try {
      await _repository.delete(id);
      _categories.removeWhere((c) => c.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> reorder(List<TagCategory> categories) async {
    _error = null;

    try {
      await _repository.reorder(categories);
      _categories = List.of(categories);
      _categories.sort((a, b) {
        final orderCompare = a.sortOrder.compareTo(b.sortOrder);
        if (orderCompare != 0) return orderCompare;
        return a.name.compareTo(b.name);
      });
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  TagCategory? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<int> getUsageCount(String categoryId) async {
    return _repository.getUsageCount(categoryId);
  }

  /// Test-only: seeds the category list without touching storage.
  @visibleForTesting
  void loadCategoriesForTest(List<TagCategory> categories) {
    _categories = List.of(categories);
  }
}
