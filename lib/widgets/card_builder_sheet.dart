import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../models/card_template.dart';
import '../models/note_card.dart';
import '../providers/card_provider.dart';
import '../providers/locale_provider.dart';
import '../core/services/card_render_service.dart';
import '../core/services/llm_service.dart';
import 'card_template_picker.dart';

/// Bottom sheet for building a Keepsake card.
/// Template picker, content editor, AI Rewrite, toggle overlays, Save.
class CardBuilderSheet extends StatefulWidget {
  final String? entryId;
  final String initialContent;
  final String? initialEmotion;
  final List<String>? initialTags;
  final String? initialPhotoPath;
  final DateTime? entryDate;
  final Future<String> Function({
    required CardTemplate template,
    required String content,
    String? imagePath,
    String? emotion,
    List<String>? tags,
    DateTime? date,
    bool? showMood,
    bool? showDate,
    bool? showTags,
    bool? showFooter,
  })? _renderFn;

  const CardBuilderSheet({
    super.key,
    this.entryId,
    required this.initialContent,
    this.initialEmotion,
    this.initialTags,
    this.initialPhotoPath,
    this.entryDate,
    @visibleForTesting Future<String> Function({
      required CardTemplate template,
      required String content,
      String? imagePath,
      String? emotion,
      List<String>? tags,
      DateTime? date,
      bool? showMood,
      bool? showDate,
      bool? showTags,
      bool? showFooter,
    })? renderFn,
  }) : _renderFn = renderFn;

  /// Show the builder as a modal bottom sheet. Returns the created NoteCard, or null if cancelled.
  static Future<NoteCard?> show(
    BuildContext context, {
    String? entryId,
    required String initialContent,
    String? initialEmotion,
    List<String>? initialTags,
    String? initialPhotoPath,
    DateTime? entryDate,
    @visibleForTesting Future<String> Function({
      required CardTemplate template,
      required String content,
      String? imagePath,
      String? emotion,
      List<String>? tags,
      DateTime? date,
      bool? showMood,
      bool? showDate,
      bool? showTags,
      bool? showFooter,
    })? renderFn,
  }) {
    return showModalBottomSheet<NoteCard>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CardBuilderSheet(
        entryId: entryId,
        initialContent: initialContent,
        initialEmotion: initialEmotion,
        initialTags: initialTags,
        initialPhotoPath: initialPhotoPath,
        entryDate: entryDate,
        renderFn: renderFn,
      ),
    );
  }

  @override
  State<CardBuilderSheet> createState() => _CardBuilderSheetState();
}

class _CardBuilderSheetState extends State<CardBuilderSheet> {
  late TextEditingController _contentController;
  late CardTemplate _selectedTemplate;
  bool _showMood = true;
  bool _showDate = true;
  bool _showTags = true;
  bool _showFooter = true;
  bool _isSaving = false;
  bool _isRewriting = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.initialContent);
    final templates = context.read<CardProvider>().templates;
    _selectedTemplate = templates.isNotEmpty ? templates.first : _fallbackTemplate();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  CardTemplate _fallbackTemplate() {
    final now = DateTime.now();
    return CardTemplate(
      id: 'tpl_fallback', name: 'Default', icon: '📄',
      fontColor: '#2C2C2C', bgColor: '#F5F0E8',
      isBuiltIn: true, createdAt: now,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final cardProvider = context.read<CardProvider>();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        children: [
          Expanded(
            child: DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      // Drag handle
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Title row with close button
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            isZh ? '保存为纪念' : 'Save as Keepsake',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Semantics(
                              identifier: 'btn_close_builder',
                              button: true,
                              onTap: () => Navigator.of(context).pop(),
                              child: IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Scrollable body
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            // Template picker
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                isZh ? '选择模板' : 'Choose Template',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ),
                            CardTemplatePicker(
                              selectedTemplate: _selectedTemplate,
                              onTemplateSelected: (tpl) {
                                setState(() => _selectedTemplate = tpl);
                              },
                            ),
                            const SizedBox(height: 16),
                            // Content editor
                            Text(
                              isZh ? '内容' : 'Content',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Semantics(
                              identifier: 'card_builder_content',
                              child: TextField(
                                controller: _contentController,
                                autofocus: true,
                                maxLines: 8,
                                minLines: 4,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  hintText: isZh ? '你的文字...' : 'Your words...',
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // AI Rewrite button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _isRewriting ? null : _handleAiRewrite,
                                icon: _isRewriting
                                    ? const SizedBox(
                                        width: 16, height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.auto_awesome, size: 18),
                                label: Text(_isRewriting
                                    ? (isZh ? '润色中...' : 'Rewriting...')
                                    : (isZh ? 'AI 润色' : 'AI Rewrite')),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Toggle row
                            Text(
                              isZh ? '显示元素' : 'Show Elements',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            Row(
                              children: [
                                Expanded(child: Text(isZh ? '心情' : 'Mood')),
                                Semantics(
                                  identifier: 'toggle_show_mood',
                                  onTap: () => setState(() => _showMood = !_showMood),
                                  child: Switch(
                                    value: _showMood,
                                    onChanged: (v) => setState(() => _showMood = v),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(child: Text(isZh ? '日期' : 'Date')),
                                Semantics(
                                  identifier: 'toggle_show_date',
                                  onTap: () => setState(() => _showDate = !_showDate),
                                  child: Switch(
                                    value: _showDate,
                                    onChanged: (v) => setState(() => _showDate = v),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(child: Text(isZh ? '标签' : 'Tags')),
                                Semantics(
                                  identifier: 'toggle_show_tags',
                                  onTap: () => setState(() => _showTags = !_showTags),
                                  child: Switch(
                                    value: _showTags,
                                    onChanged: (v) => setState(() => _showTags = v),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(child: Text(isZh ? '水印' : 'Footer')),
                                Semantics(
                                  identifier: 'toggle_show_footer',
                                  onTap: () => setState(() => _showFooter = !_showFooter),
                                  child: Switch(
                                    value: _showFooter,
                                    onChanged: (v) => setState(() => _showFooter = v),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Save button — fixed outside DraggableScrollableSheet so it is not
          // in the drag gesture arena. Native UIKit/XCTest taps reach it cleanly.
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Semantics(
              identifier: 'btn_card_save',
              container: true,
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white,
                          ),
                        )
                      : Text(isZh ? '保存纪念' : 'Save Keepsake',
                          style: const TextStyle(fontSize: 16)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAiRewrite() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isRewriting = true);
    try {
      final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
      final llm = LlmService();
      final rewritten = await llm.complete(
        isZh
            ? '润色以下文字。只返回润色后的文字，不要添加任何解释、评论或引号：\n\n$content'
            : 'Polish the following text. Return ONLY the polished text — no explanations, no commentary, no quotes, no preamble:\n\n$content',
        maxTokens: 300,
        temperature: 0.7,
      );
      if (mounted) {
        final cleaned = _stripAiPreamble(rewritten);
        _contentController.text = cleaned;
        _contentController.selection = TextSelection.collapsed(offset: cleaned.length);
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isZh ? '润色失败: $e' : 'Rewrite failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isRewriting = false);
    }
  }

  /// Strips common LLM preamble/postamble patterns from rewritten text.
  String _stripAiPreamble(String text) {
    String cleaned = text.trim();

    // Remove leading explanatory phrases (EN and ZH)
    final enPrefixes = [
      "Here's",
      "Here is",
      "Certainly!",
      "Sure!",
      "Of course!",
    ];
    final zhPrefixes = [
      '这是',
      '以下是',
    ];

    for (final prefix in [...enPrefixes, ...zhPrefixes]) {
      if (cleaned.toLowerCase().startsWith(prefix.toLowerCase())) {
        final periodIdx = cleaned.indexOf('.');
        final colonFullIdx = cleaned.indexOf('：');
        final colonHalfIdx = cleaned.indexOf(':');
        final zhPeriodIdx = cleaned.indexOf('。');
        final cutoff = [periodIdx, colonFullIdx, colonHalfIdx, zhPeriodIdx]
            .where((i) => i > 0)
            .fold<int>(cleaned.length, (a, b) => a < b ? a : b);
        cleaned = cleaned.substring(cutoff + 1).trim();
        // Strip leading dashes/separators that LLMs add after preamble
        cleaned = cleaned.replaceFirst(RegExp(r'^[-—–\s]+'), '').trim();
        break;
      }
    }

    // Remove trailing commentary (EN and ZH)
    final enSuffixes = [
      'Let me know if',
      'Let me know what',
      'I hope this',
      'This version enhances',
      'This version maintains',
      'This version preserves',
      'Feel free to',
    ];
    final zhSuffixes = [
      '如果需要',
      '如果有需要',
      '希望这个',
      '这个版本',
      '如果你需要',
      '请告诉我',
    ];

    for (final suffix in [...enSuffixes, ...zhSuffixes]) {
      final idx = cleaned.toLowerCase().indexOf(suffix.toLowerCase());
      if (idx > 0 && idx < cleaned.length - suffix.length) {
        cleaned = cleaned.substring(0, idx).trim();
        break;
      }
    }

    return cleaned.trim();
  }

  Future<void> _handleSave() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isZh ? '请输入内容' : 'Please enter some content')),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isSaving = true);
    try {
      final cardProvider = context.read<CardProvider>();

      // Preload and decode background image for reliable cross-platform rendering
      Uint8List? bgBytes;
      ui.Image? decodedBg;
      final bgPath = _selectedTemplate.backgroundImagePath;
      if (bgPath != null && bgPath.startsWith('assets/')) {
        try {
          bgBytes = (await rootBundle.load(bgPath)).buffer.asUint8List();
          decodedBg = await decodeImageFromList(bgBytes!);
        } catch (_) {}
      }

      String? photoPath = widget.initialPhotoPath;
      if (photoPath != null && !photoPath.startsWith('/')) {
        final dir = await getApplicationDocumentsDirectory();
        photoPath = '${dir.path}/$photoPath';
      }

      String? renderedPath;
      if (widget._renderFn != null) {
        renderedPath = await widget._renderFn!(
          template: _selectedTemplate,
          content: content,
          imagePath: photoPath,
          emotion: widget.initialEmotion,
          tags: widget.initialTags,
          date: widget.entryDate,
          showMood: _showMood,
          showDate: _showDate,
          showTags: _showTags,
          showFooter: _showFooter,
        );
      } else {
        final key = GlobalKey();
        final entry = OverlayEntry(
          builder: (_) => Positioned(
            left: -2000,
            top: 0,
            child: RepaintBoundary(
              key: key,
              child: CardRenderService.buildPreviewWidget(
                template: _selectedTemplate,
                content: content,
                imagePath: photoPath,
                emotion: widget.initialEmotion,
                tags: widget.initialTags,
                date: widget.entryDate,
                showMood: _showMood,
                showDate: _showDate,
                showTags: _showTags,
                showFooter: _showFooter,
                backgroundImageBytes: bgBytes,
                decodedBackgroundImage: decodedBg,
              ),
            ),
          ),
        );
        Overlay.of(context).insert(entry);
        try {
          await WidgetsBinding.instance.endOfFrame;
          renderedPath = await CardRenderService.captureFromKey(key);
        } finally {
          // Always schedule removal — even if captureFromKey throws — so the
          // entry never permanently blocks the UI on iOS.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try { entry.remove(); } catch (_) {}
          });
        }
      }

      if (renderedPath == null) {
        if (mounted) {
          final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isZh ? '渲染失败，请重试' : 'Render failed, please retry')),
          );
        }
        return;
      }

      // Persist to DB
      final card = await cardProvider.addCard(
        entryIds: widget.entryId != null ? [widget.entryId!] : [],
        templateId: _selectedTemplate.id,
        folderId: 'folder_default',
        renderedImagePath: renderedPath,
        cardContent: content,
        emotion: widget.initialEmotion,
        displayTags: widget.initialTags,
        showMood: _showMood,
        showDate: _showDate,
        showTags: _showTags,
        showFooter: _showFooter,
      );

      if (mounted) {
        final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isZh ? '纪念已保存' : 'Keepsake saved')),
        );
        Navigator.of(context).pop(card);
      }
    } catch (e) {
      if (mounted) {
        final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isZh ? '保存失败: $e' : 'Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
