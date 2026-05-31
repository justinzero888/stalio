import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../models/tag.dart';
import '../../models/routine.dart';
import '../../providers/locale_provider.dart';
import '../../providers/tag_provider.dart';
import '../../providers/routine_provider.dart';
import '../../core/services/storage_service.dart';
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

class _TagList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final tags = context.watch<TagProvider>().tags;

    return ListView(
      children: [
        ...tags.map((tag) => ListTile(
          leading: CircleAvatar(
            radius: 12,
            backgroundColor: Color(int.parse(tag.color.replaceFirst('#', '0xFF'))),
          ),
          title: Text(tag.displayName(isZh)),
          trailing: tag.category != 'system'
              ? IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: () => _showEditTagDialog(context, tag),
                )
              : const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
        )),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: OutlinedButton.icon(
            onPressed: () => _showAddTagDialog(context, isZh),
            icon: const Icon(Icons.add, size: 18),
            label: Text(isZh ? '添加标签' : 'Add Tag'),
          ),
        ),
      ],
    );
  }

  void _showAddTagDialog(BuildContext context, bool isZh) {
    final nameCtrl = TextEditingController();
    final nameEnCtrl = TextEditingController();
    String color = '#007AFF';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isZh ? '新建标签' : 'New Tag'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: isZh ? '标签名称' : 'Tag name',
                  border: const OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameEnCtrl,
                decoration: InputDecoration(
                  labelText: isZh ? '英文名称' : 'English name',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  '#007AFF', '#34C759', '#FF9500', '#FF2D55',
                  '#5856D6', '#AF52DE', '#FF3B30',
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
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isZh ? '取消' : 'Cancel')),
            FilledButton(
              onPressed: nameCtrl.text.trim().isEmpty ? null : () {
                final tagProvider = context.read<TagProvider>();
                final name = nameCtrl.text.trim();
                final nameEn = nameEnCtrl.text.trim().isEmpty ? name : nameEnCtrl.text.trim();
                tagProvider.addTag(name: name, nameEn: nameEn, color: color);
                Navigator.pop(ctx);
              },
              child: Text(isZh ? '添加' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTagDialog(BuildContext context, Tag tag) {
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    final nameCtrl = TextEditingController(text: tag.name);
    final nameEnCtrl = TextEditingController(text: tag.nameEn);
    String color = tag.color;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isZh ? '编辑标签' : 'Edit Tag'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: isZh ? '标签名称' : 'Tag name',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameEnCtrl,
                decoration: InputDecoration(
                  labelText: isZh ? '英文名称' : 'English name',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  '#007AFF', '#34C759', '#FF9500', '#FF2D55',
                  '#5856D6', '#AF52DE', '#FF3B30',
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
              },
              child: Text(isZh ? '删除' : 'Delete', style: const TextStyle(color: Colors.red)),
            ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isZh ? '取消' : 'Cancel')),
            FilledButton(
              onPressed: nameCtrl.text.trim().isEmpty ? null : () {
                context.read<TagProvider>().updateTag(tag.copyWith(
                  name: nameCtrl.text.trim(),
                  nameEn: nameEnCtrl.text.trim().isEmpty ? nameCtrl.text.trim() : nameEnCtrl.text.trim(),
                  color: color,
                ));
                Navigator.pop(ctx);
              },
              child: Text(isZh ? '保存' : 'Save'),
            ),
          ],
        ),
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
  }
  return Text(routine.effectiveIcon, style: TextStyle(fontSize: size));
}
