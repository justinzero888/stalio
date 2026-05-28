import 'package:flutter_test/flutter_test.dart';
import 'package:blinking/core/services/llm_service.dart';

void main() {
  group('LlmException.friendlyMessage', () {
    // Ensure every error type returns a non-empty message in both locales,
    // and that Chinese / English variants are distinct from each other.

    for (final type in LlmErrorType.values) {
      test('$type returns non-empty strings in both languages', () {
        final ex = LlmException('raw: $type', type);

        final zh = ex.friendlyMessage(true);
        final en = ex.friendlyMessage(false);

        expect(zh, isNotEmpty, reason: '$type Chinese message must not be empty');
        expect(en, isNotEmpty, reason: '$type English message must not be empty');
        expect(zh, isNot(equals(en)),
            reason: '$type messages must differ between languages');
      });
    }

    test('noApiKey — guides user to Settings in English', () {
      final ex = LlmException('no key', LlmErrorType.noApiKey);
      expect(ex.friendlyMessage(false), contains('Settings'));
    });

    test('noApiKey — guides user to 设置 in Chinese', () {
      final ex = LlmException('no key', LlmErrorType.noApiKey);
      expect(ex.friendlyMessage(true), contains('设置'));
    });

    test('invalidApiKey — mentions invalid/expired in English', () {
      final ex = LlmException('401', LlmErrorType.invalidApiKey);
      final msg = ex.friendlyMessage(false).toLowerCase();
      expect(msg, anyOf(contains('invalid'), contains('expired')));
    });

    test('rateLimited — mentions wait/quota in English', () {
      final ex = LlmException('429', LlmErrorType.rateLimited);
      final msg = ex.friendlyMessage(false).toLowerCase();
      expect(msg, anyOf(contains('wait'), contains('quota'), contains('rate')));
    });

    test('networkError — mentions connection in English', () {
      final ex = LlmException('socket', LlmErrorType.networkError);
      final msg = ex.friendlyMessage(false).toLowerCase();
      expect(msg, contains('connection'));
    });

    // Regression: v1.1.0 beta UAT — AI returned network error in English UI
    // because INTERNET permission was missing from AndroidManifest. Once the
    // permission was added, the friendlyMessage was the user-facing string.
    // This test ensures the English network-error message is coherent for users.
    test('networkError English message is user-friendly (no raw exception text)', () {
      final ex = LlmException('Network error: SocketException: ...', LlmErrorType.networkError);
      final msg = ex.friendlyMessage(false);

      // Should NOT leak internal exception details to the user
      expect(msg, isNot(contains('SocketException')));
      expect(msg, isNot(contains('Network error:')));
    });

    test('timeout — mentions timed out in English', () {
      final ex = LlmException('timeout', LlmErrorType.timeout);
      expect(ex.friendlyMessage(false).toLowerCase(), contains('timed out'));
    });

    test('emptyResponse — mentions empty/retry in English', () {
      final ex = LlmException('empty', LlmErrorType.emptyResponse);
      final msg = ex.friendlyMessage(false).toLowerCase();
      expect(msg, anyOf(contains('empty'), contains('try again')));
    });

    test('unknown — generic retry message in both languages', () {
      final ex = LlmException('?', LlmErrorType.unknown);
      expect(ex.friendlyMessage(false).toLowerCase(), contains('try again'));
      expect(ex.friendlyMessage(true), contains('重试'));
    });

    test('default type is unknown when not supplied', () {
      final ex = LlmException('bare');
      expect(ex.type, LlmErrorType.unknown);
    });

    test('toString contains type and message', () {
      final ex = LlmException('msg', LlmErrorType.rateLimited);
      expect(ex.toString(), contains('rateLimited'));
      expect(ex.toString(), contains('msg'));
    });
  });
}
