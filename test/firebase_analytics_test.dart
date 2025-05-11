import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:ai_chat_bot/core/services/analytics/analytics_service.dart';
import 'package:ai_chat_bot/features/chat/analytics/chat_analytics.dart';

// Create mock classes
class MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {
  @override
  Future<void> logEvent({
    required String name, 
    Map<String, Object?>? parameters,
    AnalyticsCallOptions? callOptions,
  }) async {
    return super.noSuchMethod(
      Invocation.method(#logEvent, [], {
        #name: name, 
        #parameters: parameters, 
        #callOptions: callOptions
      }),
      returnValue: Future.value(),
    );
  }
  
  @override
  Future<void> logScreenView({
    String? screenName, 
    String? screenClass,
    Map<String, Object?>? parameters,
    AnalyticsCallOptions? callOptions,
  }) async {
    return super.noSuchMethod(
      Invocation.method(#logScreenView, [], {
        #screenName: screenName, 
        #screenClass: screenClass,
        #parameters: parameters,
        #callOptions: callOptions,
      }),
      returnValue: Future.value(),
    );
  }
  
  @override
  Future<void> setUserProperty({
    required String name, 
    required String? value,
    AnalyticsCallOptions? callOptions,
  }) async {
    return super.noSuchMethod(
      Invocation.method(#setUserProperty, [], {
        #name: name, 
        #value: value,
        #callOptions: callOptions,
      }),
      returnValue: Future.value(),
    );
  }
}

class MockAnalyticsService extends Mock implements AnalyticsService {
  @override
  Future<void> logMessageSent({
    required String modelId,
    required bool isCustomBot,
    String? conversationId,
    int? messageLength,
    int? responseTime,
  }) async {
    return super.noSuchMethod(
      Invocation.method(#logMessageSent, [], {
        #modelId: modelId,
        #isCustomBot: isCustomBot,
        #conversationId: conversationId,
        #messageLength: messageLength,
        #responseTime: responseTime
      }),
      returnValue: Future.value(),
    );
  }
  
  @override
  Future<void> logError({
    required String errorType,
    required String errorMessage,
    String? errorSource,
    Map<String, dynamic>? additionalData,
  }) async {
    return super.noSuchMethod(
      Invocation.method(#logError, [], {
        #errorType: errorType,
        #errorMessage: errorMessage,
        #errorSource: errorSource,
        #additionalData: additionalData,
      }),
      returnValue: Future.value(),
    );
  }
  
  @override
  Future<void> logModelChanged({
    required String fromModel,
    required String toModel,
  }) async {
    return super.noSuchMethod(
      Invocation.method(#logModelChanged, [], {
        #fromModel: fromModel,
        #toModel: toModel,
      }),
      returnValue: Future.value(),
    );
  }
}

void main() {
  late MockAnalyticsService mockAnalyticsService;
  late ChatAnalytics chatAnalytics;

  setUp(() {
    mockAnalyticsService = MockAnalyticsService();
    chatAnalytics = ChatAnalytics(mockAnalyticsService);
  });

  group('ChatAnalytics', () {
    test('logMessageSent calls analytics service with correct parameters', () async {
      // Arrange
      const modelId = 'gpt-4o';
      const isCustomBot = false;
      const conversationId = 'test-convo-id';
      const message = 'Test message';

      // Act
      await chatAnalytics.logMessageSent(
        modelId: modelId,
        isCustomBot: isCustomBot,
        conversationId: conversationId,
        message: message,
      );

      // Assert
      verify(mockAnalyticsService.logMessageSent(
        modelId: modelId,
        isCustomBot: isCustomBot,
        conversationId: conversationId,
        messageLength: message.length,
      )).called(1);
    });

    test('logModelSwitched calls analytics service with correct parameters', () async {
      // Arrange
      const fromModel = 'gpt-3.5-turbo';
      const toModel = 'gpt-4o';

      // Act
      await chatAnalytics.logModelSwitched(
        fromModel: fromModel,
        toModel: toModel,
      );

      // Assert
      verify(mockAnalyticsService.logModelChanged(
        fromModel: fromModel,
        toModel: toModel,
      )).called(1);
    });
    
    test('logMessageError calls analytics service with correct error data', () async {
      // Arrange
      const errorType = 'network_error';
      const errorMessage = 'Connection failed';
      const modelId = 'gpt-4o';
      const conversationId = 'test-convo-id';

      // Act
      await chatAnalytics.logMessageError(
        errorType: errorType,
        errorMessage: errorMessage,
        modelId: modelId,
        conversationId: conversationId,
      );

      // Assert
      verify(mockAnalyticsService.logError(
        errorType: 'message_error_$errorType',
        errorMessage: errorMessage,
        errorSource: 'chat_screen',
        additionalData: {
          'model_id': modelId,
          'has_conversation': true,
        },
      )).called(1);
    });
  });
}
