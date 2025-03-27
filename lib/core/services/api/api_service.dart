import 'dart:async';
import 'package:logger/logger.dart';
import 'jarvis_api_service.dart';
import '../../constants/api_constants.dart';

/// API Service that wraps JarvisApiService to maintain compatibility with existing code
class ApiService {
  final Logger _logger = Logger();
  final JarvisApiService _jarvisApi = JarvisApiService();
  
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  
  ApiService._internal() {
    _initialize();
  }
  
  // Current model settings
  String _currentModel = ApiConstants.defaultModel;
  bool _useFallbackResponses = false;
  
  // Model names are now in ApiConstants
  
  Future<void> _initialize() async {
    await _jarvisApi.initialize();
  }
  
  // API Health check
  Future<bool> checkApiAvailability() async {
    try {
      // Create a simple test conversation
      final testSession = await _jarvisApi.createConversation('Test Session');
      
      // Test sending a simple message
      await _jarvisApi.sendMessage(testSession.id, 'Test message');
      await _jarvisApi.deleteConversation(testSession.id);
      
      _useFallbackResponses = false;
      _logger.i('API check successful - using online responses');
      return true;
    } catch (e) {
      _useFallbackResponses = true;
      _logger.e('API check failed: $e - using fallback responses');
      return false;
    }
  }
  
  // Set the model to use
  void setModel(String modelId) {
    if (ApiConstants.modelNames.containsKey(modelId)) {
      _currentModel = modelId;
      _logger.i('Model set to: $modelId');
    } else {
      _logger.w('Unknown model ID: $modelId, using default');
      _currentModel = ApiConstants.defaultModel;
    }
    
    // Optional: Inform the API service about the model change
    try {
      // Send model preference to API
      _jarvisApi.updateUserProfile({'selectedModel': _currentModel});
    } catch (e) {
      _logger.e('Error updating model preference: $e');
    }
  }
  
  // Get response from Gemini (or any model)
  Future<String> getDeepSeekResponse(String message) async {
    if (_useFallbackResponses) {
      return _getFallbackResponse(message);
    }
    
    try {
      // Get active conversations
      final conversations = await _jarvisApi.getConversations();
      
      // Create a new conversation if none exist
      String sessionId;
      if (conversations.isEmpty) {
        final newSession = await _jarvisApi.createConversation('New Chat');
        sessionId = newSession.id;
      } else {
        sessionId = conversations.first.id;
      }
      
      // Send message and get response
      await _jarvisApi.sendMessage(sessionId, message);
      
      // Get conversation history to extract the most recent bot response
      final messages = await _jarvisApi.getConversationHistory(sessionId);
      
      // Find the last bot message (not from the user)
      final botMessages = messages.where((msg) => !msg.isUser).toList();
      
      if (botMessages.isNotEmpty) {
        return botMessages.last.text;
      } else {
        throw 'No response received from API';
      }
    } catch (e) {
      _logger.e('Error getting model response: $e');
      _useFallbackResponses = true;
      return _getFallbackResponse(message);
    }
  }
  
  // Clear conversation history (for new chat)
  void clearConversationHistory() {
    // Nothing to do here, as history is managed by the server
    _logger.i('Conversation history reset requested');
  }
  
  // Get a fallback response when API is unavailable
  String _getFallbackResponse(String message) {
    // Simple fallback responses
    final fallbackResponses = [
      'I apologize, but I\'m currently experiencing connectivity issues. Please try again later.',
      'Sorry, I can\'t access my full capabilities at the moment. Please check your internet connection.',
      'I\'m unable to process your request right now. The server may be unavailable.',
      'It seems I\'m having trouble connecting to my knowledge base. Please try again in a few minutes.',
      'I\'m working in offline mode with limited functionality. Your question requires online access.'
    ];
    
    // Use message content to provide slightly more contextual fallback
    if (message.toLowerCase().contains('hello') || message.toLowerCase().contains('hi')) {
      return 'Hello! I\'m currently operating in offline mode with limited functionality. I\'ll do my best to assist you.';
    }
    
    if (message.length < 10) {
      return fallbackResponses[0];
    }
    
    // Return a pseudo-random response based on message length
    return fallbackResponses[message.length % fallbackResponses.length];
  }
  
  // Get available models
  List<Map<String, String>> getAvailableModels() {
    return ApiConstants.modelNames.entries.map((entry) => {
      'id': entry.key,
      'name': entry.value,
    }).toList();
  }

  // This fallback mode is used when the API is unavailable
  void resetFallbackMode() {
    _useFallbackResponses = false;
    _logger.i('API fallback mode reset. Will try to connect to API on next request');
  }
}