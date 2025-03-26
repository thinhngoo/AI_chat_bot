import 'package:logger/logger.dart';
import '../../models/user_model.dart';
import '../../models/chat/chat_session.dart';
import '../../models/chat/message.dart';
import '../api/jarvis_api_service.dart';

class FirestoreDataService {
  final Logger _logger = Logger();
  final JarvisApiService _apiService = JarvisApiService();
  
  // Flag to track API issues
  bool _hasApiIssues = false;
  
  // User data operations
  Future<void> createOrUpdateUser(UserModel user) async {
    if (_hasApiIssues) {
      _logger.w('Skipping API operation due to previous issues');
      return;
    }
    
    try {
      final success = await _apiService.updateUserProfile({
        'name': user.name ?? '',
        'selectedModel': user.selectedModel ?? 'gemini-2.0-flash',
      });
      
      if (success) {
        _logger.i('User data saved: ${user.email}');
      } else {
        throw 'Failed to update user data';
      }
    } catch (e) {
      _handleApiError(e, 'saving user data');
    }
  }
  
  // Get user by ID 
  Future<UserModel?> getUserById(String uid) async {
    if (_hasApiIssues) {
      _logger.w('Skipping API operation due to previous issues');
      return null;
    }
    
    try {
      return await _apiService.getCurrentUser();
    } catch (e) {
      _handleApiError(e, 'getting user by ID');
      return null;
    }
  }
  
  // Chat sessions operations
  Future<List<ChatSession>> getUserChatSessions(String userId) async {
    if (_hasApiIssues) {
      _logger.w('Skipping API operation due to previous issues');
      return [];
    }
    
    try {
      return await _apiService.getConversations();
    } catch (e) {
      _handleApiError(e, 'getting user chat sessions');
      return [];
    }
  }
  
  // Create a new chat session
  Future<ChatSession?> createChatSession(String title, String userId) async {
    if (_hasApiIssues) {
      _logger.w('Skipping API operation due to previous issues');
      return null;
    }
    
    try {
      return await _apiService.createConversation(title);
    } catch (e) {
      _handleApiError(e, 'creating chat session');
      return null;
    }
  }
  
  // Delete a chat session
  Future<bool> deleteChatSession(String sessionId) async {
    if (_hasApiIssues) {
      _logger.w('Skipping API operation due to previous issues');
      return false;
    }
    
    try {
      return await _apiService.deleteConversation(sessionId);
    } catch (e) {
      _handleApiError(e, 'deleting chat session');
      return false;
    }
  }
  
  // Save a chat session
  Future<bool> saveChatSession(ChatSession session, String userId) async {
    if (_hasApiIssues) {
      _logger.w('Skipping API operation due to previous issues');
      return false;
    }
    
    try {
      // For Jarvis API, we don't need to explicitly save the session
      // as messages are saved individually
      return true;
    } catch (e) {
      _handleApiError(e, 'saving chat session');
      return false;
    }
  }
  
  // Add a message to a chat session
  Future<bool> addMessageToSession(String sessionId, Message message, String userId) async {
    if (_hasApiIssues) {
      _logger.w('Skipping API operation due to previous issues');
      return false;
    }
    
    try {
      if (message.isUser) {
        // Only send user messages to API, bot responses come from the API
        await _apiService.sendMessage(sessionId, message.text);
      }
      return true;
    } catch (e) {
      _handleApiError(e, 'adding message to session');
      return false;
    }
  }
  
  // Get user's selected model
  Future<String?> getUserSelectedModel(String userId) async {
    if (_hasApiIssues) {
      _logger.w('Skipping API operation due to previous issues');
      return null;
    }
    
    try {
      final user = await _apiService.getCurrentUser();
      return user?.selectedModel ?? 'gemini-2.0-flash'; // Default model if not set
    } catch (e) {
      _handleApiError(e, 'getting user selected model');
      return null;
    }
  }
  
  // Update user's selected model
  Future<bool> updateUserSelectedModel(String userId, String model) async {
    if (_hasApiIssues) {
      _logger.w('Skipping API operation due to previous issues');
      return false;
    }
    
    try {
      return await _apiService.updateUserProfile({
        'selectedModel': model,
      });
    } catch (e) {
      _handleApiError(e, 'updating user selected model');
      return false;
    }
  }
  
  // Handle API errors
  void _handleApiError(dynamic error, String operation) {
    _logger.e('API error when $operation: $error');
    _hasApiIssues = true;
  }
  
  // Reset API issues flag
  void resetPermissionCheck() {
    _hasApiIssues = false;
    _logger.i('API issues flag has been reset');
  }
}
