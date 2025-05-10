import 'package:flutter_test/flutter_test.dart';
import 'package:ai_chat_bot/core/utils/format_utils.dart';

void main() {
  group('formatBooleanStatus tests', () {
    test('should handle null values', () {
      expect(formatBooleanStatus(null), equals('pending'));
    });

    test('should handle boolean true values', () {
      expect(formatBooleanStatus(true), equals('active'));
    });

    test('should handle boolean false values', () {
      expect(formatBooleanStatus(false), equals('inactive'));
    });

    test('should handle string values', () {
      expect(formatBooleanStatus('completed'), equals('completed'));
    });

    test('should handle other types', () {
      expect(formatBooleanStatus(123), equals('123'));
    });
    
    test('should handle custom true/false values', () {
      expect(
        formatBooleanStatus(true, trueValue: 'enabled', falseValue: 'disabled'),
        equals('enabled')
      );
      expect(
        formatBooleanStatus(false, trueValue: 'enabled', falseValue: 'disabled'),
        equals('disabled')
      );
    });
  });
}
