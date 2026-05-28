import 'dart:convert';
import 'package:http/http.dart' as http;

/// Result of a POST /api/notes call.
sealed class ChorusPostResult {}

class ChorusPostSuccess extends ChorusPostResult {
  final String id;
  ChorusPostSuccess(this.id);
}

class ChorusPostRateLimited extends ChorusPostResult {}

class ChorusPostValidationError extends ChorusPostResult {
  final String message;
  ChorusPostValidationError(this.message);
}

class ChorusPostNetworkError extends ChorusPostResult {
  final String message;
  ChorusPostNetworkError(this.message);
}

class ChorusService {
  static const _baseUrl = 'https://blinkingchorus.com';
  // Bearer token set via `wrangler pages secret put SHARED_SECRET`.
  // Bypasses the 5/hr web rate limit for app clients.
  // TODO(v1): replace with a proper session-token exchange.
  static const _secret = 'ZOYxHqTHocZcTWV9lRhV05mOY4uZN+PuUC6Ho/+5LIE=';

  static const _timeout = Duration(seconds: 15);

  Future<ChorusPostResult> postNote({
    required String text,
    String? tag,
    String? city,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/notes'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_secret',
            },
            body: jsonEncode({
              'text': text,
              if (tag != null && tag.isNotEmpty) 'tag': tag,
              if (city != null && city.isNotEmpty) 'city': city,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 201) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return ChorusPostSuccess(body['id'] as String? ?? '');
      }
      if (response.statusCode == 429) {
        return ChorusPostRateLimited();
      }
      // 400 or other client error
      String message = 'Could not post to the chorus.';
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        message = body['error'] as String? ?? message;
      } catch (_) {}
      return ChorusPostValidationError(message);
    } catch (e) {
      return ChorusPostNetworkError(e.toString());
    }
  }
}
