import 'package:logger/logger.dart';
import '../../models/chat/chat_session.dart';
import '../../models/chat/message.dart';
import '../api/jarvis_api_service.dart';
import '../auth/auth_service.dart';

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
      final session = await _apiService.createConversation(title);
      
      return session;
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
  
  // Add a message to a chat session
  Future<Message?> addMessage(String sessionId, String text) async {
    try {
      // Send message to API
      final message = await _apiService.sendMessage(sessionId, text);
      
      return message;
    } catch (e) {
      _logger.e('Error adding message: $e');
      return null;
    }
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
  
  // Get user's selected model
  Future<String?> getUserSelectedModel(String userId) async {
    try {
      // Check if user is logged in
      final isLoggedIn = await _authService.isLoggedIn();
      if (!isLoggedIn) {
        _logger.w('No user logged in, cannot get user model');
        return null;
      }
      
      // Get user profile to extract selected model
      final user = await _apiService.getCurrentUser();
      return user?.selectedModel ?? 'gemini-2.0-flash'; // Default model if not set
    } catch (e) {
      _logger.e('Error getting user selected model: $e');
      return null;
    }
  }
  
  // Update user's selected model
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
  
  // Reset API error state
  void resetApiErrorState() {
    _hasApiIssues = false;
    _logger.i('API error state has been reset');
  }
}
