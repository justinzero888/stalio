import 'package:flutter_test/flutter_test.dart';
import 'package:blinking/models/ai_call_log.dart';

void main() {
  group('AiCallLog', () {
    test('creates with correct defaults', () {
      final log = AiCallLog(
        id: 'test_id',
        surface: 'A',
        calledAt: DateTime(2026, 5, 8),
      );
      expect(log.surface, 'A');
      expect(log.kept, false);
      expect(log.moodLogId, isNull);
    });

    test('toJson and fromJson round-trip', () {
      final log = AiCallLog(
        id: 'test_id',
        surface: 'B',
        calledAt: DateTime(2026, 5, 8, 14, 30),
        moodLogId: 'mood_123',
        kept: true,
      );
      final json = log.toJson();
      final restored = AiCallLog.fromJson(json);
      expect(restored.id, log.id);
      expect(restored.surface, log.surface);
      expect(restored.calledAt.millisecondsSinceEpoch,
          log.calledAt.millisecondsSinceEpoch);
      expect(restored.moodLogId, log.moodLogId);
      expect(restored.kept, log.kept);
    });

    test('kept field serializes as integer 0/1', () {
      final kept = AiCallLog(
        id: 'a', surface: 'A', calledAt: DateTime.now(), kept: true,
      );
      final notKept = AiCallLog(
        id: 'b', surface: 'A', calledAt: DateTime.now(), kept: false,
      );
      expect(kept.toJson()['kept'], 1);
      expect(notKept.toJson()['kept'], 0);
    });
  });
}
