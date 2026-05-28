import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/services/file_service.dart';
import '../../models/entry.dart';
import '../../models/note_card.dart';
import '../../providers/entry_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/tag_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/tag_chip.dart';
import '../../widgets/card_builder_sheet.dart';
import '../../providers/card_provider.dart';
import '../add_entry_screen.dart';
import '../chorus/post_to_chorus_sheet.dart';
import 'card_preview_screen.dart';

class EntryDetailScreen extends StatefulWidget {
  final Entry entry;

  const EntryDetailScreen({super.key, required this.entry});

  @override
  State<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends State<EntryDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final tagProvider = context.watch<TagProvider>();
    // Re-read from provider so edits from AddEntryScreen are reflected immediately
    final entryProvider = context.watch<EntryProvider>();
    final entry = entryProvider.allEntries.firstWhere(
      (e) => e.id == widget.entry.id,
      orElse: () => widget.entry,
    );
    final tags = tagProvider.tags.where((t) => entry.tagIds.contains(t.id)).toList();

    final dateStr = isZh
        ? DateFormat('yyyy年M月d日 HH:mm').format(entry.createdAt)
        : DateFormat('MMM d, y  HH:mm').format(entry.createdAt);

    final isPrivate = entry.tagIds.contains('tag_private');

    return Scaffold(
      appBar: AppBar(
        leading: Semantics(
          identifier: 'btn_back_entry',
          button: true,
          onTap: () => Navigator.of(context).pop(),
          child: BackButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isPrivate)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(Icons.lock_outline, size: 16, color: Colors.grey),
              ),
            Flexible(
              child: Text(
                dateStr,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          if (!_isPastDate(entry))
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: isZh ? '编辑' : 'Edit',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEntryScreen(existingEntry: entry),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: isZh ? '分享' : 'Share',
            onPressed: () => SharePlus.instance.share(
              ShareParams(
                text: entry.content,
                subject: isZh ? '来自 Blinking' : 'From Blinking',
                sharePositionOrigin: const Rect.fromLTWH(0, 0, 1, 1),
              ),
            ),
          ),
          Semantics(
            identifier: 'btn_save_keepsake',
            child: IconButton(
              icon: const Icon(Icons.photo_library_outlined),
              tooltip: isZh ? '保存为纪念' : 'Save as Keepsake',
              onPressed: () => _handleSaveAsKeepsake(context, entry),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.public_outlined),
            tooltip: isZh ? '发布到 Chorus' : 'Post to Chorus',
            onPressed: () async {
              final posted = await PostToChorusSheet.show(
                context,
                initialText: entry.content,
              );
              if (posted && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isZh ? '已发布到 Chorus ✓' : "Posted to the chorus ✓"),
                    backgroundColor: const Color(0xFF6B8E77),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (entry.emotion != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(entry.emotion!, style: const TextStyle(fontSize: 32)),
              ),
            if (entry.format == EntryFormat.list)
              ..._buildListContent(context, entry, isZh)
            else
              SelectableText(
                entry.content,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: tags.map((t) => TagChip(tag: t, small: true)).toList(),
              ),
            ],
            if (entry.mediaUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              _MediaGrid(mediaUrls: entry.mediaUrls),
            ],
            // Keepsake badge
            const SizedBox(height: 16),
            _KeepsakeBadge(
              entryId: entry.id,
              onEditKeepsake: (card) => _handleEditKeepsake(context, card),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildListContent(
      BuildContext context, Entry entry, bool isZh) {
    final l = AppLocalizations.of(context)!;
    final provider = context.read<EntryProvider>();
    final items = entry.listItems ?? [];
    final doneCount = items.where((i) => i.isDone).length;
    final readOnly = _isPastDate(entry);

    return [
      if (entry.content.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            entry.content,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      if (items.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            l.listDetailSubtitle(doneCount, items.length),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey[500]),
          ),
        ),
      ...items.map((item) => InkWell(
            onTap: readOnly ? null : () => provider.toggleListItem(entry.id, item.id),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(
                    item.isDone ? Icons.check_box : Icons.check_box_outline_blank,
                    size: 22,
                    color: item.isDone
                        ? Colors.grey
                        : readOnly
                            ? Colors.grey[400]
                            : Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.text,
                      style: TextStyle(
                        fontSize: 16,
                        decoration: item.isDone ? TextDecoration.lineThrough : null,
                        color: item.isDone ? Colors.grey : null,
                      ),
                    ),
                  ),
                  if (item.fromPreviousDay) ...[
                    const SizedBox(width: 8),
                    Text(
                      l.fromYesterdayLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          )),
      if (items.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            l.itemsDone(doneCount, items.length),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        ),
    ];
  }

  bool _isPastDate(Entry entry) {
    final today = DateTime.now();
    final entryDay = DateTime(entry.createdAt.year, entry.createdAt.month, entry.createdAt.day);
    final todayDay = DateTime(today.year, today.month, today.day);
    return entryDay.isBefore(todayDay);
  }

  Future<void> _handleSaveAsKeepsake(BuildContext context, Entry entry) async {
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    final tagProvider = context.read<TagProvider>();
    final tags = tagProvider.tags
        .where((t) => entry.tagIds.contains(t.id))
        .map((t) => t.name)
        .toList();
    final photoPath = entry.mediaUrls.isNotEmpty ? entry.mediaUrls.first : null;

    await CardBuilderSheet.show(
      context,
      entryId: entry.id,
      initialContent: entry.content,
      initialEmotion: entry.emotion,
      initialTags: tags,
      initialPhotoPath: photoPath,
      entryDate: entry.createdAt,
    );
  }

  void _handleEditKeepsake(BuildContext context, NoteCard card) {
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    CardBuilderSheet.show(
      context,
      entryId: card.entryIds.isNotEmpty ? card.entryIds.first : null,
      initialContent: card.cardContent ?? '',
      initialEmotion: card.emotion,
      initialTags: card.displayTags,
      entryDate: card.createdAt,
    );
  }
}

class _KeepsakeBadge extends StatelessWidget {
  final String entryId;
  final void Function(NoteCard card) onEditKeepsake;
  const _KeepsakeBadge({required this.entryId, required this.onEditKeepsake});

  @override
  Widget build(BuildContext context) {
    final cardProvider = context.watch<CardProvider>();
    final card = cardProvider.getCardByEntryId(entryId);
    if (card == null) return const SizedBox.shrink();

    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final template = cardProvider.getTemplateById(card.templateId);
    final templateName = template?.displayNameFor(isZh) ?? '';

    return Center(
      child: Semantics(
        identifier: 'badge_keepsake',
        child: ActionChip(
          avatar: const Icon(Icons.photo_album, size: 18),
          label: Text(
            isZh ? '纪念 · $templateName' : 'Keepsake · $templateName',
            style: const TextStyle(fontSize: 13),
          ),
          onPressed: () async {
            final result = await Navigator.push<String>(
              context,
              MaterialPageRoute(
                builder: (_) => CardPreviewScreen(card: card),
              ),
            );
            if (result == 'edit' && context.mounted) {
              onEditKeepsake(card);
            }
          },
        ),
      ),
    );
  }
}

class _MediaGrid extends StatefulWidget {
  final List<String> mediaUrls;
  const _MediaGrid({required this.mediaUrls});

  @override
  State<_MediaGrid> createState() => _MediaGridState();
}

class _MediaGridState extends State<_MediaGrid> {
  late List<Future<String>> _pathFutures;
  final _fileService = FileService();

  @override
  void initState() {
    super.initState();
    _initFutures();
  }

  @override
  void didUpdateWidget(_MediaGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mediaUrls.length != oldWidget.mediaUrls.length ||
        !_listEquals(widget.mediaUrls, oldWidget.mediaUrls)) {
      _initFutures();
    }
  }

  void _initFutures() {
    _pathFutures = widget.mediaUrls.map((url) {
      return url.startsWith('/') ? Future.value(url) : _fileService.getFullPath(url);
    }).toList();
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(widget.mediaUrls.length, (i) {
        final url = widget.mediaUrls[i];
        final isImage = url.toLowerCase().endsWith('.jpg') ||
            url.toLowerCase().endsWith('.jpeg') ||
            url.toLowerCase().endsWith('.png') ||
            url.toLowerCase().endsWith('.heic') ||
            url.toLowerCase().endsWith('.webp');
        return FutureBuilder<String>(
          future: _pathFutures[i],
          builder: (context, snapshot) {
            final fullPath = snapshot.data;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: fullPath != null ? () => OpenFilex.open(fullPath) : null,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: (fullPath != null && isImage)
                      ? Image.file(
                          File(fullPath),
                          fit: BoxFit.contain,
                          width: double.infinity,
                          errorBuilder: (_, _, _) => Container(
                            height: 120,
                            color: Colors.grey[300],
                            child: const Icon(Icons.insert_drive_file, size: 48),
                          ),
                        )
                      : Container(
                          height: 120,
                          color: Colors.grey[300],
                          child: const Icon(Icons.insert_drive_file, size: 48),
                        ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
