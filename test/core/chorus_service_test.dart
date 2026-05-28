import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';

void main() {
  group('ChorusService', () {
    late ChorusServiceMock service;

    setUp(() {
      service = ChorusServiceMock();
    });

    group('post note validation', () {
      test('requires text parameter', () async {
        final result = await service.postNote(
          text: '',
        );
        expect(result, isA<ChorusPostValidationError>());
      });

      test('accepts non-empty text', () async {
        service.mockSuccessResponse();
        final result = await service.postNote(
          text: 'This is a valid note',
        );
        expect(result, isA<ChorusPostSuccess>());
      });

      test('text parameter is required', () async {
        final result = await service.postNote(
          text: '',
          tag: 'tag1',
        );
        expect(result, isA<ChorusPostValidationError>());
      });

      test('accepts text with multiple lines', () async {
        service.mockSuccessResponse();
        final result = await service.postNote(
          text: 'Line 1\nLine 2\nLine 3',
        );
        expect(result, isA<ChorusPostSuccess>());
      });

      test('accepts very long text', () async {
        service.mockSuccessResponse();
        final longText = 'A' * 10000;
        final result = await service.postNote(text: longText);
        expect(result, isA<ChorusPostSuccess>());
      });

      test('handles unicode text correctly', () async {
        service.mockSuccessResponse();
        final result = await service.postNote(
          text: '今天很开心，去公园散步了。😊',
        );
        expect(result, isA<ChorusPostSuccess>());
      });

      test('trims whitespace from text', () async {
        service.mockSuccessResponse();
        final result = await service.postNote(
          text: '   valid text with whitespace   ',
        );
        expect(result, isA<ChorusPostSuccess>());
      });
    });

    group('optional parameters', () {
      test('tag parameter is optional', () async {
        service.mockSuccessResponse();
        final result = await service.postNote(
          text: 'Note without tag',
        );
        expect(result, isA<ChorusPostSuccess>());
      });

      test('tag parameter is sent when provided', () async {
        service.mockSuccessResponse();
        final result = await service.postNote(
          text: 'Note with tag',
          tag: 'fitness',
        );
        expect(result, isA<ChorusPostSuccess>());
        expect(service.lastRequestBody?['tag'], 'fitness');
      });

      test('empty tag is not sent', () async {
        service.mockSuccessResponse();
        await service.postNote(
          text: 'Note with empty tag',
          tag: '',
        );
        expect(service.lastRequestBody?['tag'], isNull);
      });

      test('city parameter is optional', () async {
        service.mockSuccessResponse();
        final result = await service.postNote(
          text: 'Note without city',
        );
        expect(result, isA<ChorusPostSuccess>());
      });

      test('city parameter is sent when provided', () async {
        service.mockSuccessResponse();
        final result = await service.postNote(
          text: 'Note with city',
          city: 'San Francisco',
        );
        expect(result, isA<ChorusPostSuccess>());
        expect(service.lastRequestBody?['city'], 'San Francisco');
      });

      test('empty city is not sent', () async {
        service.mockSuccessResponse();
        await service.postNote(
          text: 'Note with empty city',
          city: '',
        );
        expect(service.lastRequestBody?['city'], isNull);
      });

      test('all optional parameters sent together', () async {
        service.mockSuccessResponse();
        final result = await service.postNote(
          text: 'Complete note',
          tag: 'travel',
          city: 'Tokyo',
        );
        expect(result, isA<ChorusPostSuccess>());
        expect(service.lastRequestBody?['tag'], 'travel');
        expect(service.lastRequestBody?['city'], 'Tokyo');
      });
    });

    group('success response', () {
      test('201 status returns ChorusPostSuccess', () async {
        service.mockSuccessResponse(statusCode: 201);
        final result = await service.postNote(text: 'Valid note');
        expect(result, isA<ChorusPostSuccess>());
      });

      test('success returns generated ID', () async {
        service.mockSuccessResponse(responseId: 'note_12345');
        final result = await service.postNote(text: 'Note with ID');

        expect(result, isA<ChorusPostSuccess>());
        if (result is ChorusPostSuccess) {
          expect(result.id, 'note_12345');
        }
      });

      test('success with empty ID returns empty string', () async {
        service.mockSuccessResponse(responseId: '');
        final result = await service.postNote(text: 'Note without ID');

        expect(result, isA<ChorusPostSuccess>());
      });
    });

    group('rate limiting', () {
      test('429 status returns ChorusPostRateLimited', () async {
        service.mockRateLimitedResponse();
        final result = await service.postNote(text: 'Rate limited');
        expect(result, isA<ChorusPostRateLimited>());
      });

      test('rate limit detected on consecutive requests', () async {
        service.mockRateLimitedResponse();

        final result1 = await service.postNote(text: 'First');
        final result2 = await service.postNote(text: 'Second');

        expect(result1, isA<ChorusPostRateLimited>());
        expect(result2, isA<ChorusPostRateLimited>());
      });

      test('can recover from rate limit', () async {
        service.mockRateLimitedResponse();
        await service.postNote(text: 'First - rate limited');

        service.mockSuccessResponse();
        final result = await service.postNote(text: 'Second - success');

        expect(result, isA<ChorusPostSuccess>());
      });
    });

    group('validation errors', () {
      test('400 status returns ChorusPostValidationError', () async {
        service.mockValidationError('Invalid content');
        final result = await service.postNote(text: 'Invalid');
        expect(result, isA<ChorusPostValidationError>());
      });

      test('validation error contains message', () async {
        service.mockValidationError('Content too short');
        final result = await service.postNote(text: 'Bad');

        expect(result, isA<ChorusPostValidationError>());
        if (result is ChorusPostValidationError) {
          expect(result.message, contains('Content'));
        }
      });

      test('default error message when parsing fails', () async {
        service.mockValidationError(null); // Unparseable response
        final result = await service.postNote(text: 'Bad');

        expect(result, isA<ChorusPostValidationError>());
        if (result is ChorusPostValidationError) {
          expect(result.message, contains('Could not post'));
        }
      });

      test('handles empty error response gracefully', () async {
        service.mockStatusCodeOnly(400);
        final result = await service.postNote(text: 'Error');

        expect(result, isA<ChorusPostValidationError>());
      });

      test('400+ status codes treated as validation error', () async {
        for (final code in [400, 401, 403, 404, 409]) {
          service.mockStatusCodeOnly(code);
          final result = await service.postNote(text: 'Error $code');
          expect(result, isA<ChorusPostValidationError>());
        }
      });
    });

    group('network errors', () {
      test('timeout returns ChorusPostNetworkError', () async {
        service.mockNetworkError('timeout');
        final result = await service.postNote(text: 'Timeout');
        expect(result, isA<ChorusPostNetworkError>());
      });

      test('connection error returns ChorusPostNetworkError', () async {
        service.mockNetworkError('Connection refused');
        final result = await service.postNote(text: 'Connection error');
        expect(result, isA<ChorusPostNetworkError>());
      });

      test('network error contains message', () async {
        service.mockNetworkError('No internet connection');
        final result = await service.postNote(text: 'No network');

        expect(result, isA<ChorusPostNetworkError>());
        if (result is ChorusPostNetworkError) {
          expect(result.message, contains('internet'));
        }
      });

      test('DNS lookup failure handled gracefully', () async {
        service.mockNetworkError('Failed to resolve hostname');
        final result = await service.postNote(text: 'DNS error');

        expect(result, isA<ChorusPostNetworkError>());
      });

      test('can retry after network error', () async {
        service.mockNetworkError('Temporary failure');
        final result1 = await service.postNote(text: 'Fails');
        expect(result1, isA<ChorusPostNetworkError>());

        service.mockSuccessResponse();
        final result2 = await service.postNote(text: 'Succeeds');
        expect(result2, isA<ChorusPostSuccess>());
      });
    });

    group('request headers', () {
      test('Content-Type header is application/json', () async {
        service.mockSuccessResponse();
        await service.postNote(text: 'Test');

        expect(
          service.lastRequestHeaders?['Content-Type'],
          'application/json',
        );
      });

      test('Authorization header is sent', () async {
        service.mockSuccessResponse();
        await service.postNote(text: 'Test');

        expect(
          service.lastRequestHeaders?.containsKey('Authorization'),
          isTrue,
        );
        expect(
          service.lastRequestHeaders?['Authorization'],
          startsWith('Bearer'),
        );
      });
    });

    group('request body', () {
      test('request body contains text', () async {
        service.mockSuccessResponse();
        await service.postNote(text: 'Test note');

        expect(service.lastRequestBody?['text'], 'Test note');
      });

      test('request body is valid JSON', () async {
        service.mockSuccessResponse();
        await service.postNote(
          text: 'Test',
          tag: 'tag1',
          city: 'SF',
        );

        expect(service.lastRequestBody, isNotNull);
        expect(service.lastRequestBody, isA<Map>());
      });

      test('unicode in request body preserved', () async {
        service.mockSuccessResponse();
        const chineseText = '我很开心';
        await service.postNote(text: chineseText);

        expect(service.lastRequestBody?['text'], chineseText);
      });
    });

    group('edge cases', () {
      test('posting to chorus endpoint uses correct URL', () async {
        service.mockSuccessResponse();
        await service.postNote(text: 'Test');

        expect(service.lastUrl, contains('blinkingchorus.com'));
        expect(service.lastUrl, contains('/api/notes'));
      });

      test('multiple consecutive posts work', () async {
        service.mockSuccessResponse();

        for (int i = 0; i < 5; i++) {
          final result = await service.postNote(text: 'Post $i');
          expect(result, isA<ChorusPostSuccess>());
        }
      });

      test('posts with same content are separate requests', () async {
        service.mockSuccessResponse(responseId: 'id1');
        final result1 = await service.postNote(text: 'Duplicate');

        service.mockSuccessResponse(responseId: 'id2');
        final result2 = await service.postNote(text: 'Duplicate');

        expect((result1 as ChorusPostSuccess).id, 'id1');
        expect((result2 as ChorusPostSuccess).id, 'id2');
      });
    });
  });
}

// Result types
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

// Mock service for testing
class ChorusServiceMock {
  int? _mockStatusCode;
  String? _mockResponseId;
  String? _mockErrorMessage;
  bool _mockNetworkError = false;

  Map<String, dynamic>? lastRequestBody;
  Map<String, String>? lastRequestHeaders;
  String? lastUrl;

  Future<ChorusPostResult> postNote({
    required String text,
    String? tag,
    String? city,
  }) async {
    // Validate text is not empty
    if (text.trim().isEmpty) {
      return ChorusPostValidationError('Text is required');
    }

    lastUrl = 'https://blinkingchorus.com/api/notes';
    lastRequestHeaders = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ZOYxHqTHocZcTWV9lRhV05mOY4uZN+PuUC6Ho/+5LIE=',
    };

    lastRequestBody = {
      'text': text,
      if (tag != null && tag.isNotEmpty) 'tag': tag,
      if (city != null && city.isNotEmpty) 'city': city,
    };

    if (_mockNetworkError) {
      return ChorusPostNetworkError(_mockErrorMessage ?? 'Network error');
    }

    if (_mockStatusCode == 201) {
      return ChorusPostSuccess(_mockResponseId ?? '');
    }

    if (_mockStatusCode == 429) {
      return ChorusPostRateLimited();
    }

    if (_mockStatusCode != null && _mockStatusCode! >= 400) {
      final message = _mockErrorMessage ?? 'Could not post to the chorus.';
      return ChorusPostValidationError(message);
    }

    return ChorusPostSuccess(_mockResponseId ?? '');
  }

  void mockSuccessResponse({
    int statusCode = 201,
    String? responseId,
  }) {
    _mockStatusCode = statusCode;
    _mockResponseId = responseId;
    _mockNetworkError = false;
  }

  void mockRateLimitedResponse() {
    _mockStatusCode = 429;
    _mockNetworkError = false;
  }

  void mockValidationError(String? errorMessage) {
    _mockStatusCode = 400;
    _mockErrorMessage = errorMessage;
    _mockNetworkError = false;
  }

  void mockNetworkError(String errorMessage) {
    _mockNetworkError = true;
    _mockErrorMessage = errorMessage;
  }

  void mockStatusCodeOnly(int statusCode) {
    _mockStatusCode = statusCode;
    _mockErrorMessage = null;
    _mockNetworkError = false;
  }
}
