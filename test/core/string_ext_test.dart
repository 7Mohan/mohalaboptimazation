import 'package:flutter_test/flutter_test.dart';
import 'package:mohalab_optimization/core/extensions/string_ext.dart';

void main() {
  group('StringExtensions', () {
    test('capitalised uppercases first char', () {
      expect('hello'.capitalised, 'Hello');
    });

    test('capitalised handles empty string', () {
      expect(''.capitalised, '');
    });

    test('isBlank returns true for whitespace-only', () {
      expect('   '.isBlank, isTrue);
    });

    test('isNotBlank returns true for non-empty', () {
      expect('hello'.isNotBlank, isTrue);
    });

    test('truncate shortens long strings', () {
      final result = 'Hello World'.truncate(7);
      expect(result.length, lessThanOrEqualTo(7));
      expect(result.endsWith('…'), isTrue);
    });

    test('truncate does not modify short strings', () {
      expect('Hi'.truncate(10), 'Hi');
    });
  });

  group('NullableStringExtensions', () {
    test('orFallback returns fallback for null', () {
      String? value;
      expect(value.orFallback('default'), 'default');
    });

    test('orFallback returns value when non-null', () {
      expect('hello'.orFallback('default'), 'hello');
    });

    test('orFallback returns fallback for blank string', () {
      expect('   '.orFallback('default'), 'default');
    });
  });
}
