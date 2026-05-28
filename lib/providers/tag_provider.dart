import 'package:flutter/foundation.dart';
import '../models/tag.dart';
import '../repositories/tag_repository.dart';


/// Provider for managing tags
/// Uses TagRepository for data access
class TagProvider extends ChangeNotifier {
  final TagRepository _repository;
  
  List<Tag> _tags = [];
  bool _isLoading = false;
  String? _error;

  TagProvider(this._repository);

  // Getters
  List<Tag> get tags => _tags;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load all tags from storage
  Future<void> loadTags() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tags = await _repository.getAll();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Add a new tag
  Future<void> addTag({
    required String name,
    required String nameEn,
    required String color,
    String category = 'custom',
  }) async {
    _error = null;
    
    try {
      final tag = await _repository.create(
        name: name,
        nameEn: nameEn,
        color: color,
        category: category,
      );
      _tags.add(tag);
      _tags.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Update an existing tag
  Future<void> updateTag(Tag tag) async {
    _error = null;
    
    try {
      await _repository.update(tag);
      final index = _tags.indexWhere((t) => t.id == tag.id);
      if (index != -1) {
        _tags[index] = tag;
        _tags.sort((a, b) => a.name.compareTo(b.name));
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Delete a tag
  Future<void> deleteTag(String id) async {
    _error = null;
    
    try {
      await _repository.delete(id);
      _tags.removeWhere((t) => t.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Get tag by ID
  Tag? getTagById(String id) {
    try {
      return _tags.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get tags by IDs (batch lookup)
  List<Tag> getTagsByIds(List<String> ids) {
    return _tags.where((t) => ids.contains(t.id)).toList();
  }

  /// Search tags
  Future<List<Tag>> search(String query) async {
    return _repository.search(query);
  }

  /// Test-only: seeds the tag list without touching storage.
  @visibleForTesting
  void loadTagsForTest(List<Tag> tags) {
    _tags = List.of(tags);
  }

  /// Reset to default tags
  Future<void> resetToDefaults() async {
    _error = null;
    
    try {
      await _repository.resetToDefaults();
      await loadTags();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
