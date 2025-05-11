import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:logger/logger.dart';

/// Define standard analytics events to ensure consistency throughout the app
class AnalyticsEvents {
  // Singleton instance
  static final AnalyticsEvents _instance = AnalyticsEvents._internal();
  factory AnalyticsEvents() => _instance;
  AnalyticsEvents._internal();
  
  final Logger _logger = Logger();

  // User engagement events
  static const String EVENT_CHAT_STARTED = 'chat_started';
  static const String EVENT_MESSAGE_SENT = 'message_sent';
  static const String EVENT_AI_MODEL_SWITCHED = 'ai_model_switched';
  static const String EVENT_PROMPT_USED = 'prompt_used';
  static const String EVENT_ERROR_OCCURRED = 'error_occurred';
  static const String EVENT_CONVERSATION_CLEARED = 'conversation_cleared';
  
  // Subscription events
  static const String EVENT_SUBSCRIPTION_VIEW = 'subscription_view';
  static const String EVENT_SUBSCRIPTION_ATTEMPT = 'subscription_attempt';
  static const String EVENT_SUBSCRIPTION_SUCCESS = 'subscription_success';
  static const String EVENT_SUBSCRIPTION_ERROR = 'subscription_error';
  static const String EVENT_TOKEN_LOW = 'token_low_warning';
  
  // Feature usage events
  static const String EVENT_FEATURE_USED = 'feature_used';
  static const String EVENT_SHARE_CONVERSATION = 'share_conversation';
  static const String EVENT_EXPORT_CONVERSATION = 'export_conversation';
  
  // User property keys
  static const String USER_PROPERTY_SUBSCRIPTION = 'subscription_level';
  static const String USER_PROPERTY_MODEL_PREFERENCE = 'preferred_model';
  static const String USER_PROPERTY_THEME = 'theme_preference';
  static const String USER_PROPERTY_IS_POWER_USER = 'is_power_user';
  
  /// Log a message sent event with standardized parameters
  Future<void> logMessageSent({
    required FirebaseAnalytics analytics,
    required String modelId,
    required bool isCustomBot,
    String? conversationId,
    int? messageLength,
    int? responseTime,
  }) async {
    try {
      final Map<String, dynamic> params = {
        'model_id': modelId,
        'is_custom_bot': isCustomBot,
        'has_conversation_id': conversationId != null,
      };
      
      // Add optional parameters if provided
      if (messageLength != null) {
        params['message_length'] = messageLength;
      }
      
      if (responseTime != null) {
        params['response_time_ms'] = responseTime;
      }
      
      await analytics.logEvent(
        name: EVENT_MESSAGE_SENT,
        parameters: params,
      );
      
      _logger.d('Event logged: $EVENT_MESSAGE_SENT for model: $modelId');
    } catch (e) {
      _logger.e('Error logging message event: $e');
    }
  }
  
  /// Log when a feature is used
  Future<void> logFeatureUsed({
    required FirebaseAnalytics analytics,
    required String featureName,
    Map<String, dynamic>? additionalParams,
  }) async {
    try {
      final Map<String, dynamic> params = {
        'feature_name': featureName,
      };
      
      // Add additional parameters if provided
      if (additionalParams != null) {
        params.addAll(additionalParams);
      }
      
      await analytics.logEvent(
        name: EVENT_FEATURE_USED,
        parameters: params,
      );
      
      _logger.d('Feature usage logged: $featureName');
    } catch (e) {
      _logger.e('Error logging feature usage: $e');
    }
  }
  
  /// Log detailed error information
  Future<void> logErrorDetails({
    required FirebaseAnalytics analytics,
    required String errorType,
    required String errorMessage,
    String? errorSource,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final Map<String, dynamic> params = {
        'error_type': errorType,
        'error_message': errorMessage,
      };
      
      if (errorSource != null) {
        params['error_source'] = errorSource;
      }
      
      // Add additional data if provided
      if (additionalData != null) {
        // Avoid parameter conflicts
        additionalData.forEach((key, value) {
          if (!params.containsKey(key)) {
            params[key] = value;
          }
        });
      }
      
      await analytics.logEvent(
        name: EVENT_ERROR_OCCURRED,
        parameters: params,
      );
      
      _logger.d('Error event logged: $errorType - $errorMessage');
    } catch (e) {
      _logger.e('Error logging error event: $e');
    }
  }
  
  /// Log when a user's subscription status changes
  Future<void> logSubscriptionChanged({
    required FirebaseAnalytics analytics,
    required String oldStatus,
    required String newStatus,
  }) async {
    try {
      await analytics.logEvent(
        name: 'subscription_changed',
        parameters: {
          'old_status': oldStatus,
          'new_status': newStatus,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      _logger.d('Subscription changed: $oldStatus -> $newStatus');
    } catch (e) {
      _logger.e('Error logging subscription change: $e');
    }
  }
}
