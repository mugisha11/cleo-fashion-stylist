import 'package:flutter_test/flutter_test.dart';
import 'package:virtual_twin/src/core/services/tryon_service.dart';

void main() {
  group('TryOnException Tests', () {
    test('TryOnException with code and message', () {
      final exception = TryOnException(
        'Model not found',
        'The AI model is not available',
      );
      expect(exception.code, equals('Model not found'));
      expect(exception.message, equals('The AI model is not available'));
    });

    test('TryOnException with status code', () {
      final exception = TryOnException(
        'Server error',
        'Internal server error',
        statusCode: 500,
      );
      expect(exception.statusCode, equals(500));
    });

    test('getUserMessage returns appropriate message for Model not found', () {
      final exception = TryOnException(
        'Model not found',
        'The AI model is not available',
      );
      expect(
        exception.getUserMessage(),
        equals(
            'The AI model is not available. Please try again in a few moments.'),
      );
    });

    test('getUserMessage returns appropriate message for Request timeout', () {
      final exception = TryOnException(
        'Request timeout',
        'Request took too long',
      );
      expect(
        exception.getUserMessage(),
        equals(
            'The request took too long. Try with a smaller or different image.'),
      );
    });

    test('getUserMessage returns appropriate message for Rate limited', () {
      final exception = TryOnException(
        'Rate limited',
        'Too many requests',
      );
      expect(
        exception.getUserMessage(),
        equals('Too many requests. Please wait a moment before trying again.'),
      );
    });

    test('getUserMessage returns message for generic error', () {
      final exception = TryOnException(
        'Unknown error',
        'An unknown error occurred',
      );
      expect(
        exception.getUserMessage(),
        equals('An unknown error occurred'),
      );
    });

    test('toString formats error correctly', () {
      final exception = TryOnException(
        'Model not found',
        'The AI model is not available',
      );
      expect(
        exception.toString(),
        equals(
            'TryOnException(Model not found): The AI model is not available'),
      );
    });

    test('TryOnException with original error', () {
      final originalError = Exception('Original error');
      final exception = TryOnException(
        'Wrapped error',
        'Error wrapped',
        originalError: originalError,
      );
      expect(exception.originalError, equals(originalError));
    });
  });
}
