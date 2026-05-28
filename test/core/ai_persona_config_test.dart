import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AI Persona Configuration', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    group('persona name', () {
      test('defaults to "AI 助手" when not set', () async {
        final name = prefs.getString('ai_assistant_name') ?? 'AI 助手';
        expect(name, 'AI 助手');
      });

      test('saves custom persona name', () async {
        await prefs.setString('ai_assistant_name', 'Kael');
        final name = prefs.getString('ai_assistant_name');
        expect(name, 'Kael');
      });

      test('allows empty persona name', () async {
        await prefs.setString('ai_assistant_name', '');
        final name = prefs.getString('ai_assistant_name');
        expect(name, '');
      });

      test('persists across app restarts', () async {
        await prefs.setString('ai_assistant_name', 'Custom');

        // Simulate app restart
        final newPrefs = await SharedPreferences.getInstance();
        final name = newPrefs.getString('ai_assistant_name');
        expect(name, 'Custom');
      });

      test('supports bilingual names', () async {
        // English
        await prefs.setString('ai_assistant_name', 'Marcus');
        expect(prefs.getString('ai_assistant_name'), 'Marcus');

        // Chinese
        await prefs.setString('ai_assistant_name', '凯尔');
        expect(prefs.getString('ai_assistant_name'), '凯尔');
      });

      test('allows unicode characters', () async {
        final names = ['Kael 凯尔', 'Elara 艾拉', 'Rush 瑞什', 'Marcus 马库斯'];
        for (final name in names) {
          await prefs.setString('ai_assistant_name', name);
          expect(prefs.getString('ai_assistant_name'), name);
        }
      });

      test('handles name updates', () async {
        await prefs.setString('ai_assistant_name', 'Old Name');
        expect(prefs.getString('ai_assistant_name'), 'Old Name');

        await prefs.setString('ai_assistant_name', 'New Name');
        expect(prefs.getString('ai_assistant_name'), 'New Name');
      });
    });

    group('persona personality', () {
      test('defaults to empty string when not set', () async {
        final personality = prefs.getString('ai_assistant_personality') ?? '';
        expect(personality, '');
      });

      test('saves custom personality description', () async {
        const desc = 'Factual and precise, prefers data over emotion.';
        await prefs.setString('ai_assistant_personality', desc);

        final personality = prefs.getString('ai_assistant_personality');
        expect(personality, desc);
      });

      test('allows long personality descriptions', () async {
        const longDesc =
            'A warm and empathetic AI assistant that values emotional connection. '
            'Prefers natural conversation over technical jargon. '
            'Offers thoughtful insights grounded in lived experience.';

        await prefs.setString('ai_assistant_personality', longDesc);
        final personality = prefs.getString('ai_assistant_personality');
        expect(personality, longDesc);
      });

      test('persists across app restarts', () async {
        const personality = 'Stoic and measured, values logic and evidence.';
        await prefs.setString('ai_assistant_personality', personality);

        // Simulate app restart
        final newPrefs = await SharedPreferences.getInstance();
        expect(newPrefs.getString('ai_assistant_personality'), personality);
      });

      test('supports bilingual descriptions', () async {
        // English
        const enDesc = 'Warm and supportive';
        await prefs.setString('ai_assistant_personality', enDesc);
        expect(prefs.getString('ai_assistant_personality'), enDesc);

        // Chinese
        const zhDesc = '温暖且充满支持';
        await prefs.setString('ai_assistant_personality', zhDesc);
        expect(prefs.getString('ai_assistant_personality'), zhDesc);
      });

      test('allows updating personality independently of name', () async {
        await prefs.setString('ai_assistant_name', 'Kael');
        await prefs.setString('ai_assistant_personality', 'Factual and precise');

        expect(prefs.getString('ai_assistant_name'), 'Kael');
        expect(prefs.getString('ai_assistant_personality'), 'Factual and precise');

        // Update only personality
        await prefs.setString('ai_assistant_personality', 'Warm and emotional');
        expect(prefs.getString('ai_assistant_name'), 'Kael');
        expect(prefs.getString('ai_assistant_personality'), 'Warm and emotional');
      });
    });

    group('predefined personas', () {
      test('Kael (📝 Factual) persona', () async {
        await prefs.setString('ai_assistant_name', 'Kael');
        await prefs.setString(
          'ai_assistant_personality',
          'Factual, precise, and data-driven.',
        );

        expect(prefs.getString('ai_assistant_name'), 'Kael');
        expect(
          prefs.getString('ai_assistant_personality'),
          'Factual, precise, and data-driven.',
        );
      });

      test('Elara (🌿 Warm) persona', () async {
        await prefs.setString('ai_assistant_name', 'Elara');
        await prefs.setString(
          'ai_assistant_personality',
          'Warm, empathetic, and emotionally intelligent.',
        );

        expect(prefs.getString('ai_assistant_name'), 'Elara');
        expect(
          prefs.getString('ai_assistant_personality'),
          'Warm, empathetic, and emotionally intelligent.',
        );
      });

      test('Rush (⚡ Unfiltered) persona', () async {
        await prefs.setString('ai_assistant_name', 'Rush');
        await prefs.setString(
          'ai_assistant_personality',
          'Direct, unfiltered, and straightforward.',
        );

        expect(prefs.getString('ai_assistant_name'), 'Rush');
        expect(
          prefs.getString('ai_assistant_personality'),
          'Direct, unfiltered, and straightforward.',
        );
      });

      test('Marcus (⚔️ Stoic) persona', () async {
        await prefs.setString('ai_assistant_name', 'Marcus');
        await prefs.setString(
          'ai_assistant_personality',
          'Stoic, measured, and principled.',
        );

        expect(prefs.getString('ai_assistant_name'), 'Marcus');
        expect(
          prefs.getString('ai_assistant_personality'),
          'Stoic, measured, and principled.',
        );
      });
    });

    group('system prompt composition', () {
      test('builds system prompt from name and personality', () async {
        await prefs.setString('ai_assistant_name', 'Kael');
        await prefs.setString('ai_assistant_personality', 'Factual and precise.');

        final name = prefs.getString('ai_assistant_name') ?? 'AI 助手';
        final personality = prefs.getString('ai_assistant_personality') ?? '';

        final systemPrompt = _buildSystemPrompt(name, personality);
        expect(systemPrompt, contains('Kael'));
        expect(systemPrompt, contains('Factual and precise'));
      });

      test('handles empty personality gracefully', () async {
        await prefs.setString('ai_assistant_name', 'Kael');
        await prefs.setString('ai_assistant_personality', '');

        final name = prefs.getString('ai_assistant_name') ?? 'AI 助手';
        final personality = prefs.getString('ai_assistant_personality') ?? '';

        final systemPrompt = _buildSystemPrompt(name, personality);
        expect(systemPrompt, contains('Kael'));
        expect(systemPrompt, isNotEmpty);
      });

      test('respects custom name in system prompt', () async {
        await prefs.setString('ai_assistant_name', 'CustomBot');
        final name = prefs.getString('ai_assistant_name') ?? 'AI 助手';
        final personality = 'A test personality';

        final systemPrompt = _buildSystemPrompt(name, personality);
        expect(systemPrompt, contains('CustomBot'));
      });
    });

    group('persona switching', () {
      test('allows switching between personas', () async {
        // Switch to Elara
        await prefs.setString('ai_assistant_name', 'Elara');
        await prefs.setString('ai_assistant_personality', 'Warm and empathetic');
        expect(prefs.getString('ai_assistant_name'), 'Elara');

        // Switch to Marcus
        await prefs.setString('ai_assistant_name', 'Marcus');
        await prefs.setString('ai_assistant_personality', 'Stoic and measured');
        expect(prefs.getString('ai_assistant_name'), 'Marcus');
      });

      test('preserves persona after switching back', () async {
        await prefs.setString('ai_assistant_name', 'Kael');
        await prefs.setString('ai_assistant_personality', 'Factual');

        // Switch away
        await prefs.setString('ai_assistant_name', 'Elara');
        await prefs.setString('ai_assistant_personality', 'Warm');

        // Switch back
        await prefs.setString('ai_assistant_name', 'Kael');
        await prefs.setString('ai_assistant_personality', 'Factual');

        expect(prefs.getString('ai_assistant_name'), 'Kael');
        expect(prefs.getString('ai_assistant_personality'), 'Factual');
      });

      test('multiple rapid persona switches work correctly', () async {
        final personas = [
          ('Kael', 'Factual'),
          ('Elara', 'Warm'),
          ('Rush', 'Direct'),
          ('Marcus', 'Stoic'),
        ];

        for (final (name, personality) in personas) {
          await prefs.setString('ai_assistant_name', name);
          await prefs.setString('ai_assistant_personality', personality);
        }

        expect(prefs.getString('ai_assistant_name'), 'Marcus');
        expect(prefs.getString('ai_assistant_personality'), 'Stoic');
      });
    });
  });
}

// Helper function to build system prompt
String _buildSystemPrompt(String name, String personality) {
  final buffer = StringBuffer();
  buffer.write('You are $name');

  if (personality.isNotEmpty) {
    buffer.write(', $personality');
  }

  buffer.write('.');
  return buffer.toString();
}
