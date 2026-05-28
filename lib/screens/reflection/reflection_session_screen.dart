import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/entry_provider.dart';
import '../../providers/routine_provider.dart';
import '../../providers/ai_persona_provider.dart';
import '../../providers/locale_provider.dart';
import '../../models/entry.dart';
import '../../models/lens_set.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/llm_service.dart';
import '../../core/services/prompt_assembler.dart';

class ReflectionSessionScreen extends StatefulWidget {
  const ReflectionSessionScreen({super.key});

  @override
  State<ReflectionSessionScreen> createState() =>
      _ReflectionSessionScreenState();
}

class _ReflectionSessionScreenState extends State<ReflectionSessionScreen> {
  final LlmService _llm = LlmService();

  LensSet? _activeLens;
  String _personality = 'Warm and grounded.';
  String _personaName = 'Companion';
  String _contextWindow = 'today';
  bool _noEntriesToday = false;

  List<ReflectionCard> _cards = [];
  bool _aiLoading = true;
  String? _aiError;
  PromptContext? _promptContext;
  bool _reflectionSaved = false;
  bool _readOnly = false;
  int _dailyCount = 0;

  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadLenses();
  }

  bool get _isZh =>
      context.read<LocaleProvider>().locale.languageCode == 'zh';

  Future<void> _loadLenses() async {
    try {
      final persona = context.read<AiPersonaProvider>();
      _personaName = persona.displayNameFor(_isZh);
      _personality = persona.personality.isNotEmpty
          ? persona.personality
          : 'Warm and grounded.';
      final prefs = await SharedPreferences.getInstance();

      // Smart progression: if already generated today without new entries, advance to 7 days
      final today = DateTime.now();
      final todayKey = '${today.year}_${today.month}_${today.day}';
      final lastCtxKey = 'reflection_last_context';
      final lastCtx = prefs.getString(lastCtxKey);
      if (_contextWindow == 'today') {
        final entryProvider = context.read<EntryProvider>();
        final todayEntries = entryProvider.entries.where((e) =>
            e.createdAt.isAfter(DateTime(today.year, today.month, today.day)));
        if (todayEntries.isEmpty) {
          _noEntriesToday = true;
          _contextWindow = 'recent';
        } else if (lastCtx == todayKey) {
          // Already generated today — advance to 7 days
          _contextWindow = 'recent';
        } else {
          await prefs.setString(lastCtxKey, todayKey);
        }
      }
      final countKey =
          'reflection_count_${today.year}_${today.month}_${today.day}';
      _dailyCount = prefs.getInt(countKey) ?? 0;
      if (_dailyCount >= 3 && mounted) {
        setState(() {
          _readOnly = true;
          _aiLoading = false;
        });
        // Load today's saved reflections
        _loadSavedReflections();
        return;
      }

      final storage = context.read<StorageService>();
      final activeLens = await storage.getActiveLensSet();
      if (activeLens == null) {
        setState(() => _loadError =
            _isZh ? '未找到激活的镜片组。' : 'No active lens set found.');
        return;
      }
      _activeLens = activeLens;

      setState(() {
        _cards = List.generate(
          activeLens.lenses.length,
          (i) => ReflectionCard(
            lens: i + 1,
            card: _isZh ? '思考中…' : 'Thinking…',
            sparse: false,
          ),
        );
      });

      _loadContextAndGenerate();
    } catch (e) {
      setState(() => _loadError =
          _isZh ? '加载失败' : 'Failed to load');
    }
  }

  Future<void> _loadSavedReflections() async {
    final entryProvider = context.read<EntryProvider>();
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    final saved = entryProvider.entries
        .where((e) =>
            e.tagIds.contains('tag_synthesis') &&
            (e.content.startsWith('Daily Reflection') ||
                e.content.startsWith('每日反思')) &&
            e.createdAt.isAfter(todayStart) &&
            e.createdAt.isBefore(todayEnd))
        .toList();

    if (mounted) {
      setState(() {
        if (saved.isNotEmpty) {
          final text = saved.map((e) => e.content ?? '').join('\n\n');
          _cards = [
            ReflectionCard(
                lens: 1, card: text.isNotEmpty ? text : 'No reflections yet.',
                sparse: false)
          ];
        } else {
          _cards = [
            ReflectionCard(
                lens: 1,
                card: _isZh ? '今天还没有反思。' : 'No reflections today.',
                sparse: true)
          ];
        }
        _reflectionSaved = true;
      });
    }
  }

  Future<void> _loadContextAndGenerate() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final countKey = 'reflection_count_${today.year}_${today.month}_${today.day}';
    _dailyCount = prefs.getInt(countKey) ?? 0;

    final entryProvider = context.read<EntryProvider>();
    final routineProvider = context.read<RoutineProvider>();
    final filteredEntries = entryProvider.entries
        .where((e) => !e.tagIds.contains('tag_private'))
        .toList();

    _promptContext = PromptAssembler.buildContext(
      entries: filteredEntries,
      routines: routineProvider.routines,
      window: _contextWindow,
    );

    if (_promptContext!.entries.isEmpty) {
      setState(() {
        for (var i = 0; i < _cards.length; i++) {
          _cards[i] = ReflectionCard(
            lens: i + 1,
            card: _isZh ? '还没有笔记' : 'No entries yet.',
            sparse: true,
          );
        }
        _aiLoading = false;
      });
      return;
    }

    if (!await LlmService.hasApiKey()) {
      setState(() {
        _aiError = _isZh ? '未配置 API Key' : 'No API key configured';
        _aiLoading = false;
      });
      return;
    }

    try {
      final prompt = PromptAssembler.assembleStage1Prompt(
        entries: _promptContext!.entries,
        moodSummary: _promptContext!.moodSummary,
        habitSummary: _promptContext!.habitSummary,
        lenses: _activeLens!.lenses,
        personalityString: _personality,
        isZh: _isZh,
      );

      final response = await _llm.complete(
        _isZh ? '请生成镜片卡片。' : 'Generate lens cards.',
        systemPrompt: prompt,
        maxTokens: 300,
      );
      final cardsData = PromptAssembler().parseStage1Response(response);

      if (!mounted) return;
      // Increment counter only on success
      _dailyCount = (prefs.getInt(countKey) ?? 0) + 1;
      await prefs.setInt(countKey, _dailyCount);
      if (_dailyCount >= 3) _readOnly = true;

      setState(() {
        final parsed = cardsData.map((c) => ReflectionCard.fromJson(c)).toList();
        for (var i = 0; i < _cards.length && i < parsed.length; i++) {
          _cards[i] = parsed[i];
        }
        _aiLoading = false;
      });
    } on LlmException catch (e) {
      if (!mounted) return;
      setState(() {
        _aiError = e.friendlyMessage(_isZh);
        _aiLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _aiError = _isZh ? '发生错误' : 'Error';
        _aiLoading = false;
      });
    }
  }

  Future<void> _saveReflection() async {
    if (_reflectionSaved) return;
    final lenses = _activeLens?.lenses ?? [];
    final buffer = StringBuffer();
    buffer.writeln(_isZh
        ? '每日反思 — ${_activeLens?.label ?? ''}'
        : 'Daily Reflection — ${_activeLens?.label ?? ''}');
    buffer.writeln();

    var hasContent = false;
    for (var i = 0; i < _cards.length; i++) {
      final card = _cards[i];
      if (card.sparse) continue;
      if (card.card == 'Thinking…' || card.card == '思考中…') continue;
      final label = i < lenses.length ? lenses[i] : 'Lens ${i + 1}';
      buffer.writeln(label);
      buffer.writeln(card.card);
      buffer.writeln();
      hasContent = true;
    }

    if (!hasContent) return;

    final text = buffer.toString().trim();
    final entryProvider = context.read<EntryProvider>();
    try {
      await entryProvider.addEntry(
        type: EntryType.freeform,
        content: text,
        emotion: null,
        tagIds: ['tag_synthesis'],
        mediaUrls: [],
      );
      if (!mounted) return;
      setState(() => _reflectionSaved = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isZh ? '反思已保存。' : 'Reflection saved.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isZh ? '保存失败。' : 'Failed to save.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final persona = context.read<AiPersonaProvider>();
    final avatarPath = persona.avatarPath;
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    final styleAsset = persona.styleAvatarAssetFor(isZh);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: avatarPath != null
                  ? FileImage(File(avatarPath))
                  : styleAsset != null
                      ? AssetImage(styleAsset)
                      : null,
              child: avatarPath == null && styleAsset == null
                  ? const Text('✦', style: TextStyle(fontSize: 16))
                  : null,
            ),
            const SizedBox(width: 8),
            Text(_personaName, style: const TextStyle(fontSize: 16)),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.tune),
            onSelected: (v) {
              if (v != _contextWindow && _dailyCount < 3) {
                setState(() {
                  _contextWindow = v;
                  _aiLoading = true;
                  _reflectionSaved = false;
                  _readOnly = false;
                  _cards = List.generate(
                    _activeLens!.lenses.length,
                    (i) => ReflectionCard(
                      lens: i + 1,
                      card: _isZh ? '思考中…' : 'Thinking…',
                      sparse: false,
                    ),
                  );
                });
                _loadContextAndGenerate();
              }
            },
            itemBuilder: (_) => [
              _windowItem('today', _isZh ? '今天' : 'Today'),
              _windowItem('recent', _isZh ? '最近 7 天' : 'Last 7 days'),
              _windowItem('month', _isZh ? '本月' : 'This month'),
              _windowItem('last3months', _isZh ? '最近 3 个月' : 'Last 3 months'),
            ],
          ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  PopupMenuItem<String> _windowItem(String value, String label) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          if (_contextWindow == value)
            const Icon(Icons.check, size: 18)
          else
            const SizedBox(width: 18),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_loadError != null) {
      return Center(
        child: Text(_loadError!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600])),
      );
    }

    if (_readOnly) return _buildReadOnly(theme);

    final entriesCount = _promptContext?.entries.length ?? 0;
    final hasContent =
        _cards.any((c) => !c.sparse && c.card != 'Thinking…' && c.card != '思考中…');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isZh ? '每日反思' : 'Daily Reflection',
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _activeLens?.label ?? '',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    Row(
                      children: [
                        Icon(Icons.date_range, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          _contextLabel(_isZh),
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                    if (_noEntriesToday)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _isZh ? '今天暂无笔记，已切换至最近 7 天' : 'No entries today — showing last 7 days',
                          style: TextStyle(color: Colors.orange[600], fontSize: 11),
                        ),
                      ),
                    if (entriesCount > 0)
                      Text(
                        _isZh ? '基于 $entriesCount 条笔记' : 'Based on $entriesCount notes',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                  ],
                ),
              ),
              if (_aiLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              if (_aiError != null)
                GestureDetector(
                  onTap: _loadContextAndGenerate,
                  child: Icon(Icons.refresh, color: Colors.orange[700], size: 20),
                ),
            ],
          ),
        ),

        if (entriesCount == 0)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.edit_note, color: Colors.grey[400]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isZh
                        ? '还没有笔记。写几条日记后镜片会自动生成观察。'
                        : 'No entries yet. Lenses will generate observations as you write.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

        for (var i = 0; i < _cards.length; i++) ...[
          _buildLensCard(theme, i),
          const SizedBox(height: 12),
        ],

        // Save button — disabled after save
        if (!_aiLoading && hasContent)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            child: Center(
              child: _reflectionSaved
                  ? OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.check, size: 18),
                      label: Text(_isZh ? '已保存' : 'Saved'),
                    )
                  : FilledButton.icon(
                      onPressed: _saveReflection,
                      icon: const Icon(Icons.bookmark_add, size: 18),
                      label: Text(_isZh ? '保存反思' : 'Save Reflection'),
                    ),
            ),
          ),
      ],
    );
  }

  Widget _buildReadOnly(ThemeData theme) {
    final content = _cards.isNotEmpty ? _cards.first.card : '';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isZh ? '每日反思' : 'Daily Reflection',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
                  const SizedBox(width: 6),
                  Text(
                    _isZh
                        ? '今日反思次数已达上限（3次）。查看已保存的反思：'
                        : 'Today\'s reflection limit reached (3). Saved reflections:',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            content.isNotEmpty ? content : (_isZh ? '暂无反思。' : 'No reflections.'),
            style: const TextStyle(fontSize: 15, height: 1.6),
          ),
        ),
      ],
    );
  }

  String _contextLabel(bool isZh) {
    switch (_contextWindow) {
      case 'today': return isZh ? '今天' : 'Today';
      case 'recent': return isZh ? '最近 7 天' : 'Last 7 days';
      case 'month': return isZh ? '本月' : 'This month';
      case 'last3months': return isZh ? '最近 3 个月' : 'Last 3 months';
      default: return '';
    }
  }

  Widget _buildLensCard(ThemeData theme, int index) {
    final card = _cards[index];
    final lenses = _activeLens?.lenses ?? [];
    final lensLabel =
        index < lenses.length ? lenses[index] : 'Lens ${index + 1}';
    final hasContent = !card.sparse &&
        card.card != 'Thinking…' &&
        card.card != '思考中…';

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: card.sparse && !_aiLoading
              ? Colors.grey.shade300
              : theme.colorScheme.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _aiLoading
                        ? Colors.grey.shade200
                        : card.sparse
                            ? Colors.grey.shade200
                            : theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: _aiLoading || card.sparse
                            ? Colors.grey
                            : theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    lensLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: card.sparse && !_aiLoading ? Colors.grey : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_aiLoading &&
                card.card == (_isZh ? '思考中…' : 'Thinking…'))
              Text(
                card.card,
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                    fontStyle: FontStyle.italic),
              )
            else
              Text(
                card.card,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: card.sparse ? Colors.grey[500] : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
