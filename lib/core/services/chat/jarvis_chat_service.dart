import 'package:logger/logger.dart';
import '../../models/chat/chat_session.dart';
import '../../models/chat/message.dart';
import '../api/jarvis_api_service.dart';
import '../auth/auth_service.dart';
import '../../constants/api_constants.dart';

class JarvisChatService {
  final Logger _logger = Logger();
  final JarvisApiService _apiService = JarvisApiService();
  final AuthService _authService = AuthService();
  
  // Flag to track API issues
  bool _hasApiIssues = false;
  
  // Get all chat sessions for current user
  Future<List<ChatSession>> getUserChatSessions() async {
    try {
      if (_hasApiIssues) {
        _logger.w('Skipping API operation due to previous issues');
        return [];
      }
      
      // Check if user is logged in
      final isLoggedIn = await _authService.isLoggedIn();
      if (!isLoggedIn) {
        _logger.w('No user logged in, returning empty chat sessions list');
        return [];
      }
      
      // Get user chat sessions from API
      final conversations = await _apiService.getConversations();
      
      // Load messages for each conversation
      for (var session in conversations) {
        final messages = await _apiService.getConversationHistory(session.id);
        session.messages.addAll(messages);
      }
      
      return conversations;
    } catch (e) {
      _logger.e('Error getting user chat sessions: $e');
      _hasApiIssues = true;
      return [];
    }
  }
  
  // Create a new chat session
  Future<ChatSession?> createChatSession(String title) async {
    try {
      // Check if user is logged in
      final isLoggedIn = await _authService.isLoggedIn();
      if (!isLoggedIn) {
        _logger.w('No user logged in, cannot create chat session');
        return null;
      }
      
      // Create new chat session
      return await _apiService.createConversation(title);
    } catch (e) {
      _logger.e('Error creating chat session: $e');
      return null;
    }
  }
  
  // Delete a chat session
  Future<bool> deleteChatSession(String sessionId) async {
    try {
      return await _apiService.deleteConversation(sessionId);
    } catch (e) {
      _logger.e('Error deleting chat session: $e');
      return false;
    }
  }
  
  // Add a message to a chat session and get the response
  Future<Message?> sendMessage(String sessionId, String text) async {
    try {
      // Send message to API
      return await _apiService.sendMessage(sessionId, text);
    } catch (e) {
      _logger.e('Error sending message: $e');
      return null;
    }
  }
  
  // Add message method (call the sendMessage method)
  Future<Message?> addMessage(String sessionId, String text) async {
    return await sendMessage(sessionId, text);
  }
  
  // Get messages from a chat session
  Future<List<Message>> getMessages(String sessionId) async {
    try {
      return await _apiService.getConversationHistory(sessionId);
    } catch (e) {
      _logger.e('Error getting messages: $e');
      return [];
    }
  }
  
  // Get user's selected model with userId parameter
  Future<String?> getUserSelectedModel(String userId) async {
    try {
      // Check if user is logged in
      final isLoggedIn = await _authService.isLoggedIn();
      if (!isLoggedIn) {
        _logger.w('No user logged in, returning default model');
        return ApiConstants.defaultModel;
      }
      
      // Get user profile to extract selected model
      final user = await _apiService.getCurrentUser();
      return user?.selectedModel ?? ApiConstants.defaultModel;
    } catch (e) {
      _logger.e('Error getting user selected model: $e');
      return ApiConstants.defaultModel;
    }
  }
  
  // Get selected model without user ID (for backward compatibility)
  Future<String?> getSelectedModel() async {
    return getUserSelectedModel('');
  }
  
  // Update user's selected model with two parameters
  Future<bool> updateUserSelectedModel(String userId, String model) async {
    try {
      // Check if user is logged in
      final isLoggedIn = await _authService.isLoggedIn();
      if (!isLoggedIn) {
        _logger.w('No user logged in, cannot update user model');
        return false;
      }
      
      // Update user profile with selected model
      return await _apiService.updateUserProfile({
        'selectedModel': model,
      });
    } catch (e) {
      _logger.e('Error updating user selected model: $e');
      return false;
    }
  }
  
  // Update model with just the model parameter (for backward compatibility)
  Future<bool> updateSelectedModel(String model) async {
    return updateUserSelectedModel('', model);
  }
  
  // Reset API error state
  void resetApiErrorState() {
    _hasApiIssues = false;
    _logger.i('API error state has been reset');
  }
}
