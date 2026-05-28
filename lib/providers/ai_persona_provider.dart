import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import '../core/services/file_service.dart';
import '../models/reflection_style.dart';

/// Holds AI assistant persona settings and notifies listeners on change.
class AiPersonaProvider extends ChangeNotifier {
  String name = 'Kael';
  String personality = '';
  String? avatarPath;
  String styleId = 'kael';

  AiPersonaProvider() {
    _load();
  }

  bool get hasCustomAvatar =>
      avatarPath != null && avatarPath!.isNotEmpty;

  String displayNameFor(bool isZh) {
    final style = ReflectionStyle.byId(styleId);
    return isZh ? style.nameZh : style.name;
  }

  /// Returns the active style's bundled avatar asset path for the given locale.
  /// Falls back to the default asset if the locale-specific variant isn't set.
  String? styleAvatarAssetFor(bool isZh) {
    final style = ReflectionStyle.byId(styleId);
    if (isZh && style.avatarAssetCn != null) return style.avatarAssetCn;
    return style.avatarAsset;
  }

  /// Returns the active style's bundled avatar asset path.
  String? get styleAvatarAsset {
    final style = ReflectionStyle.byId(styleId);
    return style.avatarAsset;
  }

  /// For custom styles, returns the emoji if set.
  String? get customStyleEmoji {
    if (!styleId.startsWith('custom_')) return null;
    return _customStyleEmoji;
  }

  String? _customStyleEmoji;

  /// Returns the file-based custom avatar if set, or null.
  /// Callers should then fall back to [styleAvatarAsset] for a bundled asset,
  /// or the emoji if neither is available.
  String? get resolvedAvatarPath {
    if (hasCustomAvatar) return avatarPath;
    return null;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    styleId = prefs.getString('ai_style_id') ?? 'kael';
    final isZh = prefs.getString('language') == 'zh';

    // Load all custom styles into the model cache
    final customList = prefs.getStringList('ai_custom_styles') ?? [];
    final customStyles = customList
        .map((s) => jsonDecode(s) as Map<String, dynamic>)
        .toList();
    ReflectionStyle.registerCustomStyles(customStyles);

    if (styleId.startsWith('custom_')) {
      final style = ReflectionStyle.byId(styleId);
      name = style.displayName(isZh);
      personality = style.persona(isZh);
      _customStyleEmoji = style.emoji;
      final index = int.tryParse(styleId.split('_').last);
      if (index != null && index < customStyles.length) {
        avatarPath = customStyles[index]['avatarPath'] as String?;
      } else {
        avatarPath = prefs.getString('ai_avatar_path');
      }
    } else {
      final style = ReflectionStyle.byId(styleId);
      final savedName = prefs.getString('ai_assistant_name');
      final savedPersonality = prefs.getString('ai_assistant_personality');
      // Use locale-aware defaults. If saved values exist and differ from ALL
      // built-in defaults, treat them as user customizations from Settings.
      final allNames = ReflectionStyle.presets.expand((s) => [s.name, s.nameZh]).toSet();
      final allPersonas = ReflectionStyle.presets.expand((s) => [s.personaEn, s.personaZh]).toSet();
      name = (savedName != null && !allNames.contains(savedName))
          ? savedName
          : style.displayName(isZh);
      personality = (savedPersonality != null && !allPersonas.contains(savedPersonality))
          ? savedPersonality
          : style.persona(isZh);
      avatarPath = prefs.getString('ai_avatar_path');
    }
    notifyListeners();
  }

  Future<void> reload() => _load();

  /// Sets the active reflection style — updates name, personality, and persists.
  Future<void> setStyle(ReflectionStyle style) async {
    final prefs = await SharedPreferences.getInstance();
    styleId = style.id;
    await prefs.setString('ai_style_id', style.id);

    final isZh = prefs.getString('language') == 'zh';
    name = style.displayName(isZh);
    personality = isZh ? style.personaZh : style.personaEn;

    // Update avatar from custom style data or SharedPreferences
    if (styleId.startsWith('custom_')) {
      final customList = prefs.getStringList('ai_custom_styles') ?? [];
      final index = int.tryParse(styleId.split('_').last);
      if (index != null && index < customList.length) {
        final data = jsonDecode(customList[index]) as Map<String, dynamic>;
        avatarPath = data['avatarPath'] as String?;
      }
    } else {
      avatarPath = prefs.getString('ai_avatar_path');
    }

    await prefs.setString('ai_assistant_name', name);
    await prefs.setString('ai_assistant_personality', personality);
    notifyListeners();
  }

  /// Activates a custom style by persisting it and updating the persona.
  Future<void> setCustomStyle(Map<String, dynamic> json) async {
    final prefs = await SharedPreferences.getInstance();
    final customList = prefs.getStringList('ai_custom_styles') ?? [];
    final index = customList.length;
    final newId = 'custom_$index';
    customList.add(jsonEncode(json));
    await prefs.setStringList('ai_custom_styles', customList);

    styleId = newId;
    await prefs.setString('ai_style_id', newId);
    ReflectionStyle.registerCustomStyles(
        customList.map((s) => jsonDecode(s) as Map<String, dynamic>).toList());

    final style = ReflectionStyle.byId(newId);
    final isZh = prefs.getString('language') == 'zh';
    name = style.name;
    personality = isZh ? style.personaZh : style.personaEn;
    _customStyleEmoji = style.emoji;
    avatarPath = json['avatarPath'] as String?;

    await prefs.setString('ai_assistant_name', name);
    await prefs.setString('ai_assistant_personality', personality);
    notifyListeners();
  }

  Future<void> updateCustomStyle(int index, Map<String, dynamic> json) async {
    final prefs = await SharedPreferences.getInstance();
    final customList = prefs.getStringList('ai_custom_styles') ?? [];
    if (index >= customList.length) return;
    customList[index] = jsonEncode(json);
    await prefs.setStringList('ai_custom_styles', customList);
    ReflectionStyle.registerCustomStyles(
        customList.map((s) => jsonDecode(s) as Map<String, dynamic>).toList());
    // If this was the active custom style, refresh persona
    if (styleId == 'custom_$index') {
      final style = ReflectionStyle.byId(styleId);
      name = style.name;
      _customStyleEmoji = style.emoji;
      avatarPath = json['avatarPath'] as String?;
    }
    notifyListeners();
  }

  Future<void> removeCustomStyle(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final customList = prefs.getStringList('ai_custom_styles') ?? [];
    if (index >= customList.length) return;
    customList.removeAt(index);
    await prefs.setStringList('ai_custom_styles', customList);
    ReflectionStyle.registerCustomStyles(
        customList.map((s) => jsonDecode(s) as Map<String, dynamic>).toList());
    if (styleId == 'custom_$index') {
      await setStyle(ReflectionStyle.byId(ReflectionStyle.defaultStyleId));
    }
    notifyListeners();
  }

  /// Removes the custom style and falls back to default.
  Future<void> clearCustomStyle() async {
    // For backward compatibility, remove all custom styles
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('ai_custom_styles');
    ReflectionStyle.registerCustomStyles([]);
    _customStyleEmoji = null;
    await setStyle(ReflectionStyle.byId(ReflectionStyle.defaultStyleId));
  }

  /// Returns loaded custom styles (for UI display).
  List<Map<String, dynamic>> getCustomStyles() {
    return ReflectionStyle.customCache.values
        .map((s) => s.toJson())
        .toList();
  }

  Future<void> saveNameAndPersonality(
      String newName, String newPersonality) async {
    name = newName;
    personality = newPersonality;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ai_assistant_name', name);
    await prefs.setString('ai_assistant_personality', personality);
    notifyListeners();
  }

  Future<void> setAvatarFromPath(String sourcePath) async {
    final savedRelative = await FileService().saveFile(sourcePath);
    final fullPath = await FileService().getFullPath(savedRelative);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ai_avatar_path', fullPath);
    avatarPath = fullPath;
    notifyListeners();
  }

  Future<void> clearAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('ai_avatar_path');
    avatarPath = null;
    notifyListeners();
  }
}
