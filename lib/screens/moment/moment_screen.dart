import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../providers/entry_provider.dart';
import '../../providers/tag_provider.dart';
import '../../providers/tag_category_provider.dart';
import '../../providers/tag_category_provider.dart';
import '../../providers/locale_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/models.dart';
import '../../l10n/app_localizations.dart';
import '../../core/utils/share_format.dart';
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
  String? _categoryFilterId;
  bool _isSelecting = false;
  final Set<String> _selectedEntryIds = {};
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';

    return Scaffold(
      appBar: AppBar(
        title: _isSelecting
            ? Text('${_selectedEntryIds.length} ${isZh ? '已选' : 'selected'}')
            : Text(l.moment, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: _isSelecting
            ? [
                IconButton(icon: const Icon(Icons.share), tooltip: 'Share', onPressed: () => _showSharePreview(context)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() { _isSelecting = false; _selectedEntryIds.clear(); })),
              ]
            : null,
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
                      hintText: l.searchEntries,
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
                    _buildFilterChip(l.all, 'all'),
                    const SizedBox(width: 8),
                    _buildFilterChip(l.today, 'today'),
                    const SizedBox(width: 8),
                    _buildFilterChip(l.thisWeek, 'week'),
                    const SizedBox(width: 8),
                    _buildFilterChip(l.tags, 'tag'),
                  ],
                ),
              ),
              // Category Filter Chips
              Consumer<TagCategoryProvider>(
                builder: (context, catProvider, _) {
                  final categories = catProvider.categories;
                  if (categories.isEmpty) return const SizedBox(height: 0);
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _buildCategoryChip(l.all, null),
                          const SizedBox(width: 8),
                          ...categories.expand((cat) => [
                            _buildCategoryChip(cat.displayName(
                                context.read<LocaleProvider>().locale.languageCode == 'zh'), cat.id),
                            const SizedBox(width: 8),
                          ]),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              // Entry List
              Expanded(
                child: _buildEntryList(provider),
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
      label: Text(label, style: TextStyle(
        color: isSelected ? const Color(0xFFE0B84F) : null,
        fontWeight: isSelected ? FontWeight.w600 : null,
      )),
      selected: isSelected,
      selectedColor: const Color(0xFF10317D),
      checkmarkColor: const Color(0xFFE0B84F),
      onSelected: (selected) {
        if (value == 'tag') {
          if (selected) {
            _showTagPicker();
          } else {
            setState(() {
              _filter = 'all';
              _tagFilterId = null;
              _categoryFilterId = null;
            });
          }
        } else {
          setState(() {
            _filter = value;
            _tagFilterId = null;
            _categoryFilterId = null;
          });
        }
      },
    );
  }

  Widget _buildCategoryChip(String label, String? categoryId) {
    final isSelected = _categoryFilterId == categoryId;
    return FilterChip(
      label: Text(label, style: TextStyle(
        color: isSelected ? const Color(0xFFE0B84F) : null,
        fontWeight: isSelected ? FontWeight.w600 : null,
        fontSize: 13,
      )),
      selected: isSelected,
      selectedColor: const Color(0xFF10317D),
      checkmarkColor: const Color(0xFFE0B84F),
      visualDensity: VisualDensity.compact,
      onSelected: (_) {
        setState(() {
          _categoryFilterId = isSelected ? null : categoryId;
        });
      },
    );
  }

  void _showTagPicker() {
    final l = AppLocalizations.of(context)!;
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    final tagProvider = context.read<TagProvider>();
    final tags = tagProvider.tags;

    if (tags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.noTagsWarning),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.selectTags),
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
                _categoryFilterId = null;
              });
              Navigator.pop(context);
            },
            child: Text(l.cancel),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryList(EntryProvider provider) {
    final l = AppLocalizations.of(context)!;
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
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

    // Apply category filter
    if (_categoryFilterId != null) {
      final tagProvider = context.read<TagProvider>();
      final categoryTagIds = tagProvider.tags
          .where((t) => t.categoryId == _categoryFilterId)
          .map((t) => t.id)
          .toSet();
      entries = entries
          .where((e) => e.tagIds.any((id) => categoryTagIds.contains(id)))
          .toList();
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
          l.noEntriesYet,
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
                isToday ? l.today : dateKey,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ),
            ...dateEntries
                .map((entry) => _buildEntryCard(entry, provider)),
          ],
        );
      },
    ),
    );
  }

  Widget _buildEntryCard(Entry entry, EntryProvider provider) {
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    final tagProvider = context.read<TagProvider>();
    final tags = tagProvider.tags.where((t) => entry.tagIds.contains(t.id)).toList();
    final isSelected = _selectedEntryIds.contains(entry.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        identifier: 'entry_item',
        child: ListTile(
          leading: _isSelecting
              ? Checkbox(value: isSelected, onChanged: (_) => _toggleEntry(entry.id), visualDensity: VisualDensity.compact)
              : Icon(_getEntryIcon(entry), color: Theme.of(context).colorScheme.primary),
          title: Text(entry.content),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('HH:mm').format(entry.createdAt),
                style: const TextStyle(fontSize: 12),
              ),
              if (tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Wrap(
                    spacing: 4,
                    children: tags.map((t) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Color(int.parse(t.color.replaceFirst('#', '0xFF'))).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(t.displayName(isZh), style: TextStyle(fontSize: 10, color: Color(int.parse(t.color.replaceFirst('#', '0xFF'))))),
                    )).toList(),
                  ),
                ),
            ],
          ),
          onTap: _isSelecting
              ? () => _toggleEntry(entry.id)
              : () { Navigator.push(context, MaterialPageRoute(builder: (_) => EntryDetailScreen(entry: entry))); },
          onLongPress: _isSelecting
              ? null
              : () { setState(() { _isSelecting = true; _selectedEntryIds.add(entry.id); }); },
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
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.deleteEntry),
        content: Text(l.deleteEntryConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () {
              provider.deleteEntry(entry.id);
              Navigator.pop(context);
            },
            child: Text(l.delete,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _toggleEntry(String id) {
    setState(() {
      if (_selectedEntryIds.contains(id)) {
        _selectedEntryIds.remove(id);
        if (_selectedEntryIds.isEmpty) _isSelecting = false;
      } else {
        _selectedEntryIds.add(id);
      }
    });
  }

  void _showSharePreview(BuildContext context) {
    final provider = context.read<EntryProvider>();
    final selected = provider.allEntries.where((e) => _selectedEntryIds.contains(e.id)).toList();
    selected.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';

    String _buildFormat(int index) {
      switch (index) {
        case 1: return ShareFormat.toMarkdown(selected, isZh);
        case 2: return ShareFormat.toRichText(selected, isZh);
        default: return ShareFormat.toPlainText(selected, isZh);
      }
    }

    int formatIndex = 0;
    final controller = TextEditingController(text: _buildFormat(0));
    final pageController = PageController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) => AlertDialog(
        title: Row(children: [
          Text(isZh ? '分享预览' : 'Share Preview'),
          const Spacer(),
          IconButton(icon: const Icon(Icons.copy), tooltip: isZh ? '复制' : 'Copy', onPressed: () {
            Clipboard.setData(ClipboardData(text: controller.text));
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isZh ? '已复制' : 'Copied'), duration: const Duration(seconds: 1)));
          }),
        ]),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _formatBtn(isZh ? '纯文本' : 'Plain', 0, formatIndex, () => setDialogState(() { formatIndex = 0; controller.text = _buildFormat(0); })),
              const SizedBox(width: 8),
              _formatBtn('Markdown', 1, formatIndex, () => setDialogState(() { formatIndex = 1; controller.text = _buildFormat(1); })),
              const SizedBox(width: 8),
              _formatBtn(isZh ? '富文本' : 'Rich', 2, formatIndex, () => setDialogState(() { formatIndex = 2; controller.text = _buildFormat(2); })),
            ]),
            const SizedBox(height: 8),
            Expanded(child: SingleChildScrollView(child: Text(controller.text, style: const TextStyle(fontSize: 13, fontFamily: 'monospace')))),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isZh ? '取消' : 'Cancel')),
          FilledButton.icon(
            icon: const Icon(Icons.share, size: 18),
            label: Text(isZh ? '分享' : 'Share'),
            onPressed: () {
              Navigator.pop(ctx);
              _shareContent(controller.text, isZh);
            },
          ),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.save_alt, size: 18),
            label: Text(isZh ? '保存为文件' : 'Save as file'),
            onPressed: () {
              Navigator.pop(ctx);
              _saveAsFile(controller.text, formatIndex, context, isZh);
            },
          ),
        ],
      )),
    );
  }

  Widget _formatBtn(String label, int index, int selected, VoidCallback onTap) {
    final active = index == selected;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: active ? Theme.of(context).colorScheme.primary : Colors.grey.shade200, borderRadius: BorderRadius.circular(16)),
        child: Text(label, style: TextStyle(color: active ? Colors.white : Colors.black87, fontSize: 12, fontWeight: FontWeight.w500)),
      ),
    );
  }

  void _shareContent(String text, bool isZh) {
    SharePlus.instance.share(ShareParams(text: text));
  }

  Future<void> _saveAsFile(String content, int formatIndex, BuildContext context, bool isZh) async {
    final dir = await getApplicationDocumentsDirectory();
    final ext = formatIndex == 1 ? 'md' : 'txt';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/stalio_export_$timestamp.$ext');
    await file.writeAsString(content);
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], subject: 'Stalio Notes'));
  }
}
