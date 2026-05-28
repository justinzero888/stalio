import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/tag.dart';
import '../../models/routine.dart';
import '../../providers/locale_provider.dart';
import '../../providers/tag_provider.dart';
import '../../providers/routine_provider.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/voice_notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
          title: const Text('Micro Habits'),
          subtitle: const Text('Version 1.0.0'),
        ),
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: Text(isZh ? '条款与隐私' : 'Terms & Privacy'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(isZh ? '条款与隐私政策' : 'Terms & Privacy Policy')),
            );
          },
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
    final activeHabits = provider.activeRoutines;
    final pausedHabits = provider.inactiveRoutines;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        if (activeHabits.isEmpty && pausedHabits.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.checklist, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    isZh ? '还没有习惯' : 'No habits yet',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isZh ? '点击右下角 + 创建第一个习惯' : 'Tap + to create your first habit',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        if (activeHabits.isNotEmpty) ...[
          Text(isZh ? '进行中' : 'Active', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
          const SizedBox(height: 8),
          ...activeHabits.map((r) => _HabitTile(
                routine: r,
                onEdit: () => _showEditHabitDialog(context, r),
              )),
          if (pausedHabits.isNotEmpty) const SizedBox(height: 16),
        ],
        if (pausedHabits.isNotEmpty) ...[
          Text(isZh ? '已暂停' : 'Paused', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
          const SizedBox(height: 8),
          ...pausedHabits.map((r) => _HabitTile(
                routine: r,
                onEdit: () => _showEditHabitDialog(context, r),
              )),
        ],
        const SizedBox(height: 80),
      ],
    );
  }

  void _showEditHabitDialog(BuildContext context, Routine routine) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _EditHabitScreen(routine: routine)),
    );
  }
}

class _HabitTile extends StatelessWidget {
  final Routine routine;
  final VoidCallback onEdit;

  const _HabitTile({required this.routine, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: routine.isActive
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.grey[200],
          child: Text(
            '${routine.streak}',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                color: routine.isActive ? null : Colors.grey),
          ),
        ),
        title: Text(
          routine.displayName(isZh),
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: routine.isActive ? null : Colors.grey,
          ),
        ),
        subtitle: Row(
          children: [
            Text(routine.frequencyLabelFor(isZh), style: const TextStyle(fontSize: 12)),
            if (routine.voiceEnabled) ...[
              const SizedBox(width: 6),
              const Icon(Icons.volume_up, size: 12, color: Colors.grey),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined, size: 18),
          onPressed: onEdit,
        ),
        onTap: onEdit,
      ),
    );
  }
}

class _EditHabitScreen extends StatefulWidget {
  final Routine routine;
  const _EditHabitScreen({required this.routine});

  @override
  State<_EditHabitScreen> createState() => _EditHabitScreenState();
}

class _EditHabitScreenState extends State<_EditHabitScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _nameEnCtrl;
  late RoutineFrequency _frequency;
  TimeOfDay? _reminderTime;
  late bool _voiceEnabled;
  late bool _isActive;
  late List<int> _weekdays;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.routine.name);
    _nameEnCtrl = TextEditingController(text: widget.routine.nameEn);
    _frequency = widget.routine.frequency;
    _voiceEnabled = widget.routine.voiceEnabled;
    _isActive = widget.routine.isActive;
    _weekdays = List.from(widget.routine.scheduledDaysOfWeek ?? []);
    if (widget.routine.reminderTime != null) {
      final parts = widget.routine.reminderTime!.split(':');
      _reminderTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameEnCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';

    return Scaffold(
      appBar: AppBar(
        title: Text(isZh ? '编辑习惯' : 'Edit Habit'),
        actions: [
          TextButton(
            child: Text(isZh ? '保存' : 'Save'),
            onPressed: _nameCtrl.text.trim().isEmpty ? null : _save,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: isZh ? '习惯名称' : 'Habit name',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameEnCtrl,
            decoration: InputDecoration(
              labelText: isZh ? '英文名称' : 'English name',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<RoutineFrequency>(
            initialValue: _frequency,
            decoration: InputDecoration(
              labelText: isZh ? '频率' : 'Frequency',
              border: const OutlineInputBorder(),
            ),
            items: RoutineFrequency.values.map((f) => DropdownMenuItem(
                  value: f,
                  child: Text(f == RoutineFrequency.daily
                      ? (isZh ? '每天' : 'Daily')
                      : f == RoutineFrequency.weekly
                          ? (isZh ? '每周' : 'Weekly')
                          : f == RoutineFrequency.scheduled
                              ? (isZh ? '指定日期' : 'Scheduled')
                              : (isZh ? '随时' : 'On demand')),
                )).toList(),
            onChanged: (v) => setState(() => _frequency = v!),
          ),
          if (_frequency == RoutineFrequency.weekly) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [1, 2, 3, 4, 5, 6, 7].map((d) {
                const names = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                return FilterChip(
                  label: Text(names[d]),
                  selected: _weekdays.contains(d),
                  onSelected: (v) {
                    setState(() {
                      v ? _weekdays.add(d) : _weekdays.remove(d);
                    });
                  },
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(isZh ? '启用' : 'Active'),
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
          ),
          SwitchListTile(
            title: Text(isZh ? '提醒' : 'Reminder'),
            value: _reminderTime != null,
            onChanged: (v) async {
              if (v) {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _reminderTime ?? const TimeOfDay(hour: 9, minute: 0),
                );
                if (time != null) setState(() => _reminderTime = time);
              } else {
                setState(() => _reminderTime = null);
              }
            },
          ),
          if (_reminderTime != null)
            SwitchListTile(
              title: Text(isZh ? '语音朗读' : 'Speak aloud'),
              value: _voiceEnabled,
              onChanged: (v) => setState(() => _voiceEnabled = v),
            ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              context.read<RoutineProvider>().deleteRoutine(widget.routine.id);
              Navigator.pop(context);
            },
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            label: Text(isZh ? '删除习惯' : 'Delete Habit', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final nameEn = _nameEnCtrl.text.trim().isEmpty ? name : _nameEnCtrl.text.trim();
    final reminderStr = _reminderTime != null
        ? '${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}'
        : null;

    final updated = widget.routine.copyWith(
      name: name,
      nameEn: nameEn,
      frequency: _frequency,
      reminderTime: reminderStr,
      isActive: _isActive,
      scheduledDaysOfWeek: _frequency == RoutineFrequency.weekly && _weekdays.isNotEmpty ? _weekdays : null,
      voiceEnabled: _voiceEnabled,
    );

    context.read<RoutineProvider>().updateRoutine(updated);
    Navigator.pop(context);
  }
}
