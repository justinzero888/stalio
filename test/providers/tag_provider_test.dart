import 'package:flutter_test/flutter_test.dart';
import 'package:blinking/models/tag.dart';
import 'package:blinking/providers/tag_provider.dart';
import 'package:blinking/repositories/tag_repository.dart';
import 'package:blinking/core/services/storage_service.dart';

class _MockStorageService extends StorageService {
  final List<Tag> _tags = [];

  @override
  Future<void> init() async {}

  @override
  Future<List<Tag>> getTags() async => List.of(_tags);

  @override
  Future<void> addTag(Tag tag) async {
    _tags.add(tag);
  }

  @override
  Future<void> updateTag(Tag tag) async {
    final index = _tags.indexWhere((t) => t.id == tag.id);
    if (index != -1) _tags[index] = tag;
  }

  @override
  Future<void> deleteTag(String id) async {
    _tags.removeWhere((t) => t.id == id);
  }

  @override
  Future<void> saveTags(List<Tag> tags) async {
    _tags.clear();
    _tags.addAll(tags);
  }
}

void main() {
  late _MockStorageService storage;
  late TagRepository repository;
  late TagProvider provider;

  final testTag = Tag(
    id: 'tag_test_1',
    name: '测试',
    nameEn: 'Test',
    color: '#FF0000',
    category: 'custom',
    createdAt: DateTime(2026, 1, 1),
  );

  setUp(() {
    storage = _MockStorageService();
    repository = TagRepository(storage);
    provider = TagProvider(repository);
  });

  group('TagProvider', () {
    group('initial state', () {
      test('has empty tags and no error initially', () {
        expect(provider.tags, isEmpty);
        expect(provider.isLoading, false);
        expect(provider.error, isNull);
      });

      test('getTagById returns null for unknown id', () {
        expect(provider.getTagById('nonexistent'), isNull);
      });

      test('getTagsByIds returns empty for unknown ids', () {
        expect(provider.getTagsByIds(['a', 'b']), isEmpty);
      });
    });

    group('loadTagsForTest', () {
      test('loads provided tags into the list', () {
        provider.loadTagsForTest([testTag]);
        expect(provider.tags.length, 1);
        expect(provider.tags.first.id, 'tag_test_1');
      });

      test('replaces existing tags', () {
        provider.loadTagsForTest([testTag]);
        provider.loadTagsForTest([testTag.copyWith(id: 'tag_test_2', name: '测试2')]);
        expect(provider.tags.length, 1);
        expect(provider.tags.first.id, 'tag_test_2');
      });
    });

    group('addTag', () {
      test('adds a tag and notifies listeners', () async {
        int notifyCount = 0;
        provider.addListener(() => notifyCount++);

        await provider.addTag(
          name: '新标签',
          nameEn: 'New Tag',
          color: '#00FF00',
        );

        expect(provider.tags.length, 1);
        expect(provider.tags.first.name, '新标签');
        expect(provider.tags.first.nameEn, 'New Tag');
        expect(provider.error, isNull);
        expect(notifyCount, greaterThan(0));
      });

      test('sorts tags alphabetically after add', () async {
        await provider.addTag(name: 'B标签', nameEn: 'B', color: '#000');
        await provider.addTag(name: 'A标签', nameEn: 'A', color: '#000');
        await provider.addTag(name: 'C标签', nameEn: 'C', color: '#000');

        expect(provider.tags.map((t) => t.name), ['A标签', 'B标签', 'C标签']);
      });
    });

    group('updateTag', () {
      test('updates existing tag in list', () async {
        provider.loadTagsForTest([testTag]);

        final updated = testTag.copyWith(name: '已更新', nameEn: 'Updated');
        await provider.updateTag(updated);

        expect(provider.tags.first.name, '已更新');
        expect(provider.tags.first.nameEn, 'Updated');
        expect(provider.error, isNull);
      });

      test('keeps list sorted after update', () async {
        provider.loadTagsForTest([
          Tag(id: 'tag_a', name: 'A', nameEn: 'A', color: '#000', createdAt: DateTime(2026)),
          Tag(id: 'tag_b', name: 'B', nameEn: 'B', color: '#000', createdAt: DateTime(2026)),
        ]);

        await provider.updateTag(
          Tag(id: 'tag_b', name: '0', nameEn: '0', color: '#000', createdAt: DateTime(2026)),
        );

        expect(provider.tags.map((t) => t.name), ['0', 'A']);
      });

      test('does nothing for nonexistent tag', () async {
        provider.loadTagsForTest([testTag]);

        await provider.updateTag(
          Tag(id: 'nonexistent', name: 'X', nameEn: 'X', color: '#000', createdAt: DateTime(2026)),
        );

        expect(provider.tags.length, 1);
        expect(provider.tags.first.name, '测试');
      });
    });

    group('deleteTag', () {
      test('removes tag from list', () async {
        provider.loadTagsForTest([testTag]);

        await provider.deleteTag('tag_test_1');

        expect(provider.tags, isEmpty);
        expect(provider.error, isNull);
      });

      test('does nothing for nonexistent id', () async {
        provider.loadTagsForTest([testTag]);

        await provider.deleteTag('nonexistent');

        expect(provider.tags.length, 1);
      });
    });

    group('getTagById', () {
      test('returns tag by id', () {
        provider.loadTagsForTest([testTag]);
        final found = provider.getTagById('tag_test_1');
        expect(found?.name, '测试');
      });

      test('returns null for missing id', () {
        provider.loadTagsForTest([testTag]);
        expect(provider.getTagById('missing'), isNull);
      });
    });

    group('getTagsByIds', () {
      test('returns matching tags', () {
        final tag2 = Tag(id: 'tag_2', name: '二', nameEn: 'Two', color: '#000', createdAt: DateTime(2026));
        provider.loadTagsForTest([testTag, tag2]);

        final result = provider.getTagsByIds(['tag_test_1']);
        expect(result.length, 1);
        expect(result.first.name, '测试');
      });

      test('returns empty for no matches', () {
        provider.loadTagsForTest([testTag]);
        expect(provider.getTagsByIds(['nope']), isEmpty);
      });
    });

    group('resetToDefaults', () {
      test('resets to default tags', () async {
        int notifyCount = 0;
        provider.addListener(() => notifyCount++);

        provider.loadTagsForTest([testTag]);
        expect(provider.tags.length, 1);

        await provider.resetToDefaults();

        expect(provider.tags.length, DefaultTags.defaults.length);
        final providerNames = provider.tags.map((t) => t.name).toList();
        for (final expected in DefaultTags.defaults.map((t) => t.name)) {
          expect(providerNames, contains(expected));
        }
        expect(notifyCount, greaterThan(0));
      });
    });
  });
}
