import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config_service.dart';

class LlmService {
  static const _defaultTimeout = Duration(seconds: 30);
  static const _trialApiKey = String.fromEnvironment('TRIAL_API_KEY');
  static const _proApiKey = String.fromEnvironment('PRO_API_KEY');

  Future<String> complete(String prompt,
      {String? systemPrompt,
      int maxTokens = 300,
      double temperature = 0.9}) async {
    final configs = await _loadConfigs();

    final messages = <Map<String, String>>[];
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }
    messages.add({'role': 'user', 'content': prompt});

    return _callWithFailover(
      configs: configs,
      messages: messages,
      maxTokens: maxTokens,
      temperature: temperature,
    );
  }

  Future<String> chat({
    required List<Map<String, String>> history,
    String? systemPrompt,
  }) async {
    final configs = await _loadConfigs();

    final messages = <Map<String, String>>[];
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }
    messages.addAll(history);

    return _callWithFailover(
      configs: configs,
      messages: messages,
    );
  }

  /// Try each key config in sequence. If one fails with a retryable error
  /// (rate limit, server error, auth failure), try the next. Throws the
  /// last error if all keys fail.
  Future<String> _callWithFailover({
    required List<Map<String, String?>> configs,
    required List<Map<String, String>> messages,
    int maxTokens = 300,
    double temperature = 0.9,
  }) async {
    if (configs.isEmpty) {
      throw LlmException('No API key configured.', LlmErrorType.noApiKey);
    }

    dynamic lastError;
    for (var i = 0; i < configs.length; i++) {
      final cfg = configs[i];
      final baseUrl = cfg['baseUrl'] ?? '';
      final apiKey = cfg['apiKey'] ?? '';
      final model = cfg['model'] ?? 'qwen/qwen3.5-flash';

      if (baseUrl.isEmpty || apiKey.isEmpty) continue;

      try {
        return await _callChatCompletions(
          baseUrl: baseUrl,
          apiKey: apiKey,
          model: model,
          messages: messages,
          maxTokens: maxTokens,
          temperature: temperature,
        );
      } on LlmException catch (e) {
        // Only fail over on retryable errors
        if (e.type == LlmErrorType.rateLimited ||
            e.type == LlmErrorType.serverError ||
            e.type == LlmErrorType.invalidApiKey ||
            e.type == LlmErrorType.timeout) {
          lastError = e;
          debugPrint(
              '[LlmService] Key ${i + 1}/${configs.length} failed (${e.type}), trying next...');
          continue;
        }
        rethrow; // Non-retryable (network error, etc.)
      }
    }

    // All keys exhausted
    if (lastError is LlmException) throw lastError;
    throw LlmException('All keys exhausted.', LlmErrorType.noApiKey);
  }

  /// Streaming single-turn. Returns a stream of response chunks.
  /// Use to show incremental output to the user for faster perceived speed.
  Stream<String> completeStream(String prompt,
      {String? systemPrompt, int maxTokens = 300, double temperature = 0.9}) async* {
    final configs = await _loadConfigs();
    if (configs.isEmpty) {
      throw LlmException('No API key configured.', LlmErrorType.noApiKey);
    }

    final cfg = configs.first;
    final baseUrl = cfg['baseUrl'] ?? '';
    final apiKey = cfg['apiKey'] ?? '';
    final model = cfg['model'] ?? 'qwen/qwen3.5-flash-02-23';

    if (baseUrl.isEmpty || apiKey.isEmpty) {
      throw LlmException('No API key configured.', LlmErrorType.noApiKey);
    }

    final messages = <Map<String, String>>[];
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }
    messages.add({'role': 'user', 'content': prompt});

    final url = Uri.parse('$baseUrl/chat/completions');
    final client = http.Client();

    try {
      final request = http.StreamedRequest('POST', url)
        ..headers.addAll({
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        });

      final body = utf8.encode(jsonEncode({
        'model': model,
        'messages': messages,
        'temperature': temperature,
        'max_tokens': maxTokens,
        'stream': true,
      }));
      request.contentLength = body.length;
      request.sink.add(body);
      request.sink.close();

      final response = await request.send().timeout(_defaultTimeout);

      if (response.statusCode != 200) {
        final errorBody = await response.stream.transform(utf8.decoder).join();
        throw LlmException('HTTP ${response.statusCode}: ${errorBody.substring(0, errorBody.length > 100 ? 100 : errorBody.length)}', LlmErrorType.serverError);
      }

      final lineStream = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in lineStream) {
        if (line.isEmpty || !line.startsWith('data: ')) continue;
        final data = line.substring(6).trim();
        if (data == '[DONE]') break;
        try {
          final parsed = jsonDecode(data);
          final delta = parsed['choices']?[0]?['delta']?['content'];
          if (delta != null && delta is String) {
            yield delta;
          }
        } catch (_) {}
      }
    } on LlmException {
      rethrow;
    } on TimeoutException {
      throw LlmException('Request timed out.', LlmErrorType.timeout);
    } catch (e) {
      throw LlmException('Network error: $e', LlmErrorType.networkError);
    } finally {
      client.close();
    }
  }

  Future<String> _callChatCompletions({
    required String baseUrl,
    required String apiKey,
    required String model,
    required List<Map<String, String>> messages,
    int maxTokens = 300,
    double temperature = 0.9,
  }) async {
    final url = Uri.parse('$baseUrl/chat/completions');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    final body = jsonEncode({
      'model': model,
      'messages': messages,
      'temperature': temperature,
      'max_tokens': maxTokens,
    });

    try {
      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(_defaultTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List<dynamic>?;
        if (choices == null || choices.isEmpty) {
          throw LlmException(
              'Empty response from API.', LlmErrorType.emptyResponse);
        }
        return choices[0]['message']['content'] as String? ?? '';
      } else {
        debugPrint(
            'LlmService HTTP ${response.statusCode}: ${response.body}');
        String detail = '';
        try {
          final err = jsonDecode(response.body);
          detail = err['error']?['message'] as String? ?? '';
        } catch (_) {}

        final status = response.statusCode;
        if (status == 401 || status == 403) {
          try {
            final err = jsonDecode(response.body);
            if (err['error'] == 'trial_expired') {
              throw LlmException(
                  'HTTP $status: $detail', LlmErrorType.trialExpired);
            }
          } catch (_) {}
          throw LlmException(
              'HTTP $status: $detail', LlmErrorType.invalidApiKey);
        } else if (status == 429) {
          throw LlmException(
              'HTTP $status: $detail', LlmErrorType.rateLimited);
        } else if (status >= 500) {
          throw LlmException(
              'HTTP $status: $detail', LlmErrorType.serverError);
        } else {
          throw LlmException('HTTP $status: $detail', LlmErrorType.unknown);
        }
      }
    } on LlmException {
      rethrow;
    } on TimeoutException {
      throw LlmException('Request timed out.', LlmErrorType.timeout);
    } catch (e) {
      throw LlmException('Network error: $e', LlmErrorType.networkError);
    }
  }

  static Future<bool> hasApiKey() async {
    final prefs = await SharedPreferences.getInstance();

    final configs = await _loadConfigsStatic(prefs);
    if (configs.isNotEmpty) return true;

    // Fallback: dart-define keys
    final state = prefs.getString('entitlement_state') ?? 'preview';
    if (state == 'preview' && _trialApiKey.isNotEmpty) return true;
    if ((state == 'paid' || state == 'restricted') &&
        _proApiKey.isNotEmpty) {
      return true;
    }
    return false;
  }

  static Future<List<Map<String, String?>>> _loadConfigsStatic(
      SharedPreferences prefs) async {
    final config = ConfigService.cached;
    final state = prefs.getString('entitlement_state') ?? 'preview';

    final configs = <Map<String, String?>>[];

    if (state == 'preview') {
      if (config != null && config.hasTrialKeys) {
        for (final k in config.trialKeys) {
          configs.add({
            'apiKey': k.key,
            'model': k.model,
            'baseUrl': 'https://openrouter.ai/api/v1',
          });
        }
      } else if (_trialApiKey.isNotEmpty) {
        configs.add({
          'apiKey': _trialApiKey,
          'model': 'qwen/qwen3.5-flash-02-23',
          'baseUrl': 'https://openrouter.ai/api/v1',
        });
      }
    } else if (state == 'paid' || state == 'restricted') {
      if (config != null && config.hasProKeys) {
        for (final k in config.proKeys) {
          configs.add({
            'apiKey': k.key,
            'model': k.model,
            'baseUrl': 'https://openrouter.ai/api/v1',
          });
        }
      } else if (_proApiKey.isNotEmpty) {
        configs.add({
          'apiKey': _proApiKey,
          'model': 'qwen/qwen3.5-flash-02-23',
          'baseUrl': 'https://openrouter.ai/api/v1',
        });
      }
    }

    return configs;
  }

  Future<List<Map<String, String?>>> _loadConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    return _loadConfigsStatic(prefs);
  }
}

enum LlmErrorType {
  noApiKey,
  invalidApiKey,
  rateLimited,
  serverError,
  networkError,
  timeout,
  emptyResponse,
  trialExpired,
  unknown,
}

class LlmException implements Exception {
  final String message;
  final LlmErrorType type;

  LlmException(this.message, [this.type = LlmErrorType.unknown]);

  String friendlyMessage(bool isZh) {
    switch (type) {
      case LlmErrorType.noApiKey:
        return isZh
            ? '尚未配置 API Key，请前往设置。'
            : 'No API key configured. Go to Settings.';
      case LlmErrorType.invalidApiKey:
        return isZh
            ? 'API Key 无效。'
            : 'API key is invalid.';
      case LlmErrorType.rateLimited:
        return isZh
            ? '请求频率超限，请稍后再试。'
            : 'Rate limit reached. Please try again.';
      case LlmErrorType.serverError:
        return isZh
            ? 'AI 服务暂时不可用，请稍后重试。'
            : 'AI service temporarily unavailable. Try again later.';
      case LlmErrorType.networkError:
        return isZh
            ? '网络连接失败，请检查网络后重试。'
            : 'Network connection failed. Check your connection.';
      case LlmErrorType.timeout:
        return isZh
            ? '请求超时，请重试。'
            : 'Request timed out. Please try again.';
      case LlmErrorType.emptyResponse:
        return isZh ? 'AI 返回空响应，请重试。' : 'AI returned empty response. Try again.';
      case LlmErrorType.trialExpired:
        return isZh
            ? '试用已结束。升级至 Pro 以继续使用。'
            : 'Your trial has ended. Upgrade to Pro to continue.';
      case LlmErrorType.unknown:
        return isZh ? '发生未知错误，请重试。' : 'An unexpected error occurred. Try again.';
    }
  }

  @override
  String toString() => 'LlmException[$type]: $message';
}
