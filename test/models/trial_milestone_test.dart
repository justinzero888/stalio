import 'package:flutter_test/flutter_test.dart';
import 'package:blinking/models/trial_milestone.dart';

void main() {
  group('TrialMilestone', () {
    test('wasShown is false when shownAt is null', () {
      final milestone = TrialMilestone(milestone: 'start');
      expect(milestone.wasShown, false);
    });

    test('wasShown is true when shownAt is set', () {
      final milestone = TrialMilestone(
        milestone: 'middle',
        shownAt: DateTime.now(),
      );
      expect(milestone.wasShown, true);
    });

    test('toJson and fromJson round-trip', () {
      final shown = TrialMilestone(
          milestone: 'end', shownAt: DateTime(2026, 5, 8));
      final notShown = TrialMilestone(milestone: 'start');

      expect(
          TrialMilestone.fromJson(shown.toJson()).shownAt?.millisecondsSinceEpoch,
          shown.shownAt?.millisecondsSinceEpoch);
      expect(TrialMilestone.fromJson(notShown.toJson()).shownAt, isNull);
    });
  });
}
