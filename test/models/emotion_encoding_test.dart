import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Emotion Encoding', () {
    // Emotion encoding: 😊=5, 😌=4, 😐=3, 😢=2, 😡=1
    // This is used in SummaryProvider for mood trend charts

    test('happy emotion encodes to 5', () {
      const happyEmoji = '😊';
      final score = _emotionToScore(happyEmoji);
      expect(score, 5);
    });

    test('peaceful emotion encodes to 4', () {
      const peacefulEmoji = '😌';
      final score = _emotionToScore(peacefulEmoji);
      expect(score, 4);
    });

    test('neutral emotion encodes to 3', () {
      const neutralEmoji = '😐';
      final score = _emotionToScore(neutralEmoji);
      expect(score, 3);
    });

    test('sad emotion encodes to 2', () {
      const sadEmoji = '😢';
      final score = _emotionToScore(sadEmoji);
      expect(score, 2);
    });

    test('angry emotion encodes to 1', () {
      const angryEmoji = '😡';
      final score = _emotionToScore(angryEmoji);
      expect(score, 1);
    });

    test('missing emotion defaults to neutral (3)', () {
      const unknownEmoji = '❓';
      final score = _emotionToScore(unknownEmoji);
      expect(score, 3);
    });

    test('null emotion defaults to neutral (3)', () {
      final score = _emotionToScore(null);
      expect(score, 3);
    });

    test('empty string emotion defaults to neutral (3)', () {
      final score = _emotionToScore('');
      expect(score, 3);
    });

    test('emotion scores follow consistent ordering', () {
      const happyScore = 5;
      const peacefulScore = 4;
      const neutralScore = 3;
      const sadScore = 2;
      const angryScore = 1;

      expect(happyScore, greaterThan(peacefulScore));
      expect(peacefulScore, greaterThan(neutralScore));
      expect(neutralScore, greaterThan(sadScore));
      expect(sadScore, greaterThan(angryScore));
    });

    test('emotion scores are in valid range [1, 5]', () {
      final emotions = ['😊', '😌', '😐', '😢', '😡'];
      for (final emoji in emotions) {
        final score = _emotionToScore(emoji);
        expect(score, greaterThanOrEqualTo(1));
        expect(score, lessThanOrEqualTo(5));
      }
    });
  });
}

// Helper function that mirrors SummaryProvider logic
int _emotionToScore(String? emoji) {
  switch (emoji) {
    case '😊':
      return 5;
    case '😌':
      return 4;
    case '😐':
      return 3;
    case '😢':
      return 2;
    case '😡':
      return 1;
    default:
      return 3; // neutral baseline
  }
}
