import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';
import '../../models/lens_set.dart';
import '../../core/services/storage_service.dart';

class LensConfigScreen extends StatefulWidget {
  const LensConfigScreen({super.key});

  @override
  State<LensConfigScreen> createState() => _LensConfigScreenState();
}

class _LensConfigScreenState extends State<LensConfigScreen> {
  List<LensSet> _sets = [];
  String? _activeId;
  bool _loading = true;
  bool _isEditing = false;
  final _lens1Controller = TextEditingController();
  final _lens2Controller = TextEditingController();
  final _lens3Controller = TextEditingController();
  String _customLabel = '';

  bool get _isZh =>
      context.read<LocaleProvider>().locale.languageCode == 'zh';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final storage = context.read<StorageService>();
    final sets = await storage.getLensSets();
    final activeId = await storage.getActiveLensSetId();
    if (mounted) {
      setState(() {
        _sets = sets;
        _activeId = activeId;
        _loading = false;
      });
    }
  }

  Future<void> _activate(LensSet set) async {
    final storage = context.read<StorageService>();
    await storage.setActiveLensSet(set.id);
    await _load();
  }

  void _showCustomForm() {
    _lens1Controller.clear();
    _lens2Controller.clear();
    _lens3Controller.clear();
    _customLabel = '';
    setState(() => _isEditing = true);
  }

  Future<void> _saveCustom() async {
    final l1 = _lens1Controller.text.trim();
    final l2 = _lens2Controller.text.trim();
    final l3 = _lens3Controller.text.trim();

    if (l1.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isZh ? '请输入第一镜。' : 'First lens is required.')),
      );
      return;
    }

    final storage = context.read<StorageService>();
    final id = 'lens_custom_${DateTime.now().millisecondsSinceEpoch}';
    final label = _customLabel.trim().isNotEmpty
        ? _customLabel.trim()
        : (_isZh ? '自定义' : 'Custom');

    final set = LensSet(
      id: id,
      label: label,
      lens1: l1,
      lens2: l2.isNotEmpty ? l2 : l1,
      lens3: l3.isNotEmpty ? l3 : l1,
      isBuiltin: false,
      sortOrder: 99,
      createdAt: DateTime.now(),
    );

    await storage.addLensSet(set);
    await storage.setActiveLensSet(id);
    await _load();
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isZh ? '你的三镜' : 'Your Three'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Active lens set preview
                if (_activeId != null) ...[
                  _buildActivePreview(theme),
                  const SizedBox(height: 16),
                ],

                // Built-in sets
                Text(
                  _isZh ? '内置镜片组' : 'Built-in Lens Sets',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ..._sets.where((s) => s.isBuiltin).map((s) => _buildLensTile(s)),

                const SizedBox(height: 20),

                // Custom sets
                if (_sets.any((s) => !s.isBuiltin)) ...[
                  Text(
                    _isZh ? '自定义镜片组' : 'Custom Lens Sets',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._sets.where((s) => !s.isBuiltin).map((s) => _buildLensTile(s)),
                  const SizedBox(height: 16),
                ],

                // Write your own
                if (!_isEditing)
                  ListTile(
                    leading: Icon(Icons.edit, color: theme.colorScheme.primary),
                    title: Text(
                      _isZh ? '写你自己' : 'Write your own',
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                    onTap: _showCustomForm,
                  ),

                // Custom form
                if (_isEditing)
                  _buildCustomForm(theme),
              ],
            ),
    );
  }

  Widget _buildActivePreview(ThemeData theme) {
    final active = _sets.where((s) => s.id == _activeId).firstOrNull;
    if (active == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.7)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(
                active.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...active.lenses.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${e.key + 1}. ${e.value}',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildLensTile(LensSet set) {
    final isActive = set.id == _activeId;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: isActive
            ? BorderSide(
                color: Theme.of(context).colorScheme.primary, width: 1.5)
            : BorderSide.none,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isActive
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.grey.shade100,
          child: Text(
            set.isBuiltin ? '⭐' : '✏️',
            style: const TextStyle(fontSize: 16),
          ),
        ),
        title: Text(
          set.label,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        subtitle: Text(
          set.lenses.take(2).join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        trailing: isActive
            ? Icon(Icons.check_circle,
                color: Theme.of(context).colorScheme.primary)
            : TextButton(
                onPressed: () => _activate(set),
                child: Text(_isZh ? '使用' : 'Use',
                    style: const TextStyle(fontSize: 13)),
              ),
      ),
    );
  }

  Widget _buildCustomForm(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(top: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isZh ? '创建自定义镜片组' : 'Create Custom Lens Set',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: _isZh ? '名称（可选）' : 'Name (optional)',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => _customLabel = v,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lens1Controller,
              maxLength: 80,
              decoration: InputDecoration(
                labelText: _isZh ? '第一镜' : 'First lens',
                hintText: _isZh ? '例如：今天我学到了什么？' : 'e.g. What did I learn today?',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _lens2Controller,
              maxLength: 80,
              decoration: InputDecoration(
                labelText: _isZh ? '第二镜' : 'Second lens',
                hintText: _isZh ? '例如：我善待了谁？' : 'e.g. Who did I show kindness to?',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _lens3Controller,
              maxLength: 80,
              decoration: InputDecoration(
                labelText: _isZh ? '第三镜' : 'Third lens',
                hintText: _isZh ? '例如：我忽略了什么？' : 'e.g. What did I overlook?',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _isEditing = false),
                    child: Text(_isZh ? '取消' : 'Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _saveCustom,
                    child: Text(_isZh ? '保存并激活' : 'Save & Activate'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _lens1Controller.dispose();
    _lens2Controller.dispose();
    _lens3Controller.dispose();
    super.dispose();
  }
}
