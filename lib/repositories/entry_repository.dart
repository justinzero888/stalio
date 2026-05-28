import 'package:uuid/uuid.dart';
import '../models/entry.dart';
import '../core/services/storage_service.dart';

/// Repository for Entry data access
/// Acts as a bridge between Providers and StorageService
class EntryRepository {
  final StorageService _storage;
  final _uuid = const Uuid();

  EntryRepository(this._storage);

  /// Get all entries, sorted by newest first
  Future<List<Entry>> getAll() async {
    final entries = await _storage.getEntries();
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  /// Get entries for a specific date
  Future<List<Entry>> getByDate(DateTime date) async {
    final entries = await getAll();
    return entries.where((e) =>
        e.createdAt.year == date.year &&
        e.createdAt.month == date.month &&
        e.createdAt.day == date.day).toList();
  }

  /// Get entries for a date range
  Future<List<Entry>> getByDateRange(DateTime start, DateTime end) async {
    final entries = await getAll();
    return entries.where((e) =>
        e.createdAt.isAfter(start.subtract(const Duration(days: 1))) &&
        e.createdAt.isBefore(end.add(const Duration(days: 1)))).toList();
  }

  /// Get entries by tag ID
  Future<List<Entry>> getByTag(String tagId) async {
    final entries = await getAll();
    return entries.where((e) => e.tagIds.contains(tagId)).toList();
  }

  /// Get entries by type (freeform or routine)
  Future<List<Entry>> getByType(EntryType type) async {
    final entries = await getAll();
    return entries.where((e) => e.type == type).toList();
  }

  /// Search entries by content
  Future<List<Entry>> search(String query) async {
    final entries = await getAll();
    final lowerQuery = query.toLowerCase();
    return entries.where((e) =>
        e.content.toLowerCase().contains(lowerQuery)).toList();
  }

  /// Get a single entry by ID
  Future<Entry?> getById(String id) async {
    final entries = await getAll();
    try {
      return entries.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Create a new entry
  Future<Entry> create({
    required EntryType type,
    required String content,
    List<String> tagIds = const [],
    List<String> mediaUrls = const [],
    Map<String, dynamic>? metadata,
    String? emotion,
    EntryFormat format = EntryFormat.note,
    List<ListItem>? listItems,
    bool listCarriedForward = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) async {
    final now = DateTime.now();
    final entry = Entry(
      id: _uuid.v4(),
      type: type,
      content: content,
      tagIds: tagIds,
      mediaUrls: mediaUrls,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      metadata: metadata,
      emotion: emotion,
      format: format,
      listItems: listItems,
      listCarriedForward: listCarriedForward,
    );
    await _storage.addEntry(entry);
    return entry;
  }

  /// Update an existing entry
  Future<Entry?> update(Entry entry) async {
    final updated = entry.copyWith(updatedAt: DateTime.now());
    await _storage.updateEntry(updated);
    return updated;
  }

  /// Delete an entry
  Future<void> delete(String id) async {
    await _storage.deleteEntry(id);
  }

  /// Get today's entries
  Future<List<Entry>> getTodayEntries() async {
    return getByDate(DateTime.now());
  }

  /// Get this week's entries
  Future<List<Entry>> getThisWeekEntries() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return getByDateRange(startOfWeek, now);
  }

  /// Get this month's entries
  Future<List<Entry>> getThisMonthEntries() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return getByDateRange(startOfMonth, now);
  }

  Future<void> toggleListItem(String entryId, String itemId) async {
    await _storage.toggleListItem(entryId, itemId);
  }

  Future<Entry?> getYesterdayListEntry() async {
    final allEntries = await getAll();
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final yesterday = todayDate.subtract(const Duration(days: 1));

    for (final entry in allEntries) {
      if (entry.format != EntryFormat.list) continue;
      final entryDate = DateTime(entry.createdAt.year, entry.createdAt.month, entry.createdAt.day);
      if (entryDate == yesterday) return entry;
    }
    return null;
  }

  bool hasTodayList(List<Entry> allEntries) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    return allEntries.any((e) {
      if (e.format != EntryFormat.list) return false;
      final d = DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day);
      return d == todayDate;
    });
  }

  List<ListItem> getUncheckedItems(Entry entry) {
    return (entry.listItems ?? []).where((item) => !item.isDone).toList();
  }

  Future<Entry> createTodayListWithItems(List<ListItem> items, {String content = ''}) async {
    final entry = await create(
      type: EntryType.freeform,
      content: content,
      format: EntryFormat.list,
      listItems: items,
    );
    return entry;
  }
}
