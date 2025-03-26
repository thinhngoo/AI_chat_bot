import 'package:logger/logger.dart';
import '../../models/chat/chat_session.dart';
import '../../models/chat/message.dart';
import '../api/jarvis_api_service.dart';
import '../auth/auth_service.dart';

class FirebaseChatService {
  final Logger _logger = Logger();
  final JarvisApiService _apiService = JarvisApiService();
  final AuthService _authService = AuthService();
  
  // Get chat sessions for current user with improved message loading
  Future<List<ChatSession>> getUserChatSessions() async {
    try {
      // Get current user ID
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        _logger.w('No user logged in, returning empty chat sessions list');
        return [];
      }
      
      // Get user ID based on auth provider type
      final userId = currentUser is String ? currentUser : currentUser.uid;
      
      _logger.i('Fetching chat sessions for user: $userId');
      
      // Get conversations from API
      final conversations = await _apiService.getConversations();
      
      _logger.i('Found ${conversations.length} chat sessions');
      
      // Load messages for each conversation
      List<ChatSession> chatSessions = [];
      for (var conversation in conversations) {
        final messages = await _apiService.getConversationHistory(conversation.id);
        
        _logger.i('Found ${messages.length} messages in session ${conversation.id}');
        
        // Create complete chat session with messages
        chatSessions.add(ChatSession(
          id: conversation.id,
          title: conversation.title,
          createdAt: conversation.createdAt,
          messages: messages,
        ));
      }
      
      _logger.i('Successfully loaded ${chatSessions.length} chat sessions with messages');
      return chatSessions;
    } catch (e) {
      _logger.e('Error getting user chat sessions: $e');
      return [];
    }
  }
  
  // Save a chat session
  Future<bool> saveChatSession(ChatSession session) async {
    try {
      // Get current user ID
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        _logger.w('No user logged in, cannot save chat session');
        return false;
      }
      
      // For Jarvis API, individual messages are saved separately
      // and there's no need to explicitly save the entire session
      
      return true;
    } catch (e) {
      _logger.e('Error saving chat session: $e');
      return false;
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
  
  // Add a single message to an existing chat session
  Future<bool> addMessage(String sessionId, Message message) async {
    try {
      if (message.isUser) {
        // Only send user messages to API
        await _apiService.sendMessage(sessionId, message.text);
      }
      
      return true;
    } catch (e) {
      _logger.e('Error adding message: $e');
      return false;
    }
  }
}
