import 'package:flutter_test/flutter_test.dart';
import 'package:blinking/models/ai_identity.dart';

void main() {
  group('AiIdentity', () {
    test('creates with correct defaults', () {
      final identity = AiIdentity(updatedAt: DateTime.now());
      expect(identity.avatarEmoji, '\u2726');
      expect(identity.assistantName, 'Companion');
      expect(identity.personalityString, 'Warm and grounded.');
      expect(identity.avatarImagePath, isNull);
    });

    test('toJson and fromJson round-trip', () {
      final identity = AiIdentity(
        avatarEmoji: '🤖',
        assistantName: 'Helper',
        personalityString: 'Friendly and direct.',
        avatarImagePath: '/path/to/image.png',
        updatedAt: DateTime(2026, 5, 8),
      );
      final json = identity.toJson();
      final restored = AiIdentity.fromJson(json);
      expect(restored.avatarEmoji, identity.avatarEmoji);
      expect(restored.assistantName, identity.assistantName);
      expect(restored.personalityString, identity.personalityString);
      expect(restored.avatarImagePath, identity.avatarImagePath);
    });

    test('copyWith updates fields', () {
      final identity = AiIdentity(updatedAt: DateTime(2026, 1, 1));
      final updated = identity.copyWith(
        avatarEmoji: '🌟',
        assistantName: 'New Name',
      );
      expect(updated.avatarEmoji, '🌟');
      expect(updated.assistantName, 'New Name');
      expect(updated.personalityString, identity.personalityString);
      expect(updated.avatarImagePath, identity.avatarImagePath);
    });
  });
}
