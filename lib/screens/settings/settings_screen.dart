import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../models/tag.dart';
import '../../models/tag_category.dart';
import '../../models/routine.dart';
import '../../providers/locale_provider.dart';
import '../../providers/tag_provider.dart';
import '../../providers/tag_category_provider.dart';
import '../../providers/routine_provider.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/export_service.dart';
import '../../core/services/voice_notification_service.dart';
import '../../core/constants/legal_content.dart';
import '../routine/routine_screen.dart';

class SettingsScreen extends StatefulWidget {
  final int initialTab;
  const SettingsScreen({super.key, this.initialTab = 0});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    return Scaffold(
      appBar: AppBar(
        title: Text(isZh ? '设置' : 'Settings'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: isZh ? '通用' : 'General'),
            Tab(text: isZh ? '标签' : 'Tags'),
            Tab(text: isZh ? '习惯' : 'Habits'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _GeneralTab(),
          _TagList(),
          _HabitBuildTab(),
        ],
      ),
    );
  }
}

class _GeneralTab extends StatefulWidget {
  @override
  State<_GeneralTab> createState() => _GeneralTabState();
}

class _GeneralTabState extends State<_GeneralTab> {
  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final storage = context.read<StorageService>();
    final voiceEnabled = storage.getVoiceEnabled();

    return ListView(
      children: [
        _sectionHeader(isZh ? '通知' : 'Notifications'),
        SwitchListTile(
          title: Text(isZh ? '语音提醒' : 'Voice Reminders'),
          subtitle: Text(isZh ? '在设定时间朗读习惯名称' : 'Speak habit names at scheduled times'),
          value: voiceEnabled,
          onChanged: (value) {
            storage.setVoiceEnabled(value);
            setState(() {});
          },
        ),
        if (voiceEnabled)
          Padding(
            padding: const EdgeInsets.only(left: 72, right: 16, bottom: 8),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.play_arrow, size: 18),
              label: Text(isZh ? '测试语音' : 'Test Voice'),
              onPressed: () async {
                await VoiceNotificationService.speak(
                  isZh ? '你好，这是语音提醒测试' : 'Hello, this is a voice reminder test',
                  language: isZh ? 'zh-CN' : 'en-US',
                );
              },
            ),
          ),
        const Divider(),
        _sectionHeader(isZh ? '语言' : 'Language'),
        Consumer<LocaleProvider>(
          builder: (context, localeProvider, _) {
            final isZhNow = localeProvider.locale.languageCode == 'zh';
            return ListTile(
              leading: const Icon(Icons.language),
              title: Text(isZh ? '语言' : 'Language'),
              subtitle: Text(isZhNow ? '中文' : 'English'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showLanguageDialog(context, localeProvider),
            );
          },
        ),
        const Divider(),
        _sectionHeader(isZh ? '数据备份' : 'Backup & Restore'),
        ListTile(
          leading: const Icon(Icons.archive_outlined),
          title: Text(isZh ? '完整备份 (ZIP)' : 'Full Backup (ZIP)'),
          subtitle: Text(isZh ? '包含所有数据和多媒体' : 'All data and media'),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(isZh ? '备份功能开发中...' : 'Backup coming soon...')),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.table_chart_outlined),
          title: Text(isZh ? '导出CSV' : 'Export CSV'),
          subtitle: Text(isZh ? '导出为电子表格格式' : 'Export as spreadsheet'),
          onTap: () => _showDateRangePicker(context),
        ),
        ListTile(
          leading: const Icon(Icons.picture_as_pdf_outlined),
          title: Text(isZh ? '导出PDF' : 'Export PDF'),
          subtitle: Text(isZh ? '导出为文档格式' : 'Export as document'),
          onTap: () => _showPdfDateRangePicker(context),
        ),
        ListTile(
          leading: const Icon(Icons.restore_outlined),
          title: Text(isZh ? '恢复数据' : 'Restore Data'),
          subtitle: Text(isZh ? '从备份文件导入' : 'Import from backup file'),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(isZh ? '恢复功能开发中...' : 'Restore coming soon...')),
            );
          },
        ),
        const Divider(),
        _sectionHeader(isZh ? '关于' : 'About'),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('Stalio'),
          subtitle: const Text('Version 1.0.0'),
        ),
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: Text(isZh ? '条款与隐私' : 'Terms & Privacy'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showLegalSheet(context),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
    );
  }

  void _showDateRangePicker(BuildContext ctx) {
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    showDialog(context: ctx, builder: (dCtx) => AlertDialog(
      title: Text(isZh ? '选择导出范围' : 'Select Export Range'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(title: Text(isZh ? '全部时间' : 'All time'), trailing: const Icon(Icons.chevron_right, size: 18), onTap: () { Navigator.pop(dCtx); _exportCsvData(ctx); }),
        ListTile(title: Text(isZh ? '最近30天' : 'Last 30 days'), trailing: const Icon(Icons.chevron_right, size: 18), onTap: () { Navigator.pop(dCtx); _exportCsvData(ctx, days: 30); }),
        ListTile(title: Text(isZh ? '最近90天' : 'Last 90 days'), trailing: const Icon(Icons.chevron_right, size: 18), onTap: () { Navigator.pop(dCtx); _exportCsvData(ctx, days: 90); }),
        ListTile(title: Text(isZh ? '自定义' : 'Custom'), trailing: const Icon(Icons.chevron_right, size: 18), onTap: () { Navigator.pop(dCtx); _showCustomDateRange(ctx, isCsv: true); }),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(dCtx), child: Text(isZh ? '取消' : 'Cancel'))],
    ));
  }

  void _showPdfDateRangePicker(BuildContext ctx) {
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    showDialog(context: ctx, builder: (dCtx) => AlertDialog(
      title: Text(isZh ? '选择导出范围' : 'Select Export Range'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(title: Text(isZh ? '全部时间' : 'All time'), trailing: const Icon(Icons.chevron_right, size: 18), onTap: () { Navigator.pop(dCtx); _exportPdfData(ctx); }),
        ListTile(title: Text(isZh ? '最近30天' : 'Last 30 days'), trailing: const Icon(Icons.chevron_right, size: 18), onTap: () { Navigator.pop(dCtx); _exportPdfData(ctx, days: 30); }),
        ListTile(title: Text(isZh ? '最近90天' : 'Last 90 days'), trailing: const Icon(Icons.chevron_right, size: 18), onTap: () { Navigator.pop(dCtx); _exportPdfData(ctx, days: 90); }),
        ListTile(title: Text(isZh ? '自定义' : 'Custom'), trailing: const Icon(Icons.chevron_right, size: 18), onTap: () { Navigator.pop(dCtx); _showCustomDateRange(ctx, isCsv: false); }),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(dCtx), child: Text(isZh ? '取消' : 'Cancel'))],
    ));
  }

  Future<void> _showCustomDateRange(BuildContext ctx, {bool isCsv = true}) async {
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    final now = DateTime.now();
    final picked = await showDateRangePicker(context: ctx, firstDate: DateTime(2020), lastDate: now, initialDateRange: DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now));
    if (picked != null) {
      if (isCsv) {
        _exportCsvData(ctx, startDate: picked.start, endDate: picked.end);
      } else {
        _exportPdfData(ctx, startDate: picked.start, endDate: picked.end);
      }
    }
  }

  Future<void> _exportCsvData(BuildContext ctx, {int? days, DateTime? startDate, DateTime? endDate}) async {
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    final exportService = context.read<ExportService>();
    showDialog(context: ctx, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      DateTime? s = startDate; DateTime? e = endDate;
      if (days != null) { e = DateTime.now(); s = e.subtract(Duration(days: days)); }
      final filePath = await exportService.exportCsv(startDate: s, endDate: e);
      if (!ctx.mounted) return;
      Navigator.of(ctx).pop();
      await exportService.shareFile(filePath, subject: 'Stalio CSV Export', text: isZh ? 'Stalio 数据导出 (CSV)' : 'Stalio data export (CSV)');
    } catch (e) {
      if (ctx.mounted) Navigator.of(ctx).pop();
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(isZh ? '导出失败: $e' : 'Export failed: $e'), duration: const Duration(seconds: 4)));
    }
  }

  Future<void> _exportPdfData(BuildContext ctx, {int? days, DateTime? startDate, DateTime? endDate}) async {
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    final exportService = context.read<ExportService>();
    showDialog(context: ctx, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      DateTime? s = startDate; DateTime? e = endDate;
      if (days != null) { e = DateTime.now(); s = e.subtract(Duration(days: days)); }
      final filePath = await exportService.exportPdf(startDate: s, endDate: e);
      if (!ctx.mounted) return;
      Navigator.of(ctx).pop();
      await exportService.shareFile(filePath, subject: 'Stalio PDF Export', text: isZh ? 'Stalio 数据导出 (PDF)' : 'Stalio data export (PDF)');
    } catch (e) {
      if (ctx.mounted) Navigator.of(ctx).pop();
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(isZh ? '导出失败: $e' : 'Export failed: $e'), duration: const Duration(seconds: 4)));
    }
  }

  void _showLegalSheet(BuildContext context) {
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) => DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: Text(isZh ? '条款与隐私' : 'Terms & Privacy'),
              bottom: TabBar(
                tabs: [
                  Tab(text: isZh ? '隐私政策' : 'Privacy'),
                  Tab(text: isZh ? '服务条款' : 'Terms'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _legalText(isZh ? kPrivacyPolicyContentZh : kPrivacyPolicyContent, scrollController),
                _legalText(isZh ? kTermsOfServiceContentZh : kTermsOfServiceContent, scrollController),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _legalText(String content, ScrollController scrollController) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        SelectableText(content, style: const TextStyle(fontSize: 14, height: 1.6)),
      ],
    );
  }

  void _showLanguageDialog(BuildContext context, LocaleProvider localeProvider) {
    final isZh = localeProvider.locale.languageCode == 'zh';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isZh ? '选择语言' : 'Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              trailing: !isZh ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () {
                localeProvider.setLocale(const Locale('en'));
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('中文'),
              trailing: isZh ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () {
                localeProvider.setLocale(const Locale('zh'));
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TagList extends StatefulWidget {
  @override
  State<_TagList> createState() => _TagListState();
}

class _TagListState extends State<_TagList> {
  final Map<String, bool> _expanded = {};
  bool _isSelecting = false;
  final Set<String> _selectedTagIds = {};

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final tags = context.watch<TagProvider>().tags;
    final categories = context.watch<TagCategoryProvider>().categories;

    final uncategorized = tags.where((t) => t.categoryId == null || t.categoryId!.isEmpty).toList();
    final categorized = <String, List<Tag>>{};
    for (final t in tags) {
      if (t.categoryId != null && t.categoryId!.isNotEmpty) {
        categorized.putIfAbsent(t.categoryId!, () => []).add(t);
      }
    }

    final selectable = tags.where((t) => t.category != 'system').toList();

    final children = <Widget>[];

    for (final cat in categories) {
      final catTags = categorized[cat.id] ?? [];
      final isExpanded = _expanded[cat.id] ?? true;
      final catSelectable = catTags.where((t) => t.category != 'system').toList();
      final allCatSelected = catSelectable.isNotEmpty && catSelectable.every((t) => _selectedTagIds.contains(t.id));

      children.add(_CategoryHeader(
        category: cat,
        isExpanded: isExpanded,
        tagCount: catTags.length,
        isSelecting: _isSelecting,
        allSelected: allCatSelected,
        hasSelectable: catSelectable.isNotEmpty,
        onTap: () => setState(() => _expanded[cat.id] = !isExpanded),
        onSelectAll: () => _toggleSelectAll(catSelectable),
        onEdit: () => _showEditCategoryDialog(context, cat),
        onDelete: () => _showDeleteCategoryDialog(context, cat),
      ));
      if (isExpanded) {
        if (catTags.isEmpty) {
          children.add(const Padding(
            padding: EdgeInsets.only(left: 48, bottom: 8),
            child: Text('No tags in this category', style: TextStyle(color: Colors.grey, fontSize: 13)),
          ));
        } else {
          for (final tag in catTags) {
            children.add(_TagTile(
              tag: tag, isZh: isZh, categories: categories,
              isSelecting: _isSelecting, isSelected: _selectedTagIds.contains(tag.id),
              onSelect: () => _toggleTag(tag), onLongPress: () => _enterSelectMode(tag),
              onEdit: () => _showEditTagDialog(context, tag, categories),
            ));
          }
        }
      }
      children.add(const SizedBox(height: 4));
    }

    if (uncategorized.isNotEmpty || categories.isEmpty) {
      final isExpanded = _expanded['uncategorized'] ?? true;
      final uncatSelectable = uncategorized.where((t) => t.category != 'system').toList();
      final allUncatSelected = uncatSelectable.isNotEmpty && uncatSelectable.every((t) => _selectedTagIds.contains(t.id));

      children.add(_CategoryHeader(
        category: TagCategory(id: 'uncategorized', name: isZh ? '未分类' : 'Uncategorized', nameEn: 'Uncategorized', color: '#9E9E9E', icon: '📋', createdAt: DateTime.now()),
        isExpanded: isExpanded, tagCount: uncategorized.length,
        isSelecting: _isSelecting, allSelected: allUncatSelected, hasSelectable: uncatSelectable.isNotEmpty,
        onTap: () => setState(() => _expanded['uncategorized'] = !isExpanded),
        onSelectAll: () => _toggleSelectAll(uncatSelectable),
        onEdit: null, onDelete: null,
      ));
      if (isExpanded) {
        for (final tag in uncategorized) {
          children.add(_TagTile(
            tag: tag, isZh: isZh, categories: categories,
            isSelecting: _isSelecting, isSelected: _selectedTagIds.contains(tag.id),
            onSelect: () => _toggleTag(tag), onLongPress: () => _enterSelectMode(tag),
            onEdit: () => _showEditTagDialog(context, tag, categories),
          ));
        }
      }
      children.add(const SizedBox(height: 4));
    }

    if (_isSelecting) {
      children.add(Container(
        color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(children: [
          Text('${_selectedTagIds.length} ${isZh ? '已选' : 'selected'}', style: const TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          TextButton(onPressed: () => setState(() { _isSelecting = false; _selectedTagIds.clear(); }), child: Text(isZh ? '取消' : 'Cancel')),
        ]),
      ));
      children.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Wrap(spacing: 8, runSpacing: 4, children: [
          ActionChip(avatar: const Icon(Icons.folder_outlined, size: 16), label: Text(isZh ? '移至分类' : 'Assign Category'), onPressed: _selectedTagIds.isEmpty ? null : () => _showAssignCategoryDialog(context)),
          ActionChip(avatar: const Icon(Icons.merge, size: 16), label: Text(isZh ? '合并' : 'Merge'), onPressed: _selectedTagIds.length < 2 ? null : () => _showMergeDialog(context)),
          ActionChip(avatar: const Icon(Icons.color_lens, size: 16), label: Text(isZh ? '改色' : 'Recolor'), onPressed: _selectedTagIds.isEmpty ? null : () => _showRecolorDialog(context)),
        ]),
      ));
    }

    if (!_isSelecting) {
      children.add(Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: OutlinedButton.icon(onPressed: () => _showAddCategoryDialog(context), icon: const Icon(Icons.create_new_folder_outlined, size: 18), label: Text(isZh ? '添加分类' : 'Add Category'))));
      children.add(Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: OutlinedButton.icon(onPressed: () => _showAddTagDialog(context, categories, isZh), icon: const Icon(Icons.add, size: 18), label: Text(isZh ? '添加标签' : 'Add Tag'))));
    }

    return ListView(children: children);
  }

  void _toggleTag(Tag tag) {
    setState(() {
      if (tag.category == 'system') return;
      if (_selectedTagIds.contains(tag.id)) { _selectedTagIds.remove(tag.id); if (_selectedTagIds.isEmpty) _isSelecting = false; }
      else { _selectedTagIds.add(tag.id); _isSelecting = true; }
    });
  }
  void _enterSelectMode(Tag tag) { if (tag.category == 'system') return; setState(() { _isSelecting = true; _selectedTagIds.add(tag.id); }); }
  void _toggleSelectAll(List<Tag> tags) {
    setState(() {
      final allSelected = tags.every((t) => _selectedTagIds.contains(t.id));
      if (allSelected) { for (final t in tags) _selectedTagIds.remove(t.id); if (_selectedTagIds.isEmpty) _isSelecting = false; }
      else { for (final t in tags) _selectedTagIds.add(t.id); _isSelecting = true; }
    });
  }

  void _showAssignCategoryDialog(BuildContext context) {
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    final categories = context.read<TagCategoryProvider>().categories;
    String? selectedCategoryId;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) => AlertDialog(
      title: Text(isZh ? '移至分类' : 'Assign to Category'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(isZh ? '将 ${_selectedTagIds.length} 个标签移至：' : 'Move ${_selectedTagIds.length} tags to:'),
        const SizedBox(height: 12),
        for (final cat in categories) RadioListTile<String>(title: Text('${cat.icon} ${cat.displayName(isZh)}'), value: cat.id, groupValue: selectedCategoryId, onChanged: (v) => setDialogState(() => selectedCategoryId = v)),
        RadioListTile<String>(title: Text(isZh ? '（无分类）' : '(Uncategorized)'), value: '_none_', groupValue: selectedCategoryId, onChanged: (v) => setDialogState(() => selectedCategoryId = v)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isZh ? '取消' : 'Cancel')),
        FilledButton(onPressed: selectedCategoryId == null ? null : () {
          final targetId = selectedCategoryId == '_none_' ? null : selectedCategoryId;
          final tagProvider = context.read<TagProvider>();
          for (final id in _selectedTagIds.toList()) { final tag = tagProvider.getTagById(id); if (tag != null) tagProvider.updateTag(tag.copyWith(categoryId: targetId)); }
          Navigator.pop(ctx); setState(() { _isSelecting = false; _selectedTagIds.clear(); });
        }, child: Text(isZh ? '移动' : 'Move')),
      ],
    )));
  }

  void _showMergeDialog(BuildContext context) {
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    final tagProvider = context.read<TagProvider>();
    final selectedTags = _selectedTagIds.map((id) => tagProvider.getTagById(id)!).where((t) => t != null).toList();
    String? targetId;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) => AlertDialog(
      title: Text(isZh ? '合并标签' : 'Merge Tags'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(isZh ? '选择保留的标签，其他标签的条目将合并到此标签：' : 'Choose the tag to keep. Entries from other tags will be merged into it:'),
        const SizedBox(height: 12),
        for (final tag in selectedTags) RadioListTile<String>(title: Text(tag.displayName(isZh)), value: tag.id, groupValue: targetId, onChanged: (v) => setDialogState(() => targetId = v)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isZh ? '取消' : 'Cancel')),
        FilledButton(onPressed: targetId == null ? null : () { final sourceIds = _selectedTagIds.where((id) => id != targetId).toList(); context.read<TagProvider>().mergeTags(targetId!, sourceIds); Navigator.pop(ctx); setState(() { _isSelecting = false; _selectedTagIds.clear(); }); }, child: Text(isZh ? '合并' : 'Merge')),
      ],
    )));
  }

  void _showRecolorDialog(BuildContext context) {
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    String newColor = '#007AFF';
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) => AlertDialog(
      title: Text(isZh ? '批量改色' : 'Batch Recolor'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(isZh ? '将 ${_selectedTagIds.length} 个标签改为：' : 'Change ${_selectedTagIds.length} tags to:'),
        const SizedBox(height: 16),
        Wrap(spacing: 8, children: ['#007AFF', '#34C759', '#FF9500', '#FF2D55', '#5856D6', '#AF52DE', '#FF3B30'].map((c) {
          final selected = newColor == c;
          return GestureDetector(onTap: () => setDialogState(() => newColor = c), child: Container(width: 36, height: 36, decoration: BoxDecoration(color: Color(int.parse(c.replaceFirst('#', '0xFF'))), shape: BoxShape.circle, border: selected ? Border.all(color: Colors.black, width: 2) : null)));
        }).toList()),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isZh ? '取消' : 'Cancel')),
        FilledButton(onPressed: () { final tagProvider = context.read<TagProvider>(); for (final id in _selectedTagIds.toList()) { final tag = tagProvider.getTagById(id); if (tag != null) tagProvider.updateTag(tag.copyWith(color: newColor)); } Navigator.pop(ctx); setState(() { _isSelecting = false; _selectedTagIds.clear(); }); }, child: Text(isZh ? '应用' : 'Apply')),
      ],
    )));
  }

  void _showAddCategoryDialog(BuildContext context) {
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    final nameCtrl = TextEditingController(); final nameEnCtrl = TextEditingController();
    String color = '#007AFF'; String icon = '📁';
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) => AlertDialog(
      title: Text(isZh ? '添加分类' : 'Add Category'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, decoration: InputDecoration(labelText: isZh ? '分类名称' : 'Category name', border: const OutlineInputBorder()), autofocus: true),
        const SizedBox(height: 8),
        TextField(controller: nameEnCtrl, decoration: InputDecoration(labelText: isZh ? '英文名称' : 'English name', border: const OutlineInputBorder())),
        const SizedBox(height: 8),
        TextField(decoration: InputDecoration(labelText: isZh ? '图标 (emoji)' : 'Icon (emoji)', border: const OutlineInputBorder(), hintText: '📁'), onChanged: (v) => icon = v.isNotEmpty ? v : '📁'),
        const SizedBox(height: 16),
        Wrap(spacing: 8, children: ['#007AFF', '#34C759', '#FF9500', '#FF2D55', '#5856D6', '#AF52DE', '#FF3B30'].map((c) {
          final selected = color == c;
          return GestureDetector(onTap: () => setDialogState(() => color = c), child: Container(width: 32, height: 32, decoration: BoxDecoration(color: Color(int.parse(c.replaceFirst('#', '0xFF'))), shape: BoxShape.circle, border: selected ? Border.all(color: Colors.black, width: 2) : null)));
        }).toList()),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isZh ? '取消' : 'Cancel')),
        FilledButton(onPressed: nameCtrl.text.trim().isEmpty ? null : () { context.read<TagCategoryProvider>().addCategory(name: nameCtrl.text.trim(), nameEn: nameEnCtrl.text.trim().isEmpty ? nameCtrl.text.trim() : nameEnCtrl.text.trim(), color: color, icon: icon); Navigator.pop(ctx); }, child: Text(isZh ? '添加' : 'Add')),
      ],
    )));
  }

  void _showEditCategoryDialog(BuildContext context, TagCategory cat) {
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    final nameCtrl = TextEditingController(text: cat.name); final nameEnCtrl = TextEditingController(text: cat.nameEn);
    String color = cat.color; String icon = cat.icon;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) => AlertDialog(
      title: Text(isZh ? '编辑分类' : 'Edit Category'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, decoration: InputDecoration(labelText: isZh ? '分类名称' : 'Category name', border: const OutlineInputBorder())),
        const SizedBox(height: 8),
        TextField(controller: nameEnCtrl, decoration: InputDecoration(labelText: isZh ? '英文名称' : 'English name', border: const OutlineInputBorder())),
        const SizedBox(height: 8),
        TextField(decoration: InputDecoration(labelText: isZh ? '图标 (emoji)' : 'Icon (emoji)', border: const OutlineInputBorder(), hintText: cat.icon), onChanged: (v) => icon = v.isNotEmpty ? v : cat.icon),
        const SizedBox(height: 16),
        Wrap(spacing: 8, children: ['#007AFF', '#34C759', '#FF9500', '#FF2D55', '#5856D6', '#AF52DE', '#FF3B30'].map((c) {
          final selected = color == c;
          return GestureDetector(onTap: () => setDialogState(() => color = c), child: Container(width: 32, height: 32, decoration: BoxDecoration(color: Color(int.parse(c.replaceFirst('#', '0xFF'))), shape: BoxShape.circle, border: selected ? Border.all(color: Colors.black, width: 2) : null)));
        }).toList()),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isZh ? '取消' : 'Cancel')),
        FilledButton(onPressed: nameCtrl.text.trim().isEmpty ? null : () { context.read<TagCategoryProvider>().updateCategory(cat.copyWith(name: nameCtrl.text.trim(), nameEn: nameEnCtrl.text.trim().isEmpty ? nameCtrl.text.trim() : nameEnCtrl.text.trim(), color: color, icon: icon)); Navigator.pop(ctx); }, child: Text(isZh ? '保存' : 'Save')),
      ],
    )));
  }

  void _showDeleteCategoryDialog(BuildContext context, TagCategory cat) {
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text(isZh ? '删除分类' : 'Delete Category'),
      content: Text(isZh ? '确定删除"${cat.name}"？所属标签将变为未分类。' : 'Delete "${cat.nameEn}"? Tags in this category will become uncategorized.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isZh ? '取消' : 'Cancel')), TextButton(onPressed: () { context.read<TagCategoryProvider>().deleteCategory(cat.id); Navigator.pop(ctx); }, child: Text(isZh ? '删除' : 'Delete', style: const TextStyle(color: Colors.red)))],
    ));
  }

  void _showAddTagDialog(BuildContext context, List<TagCategory> categories, bool isZh) {
    final nameCtrl = TextEditingController(); final nameEnCtrl = TextEditingController();
    String color = '#007AFF'; String? categoryId;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) => AlertDialog(
      title: Text(isZh ? '新建标签' : 'New Tag'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, decoration: InputDecoration(labelText: isZh ? '标签名称' : 'Tag name', border: const OutlineInputBorder()), autofocus: true),
        const SizedBox(height: 8),
        TextField(controller: nameEnCtrl, decoration: InputDecoration(labelText: isZh ? '英文名称' : 'English name', border: const OutlineInputBorder())),
        if (categories.isNotEmpty) ...[const SizedBox(height: 12), DropdownButtonFormField<String?>(value: categoryId, decoration: InputDecoration(labelText: isZh ? '分类' : 'Category', border: const OutlineInputBorder()), items: [DropdownMenuItem<String?>(value: null, child: Text(isZh ? '（无分类）' : '(Uncategorized)')), ...categories.map((c) => DropdownMenuItem<String?>(value: c.id, child: Text('${c.icon} ${c.displayName(isZh)}')))], onChanged: (v) => setDialogState(() => categoryId = v))],
        const SizedBox(height: 16),
        Wrap(spacing: 8, children: ['#007AFF', '#34C759', '#FF9500', '#FF2D55', '#5856D6', '#AF52DE', '#FF3B30'].map((c) {
          final selected = color == c;
          return GestureDetector(onTap: () => setDialogState(() => color = c), child: Container(width: 32, height: 32, decoration: BoxDecoration(color: Color(int.parse(c.replaceFirst('#', '0xFF'))), shape: BoxShape.circle, border: selected ? Border.all(color: Colors.black, width: 2) : null)));
        }).toList()),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isZh ? '取消' : 'Cancel')),
        FilledButton(onPressed: nameCtrl.text.trim().isEmpty ? null : () { final name = nameCtrl.text.trim(); final nameEn = nameEnCtrl.text.trim().isEmpty ? name : nameEnCtrl.text.trim(); context.read<TagProvider>().addTag(name: name, nameEn: nameEn, color: color, categoryId: categoryId); Navigator.pop(ctx); }, child: Text(isZh ? '添加' : 'Add')),
      ],
    )));
  }

  void _showEditTagDialog(BuildContext context, Tag tag, List<TagCategory> categories) {
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    final nameCtrl = TextEditingController(text: tag.name); final nameEnCtrl = TextEditingController(text: tag.nameEn);
    String color = tag.color; String? categoryId = tag.categoryId;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) => AlertDialog(
      title: Text(isZh ? '编辑标签' : 'Edit Tag'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, decoration: InputDecoration(labelText: isZh ? '标签名称' : 'Tag name', border: const OutlineInputBorder())),
        const SizedBox(height: 8),
        TextField(controller: nameEnCtrl, decoration: InputDecoration(labelText: isZh ? '英文名称' : 'English name', border: const OutlineInputBorder())),
        if (categories.isNotEmpty) ...[const SizedBox(height: 12), DropdownButtonFormField<String?>(value: categoryId, decoration: InputDecoration(labelText: isZh ? '分类' : 'Category', border: const OutlineInputBorder()), items: [DropdownMenuItem<String?>(value: null, child: Text(isZh ? '（无分类）' : '(Uncategorized)')), ...categories.map((c) => DropdownMenuItem<String?>(value: c.id, child: Text('${c.icon} ${c.displayName(isZh)}')))], onChanged: (v) => setDialogState(() => categoryId = v))],
        const SizedBox(height: 16),
        Wrap(spacing: 8, children: ['#007AFF', '#34C759', '#FF9500', '#FF2D55', '#5856D6', '#AF52DE', '#FF3B30'].map((c) {
          final selected = color == c;
          return GestureDetector(onTap: () => setDialogState(() => color = c), child: Container(width: 32, height: 32, decoration: BoxDecoration(color: Color(int.parse(c.replaceFirst('#', '0xFF'))), shape: BoxShape.circle, border: selected ? Border.all(color: Colors.black, width: 2) : null)));
        }).toList()),
      ])),
      actions: [
        TextButton(onPressed: () { context.read<TagProvider>().deleteTag(tag.id); Navigator.pop(ctx); }, child: Text(isZh ? '删除' : 'Delete', style: const TextStyle(color: Colors.red))),
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isZh ? '取消' : 'Cancel')),
        FilledButton(onPressed: nameCtrl.text.trim().isEmpty ? null : () { context.read<TagProvider>().updateTag(tag.copyWith(name: nameCtrl.text.trim(), nameEn: nameEnCtrl.text.trim().isEmpty ? nameCtrl.text.trim() : nameEnCtrl.text.trim(), color: color, categoryId: categoryId)); Navigator.pop(ctx); }, child: Text(isZh ? '保存' : 'Save')),
      ],
    )));
  }
}

class _CategoryHeader extends StatelessWidget {
  final TagCategory category; final bool isExpanded; final int tagCount; final bool isSelecting; final bool allSelected; final bool hasSelectable;
  final VoidCallback onTap; final VoidCallback? onSelectAll; final VoidCallback? onEdit; final VoidCallback? onDelete;
  const _CategoryHeader({required this.category, required this.isExpanded, required this.tagCount, this.isSelecting = false, this.allSelected = false, this.hasSelectable = false, required this.onTap, this.onSelectAll, this.onEdit, this.onDelete});
  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final isUncategorized = category.id == 'uncategorized';
    final color = Color(int.parse(category.color.replaceFirst('#', '0xFF')));
    return ListTile(
      leading: CircleAvatar(radius: 16, backgroundColor: color.withValues(alpha: 0.2), child: Text(category.icon, style: const TextStyle(fontSize: 16))),
      title: Text(category.displayName(isZh), style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: tagCount > 0 ? Text('$tagCount ${isZh ? '个标签' : 'tags'}') : null,
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (isSelecting && hasSelectable) Checkbox(value: allSelected, onChanged: (_) => onSelectAll?.call(), visualDensity: VisualDensity.compact),
        if (!isSelecting) ...[
          if (!isUncategorized && onEdit != null) IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: onEdit),
          if (!isUncategorized && onDelete != null) IconButton(icon: const Icon(Icons.delete_outline, size: 18), onPressed: onDelete),
        ],
        Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
      ]),
      onTap: onTap,
    );
  }
}

class _TagTile extends StatelessWidget {
  final Tag tag; final bool isZh; final List<TagCategory> categories; final bool isSelecting; final bool isSelected; final VoidCallback? onSelect; final VoidCallback? onLongPress; final VoidCallback onEdit;
  const _TagTile({required this.tag, required this.isZh, required this.categories, this.isSelecting = false, this.isSelected = false, this.onSelect, this.onLongPress, required this.onEdit});
  @override
  Widget build(BuildContext context) {
    final isSystem = tag.category == 'system';
    return Padding(
      padding: const EdgeInsets.only(left: 48, right: 8),
      child: ListTile(
        dense: true,
        leading: isSelecting && !isSystem ? Checkbox(value: isSelected, onChanged: (_) => onSelect?.call(), visualDensity: VisualDensity.compact) : CircleAvatar(radius: 10, backgroundColor: Color(int.parse(tag.color.replaceFirst('#', '0xFF')))),
        title: Text(tag.displayName(isZh), style: const TextStyle(fontSize: 14)),
        trailing: isSelecting ? null : isSystem ? const Icon(Icons.lock_outline, size: 14, color: Colors.grey) : IconButton(icon: const Icon(Icons.edit_outlined, size: 16), onPressed: onEdit),
        onTap: isSelecting && !isSystem ? () => onSelect?.call() : null,
        onLongPress: !isSelecting && !isSystem ? () => onLongPress?.call() : null,
      ),
    );
  }
}

class _HabitBuildTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final provider = context.watch<RoutineProvider>();
    final routines = provider.routines;
    final active = routines.where((r) => r.isActive).toList();
    final paused = routines.where((r) => !r.isActive).toList();

    if (routines.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                isZh ? '开始建立你的日常习惯' : 'Start building your routine',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                isZh
                    ? '小的习惯，坚持做下去，\n会带来持久的改变。'
                    : 'Small habits, done consistently,\ncreate lasting change.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (active.isNotEmpty) ...[
          Row(
            children: [
              Text(
                isZh ? '活跃' : 'Active',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${active.length}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...active.map((r) => _BuildRoutineTile(
                routine: r,
                onEdit: () => _showEditHabitDialog(context, r),
                onToggle: () => _toggleActive(context, r),
              )),
          const SizedBox(height: 16),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: OutlinedButton.icon(
            onPressed: () => _showAddHabitDialog(context),
            icon: const Icon(Icons.add, size: 18),
            label: Text(isZh ? '添加习惯' : 'Add Habit'),
          ),
        ),
        if (paused.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                isZh ? '已暂停' : 'Paused',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${paused.length}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...paused.map((r) => _BuildRoutineTile(
                routine: r,
                onEdit: () => _showEditHabitDialog(context, r),
                onToggle: () => _toggleActive(context, r),
              )),
        ],
        const SizedBox(height: 80),
      ],
    );
  }

  void _showEditHabitDialog(BuildContext context, Routine routine) {
    RoutineDialog.show(context, existing: routine);
  }

  void _showAddHabitDialog(BuildContext context) {
    RoutineDialog.show(context);
  }

  void _toggleActive(BuildContext context, Routine routine) {
    context.read<RoutineProvider>().toggleActive(routine.id);
  }
}

class _BuildRoutineTile extends StatelessWidget {
  final Routine routine;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  const _BuildRoutineTile({
    required this.routine,
    required this.onEdit,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final active = routine.isActive;
    return Opacity(
      opacity: active ? 1.0 : 0.55,
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: active
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: _buildRoutineIcon(routine, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routine.displayName(isZh),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: active ? null : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      routine.frequencyLabelFor(isZh),
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                    if (routine.description != null &&
                        routine.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          isZh
                              ? routine.description!
                              : (routine.descriptionEn ?? routine.description!),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    if (!active && routine.streak > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          isZh
                              ? '暂停 · 最佳记录 ${routine.streak} 天'
                              : 'Paused · best ${routine.streak} days',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Switch(
                value: active,
                onChanged: (_) => onToggle(),
                activeTrackColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                activeThumbColor: Theme.of(context).colorScheme.primary,
              ),
              GestureDetector(
                onTap: onEdit,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(Icons.more_vert,
                      size: 18, color: Colors.grey[400]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildRoutineIcon(Routine routine, {double size = 20}) {
  if (routine.iconImagePath != null) {
    final file = File(routine.iconImagePath!);
    if (file.existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.file(file,
            width: size, height: size, fit: BoxFit.cover),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
    );
  }
}
  return Text(routine.effectiveIcon, style: TextStyle(fontSize: size));
}
