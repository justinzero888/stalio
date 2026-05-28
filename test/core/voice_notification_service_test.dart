import 'package:flutter_test/flutter_test.dart';
import 'package:blinking/core/services/voice_notification_service.dart';

void main() {
  group('VoiceNotificationService', () {
    test('speak() before init() does not crash', () async {
      // VoiceNotificationService is a static singleton — speak before init
      // should log a warning but not throw
      await VoiceNotificationService.speak('test', language: 'en-US');
      // No exception = pass
    });

    test('stop() before init() does not crash', () async {
      await VoiceNotificationService.stop();
      // No exception = pass
    });

    test('init() can be called multiple times without crash', () async {
      await VoiceNotificationService.init();
      await VoiceNotificationService.init();
      // No exception = pass
    });

    test('speak() after init() does not crash', () async {
      await VoiceNotificationService.init();
      await VoiceNotificationService.speak(
        'Hello voice test',
        language: 'en-US',
      );
      // No exception = pass. Actual TTS depends on platform engine.
    });

    test('speak() with zh-CN language does not crash', () async {
      await VoiceNotificationService.init();
      await VoiceNotificationService.speak(
        '你好',
        language: 'zh-CN',
      );
      // No exception = pass
    });
  });
}
