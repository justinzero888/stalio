import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/entry_provider.dart';
import '../../providers/tag_provider.dart';
import '../../providers/locale_provider.dart';
import '../../models/models.dart';
import 'entry_detail_screen.dart';

class MomentScreen extends StatefulWidget {
  const MomentScreen({super.key});

  @override
  State<MomentScreen> createState() => _MomentScreenState();
}

class _MomentScreenState extends State<MomentScreen> {
  String _filter = 'all'; // all, today, week, tag
  String _searchQuery = '';
  String? _tagFilterId;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';

    return Scaffold(
      appBar: AppBar(
        title: Text(isZh ? '瞬间' : 'Moments',
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Consumer<EntryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Semantics(
                  identifier: 'input_moments_search',
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: isZh ? '搜索记录...' : 'Search entries...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value.trim());
                    },
                  ),
                ),
              ),
              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildFilterChip(isZh ? '全部' : 'All', 'all'),
                    const SizedBox(width: 8),
                    _buildFilterChip(isZh ? '今天' : 'Today', 'today'),
                    const SizedBox(width: 8),
                    _buildFilterChip(isZh ? '本周' : 'This week', 'week'),
                    const SizedBox(width: 8),
                    _buildFilterChip(isZh ? '标签' : 'Tags', 'tag'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Entry List
              Expanded(
                child: _buildEntryList(provider, isZh),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (value == 'tag') {
          if (selected) {
            _showTagPicker();
          } else {
            setState(() {
              _filter = 'all';
              _tagFilterId = null;
            });
          }
        } else {
          setState(() {
            _filter = value;
            _tagFilterId = null;
          });
        }
      },
    );
  }

  void _showTagPicker() {
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    final tagProvider = context.read<TagProvider>();
    final tags = tagProvider.tags;

    if (tags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isZh
              ? '暂无标签，请先在设置中添加标签'
              : 'No tags yet. Add tags in Settings first.'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isZh ? '选择标签' : 'Select Tag'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: tags.map((tag) {
              final colorValue =
                  int.parse(tag.color.substring(1), radix: 16) + 0xFF000000;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(colorValue),
                  radius: 8,
                ),
                title: Text(tag.displayName(isZh)),
                onTap: () {
                  setState(() {
                    _filter = 'tag';
                    _tagFilterId = tag.id;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _filter = 'all';
                _tagFilterId = null;
              });
              Navigator.pop(context);
            },
            child: Text(isZh ? '取消' : 'Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryList(EntryProvider provider, bool isZh) {
    final now = DateTime.now();

    // Get base list from date filter
    List<Entry> entries;
    switch (_filter) {
      case 'today':
        entries = provider.allEntries
            .where((e) =>
                e.createdAt.year == now.year &&
                e.createdAt.month == now.month &&
                e.createdAt.day == now.day)
            .toList();
        break;
      case 'week':
        final weekAgo = now.subtract(const Duration(days: 7));
        entries = provider.allEntries
            .where((e) => e.createdAt.isAfter(weekAgo))
            .toList();
        break;
      case 'tag':
        entries = _tagFilterId != null
            ? provider.allEntries
                .where((e) => e.tagIds.contains(_tagFilterId))
                .toList()
            : provider.allEntries;
        break;
      default:
        entries = provider.allEntries;
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      entries = entries
          .where((e) =>
              e.content.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    if (entries.isEmpty) {
      return Center(
        child: Text(
          isZh ? '暂无记录\n点击 + 添加第一条' : 'No entries yet\nTap + to add one',
          textAlign: TextAlign.center,
        ),
      );
    }

    // Group by date
    final grouped = <String, List<Entry>>{};
    for (var entry in entries) {
      final dateKey = isZh
          ? DateFormat('yyyy年M月d日').format(entry.createdAt)
          : DateFormat('MMM d, y').format(entry.createdAt);
      grouped.putIfAbsent(dateKey, () => []).add(entry);
    }

    return Semantics(
      identifier: 'list_entries',
      child: ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final dateKey = grouped.keys.elementAt(index);
        final dateEntries = grouped[dateKey]!;
        final isToday = _isToday(dateEntries.first.createdAt);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                isToday ? (isZh ? '今天' : 'Today') : dateKey,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ),
            ...dateEntries
                .map((entry) => _buildEntryCard(entry, provider, isZh)),
          ],
        );
      },
    ),
    );
  }

  Widget _buildEntryCard(Entry entry, EntryProvider provider, bool isZh) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        identifier: 'entry_item',
        child: ListTile(
          leading: Icon(
            _getEntryIcon(entry),
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(entry.content),
          subtitle: Text(
            DateFormat('HH:mm').format(entry.createdAt),
            style: const TextStyle(fontSize: 12),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (entry.tagIds.isNotEmpty) ...[
                const Icon(Icons.label, size: 16, color: Colors.grey),
                const SizedBox(width: 2),
                Text('${entry.tagIds.length}',
                    style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
              ],
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EntryDetailScreen(entry: entry),
              ),
            );
          },
          onLongPress: () {
            _showDeleteDialog(entry, provider);
          },
        ),
      ),
    );
  }

  IconData _getEntryIcon(Entry entry) {
    if (entry.type == EntryType.routine) return Icons.check_circle;
    if (entry.format == EntryFormat.list) return Icons.checklist;
    return Icons.note;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  void _showDeleteDialog(Entry entry, EntryProvider provider) {
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isZh ? '删除记录' : 'Delete Entry'),
        content: Text(isZh ? '确定要删除这条记录吗？' : 'Delete this entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isZh ? '取消' : 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteEntry(entry.id);
              Navigator.pop(context);
            },
            child: Text(isZh ? '删除' : 'Delete',
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
