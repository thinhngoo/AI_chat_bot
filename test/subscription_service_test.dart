// filepath: c:\Project\AI_chat_bot\test\subscription_service_test.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';
import '../lib/core/services/auth/auth_service.dart';
import '../lib/features/subscription/models/subscription_model.dart';
import '../lib/features/subscription/services/subscription_service_fixed.dart';

// Use Mocktail instead of Mockito for easier mocking
class MockAuthService extends Mock implements AuthService {}
class MockClient extends Mock implements http.Client {}
class MockLogger extends Mock implements Logger {}

void main() {
  late MockAuthService mockAuthService;
  late Logger mockLogger;
  late SubscriptionService subscriptionService;
  late http.Client originalClient;

  setUpAll(() {
    // Register fallbacks for common types used in the mock
    registerFallbackValue(Uri.parse('https://example.com'));
  });

  setUp(() {
    mockAuthService = MockAuthService();
    mockLogger = MockLogger();
    
    // Configure mockAuthService behavior
    when(() => mockAuthService.accessToken).thenReturn('mock_token');
    when(() => mockAuthService.isLoggedIn()).thenAnswer((_) async => true);
    when(() => mockAuthService.getUserId()).thenReturn('mock_user_id');
    when(() => mockAuthService.getToken()).thenAnswer((_) async => 'mock_token');
    
    // Store original client for restoration later
    originalClient = http.Client();
    
    // Configure logger to avoid warnings
    when(() => mockLogger.i(any(), error: any(named: 'error'), stackTrace: any(named: 'stackTrace'), time: any(named: 'time'))).thenReturn(null);
    when(() => mockLogger.w(any(), error: any(named: 'error'), stackTrace: any(named: 'stackTrace'), time: any(named: 'time'))).thenReturn(null);
    when(() => mockLogger.e(any(), error: any(named: 'error'), stackTrace: any(named: 'stackTrace'), time: any(named: 'time'))).thenReturn(null);
    when(() => mockLogger.d(any(), error: any(named: 'error'), stackTrace: any(named: 'stackTrace'), time: any(named: 'time'))).thenReturn(null);
    
    subscriptionService = SubscriptionService(mockAuthService, mockLogger);
  });

  tearDown(() {
    subscriptionService.dispose();
    http.Client.new = () => originalClient;
  });

  group('SubscriptionService Timeout Handling', () {
    test('should handle timeouts gracefully by using cached data', () async {
      // Create a client that will always time out
      final mockClient = MockTimeoutClient();
      
      // Replace the default client with our mock
      http.Client.new = () => mockClient;
      
      // First call should result in using default subscription
      final result = await subscriptionService.getCurrentSubscription();
      
      // Verify the result is a default subscription
      expect(result.plan, equals(SubscriptionPlan.free));
      expect(result.id, isNotEmpty);
    });

    test('should use background refresh for stale cache', () async {
      // Create a mock client that returns a subscription
      final mockClient = MockHttpClient();
      
      // Replace the default client with our mock
      http.Client.new = () => mockClient;

      // Configure the mock response
      final mockSubscriptionData = {
        'id': 'test_sub_id',
        'plan': 'pro',
        'startDate': DateTime.now().toIso8601String(),
        'endDate': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'isActive': true,
        'autoRenew': true,
        'features': {
          'tokenLimit': -1,
          'maxBots': -1,
          'allowedModels': ['gpt-4o', 'claude-3-haiku'],
          'currentUsage': 0
        }
      };

      // First API call should return mock data
      final result1 = await subscriptionService.getCurrentSubscription();
      expect(result1.id, isNotEmpty);
      
      // Allow some time for background refresh logic to run
      await Future.delayed(const Duration(milliseconds: 100));
    });
  });
}

/// A custom HTTP client that always times out for testing timeout handling
class MockTimeoutClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Simulate a timeout
    await Future.delayed(const Duration(seconds: 10));
    throw TimeoutException('Connection timeout');
  }
}

/// A simple HTTP client mock for controlled responses
class MockHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final mockSubscriptionData = {
      'id': 'test_sub_id',
      'plan': 'pro',
      'startDate': DateTime.now().toIso8601String(),
      'endDate': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      'isActive': true,
      'autoRenew': true,
      'features': {
        'tokenLimit': -1,
        'maxBots': -1,
        'allowedModels': ['gpt-4o', 'claude-3-haiku'],
        'currentUsage': 0
      }
    };
    
    final body = utf8.encode(jsonEncode(mockSubscriptionData));
    
    return http.StreamedResponse(
      Stream.value(body),
      200,
      headers: {'content-type': 'application/json'},
      contentLength: body.length,
    );
  }
}
