import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/auth/auth_service.dart';
import '../models/conversation_message.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;

  final Logger _logger = Logger();
  final AuthService _authService = AuthService();

  ChatService._internal();

  Future<ConversationMessagesResponse> getConversationHistory(
    String conversationId, {
    String? assistantId,
    String? cursor,
    int limit = 20,
  }) async {
    try {
      _logger.i('Fetching conversation history for ID: $conversationId');
      
      // Build query parameters
      final queryParams = {
        'assistantModel': 'dify', // Required parameter
        'limit': limit.toString(),
      };
      
      if (assistantId != null) {
        queryParams['assistantId'] = assistantId;
      }
      
      if (cursor != null) {
        queryParams['cursor'] = cursor;
      }
      
      // Build URL
      final baseUrl = ApiConstants.jarvisApiUrl;
      final endpoint = '/api/v1/ai-chat/conversations/$conversationId/messages';
      final uri = Uri.parse(baseUrl + endpoint).replace(queryParameters: queryParams);
      
      // Log full request URI for debugging
      _logger.i('Request URI: $uri');
      
      // Get access token
      final accessToken = _authService.accessToken;
      if (accessToken == null) {
        throw 'No access token available. Please log in again.';
      }
      
      // Prepare headers
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'x-jarvis-guid': generateGuid(),
      };
      
      // Send request
      final response = await http.get(uri, headers: headers);
      
      _logger.i('Conversation history response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ConversationMessagesResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        _logger.w('Token expired, attempting to refresh...');
        final refreshSuccess = await _authService.refreshToken();
        
        if (refreshSuccess) {
          // Retry with new token
          return getConversationHistory(
            conversationId,
            assistantId: assistantId,
            cursor: cursor,
            limit: limit,
          );
        } else {
          throw 'Authentication expired. Please log in again.';
        }
      } else {
        // Provide more specific error messages based on status code
        _logger.e('Failed to fetch conversation history: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        
        if (response.statusCode == 404) {
          throw 'Conversation not found. The conversation ID may be invalid.';
        } else if (response.statusCode == 500) {
          throw 'Server error. This might be due to an invalid conversation ID or server issues.';
        } else {
          throw 'Failed to fetch conversation history: ${response.statusCode}';
        }
      }
    } catch (e) {
      _logger.e('Error fetching conversation history: $e');
      rethrow;
    }
  }
  
  Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      _logger.i('Fetching conversations list');
      
      // Build query parameters
      final queryParams = {
        'assistantModel': 'dify', // Required parameter
        'limit': '20', // Optional parameter
      };
      
      // Build URL with query parameters
      final baseUrl = ApiConstants.jarvisApiUrl;
      final endpoint = ApiConstants.aiChatConversations;
      final uri = Uri.parse(baseUrl + endpoint).replace(queryParameters: queryParams);
      
      // Log request details for debugging
      _logger.i('Request URI: $uri');
      
      // Get access token
      final accessToken = _authService.accessToken;
      if (accessToken == null) {
        throw 'No access token available. Please log in again.';
      }
      
      // Log partially masked token for debugging
      final maskedToken = accessToken.length > 15 
          ? '${accessToken.substring(0, 10)}...${accessToken.substring(accessToken.length - 5)}'
          : '***masked***';
      _logger.i('Using access token: $maskedToken');
      
      // Prepare headers
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'x-jarvis-guid': generateGuid(),
      };
      
      // Send request
      final response = await http.get(uri, headers: headers);
      
      _logger.i('Conversations list response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
        
        _logger.i('Successfully fetched ${items.length} conversations');
        if (items.isEmpty) {
          _logger.i('No conversations found for this user');
        }
        
        return items;
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        _logger.w('Token expired, attempting to refresh...');
        final refreshSuccess = await _authService.refreshToken();
        
        if (refreshSuccess) {
          // Retry with new token
          return getConversations();
        } else {
          throw 'Authentication expired. Please log in again.';
        }
      } else if (response.statusCode == 500) {
        // Handle server error - MODIFIED TO RETURN EMPTY LIST
        String requestId = 'unknown';
        try {
          final errorData = jsonDecode(response.body);
          requestId = errorData['requestId'] ?? 'unknown';
        } catch (e) {
          _logger.e('Error parsing server error response: $e');
        }
        
        _logger.w('Server returned 500 error (Request ID: $requestId) - treating as empty conversations list');
        _logger.w('Response body: ${response.body}');
        
        // Return empty list instead of throwing exception
        return [];
      } else {
        // Handle other errors
        _logger.e('Failed to fetch conversations: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        
        // Extract request ID if available for support
        String requestId = '';
        try {
          final errorData = jsonDecode(response.body);
          requestId = errorData['requestId'] ?? '';
        } catch (e) {
          // Parsing error, ignore
        }
        
        throw 'Failed to fetch conversations: ${response.statusCode}${requestId.isNotEmpty ? ' (Request ID: $requestId)' : ''}';
      }
    } catch (e) {
      _logger.e('Error fetching conversations: $e');
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> sendMessage({
    required String content,
    required String assistantId,
    String? conversationId,
    List<String>? files,
  }) async {
    try {
      _logger.i('Sending message to AI chat');
      if (conversationId != null && conversationId.isNotEmpty) {
        _logger.i('Using existing conversation ID: $conversationId');
      } else {
        _logger.i('No conversation ID provided - starting new conversation');
      }
      
      // Get access token
      final accessToken = _authService.accessToken;
      if (accessToken == null) {
        throw 'No access token available. Please log in again.';
      }
      
      // Prepare headers
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'x-jarvis-guid': generateGuid(),
        'Content-Type': 'application/json'
      };
      
      // Build URL
      final baseUrl = ApiConstants.jarvisApiUrl;
      final endpoint = '/api/v1/ai-chat/messages';
      final uri = Uri.parse(baseUrl + endpoint);
      
      // Prepare request body based on API documentation
      final Map<String, dynamic> body = {
        'content': content,
        'assistant': {
          'id': assistantId,
          'model': 'dify',
          'name': _getAssistantName(assistantId),
        },
        'files': [], // Always include empty files array
        'type': 'regular', // Add type parameter which may be required
      };
      
      // Handle files properly for Dify 0.10.1
      if (files != null && files.isNotEmpty) {
        // Format files with created_by_role property as required by Dify 0.10.1
        final formattedFiles = files.map((fileId) => {
          'id': fileId,
          'created_by_role': 'user' // Required enum value in Dify 0.10.1
        }).toList();
        
        body['files'] = formattedFiles;
        _logger.i('Including ${files.length} files in the message with created_by_role property');
      }
      
      // Only include metadata for existing conversations
      if (conversationId != null && conversationId.isNotEmpty) {
        // For existing conversations, include the ID in metadata
        body['metadata'] = {
          'conversation': {
            'id': conversationId,
          }
        };
        _logger.i('Including conversation ID in metadata: $conversationId');
      }
      // For new conversations, don't include metadata at all
      
      _logger.i('Sending message to: $uri');
      _logger.d('Request body: ${jsonEncode(body)}');
      
      // Send request
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );
      
      _logger.i('Send message response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.i('Message sent successfully, conversation ID: ${data['conversationId']}');
        return data;
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        _logger.w('Token expired, attempting to refresh...');
        final refreshSuccess = await _authService.refreshToken();
        
        if (refreshSuccess) {
          // Retry with new token
          return sendMessage(
            content: content,
            assistantId: assistantId,
            conversationId: conversationId,
            files: files,
          );
        } else {
          throw 'Authentication expired. Please log in again.';
        }
      } else if (response.statusCode == 500) {
        // Handle potential conversation ID issues
        _logger.e('Server returned 500 error - might be related to conversation handling');
        _logger.e('Response body: ${response.body}');
        
        // Try to extract more detailed error information if available
        String errorMsg = 'Failed to send message (Server error 500)';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null) {
            errorMsg = errorData['message'];
          }
          if (errorData['requestId'] != null) {
            _logger.e('Request ID: ${errorData['requestId']}');
            errorMsg += ' (Request ID: ${errorData['requestId']})';
          }
        } catch (e) {
          // Ignore JSON parsing errors
        }
        
        throw 'Error sending message: $errorMsg. Try starting a new conversation.';
      } else {
        // Handle other errors
        _logger.e('Failed to send message: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        
        String errorMessage = 'Failed to send message: ${response.statusCode}';
        
        // Try to parse error details
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          }
        } catch (e) {
          // Ignore JSON parsing errors
        }
        
        throw errorMessage;
      }
    } catch (e) {
      _logger.e('Error sending message: $e');
      rethrow;
    }
  }
  
  // Helper method to get assistant name based on ID
  String _getAssistantName(String assistantId) {
    switch (assistantId) {
      case 'gpt-4o':
        return 'GPT-4o';
      case 'gpt-4o-mini':
        return 'GPT-4o mini';
      case 'gemini-1.5-flash-latest':
        return 'Gemini 1.5 Flash';
      case 'gemini-1.5-pro-latest':
        return 'Gemini 1.5 Pro';
      case 'claude-3-haiku-20240307':
        return 'Claude 3 Haiku';
      case 'claude-3-sonnet-20240229':
        return 'Claude 3 Sonnet';
      default:
        return assistantId;
    }
  }
  
  // Generate a simple GUID for request tracking
  String generateGuid() {
    // This is a simplified GUID generator - in production, use a proper UUID library
    final now = DateTime.now().millisecondsSinceEpoch;
    final random = now % 1000000;
    return '$now-$random-chat-history';
  }
}
