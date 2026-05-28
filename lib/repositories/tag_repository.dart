import 'package:uuid/uuid.dart';
import '../models/tag.dart';
import '../core/services/storage_service.dart';

/// Repository for Tag data access
/// Handles creation, retrieval, update and deletion of tags
class TagRepository {
  final StorageService _storage;
  final _uuid = const Uuid();

  TagRepository(this._storage);

  /// Get all tags
  Future<List<Tag>> getAll() async {
    final tags = await _storage.getTags();
    tags.sort((a, b) => a.name.compareTo(b.name));
    return tags;
  }

  /// Get a single tag by ID
  Future<Tag?> getById(String id) async {
    final tags = await getAll();
    try {
      return tags.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get tags by category
  Future<List<Tag>> getByCategory(String category) async {
    final tags = await getAll();
    return tags.where((t) => t.category == category).toList();
  }

  /// Search tags by name
  Future<List<Tag>> search(String query) async {
    final tags = await getAll();
    final lowerQuery = query.toLowerCase();
    return tags.where((t) =>
        t.name.toLowerCase().contains(lowerQuery) ||
        t.nameEn.toLowerCase().contains(lowerQuery)).toList();
  }

  /// Create a new tag
  Future<Tag> create({
    required String name,
    required String nameEn,
    required String color,
    String category = 'custom',
  }) async {
    final tag = Tag(
      id: _uuid.v4(),
      name: name,
      nameEn: nameEn,
      color: color,
      category: category,
      createdAt: DateTime.now(),
    );
    await _storage.addTag(tag);
    return tag;
  }

  /// Update an existing tag
  Future<Tag?> update(Tag tag) async {
    await _storage.updateTag(tag);
    return tag;
  }

  /// Delete a tag
  Future<void> delete(String id) async {
    await _storage.deleteTag(id);
  }

  /// Check if tag name already exists
  Future<bool> nameExists(String name, {String? excludeId}) async {
    final tags = await getAll();
    return tags.any((t) =>
        t.name == name && t.id != excludeId);
  }

  /// Get default tags
  List<Tag> getDefaults() {
    return DefaultTags.defaults;
  }

  /// Reset to default tags (delete all and recreate)
  Future<void> resetToDefaults() async {
    await _storage.saveTags(DefaultTags.defaults);
  }

  /// Get tags by IDs (batch lookup)
  Future<List<Tag>> getByIds(List<String> ids) async {
    final allTags = await getAll();
    return allTags.where((t) => ids.contains(t.id)).toList();
  }
}
