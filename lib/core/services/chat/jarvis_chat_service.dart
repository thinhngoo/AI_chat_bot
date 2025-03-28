import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/chat/chat_session.dart';
import '../../models/chat/message.dart';
import '../api/jarvis_api_service.dart';
import '../api/gemini_api_service.dart';
import '../../constants/api_constants.dart';

/// Service for chat-related operations using the Jarvis API
class JarvisChatService {
  static final JarvisChatService _instance = JarvisChatService._internal();
  factory JarvisChatService() => _instance;
  
  final Logger _logger = Logger();
  final JarvisApiService _apiService = JarvisApiService();
  final GeminiApiService _geminiApiService = GeminiApiService();
  bool _hasApiError = false;
  bool _useDirectGeminiApi = false;
  String? _selectedModel;
  
  JarvisChatService._internal();
  
  /// Get a list of the user's chat sessions
  Future<List<ChatSession>> getUserChatSessions() async {
    try {
      _logger.i('Getting user chat sessions');
      
      // First check if the API service is authenticated
      final isAuthenticated = _apiService.isAuthenticated();
      if (!isAuthenticated) {
        _logger.w('User is not authenticated, attempting token refresh');
        final refreshed = await _apiService.refreshToken();
        if (!refreshed) {
          if (_useDirectGeminiApi) {
            // Return empty list when using Gemini API directly
            _logger.i('Using Gemini API directly, returning empty sessions list');
            return [];
          }
          throw 'Authentication failed. Please login again.';
        }
      }
      
      // Check if we had a previous API error
      if (_hasApiError) {
        _logger.w('Previous API error detected, attempting to refresh token');
        final refreshed = await _apiService.refreshToken();
        if (!refreshed) {
          // If token refresh fails and we're not using Gemini, try switching to it
          if (!_useDirectGeminiApi) {
            _logger.i('Token refresh failed, switching to direct Gemini API');
            _useDirectGeminiApi = true;
            return [];
          }
          throw 'Unable to refresh token after previous API error';
        }
        _hasApiError = false;
      }
      
      // Get conversations from API
      final sessions = await _apiService.getConversations();
      
      _logger.i('Retrieved ${sessions.length} chat sessions');
      return sessions;
    } catch (e) {
      _logger.e('Error getting chat sessions: $e');
      
      // If it's an auth error and we're not using Gemini, switch to it
      if (e.toString().contains('Unauthorized') || 
          e.toString().contains('Authentication failed') ||
          e.toString().contains('401')) {
        if (!_useDirectGeminiApi) {
          _logger.i('Authorization error, switching to direct Gemini API');
          _useDirectGeminiApi = true;
          return [];
        }
      }
      
      // Mark as having API error for future requests
      _hasApiError = true;
      
      throw 'Failed to get chat sessions: ${e.toString()}';
    }
  }

  // Add a method to create a local session when using direct Gemini API
  Future<ChatSession> _createLocalChatSession(String title) async {
    return ChatSession(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      title: title.isEmpty ? 'New Chat' : title,
      createdAt: DateTime.now(),
    );
  }

  /// Get messages for a specific chat session
  Future<List<Message>> getMessages(String sessionId) async {
    try {
      _logger.i('Getting messages for chat session: $sessionId');

      // First check if the API service is authenticated
      final isAuthenticated = _apiService.isAuthenticated();
      if (!isAuthenticated) {
        _logger.w('User is not authenticated, attempting token refresh');
        final refreshed = await _apiService.refreshToken();
        if (!refreshed) {
          // If using direct Gemini API, return empty messages list
          if (_useDirectGeminiApi) {
            _logger.i('Using Gemini API directly, returning empty messages list');
            return [];
          }
          throw 'Authentication failed. Please login again.';
        }
      }
      
      // Check if we had a previous API error
      if (_hasApiError) {
        _logger.w('Previous API error detected, attempting to refresh token');
        final refreshed = await _apiService.refreshToken();
        if (!refreshed) {
          // If token refresh fails and we're not using Gemini, try switching to it
          if (!_useDirectGeminiApi) {
            _logger.i('Token refresh failed, switching to direct Gemini API');
            _useDirectGeminiApi = true;
            return [];
          }
          throw 'Unable to refresh token after previous API error';
        }
        _hasApiError = false;
      }
      
      // If we're using direct Gemini API, return empty messages list for now
      // (since we can't get history from Gemini API)
      if (_useDirectGeminiApi) {
        _logger.i('Using Gemini API directly, returning empty messages list');
        return [];
      }
      
      // Get conversation history from API
      final messages = await _apiService.getConversationHistory(sessionId);
      
      _logger.i('Retrieved ${messages.length} messages');
      return messages;
    } catch (e) {
      _logger.e('Error getting messages: $e');
      
      // If it's an auth error and we're not using Gemini, switch to it
      if (e.toString().contains('Unauthorized') || 
          e.toString().contains('Authentication failed') ||
          e.toString().contains('401')) {
        if (!_useDirectGeminiApi) {
          _logger.i('Authorization error, switching to direct Gemini API');
          _useDirectGeminiApi = true;
          return [];
        }
      }
      
      // Mark as having API error for future requests
      _hasApiError = true;
      
      throw 'Failed to get messages: ${e.toString()}';
    }
  }
  
  /// Send a message in a chat session - modified to optionally use direct Gemini API
  Future<Message> sendMessage(String sessionId, String text) async {
    try {
      _logger.i('Sending message to session: $sessionId');
      
      // Check if we should use direct Gemini API
      if (_useDirectGeminiApi) {
        _logger.i('Using direct Gemini API for message');
        
        // Just return the user message, response will be generated separately
        return Message(
          text: text,
          isUser: true,
          timestamp: DateTime.now(),
        );
      }
      
      // Otherwise, use Jarvis API as normal
      // Check if we had a previous API error
      if (_hasApiError) {
        _logger.w('Previous API error detected, attempting to refresh token');
        final refreshed = await _apiService.refreshToken();
        if (!refreshed) {
          // If refresh token fails, switch to direct Gemini API
          _logger.i('Token refresh failed, switching to direct Gemini API');
          _useDirectGeminiApi = true;
          return Message(
            text: text,
            isUser: true,
            timestamp: DateTime.now(),
          );
        }
        _hasApiError = false;
      }
      
      // Send message to API
      final response = await _apiService.sendMessage(sessionId, text);
      
      _logger.i('Message sent successfully to Jarvis API');
      return response;
    } catch (e) {
      _logger.e('Error sending message: $e');
      
      // If Jarvis API fails, switch to direct Gemini API
      if (!_useDirectGeminiApi) {
        _logger.i('Switching to direct Gemini API due to error');
        _useDirectGeminiApi = true;
        
        return Message(
          text: text,
          isUser: true,
          timestamp: DateTime.now(),
        );
      }
      
      // Mark as having API error for future requests
      _hasApiError = true;
      
      throw 'Failed to send message: ${e.toString()}';
    }
  }
  
  /// Get a direct response from the AI when using Gemini API
  Future<String> getDirectAIResponse(String text, List<Map<String, String>> chatHistory) async {
    try {
      _logger.i('Getting direct AI response using Gemini API');
      
      // Generate response using Gemini API
      final response = await _geminiApiService.generateChatResponse(text, chatHistory: chatHistory);
      
      _logger.i('Successfully generated AI response via Gemini');
      return response;
    } catch (e) {
      _logger.e('Error getting direct AI response: $e');
      return "I'm sorry, I couldn't generate a response at this time. Please try again later.";
    }
  }
  
  /// Create a new chat session
  Future<ChatSession?> createChatSession(String title) async {
    try {
      _logger.i('Creating new chat session: $title');
      
      // If using direct Gemini API, create a local session
      if (_useDirectGeminiApi) {
        _logger.i('Using direct Gemini API, creating local session');
        return await _createLocalChatSession(title);
      }
      
      // Check if we had a previous API error
      if (_hasApiError) {
        _logger.w('Previous API error detected, attempting to refresh token');
        final refreshed = await _apiService.refreshToken();
        if (!refreshed) {
          // If refresh fails, switch to Gemini API
          _logger.i('Token refresh failed, switching to direct Gemini API');
          _useDirectGeminiApi = true;
          return await _createLocalChatSession(title);
        }
        _hasApiError = false;
      }
      
      // Create conversation via API
      final session = await _apiService.createConversation(title);
      
      _logger.i('Chat session created with ID: ${session.id}');
      return session;
    } catch (e) {
      _logger.e('Error creating chat session: $e');
      
      // If it's an auth error, switch to Gemini API
      if (e.toString().contains('Unauthorized') || 
          e.toString().contains('Authentication failed') ||
          e.toString().contains('401')) {
        if (!_useDirectGeminiApi) {
          _logger.i('Authorization error, switching to direct Gemini API');
          _useDirectGeminiApi = true;
          return await _createLocalChatSession(title);
        }
      }
      
      // Mark as having API error for future requests
      _hasApiError = true;
      
      throw 'Failed to create chat session: ${e.toString()}';
    }
  }
  
  /// Delete a chat session
  Future<bool> deleteChatSession(String sessionId) async {
    try {
      _logger.i('Deleting chat session: $sessionId');
      
      // Check if we had a previous API error
      if (_hasApiError) {
        _logger.w('Previous API error detected, attempting to refresh token');
        final refreshed = await _apiService.refreshToken();
        if (!refreshed) {
          throw 'Unable to refresh token after previous API error';
        }
        _hasApiError = false;
      }
      
      // Delete conversation via API
      final success = await _apiService.deleteConversation(sessionId);
      
      _logger.i('Chat session deleted: $success');
      return success;
    } catch (e) {
      _logger.e('Error deleting chat session: $e');
      
      // Mark as having API error for future requests
      _hasApiError = true;
      
      throw 'Failed to delete chat session: ${e.toString()}';
    }
  }
  
  /// Get available AI models
  Future<List<Map<String, String>>> getAvailableModels() async {
    try {
      _logger.i('Getting available AI models');
      
      // Get models from API
      final models = await _apiService.getAvailableModels();
      
      _logger.i('Retrieved ${models.length} available models');
      return models;
    } catch (e) {
      _logger.e('Error getting available models: $e');
      
      // Return default models as fallback
      final defaultModels = ApiConstants.modelNames.entries.map((entry) => {
        'id': entry.key,
        'name': entry.value,
      }).toList();
      
      return defaultModels;
    }
  }
  
  /// Get the currently selected AI model
  Future<String?> getSelectedModel() async {
    // Return cached value if available
    if (_selectedModel != null) {
      return _selectedModel;
    }
    
    try {
      _logger.i('Getting selected AI model');
      
      // Load selected model from preferences
      final prefs = await SharedPreferences.getInstance();
      final model = prefs.getString('selectedModel');
      
      if (model != null && model.isNotEmpty) {
        _selectedModel = model;
        _logger.i('Retrieved selected model: $model');
      } else {
        // Set default model if none is selected
        _selectedModel = ApiConstants.defaultModel;
        _logger.i('No selected model found, using default: ${ApiConstants.defaultModel}');
      }
      
      return _selectedModel;
    } catch (e) {
      _logger.e('Error getting selected model: $e');
      
      // Return default model as fallback
      return ApiConstants.defaultModel;
    }
  }
  
  /// Update the selected AI model
  Future<bool> updateSelectedModel(String modelId) async {
    try {
      _logger.i('Updating selected AI model to: $modelId');
      
      // Save selected model to preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedModel', modelId);
      
      // Update cached value
      _selectedModel = modelId;
      
      _logger.i('Selected model updated successfully');
      return true;
    } catch (e) {
      _logger.e('Error updating selected model: $e');
      return false;
    }
  }
  
  /// Reset API error state
  void resetApiErrorState() {
    _logger.i('Resetting API error state');
    _hasApiError = false;
  }
  
  /// Check API connection
  Future<bool> checkApiConnection() async {
    try {
      _logger.i('Checking API connection');
      return await _apiService.checkApiStatus();
    } catch (e) {
      _logger.e('Error checking API connection: $e');
      return false;
    }
  }
  
  /// Check both API connections
  Future<Map<String, bool>> checkAllApiConnections() async {
    final results = <String, bool>{};
    
    try {
      _logger.i('Checking all API connections');
      
      // Check Jarvis API
      results['jarvisApi'] = await checkApiConnection();
      
      // Check Gemini API
      results['geminiApi'] = await _geminiApiService.checkApiStatus();
      
      return results;
    } catch (e) {
      _logger.e('Error checking API connections: $e');
      return {
        'jarvisApi': false,
        'geminiApi': false,
      };
    }
  }
  
  /// Toggle between Jarvis API and direct Gemini API
  void toggleDirectGeminiApi(bool useDirectApi) {
    _logger.i('Toggling direct Gemini API: $useDirectApi');
    _useDirectGeminiApi = useDirectApi;
  }
  
  /// Get whether direct Gemini API is in use
  bool isUsingDirectGeminiApi() {
    return _useDirectGeminiApi;
  }
}
