import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceNotificationService {
  static final _tts = FlutterTts();
  static bool _initialized = false;
  static String _currentLanguage = 'en-US';

  static Future<void> init() async {
    if (_initialized) return;
    try {
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);
      await _tts.setVolume(0.8);
      _initialized = true;
      _log('Initialized (rate=0.45, pitch=1.0, volume=0.8)');
    } catch (e) {
      _log('Init failed: $e');
    }
  }

  static Future<void> speak(String text, {required String language}) async {
    if (!_initialized) {
      _log('speak() called before init — ignoring');
      return;
    }
    try {
      if (language != _currentLanguage) {
        await _tts.setLanguage(language);
        _currentLanguage = language;
      }
      _log('Speaking: "$text" ($language)');
      await _tts.speak(text);
    } catch (e) {
      _log('TTS error: $e');
    }
  }

  static Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  static void _log(String msg) {
    debugPrint('\u{1F50A} [Voice] $msg');
  }
}
