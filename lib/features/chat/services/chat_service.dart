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
        // Handle server error
        String requestId = 'unknown';
        try {
          final errorData = jsonDecode(response.body);
          requestId = errorData['requestId'] ?? 'unknown';
        } catch (e) {
          _logger.e('Error parsing server error response: $e');
        }
        
        _logger.e('Server error when fetching conversations. Request ID: $requestId');
        _logger.e('Response body: ${response.body}');
        
        throw 'Unable to load conversations due to a server error. Please try again later.';
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
  
  // Generate a simple GUID for request tracking
  String generateGuid() {
    // This is a simplified GUID generator - in production, use a proper UUID library
    final now = DateTime.now().millisecondsSinceEpoch;
    final random = now % 1000000;
    return '$now-$random-chat-history';
  }
}
