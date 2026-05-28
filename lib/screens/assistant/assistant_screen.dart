import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/entry_provider.dart';
import '../../providers/ai_persona_provider.dart';
import '../../providers/locale_provider.dart';
import '../../models/entry.dart';
import '../../core/services/llm_service.dart';
import '../../core/services/soft_prompt_service.dart';
import '../../widgets/card_builder_sheet.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _llmService = LlmService();
  final List<ChatMessage> _messages = [];
  bool _isSending = false;
  bool _showTrialExpiredBanner = false;
  bool _hasSavedReflection = false;
  String _lastSavedReflectionContent = '';

  // Notes context — always on; custom range overrides the 30-day default
  bool _customRangeActive = false;
  late DateTime _notesStartDate;
  late DateTime _notesEndDate;

  static const int _defaultDays = 30;

  @override
  void initState() {
    super.initState();
    _resetToDefaultRange();
    // Post system info message after first frame (providers ready)
    WidgetsBinding.instance.addPostFrameCallback((_) => _postNoteLoadMessage());
  }

  void _resetToDefaultRange() {
    _notesStartDate = DateTime.now().subtract(const Duration(days: _defaultDays));
    _notesEndDate = DateTime.now();
    _customRangeActive = false;
  }

  void _postNoteLoadMessage() {
    if (!mounted) return;
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    final entries = context.read<EntryProvider>().allEntries;
    final secretCount = _countSecretEntries(entries, _notesStartDate, _notesEndDate);
    final count = _countEntriesInRange(entries, _notesStartDate, _notesEndDate) - secretCount;
    String text;
    if (secretCount > 0) {
      text = isZh
          ? '📖 已加载最近 $_defaultDays 天的 $count 条笔记（已排除 $secretCount 条私密笔记）'
          : '📖 Loaded $count ${count == 1 ? 'entry' : 'entries'} from the past $_defaultDays days ($secretCount private ${secretCount == 1 ? 'entry' : 'entries'} excluded)';
    } else {
      text = isZh
          ? '📖 已加载最近 $_defaultDays 天的 $count 条笔记'
          : '📖 Loaded $count ${count == 1 ? 'entry' : 'entries'} from the past $_defaultDays days';
    }
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: false,
        isSystem: true,
        timestamp: DateTime.now(),
      ));
    });
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  int _countEntriesInRange(
      List<Entry> entries, DateTime start, DateTime end) {
    final endOfDay =
        DateTime(end.year, end.month, end.day, 23, 59, 59);
    return entries
        .where((e) =>
            !e.createdAt.isBefore(start) && !e.createdAt.isAfter(endOfDay))
        .length;
  }

  List<Entry> _filterEntriesInRange(
      List<Entry> entries, DateTime start, DateTime end) {
    final endOfDay =
        DateTime(end.year, end.month, end.day, 23, 59, 59);
    return entries
        .where((e) =>
            !e.createdAt.isBefore(start) &&
            !e.createdAt.isAfter(endOfDay) &&
            !e.tagIds.contains('tag_private'))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// Count entries excluded from AI due to Secrets tag (for display only)
  int _countSecretEntries(List<Entry> entries, DateTime start, DateTime end) {
    final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
    return entries
        .where((e) =>
            !e.createdAt.isBefore(start) &&
            !e.createdAt.isAfter(endOfDay) &&
            e.tagIds.contains('tag_private'))
        .length;
  }

  String _buildNotesBlock(List<Entry> filtered, bool isZh) {
    if (filtered.isEmpty) return '';
    final header = isZh
        ? '以下是用户在 ${_fmtDate(_notesStartDate)} 至 ${_fmtDate(_notesEndDate)} 的笔记记录：\n\n'
        : 'User journal entries from ${_fmtDate(_notesStartDate)} to ${_fmtDate(_notesEndDate)}:\n\n';
    final buf = StringBuffer(header);
    for (final e in filtered) {
      buf.write('[${_fmtDate(e.createdAt)}');
      if (e.emotion != null) buf.write(' ${e.emotion}');
      buf.write('] ${e.content}\n');
    }
    return buf.toString();
  }

  String _buildSystemPrompt() {
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    final persona = context.read<AiPersonaProvider>();
    final String base;
    if (isZh) {
      base = '你是 Blinking 日记应用的 AI 助手，名字叫 ${persona.name}。'
          '${persona.personality.isNotEmpty ? "你的性格特点：${persona.personality}。" : ""}'
          '帮助用户回顾每日记录、提供情绪支持和成长建议。请用温暖、简洁的中文回答。如果用户分享了心情或记录，给出有共鸣的回应。';
    } else {
      base = 'You are ${persona.name}, the AI assistant for the Blinking journal app.'
          '${persona.personality.isNotEmpty ? " Your personality: ${persona.personality}." : ""}'
          ' Help users reflect on their daily entries, provide emotional support and growth suggestions.'
          ' Respond warmly and concisely in English. When the user shares feelings or entries, give an empathetic response.';
    }

    final entries = context.read<EntryProvider>().allEntries;
    final filtered = _filterEntriesInRange(entries, _notesStartDate, _notesEndDate);
    final notesBlock = _buildNotesBlock(filtered, isZh);
    return notesBlock.isEmpty ? base : '$base\n\n$notesBlock';
  }

  String _fmtDate(DateTime d) =>
      '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

  String _formatTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  // ─── Scroll ─────────────────────────────────────────────────────────────────

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─── Send ────────────────────────────────────────────────────────────────────

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    _messageController.clear();
    setState(() {
      _messages.add(
          ChatMessage(text: text, isUser: true, timestamp: DateTime.now()));
      _isSending = true;
    });
    _scrollToBottom();

    try {
      // Exclude system messages from LLM history
      final history = _messages
          .where((m) => !m.isSystem)
          .map((m) =>
              {'role': m.isUser ? 'user' : 'assistant', 'content': m.text})
          .toList();

      final reply = await _llmService.chat(
        history: history,
        systemPrompt: _buildSystemPrompt(),
      );

      if (mounted) {
        setState(() {
          _messages.add(
              ChatMessage(text: reply, isUser: false, timestamp: DateTime.now()));
        });
        _scrollToBottom();
      }
    } on LlmException catch (e) {
      if (mounted) {
        final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
        if (e.type == LlmErrorType.trialExpired) {
          setState(() => _showTrialExpiredBanner = true);
        }
        setState(() {
          _messages.add(ChatMessage(
              text: '⚠️ ${e.friendlyMessage(isZh)}',
              isUser: false,
              timestamp: DateTime.now()));
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) {
        final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
        setState(() {
          _messages.add(ChatMessage(
              text: isZh
                  ? '⚠️ 网络连接失败，请检查网络后重试。'
                  : '⚠️ Network connection failed. Please check your connection and try again.',
              isUser: false,
              timestamp: DateTime.now()));
        });
        _scrollToBottom();
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _sendText(String text) {
    _messageController.text = text;
    _sendMessage();
  }

  // ─── Quick action handlers ───────────────────────────────────────────────────

  void _showReflectionPrompt() {
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    final prompts = isZh
        ? [
            '今天最让你开心的事是什么？',
            '今天遇到了什么挑战？你是如何应对的？',
            '今天学到了什么新东西？',
            '有什么想对明天的自己说的话吗？',
            '今天有什么值得感恩的事情？',
          ]
        : [
            'What made you happiest today?',
            'What challenge did you face today, and how did you handle it?',
            'What new thing did you learn today?',
            'Is there anything you want to tell your future self?',
            'What are you grateful for today?',
          ];
    final prompt = prompts[DateTime.now().second % prompts.length];
    setState(() {
      _messages.add(ChatMessage(
        text: '💭 ${isZh ? '反思时刻' : 'Reflection'}\n\n$prompt',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _sendTodayEmotion() {
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    final today = DateTime.now();
    final todayEntries =
        context.read<EntryProvider>().getEntriesForDate(today);

    if (todayEntries.isEmpty) {
      _sendText(isZh
          ? '今天还没有记录。请根据我最近的笔记帮我分析近期情绪趋势，并给出建议。'
          : "I haven't logged anything today. Based on my recent entries, can you help me analyze my recent mood trends and offer suggestions?");
      return;
    }

    final parts = todayEntries.map((e) {
      final buf = StringBuffer();
      if (e.emotion != null) buf.write('${e.emotion} ');
      buf.write(e.content);
      return buf.toString();
    }).join(isZh ? '；' : '; ');

    _sendText(isZh
        ? '今天我记录了 ${todayEntries.length} 条笔记：$parts。请帮我回顾今日情绪并给出建议。'
        : "Today I logged ${todayEntries.length} ${todayEntries.length == 1 ? 'entry' : 'entries'}: $parts. Can you help me reflect on today's mood and offer suggestions?");
  }

  // ─── Date range picker ───────────────────────────────────────────────────────

  Future<void> _pickCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange:
          DateTimeRange(start: _notesStartDate, end: _notesEndDate),
    );
    if (picked != null && mounted) {
      final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
      final entries = context.read<EntryProvider>().allEntries;
      final count = _countEntriesInRange(entries, picked.start, picked.end);
      setState(() {
        _notesStartDate = picked.start;
        _notesEndDate = picked.end;
        _customRangeActive = true;
      });
      // Post system feedback
      setState(() {
        _messages.add(ChatMessage(
          text: isZh
              ? '📖 已切换至 ${_fmtDate(picked.start)} – ${_fmtDate(picked.end)}，共 $count 条笔记'
              : '📖 Switched to ${_fmtDate(picked.start)} – ${_fmtDate(picked.end)}, $count ${count == 1 ? 'entry' : 'entries'}',
          isUser: false,
          isSystem: true,
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
    }
  }

  void _resetDateRange() {
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    final entries = context.read<EntryProvider>().allEntries;
    _resetToDefaultRange();
    final count =
        _countEntriesInRange(entries, _notesStartDate, _notesEndDate);
    setState(() {
      _messages.add(ChatMessage(
        text: isZh
            ? '📖 已恢复最近 $_defaultDays 天，共 $count 条笔记'
            : '📖 Reset to last $_defaultDays days, $count ${count == 1 ? 'entry' : 'entries'}',
        isUser: false,
        isSystem: true,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  // ─── Summarize range ─────────────────────────────────────────────────────────

  Future<void> _summarizeNotesInRange() async {
    final entries = context.read<EntryProvider>().allEntries;
    final filtered =
        _filterEntriesInRange(entries, _notesStartDate, _notesEndDate);

    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';

    if (filtered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isZh
              ? '所选日期范围内没有笔记'
              : 'No entries in the selected date range'),
        ),
      );
      return;
    }

    final notesText = filtered
        .map((e) =>
            '[${_fmtDate(e.createdAt)}${e.emotion != null ? " ${e.emotion}" : ""}] ${e.content}')
        .join('\n');

    final prompt = isZh
        ? '请对以下 ${_fmtDate(_notesStartDate)} 至 ${_fmtDate(_notesEndDate)} 期间的笔记做一个深度总结，'
            '分析情绪变化、主要事件和成长点（200字以内）：\n\n$notesText'
        : 'Please provide a deep summary of the following journal entries from ${_fmtDate(_notesStartDate)} to ${_fmtDate(_notesEndDate)}. '
            'Analyze mood patterns, key events, and growth points (within 200 words):\n\n$notesText';

    setState(() => _isSending = true);
    try {
      final summary = await _llmService.complete(prompt);
      if (!mounted) return;

      await context.read<EntryProvider>().addEntry(
        type: EntryType.freeform,
        content:
            '【AI 总结 ${_fmtDate(_notesStartDate)}–${_fmtDate(_notesEndDate)}】\n\n$summary',
        tagIds: ['tag_synthesis'],
      );

      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text:
                '📋 ${isZh ? '总结' : 'Summary'} (${_fmtDate(_notesStartDate)}–${_fmtDate(_notesEndDate)})\n\n$summary',
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
        _scrollToBottom();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isZh ? '总结已保存到记录 ✨' : 'Summary saved to entries ✨')),
        );
      }
    } on LlmException catch (e) {
      if (mounted) {
        final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.friendlyMessage(isZh))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // ─── Save ────────────────────────────────────────────────────────────────────

  Future<void> _saveReflection() async {
    // Only include real conversation (exclude system messages)
    final conversation = _messages
        .where((m) => !m.isSystem)
        .map((m) => '${m.isUser ? "用户" : "AI"}: ${m.text}')
        .join('\n\n');
    if (conversation.isEmpty) return;

    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    final prompt = isZh
        ? '请将以下对话总结成一段简洁的反思笔记（100-200字），用第一人称，以"今天"或"这次"开头：\n\n$conversation'
        : 'Summarize the following conversation into a concise personal reflection note (100-200 words), written in first person, starting with "Today" or "This time":\n\n$conversation';

    setState(() => _isSending = true);
    String summary;
    try {
      summary = await _llmService.complete(prompt);
    } on LlmException catch (e) {
      if (mounted) {
        final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.friendlyMessage(isZh))),
        );
      }
      setState(() => _isSending = false);
      return;
    } catch (_) {
      summary = _messages
          .where((m) => m.isUser)
          .map((m) => m.text)
          .join('\n');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }

    if (!mounted) return;
    await context.read<EntryProvider>().addEntry(
      type: EntryType.freeform,
      content: summary,
      tagIds: ['tag_synthesis'],
    );
    if (mounted) {
      final isZhSnack = context.read<LocaleProvider>().locale.languageCode == 'zh';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isZhSnack ? '反思已保存到记录 ✨' : 'Reflection saved ✨')),
      );
      setState(() {
        _hasSavedReflection = true;
        _lastSavedReflectionContent = summary;
      });
      await SoftPromptService.maybeShow(context);
    }
  }

  Future<void> _saveSingleMessage(ChatMessage message) async {
    await context.read<EntryProvider>().addEntry(
      type: EntryType.freeform,
      content: message.text,
      tagIds: ['tag_synthesis'],
    );
    if (mounted) {
      final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isZh ? '已保存到记录 ✨' : 'Saved to entries ✨')),
      );
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final persona = context.watch<AiPersonaProvider>();
    final avatarFile =
        persona.avatarPath != null ? File(persona.avatarPath!) : null;
    final hasCustomAvatar = avatarFile != null && avatarFile.existsSync();
    final styleAsset = persona.styleAvatarAssetFor(isZh);
    final hasRealMessages = _messages.any((m) => !m.isSystem);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (hasCustomAvatar)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CircleAvatar(
                  radius: 14,
                  backgroundImage: FileImage(avatarFile),
                ),
              )
            else if (styleAsset != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CircleAvatar(
                  radius: 14,
                  backgroundImage: AssetImage(styleAsset),
                ),
              ),
            Text(persona.displayNameFor(isZh)),
          ],
        ),
        actions: [
          if (_hasSavedReflection)
            Semantics(
              identifier: 'btn_assistant_save_keepsake',
              child: IconButton(
                icon: const Icon(Icons.photo_album_outlined),
                tooltip: isZh ? '保存为纪念' : 'Save as Keepsake',
                onPressed: () {
                  CardBuilderSheet.show(
                    context,
                    initialContent: _lastSavedReflectionContent,
                  );
                },
              ),
            ),
          if (hasRealMessages)
            IconButton(
              icon: const Icon(Icons.save_alt),
              tooltip: isZh ? '保存反思' : 'Save reflection',
              onPressed: _isSending ? null : _saveReflection,
            ),
        ],
      ),
      body: Column(
        children: [
          _buildQuickActions(isZh),
          if (_customRangeActive) _buildCustomRangeBar(isZh),
          if (_showTrialExpiredBanner) _buildTrialExpiredBanner(isZh),
          const Divider(height: 1),
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState(hasCustomAvatar, avatarFile, styleAsset, persona.displayNameFor(isZh), isZh)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) => _buildMessageBubble(_messages[i]),
                  ),
          ),
          const Divider(height: 1),
          _buildInputField(),
        ],
      ),
    );
  }

  Widget _buildQuickActions(bool isZh) {
    final label = _customRangeActive
        ? '📖 ${_fmtDate(_notesStartDate).substring(5)}–${_fmtDate(_notesEndDate).substring(5)}'
        : (isZh ? '📖 最近$_defaultDays天' : '📖 Last $_defaultDays days');

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          ActionChip(
            avatar: const Icon(Icons.psychology, size: 18, color: Colors.black87),
            label: Text(isZh ? '反思提示' : 'Reflect',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black87)),
            onPressed: _showReflectionPrompt,
          ),
          const SizedBox(width: 8),
          ActionChip(
            avatar: const Icon(Icons.mood, size: 18, color: Colors.black87),
            label: Text(isZh ? '今日情绪' : "Mood",
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black87)),
            onPressed: _sendTodayEmotion,
          ),
          const SizedBox(width: 8),
          ActionChip(
            avatar: const Icon(Icons.lightbulb_outline,
                size: 18, color: Colors.black87),
            label: Text(isZh ? '激励一下' : 'Motivate',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black87)),
            onPressed: () => _sendText(isZh
                ? '给我一句温暖的鼓励'
                : 'Give me a warm word of encouragement'),
          ),
          const SizedBox(width: 8),
          ActionChip(
            label: Text(label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12)),
            onPressed: _pickCustomDateRange,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomRangeBar(bool isZh) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.date_range, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              isZh
                  ? '自定义：${_fmtDate(_notesStartDate)} – ${_fmtDate(_notesEndDate)}'
                  : 'Range: ${_fmtDate(_notesStartDate)} – ${_fmtDate(_notesEndDate)}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: _resetDateRange,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(isZh ? '重置' : 'Reset',
                style: const TextStyle(fontSize: 12)),
          ),
          TextButton(
            onPressed: _isSending ? null : _summarizeNotesInRange,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(isZh ? '生成总结' : 'Summarize',
                style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildTrialExpiredBanner(bool isZh) {
    return Container(
      color: Colors.orange.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const Text('\u23F0', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isZh
                  ? '7 天试用已过期。请前往设置添加 API Key 以继续聊天。'
                  : 'Your 7-day trial has ended. Add your own API key in Settings to continue chatting.',
              style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              isZh ? '设置 \u2192' : 'Settings \u2192',
              style: TextStyle(fontSize: 12, color: Colors.orange.shade800, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () => setState(() => _showTrialExpiredBanner = false),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
      bool hasCustomAvatar, File? avatarFile, String? styleAsset, String name, bool isZh) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (hasCustomAvatar)
            CircleAvatar(
              radius: 36,
              backgroundImage: FileImage(avatarFile!),
            )
          else if (styleAsset != null)
            CircleAvatar(
              radius: 36,
              backgroundImage: AssetImage(styleAsset),
            )
          else
            const Text('🤖', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
              isZh ? '你好！我是你的 $name' : 'Hi! I\'m your $name',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            isZh
                ? '可以聊聊今天的心情，或者问我任何事'
                : 'Share how you\'re feeling, or ask me anything',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    // System messages: centered, grey, small — not a chat bubble
    if (message.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: Text(
            message.text,
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showSaveMessageSheet(message),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          constraints:
              BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            color: isUser
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isUser ? 16 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message.text, style: const TextStyle(fontSize: 15)),
              const SizedBox(height: 4),
              Text(
                _formatTime(message.timestamp),
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSaveMessageSheet(ChatMessage message) {
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.save_alt),
              title: Text(isZh ? '保存为笔记' : 'Save as note'),
              onTap: () {
                Navigator.pop(context);
                _saveSingleMessage(message);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField() {
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: MergeSemantics(child: Semantics(
              identifier: 'input_ai_chat',
              textField: true,
              child: TextField(
                controller: _messageController,
              decoration: InputDecoration(
                hintText: isZh ? '向 AI 提问…' : 'Ask AI…',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
            )),
          ),
          const SizedBox(width: 8),
          _isSending
              ? const SizedBox(
                  width: 40,
                  height: 40,
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : Semantics(
                  identifier: 'btn_ai_send',
                  child: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final bool isSystem;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.isSystem = false,
    required this.timestamp,
  });
}
