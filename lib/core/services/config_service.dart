import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class KeyConfig {
  final String key;
  final String model;

  KeyConfig({required this.key, this.model = 'qwen/qwen3.5-flash-02-23'});

  factory KeyConfig.fromJson(Map<String, dynamic> json) {
    return KeyConfig(
      key: json['key'] as String,
      model: json['model'] as String? ?? 'qwen/qwen3.5-flash-02-23',
    );
  }

  Map<String, dynamic> toJson() => {'key': key, 'model': model};
}

class ServerConfig {
  final List<KeyConfig> trialKeys;
  final List<KeyConfig> proKeys;

  ServerConfig({
    this.trialKeys = const [],
    this.proKeys = const [],
  });

  bool get hasTrialKeys => trialKeys.isNotEmpty;
  bool get hasProKeys => proKeys.isNotEmpty;

  factory ServerConfig.fromJson(Map<String, dynamic> json) {
    // Support both new format (lists) and legacy format (single key)
    List<KeyConfig> parseKeys(dynamic value) {
      if (value is String && value.isNotEmpty) {
        return [KeyConfig(key: value)];
      }
      if (value is List) {
        return value
            .map((e) => KeyConfig.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    }

    return ServerConfig(
      trialKeys: parseKeys(json['trial_keys'] ?? json['trial_key']),
      proKeys: parseKeys(json['pro_keys'] ?? json['pro_key']),
    );
  }

  Map<String, dynamic> toJson() => {
        'trial_keys': trialKeys.map((k) => k.toJson()).toList(),
        'pro_keys': proKeys.map((k) => k.toJson()).toList(),
      };
}

class ConfigService {
  static const _baseUrl = 'https://blinkingchorus.com/api/config';
  static const _cacheDuration = Duration(hours: 24);

  static ServerConfig? _cached;

  static ServerConfig? get cached => _cached;

  static Future<ServerConfig?> fetch() async {
    final prefs = await SharedPreferences.getInstance();

    final lastFetch = prefs.getString('config_last_fetch');
    if (lastFetch != null) {
      final last = DateTime.tryParse(lastFetch);
      if (last != null &&
          DateTime.now().difference(last) < _cacheDuration) {
        return _loadFromCache(prefs);
      }
    }

    try {
      final response = await http
          .get(Uri.parse(_baseUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final config = ServerConfig.fromJson(data);

        await prefs.setString('config_json', jsonEncode(config.toJson()));
        await prefs.setString(
            'config_last_fetch', DateTime.now().toIso8601String());

        _cached = config;
        debugPrint('[ConfigService] Fetched config: '
            'trial=${config.trialKeys.length} keys, '
            'pro=${config.proKeys.length} keys');
        return config;
      }
    } catch (e) {
      debugPrint('[ConfigService] Fetch failed: $e');
    }

    return _loadFromCache(prefs);
  }

  static ServerConfig? _loadFromCache(SharedPreferences prefs) {
    final json = prefs.getString('config_json');
    if (json != null) {
      try {
        _cached = ServerConfig.fromJson(
            jsonDecode(json) as Map<String, dynamic>);
        return _cached;
      } catch (_) {}
    }
    return null;
  }

  static Future<ServerConfig?> refresh() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('config_last_fetch');
    return fetch();
  }
}
