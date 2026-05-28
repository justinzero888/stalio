import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/tag.dart';
import '../../providers/locale_provider.dart';
import '../../providers/tag_provider.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/voice_notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final storage = context.read<StorageService>();
    final voiceEnabled = storage.getVoiceEnabled();

    return Scaffold(
      appBar: AppBar(title: Text(isZh ? '设置' : 'Settings')),
      body: ListView(
        children: [
          _buildSectionHeader(isZh ? '通知' : 'Notifications'),
          SwitchListTile(
            title: Text(isZh ? '语音提醒' : 'Voice Reminders'),
            subtitle: Text(isZh ? '在设定时间朗读习惯名称' : 'Speak habit names at scheduled times'),
            value: voiceEnabled,
            onChanged: (value) {
              storage.setVoiceEnabled(value);
              setState(() {});
            },
          ),
          ValueListenableBuilder<bool>(
            valueListenable: ValueNotifier(voiceEnabled),
            builder: (context, v, _) {
              if (!voiceEnabled) return const SizedBox.shrink();
              return Padding(
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
              );
            },
          ),
          const Divider(),
          _buildSectionHeader(isZh ? '标签管理' : 'Tag Management'),
          _TagList(isZh: isZh),
          const Divider(),
          _buildSectionHeader(isZh ? '语言' : 'Language'),
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
          _buildSectionHeader(isZh ? '数据' : 'Data'),
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
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: Text(isZh ? '清除所有数据' : 'Clear All Data', style: const TextStyle(color: Colors.red)),
            subtitle: Text(isZh ? '永久删除所有笔记和习惯' : 'Permanently delete all notes and habits'),
            onTap: () => _showClearDialog(context, isZh, storage),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
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

  void _showClearDialog(BuildContext context, bool isZh, StorageService storage) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isZh ? '清除所有数据？' : 'Clear all data?'),
        content: Text(isZh ? '这将永久删除所有笔记、习惯和标签。此操作不可撤销。' : 'This will permanently delete all notes, habits, and tags. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isZh ? '取消' : 'Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await storage.clearAll();
              Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isZh ? '所有数据已清除' : 'All data cleared')),
                );
              }
            },
            child: Text(isZh ? '全部清除' : 'Clear All'),
          ),
        ],
      ),
    );
  }
}

class _TagList extends StatefulWidget {
  final bool isZh;
  const _TagList({required this.isZh});

  @override
  State<_TagList> createState() => _TagListState();
}

class _TagListState extends State<_TagList> {
  List<Tag> _tags = [];

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  void _loadTags() {
    final tagProvider = context.read<TagProvider>();
    setState(() => _tags = tagProvider.tags);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ..._tags.map((tag) => ListTile(
          leading: CircleAvatar(
            radius: 12,
            backgroundColor: Color(int.parse(tag.color.replaceFirst('#', '0xFF'))),
          ),
          title: Text(tag.displayName(widget.isZh)),
          trailing: tag.category != 'system'
              ? IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: () => _showEditTagDialog(tag),
                )
              : const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
        )),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: OutlinedButton.icon(
            onPressed: _showAddTagDialog,
            icon: const Icon(Icons.add, size: 18),
            label: Text(widget.isZh ? '添加标签' : 'Add Tag'),
          ),
        ),
      ],
    );
  }

  void _showAddTagDialog() {
    final nameCtrl = TextEditingController();
    final nameEnCtrl = TextEditingController();
    String color = '#007AFF';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(widget.isZh ? '新建标签' : 'New Tag'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: widget.isZh ? '标签名称' : 'Tag name',
                  border: const OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameEnCtrl,
                decoration: InputDecoration(
                  labelText: widget.isZh ? '英文名称' : 'English name',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  '#007AFF', '#34C759', '#FF9500', '#FF2D55',
                  '#5856D6', '#AF52DE', '#FF3B30', '#FF9500',
                ].map((c) {
                  final selected = color == c;
                  return GestureDetector(
                    onTap: () => setDialogState(() => color = c),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: Color(int.parse(c.replaceFirst('#', '0xFF'))),
                        shape: BoxShape.circle,
                        border: selected ? Border.all(color: Colors.black, width: 2) : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(widget.isZh ? '取消' : 'Cancel')),
            FilledButton(
              onPressed: nameCtrl.text.trim().isEmpty ? null : () {
                final tagProvider = context.read<TagProvider>();
                final name = nameCtrl.text.trim();
                final nameEn = nameEnCtrl.text.trim().isEmpty ? name : nameEnCtrl.text.trim();
                tagProvider.addTag(name: name, nameEn: nameEn, color: color);
                Navigator.pop(ctx);
                _loadTags();
              },
              child: Text(widget.isZh ? '添加' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTagDialog(Tag tag) {
    final nameCtrl = TextEditingController(text: tag.name);
    final nameEnCtrl = TextEditingController(text: tag.nameEn);
    String color = tag.color;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(widget.isZh ? '编辑标签' : 'Edit Tag'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: widget.isZh ? '标签名称' : 'Tag name',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameEnCtrl,
                decoration: InputDecoration(
                  labelText: widget.isZh ? '英文名称' : 'English name',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  '#007AFF', '#34C759', '#FF9500', '#FF2D55',
                  '#5856D6', '#AF52DE', '#FF3B30', '#FF9500',
                ].map((c) {
                  final selected = color == c;
                  return GestureDetector(
                    onTap: () => setDialogState(() => color = c),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: Color(int.parse(c.replaceFirst('#', '0xFF'))),
                        shape: BoxShape.circle,
                        border: selected ? Border.all(color: Colors.black, width: 2) : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                context.read<TagProvider>().deleteTag(tag.id);
                Navigator.pop(ctx);
                _loadTags();
              },
              child: Text(widget.isZh ? '删除' : 'Delete', style: const TextStyle(color: Colors.red)),
            ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(widget.isZh ? '取消' : 'Cancel')),
            FilledButton(
              onPressed: nameCtrl.text.trim().isEmpty ? null : () {
                final tagProvider = context.read<TagProvider>();
                tagProvider.updateTag(tag.copyWith(
                  name: nameCtrl.text.trim(),
                  nameEn: nameEnCtrl.text.trim().isEmpty ? nameCtrl.text.trim() : nameEnCtrl.text.trim(),
                  color: color,
                ));
                Navigator.pop(ctx);
                _loadTags();
              },
              child: Text(widget.isZh ? '保存' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}
