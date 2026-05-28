import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/card_folder.dart';
import '../models/card_template.dart';
import '../models/note_card.dart';
import '../core/services/storage_service.dart';

/// Provider for card folders, templates and note cards
class CardProvider extends ChangeNotifier {
  final StorageService _storage;
  final _uuid = const Uuid();

  List<CardFolder> _folders = [];
  List<CardTemplate> _templates = [];
  List<NoteCard> _cards = [];
  bool _isLoading = false;

  CardProvider(this._storage);

  // Getters
  List<CardFolder> get folders => _folders;
  List<CardTemplate> get templates => _templates
      .where((t) => t.isBuiltIn || t.customImagePath != null || t.backgroundImagePath != null)
      .toList();
  List<NoteCard> get cards => _cards;
  bool get isLoading => _isLoading;

  /// Load all data from storage
  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _folders = await _storage.getCardFolders();
      _templates = await _storage.getTemplates();
      _cards = await _storage.getNoteCards();
    } catch (e) {
      debugPrint('CardProvider.load error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  // ---- Note Cards ----

  Future<NoteCard> addCard({
    required List<String> entryIds,
    required String templateId,
    required String folderId,
    String? renderedImagePath,
    String? aiSummary,
    String? richContent,
    String? cardContent,
    String? emotion,
    List<String>? displayTags,
    bool showMood = true,
    bool showDate = true,
    bool showTags = true,
    bool showFooter = true,
    String? templateOverrides,
  }) async {
    final now = DateTime.now();
    final card = NoteCard(
      id: _uuid.v4(),
      entryIds: entryIds,
      templateId: templateId,
      folderId: folderId,
      renderedImagePath: renderedImagePath,
      aiSummary: aiSummary,
      richContent: richContent,
      cardContent: cardContent,
      emotion: emotion,
      displayTags: displayTags,
      showMood: showMood,
      showDate: showDate,
      showTags: showTags,
      showFooter: showFooter,
      templateOverrides: templateOverrides,
      createdAt: now,
      updatedAt: now,
    );
    await _storage.addNoteCard(card);
    _cards.insert(0, card);
    notifyListeners();
    return card;
  }

  Future<void> updateCard(NoteCard card) async {
    final index = _cards.indexWhere((c) => c.id == card.id);
    if (index != -1) {
      final oldPath = _cards[index].renderedImagePath;
      final newPath = card.renderedImagePath;
      if (oldPath != null && oldPath != newPath) {
        final file = File(oldPath);
        if (await file.exists()) await file.delete();
      }
    }
    await _storage.updateNoteCard(card);
    if (index != -1) {
      _cards[index] = card;
      notifyListeners();
    }
  }

  Future<void> deleteCard(String id) async {
    final card = _cards.where((c) => c.id == id).firstOrNull;
    final imagePath = card?.renderedImagePath;
    await _storage.deleteNoteCard(id);
    _cards.removeWhere((c) => c.id == id);
    if (imagePath != null) {
      final file = File(imagePath);
      if (await file.exists()) await file.delete();
    } else {
      final docDir = await getApplicationDocumentsDirectory();
      final deterministicPath = '${docDir.path}/cards/$id.png';
      final determFile = File(deterministicPath);
      if (await determFile.exists()) await determFile.delete();
    }
    notifyListeners();
  }

  List<NoteCard> getCardsInFolder(String folderId) {
    return _cards.where((c) => c.folderId == folderId).toList();
  }

  /// Returns the first card linked to the given entry, or null if none.
  NoteCard? getCardByEntryId(String entryId) {
    return _cards.where((c) => c.entryIds.contains(entryId)).firstOrNull;
  }

  // ---- Folders ----

  Future<void> addFolder(String name, String icon) async {
    final folder = CardFolder(
      id: _uuid.v4(),
      name: name,
      icon: icon,
      createdAt: DateTime.now(),
    );
    await _storage.addCardFolder(folder);
    _folders.add(folder);
    notifyListeners();
  }

  Future<void> updateFolder(CardFolder folder) async {
    await _storage.updateCardFolder(folder);
    final index = _folders.indexWhere((f) => f.id == folder.id);
    if (index != -1) {
      _folders[index] = folder;
      notifyListeners();
    }
  }

  Future<void> deleteFolder(String id) async {
    final cardsInFolder = _cards.where((c) => c.folderId == id).toList();
    final docDir = await getApplicationDocumentsDirectory();
    for (final card in cardsInFolder) {
      final imagePath = card.renderedImagePath;
      if (imagePath != null) {
        final file = File(imagePath);
        if (await file.exists()) await file.delete();
      }
      final deterministicPath = '${docDir.path}/cards/${card.id}.png';
      if (deterministicPath != imagePath) {
        final determFile = File(deterministicPath);
        if (await determFile.exists()) await determFile.delete();
      }
    }
    await _storage.deleteCardFolder(id);
    _folders.removeWhere((f) => f.id == id);
    _cards.removeWhere((c) => c.folderId == id);
    notifyListeners();
  }

  // ---- Templates ----

  Future<void> addTemplate(CardTemplate template) async {
    await _storage.addTemplate(template);
    _templates.add(template);
    notifyListeners();
  }

  Future<void> updateTemplate(CardTemplate template) async {
    if (template.isBuiltIn) return;
    final oldTemplate = _templates.where((t) => t.id == template.id).firstOrNull;
    final oldPath = oldTemplate?.customImagePath;
    final newPath = template.customImagePath;
    if (oldPath != null && oldPath != newPath) {
      final file = File(oldPath);
      if (await file.exists()) await file.delete();
    }
    await _storage.updateTemplate(template);
    final index = _templates.indexWhere((t) => t.id == template.id);
    if (index != -1) {
      _templates[index] = template;
      notifyListeners();
    }
  }

  Future<void> deleteTemplate(String id) async {
    final template = _templates.firstWhere((t) => t.id == id,
        orElse: () => throw Exception('Template not found'));
    if (template.isBuiltIn) return;
    final customPath = template.customImagePath;
    await _storage.deleteTemplate(id);
    _templates.removeWhere((t) => t.id == id);
    if (customPath != null) {
      final file = File(customPath);
      if (await file.exists()) await file.delete();
    }
    notifyListeners();
  }

  /// Get template by id, returns null if not found
  CardTemplate? getTemplateById(String id) {
    try {
      return _templates.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Test-only: seeds the internal card list without touching storage.
  @visibleForTesting
  void seedForTest(List<NoteCard> cards) {
    _cards = List.of(cards);
  }

  /// Test-only: marks provider as loaded without touching storage.
  @visibleForTesting
  void loadForTest() {
    _isLoading = false;
  }

  /// Test-only: seeds the internal template list without touching storage.
  @visibleForTesting
  void seedTemplatesForTest(List<CardTemplate> templates) {
    _templates = List.of(templates);
  }
}
