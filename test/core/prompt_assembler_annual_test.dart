import 'package:flutter_test/flutter_test.dart';
import 'package:blinking/core/services/prompt_assembler.dart';
import 'package:blinking/models/entry.dart';

Entry _entry({
  required String id,
  required DateTime date,
  String? emotion,
  String content = 'Sample content',
}) {
  return Entry(
    id: id,
    type: EntryType.freeform,
    content: content,
    createdAt: date,
    updatedAt: date,
    emotion: emotion,
  );
}

void main() {
  group('PromptAssembler.selectAnnualSamples', () {
    test('returns empty for empty input', () {
      expect(PromptAssembler.selectAnnualSamples([], 2026).length, 0);
    });

    test('filters entries by year only', () {
      final entries = [
        _entry(id: '1', date: DateTime(2026, 1, 5)),
        _entry(id: '2', date: DateTime(2025, 6, 10)),
        _entry(id: '3', date: DateTime(2026, 3, 20)),
        _entry(id: '4', date: DateTime(2024, 12, 31)),
      ];
      final result = PromptAssembler.selectAnnualSamples(entries, 2026);
      expect(result.map((e) => e.id), ['1', '3']);
    });

    test('selects up to 2 entries per month', () {
      final List<Entry> entries = [];
      for (var i = 0; i < 5; i++) {
        entries.add(_entry(
          id: 'jan_$i',
          date: DateTime(2026, 1, i + 1),
          content: 'Content $i',
        ));
      }
      for (var i = 0; i < 3; i++) {
        entries.add(_entry(
          id: 'feb_$i',
          date: DateTime(2026, 2, i + 1),
          content: 'Content $i',
        ));
      }
      final result = PromptAssembler.selectAnnualSamples(entries, 2026);
      final janEntries = result.where((e) => e.id.startsWith('jan_')).toList();
      final febEntries = result.where((e) => e.id.startsWith('feb_')).toList();
      expect(janEntries.length, 2);
      expect(febEntries.length, 2);
    });

    test('returns max 24 samples (2 per month x 12)', () {
      final List<Entry> entries = [];
      for (var month = 1; month <= 12; month++) {
        for (var day = 1; day <= 5; day++) {
          entries.add(_entry(
            id: '${month}_$day',
            date: DateTime(2026, month, day),
            content: 'Content for month $month day $day',
          ));
        }
      }
      final result = PromptAssembler.selectAnnualSamples(entries, 2026);
      expect(result.length, 24);
    });

    test('returns fewer than 2 for months with only 1 entry', () {
      final entries = [
        _entry(id: 'jan_1', date: DateTime(2026, 1, 5)),
      ];
      final result = PromptAssembler.selectAnnualSamples(entries, 2026);
      expect(result.length, 1);
      expect(result.first.id, 'jan_1');
    });

    test('entries with emotions get a +1 bonus in sorting score', () {
      // Score = (has_emotion ? 1 : 0) + content.length
      // Long content (>1 char diff) will outweigh the emotion bonus.
      // With equal-length content, the one with emotion wins.
      final entries = [
        _entry(id: 'no_emo', date: DateTime(2026, 1, 1), emotion: null, content: 'AAAA'),
        _entry(id: 'has_emo', date: DateTime(2026, 1, 2), emotion: '😊', content: 'AAAA'),
      ];
      final result = PromptAssembler.selectAnnualSamples(entries, 2026);
      // Same content length (4), has_emo gets +1 → score 5 vs 4
      expect(result.first.id, 'has_emo');
    });

    test('content length dominates emotion bonus when lengths differ significantly', () {
      final entries = [
        _entry(id: 'no_emo', date: DateTime(2026, 1, 1), emotion: null, content: 'A very long content entry here'),
        _entry(id: 'has_emo', date: DateTime(2026, 1, 2), emotion: '😊', content: 'Hi'),
      ];
      final result = PromptAssembler.selectAnnualSamples(entries, 2026);
      // no_emo: length 31, score 31; has_emo: length 2, score 3
      expect(result.first.id, 'no_emo');
    });

    test('among same-emotion entries, picks longer content first', () {
      final entries = [
        _entry(id: 'short', date: DateTime(2026, 1, 1), emotion: '😊', content: 'Hi'),
        _entry(id: 'long', date: DateTime(2026, 1, 2), emotion: '😊', content: 'A much longer piece of content that should rank higher'),
      ];
      final result = PromptAssembler.selectAnnualSamples(entries, 2026);
      expect(result.first.id, 'long');
    });

    test('skips months with no entries entirely', () {
      final entries = [
        _entry(id: 'jan', date: DateTime(2026, 1, 10)),
        _entry(id: 'dec', date: DateTime(2026, 12, 25)),
      ];
      final result = PromptAssembler.selectAnnualSamples(entries, 2026);
      expect(result.map((e) => e.id).toSet(), {'jan', 'dec'});
      expect(result.length, 2);
    });

    test('handles entries spanning midnight boundary correctly', () {
      final entries = [
        _entry(id: 'jan31', date: DateTime(2026, 1, 31, 23, 59)),
        _entry(id: 'feb1', date: DateTime(2026, 2, 1, 0, 1)),
      ];
      final result = PromptAssembler.selectAnnualSamples(entries, 2026);
      final janEntry = result.firstWhere((e) => e.id == 'jan31');
      final febEntry = result.firstWhere((e) => e.id == 'feb1');
      expect(janEntry.createdAt.month, 1);
      expect(febEntry.createdAt.month, 2);
    });

    test('handles years with zero entries', () {
      final entries = [
        _entry(id: '1', date: DateTime(2025, 6, 1)),
      ];
      expect(PromptAssembler.selectAnnualSamples(entries, 2026).length, 0);
    });
  });

  group('PromptAssembler.maxTokensForAnnual', () {
    test('returns 500', () {
      expect(PromptAssembler.maxTokensForAnnual(), 500);
    });
  });

  group('PromptAssembler.assembleAnnualReflectionPrompt', () {
    final samples = [
      _entry(id: '1', date: DateTime(2026, 1, 15), emotion: '😊', content: 'Had a great day at the park'),
      _entry(id: '2', date: DateTime(2026, 3, 10), emotion: '😢', content: 'Feeling down today'),
      _entry(id: '3', date: DateTime(2026, 6, 5), emotion: null, content: 'A quiet evening with thoughts'),
    ];

    test('English prompt contains all required sections', () {
      final prompt = PromptAssembler.assembleAnnualReflectionPrompt(
        samples: samples,
        personalityString: 'Warm and grounded.',
        year: 2026,
        isZh: false,
      );

      expect(prompt, contains('You are a thoughtful companion inside a journaling app.'));
      expect(prompt, contains('3 representative journal entries'));
      expect(prompt, contains('2026'));
      expect(prompt, contains('1. Identifies 2-3 themes that span the year'));
      expect(prompt, contains('2. Notes emotional shifts across seasons'));
      expect(prompt, contains('3. Highlights one personal growth arc'));
      expect(prompt, contains('4. Ends with a forward-looking reflection'));
      expect(prompt, contains('5. Keep it to 8-12 sentences'));
      expect(prompt, contains('Voice instruction:'));
      expect(prompt, contains('"Warm and grounded."'));
      expect(prompt, contains('Annual journal samples:'));
    });

    test('Chinese prompt contains all required sections', () {
      final prompt = PromptAssembler.assembleAnnualReflectionPrompt(
        samples: samples,
        personalityString: '温暖而踏实。',
        year: 2026,
        isZh: true,
      );

      expect(prompt, contains('你是日记应用中的一位深思熟虑的伙伴。'));
      expect(prompt, contains('3'));
      expect(prompt, contains('2026'));
      expect(prompt, contains('1. 找出2-3个贯穿全年的主题'));
      expect(prompt, contains('2. 注意情绪在不同季节的变化'));
      expect(prompt, contains('3. 强调一条个人成长弧线'));
      expect(prompt, contains('4. 以展望未来作为结尾'));
      expect(prompt, contains('5. 控制在 8-12 句话以内'));
      expect(prompt, contains('年度日记样本：'));
      expect(prompt, contains('"温暖而踏实。"'));
    });

    test('entry format is [MM/DD emotion] content', () {
      final prompt = PromptAssembler.assembleAnnualReflectionPrompt(
        samples: samples,
        personalityString: 'test',
        year: 2026,
        isZh: false,
      );

      expect(prompt, contains('[1/15 😊] Had a great day at the park'));
      expect(prompt, contains('[3/10 😢] Feeling down today'));
      expect(prompt, contains('[6/5 ] A quiet evening with thoughts'));
    });

    test('number of entries shown matches samples count', () {
      final singleSample = [_entry(id: '1', date: DateTime(2026, 5, 1), emotion: '😊', content: 'Hello')];
      final prompt = PromptAssembler.assembleAnnualReflectionPrompt(
        samples: singleSample,
        personalityString: 'test',
        year: 2026,
        isZh: false,
      );

      expect(prompt, contains('1 representative journal entries'));
    });

    test('personality string is included as Voice instruction', () {
      final prompt = PromptAssembler.assembleAnnualReflectionPrompt(
        samples: samples,
        personalityString: 'Stoic and philosophical.',
        year: 2026,
        isZh: false,
      );

      expect(prompt, contains('"Stoic and philosophical."'));
    });
  });
}
