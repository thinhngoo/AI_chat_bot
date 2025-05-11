import '../../../core/services/analytics/analytics_service.dart';

/// Helper class for tracking chat-specific analytics events
class ChatAnalytics {
  final AnalyticsService _analytics;
  
  ChatAnalytics(this._analytics);
  
  /// Log when a user starts a new chat
  Future<void> logNewChat({
    required String modelId,
  }) async {
    await _analytics.logChatSessionStarted(
      modelId: modelId,
      source: 'new_chat_button',
    );
  }
  
  /// Log when a message is sent to an AI model
  Future<void> logMessageSent({
    required String modelId,
    required bool isCustomBot,
    required String? conversationId,
    required String message,
  }) async {
    await _analytics.logMessageSent(
      modelId: modelId,
      isCustomBot: isCustomBot,
      conversationId: conversationId,
      messageLength: message.length,
    );
  }
  
  /// Log when a chat feature is used (like sharing or exporting)
  Future<void> logChatFeatureUsed({
    required String featureName,
    Map<String, dynamic>? additionalData,
  }) async {
    await _analytics.logFeatureUsed(
      featureName: 'chat_$featureName',
      additionalParams: additionalData,
    );
  }
  
  /// Log when a user switches AI models
  Future<void> logModelSwitched({
    required String fromModel,
    required String toModel,
  }) async {
    await _analytics.logModelChanged(
      fromModel: fromModel,
      toModel: toModel,
    );
  }
  
  /// Log when a user interacts with a prompt
  Future<void> logPromptInteraction({
    required String promptAction,
    String? promptText,
  }) async {
    await _analytics.logFeatureUsed(
      featureName: 'prompt_$promptAction',
      additionalParams: promptText != null ? {'text_length': promptText.length} : null,
    );
  }
  
  /// Log message sending errors
  Future<void> logMessageError({
    required String errorType,
    required String errorMessage,
    required String modelId,
    String? conversationId,
  }) async {
    await _analytics.logError(
      errorType: 'message_error_$errorType',
      errorMessage: errorMessage,
      errorSource: 'chat_screen',
      additionalData: {
        'model_id': modelId,
        'has_conversation': conversationId != null,
      },
    );
  }
  
  /// Track conversation load time for performance monitoring
  Future<void> logConversationLoadTime({
    required int loadTimeMs,
    required String modelId,
    required bool isSuccessful,
  }) async {
    await _analytics.logFeatureUsed(
      featureName: 'conversation_load',
      additionalParams: {
        'load_time_ms': loadTimeMs,
        'model_id': modelId,
        'success': isSuccessful,
      },
    );
  }
}
