import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/ai_persona_provider.dart';
import '../../providers/llm_config_notifier.dart';
import '../../providers/tag_provider.dart';
import '../../providers/locale_provider.dart';
import '../legal_doc_screen.dart';
import '../../core/constants/legal_content.dart';
import '../../core/config/constants.dart';
import '../../providers/entry_provider.dart';
import '../../providers/routine_provider.dart';
import '../../models/tag.dart';
import '../../core/services/voice_notification_service.dart';
import '../../core/config/theme.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/export_service.dart';
import '../../core/services/entitlement_service.dart';
import '../../core/services/soft_prompt_service.dart';
import '../../core/services/file_service.dart';
import '../../models/reflection_style.dart';

import '../../models/lens_set.dart';
import '../purchase/paywall_screen.dart';

enum _BackupRange { all, lastMonth, last3Months, last6Months, custom }

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  // LLM Provider settings (persisted via SharedPreferences)
  // OpenRouter is first — lowest friction for new users (free trial key)
  final List<Map<String, String>> _llmProviders = [
    {
      'name': 'Open Router',
      'model': 'qwen/qwen3.5-flash-02-23',
      'apiKey': '',
      'baseUrl': 'https://openrouter.ai/api/v1',
    },
    {
      'name': 'OpenAI',
      'model': 'gpt-4o',
      'apiKey': '',
      'baseUrl': 'https://api.openai.com/v1',
    },
    {
      'name': 'Claude (Anthropic)',
      'model': 'claude-3.5-sonnet',
      'apiKey': '',
      'baseUrl': 'https://api.anthropic.com/v1',
    },
    {
      'name': 'Gemini (Google)',
      'model': 'gemini-pro',
      'apiKey': '',
      'baseUrl': 'https://generativelanguage.googleapis.com/v1',
    },
  ];

  int _selectedLlmIndex = 0;

  String _aiName = 'AI 助手';
  String _aiPersonality = '';

  Map<String, dynamic>? _customStyle;
  List<Map<String, dynamic>> _customStyles = [];
  bool _hasCustomStyle = false;
  bool _voiceLoaded = false;
  SharedPreferences? _prefs;
  final ValueNotifier<bool> _voiceNotifier = ValueNotifier<bool>(false);

  int _debugTapCount = 0;
  DateTime _lastDebugTap = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadLlmSettings();
    _loadAiSettings();
    _loadVoiceSetting();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _voiceNotifier.dispose();
    super.dispose();
  }

  void _debugToggleEntitlement() {
    final now = DateTime.now();
    if (now.difference(_lastDebugTap).inSeconds > 2) _debugTapCount = 0;
    _lastDebugTap = now;
    _debugTapCount++;
    if (_debugTapCount < 5) return;
    _debugTapCount = 0;
    _forceRestrictedForTesting();
  }

  Future<void> _forceRestrictedForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    final currentState = context.read<EntitlementService>().currentState;
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';

    if (currentState == EntitlementState.restricted) {
      // Reset to preview for testing
      await prefs.remove('entitlement_state');

      await prefs.remove('entitlement_preview_started');
      await prefs.remove('entitlement_preview_days');
      await prefs.remove('entitlement_jwt');
      await prefs.remove('entitlement_was_preview');
      final svc = context.read<EntitlementService>();
      await svc.init(prefs);
    } else {
      // Force restricted to test paywall
      await prefs.remove('entitlement_jwt');
      await prefs.setString('entitlement_state', 'restricted');
      await prefs.setBool('entitlement_was_preview', true);
      await prefs.setInt('entitlement_preview_days', 0);
      // Set preview_started to an old date so _applyLocalPreview skips
      await prefs.setString('entitlement_preview_started', '2020-01-01T00:00:00.000');
      final svc = context.read<EntitlementService>();
      await svc.init(prefs);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isZh ? 'Debug: 切换至 ${currentState == EntitlementState.restricted ? "预览" : "限制"} 模式' 
                 : 'Debug: Switched to ${currentState == EntitlementState.restricted ? "preview" : "restricted"} mode',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _loadAiSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      final customList = prefs.getStringList('ai_custom_styles') ?? [];
      final activeId = prefs.getString('ai_style_id') ?? 'kael';
      setState(() {
        _aiName = prefs.getString('ai_assistant_name') ?? 'AI 助手';
        _aiPersonality = prefs.getString('ai_assistant_personality') ?? '';
        _customStyles = customList
            .map((s) => jsonDecode(s) as Map<String, dynamic>)
            .toList();
        _hasCustomStyle = _customStyles.isNotEmpty;
      });
    }
  }

  Future<void> _saveAiSettings() async {
    await context
        .read<AiPersonaProvider>()
        .saveNameAndPersonality(_aiName, _aiPersonality);
    if (mounted) {
      final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isZh ? 'AI 设置已保存' : 'AI settings saved')),
      );
    }
  }

  Future<void> _pickAiAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;

    try {
      await context.read<AiPersonaProvider>().setAvatarFromPath(picked.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('头像保存失败: $e')),
        );
      }
    }
  }

  Future<void> _clearAiAvatar() async {
    await context.read<AiPersonaProvider>().clearAvatar();
  }

  Future<void> _loadLlmSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('llm_providers');
    if (jsonStr != null && mounted) {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      final saved = decoded
          .map((m) => (m as Map<String, dynamic>)
              .map((k, v) => MapEntry(k, v.toString())))
          .toList();

      // Merge: start from saved list (preserves user API keys), then append
      // any default providers whose name isn't already present.
      final savedNames = saved.map((p) => p['name']).toSet();
      final merged = [...saved];
      for (final def in _llmProviders) {
        if (!savedNames.contains(def['name'])) {
          merged.add(Map<String, String>.from(def));
        }
      }

      setState(() {
        _llmProviders
          ..clear()
          ..addAll(merged);
        final idx = prefs.getInt('llm_selected_index') ?? 0;
        _selectedLlmIndex = idx < _llmProviders.length ? idx : 0;
      });
    }
  }

  Future<void> _saveLlmSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('llm_providers', jsonEncode(_llmProviders));
    await prefs.setInt('llm_selected_index', _selectedLlmIndex);
    if (mounted) {
      context.read<LlmConfigNotifier>().notify();
    }
  }

  List<Map<String, String>> get _displayProviders => _llmProviders;


  Widget _buildAITab(bool isZh) {
    final entitlement = context.watch<EntitlementService>();

    if (entitlement.isRestricted) {
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.lock_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  isZh ? 'AI 功能需要 Pro' : 'AI features require Pro',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  isZh
                      ? '包含 AI 反思、年度回顾、自定义 AI 风格等功能。'
                      : 'Includes AI reflections, annual review, custom AI styles, and more.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PaywallScreen()),
                      );
                    },
                    child: Text(isZh ? '获取 Pro — \$19.99' : 'Get Pro — \$19.99'),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Active style preview
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Consumer<AiPersonaProvider>(
            builder: (context, persona, _) {
              final styleId = persona.styleId;
              final isCustom = styleId.startsWith('custom_') && _customStyles.isNotEmpty;
              final customIndex = isCustom ? int.tryParse(styleId.split('_').last) : null;
              final style = isCustom && customIndex != null && customIndex < _customStyles.length
                  ? ReflectionStyle.fromJson(_customStyles[customIndex], id: styleId)
                  : ReflectionStyle.byId(styleId);
              final color = _colorFromHex(style.colorHex);
              final avatarPath = isCustom && customIndex != null && customIndex < _customStyles.length
                  ? _customStyles[customIndex]['avatarPath'] as String?
                  : null;
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: const BoxDecoration(
                            color: Colors.white24, shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: avatarPath != null && avatarPath.isNotEmpty && File(avatarPath).existsSync()
                                ? Image.file(File(avatarPath), fit: BoxFit.cover)
                                : style.avatarAssetFor(isZh) != null
                                    ? Image.asset(style.avatarAssetFor(isZh)!, fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => Center(
                                            child: Text(style.emoji, style: const TextStyle(fontSize: 24))))
                                    : Center(
                                        child: Text(style.emoji, style: const TextStyle(fontSize: 24))),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(style.displayName(isZh),
                                  style: const TextStyle(
                                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                              Text(style.vibe(isZh),
                                  style: TextStyle(color: Colors.white70, fontSize: 13)),
                            ],
                          ),
                        ),
                        if (persona.hasCustomAvatar)
                          IconButton(
                            icon: const Icon(Icons.close, size: 18, color: Colors.white70),
                            onPressed: _clearAiAvatar,
                            tooltip: isZh ? '移除头像' : 'Remove avatar',
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...style.lenses(isZh).take(3).map((l) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(l, style: TextStyle(color: Colors.white70, fontSize: 12)),
                    )),
                  ],
                ),
              );
            },
          ),
        ),
        // Style selection
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            isZh ? '选择反思风格' : 'Choose reflection style',
            style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
        const SizedBox(height: 8),
        ...ReflectionStyle.presets.map((style) {
          final isActive = context.watch<AiPersonaProvider>().styleId == style.id;
          final color = _colorFromHex(style.colorHex);
          return Semantics(
          identifier: 'persona_${style.id}',
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isActive ? BorderSide(color: color, width: 1.5) : BorderSide.none,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _activateStyle(style),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12), shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(style.emoji, style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(style.displayName(isZh), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          Text(style.vibe(isZh), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        ],
                      ),
                    ),
                    if (isActive)
                      Icon(Icons.check_circle, color: color, size: 22),
                  ],
                ),
              ),
            ),
          ),
          );
        }),
        if (_hasCustomStyle) ...[
          const SizedBox(height: 4),
          ...List.generate(_customStyles.length, (i) {
            return _buildCustomStyleCard(context, isZh, i);
          }),
        ],
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showCustomStyleDialog(context, isZh),
              icon: const Icon(Icons.add, size: 18),
              label: Text(isZh ? '自定义风格' : 'Create Custom Style'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  void _activateStyle(ReflectionStyle style) async {
    final persona = context.read<AiPersonaProvider>();
    persona.setStyle(style);
    // Seed and activate style-specific lens set
    final storage = context.read<StorageService>();
    final lensId = 'lens_style_${style.id}';
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    final existing = await storage.getLensSets();
    if (!existing.any((s) => s.id == lensId)) {
      final lenses = style.lenses(isZh);
      await storage.addLensSet(LensSet(
        id: lensId,
        label: '${style.displayName(isZh)} — ${style.vibe(isZh)}',
        lens1: lenses[0],
        lens2: lenses[1],
        lens3: lenses[2],
        isBuiltin: false,
        sortOrder: 50,
        createdAt: DateTime.now(),
      ));
    }
    await storage.setActiveLensSet(lensId);
    if (mounted) setState(() {});
  }

  Widget _buildCustomStyleCard(BuildContext context, bool isZh, int index) {
    final styleId = context.watch<AiPersonaProvider>().styleId;
    final customId = 'custom_$index';
    final isActive = styleId == customId;
    final data = _customStyles[index];
    final name = data['name'] as String? ?? 'Custom';
    final emoji = data['emoji'] as String? ?? '✨';
    final avatarPath = data['avatarPath'] as String?;
    final color = _colorFromHex(_customStyle?['colorHex'] as String? ?? '#FF9500');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isActive ? BorderSide(color: color, width: 1.5) : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isActive ? null : () => _activateCustomStyle(index),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12), shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: avatarPath != null && File(avatarPath).existsSync()
                      ? Image.file(File(avatarPath), fit: BoxFit.cover)
                      : Center(
                          child: Text(emoji, style: const TextStyle(fontSize: 22)),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    Text(
                      _customStyle?['vibe'] as String? ?? (isZh ? '自定义风格' : 'Custom Style'),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (isActive)
                Icon(Icons.check_circle, color: color, size: 22),
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                onPressed: () => _showCustomStyleDialog(context, isZh, isEdit: true, editIndex: index),
                tooltip: isZh ? '编辑' : 'Edit',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                onPressed: () => _deleteCustomStyle(context, isZh, index),
                tooltip: isZh ? '删除' : 'Delete',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _activateCustomStyle(int index) async {
    if (index >= _customStyles.length) return;
    final style = ReflectionStyle.fromJson(_customStyles[index], id: 'custom_$index');
    await context.read<AiPersonaProvider>().setStyle(style);
    // Seed and activate custom lens set
    final storage = context.read<StorageService>();
    final lensId = 'lens_style_custom_$index';
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    final existing = await storage.getLensSets();
    if (!existing.any((s) => s.id == lensId)) {
      final lenses = style.lenses(isZh);
      await storage.addLensSet(LensSet(
        id: lensId,
        label: '${style.name} — ${style.vibe(isZh)}',
        lens1: lenses[0],
        lens2: lenses[1],
        lens3: lenses[2],
        isBuiltin: false,
        sortOrder: 60,
        createdAt: DateTime.now(),
      ));
    }
    await storage.setActiveLensSet(lensId);
    if (mounted) setState(() {});
  }

  void _deleteCustomStyle(BuildContext context, bool isZh, int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isZh ? '删除自定义风格？' : 'Delete custom style?'),
        content: Text(isZh
            ? '删除后将恢复为默认风格 Elara。'
            : 'This will revert to the default style Elara.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isZh ? '取消' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isZh ? '删除' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await context.read<AiPersonaProvider>().removeCustomStyle(index);
    if (mounted) {
      final prefs = await SharedPreferences.getInstance();
      final customList = prefs.getStringList('ai_custom_styles') ?? [];
      setState(() {
        _customStyles = customList
            .map((s) => jsonDecode(s) as Map<String, dynamic>)
            .toList();
        _hasCustomStyle = _customStyles.isNotEmpty;
      });
    }
  }

  void _showCustomStyleDialog(BuildContext context, bool isZh, {bool isEdit = false, int editIndex = 0}) {
    final style = (!isEdit || _customStyles.isEmpty || editIndex >= _customStyles.length) ? null : _customStyles[editIndex];
    final nameCtrl = TextEditingController(text: style?['name'] as String? ?? '');
    final emojiCtrl = TextEditingController(text: style?['emoji'] as String? ?? '✨');
    final vibeCtrl = TextEditingController(text: style?['vibe'] as String? ?? '');
    final personaCtrl = TextEditingController(text: style?['persona'] as String? ?? '');
    final lens1Ctrl = TextEditingController(text: style?['lens1'] as String? ?? '');
    final lens2Ctrl = TextEditingController(text: style?['lens2'] as String? ?? '');
    final lens3Ctrl = TextEditingController(text: style?['lens3'] as String? ?? '');
    String? pickedImagePath = style?['avatarPath'] as String?;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => _CustomStyleFormPage(
          isZh: isZh,
          nameCtrl: nameCtrl,
          emojiCtrl: emojiCtrl,
          vibeCtrl: vibeCtrl,
          personaCtrl: personaCtrl,
          lens1Ctrl: lens1Ctrl,
          lens2Ctrl: lens2Ctrl,
          lens3Ctrl: lens3Ctrl,
          pickedImagePath: pickedImagePath,
          onSave: (name, emoji, vibe, persona, l1, l2, l3, path) {
            _saveCustomStyle(name, emoji, vibe, persona, l1, l2, l3, isZh, imagePath: path, editIndex: isEdit ? editIndex : null);
          },
        ),
      ),
    );
  }

  void _saveCustomStyle(
    String name,
    String emoji,
    String vibe,
    String persona,
    String lens1,
    String lens2,
    String lens3,
    bool isZh, {
    String? imagePath,
    int? editIndex,
  }) async {
    // Save custom avatar image if picked
    String? savedAvatarPath;
    if (imagePath != null) {
      try {
        final relative = await FileService().saveFile(imagePath);
        savedAvatarPath = await FileService().getFullPath(relative);
      } catch (_) {}
    }

    final json = <String, dynamic>{
      'name': name,
      'emoji': emoji,
      'vibe': vibe,
      'colorHex': '#FF9500',
      'persona': persona,
      'lens1': lens1,
      'lens2': lens2,
      'lens3': lens3,
    };
    if (savedAvatarPath != null) json['avatarPath'] = savedAvatarPath;

    final provider = context.read<AiPersonaProvider>();
    if (editIndex != null) {
      await provider.updateCustomStyle(editIndex, json);
    } else {
      await provider.setCustomStyle(json);
    }
    // Seed and activate the custom persona's lens set
    final storage = context.read<StorageService>();
    final prefs = await SharedPreferences.getInstance();
    final customList = prefs.getStringList('ai_custom_styles') ?? [];
    final cIndex = editIndex ?? (customList.length - 1);
    final lensId = 'lens_style_custom_$cIndex';
    final existing = await storage.getLensSets();
    if (!existing.any((s) => s.id == lensId)) {
      await storage.addLensSet(LensSet(
        id: lensId,
        label: '$name — $vibe',
        lens1: lens1,
        lens2: lens2,
        lens3: lens3,
        isBuiltin: false,
        sortOrder: 60,
        createdAt: DateTime.now(),
      ));
    }
    await storage.setActiveLensSet(lensId);

    if (mounted) {
      final prefs = await SharedPreferences.getInstance();
      final customList = prefs.getStringList('ai_custom_styles') ?? [];
      setState(() {
        _customStyles = customList
            .map((s) => jsonDecode(s) as Map<String, dynamic>)
            .toList();
        _hasCustomStyle = _customStyles.isNotEmpty;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isZh ? '自定义风格已保存' : 'Custom style saved'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Color _colorFromHex(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

   Widget _buildTagsTab(bool isZh) {
    return Consumer<TagProvider>(
      builder: (context, tagProvider, _) {
        final entitlement = context.watch<EntitlementService>();
        final isRestricted = entitlement.isRestricted;
        return ListView(
          children: [
            ...tagProvider.tags.map(
              (tag) => _buildTagTile(context, tag, tagProvider, isZh),
            ),
            ListTile(
              leading: Icon(
                isRestricted ? Icons.lock : Icons.add,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                isRestricted
                    ? (isZh ? '升级至 Pro 以管理标签' : 'Upgrade to Pro to manage tags')
                    : (isZh ? '添加标签' : 'Add Tag'),
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
              onTap: () {
                if (isRestricted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PaywallScreen()),
                  );
                  return;
                }
                _showAddTagDialog(context, tagProvider, isZh);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildGeneralTab(bool isZh) {
    return ListView(
      children: [
        _buildSectionHeader(isZh ? '语言' : 'Language'),
        Consumer<LocaleProvider>(
          builder: (context, localeProvider, _) {
            return Semantics(
              identifier: 'btn_language_picker',
              child: ListTile(
                leading: const Icon(Icons.language),
                title: Text(isZh ? '语言' : 'Language'),
                subtitle: Text(isZh ? '中文' : 'English'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showLanguageDialog(context, localeProvider),
              ),
            );
          },
        ),
        const Divider(),
        _buildSectionHeader(isZh ? '通知' : 'Notifications'),
        _buildVoiceToggle(isZh),
        ValueListenableBuilder<bool>(
          valueListenable: _voiceNotifier,
          builder: (context, voiceEnabled, _) {
            if (!voiceEnabled) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(left: 72, right: 16, bottom: 4),
              child: Semantics(
                identifier: 'btn_test_voice',
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
            );
          },
        ),
        const Divider(),
        _buildSectionHeader(isZh ? '数据备份与迁移' : 'Data Portability'),
        MergeSemantics(
          child: Semantics(
          identifier: 'btn_full_backup',
          child: ListTile(
          leading: const Icon(Icons.archive_outlined),
          title: Text(isZh ? '完整备份 (ZIP)' : 'Full Backup (ZIP)'),
          subtitle: Text(isZh ? '包含所有数据和多媒体文件' : 'All data and media files'),
          onTap: () async {
            final entitlement = context.read<EntitlementService>();
            if (!entitlement.canBackup && entitlement.isRestricted) {
              if (await SoftPromptService.canShowReengage('backup')) {
              await SoftPromptService.showReengage(
                context,
                triggerKey: 'backup',
                title: isZh ? '备份功能需要 Pro' : 'Backup requires Pro',
                body: isZh
                    ? '跨设备备份与恢复是 Pro 功能。你的笔记仍然安全地保存在本地。'
                    : 'Backup & restore across devices is part of Pro. Your notes are still safe locally.',
              );
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen()));
              }
              return;
            }
            _handleBackup(context, isZh);
          },
        ))),
        ListTile(
          leading: const Icon(Icons.table_chart_outlined),
          title: Text(isZh ? '导出为 CSV' : 'Export to CSV'),
          subtitle: Text(isZh ? '适用于 Excel 统计' : 'Compatible with Excel'),
          onTap: () async {
            final entitlement = context.read<EntitlementService>();
            if (!entitlement.canExport && entitlement.isRestricted) {
              if (await SoftPromptService.canShowReengage('export_csv')) {
              await SoftPromptService.showReengage(
                context,
                triggerKey: 'export_csv',
                title: isZh ? '导出功能需要 Pro' : 'Export requires Pro',
                body: isZh
                    ? '数据导出是 Pro 功能。升级后可以导出 CSV 和 JSON。'
                    : 'Data export is part of Pro. Upgrade to export CSV and JSON.',
              );
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen()));
              }
              return;
            }
            _handleExportCsv(context, isZh);
          },
        ),
        ListTile(
          leading: const Icon(Icons.code),
          title: Text(isZh ? '导出为 JSON' : 'Export to JSON'),
          subtitle: Text(isZh ? '仅导出结构化数据' : 'Structured data only'),
          onTap: () async {
            final entitlement = context.read<EntitlementService>();
            if (!entitlement.canExport && entitlement.isRestricted) {
              if (await SoftPromptService.canShowReengage('export_json')) {
              await SoftPromptService.showReengage(
                context,
                triggerKey: 'export_json',
                title: isZh ? '导出功能需要 Pro' : 'Export requires Pro',
                body: isZh
                    ? '数据导出是 Pro 功能。升级后可以导出 JSON。'
                    : 'Data export is part of Pro. Upgrade to export JSON.',
              );
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen()));
              }
              return;
            }
            _handleExportJson(context, isZh);
          },
        ),
        ListTile(
          leading: const Icon(Icons.restore_outlined),
          title: Text(isZh ? '恢复数据' : 'Restore Data'),
          subtitle: Text(isZh ? '从备份文件导入' : 'Import from backup file'),
          onTap: () async {
            final entitlement = context.read<EntitlementService>();
            if (!entitlement.canBackup && entitlement.isRestricted) {
              if (await SoftPromptService.canShowReengage('restore')) {
              await SoftPromptService.showReengage(
                context,
                triggerKey: 'restore',
                title: isZh ? '恢复功能需要 Pro' : 'Restore requires Pro',
                body: isZh
                    ? '数据恢复是 Pro 功能。升级后可以恢复备份数据。'
                    : 'Data restore is part of Pro. Upgrade to restore from backup.',
              );
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen()));
              }
              return;
            }
            _handleRestore(context, isZh);
          },
        ),
        MergeSemantics(
          child: Semantics(
          identifier: 'btn_export_habits',
          child: ListTile(
          leading: const Icon(Icons.fitness_center_outlined),
          title: Text(isZh ? '导出习惯数据' : 'Export Habits'),
          subtitle: Text(isZh ? '导出所有习惯为 JSON 文件' : 'Export all habits as JSON'),
          onTap: () async {
            final entitlement = context.read<EntitlementService>();
            if (!entitlement.canExport && entitlement.isRestricted) {
              if (await SoftPromptService.canShowReengage('export_habits')) {
              await SoftPromptService.showReengage(
                context,
                triggerKey: 'export_habits',
                title: isZh ? '导出功能需要 Pro' : 'Export requires Pro',
                body: isZh
                    ? '习惯数据导出是 Pro 功能。'
                    : 'Habit export is part of Pro.',
              );
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen()));
              }
              return;
            }
            _handleExportHabits(context, isZh);
          },
        ))),
        ListTile(
          leading: const Icon(Icons.upload_outlined),
          title: Text(isZh ? '导入习惯数据' : 'Import Habits'),
          subtitle: Text(isZh ? '从 JSON 文件导入习惯' : 'Import habits from JSON file'),
          onTap: () async {
            final entitlement = context.read<EntitlementService>();
            if (!entitlement.canExport && entitlement.isRestricted) {
              if (await SoftPromptService.canShowReengage('import_habits')) {
              await SoftPromptService.showReengage(
                context,
                triggerKey: 'import_habits',
                title: isZh ? '导入功能需要 Pro' : 'Import requires Pro',
                body: isZh
                    ? '习惯数据导入是 Pro 功能。'
                    : 'Habit import is part of Pro.',
              );
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen()));
              }
              return;
            }
            _handleImportHabits(context, isZh);
          },
        ),
        const Divider(),
        _buildSectionHeader(isZh ? '关于' : 'About'),
        ListTile(
          leading: const Icon(Icons.feedback_outlined),
          title: Text(isZh ? '发送反馈' : 'Send Feedback'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _sendFeedback(context, isZh),
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: Text(isZh ? '隐私政策' : 'Privacy Policy'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LegalDocScreen(
                title: isZh ? '隐私政策' : 'Privacy Policy',
                content: isZh ? kPrivacyPolicyContentZh : kPrivacyPolicyContent,
              ),
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: Text(isZh ? '服务条款' : 'Terms of Service'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LegalDocScreen(
                title: isZh ? '服务条款' : 'Terms of Service',
                content: isZh ? kTermsOfServiceContentZh : kTermsOfServiceContent,
              ),
            ),
          ),
        ),
        MergeSemantics(
          child: Semantics(
            identifier: 'btn_debug_toggle',
            child: ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Blinking (记忆闪烁)'),
              subtitle: Text(isZh ? '版本 ${AppConstants.appVersion}' : 'Version ${AppConstants.appVersion}'),
              onTap: () => _debugToggleEntitlement(),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Future<void> _loadVoiceSetting() async {
    _prefs = await SharedPreferences.getInstance();
    if (mounted) {
      _voiceNotifier.value = _prefs?.getBool('voice_notifications_enabled') ?? false;
      setState(() => _voiceLoaded = true);
    }
  }

  Widget _buildVoiceToggle(bool isZh) {
    return ValueListenableBuilder<bool>(
      valueListenable: _voiceNotifier,
      builder: (context, voiceEnabled, _) {
        return GestureDetector(
          excludeFromSemantics: true,
          onTap: () {
            final newValue = !voiceEnabled;
            _voiceNotifier.value = newValue;
            _prefs?.setBool('voice_notifications_enabled', newValue);
            if (newValue) {
              VoiceNotificationService.init();
            } else {
              VoiceNotificationService.stop();
            }
          },
          child: Semantics(
            identifier: 'toggle_voice_reminders',
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.volume_up_outlined),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isZh ? '语音提醒' : 'Voice Reminders'),
                        Text(
                          isZh ? '提醒时如果应用打开，会朗读习惯名称'
                              : 'Speak routine names at reminder time when app is open',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: voiceEnabled,
                    onChanged: (value) async {
                      _voiceNotifier.value = value;
                      await _prefs?.setBool('voice_notifications_enabled', value);
                      if (value) {
                        await VoiceNotificationService.init();
                      } else {
                        await VoiceNotificationService.stop();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEntitlementBanner(bool isZh) {
    final entitlement = context.watch<EntitlementService>();
    final state = entitlement.currentState;

    // PREVIEW — full access trial active
    if (state == EntitlementState.preview) {
      final daysLeft = entitlement.previewDaysRemaining;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade400, Colors.purple.shade400],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('✨', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isZh
                          ? '21 天全功能预览 — 剩余 $daysLeft 天'
                          : '21-Day Preview — $daysLeft ${daysLeft == 1 ? 'day' : 'days'} left',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                isZh
                    ? '试用期间享全部功能。'
                    : 'Enjoy all features during your trial.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Text(
                isZh
                    ? '预览结束后，核心功能永久免费。购买 Pro 解锁全部功能。'
                    : 'After preview, core features remain free forever. Buy Pro to unlock everything.',
                style: TextStyle(color: Colors.white60, fontSize: 11),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PaywallScreen()),
                    );
                  },
                  icon: const Icon(Icons.workspace_premium, size: 16),
                  label: Text(
                    isZh ? '获取 Blinking Pro — \$19.99' : 'Get Blinking Pro — \$19.99',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white24,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // PAID — user has purchased Pro
    if (state == EntitlementState.paid) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade500, Colors.teal.shade400],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('💎', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isZh ? 'Pro — 全部功能解锁' : 'Pro — All features unlocked',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isZh
                          ? '全部功能永久解锁'
                          : 'All features unlocked forever',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // RESTRICTED — after preview, no purchase
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          border: Border.all(color: Colors.orange.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('⚡', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isZh ? '升级至 Pro' : 'Upgrade to Pro',
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              isZh
                  ? '✅ 记录笔记、查看历史、打卡已有习惯 — 永久免费'
                  : '✅ Notes, history, check-in existing habits — free forever',
              style: TextStyle(color: Colors.orange.shade600, fontSize: 11),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PaywallScreen()),
                  );
                },
                icon: const Icon(Icons.workspace_premium, size: 18),
                label: Text(
                  isZh
                      ? '获取 Blinking Pro — \$19.99 一次购买，终身使用'
                      : 'Get Blinking Pro — \$19.99 once, lifetime access',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    final isZh = locale.languageCode == 'zh';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isZh ? '设置' : 'Settings',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Entitlement banner — always visible
          _buildEntitlementBanner(isZh),
          // Tab bar
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(child: Semantics(identifier: 'settings_tab_ai', child: Text(isZh ? 'AI 个性化' : 'AI Personalization'))),
              Tab(child: Semantics(identifier: 'settings_tab_tags', child: Text(isZh ? '标签管理' : 'Tags'))),
              Tab(child: Semantics(identifier: 'settings_tab_general', child: Text(isZh ? '通用' : 'General'))),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAITab(isZh),
                _buildTagsTab(isZh),
                _buildGeneralTab(isZh),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  // ============ TAG MANAGEMENT ============

  static const _systemTagIds = {'tag_synthesis', 'tag_private', 'tag_welcome'};
  // Tags hidden from the add-entry tag picker
  static const _hiddenTagIds = {'tag_synthesis', 'tag_welcome'};

  Widget _buildTagTile(
    BuildContext context, Tag tag, TagProvider provider, bool isZh,
  ) {
    final isSystem = _systemTagIds.contains(tag.id);
    final entitlement = context.watch<EntitlementService>();
    final isRestricted = entitlement.isRestricted;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.hexColor(tag.color),
        radius: 12,
      ),
      title: Text(tag.displayName(isZh)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isSystem && !isRestricted)
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _showEditTagDialog(context, tag, provider, isZh),
            ),
          if (!isSystem && !isRestricted)
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: () => _confirmDeleteTag(context, tag, provider, isZh),
            ),
          if (isSystem)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.lock_outline, size: 16, color: Colors.grey[400]),
            ),
        ],
      ),
    );
  }

  void _showAddTagDialog(
    BuildContext context, TagProvider provider, bool isZh,
  ) {
    final nameController = TextEditingController();
    String selectedColor = '#007AFF';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isZh ? '添加标签' : 'Add Tag'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: isZh ? '标签名称' : 'Tag Name',
                  hintText: isZh ? '例如：工作、学习' : 'e.g. Work, Study',
                ),
              ),
              const SizedBox(height: 16),
              Text(isZh ? '选择颜色' : 'Pick Color'),
              const SizedBox(height: 8),
              _buildColorPicker(selectedColor, (color) {
                setState(() => selectedColor = color);
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(isZh ? '取消' : 'Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  provider.addTag(
                    name: nameController.text,
                    nameEn: nameController.text,
                    color: selectedColor,
                  );
                  Navigator.pop(context);
                }
              },
              child: Text(isZh ? '添加' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTagDialog(
    BuildContext context, Tag tag, TagProvider provider, bool isZh,
  ) {
    final nameController = TextEditingController(text: tag.name);
    String selectedColor = tag.color;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isZh ? '编辑标签' : 'Edit Tag'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: isZh ? '标签名称' : 'Tag Name',
                ),
              ),
              const SizedBox(height: 16),
              _buildColorPicker(selectedColor, (color) {
                setState(() => selectedColor = color);
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(isZh ? '取消' : 'Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  provider.updateTag(tag.copyWith(
                    name: nameController.text,
                    color: selectedColor,
                  ));
                  Navigator.pop(context);
                }
              },
              child: Text(isZh ? '保存' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteTag(
    BuildContext context, Tag tag, TagProvider provider, bool isZh,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isZh ? '删除标签' : 'Delete Tag'),
        content: Text(
          isZh ? '确定要删除 "${tag.name}" 吗？' : 'Delete "${tag.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isZh ? '取消' : 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteTag(tag.id);
              Navigator.pop(context);
            },
            child: Text(
              isZh ? '删除' : 'Delete',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPicker(String selectedColor, Function(String) onSelect) {
    return Wrap(
      spacing: 8,
      children: [
        '#007AFF', '#34C759', '#FF9500', '#FF3B30',
        '#AF52DE', '#5856D6', '#FF2D55', '#00C7BE',
      ].map((color) => GestureDetector(
        onTap: () => onSelect(color),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.hexColor(color),
            shape: BoxShape.circle,
            border: selectedColor == color
                ? Border.all(color: Colors.black, width: 2)
                : null,
          ),
        ),
      )).toList(),
    );
  }

  // ============ LANGUAGE ============

  void _onLocaleChanged(BuildContext context, bool isZh) {
    // Reload persona with new locale
    try { context.read<AiPersonaProvider>().reload(); } catch (_) {}
    // Re-seed lens sets with new locale
    try { context.read<StorageService>().reSeedLensesForLocale(isZh); } catch (_) {}
  }

  void _showLanguageDialog(BuildContext context, LocaleProvider localeProvider) {
    final isZh = localeProvider.locale.languageCode == 'zh';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isZh ? '选择语言' : 'Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('中文'),
              trailing: isZh
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                localeProvider.setLocale(const Locale('zh'));
                _onLocaleChanged(context, true);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('English'),
              trailing: !isZh
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                localeProvider.setLocale(const Locale('en'));
                _onLocaleChanged(context, false);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ============ LLM PROVIDER MANAGEMENT ============

  void _showEditLlmDialog(BuildContext context, int index, bool isZh) {
    final provider = _llmProviders[index];
    final nameController = TextEditingController(text: provider['name']);
    final modelController = TextEditingController(text: provider['model']);
    final apiKeyController = TextEditingController(text: provider['apiKey']);
    final baseUrlController = TextEditingController(text: provider['baseUrl']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isZh ? '编辑 AI 服务' : 'Edit AI Provider'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: isZh ? '服务名称' : 'Provider Name',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: modelController,
                decoration: InputDecoration(
                  labelText: isZh ? '模型名称' : 'Model Name',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: apiKeyController,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  hintText: 'sk-...',
                ),
                obscureText: true,
              ),
              if ((provider['baseUrl'] ?? '').contains('openrouter'))
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: GestureDetector(
                    onTap: () => launchUrl(
                      Uri.parse('https://openrouter.ai/keys'),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: Text(
                      isZh ? '🔑 免费获取 API Key →' : '🔑 Get a free API key →',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: baseUrlController,
                decoration: const InputDecoration(
                  labelText: 'Base URL',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isZh ? '取消' : 'Cancel'),
          ),
          if (_llmProviders.length > 1)
            TextButton(
              onPressed: () {
                setState(() {
                  _llmProviders.removeAt(index);
                  if (_selectedLlmIndex >= _llmProviders.length) {
                    _selectedLlmIndex = _llmProviders.length - 1;
                  }
                });
                _saveLlmSettings();
                Navigator.pop(context);
              },
              child: Text(
                isZh ? '删除' : 'Delete',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          TextButton(
            onPressed: () {
              setState(() {
                _llmProviders[index] = {
                  'name': nameController.text,
                  'model': modelController.text,
                  'apiKey': apiKeyController.text,
                  'baseUrl': baseUrlController.text,
                };
              });
              _saveLlmSettings();
              Navigator.pop(context);
            },
            child: Text(isZh ? '保存' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _showAddLlmDialog(BuildContext context, bool isZh) {
    final nameController = TextEditingController();
    final modelController = TextEditingController();
    final apiKeyController = TextEditingController();
    final baseUrlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isZh ? '添加 AI 服务' : 'Add AI Provider'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: isZh ? '服务名称' : 'Provider Name',
                  hintText: isZh ? '例如：DeepSeek' : 'e.g. DeepSeek',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: modelController,
                decoration: InputDecoration(
                  labelText: isZh ? '模型名称' : 'Model Name',
                  hintText: 'e.g. deepseek-chat',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: apiKeyController,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  hintText: 'sk-...',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: baseUrlController,
                decoration: const InputDecoration(
                  labelText: 'Base URL',
                  hintText: 'https://api.example.com/v1',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isZh ? '取消' : 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                setState(() {
                  _llmProviders.add({
                    'name': nameController.text,
                    'model': modelController.text,
                    'apiKey': apiKeyController.text,
                    'baseUrl': baseUrlController.text,
                  });
                });
                _saveLlmSettings();
                Navigator.pop(context);
              }
            },
            child: Text(isZh ? '添加' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _showTrialInfoDialog(BuildContext context, bool isZh) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isZh ? '试用详情' : 'Trial Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isZh ? '模型：qwen/qwen3.5-flash' : 'Model: qwen/qwen3.5-flash'),
            const SizedBox(height: 8),
            Text(isZh ? '由 Blinking 试用后端代理' : 'Proxied by Blinking trial backend'),
            const SizedBox(height: 8),
            Text(
              isZh ? '每天最多 20 次请求，共 7 天试用期。' : 'Up to 20 requests/day for 7 days.',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Text(
              isZh ? '试用服务商不可编辑。' : 'Trial provider cannot be edited.',
              style: TextStyle(color: Colors.red[400], fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isZh ? '关闭' : 'Close'),
          ),
        ],
      ),
    );
  }

  // ============ DATA PORTABILITY ============

  String _rangeLabel(_BackupRange r, bool isZh) {
    switch (r) {
      case _BackupRange.all:
        return isZh ? '全部数据' : 'All data';
      case _BackupRange.lastMonth:
        return isZh ? '最近1个月' : 'Last month';
      case _BackupRange.last3Months:
        return isZh ? '最近3个月' : 'Last 3 months';
      case _BackupRange.last6Months:
        return isZh ? '最近6个月' : 'Last 6 months';
      case _BackupRange.custom:
        return isZh ? '自定义' : 'Custom';
    }
  }

  Future<void> _handleBackup(BuildContext context, bool isZh) async {
    var phase = 0;
    var range = _BackupRange.all;
    var includeMedia = false;
    DateTime? customFrom;
    DateTime? customTo;
    var progress = 0.0;
    var estimateText = '';
    final estimator = _BackupEstimator();

    (DateTime?, DateTime?) resolveRange() {
      final now = DateTime.now();
      switch (range) {
        case _BackupRange.lastMonth:
          return (now.subtract(const Duration(days: 30)), null);
        case _BackupRange.last3Months:
          return (now.subtract(const Duration(days: 90)), null);
        case _BackupRange.last6Months:
          return (now.subtract(const Duration(days: 180)), null);
        case _BackupRange.custom:
          return (customFrom, customTo);
        case _BackupRange.all:
          return (null, null);
      }
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) {
          if (phase == 0) {
            return AlertDialog(
              title: Text(isZh ? '选择备份范围' : 'Select Backup Range'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final r in _BackupRange.values)
                          if (r != _BackupRange.custom)
                            ChoiceChip(
                              label: Text(_rangeLabel(r, isZh)),
                              selected: range == r,
                              onSelected: (_) =>
                                  setDialogState(() => range = r),
                            ),
                        ChoiceChip(
                          label: Text(isZh ? '自定义' : 'Custom'),
                          selected: range == _BackupRange.custom,
                          onSelected: (_) => setDialogState(
                              () => range = _BackupRange.custom),
                        ),
                      ],
                    ),
                    if (range == _BackupRange.custom) ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextButton.icon(
                              icon: const Icon(Icons.calendar_today, size: 16),
                              label: Text(customFrom != null
                                  ? '${customFrom!.year}-${customFrom!.month.toString().padLeft(2, '0')}-${customFrom!.day.toString().padLeft(2, '0')}'
                                  : (isZh ? '开始日期' : 'From')),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: customFrom ??
                                      DateTime.now()
                                          .subtract(const Duration(days: 30)),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setDialogState(() => customFrom = picked);
                                }
                              },
                            ),
                          ),
                          const Text('→'),
                          Expanded(
                            child: TextButton.icon(
                              icon: const Icon(Icons.calendar_today, size: 16),
                              label: Text(customTo != null
                                  ? '${customTo!.year}-${customTo!.month.toString().padLeft(2, '0')}-${customTo!.day.toString().padLeft(2, '0')}'
                                  : (isZh ? '结束日期' : 'To')),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: customTo ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setDialogState(() => customTo = picked);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                    const Divider(height: 24),
                    SwitchListTile(
                      title: Text(isZh ? '包含图片' : 'Include photos'),
                      subtitle: Text(isZh
                          ? '文件较大, 关闭后仅导出文本数据 (~200 KB)'
                          : 'Large files — off for text-only backup (~200 KB)'),
                      value: includeMedia,
                      onChanged: (v) => setDialogState(() => includeMedia = v),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(isZh ? '取消' : 'Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    setDialogState(() => phase = 1);
                    // Wait for the frame to render before blocking the thread
                    await Future(() {});
                    await Future(() {});
                    await Future(() {});
                    final exportService = context.read<ExportService>();
                    try {
                      final (startDate, endDate) = resolveRange();
                      final path = await exportService.exportAll(
                        startDate: startDate,
                        endDate: endDate,
                        excludeMedia: !includeMedia,
                        onProgress: (p) {
                          if (dialogContext.mounted) {
                            setDialogState(() {
                              progress = p;
                              estimateText = estimator.estimate(p, isZh);
                            });
                          }
                        },
                      );
                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                      await exportService.shareFile(
                        path,
                        subject:
                            isZh ? 'Blinking 全量备份' : 'Blinking Full Backup',
                        text: isZh
                            ? '这是我的 Blinking App 备份文件。'
                            : 'This is my Blinking App backup file.',
                      );
                      // Delete the ZIP after sharing — no reason to keep a copy on device
                      try { await File(path).delete(); } catch (_) {}
                    } catch (e) {
                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                      if (context.mounted) _showError(context, isZh, e.toString());
                    }
                  },
                  child: Text(isZh ? '开始备份' : 'Start Backup'),
                ),
              ],
            );
          }

          // Phase 2: progress
          return PopScope(
            canPop: false,
            child: AlertDialog(
              title: Text(isZh ? '正在备份...' : 'Backing up...'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isZh ? '正在压缩和保存数据文件。' : 'Compressing and saving data files.',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: 16, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        isZh ? '请勿关闭应用' : 'Do not close the app',
                        style: const TextStyle(color: Colors.orange),
                      ),
                    ],
                  ),
                  ],
                ),
              ),
            );
          },
      ),
    );
  }

  Future<void> _handleExportCsv(BuildContext context, bool isZh) async {
    try {
      final exportService = context.read<ExportService>();
      final path = await exportService.exportCsv();
      await exportService.shareFile(
        path,
        subject: isZh ? 'Blinking 习惯与条目导出 (CSV)' : 'Blinking Habit & Entries Export (CSV)',
      );
    } catch (e) {
      _showError(context, isZh, e.toString());
    }
  }

  Future<void> _handleExportJson(BuildContext context, bool isZh) async {
    try {
      final exportService = context.read<ExportService>();
      final path = await exportService.exportJsonFile();
      await exportService.shareFile(
        path,
        subject: isZh ? 'Blinking 数据导出 (JSON)' : 'Blinking Data Export (JSON)',
      );
    } catch (e) {
      _showError(context, isZh, e.toString());
    }
  }

  Future<void> _handleRestore(BuildContext context, bool isZh) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip', 'json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);

      if (!mounted) return;

      var phase = 0;
      double progress = 0.0;
      String estimateText = '';
      final estimator = _BackupEstimator();

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
          builder: (_, setDialogState) {
            if (phase == 0) {
              return AlertDialog(
                title: Text(isZh ? '恢复数据' : 'Restore Data'),
                content: Text(isZh
                    ? '从此备份恢复数据将替换您当前的所有数据。'
                    : 'Restore data from this backup? This will replace all your current data.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(isZh ? '取消' : 'Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      setDialogState(() => phase = 1);
                      await _performRestore(
                        context,
                        dialogContext,
                        file,
                        isZh,
                        (p) {
                          if (dialogContext.mounted) {
                            setDialogState(() {
                              progress = p;
                              estimateText = estimator.estimate(p, isZh);
                            });
                          }
                        },
                      );
                    },
                    child: Text(isZh ? '恢复' : 'Restore'),
                  ),
                ],
              );
            }

            // Phase 1: progress
            return PopScope(
              canPop: false,
              child: AlertDialog(
                title: Text(isZh ? '正在恢复...' : 'Restoring...'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(
                        value: progress > 0 ? progress : null),
                    const SizedBox(height: 12),
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    if (estimateText.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(estimateText,
                          style: const TextStyle(color: Colors.grey)),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            size: 16, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          isZh ? '请勿关闭应用' : 'Do not close the app',
                          style: const TextStyle(color: Colors.orange),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
      }
    } catch (e) {
      if (mounted) _showError(context, isZh, e.toString());
    }
  }

  Future<void> _performRestore(
    BuildContext context,
    BuildContext dialogContext,
    File file,
    bool isZh,
    void Function(double)? onProgress,
  ) async {
    try {
      final storage = context.read<StorageService>();
      await storage.restoreFromBackup(file, onProgress: onProgress);

      if (!context.mounted) return;
      context.read<EntryProvider>().loadEntries();
      context.read<RoutineProvider>().loadRoutines();
      context.read<TagProvider>().loadTags();
      await context.read<AiPersonaProvider>().reload();

      if (!dialogContext.mounted) return;
      Navigator.pop(dialogContext);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isZh ? '数据恢复成功！' : 'Data restored successfully!')),
      );
    } catch (e) {
      if (dialogContext.mounted) Navigator.pop(dialogContext);
      if (context.mounted) _showError(context, isZh, e.toString());
    }
  }

  Future<void> _handleExportHabits(BuildContext context, bool isZh) async {
    try {
      final provider = context.read<RoutineProvider>();
      final json = provider.exportRoutinesJson();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/habits_export.json');
      await file.writeAsString(json);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: isZh ? '习惯数据导出' : 'Habits Export',
          sharePositionOrigin: const Rect.fromLTWH(0, 0, 1, 1),
        ),
      );
    } catch (e) {
      if (mounted) _showError(context, isZh, e.toString());
    }
  }

  Future<void> _handleImportHabits(BuildContext context, bool isZh) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final json = await file.readAsString();

      if (!mounted) return;
      final provider = context.read<RoutineProvider>();
      final counts = await provider.importRoutinesJson(json);

      if (mounted) {
        final msg = isZh
            ? '导入完成：${counts.imported} 条已导入，${counts.skipped} 条已跳过'
            : 'Import complete: ${counts.imported} imported, ${counts.skipped} skipped';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) _showError(context, isZh, e.toString());
    }
  }

  Future<void> _sendFeedback(BuildContext context, bool isZh) async {
    const email = 'blinkingfeedback@gmail.com';
    const version = AppConstants.appVersion;
    final subject = Uri.encodeComponent('Blinking App Feedback - v$version');
    final body = Uri.encodeComponent(
      'What happened:\n\n\nSteps to reproduce:\n\n\nExpected behavior:\n\n\nDevice & OS:\n\n',
    );
    final uri = Uri.parse('mailto:$email?subject=$subject&body=$body');

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        _showMailFallback(context, isZh, email);
      }
    } catch (_) {
      if (context.mounted) _showMailFallback(context, isZh, email);
    }
  }

  void _showMailFallback(BuildContext context, bool isZh, String email) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isZh
              ? '无法打开邮件应用，请发送邮件至 $email'
              : 'No mail app found. Please email $email',
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showError(BuildContext context, bool isZh, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isZh ? '操作失败: $error' : 'Operation failed: $error'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

class _BackupEstimator {
  final _start = DateTime.now();
  final _samples = <({double progress, int elapsed})>[];

  String estimate(double progress, bool isZh) {
    final elapsedMs = DateTime.now().difference(_start).inMilliseconds;
    _samples.add((progress: progress, elapsed: elapsedMs));
    if (_samples.length > 5) _samples.removeAt(0);

    if (progress < 0.15 || _samples.length < 2) return '';

    final oldest = _samples.first;
    final newest = _samples.last;
    final progressDelta = newest.progress - oldest.progress;
    final timeDelta = newest.elapsed - oldest.elapsed;
    if (progressDelta <= 0 || timeDelta <= 0) return '';

    final msPerProgress = timeDelta / progressDelta;
    final remainingMs = msPerProgress * (1.0 - progress);
    final remainingSec = (remainingMs / 1000).round();

    if (remainingSec < 10) {
      return isZh ? '不到10秒' : 'Less than 10 seconds';
    } else if (remainingSec < 60) {
      final rounded = ((remainingSec / 10).round() * 10).clamp(10, 50);
      return isZh ? '约$rounded秒' : 'About $rounded seconds';
    } else {
      final mins = (remainingSec / 60).ceil();
      return isZh ? '约$mins分钟' : 'About $mins minute${mins > 1 ? 's' : ''}';
    }
  }
}

// ─── Custom Style Form Page ──────────────────────────────────────

class _CustomStyleFormPage extends StatefulWidget {
  final bool isZh;
  final TextEditingController nameCtrl;
  final TextEditingController emojiCtrl;
  final TextEditingController vibeCtrl;
  final TextEditingController personaCtrl;
  final TextEditingController lens1Ctrl;
  final TextEditingController lens2Ctrl;
  final TextEditingController lens3Ctrl;
  final String? pickedImagePath;
  final void Function(String name, String emoji, String vibe, String persona,
      String l1, String l2, String l3, String? path) onSave;

  const _CustomStyleFormPage({
    required this.isZh,
    required this.nameCtrl,
    required this.emojiCtrl,
    required this.vibeCtrl,
    required this.personaCtrl,
    required this.lens1Ctrl,
    required this.lens2Ctrl,
    required this.lens3Ctrl,
    required this.pickedImagePath,
    required this.onSave,
  });

  @override
  State<_CustomStyleFormPage> createState() => _CustomStyleFormPageState();
}

class _CustomStyleFormPageState extends State<_CustomStyleFormPage> {
  final _emojiOptions = const [
    '✨', '🌟', '💫', '⭐', '🔥', '💡', '🎯', '🧠',
    '💪', '🌱', '🌸', '🌿', '🍀', '🌙', '☀️', '🌈',
    '🦋', '🐣', '🕊️', '🐚', '💎', '🎨', '🎵', '📚',
    '✏️', '📝', '🗂️', '🔑', '💭', '🗣️', '🎭', '🪞',
  ];

  late String? _pickedImagePath = widget.pickedImagePath;

  @override
  Widget build(BuildContext context) {
    final isZh = widget.isZh;
    final currentEmoji = widget.emojiCtrl.text.isEmpty ? '✨' : widget.emojiCtrl.text;

    return Scaffold(
      appBar: AppBar(
        title: Text(isZh ? '自定义风格' : 'Custom Style'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isZh ? '取消' : 'Cancel'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MergeSemantics(
              child: Semantics(
              identifier: 'input_custom_style_name',
              textField: true,
              child: TextField(
                controller: widget.nameCtrl,
                decoration: InputDecoration(
                  labelText: isZh ? '名称 *' : 'Name *',
                  border: const OutlineInputBorder(),
                  hintText: isZh ? '给你的风格起个名字' : 'Name your style',
                ),
              ),
            )),
            const SizedBox(height: 16),
            TextField(
              controller: widget.vibeCtrl,
              decoration: InputDecoration(
                labelText: isZh ? '风格标签' : 'Style (vibe)',
                border: const OutlineInputBorder(),
                hintText: isZh ? '例如：沉稳冥想' : 'e.g. Slow & Meditative',
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isZh ? '选择头像' : 'Choose Avatar',
              style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 256,
                    maxHeight: 256,
                    imageQuality: 85,
                  );
                  if (picked != null) {
                    setState(() {
                      _pickedImagePath = picked.path;
                      widget.emojiCtrl.clear();
                    });
                  }
                },
                icon: const Icon(Icons.image, size: 18),
                label: Text(isZh ? '上传图片' : 'Upload Image'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            if (_pickedImagePath != null) ...[
              const SizedBox(height: 8),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    ClipOval(
                      child: _pickedImagePath!.isNotEmpty
                          ? Image.file(
                              File(_pickedImagePath!),
                              width: 56, height: 56, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 56, height: 56,
                                color: Colors.grey[200],
                                child: const Icon(Icons.broken_image, size: 24, color: Colors.grey),
                              ),
                            )
                          : const SizedBox(width: 56, height: 56),
                    ),
                    TextButton(
                      onPressed: () {
                      setState(() {
                        _pickedImagePath = null;
                        widget.emojiCtrl.text = '✨';
                      });
                    },
                    child: Text(isZh ? '清除' : 'Clear', style: const TextStyle(fontSize: 13)),
                  ),
                ],
              ),
              ),
              const SizedBox(height: 8),
            ],
            Container(
              padding: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Column(
                children: [
                  if (_pickedImagePath == null)
                    Center(
                      child: Container(
                        width: 56, height: 56,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(currentEmoji, style: const TextStyle(fontSize: 28)),
                        ),
                      ),
                    ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _emojiOptions.map((emoji) {
                      final selected = currentEmoji == emoji;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _pickedImagePath = null;
                            widget.emojiCtrl.text = emoji;
                          });
                        },
                        child: Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.orange.withValues(alpha: 0.15)
                                : Colors.grey[100],
                            shape: BoxShape.circle,
                            border: selected
                                ? Border.all(color: Colors.orange, width: 2)
                                : null,
                          ),
                          child: Center(
                            child: Text(emoji, style: const TextStyle(fontSize: 22)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: widget.personaCtrl,
              maxLines: 3,
              maxLength: 150,
              decoration: InputDecoration(
                labelText: isZh ? '人格描述 (最多 150 字)' : 'Personality (max 150 chars)',
                border: const OutlineInputBorder(),
                hintText: isZh
                    ? '描述 AI 助手应该如何说话...'
                    : 'Describe how the AI should speak...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isZh ? '反思镜头 (3 个问题)' : 'Reflection Lenses (3 questions)',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            MergeSemantics(child: Semantics(
              identifier: 'input_custom_style_lens1',
              textField: true,
              child: TextField(
                controller: widget.lens1Ctrl,
                decoration: InputDecoration(
                  labelText: isZh ? '镜头 1 *' : 'Lens 1 *',
                  border: const OutlineInputBorder(),
                ),
              ),
            )),
            const SizedBox(height: 10),
            MergeSemantics(child: Semantics(
              identifier: 'input_custom_style_lens2',
              textField: true,
              child: TextField(
                controller: widget.lens2Ctrl,
                decoration: InputDecoration(
                  labelText: isZh ? '镜头 2 *' : 'Lens 2 *',
                  border: const OutlineInputBorder(),
                ),
              ),
            )),
            const SizedBox(height: 10),
            MergeSemantics(child: Semantics(
              identifier: 'input_custom_style_lens3',
              textField: true,
              child: TextField(
                controller: widget.lens3Ctrl,
                decoration: InputDecoration(
                  labelText: isZh ? '镜头 3 *' : 'Lens 3 *',
                  border: const OutlineInputBorder(),
                ),
              ),
            )),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: MergeSemantics(child: Semantics(
              identifier: 'btn_custom_style_save',
              child: FilledButton(
                onPressed: () {
                  final name = widget.nameCtrl.text.trim();
                  final emoji = widget.emojiCtrl.text.trim().isEmpty
                      ? '✨'
                      : widget.emojiCtrl.text.trim();
                  final vibe = widget.vibeCtrl.text.trim();
                  final persona = widget.personaCtrl.text.trim();
                  final l1 = widget.lens1Ctrl.text.trim();
                  final l2 = widget.lens2Ctrl.text.trim();
                  final l3 = widget.lens3Ctrl.text.trim();

                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isZh ? '请输入名称' : 'Name is required')),
                    );
                    return;
                  }
                  if (l1.isEmpty || l2.isEmpty || l3.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isZh ? '请填写所有 3 个镜头问题' : 'All 3 lenses are required')),
                    );
                    return;
                  }

                  Navigator.pop(context);
                  widget.onSave(name, emoji, vibe, persona, l1, l2, l3, _pickedImagePath);
                },
                child: Text(isZh ? '保存' : 'Save'),
              ))),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
