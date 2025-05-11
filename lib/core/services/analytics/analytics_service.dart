import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:logger/logger.dart';
import '../../../features/bot/services/bot_analytics_service.dart';
import 'analytics_events.dart';

/// A service that handles both Firebase Analytics and custom backend analytics
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  
  factory AnalyticsService() => _instance;
    // Firebase Analytics instance
  late final FirebaseAnalytics _analytics;
  // BotAnalytics for custom backend events
  final BotAnalyticsService _botAnalytics = BotAnalyticsService();
  // Standard analytics events
  final AnalyticsEvents _events = AnalyticsEvents();
  final Logger _logger = Logger();
  bool _initialized = false;
  
  // Getter for Firebase Analytics instance
  FirebaseAnalytics get analytics => _analytics;
  
  AnalyticsService._internal();
  
  /// Initialize the analytics service
  Future<void> initialize() async {
    try {
      if (_initialized) return;
      
      _analytics = FirebaseAnalytics.instance;
      // Allow up to 500 events to be queued if offline
      await _analytics.setAnalyticsCollectionEnabled(true);
      
      _logger.i('Analytics service initialized');
      _initialized = true;
    } catch (e) {
      _logger.e('Failed to initialize analytics: $e');
    }
  }
  
  /// Log a screen view event
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? 'Flutter',
      );
      _logger.d('Screen view logged: $screenName');
    } catch (e) {
      _logger.e('Error logging screen view: $e');
    }
  }
  
  /// Log a user login event
  Future<void> logLogin({String? method}) async {
    try {
      await _analytics.logLogin(loginMethod: method ?? 'default');
      _logger.d('Login event logged');
    } catch (e) {
      _logger.e('Error logging login event: $e');
    }
  }
  /// Log when the user sends a message to an AI model
  Future<void> logMessageSent({
    required String modelId,
    required bool isCustomBot,
    String? conversationId,
    int? messageLength,
    int? responseTime,
  }) async {
    try {
      // Use standardized event logging
      await _events.logMessageSent(
        analytics: _analytics,
        modelId: modelId,
        isCustomBot: isCustomBot,
        conversationId: conversationId,
        messageLength: messageLength,
        responseTime: responseTime,
      );
      
      // Also log to backend analytics if appropriate
      if (isCustomBot) {
        await _botAnalytics.trackEvent(
          botId: modelId,
          platform: 'app',
          eventType: 'message_sent',
          eventData: {
            'conversation_id': conversationId,
            if (messageLength != null) 'message_length': messageLength,
            if (responseTime != null) 'response_time_ms': responseTime,
          },
        );
      }
      
      _logger.d('Message sent event logged for model: $modelId');
    } catch (e) {
      _logger.e('Error logging message sent event: $e');
    }
  }

  /// Log when an error occurs during message sending
  Future<void> logError({
    required String errorType,
    required String errorMessage,
    String? errorSource,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Use standardized error logging
      await _events.logErrorDetails(
        analytics: _analytics,
        errorType: errorType,
        errorMessage: errorMessage,
        errorSource: errorSource,
        additionalData: additionalData,
      );
      
      _logger.d('Error event logged: $errorType - $errorMessage');
    } catch (e) {
      _logger.e('Error logging error event: $e');
    }
  }
  
  /// Log when a user changes the AI model/assistant
  Future<void> logModelChanged({
    required String fromModel,
    required String toModel, 
  }) async {
    try {
      await _analytics.logEvent(
        name: 'model_changed',
        parameters: {
          'from_model': fromModel,
          'to_model': toModel,
        },
      );
      _logger.d('Model changed event logged: $fromModel -> $toModel');
    } catch (e) {
      _logger.e('Error logging model changed event: $e');
    }
  }
  
  /// Log when a subscription-related action is performed
  Future<void> logSubscriptionEvent({
    required String action,
    String? plan,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'subscription_action',
        parameters: {
          'action': action,
          'plan': plan ?? 'unknown',
        },
      );
      _logger.d('Subscription event logged: $action - $plan');
    } catch (e) {
      _logger.e('Error logging subscription event: $e');
    }
  }
  
  /// Set the user ID for analytics
  Future<void> setUserId(String? id) async {
    if (id == null || id.isEmpty) return;
    
    try {
      await _analytics.setUserId(id: id);
      _logger.d('User ID set for analytics: $id');
    } catch (e) {
      _logger.e('Error setting user ID: $e');
    }
  }
    /// Set a user property for analytics segmentation
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
      _logger.d('User property set: $name = $value');
    } catch (e) {
      _logger.e('Error setting user property: $e');
    }
  }
  
  /// Log when a user uses a specific feature
  Future<void> logFeatureUsed({
    required String featureName,
    Map<String, dynamic>? additionalParams,
  }) async {
    try {
      await _events.logFeatureUsed(
        analytics: _analytics,
        featureName: featureName,
        additionalParams: additionalParams,
      );
    } catch (e) {
      _logger.e('Error logging feature usage: $e');
    }
  }
  
  /// Log when a user's chat session begins
  Future<void> logChatSessionStarted({
    required String modelId,
    String? source,
  }) async {
    try {
      await _analytics.logEvent(
        name: AnalyticsEvents.EVENT_CHAT_STARTED,
        parameters: {
          'model_id': modelId,
          'source': source ?? 'app_direct',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      _logger.e('Error logging chat session start: $e');
    }
  }
}
