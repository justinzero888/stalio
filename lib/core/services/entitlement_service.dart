import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'device_service.dart';
import 'device_fingerprint_service.dart';

enum EntitlementState {
  preview,
  restricted,
  paid,
}

enum AISource {
  managed,
  byok,
  none,
}

enum AIButtonVisual {
  active,
  dormant,
  dormantWarn,
  hidden,
  pulsing,
}

class EntitlementService extends ChangeNotifier {
  static const _baseUrl = 'https://blinkingchorus.com/api/entitlement';
  static const _jwtKey = 'entitlement_jwt';
  static const _stateKey = 'entitlement_state';
  static const _previewStartedKey = 'entitlement_preview_started';
  static const _previewDaysKey = 'entitlement_preview_days';

  static const _previewTotalDays = 21;

  SharedPreferences? _prefs;
  String? _jwt;
  EntitlementState _state = EntitlementState.restricted;
  int _previewDaysRemaining = 0;
  bool _initialized = false;
  bool _initInProgress = false;

  Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;

    _jwt = prefs.getString(_jwtKey);
    _state = _parseState(prefs.getString(_stateKey));
    _previewDaysRemaining = prefs.getInt(_previewDaysKey) ?? 0;

    // Apply local logic immediately for all states.
    // Server calls are async and defer notifyListeners() — we want the UI
    // to show the correct state right away.
    _applyLocalPreview();

    // Then try server in background (non-blocking for UI purposes)
    if (_state == EntitlementState.preview && _jwt == null) {
      _callInit(); // fire-and-forget, don't await
    } else if (_jwt != null && _jwt!.isNotEmpty) {
      await _refreshStatus();
    }

    _initialized = true;
    notifyListeners();
  }

  void _applyLocalPreview() {
    if (_state == EntitlementState.restricted || _state == EntitlementState.paid) {
      return;
    }
    final now = DateTime.now();

    final startedStr = _prefs?.getString(_previewStartedKey);
    if (startedStr == null) {
      final savedDays = _prefs?.getInt(_previewDaysKey) ?? 0;
      if (savedDays > 0 && savedDays < _previewTotalDays) {
        final estimatedStart = now.subtract(Duration(days: _previewTotalDays - savedDays));
        _prefs?.setString(_previewStartedKey, estimatedStart.toIso8601String());
      } else {
        _prefs?.setString(_previewStartedKey, now.toIso8601String());
      }
      _previewDaysRemaining = savedDays > 0 && savedDays < _previewTotalDays
          ? savedDays
          : _previewTotalDays;
      _state = EntitlementState.preview;
      _saveState();
      return;
    }

    final started = DateTime.tryParse(startedStr);
    if (started == null) return;

    final daysElapsed = now.difference(started).inDays;
    _previewDaysRemaining = (_previewTotalDays - daysElapsed).clamp(0, _previewTotalDays);

    if (_previewDaysRemaining <= 0) {
      _state = EntitlementState.restricted;
      _previewDaysRemaining = 0;
      _prefs?.setBool('entitlement_was_preview', true);
      _saveState();
      return;
    }

    _state = EntitlementState.preview;
    _prefs?.setBool('entitlement_was_preview', true);
    _saveState();
  }

  Future<void> _callInit() async {
    if (_initInProgress) return;
    _initInProgress = true;

    try {
      final deviceId = await DeviceService.getDeviceId();
      final fingerprint = await DeviceFingerprintService.getFingerprint();
      final body = {'device_id': deviceId};
      if (fingerprint != null) {
        body['device_fingerprint'] = fingerprint;
      }
      final response = await http.post(
        Uri.parse('$_baseUrl/init'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _jwt = data['token'] as String;
        _state = _parseState(data['state'] as String?);
        _previewDaysRemaining = data['preview_duration_days'] ?? _previewTotalDays;
        await _saveState();
      }
    } catch (_) {}

    _initInProgress = false;
    notifyListeners();
  }

  Future<void> _refreshStatus() async {
    if (_jwt == null || _jwt!.isEmpty) return;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/status'),
        headers: {'Authorization': 'Bearer $_jwt'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prevState = _state;
        _state = _parseState(data['state'] as String?);
        _jwt = data['token'] as String? ?? _jwt;
        _previewDaysRemaining = data['preview_days_remaining'] as int? ?? 0;

        if (data['preview_started_at'] != null) {
          await _prefs?.setString(
              _previewStartedKey, data['preview_started_at'] as String);
        }

        if (prevState == EntitlementState.preview && _state == EntitlementState.restricted) {
          await _prefs?.setBool('entitlement_was_preview', true);
        }
        if (_state == EntitlementState.preview) {
          await _prefs?.setBool('entitlement_was_preview', true);
        }

        await _saveState();
      } else if (response.statusCode == 403 || response.statusCode == 404) {
        _jwt = null;
        await _callInit();
      }
    } catch (_) {}

    notifyListeners();
  }

  bool get wasPreview => _prefs?.getBool('entitlement_was_preview') ?? false;

  Future<void> refresh() => _refreshStatus();

  EntitlementState get currentState => _state;

  bool get hasOwnKey {
    if (_prefs == null) return false;
    final jsonStr = _prefs!.getString('llm_providers');
    if (jsonStr == null || jsonStr.isEmpty) return false;
    try {
      final providers = jsonDecode(jsonStr) as List<dynamic>;
      for (final p in providers) {
        if (p is Map) {
          final apiKey = p['apiKey'] as String? ?? '';
          final name = p['name'] as String? ?? '';
          if (apiKey.isNotEmpty && name != 'Trial' && name != '7-Day Trial') {
            return true;
          }
        }
      }
    } catch (_) {}
    return false;
  }

  bool get hasActiveBYOK => hasOwnKey;

  AISource get aiSource {
    // BYOK hidden — always return managed
    if (_state == EntitlementState.preview) return AISource.managed;
    if (_state == EntitlementState.paid) return AISource.managed;
    return AISource.none;
  }

  bool get canUseAI {
    // BYOK hidden — only state-based
    if (_state == EntitlementState.preview) return true;
    if (_state == EntitlementState.paid) return true;
    return false;
  }

  String? get entitlementJwt => _jwt;

  AIButtonVisual get buttonVisual {
    if (_state == EntitlementState.preview) {
      return AIButtonVisual.active;
    }
    if (_state == EntitlementState.restricted) {
      return AIButtonVisual.dormant;
    }
    if (_state == EntitlementState.paid) {
      return AIButtonVisual.active;
    }
    return AIButtonVisual.dormant;
  }

  bool _isBYOKKeyValid() {
    if (!hasActiveBYOK || _prefs == null) return false;
    return _prefs!.getBool('entitlement_byok_validated') ?? true;
  }

  int get previewDaysRemaining => _previewDaysRemaining;
  int get previewDaysTotal => _previewTotalDays;

  bool get isPreviewActive => _state == EntitlementState.preview;
  bool get isRestricted => _state == EntitlementState.restricted;
  bool get isPaid => _state == EntitlementState.paid;

  bool get canAddHabit => _state != EntitlementState.restricted;
  bool get canEditNote => _state != EntitlementState.restricted;
  bool get canBackup => _state != EntitlementState.restricted;
  bool get canExport => _state != EntitlementState.restricted;

  Future<void> _saveState() async {
    if (_prefs == null) return;
    if (_jwt != null) await _prefs!.setString(_jwtKey, _jwt!);
    await _prefs!.setString(_stateKey, _state.name);
    await _prefs!.setInt(_previewDaysKey, _previewDaysRemaining);
  }

  EntitlementState _parseState(String? s) {
    switch (s) {
      case 'paid':
        return EntitlementState.paid;
      case 'restricted':
        return EntitlementState.restricted;
      case 'preview':
      default:
        return EntitlementState.preview;
    }
  }
}
