import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import '../providers/entry_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/tag_provider.dart';
import '../models/entry.dart';
import '../models/tag.dart';
import '../models/media.dart';
import '../core/services/file_service.dart';
import '../core/config/emotions.dart';
import '../l10n/app_localizations.dart';
import '../screens/settings/settings_screen.dart';
import 'package:open_filex/open_filex.dart';

class AddEntryScreen extends StatefulWidget {
  final Entry? existingEntry;
  const AddEntryScreen({super.key, this.existingEntry});

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _itemController = TextEditingController();
  final FocusNode _itemFocusNode = FocusNode();
  final FileService _fileService = FileService();
  final _uuid = const Uuid();

  final List<Media> _mediaItems = [];
  final Set<String> _selectedTagIds = {};
  Set<String> _suggestedTagIds = {};
  String? _selectedEmotion;
  EntryFormat _selectedFormat = EntryFormat.note;
  final List<ListItem> _listItems = [];

  @override
  void initState() {
    super.initState();
    _loadExistingEntry();
    _textController.addListener(_updateSuggestions);
  }

  bool get _isPastEntry {
    if (widget.existingEntry == null) return false;
    final today = DateTime.now();
    final entryDay = DateTime(
      widget.existingEntry!.createdAt.year,
      widget.existingEntry!.createdAt.month,
      widget.existingEntry!.createdAt.day,
    );
    final todayDay = DateTime(today.year, today.month, today.day);
    return entryDay.isBefore(todayDay);
  }

  Future<void> _loadExistingEntry() async {
    if (widget.existingEntry != null) {
      final e = widget.existingEntry!;
      if (e.format == EntryFormat.list) {
        _selectedFormat = EntryFormat.list;
        _titleController.text = e.content;
        if (e.listItems != null) {
          _listItems.addAll(e.listItems!);
        }
      } else {
        _textController.text = e.content;
      }
      _selectedTagIds.addAll(e.tagIds);
      if (e.emotion != null) {
        setState(() => _selectedEmotion = e.emotion);
      }
      for (final url in e.mediaUrls) {
        String displayPath = url;
        if (!url.startsWith('/')) {
           displayPath = await _fileService.getFullPath(url);
        }
        setState(() {
          _mediaItems.add(Media(
            id: DateTime.now().millisecondsSinceEpoch.toString() + url,
            entryId: e.id,
            type: _getMediaTypeFromUrl(url),
            localPath: displayPath,
          ));
        });
      }
    }
  }

  MediaType _getMediaTypeFromUrl(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('.mp4') || lower.contains('.mov')) return MediaType.video;
    if (lower.contains('.aac') || lower.contains('.m4a') || lower.contains('.mp3')) return MediaType.audio;
    return MediaType.image;
  }

  @override
  void dispose() {
    _textController.dispose();
    _titleController.dispose();
    _itemController.dispose();
    _itemFocusNode.dispose();
    super.dispose();
  }

  void _removeMedia(int index) {
    setState(() {
      _mediaItems.removeAt(index);
    });
  }

  void _toggleTag(String tagId) {
    setState(() {
      if (_selectedTagIds.contains(tagId)) {
        _selectedTagIds.remove(tagId);
      } else {
        _selectedTagIds.add(tagId);
      }
      _suggestedTagIds.remove(tagId);
    });
  }

  void _updateSuggestions() {
    if (!mounted) return;
    final text = _textController.text.toLowerCase();
    final suggested = <String>{};
    final tagProvider = context.read<TagProvider>();
    final tags = tagProvider.tags;

    for (final tag in tags) {
      if (_selectedTagIds.contains(tag.id)) continue;
      final keywords = _tagKeywords(tag);
      for (final kw in keywords) {
        if (text.contains(kw.toLowerCase())) {
          suggested.add(tag.id);
          break;
        }
      }
    }

    if (!_setEquals(_suggestedTagIds, suggested)) {
      setState(() => _suggestedTagIds = suggested);
    }
  }

  bool _setEquals(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }

  List<String> _tagKeywords(Tag tag) {
    switch (tag.id) {
      case 'tag_family':
        return ['家人', 'family', '妈妈', '爸爸', '孩子', '父母', 'mom', 'dad', 'parent', 'child'];
      case 'tag_health':
      case 'tag_wellness':
        return ['健康', '养生', 'health', '运动', '锻炼', '跑步', '冥想', 'exercise', 'run', 'meditate', '瑜伽', 'yoga', '睡眠', 'sleep'];
      case 'tag_learning':
        return ['学习', 'learn', '读', 'read', '书', 'book', '课程', 'course', '研究', 'study', '知识', 'knowledge'];
      case 'tag_insight':
        return ['领悟', 'insight', '感悟', '反思', '思考', '启发', 'reflect', 'think', 'realize'];
      case 'tag_gratitude':
        return ['感恩', 'gratitude', '感谢', '谢谢', 'thank', 'appreciate', '感激'];
      case 'tag_daily':
        return ['日常', 'daily', '今天', 'today', '每天', 'everyday', '早上', 'morning', '晚上', 'evening'];
      case 'tag_private':
        return ['私密', 'private', '秘密', 'secret', '个人', 'personal'];
      default:
        return [tag.name.toLowerCase(), tag.nameEn.toLowerCase()];
    }
  }

  void _switchFormat(EntryFormat newFormat) {
    if (newFormat == _selectedFormat) return;

    if (newFormat == EntryFormat.list && widget.existingEntry == null) {
      final entryProvider = context.read<EntryProvider>();
      final todayLists = entryProvider.getEntriesForDate(DateTime.now())
          .where((e) => e.format == EntryFormat.list)
          .toList();
      if (todayLists.isNotEmpty) {
        final existingList = todayLists.first;
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.listAlreadyExistsHint),
            duration: const Duration(milliseconds: 800),
          ),
        );
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (_, _, _) => AddEntryScreen(existingEntry: existingList),
                transitionDuration: const Duration(milliseconds: 300),
                transitionsBuilder: (_, animation, _, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
            );
          }
        });
        return;
      }
    }

    setState(() {
      if (_selectedFormat == EntryFormat.note && newFormat == EntryFormat.list) {
        final noteText = _textController.text;
        final lineBreak = noteText.indexOf('\n');
        final titleText = lineBreak > 0
            ? noteText.substring(0, lineBreak < 200 ? lineBreak : 200)
            : noteText.substring(0, noteText.length < 200 ? noteText.length : 200);
        _titleController.text = titleText;
        _textController.clear();
      } else if (_selectedFormat == EntryFormat.list && newFormat == EntryFormat.note) {
        final bodyLines = _listItems.map((item) => '- ${item.text}').join('\n');
        _textController.text = _titleController.text.isNotEmpty
            ? '${_titleController.text}\n\n$bodyLines'
            : bodyLines;
        _titleController.clear();
        _listItems.clear();
      }
      _selectedFormat = newFormat;
    });
  }

  void _addListItem() {
    final text = _itemController.text.trim();
    if (text.isEmpty || text.length > 200) return;
    setState(() {
      _listItems.add(ListItem(
        id: _uuid.v4(),
        text: text,
        isDone: false,
        sortOrder: _listItems.length,
      ));
      _itemController.clear();
    });
    _itemFocusNode.requestFocus();
  }

  void _removeListItem(int index) {
    setState(() {
      _listItems.removeAt(index);
      for (var i = 0; i < _listItems.length; i++) {
        _listItems[i] = _listItems[i].copyWith(sortOrder: i);
      }
    });
  }

  void _onItemReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _listItems.removeAt(oldIndex);
      _listItems.insert(newIndex, item);
      for (var i = 0; i < _listItems.length; i++) {
        _listItems[i] = _listItems[i].copyWith(sortOrder: i);
      }
    });
  }

  String _moodLabel(BuildContext context, String emoji) {
    final l = AppLocalizations.of(context)!;
    switch (emoji) {
      case '😊': return l.moodHappy;
      case '😢': return l.moodSad;
      case '😡': return l.moodAngry;
      case '😰': return l.moodAnxious;
      case '😴': return l.moodTired;
      case '🤩': return l.moodExcited;
      case '😌': return l.moodCalm;
      case '😤': return l.moodFrustrated;
      case '🥰': return l.moodLoving;
      case '😐': return l.moodNeutral;
      default: return emoji;
    }
  }

  Future<void> _saveEntry() async {
    final l = AppLocalizations.of(context)!;
    final isList = _selectedFormat == EntryFormat.list;

    if (isList) {
      if (_listItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.listSaveDisabledHint)),
        );
        return;
      }
    } else {
      if (_textController.text.trim().isEmpty && _mediaItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.addContentRequired)),
        );
        return;
      }
    }

    final entryProvider = context.read<EntryProvider>();

    final List<String> persistentMediaUrls = [];
    for (final media in _mediaItems) {
      if (media.localPath == null) continue;
      if (media.localPath!.startsWith('media/')) {
        persistentMediaUrls.add(media.localPath!);
      } else {
        try {
          final relativePath = await _fileService.saveFile(media.localPath!);
          persistentMediaUrls.add(relativePath);
        } catch (e) {
          debugPrint('Error persisting file: $e');
          persistentMediaUrls.add(media.localPath!);
        }
      }
    }

    String content = isList
        ? (_titleController.text.trim().isEmpty
            ? _defaultListTitle()
            : _titleController.text.trim())
        : _textController.text.trim();

    if (widget.existingEntry != null) {
      final today = DateTime.now();
      final entryDay = DateTime(
        widget.existingEntry!.createdAt.year,
        widget.existingEntry!.createdAt.month,
        widget.existingEntry!.createdAt.day,
      );
      final todayDay = DateTime(today.year, today.month, today.day);
      if (entryDay.isBefore(todayDay)) {
        if (mounted) {
          Navigator.pop(context);
        }
        return;
      }

      await entryProvider.updateEntry(
        widget.existingEntry!.copyWith(
          content: content,
          tagIds: _selectedTagIds.toList(),
          mediaUrls: persistentMediaUrls,
          updatedAt: DateTime.now(),
          emotion: _selectedEmotion,
          clearEmotion: _selectedEmotion == null,
          format: _selectedFormat,
          listItems: isList ? List.from(_listItems) : null,
          clearListItems: !isList,
        ),
      );
    } else {
      await entryProvider.addEntry(
        type: EntryType.freeform,
        content: content,
        tagIds: _selectedTagIds.toList(),
        mediaUrls: persistentMediaUrls,
        emotion: _selectedEmotion,
        format: _selectedFormat,
        listItems: isList ? _listItems : null,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(widget.existingEntry != null
                ? l.memoryUpdated
                : l.memorySaved)),
      );
      Navigator.pop(context);
    }
  }

  String _defaultListTitle() {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute.toString().padLeft(2, '0');
    final amPm = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[now.month - 1]} ${now.day}, $displayHour:$minute $amPm';
  }

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final l = AppLocalizations.of(context)!;
    final isList = _selectedFormat == EntryFormat.list;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingEntry != null
            ? (_isPastEntry
                ? l.viewMemory
                : l.editMemory)
            : l.addMemory),
        actions: [
          if (!_isPastEntry)
            Semantics(
              identifier: 'btn_entry_save',
              child: IconButton(
                icon: const Icon(Icons.check, size: 28),
                onPressed: _saveEntry,
                tooltip: 'Save',
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isPastEntry)
              SegmentedButton<EntryFormat>(
                segments: [
                  ButtonSegment(value: EntryFormat.note, label: Text(l.noteFormat)),
                  ButtonSegment(value: EntryFormat.list, label: Text(l.listFormat)),
                ],
                selected: {_selectedFormat},
                onSelectionChanged: (format) => _switchFormat(format.first),
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            if (!_isPastEntry) const SizedBox(height: 16),
            if (isList) ..._buildListMode(l) else ..._buildNoteMode(l),
            if (!_isPastEntry) ...[
              const SizedBox(height: 16),
              _buildTagSection(l),
              const SizedBox(height: 16),
              ..._buildSharedSections(l),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildNoteMode(AppLocalizations l) {
    return [
      MergeSemantics(child: Semantics(
        identifier: 'input_entry_body',
        textField: true,
        child: TextField(
          controller: _textController,
          readOnly: _isPastEntry,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: l.addContentPrompt,
          filled: true,
          fillColor: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 1.5,
            ),
          ),
        ),
      ))),
    ];
  }

  List<Widget> _buildListMode(AppLocalizations l) {
    return [
      TextField(
        controller: _titleController,
        readOnly: _isPastEntry,
        decoration: InputDecoration(
          hintText: l.listTitleHint,
          filled: true,
          fillColor: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 1.5,
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      if (_listItems.isNotEmpty && !_isPastEntry)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            l.listEditHint,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.grey[500],
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      if (!_isPastEntry)
        Row(
        children: [
          Expanded(
            child: Semantics(
              identifier: 'input_checklist_item',
              child: TextField(
                controller: _itemController,
                focusNode: _itemFocusNode,
                decoration: InputDecoration(
                  hintText: l.listItemHint,
                filled: true,
                fillColor: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.5,
                  ),
                ),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _addListItem(),
            ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: _addListItem,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      if (_listItems.isNotEmpty) ...[
        const SizedBox(height: 8),
        SizedBox(
          height: (_listItems.length * 48.0).clamp(0, 240),
          child: ReorderableListView.builder(
            shrinkWrap: true,
            itemCount: _listItems.length,
            onReorder: _onItemReorder,
            buildDefaultDragHandles: false,
            itemBuilder: (context, index) {
              final item = _listItems[index];
              return ListTile(
                key: ValueKey(item.id),
                dense: true,
                leading: GestureDetector(
                  onTap: _isPastEntry ? null : () {
                    setState(() {
                      _listItems[index] = item.copyWith(isDone: !item.isDone);
                    });
                  },
                  child: Icon(
                    item.isDone ? Icons.check_box : Icons.check_box_outline_blank,
                    size: 22,
                    color: item.isDone
                        ? Colors.grey
                        : _isPastEntry
                            ? Colors.grey[400]
                            : Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          decoration: item.isDone ? TextDecoration.lineThrough : null,
                          color: item.isDone ? Colors.grey : null,
                        ),
                      ),
                    ),
                    if (item.fromPreviousDay)
                      Text(
                        AppLocalizations.of(context)!.fromYesterdayLabel,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
                trailing: _isPastEntry
                    ? null
                    : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_handle, size: 24, color: Colors.grey),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => _removeListItem(index),
                      child: const Icon(Icons.close, size: 18, color: Colors.grey),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ];
  }

  List<Widget> _buildSharedSections(AppLocalizations l) {
    return [
      const SizedBox(height: 16),
      if (_mediaItems.isNotEmpty) ...[
        Text(
          l.media,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _mediaItems.length,
            itemBuilder: (context, index) {
              final media = _mediaItems[index];
              return _MediaPreview(
                media: media,
                onRemove: () => _removeMedia(index),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
      Text(
        l.mood,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      SizedBox(
        height: 44,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: kDefaultEmotions.map((emoji) {
              final isSelected = _selectedEmotion == emoji;
              final label = _moodLabel(context, emoji);
              return MergeSemantics(
                child: Semantics(
                  label: label,
                  button: true,
                  selected: isSelected,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedEmotion = isSelected ? null : emoji;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected
                            ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                            : null,
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
      if (_selectedEmotion != null)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '$_selectedEmotion  ${_moodLabel(context, _selectedEmotion!)}',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
    ];
  }

  Widget _buildTagSection(AppLocalizations l) {
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l.tags,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              tooltip: l.manageTags,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SettingsScreen(initialTab: 1),
                  ),
                );
              },
            ),
          ],
        ),
        if (_suggestedTagIds.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            isZh ? '建议标签' : 'Suggested',
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Consumer<TagProvider>(
            builder: (context, tagProvider, child) {
              final suggested = tagProvider.tags.where((t) => _suggestedTagIds.contains(t.id));
              return Wrap(
                spacing: 8,
                runSpacing: 4,
                children: suggested.map((tag) {
                  final isSelected = _selectedTagIds.contains(tag.id);
                  final colorValue = int.parse(tag.color.substring(1), radix: 16) + 0xFF000000;
                  return FilterChip(
                    label: Text(tag.displayName(isZh), style: const TextStyle(fontSize: 12)),
                    selected: isSelected,
                    onSelected: (_) => _toggleTag(tag.id),
                    backgroundColor: Color(colorValue).withValues(alpha: 0.1),
                    selectedColor: Color(colorValue).withValues(alpha: 0.3),
                    avatar: const Icon(Icons.auto_awesome, size: 14, color: Colors.amber),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
        ],
        const SizedBox(height: 8),
        Consumer<TagProvider>(
          builder: (context, tagProvider, child) {
            final tags = tagProvider.tags.where((t) => t.id != '' && !_suggestedTagIds.contains(t.id));
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags.map((tag) {
                final isSelected = _selectedTagIds.contains(tag.id);
                final colorValue = int.parse(tag.color.substring(1), radix: 16) + 0xFF000000;
                return FilterChip(
                  label: Text(tag.displayName(isZh)),
                  selected: isSelected,
                  onSelected: (_) => _toggleTag(tag.id),
                  backgroundColor: Color(colorValue).withValues(alpha: 0.2),
                  selectedColor: Color(colorValue),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _MediaPreview extends StatelessWidget {
  final Media media;
  final VoidCallback onRemove;

  const _MediaPreview({
    required this.media,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          GestureDetector(
            onTap: () {
              if (media.localPath != null) {
                OpenFilex.open(media.localPath!);
              }
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildPreview(),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (media.localPath == null) {
      return Container(
        width: 100,
        height: 100,
        color: Colors.grey,
        child: const Icon(Icons.error),
      );
    }
    
    switch (media.type) {
      case MediaType.image:
        return Image.file(
          File(media.localPath!),
          width: 100,
          height: 100,
          fit: BoxFit.cover,
        );
      case MediaType.video:
        return Container(
          width: 100,
          height: 100,
          color: Colors.black12,
          child: const Icon(Icons.play_circle_outline, size: 40),
        );
      case MediaType.audio:
        return Container(
          width: 100,
          height: 100,
          color: Colors.black12,
          child: const Icon(Icons.audiotrack, size: 40),
        );
      case MediaType.text:
        return Container(
          width: 100,
          height: 100,
          color: Colors.black12,
          child: const Icon(Icons.text_fields, size: 40),
        );
    }
  }
}
