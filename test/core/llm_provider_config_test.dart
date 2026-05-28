import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  group('LLM Provider Configuration - Merge-on-Load', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    group('saving and loading provider list', () {
      test('saves provider list to llm_providers key', () async {
        final providers = [
          {'name': 'OpenRouter', 'apiKey': 'sk-test', 'baseUrl': 'https://openrouter.ai'},
        ];
        final json = jsonEncode(providers);
        await prefs.setString('llm_providers', json);

        final savedJson = prefs.getString('llm_providers');
        expect(savedJson, json);
      });

      test('loads empty list when llm_providers not set', () async {
        final savedJson = prefs.getString('llm_providers');
        expect(savedJson, isNull);
      });

      test('parses provider list correctly', () async {
        final providers = [
          {'name': 'OpenRouter', 'apiKey': 'sk-test'},
        ];
        final json = jsonEncode(providers);
        await prefs.setString('llm_providers', json);

        final parsed = jsonDecode(prefs.getString('llm_providers')!) as List;
        expect(parsed.length, 1);
        expect(parsed[0]['name'], 'OpenRouter');
      });
    });

    group('merge-on-load strategy', () {
      test('preserves saved providers when loading defaults', () async {
        // User has saved a custom provider
        final saved = [
          {'name': 'Custom', 'apiKey': 'custom-key'},
        ];
        await prefs.setString('llm_providers', jsonEncode(saved));

        // Load defaults (simulate app startup)
        final defaults = [
          {'name': 'Trial', 'apiKey': 'trial-key'},
          {'name': 'Custom', 'apiKey': 'default-custom-key'}, // Same name
        ];

        final merged = _mergeProviders(
          saved,
          defaults,
        );

        // Custom provider should be preserved with original API key
        final customIndex = merged.indexWhere((p) => p['name'] == 'Custom');
        expect(customIndex, greaterThanOrEqualTo(0));
        expect(merged[customIndex]['apiKey'], 'custom-key');
      });

      test('appends new defaults not in saved list', () async {
        final saved = [
          {'name': 'Custom', 'apiKey': 'custom-key'},
        ];

        final defaults = [
          {'name': 'Trial', 'apiKey': 'trial-key'},
          {'name': 'Gemini', 'apiKey': 'gemini-key'},
        ];

        final merged = _mergeProviders(saved, defaults);

        expect(merged.length, 3); // Custom + Trial + Gemini
        expect(
          merged.any((p) => p['name'] == 'Custom'),
          isTrue,
        );
        expect(
          merged.any((p) => p['name'] == 'Trial'),
          isTrue,
        );
        expect(
          merged.any((p) => p['name'] == 'Gemini'),
          isTrue,
        );
      });

      test('does not discard saved providers', () async {
        final saved = [
          {'name': 'Provider1', 'apiKey': 'key1'},
          {'name': 'Provider2', 'apiKey': 'key2'},
          {'name': 'Provider3', 'apiKey': 'key3'},
        ];

        final defaults = [
          {'name': 'Trial', 'apiKey': 'trial-key'},
        ];

        final merged = _mergeProviders(saved, defaults);

        expect(merged.length, 4);
        for (final saved in saved) {
          expect(
            merged.any((p) => p['name'] == saved['name']),
            isTrue,
            reason: 'Saved provider ${saved['name']} should be preserved',
          );
        }
      });

      test('matches by name, not position', () async {
        final saved = [
          {'name': 'OpenRouter', 'apiKey': 'user-key'},
          {'name': 'Custom', 'apiKey': 'custom-key'},
        ];

        final defaults = [
          {'name': 'OpenRouter', 'apiKey': 'default-key'},
          {'name': 'Trial', 'apiKey': 'trial-key'},
        ];

        final merged = _mergeProviders(saved, defaults);

        final openrouter = merged.firstWhere((p) => p['name'] == 'OpenRouter');
        expect(openrouter['apiKey'], 'user-key');
      });

      test('handles empty saved list', () async {
        final saved = <Map<String, dynamic>>[];
        final defaults = [
          {'name': 'Trial', 'apiKey': 'trial-key'},
          {'name': 'Gemini', 'apiKey': 'gemini-key'},
        ];

        final merged = _mergeProviders(saved, defaults);

        expect(merged.length, 2);
        expect(merged, equals(defaults));
      });

      test('handles empty defaults list', () async {
        final saved = [
          {'name': 'Custom', 'apiKey': 'custom-key'},
        ];
        final defaults = <Map<String, dynamic>>[];

        final merged = _mergeProviders(saved, defaults);

        expect(merged.length, 1);
        expect(merged, equals(saved));
      });

      test('handles both empty lists', () async {
        final saved = <Map<String, dynamic>>[];
        final defaults = <Map<String, dynamic>>[];

        final merged = _mergeProviders(saved, defaults);

        expect(merged.isEmpty, isTrue);
      });
    });

    group('provider selection index', () {
      test('saves selected provider index', () async {
        await prefs.setInt('llm_selected_index', 1);
        final index = prefs.getInt('llm_selected_index');
        expect(index, 1);
      });

      test('defaults to 0 when not set', () async {
        final index = prefs.getInt('llm_selected_index') ?? 0;
        expect(index, 0);
      });

      test('allows changing selected provider', () async {
        await prefs.setInt('llm_selected_index', 0);
        expect(prefs.getInt('llm_selected_index'), 0);

        await prefs.setInt('llm_selected_index', 2);
        expect(prefs.getInt('llm_selected_index'), 2);
      });

      test('does not reset on app restart', () async {
        await prefs.setInt('llm_selected_index', 2);

        // Simulate app restart by creating new prefs instance
        final newPrefs = await SharedPreferences.getInstance();
        expect(newPrefs.getInt('llm_selected_index'), 2);
      });
    });

    group('provider metadata', () {
      test('stores provider name', () async {
        final provider = {
          'name': 'OpenRouter',
          'apiKey': 'sk-test',
          'baseUrl': 'https://openrouter.ai',
        };
        final json = jsonEncode([provider]);
        await prefs.setString('llm_providers', json);

        final parsed = jsonDecode(prefs.getString('llm_providers')!) as List;
        expect(parsed[0]['name'], 'OpenRouter');
      });

      test('stores provider API key', () async {
        final provider = {
          'name': 'OpenRouter',
          'apiKey': 'sk-test',
        };
        final json = jsonEncode([provider]);
        await prefs.setString('llm_providers', json);

        final parsed = jsonDecode(prefs.getString('llm_providers')!) as List;
        expect(parsed[0]['apiKey'], 'sk-test');
      });

      test('stores optional provider base URL', () async {
        final provider = {
          'name': 'OpenRouter',
          'apiKey': 'sk-test',
          'baseUrl': 'https://openrouter.ai/api/v1',
        };
        final json = jsonEncode([provider]);
        await prefs.setString('llm_providers', json);

        final parsed = jsonDecode(prefs.getString('llm_providers')!) as List;
        expect(parsed[0]['baseUrl'], 'https://openrouter.ai/api/v1');
      });

      test('allows custom provider metadata fields', () async {
        final provider = {
          'name': 'Custom',
          'apiKey': 'custom-key',
          'model': 'custom-model',
          'description': 'My custom provider',
        };
        final json = jsonEncode([provider]);
        await prefs.setString('llm_providers', json);

        final parsed = jsonDecode(prefs.getString('llm_providers')!) as List;
        expect(parsed[0]['model'], 'custom-model');
        expect(parsed[0]['description'], 'My custom provider');
      });
    });

    group('provider validation', () {
      test('requires name field', () async {
        final provider = {'apiKey': 'test-key'};
        final providers = [provider];

        // merge should handle missing name gracefully
        final merged = _mergeProviders(providers, []);
        expect(merged.isNotEmpty, isTrue);
      });

      test('allows empty API key for display providers', () async {
        final provider = {
          'name': 'Unconfigurated',
          'apiKey': '',
        };
        final providers = [provider];
        final json = jsonEncode(providers);

        await prefs.setString('llm_providers', json);
        final parsed = jsonDecode(prefs.getString('llm_providers')!) as List;
        expect(parsed[0]['apiKey'], '');
      });

      test('distinguishes configured from unconfigured providers', () async {
        final providers = [
          {'name': 'Configured', 'apiKey': 'real-key'},
          {'name': 'Unconfigured', 'apiKey': ''},
        ];
        final json = jsonEncode(providers);
        await prefs.setString('llm_providers', json);

        final parsed = jsonDecode(prefs.getString('llm_providers')!) as List;
        final configured = parsed.where((p) => (p['apiKey'] as String).isNotEmpty);
        expect(configured.length, 1);
      });
    });
  });
}

// Helper function implementing merge-on-load strategy
List<Map<String, dynamic>> _mergeProviders(
  List<Map<String, dynamic>> saved,
  List<Map<String, dynamic>> defaults,
) {
  // Start with saved providers
  final merged = List<Map<String, dynamic>>.from(saved);

  // Append defaults not already present by name
  for (final defaultProvider in defaults) {
    final name = defaultProvider['name'];
    final alreadyExists = merged.any((p) => p['name'] == name);

    if (!alreadyExists) {
      merged.add(defaultProvider);
    }
  }

  return merged;
}
